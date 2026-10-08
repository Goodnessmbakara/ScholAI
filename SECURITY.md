# ScholAI — Security & Privacy Architecture Spec

**Version:** 1.0  
**Security Level:** Zero-Knowledge, Zero-PII  
**Target:** DevFest Ibadan 2026 / Institutional Privacy Review  

---

## 1. Threat Model & Cultural Context

In Nigerian university settings, mental health carries heavy social and institutional stigma. If a student's personal distress reflections were ever exposed to peers, lecturers, or university administrators, the consequences could include social ostracization, academic discrimination, or victim-blaming.

**Our Core Security Thesis:**  
> ScholAI is architected so that **even if our entire cloud database is compromised, an attacker learns zero names and cannot read a single journal entry.**

---

## 2. The 5 Pillars of ScholAI Security

```
┌────────────────────────────────────────────────────────────────────────┐
│ 1. ZERO PII IDENTITY                                                   │
│    No names, emails, phones, or student matriculation numbers.         │
│    Ephemeral Anonymous Firebase Auth token only.                       │
├────────────────────────────────────────────────────────────────────────┤
│ 2. ZERO-KNOWLEDGE CLIENT-SIDE ENCRYPTION (AES-256)                     │
│    Journal text encrypted on-device before writing to Cloud Firestore. │
│    Key stored in hardware enclave (Android Keystore / iOS Keychain).   │
├────────────────────────────────────────────────────────────────────────┤
│ 3. ENTERPRISE AI PRIVACY GUARANTEES                                    │
│    Gemini API terms strictly prohibit training on developer inputs.    │
│    Prompts are never used to train Google foundation models.           │
├────────────────────────────────────────────────────────────────────────┤
│ 4. STRICT DATABASE AUTHORIZATION (Firestore Rules)                     │
│    Users can ONLY read/write documents where request.auth.uid == uid.   │
│    No cross-collection listing or indexing permissions.                │
├────────────────────────────────────────────────────────────────────────┤
│ 5. CRYPTOGRAPHIC DATA WIPE                                             │
│    One-tap deletion permanently destroys the local AES key, rendering   │
│    all remote ciphertext permanently unrecoverable mathematical noise. │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Security Implementations

### 3.1 Client-Side AES-256 Encryption (`EncryptionService`)
- Implemented in: [`lib/core/services/encryption_service.dart`](file:///Users/abba/Desktop/ScholAI/scholai_app/lib/core/services/encryption_service.dart)
- Every user's device generates a cryptographically secure 256-bit AES master key upon initialization (`SecureRandom(32)`).
- The key is saved exclusively in the device's secure enclave:
  - **Android**: `EncryptedSharedPreferences` backed by hardware **Android Keystore**.
  - **iOS**: **Keychain** with `KeychainAccessibility.first_unlock`.
- Each journal message is encrypted with a distinct, randomly generated **16-byte Initialization Vector (IV)** to prevent pattern/frequency cryptanalysis.

#### What Firestore Actually Stores:
```json
{
  "ciphertext": "6p8s9K1FzD...a9x0=",
  "iv": "v8T9q1L2...z0A=",
  "timestamp": 1728416400000,
  "category": "Exams"
}
```
*Neither Google, Firebase engineers, nor database admins have the key to decrypt this ciphertext.*

---

### 3.2 Cloud Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users can access their own document sandbox
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Deny all other access by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

### 3.3 Gemini API Privacy Policy
Unlike consumer tools (ChatGPT web or consumer Gemini), Google's **Gemini Developer API** operates under enterprise terms:
1. Google **does not** use API customer prompts or responses to train Gemini foundation models.
2. Data in transit is secured with **TLS 1.3**.
3. ScholAI does not store conversational session history on external servers.

---

### 3.4 Local Privacy & Logging (`AppLogger`)
- Implemented in: [`lib/core/utils/app_logger.dart`](file:///Users/abba/Desktop/ScholAI/scholai_app/lib/core/utils/app_logger.dart)
- `kReleaseMode` automatically suppresses all verbose and debug logs.
- Strict development guideline: Emotional text and journal content are **never** passed into log statements or crash reporting tools.

---

### 3.5 Cryptographic Wipe (Self-Destruct)
If a student wishes to delete their history:
1. `EncryptionService.instance.cryptographicallyWipeData()` wipes the master key from the device's secure enclave.
2. Even if remote Firestore records take seconds to delete over slow networks, they become mathematically impossible to decipher immediately.

---

## 4. Test Verification
The encryption engine is actively verified by the test suite:
- **Test File:** [`test/unit/encryption_test.dart`](file:///Users/abba/Desktop/ScholAI/scholai_app/test/unit/encryption_test.dart)
- Verified: Correct plaintext recovery, distinct IV generation per message, and tamper resistance against invalid keys.
