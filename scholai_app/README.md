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
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project called `scholai`
3. Add an Android app (`com.scholai.scholai_app`) and an iOS app
4. Download `google-services.json` → place in `android/app/`
5. Download `GoogleService-Info.plist` → place in `ios/Runner/`
6. Enable **Anonymous Authentication** in Firebase Console → Authentication → Sign-in methods
7. Create a **Firestore** database in test mode

### 3. Gemini API Key
```bash
# Run with your key passed as a Dart define:
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

> ⚠️ Never commit your API key. Before production, move it to Firebase Remote Config.

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
