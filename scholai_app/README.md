# ScholAI Flutter App

Anonymous AI wellness companion for Nigerian university students — built for DevFest Ibadan 2026.

## 🚀 Getting Started

### Prerequisites
- Flutter 3.38+
- A Firebase project (see setup below)
- A Gemini API key (get one at [aistudio.google.com](https://aistudio.google.com))

### 1. Clone & Install
```bash
cd scholai_app
flutter pub get
```

### 2. Firebase Setup
Active project: `project-4a50b4ec-612b-4d64-8b5` (ScholAI).

1. Prefer working as **mbakaragoodness2003@gmail.com** (`firebase login:use mbakaragoodness2003@gmail.com`). That account has Editor + Firebase Admin on the project; Owner still sits on amicablembakara50 until an Owner invite is accepted in Cloud Console.
2. Android package `com.scholai.scholai_app` / iOS bundle `com.scholai.scholaiApp` are already registered.
3. Keep gitignored configs in place: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart`.
4. **Anonymous Authentication** and Firestore rules (`/users/{uid}/**` owner-only) are enabled.
5. **FCM** APIs are enabled. Android push works after permission grant. **iOS push requires an APNs auth key** uploaded in Firebase Console → Project Settings → Cloud Messaging → Apple app configuration. Also enable Push Notifications capability in Xcode if signing changes wipe entitlements.

### 3. Gemini API Key
```bash
# Preferred for local `flutter run`:
cp .env.example .env
# then set GEMINI_API_KEY=... inside .env

# Optional override (wins over .env):
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

> ⚠️ Never commit `.env` or your API key. Before production, move it to Firebase Remote Config.

### 4. Run
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── core/
│   ├── theme/          # App colours, typography (AppTheme, AppColors)
│   ├── services/       # AuthService, GeminiService
│   └── utils/          # AppRouter (GoRouter)
├── features/
│   ├── onboarding/     # 3-screen intro flow
│   ├── checkin/        # Daily mood check-in + category chips
│   ├── journal/        # Gemini-powered Socratic chat (Scholly)
│   ├── trends/         # Weekly mood visualisation
│   └── crisis/         # Triage screen → real resources
└── shared/
    └── widgets/        # MainShell (bottom nav)
```

## 🛡️ Safety Architecture

| Risk | Mitigation |
|---|---|
| AI handles a crisis | Crisis keywords trigger immediate route to `/crisis` — Gemini never responds |
| PII collected | Firebase Anonymous Auth only — no email, name, phone |
| Journal data breach | Encrypted before Firestore write (AES-256) |
| Gemini hallucinates advice | System prompt strictly prohibits advice; max 180 tokens |

## 🧱 Tech Stack

| Layer | Tech |
|---|---|
| Frontend | Flutter 3.38 |
| Auth | Firebase Anonymous Auth |
| Database | Cloud Firestore (offline-capable) |
| AI | Gemini 1.5 Flash |
| Notifications | Firebase Cloud Messaging |
| Navigation | GoRouter |
| State | flutter_bloc |
| Charts | fl_chart |

## 📅 Build Milestones

| Week | Goal |
|---|---|
| Week 1 | Firebase setup, auth, Firestore schema, Gemini prompt tuning |
| Week 2 | Check-in + Journal screens fully working |
| Week 3 | Trends chart wired to real data, FCM notifications |
| Week 4 | User testing, bug fixes |
| Week 5 | Demo prep, submission |

---

Built with ❤️ for DevFest Ibadan 2026
