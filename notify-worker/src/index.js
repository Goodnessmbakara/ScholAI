import {SignJWT, importPKCS8} from 'jose';

const FIRESTORE_BASE =
  'https://firestore.googleapis.com/v1/projects/PROJECT_ID/databases/(default)/documents';
const FCM_BASE =
  'https://fcm.googleapis.com/v1/projects/PROJECT_ID/messages:send';
const TOKENINFO = 'https://oauth2.googleapis.com/tokeninfo?id_token=';
const BOOTSTRAP_ADMINS = new Set([
  'mbakaragoodness2003@gmail.com',
  'amicablembakara50@gmail.com',
]);

let cachedAccessToken = null;
let accessTokenExp = 0;

async function serviceAccountToken(env) {
  if (cachedAccessToken && Date.now() < accessTokenExp - 60_000) {
    return cachedAccessToken;
  }
  const sa = JSON.parse(env.FIREBASE_SA_KEY);
  const key = await importPKCS8(sa.private_key, 'RS256');
  const now = Math.floor(Date.now() / 1000);
  const jwt = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({alg: 'RS256', kid: sa.private_key_id})
    .setIssuer(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  if (!res.ok) throw new Error(`oauth exchange failed: ${res.status}`);
  const data = await res.json();
  cachedAccessToken = data.access_token;
  accessTokenExp = Date.now() + data.expires_in * 1000;
  return cachedAccessToken;
}

// Verify the caller's Firebase ID token via Google's tokeninfo endpoint.
async function callerIdentity(idToken, projectId) {
  const res = await fetch(TOKENINFO + encodeURIComponent(idToken));
  if (!res.ok) return null;
  const info = await res.json();
  if (info.aud !== projectId || !info.sub) return null;
  return {uid: info.sub, email: info.email || ''};
}

async function firestoreGet(path, token) {
  const res = await fetch(`${FIRESTORE_BASE}/${path}`, {
    headers: {Authorization: `Bearer ${token}`},
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`firestore get ${path}: ${res.status}`);
  return res.json();
}

const fs = (v) => v?.stringValue ?? v?.integerValue ?? v?.booleanValue ?? null;

function docToFields(doc) {
  const out = {};
  for (const [k, v] of Object.entries(doc?.fields || {})) {
    if ('arrayValue' in v) {
      out[k] = v.arrayValue.values || [];
    } else {
      out[k] = fs(v);
    }
  }
  return out;
}

async function isAdmin(uid, email, token) {
  if (BOOTSTRAP_ADMINS.has(email.toLowerCase())) return true;
  const doc = await firestoreGet(`users/${uid}`, token);
  const role = fs(doc?.fields?.role);
  return role === 'admin' || role === 'superAdmin';
}

async function sendToUser(uid, title, body, route, token, projectId) {
  const tokensDoc = await fetch(
    `${FIRESTORE_BASE}/users/${uid}/fcmTokens?pageSize=50`,
    {headers: {Authorization: `Bearer ${token}`}},
  );
  if (!tokensDoc.ok) return {sent: 0};
  const listing = await tokensDoc.json();

  let sent = 0;
  for (const doc of listing.documents || []) {
    const fcmToken = fs(doc.fields?.token);
    if (!fcmToken) continue;
    const res = await fetch(FCM_BASE.replace('PROJECT_ID', projectId), {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {title, body},
          data: {route},
          android: {
            priority: 'HIGH',
            notification: {channel_id: 'scholai_checkin'},
          },
        },
      }),
    });
    if (res.ok) {
      sent++;
    } else {
      const err = await res.text();
      if (err.includes('NOT_FOUND') || err.includes('UNREGISTERED')) {
        // Prune the dead token.
        fetch(`${FIRESTORE_BASE}/users/${uid}/fcmTokens/${doc.name.split('/').pop()}`,
          {method: 'DELETE', headers: {Authorization: `Bearer ${token}`}}).catch(() => {});
      }
    }
  }
  return {sent};
}

export default {
  async fetch(request, env) {
    const cors = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization,content-type',
      'Access-Control-Allow-Methods': 'POST,OPTIONS',
    };
    if (request.method === 'OPTIONS') {
      return new Response(null, {status: 204, headers: cors});
    }
    if (request.method !== 'POST' || new URL(request.url).pathname !== '/notify') {
      return Response.json({error: 'not found'}, {status: 404, headers: cors});
    }

    try {
      const projectId = env.FIREBASE_PROJECT_ID;
      const auth = request.headers.get('Authorization') || '';
      const idToken = auth.startsWith('Bearer ') ? auth.slice(7) : '';
      const caller = await callerIdentity(idToken, projectId);
      if (!caller) {
        return Response.json({error: 'unauthenticated'}, {status: 401, headers: cors});
      }

      const {studentUid, requestId, kind} = await request.json();
      if (!studentUid || !requestId) {
        return Response.json({error: 'bad request'}, {status: 400, headers: cors});
      }

      const token = await serviceAccountToken(env);
      const reqDoc = await firestoreGet(
        `users/${studentUid}/proRequests/${requestId}`,
        token,
      );
      if (!reqDoc) {
        return Response.json({error: 'request not found'}, {status: 404, headers: cors});
      }
      const fields = docToFields(reqDoc);
      const proUid = fields.professionalId;
      const msgs = fields.messages || [];
      const lastMsg = msgs[msgs.length - 1]?.mapValue?.fields || {};

      const callerIsStudent = caller.uid === studentUid;
      const callerIsPro = proUid && caller.uid === proUid;
      const callerIsAdmin = !callerIsStudent && !callerIsPro
        ? await isAdmin(caller.uid, caller.email, token)
        : false;

      if (!callerIsStudent && !callerIsPro && !callerIsAdmin) {
        return Response.json({error: 'forbidden'}, {status: 403, headers: cors});
      }

      const body = String(fs(lastMsg.text) || '').slice(0, 120);

      // Match notification: caller asked us to tell the student they're matched.
      let result;
      if (callerIsStudent && proUid) {
        result = await sendToUser(
          proUid,
          'A student needs you',
          body || `${fields.topic || 'Support request'} — ${fields.timeWindow || ''}`,
          '/my-cases',
          token,
          projectId,
        );
      } else {
        const title = kind === 'matched'
          ? 'You were matched'
          : 'New message in your support request';
        result = await sendToUser(
          studentUid,
          title,
          body || `${fields.professionalName || 'Your volunteer'} is ready to talk.`,
          '/support',
          token,
          projectId,
        );
      }
      return Response.json({ok: true, ...result}, {headers: cors});
    } catch (err) {
      return Response.json({error: String(err)}, {status: 500, headers: cors});
    }
  },
};
