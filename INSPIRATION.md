# ScholAI — Inspiration & Reference Projects

**Document type:** Research Reference  
**Last updated:** October 2026  
**Purpose:** Projects to study, steal UX patterns from, and learn from — for ScholAI development

---

## How to Use This Document

For each project below, I've noted:
- **What to steal** — specific patterns or features to adapt
- **What to avoid** — where they got it wrong for our context
- **Links** — where to find the code/app

The goal is *not* to clone any of these. It's to understand the best decisions each one made and make them your own in a Nigerian, university, mobile-first context.

---

## 🌍 Category 1 — Direct Competitors (Nigerian/African Market)

---

### 1. Nguvu Health
**What it is:** Nigerian teletherapy platform. Text, audio, video therapy. Has a "Rant Room" — free, anonymous emotional release space.  
**Website:** nguvu.health  

#### What to steal:
- ✅ **The "Rant Room" concept** — an anonymous, freeform space with zero commitment is exactly the kind of entry point ScholAI needs. It's a brilliant low-friction on-ramp.
- ✅ **Flexible, multi-format communication** — not forcing text-only is smart for Nigerian users who may prefer voice

#### What to avoid:
- ❌ They require connecting with paid therapists eventually — creates a payment wall that Nigerian students will bounce off
- ❌ Their branding is quite formal/clinical — not the warm tone we need

#### Lesson for ScholAI:
> The "Rant Room" = our free-text journal. Anonymous, no commitment, no therapist needed. That's a proven entry point — use it.

---

### 2. Fafa (Node Eight, Ghana — March 2026)
**What it is:** Mobile app from Ho, Ghana. Safe, confidential space for young people to share thoughts anonymously, access curated mental health resources, and connect with counselors.  
**Why it matters:** This is the closest competitor to ScholAI in West Africa. Built in 2026, so it's fresh.

#### What to steal:
- ✅ **Anonymity as a first-class feature** — they launched with this as the headline. Validates our direction.
- ✅ **Curated resources (videos, podcasts, blogs)** — passive content is a great low-commitment entry before active journaling
- ✅ **Community + professional path** — they show the spectrum from self-help → peer → professional

#### What to avoid:
- ❌ Connecting to counselors can scare off users who just want to vent. Don't make it feel like a referral funnel.
- ❌ Unknown how culturally specific it is to Nigeria vs. general West Africa

#### Lesson for ScholAI:
> Fafa proves the market exists in West Africa. But ScholAI's edge is: **Gemini-powered reflection** (not just passive content) + **specifically University of Ibadan** (hyper-local is stronger than regional).

---

### 3. Digital MindSKILLZ
**What it is:** Gamified mental health intervention. Works on ANY mobile phone via Interactive Voice Response (IVR) — no smartphone, no internet, no high literacy required.  
**Available in:** Nigeria and Ghana  

#### What to steal:
- ✅ **Voice as primary input** — IVR proves Nigerian users are comfortable with audio-first interactions. Future ScholAI v2 should consider Gemini Live API for voice journaling.
- ✅ **Gamification that doesn't trivialize** — they've found a balance. Study their structure.

#### What to avoid:
- ❌ IVR is a fallback, not a best experience. Our Flutter app should be better, not just a smartphone version of IVR.

---

## 🌐 Category 2 — Global Best-in-Class (UI/UX Inspiration)

---

### 4. Wysa
**What it is:** AI CBT chatbot. Originally consumer-facing, now mostly enterprise (employer/provider access). Used globally.  
**App Store:** Still findable. Study the interaction design.  

#### What to steal:
- ✅ **The "guardrailed AI" model** — Wysa uses LLMs for *classification* and *tone*, but the actual responses often follow pre-written clinical scripts. This is **exactly** how ScholAI's Gemini integration should work — AI is the engine, not a freestyle chatbot.
- ✅ **Crisis detection architecture** — their SOS keyword monitoring → instant resource escalation is the gold standard. Our crisis triage feature should mirror this.
- ✅ **Empathetic rewriter pattern** — a second layer that ensures responses stay warm and non-judgmental regardless of input

#### What to avoid:
- ❌ Their UI is quite Western and clinical. Cool blues, medical feel. ScholAI should be warmer, earthier.
- ❌ They moved enterprise-only = they abandoned their best users. Stay student-first.

#### Lesson for ScholAI:
> Wysa's architecture is the blueprint for safe AI in mental health. But their UX is dated and their market positioning abandoned real users. We can do both better.

---

### 5. Finch — Self-Care Pet
**What it is:** App where you have a virtual bird. You "take care" of it by completing self-care goals and check-ins. Hugely popular (Gen Z).  
**Download:** App Store / Play Store  

#### What to steal:
- ✅ **Emotional anchoring** — the pet creates a reason to return that isn't "you should track your mental health." It's softer, less clinical. ScholAI could use a subtle plant/companion element — nothing cheesy, just a living progress metaphor.
- ✅ **Low-friction micro check-ins** — Finch pioneered the idea that wellness tracking should take under 30 seconds. Their daily check-in is a single tap on a mood scale.
- ✅ **No guilt on missed days** — they explicitly do NOT have "streaks." If you miss 5 days, your bird is just... waiting. Not dead. This is *crucial* for mental health apps.

#### What to avoid:
- ❌ Full gamification (earning items, dressing your pet) — feels infantile for a university showcase. Take the principles, not the literal mechanic.
- ❌ English-only, Western color palette (pastel, very sweet). ScholAI needs to feel grounded, not sugary.

#### Lesson for ScholAI:
> No streaks. No shame for missing days. Make returning feel welcoming, not like catching up on a chore.

---

### 6. Woebot
**What it is:** AI CBT chatbot, originally Stanford research project. Now enterprise-only.  
**Research papers:** Publicly available — study these, not just the app.

#### What to steal:
- ✅ **Structured dialogue trees** — Woebot's original power wasn't the AI, it was the clinician-authored conversation trees. Even with Gemini, ScholAI should have *pre-authored scripts* for common scenarios (exam stress, financial pressure, loneliness) that Gemini enhances, rather than Gemini freestyling everything.
- ✅ **Naming the feeling before solving it** — Woebot never jumps to solutions. It first validates: "That sounds really frustrating." Then it asks: "What's the biggest part of this?" This is the pattern ScholAI's Gemini prompt must encode.
- ✅ **Short sessions** — Woebot sessions are 5-10 minutes max. Research shows longer = worse outcomes for emotional regulation in apps.

#### What to avoid:
- ❌ Their complete pivot to enterprise destroyed the product's soul. 
- ❌ Heavy CBT terminology bleeds through their UI occasionally ("cognitive distortions," "thought records") — this would bomb in a Nigerian university context. Keep language plain.

---

### 7. Reflectly
**What it is:** AI journaling app. Freemium, still active. Known for stunning visual design.  
**Website:** reflectlyapp.com  

#### What to steal:
- ✅ **Color-coded mood sliders** instead of numeric scales — "How are you?" on a 1-10 feels clinical. A gradient color from red to green with emoji anchors feels human.
- ✅ **Prompted journaling** — instead of a blank text box (terrifying to a student who's never journaled), they ask a specific question every day: *"What was the most meaningful moment today?"* This is the pattern for ScholAI's first journal prompt.
- ✅ **Visual trend graphs** — their weekly/monthly mood visualization is clean and non-judgmental. Shows patterns without scoring or grading the user.

#### What to avoid:
- ❌ Very Western, very "Instagram journal" aesthetic. Gradient pinks, cursive fonts. ScholAI needs a different visual identity.
- ❌ They monetize aggressively (most features paywalled). ScholAI must be fully free for students.

---

## 💻 Category 3 — Open Source Code References

---

### 8. Mental Health App — Fabrice-Fabio (GitHub)
**Repo:** [github.com/Fabrice-Fabio/mental-health-app](https://github.com/Fabrice-Fabio/mental-health-app)  
**Stack:** Flutter + Bloc + Node.js + **Gemini AI**  

#### What to steal:
- ✅ This is the closest open-source code reference to what ScholAI needs — it literally uses Gemini
- ✅ Study their Bloc state management pattern — clean architecture for complex emotional state flows
- ✅ Their Gemini prompt structure for mental health conversations

#### What to do with it:
> Clone the repo. Read the Gemini integration code. Don't copy it wholesale — understand how they structured the prompts and adapt it for a Socratic (question-based) rather than advice-based pattern.

---

### 9. MindHaven (GitHub)
**Repo:** [github.com/kauanhindlmayer/mental-health-app](https://github.com/kauanhindlmayer/mental-health-app)  
**Stack:** Flutter, journaling + mood tracking, privacy-conscious  

#### What to steal:
- ✅ Clean architecture separation (data / domain / presentation layers)
- ✅ Offline-first Firestore pattern
- ✅ Encrypted local storage implementation

#### What to do with it:
> Use as your **architecture template**. Their folder structure and layer separation is what you want to start from for a maintainable codebase.

---

### 10. EaseNeura (GitHub)
**Repo:** [github.com/santanamnaa/easeneura](https://github.com/santanamnaa/easeneura)  
**Stack:** Flutter, mental health tracking + specialist booking  

#### What to steal:
- ✅ UI components — their mental health tracking screens are well-designed
- ✅ Firebase integration patterns

#### What to avoid:
- ❌ The specialist-booking part is out of scope for ScholAI MVP

---

### 11. Anonymous Chat App — Rezuanul-Islam-Fahim (GitHub)
**Repo:** [github.com/Rezuanul-Islam-Fahim/anonymous_chat](https://github.com/Rezuanul-Islam-Fahim/anonymous_chat)  
**Stack:** Flutter + Firebase Anonymous Auth + Firestore  

#### What to steal:
- ✅ **The anonymous auth flow** — this is the exact Firebase Anonymous Auth implementation ScholAI needs. Study how they handle UID generation, session persistence, and Firestore data namespacing under anonymous UIDs.
- ✅ Real-time Firestore patterns

---

## 🎨 Category 4 — UX & Visual Design References

---

### 12. Headspace (Visual Language)
**Study at:** headspace.com  

#### What to steal:
- ✅ **Illustration style** — Headspace uses simple, warm, inclusive illustrations with diverse characters and muted earthy tones. No clinical imagery, no sad faces, no brain diagrams.
- ✅ **Typography** — large, rounded, readable. Not serif/formal, not tech-startup sharp. Friendly and accessible.
- ✅ **Empty states** — their empty state screens (when you haven't journaled yet, when there's no data) are warm and inviting, not cold system messages.

#### ScholAI application:
> Muted terracotta, warm olive, off-white backgrounds. Adire/ankara-inspired geometric accents (subtle, not costume-y). Large rounded font. Never blue-white clinical.

---

### 13. October Health (Institutional Wellness App)
**Won:** 2024 FNB App of the Year (Africa)  
**Website:** october.health  

#### What to steal:
- ✅ **How they pitch to institutions** — October Health is adopted by universities/employers who give it to users. ScholAI's path to UI's counseling center is the same B2B2C model. Study their institutional pitch.
- ✅ **AI coaching positioning** — they call it "AI-powered mental wellness coaching," not "therapy" or "chatbot." Language matters. ScholAI should similarly frame Gemini as a "reflection companion," not an "AI therapist."

---

## 📋 Quick Reference: What Each Project Teaches ScholAI

| Project | Primary Lesson |
|---|---|
| **Nguvu Health** | Rant Room = anonymous freeform entry point. Works. |
| **Fafa (Ghana)** | Anonymity-first is proven in West Africa. Be more local. |
| **Digital MindSKILLZ** | Voice input is the future for Nigeria. Plan v2 with Gemini Live. |
| **Wysa** | Guardrailed AI + crisis keyword detection = the safe architecture blueprint |
| **Finch** | No streaks. No shame. Companion energy, not performance tracking. |
| **Woebot** | Validate feeling first, solve second. Short sessions. No jargon. |
| **Reflectly** | Color-coded mood input. Prompted journaling (not blank text box). Trend graphs. |
| **Fabrice-Fabio repo** | Gemini + Flutter code to study directly |
| **MindHaven repo** | Clean architecture template to start from |
| **Anonymous Chat repo** | Firebase Anonymous Auth implementation |
| **Headspace** | Visual language — warm illustrations, earthy palette, inclusive |
| **October Health** | Institutional pitch model for approaching UI's counseling center |

---

## 🔑 The Synthesis: What ScholAI Does Differently Than All of Them

After studying all of the above, here's the clear gap ScholAI fills that none of them fully addresses:

1. **Gemini's Socratic questioning** — none of these apps use AI to *ask you better questions*. They either give advice (Wysa/Woebot) or give you a blank canvas (Reflectly). ScholAI's AI asks you one thoughtful question at a time until you arrive at your own clarity.

2. **University of Ibadan specificity** — none of these are built for a specific campus, a specific Nigerian city, a specific cultural context. That hyper-locality is both the risk (small initial TAM) and the superpower (resonates deeply with everyone in that audience).

3. **Nigerian cultural tone** — "How far? How you dey?" is not just language. It's a signal that this app was built by someone who actually understands you. None of the global apps get this.

4. **Crisis triage to *real, local resources*** — global apps surface generic crisis hotlines. ScholAI surfaces the UI Counselling Centre address, the NSPI Nigeria line, the specific peer support groups on that campus. That specificity is trust.

---

*Document maintained in: `/Desktop/ScholAI/INSPIRATION.md`*
