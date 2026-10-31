const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');

initializeApp();

/**
 * Pings the other side of a support request thread.
 *
 * - Student writes (isUser: true)  -> notify the matched professional.
 * - Staff/pro writes (isUser false) -> notify the student.
 * - Status becomes "matched"        -> notify the student they have a volunteer.
 *
 * Devices are found via users/{uid}/fcmTokens/{doc}.token — the collection
 * the Flutter app already maintains. Stale tokens are deleted.
 */
exports.proRequestThreadNotify = onDocumentUpdated(
  'users/{uid}/proRequests/{requestId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const studentUid = event.params.uid;

    // Matched: tell the student a volunteer is ready.
    if (before.status !== 'matched' && after.status === 'matched') {
      await notifyUser(
        studentUid,
        'You were matched',
        `${after.professionalName || 'A volunteer'} is ready to talk.`,
        '/support',
      );
    }

    const beforeLen = (before.messages || []).length;
    const afterMsgs = after.messages || [];
    if (afterMsgs.length <= beforeLen) return;

    const last = afterMsgs[afterMsgs.length - 1];
    const senderIsStudent = last.isUser === true;

    // Student replied -> ping the pro's devices. Staff/pro replied -> ping
    // the student. professionalId on the doc is the pro's Firebase uid.
    const targetUid = senderIsStudent ? after.professionalId : studentUid;
    if (!targetUid) return;

    const title = senderIsStudent
      ? `${after.professionalName || 'Your student'} replied`
      : 'New message in your support request';
    const body = String(last.text || '').slice(0, 120);
    const route = senderIsStudent ? '/my-cases' : '/support';

    await notifyUser(targetUid, title, body, route);
  },
);

async function notifyUser(uid, title, body, route) {
  const db = getFirestore();
  const tokens = await db
    .collection('users')
    .doc(uid)
    .collection('fcmTokens')
    .get();

  const messaging = getMessaging();
  const sends = [];
  for (const doc of tokens.docs) {
    const token = doc.data().token;
    if (!token) continue;
    sends.push(
      messaging
        .send({
          token,
          notification: {title, body},
          data: {route},
          android: {
            priority: 'high',
            notification: {channelId: 'scholai_checkin'},
          },
        })
        .catch((err) => {
          if (err.code === 'messaging/registration-token-not-registered') {
            return doc.ref.delete();
          }
          console.warn('send failed', {uid, err});
          return null;
        }),
    );
  }
  await Promise.all(sends);
}
