# scholai-notify worker

Sends FCM push notifications for support-request threads — the free-tier
alternative to Cloud Functions (which need the Blaze plan).

## What it does

`POST /notify` with the caller's Firebase ID token. The worker:

1. Verifies the ID token via Google's `tokeninfo` (audience = this project).
2. Reads `users/{studentUid}/proRequests/{requestId}` with a service account.
3. Only allows the actual counterpart to ping: the student (→ notifies the
   matched pro at `/my-cases`), the matched professional (→ notifies the
   student at `/support`), or an admin/bootstrap email.
4. Sends FCM v1 to every `users/{target}/fcmTokens` token; prunes dead ones.

If the worker isn't configured (`NOTIFY_WORKER_URL` empty) or the call
fails, the app silently skips push — Firestore streams still sync open apps.

## One-time setup (~5 min)

```bash
cd notify-worker
npm install
npx wrangler login

# 1. Create a service-account key:
#    Firebase Console → Project settings → Service accounts → Generate new
#    private key → save the JSON.
# 2. Store it as a Worker secret (paste the whole JSON):
npx wrangler secret put FIREBASE_SA_KEY

npx wrangler deploy
# → prints https://scholai-notify.<account>.workers.dev
```

Then put that URL in `scholai_app/.env`:

```
NOTIFY_WORKER_URL=https://scholai-notify.<account>.workers.dev
```

(or pass `--dart-define=NOTIFY_WORKER_URL=...` at build time.)

## Required API scopes

The service account needs nothing extra in the console — the worker requests
`datastore` + `firebase.messaging` scopes, both covered by the default
Firebase Admin service account role.
