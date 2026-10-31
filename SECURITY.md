# ScholAI — Security & Privacy Architecture Spec

**Version:** 1.1 (corrected to match shipped code)
**Target:** DevFest Ibadan 2026 / Institutional Privacy Review

---

## 1. Threat Model & Cultural Context

In Nigerian university settings, mental health carries heavy social and
institutional stigma. If a student's personal distress reflections were ever
exposed to peers, lecturers, or university administrators, the consequences
could include social ostracization, academic discrimination, or victim-blaming.

**Security posture (as actually implemented):**

- The journal transcript is **never written to ScholAI's own database**. It
  exists only in memory on the device and inside the Gemini API request/response.
- Sensitive state (habit plans, urge logs, saved check-ins, onboarding flag,
  local mirror of support requests) lives in app-private storage on the device.
- Cloud Firestore holds only: the anonymous account record, FCM tokens,
  support requests (explicitly consented as non-anonymous), professional
  applications/listings, and conversation abuse reports.

---

## 2. Identity & PII

- Anonymous Firebase Auth by default — no name, email, or phone required.
- Optional "Continue with Google" links the Google account to the *same*
  Firebase UID, so cloud data follows the account across devices.
- Support requests are **not anonymous by design** — the intake form requires
  explicit consent, and the topic/note/contact preference are visible to the
  matched volunteer and platform admins.

## 3. Gemini data flow (honest version)

- Journal messages, urge-reflection prompts (habit + intensity + outcome),
  and live voice audio are sent to the **unpaid Gemini Developer API**.
- Under Google's current unpaid-service terms, Google **may** use those
  inputs to improve its products and human reviewers may read them after
  de-identification. The in-app privacy policy states this plainly; students
  should not type or say things they need kept from that process.
- ScholAI keeps no server-side copy of journal text or audio.

## 4. Firestore authorization

`firestore.rules` enforces, server-side:

- `users/{uid}` — read by owner or admins; role changes restricted so an
  owner can never change their own role.
- `users/{uid}/**` private subcollections — owner-only read/write.
- `users/{uid}/proRequests/{id}` — owner + admins read; admins may update
  (assignment, staff replies). Only admins can mutate another user's request.
- `professionalApplications/{uid}` — owner creates/updates only while
  `pending`; admins review.
- `professionals` — any signed-in user reads the roster; only admins write.
- `conversationReports` — shape-validated create (reporter = caller, bounded
  field sizes, status `open`); admins read and mark `reviewed`.
- Catch-all `match /{document=**}` — default deny.

## 5. On-device encryption

`EncryptionService` (AES-256-CBC, random IV per record, key in Android
Keystore / iOS Keychain) exists and is unit-tested for any future
encrypted-at-rest cloud writes. Today **no network payload uses it** —
nothing sensitive is written to the cloud to begin with. Its
`cryptographicallyWipeData()` is wired to Settings → "Erase data on this
device".

## 6. Local data & backups

- `android:allowBackup="false"` — habit logs, check-in history, and the local
  request mirror cannot be extracted via `adb backup` or auto-restore.
- `AppLogger` suppresses debug logs in release builds; journal/emotional text
  is never passed to log statements by convention.
- Local notifications and the daily reminder are scheduled on-device; the FCM
  token is stored under the user's own doc for the messaging service only.

## 7. Known limitations & recommended follow-ups

| Risk | Status | Mitigation |
|------|--------|------------|
| Gemini API key ships inside the app bundle (`.env` asset or `--dart-define`) | Accepted for MVP | Restrict the key by Android app signature in Google Cloud; longer-term, move to Firebase AI Logic + App Check or a Cloud Functions proxy |
| No Firebase App Check | Open | Enable App Check + Play Integrity to stop Firestore abuse from outside the app |
| Support-request creation has no rate limit | Open | App Check (above); optionally a Cloud Function gate |
| Anonymous UID is the only auth boundary | By design | A stolen device + unlocked app = readable local data; OS-level lock is the mitigation |
| Staff replies are plaintext on the student doc | By design | Support threads are non-anonymous; do not share clinical detail there |

## 8. Test verification

- `test/unit/encryption_test.dart` — AES round-trip, unique IVs, wrong-key
  tamper failure.
- `test/unit/platform_role_test.dart` — role parsing + bootstrap admin gates.
- `test/unit/crisis_detection_test.dart` — crisis keyword divert coverage.
