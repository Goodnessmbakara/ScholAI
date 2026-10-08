# ScholAI — Product Requirements Document

**Version:** 1.0  
**Date:** October 2026  
**Status:** Draft  
**Author:** [Your Name]  
**Target Event:** DevFest Ibadan 2026 Project Showcase (Demo: Nov 21, 2026)

---

## 1. Executive Summary

ScholAI is an anonymous, AI-powered academic wellness companion designed specifically for Nigerian university students. It addresses the documented mental health crisis in Nigerian tertiary institutions — particularly at the University of Ibadan — where a severe shortage of counselors (and heavy cultural stigma) prevents most students from seeking help.

ScholAI is **not** a therapy app. It is a **peer-first, stigma-free daily check-in and reflective journaling tool** that triages distress signals and connects students to real resources before crises escalate.

---

## 2. Problem Statement

### 2.1 The Real Problem

Nigerian university students are in crisis:

- **Documented shortage**: Nigeria has fewer than 300 practicing psychiatrists for 220 million people. University counseling centers are critically understaffed.
- **Stigma barrier**: The majority of students who experience mental health challenges never seek formal help. Seeking counseling is widely perceived as a sign of weakness or "madness."
- **Acute triggers**: Academic pressure (CGPA culture, professional courses like Law and Medicine), financial strain (rising cost of living, ASUU strikes disrupting plans), social media comparison, and isolation.
- **High-profile outcomes**: In late 2025, a University of Ibadan law student died — a tragedy that prompted the Vice-Chancellor to formally acknowledge the systemic mental health crisis on campus.

### 2.2 Why Existing Solutions Fail

| Existing Option | Why It Fails for Nigerian Students |
|---|---|
| University Counseling Center | Long waits, not anonymous, stigma of being seen entering |
| Western mental health apps (BetterHelp, Calm) | Expensive (\$60+/month), culturally tone-deaf, require stable internet |
| WhatsApp friends | No structure, no escalation path, burden shifts to peers |
| Doing nothing | The current default — and the most dangerous option |

### 2.3 The Gap ScholAI Fills

A lightweight, anonymous, culturally-aware first layer of support that:
1. Removes the stigma of "seeking help" by framing it as a daily habit
2. Uses AI to reflect — not advise — helping students process their own thoughts
3. Knows when to escalate and surfaces real resources without becoming a liability

---

## 3. Goals & Success Metrics

### 3.1 Goals

- **Primary**: Give Nigerian university students a private, stigma-free way to check in on their mental wellness daily
- **Secondary**: Detect early distress signals and route students to appropriate help before crisis
- **Tertiary**: Generate anonymized aggregate data that universities can use to understand campus stress patterns

### 3.2 Success Metrics (MVP — for DevFest showcase)

| Metric | Target |
|---|---|
| Daily check-in completion (demo users) | > 70% over 7 days |
| Crisis escalation accuracy (flagging vs. not flagging) | Tested against 20 synthetic scenarios |
| Time to complete daily check-in | < 60 seconds |
| App size (APK/Flutter) | < 15 MB |
| Works offline (journaling) | Yes — syncs when online |

---

## 4. Target Users

### 4.1 Primary User — "The Quietly Struggling Student"

- **Who**: 18–26 year old Nigerian undergraduate or postgraduate student
- **Context**: University of Ibadan (initial focus), expandable to any Nigerian university
- **Tech literacy**: Has a smartphone, uses WhatsApp daily, comfortable with apps
- **Key insight**: They *know* something is wrong but won't walk into a counseling center. They need a private, low-commitment entry point.

### 4.2 Secondary User — "The University Wellness Officer"

- **Who**: Student affairs / counseling center administrators
- **Need**: Aggregated, anonymized data on campus stress levels by faculty/week — without breaching student privacy
- **Interaction**: Dashboard (out of scope for MVP, future feature)

---

## 5. Core Features (MVP)

### 5.1 Feature 1 — Anonymous Onboarding

**Description**: Users create an account with zero personal information. No name, no email, no phone number.

**Behavior**:
- Firebase Anonymous Authentication — a unique, non-identifiable UID is generated
- User selects their faculty (optional, for aggregate data) and year of study
- Brief 3-screen onboarding explaining: "This is not therapy. This is your daily check-in. Everything is private."

**Acceptance Criteria**:
- [ ] Onboarding completes in under 90 seconds
- [ ] No PII collected at any point
- [ ] User can optionally choose to remain completely unclassified (skip faculty/year)

---

### 5.2 Feature 2 — Daily Mood Check-In (60 Seconds)

**Description**: A quick, emoji + color-based daily mood snapshot. No text required. Low friction is the entire point.

**Behavior**:
- Daily push notification: "Hey. How are you today?" (customizable time)
- 5-level mood scale with visual indicators (not clinical language — no "depressed," "manic")
- Optional: one-tap "what's most on your mind?" category selector (exams, money, relationships, family, nothing specific)
- Data stored to Firebase with timestamp

**UI Design Principles**:
- Warm, not clinical. Earthy colors, not medical whites/blues.
- Nigerian cultural tone — casual, like a friend asking, not a form

**Acceptance Criteria**:
- [ ] Check-in completes in under 60 seconds
- [ ] Works fully offline, syncs when back online
- [ ] No day's data is lost due to connectivity issues

---

### 5.3 Feature 3 — Gemini-Powered Reflective Journaling

**Description**: The core differentiator. After the mood check-in, users can optionally open a journaling session. ScholAI uses Gemini to *ask questions*, not give advice.

**Behavior**:
- User taps "Talk about it" → free-text or voice input
- Gemini responds with a **Socratic reflection prompt**, not advice:
  - ❌ "You should try deep breathing exercises."
  - ✅ "You mentioned exams are overwhelming. What feels most out of your control right now?"
- Conversation continues for up to 5 exchanges
- At the end: optional private journal save (stored encrypted in Firebase, user-only access)

**Gemini Prompt Engineering Strategy**:
- System prompt defines: "You are a reflective companion. Never give medical advice. Never diagnose. Ask one question at a time. Use warm, casual Nigerian-English tone. If the user expresses thoughts of self-harm or suicide, immediately pivot to the crisis response flow."
- Temperature: 0.7 (warm but grounded)
- Max tokens per response: 150 (keep it conversational, not essay-length)

**Acceptance Criteria**:
- [ ] Gemini never provides medical advice (validated with 50 test prompts)
- [ ] Responds in < 3 seconds on average (Gemini Flash model)
- [ ] Tone is casual and warm, not clinical
- [ ] Journal entries are encrypted at rest

---

### 5.4 Feature 4 — Crisis Triage & Resource Surfacing

**Description**: ScholAI detects distress signals and surfaces real-world resources. This is the ethical backbone of the product.

**Trigger Conditions** (any of the following):
- User selects the lowest two mood levels for 3+ consecutive days
- Gemini's response classifier detects self-harm language in journal input
- User manually taps "I need more help than this"

**Response Flow**:
1. ScholAI acknowledges: *"It sounds like things are really heavy right now. You don't have to go through this alone."*
2. Surfaces 3 resources (never just one):
   - University of Ibadan Counselling Centre — location, hours, phone
   - Nigeria Suicide Prevention Initiative (NSPI) crisis line: 0800-800-2000
   - A curated list of student-led peer support groups on campus
3. Asks: "Would you like me to remind you about this tomorrow?"
4. Does NOT attempt further AI conversation — exits gracefully

**Acceptance Criteria**:
- [ ] Crisis flow triggers correctly in 95%+ of test scenarios involving distress language
- [ ] Resources are verified and accurate at time of submission
- [ ] The AI never attempts to handle a crisis situation itself

---

### 5.5 Feature 5 — Personal Trend Visualization

**Description**: A simple, private view of the user's mood over time.

**Behavior**:
- Weekly summary: "Your mood was lowest on Tuesdays — this is the second week in a row."
- Visual: simple line/area chart (no clinical scoring)
- Optional Gemini-generated insight: "You seem to feel better after weekends. What do you do on weekends that helps?"

**Acceptance Criteria**:
- [ ] Chart renders correctly with 7 days of data minimum
- [ ] Insight is personalized to the user's actual pattern, not generic

---

## 6. Out of Scope (MVP)

The following are explicitly **not** in the MVP:

- ❌ Social/community features (comparing with other students, leaderboards)
- ❌ University admin dashboard (aggregated data view)
- ❌ Therapist matching or paid counseling
- ❌ SMS/USSD fallback (future — for non-smartphone users)
- ❌ Multi-language support (Yoruba, Pidgin) — future iteration
- ❌ Wearable/biometric integration

---

## 7. Technical Architecture

### 7.1 Tech Stack

| Layer | Technology | Reason |
|---|---|---|
| Frontend | Flutter (iOS + Android) | Cross-platform, Google stack bonus, fast UI |
| Auth | Firebase Anonymous Auth | Zero PII, instant onboarding |
| Database | Firebase Firestore | Real-time sync, offline persistence built-in |
| AI / NLP | Gemini 1.5 Flash API | Fast, low-latency, affordable, multimodal ready |
| Notifications | Firebase Cloud Messaging (FCM) | Daily check-in reminders |
| Hosting (future dashboard) | Google Cloud Run | Serverless, scalable |
| Encryption | AES-256 (Flutter encrypt package) | Journal entries encrypted before Firestore write |

### 7.2 Architecture Diagram

```
┌─────────────────────────────────────────────┐
│                  Flutter App                │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐ │
│  │ Check-in │  │ Journal  │  │  Trends   │ │
│  │   UI     │  │   UI     │  │    UI     │ │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘ │
└───────┼─────────────┼──────────────┼────────┘
        │             │              │
        ▼             ▼              │
┌───────────────┐  ┌──────────────┐  │
│   Firebase    │  │ Gemini Flash │  │
│  Firestore    │  │    API       │  │
│  (offline     │  │ (Socratic    │  │
│   capable)    │  │  prompting)  │  │
└───────────────┘  └──────────────┘  │
        │                            │
        └────────────────────────────┘
                Mood data → Trend chart
```

### 7.3 Data Privacy Architecture

- **Anonymous UID only** — Firebase generates a random UID, no email/phone linked
- **Journal entries encrypted** — encrypted with AES-256 on-device before writing to Firestore. Firebase cannot read them. We cannot read them.
- **No cross-user data sharing** — each user's data is namespaced under their UID
- **Gemini API calls** — journal text is sent to Gemini API. Gemini's data usage policy (no training on API data) applies. This must be disclosed to users.
- **Right to delete** — users can wipe all their data from within the app in one tap

---

## 8. Design & UX Principles

1. **Warm, not clinical** — The app should feel like a friend who checks in, not a hospital intake form
2. **Minimum friction** — Every extra tap is a student who gives up. Keep core flows to 3 taps max.
3. **Nigerian English first** — Casual, direct, warm. "How far?" energy, not "How are you feeling today on a scale of 1-10?"
4. **No gamification of wellness** — No streaks for check-ins, no badges for journaling. This is not Duolingo.
5. **Dark mode by default** — Students use phones at night; 2am check-ins should not blast their eyes

---

## 9. Ethical Considerations

This section is critical and must be addressed head-on at the showcase.

| Risk | Mitigation |
|---|---|
| App handles a crisis badly | Crisis flow is hardcoded — Gemini cannot override it. Any trigger → resources + exit. |
| False sense of security | Onboarding makes scope explicit: "This is not therapy or a crisis line." |
| Data breach exposes vulnerable students | Anonymous auth + end-to-end encrypted journals = even a full breach reveals nothing identifiable |
| Gemini hallucinates bad advice | Strict system prompt + response validation. App tested with 50+ adversarial prompts before submission |
| Students rely on it instead of real help | Every 14 days, the app surfaces: "Have you spoken to anyone in person recently?" |

---

## 10. 5-Week Build Plan

| Week | Dates | Milestone |
|---|---|---|
| **Week 1** | Oct 8–14 | Firebase setup, Flutter project scaffold, Anonymous Auth, Firestore schema, Gemini API prompt engineering (this is the hardest part — nail the tone) |
| **Week 2** | Oct 15–21 | Daily check-in UI + Firestore write, Gemini journal flow working end-to-end, basic crisis trigger logic |
| **Week 3** | Oct 22–28 | Trend visualization, FCM push notifications, encryption for journal entries, UI polish |
| **Week 4** | Oct 29–Nov 1 | **SUBMISSION DEADLINE NOV 1** — User testing (5–10 real students at UI), fix critical bugs, write 2-min demo script |
| **Week 5** | Nov 2–20 | Post-submission polish, prepare live demo, rehearse pitch for Nov 21 showcase |

> ⚠️ **Golden Rule**: By end of Week 2, the Gemini journaling conversation must work. That is the demo centerpiece. Everything else is secondary.

---

## 11. Demo Script (2-Minute Showcase)

**Hook (15 sec)**: "A student at this university died last year. The Vice-Chancellor acknowledged a mental health crisis. And the most common solution? 'Talk to someone.' But who? When the counselor has 3,000 students and the stigma means you won't walk through that door?"

**Problem (20 sec)**: Quick stat on counselor-to-student ratios. Show a WhatsApp message of a student venting to a friend — the wrong escalation path.

**Demo (60 sec)**:
1. Open ScholAI → Tap mood (low) → select "Exams" category [15 sec]
2. Tap "Talk about it" → type "I haven't slept in 3 days and I don't see the point" [10 sec]
3. Show Gemini's reflective response: *"That sounds really exhausting. What would feel like a small relief right now?"* [15 sec]
4. Show the trend visualization — "Your lowest days are always before your 400L seminars" [10 sec]
5. Show crisis trigger → resources appear [10 sec]

**Differentiation (15 sec)**: Anonymous. Encrypted. Nigerian-tone AI. Built for this campus.

**Call to action (10 sec)**: "We want to pilot this with UI's counseling center next semester. The app is live. You can download it now."

---

## 12. Submission Checklist (Nov 1)

- [ ] Project name: **ScholAI**
- [ ] Short description: *AI-powered anonymous mental wellness companion for Nigerian university students*
- [ ] Problem it solves: Mental health crisis + counselor shortage + stigma at Nigerian universities
- [ ] Demo link / repo: [GitHub link TBD]
- [ ] 2-minute demo video recorded
- [ ] Tech stack: Flutter, Firebase (Auth, Firestore, FCM), Gemini 1.5 Flash API, Google Cloud
- [ ] Team members listed

---

*Document maintained in: `/Desktop/ScholAI/PRD.md`*  
*Next review: After Week 2 build milestone*
