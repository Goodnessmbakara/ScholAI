# ScholAI — Brand Identity & Design Toolchain

**Document type:** Design Briefing + Tool Research  
**Last updated:** October 2026  
**Purpose:** Define the exact tools needed, what each one does, and what to hand over so design work can begin immediately.

---

## 🧠 First — What "Brand Identity" Means for ScholAI

Before tools, here's what we're actually building. Brand identity for a mobile app = 6 components:

| Component | What It Is | Who Uses It |
|---|---|---|
| **Logo** | The mark — wordmark, icon, or both | App icon, splash screen, pitch deck |
| **Colour System** | Exact hex values + semantic rules | Flutter `AppColors`, all UI |
| **Typography** | Font family + scale (H1→caption) | Every screen, every label |
| **Iconography** | Icon set style — line, filled, rounded | All buttons, nav, actions |
| **Illustration style** | How characters/scenes look | Onboarding, empty states |
| **Motion language** | How things animate + feel | Transitions, loading, feedback |

We already have a rough colour system in the code. Everything else needs to be designed.

---

## 🛠️ The Tools — What You Need to Get, What I Can Use

### Tier 1 — MUST HAVE (Give me access to these)

---

#### 1. 🎨 Figma (Free tier is enough)
**What it is:** The industry-standard UI design tool. Every screen mockup lives here.  
**Why it's non-negotiable:** It's what I need to reference designs from, and what you need to communicate design decisions visually.  
**Cost:** Free tier — unlimited files for personal use  
**Get it at:** [figma.com](https://figma.com) → sign up free  

**What to do after signing up:**
1. Create a new file called `ScholAI Design System`
2. Share the link with me (just paste it here) — I can read Figma files and use them to generate pixel-perfect Flutter code

> **If you already have Figma** — just share the project link. That's all I need.

---

#### 2. 🤖 Recraft (Free tier — for the logo)
**What it is:** The best AI tool for generating **editable vector logos (SVG)**. Not a PNG — an actual editable vector file.  
**Why it matters:** ScholAI's logo needs to work at 16px (app icon) AND at display size (pitch deck). Only vectors do this cleanly.  
**Cost:** Free tier gives 50 generations/day  
**Get it at:** [recraft.ai](https://recraft.ai)  

**What to generate:**
- Style: `Flat vector`, `Minimalist`, `Single colour`
- Prompt directions (we'll refine together): abstract mark suggesting warmth, openness, reflection — NOT a brain, NOT a heart, NOT a chat bubble (all overused in mental health)
- Download as: **SVG + PNG (1024x1024)**

---

#### 3. 🎭 LottieFiles (Free)
**What it is:** Library of pre-made Lottie animations (.json files) that drop directly into Flutter apps.  
**Why it matters:** ScholAI needs at least 3 animations: loading state, onboarding illustrations, check-in confirmation ("logged! ✓"). Hand-crafted animations = weeks of work. LottieFiles = minutes.  
**Cost:** Free  
**Get it at:** [lottiefiles.com](https://lottiefiles.com)  

**What to download (search terms):**
- `"breathing"` or `"calm"` — for loading states
- `"plant growing"` or `"seedling"` — for the companion/growth metaphor
- `"check success warm"` — for check-in confirmation
- **File format:** `.json` (Lottie, not GIF)
- **Colour filter:** Download ones that use warm orange/earth tones, OR ones that are single-colour (easiest to recolour in code)

---

### Tier 2 — RECOMMENDED (Strong advantage, still free)

---

#### 4. 🔤 Google Fonts (Already integrated — just pick)
**What it is:** Google's free font library — already in the Flutter project.  
**Current code uses:** `DM Sans` (good choice — clean, modern, readable)  
**What you need to decide:**

Pick ONE heading font pairing from below (I'll implement whichever you choose):

| Option | Heading Font | Body Font | Vibe |
|---|---|---|---|
| **A (Recommended)** | `Plus Jakarta Sans` | `DM Sans` | Modern West African creative energy |
| **B** | `Bricolage Grotesque` | `DM Sans` | Bold, editorial, expressive |
| **C** | `Fraunces` (serif) | `DM Sans` | Warm, literary, trustworthy |
| **D** | `Sora` | `Inter` | Clean tech, neutral, safe |

> Preview all at [fonts.google.com](https://fonts.google.com) — type "ScholAI" in the preview box and compare.

**My recommendation: Option A — Plus Jakarta Sans + DM Sans.** It's bold without being aggressive, very popular in Nigerian design circles right now, and it reads beautifully on AMOLED dark screens.

---

#### 5. 🎨 Phosphor Icons (Free, Flutter-compatible)
**What it is:** A beautifully consistent icon set with 1,200+ icons in multiple weights (thin/regular/bold/fill).  
**Why not Material Icons:** Material icons look generic. Phosphor has personality while remaining clean.  
**Flutter package:** `phosphor_flutter` — drop-in replacement for `Icons.x`  
**Get it at:** [phosphoricons.com](https://phosphoricons.com) (browse), or just add to pubspec  

**Icon style for ScholAI:** Use `regular` weight for nav/UI + `fill` for selected/active states.

---

#### 6. 🖼️ unDraw (Free SVG illustrations)
**What it is:** Open-source illustration library — you pick a colour and download matching SVGs.  
**Why it matters:** Empty states, onboarding screens, and the "no journal entries yet" screen all need illustrations. Drawing these from scratch takes days.  
**Get it at:** [undraw.co](https://undraw.co)  
**Colour to use:** Set the accent colour to `#B85C38` (ScholAI terracotta primary)  

**Illustrations to download:**
- `"meditation"` → Onboarding screen 2 (Scholly intro)
- `"personal data"` or `"privacy"` → Onboarding screen 3 (privacy)
- `"feeling happy"` or `"mindfulness"` → Empty state on Trends screen
- `"mental health"` → Check-in empty state

---

### Tier 3 — OPTIONAL BUT POWERFUL

---

#### 7. ✨ Google Stitch (formerly Galileo AI) — For AI-generated screen mockups
**What it is:** Generates full, high-fidelity mobile app screens from a text prompt, exports as editable Figma layers.  
**Why it's useful:** Instead of designing every screen in Figma manually, you describe it and get a starting point.  
**Cost:** Paid (starts ~\$19/month) — only worth it if you want to move very fast  
**Get it at:** [stitch.withgoogle.com](https://stitch.withgoogle.com)  

**Alternative (free):** Use [Uizard](https://uizard.io) — upload a hand-drawn sketch photo, it converts to a UI mockup.

---

#### 8. 🎨 Penpot (Free Figma alternative — if you prefer open source)
**What it is:** Open-source, browser-based design tool. Fully free, no storage limits.  
**When to use:** If you don't want to use Figma, Penpot is the best alternative.  
**Get it at:** [penpot.app](https://penpot.app)

---

## 🎯 What I Can Do RIGHT NOW (No Extra Tools Needed)

Here's what I can produce immediately, today, without you needing to set up anything:

| Deliverable | How | Quality |
|---|---|---|
| **Logo concept images** | AI image generation (built into my workflow) | High — multiple options to choose from |
| **Full colour system spec** | Already partially done in `AppColors` | Production-ready |
| **Typography scale** | Dart `TextTheme` code | Production-ready |
| **App icon design** | AI image generation → export | Needs vector trace (Recraft) |
| **Onboarding screen mockup** | AI image generation | High-fidelity preview |
| **Flutter design tokens** | Direct code in `app_theme.dart` | Production-ready |
| **All screen UI** | Flutter code from mockups | Ready to run |

---

## 📋 The Hand-Off Checklist (What I Need From You)

Once you've set up the tools above, hand me these things and I can build everything else:

### ✅ Required (blocks design work without these)
- [ ] **Font decision** — pick A, B, C, or D from the typography table above
- [ ] **Logo direction** — describe in 1-2 sentences what the ScholAI icon should feel like (I'll generate 4 options for you to choose from)
- [ ] **Recraft SVG logo** — once you generate/choose a logo on Recraft, download the SVG and share it here

### 🔶 Recommended (makes everything much better)
- [ ] **Figma link** — create a file, share with me. Even an empty one is fine — I'll populate it.
- [ ] **LottieFiles downloads** — download the 3 animations listed above, drop them in `scholai_app/assets/animations/`
- [ ] **unDraw SVG downloads** — download 4 illustrations listed above, drop in `scholai_app/assets/images/`

### 💡 Optional (nice to have)
- [ ] **Reference apps you like visually** — screenshot 2-3 apps whose *look and feel* you love (doesn't have to be mental health apps). This is the most valuable design brief you can give me.

---

## 🔮 What Happens After Hand-Off

Once I have the above, here's what I build immediately:

```
Day 1  → Complete design tokens (colours, typography, spacing, radius) in Flutter
Day 1  → App icon + splash screen (from your logo SVG)
Day 2  → Onboarding screens (3 screens with illustrations + animations)
Day 2  → Check-in screen (polished mood selector, final typography)
Day 3  → Journal screen (Scholly chat UI, bubble styling, typing animation)
Day 3  → Trends screen (fl_chart line chart, insight cards)
Day 4  → Crisis screen (final polish)
Day 4  → Icon set integrated (Phosphor), empty states with unDraw illustrations
Day 5  → Full app review pass — spacing, shadows, micro-interactions
```

---

## 📌 Priority Order (What To Do Right Now)

1. **Sign up for Figma** (5 mins) → [figma.com](https://figma.com)
2. **Pick a font** (2 mins) → Preview at fonts.google.com, tell me A/B/C/D
3. **Generate logo on Recraft** (15 mins) → [recraft.ai](https://recraft.ai)
4. **Tell me what you want the icon to feel like** → 1-2 sentences
5. **Download Lottie animations** (10 mins) → [lottiefiles.com](https://lottiefiles.com)
6. **Download unDraw illustrations** (5 mins) → [undraw.co](https://undraw.co) with hex `#B85C38`
7. **Share the Figma link + SVG logo here** → I build immediately

> ⚡ If you do steps 1–4 right now, I can generate logo options + a full colour/typography spec within the next 15 minutes.

---

*Document maintained in: `/Desktop/ScholAI/BRAND_TOOLS.md`*
