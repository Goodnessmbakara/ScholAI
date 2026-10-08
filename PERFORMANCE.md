# ScholAI — Speed, Latency & Performance Optimization Blueprint

**Target Context:** Nigerian Mobile Networks (MTN, Airtel, Glo 3G/4G) + Budget/Mid-range Android Devices (Tecno, Infinix, Redmi) + Live DevFest Stage Demo

---

## 1. The Latency Problem Breakdown

| Latency Bottleneck | The Risk | ScholAI Strategy | Target SLA |
|---|---|---|---|
| **AI Generation Latency** | Waiting 3–6s for a complete response feels unresponsive or frozen. | **Token Streaming (`sendMessageStream`)** — Time-to-First-Token appears in ~400ms. | `< 500ms` first word |
| **Network Fluctuation** | Spotty 3G/4G network drops requests in hostels or lecture halls. | **Optimistic UI Updates + Offline Firestore Cache**. | `0ms` (Instant local save) |
| **App Cold Start (TTID)** | Blank screen while awaiting cloud services. | **Non-blocking bootstrap** + zero network calls in `main()`. | `< 1.2s` on budget Android |
| **Asset Load Stutter** | Image pop-in on onboarding swipe or trends screen. | **`precacheImage`** in splash lifecycle. | `0ms` pop-in |
| **UI Frame Drops (Jank)** | Rebuilding entire widget trees on every chat token. | **Granular BLoC rebuilds** + `const` constructors + `RepaintBoundary`. | `60 fps` steady |

---

## 2. Approach 1: Streaming AI Inference (Gemini Stream)

### The Difference:
- **`sendMessage()` (Blocking)**:
  `User sends text ──[Wait 3.5s]──> Full paragraph appears all at once.`
- **`sendMessageStream()` (Streaming)**:
  `User sends text ──[350ms]──> "That" ──[50ms]──> " sounds" ──[50ms]──> " really" ──[50ms]──> " heavy..."`

### Why This Matters for the Live DevFest Demo:
When you are on stage at DevFest Ibadan with hundreds of people watching, a 4-second loading spinner feels like an eternity and risks Wi-Fi congestion. With streaming, the AI begins responding almost before your thumb leaves the screen.

---

## 3. Approach 2: Optimistic UI & Zero-Latency Local Writes

Every user action must render **optimistically at 0ms latency**:
1. When a student logs their mood in the check-in screen:
   - UI instantly ticks `✓ Logged!` with haptic feedback.
   - Entry is committed immediately to the on-device encrypted cache.
   - Background sync pushes the ciphertext to Firestore whenever an internet connection is established.
2. When a student types a message in the journal:
   - The user's chat bubble appears immediately in the list (`0ms`).
   - The input text field clears immediately.
   - The typing indicator mounts below it while streaming initiates.

---

## 4. Approach 3: Firestore Offline Persistence Config

In Flutter, Cloud Firestore supports hardware-backed persistent caching:
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```
- Even if the student enters the UI library with zero signal or turns off their data to save battery, they can journal and review trends without interruption.
- Syncs automatically when back online.

---

## 5. Approach 4: Image & Asset Optimization

1. **Pre-caching**:
   ```dart
   @override
   void didChangeDependencies() {
     super.didChangeDependencies();
     precacheImage(const AssetImage('assets/images/onboarding_welcome.jpg'), context);
     precacheImage(const AssetImage('assets/images/onboarding_companion.jpg'), context);
     precacheImage(const AssetImage('assets/images/onboarding_privacy.jpg'), context);
   }
   ```
2. **Decoded Dimensions**:
   Avoid decoding a 2048x2048 image into GPU memory if it's only rendered at 240px height. Use `ResizeImage` or optimal asset sizing to keep RAM footprint `< 80MB`.

---

## 6. Approach 5: Render Tree Performance & Repaint Boundaries

- Wrap the animated typing indicator in a `RepaintBoundary` so 60fps dot bouncing doesn't trigger redraws on the entire chat history.
- Use `ListView.builder` (never `SingleChildScrollView` + `Column`) for chat and trends, recycling views outside the viewport.
