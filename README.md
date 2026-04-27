# 🍽️ Kitchen AI Inspector

> AI-powered food quality and kitchen hygiene inspection — built for Google Solution Challenge 2026

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Groq AI](https://img.shields.io/badge/Groq-Llama%204%20Scout-F55036?logo=groq)](https://groq.com)
[![Firebase](https://img.shields.io/badge/Firebase-Hosted-FFCA28?logo=firebase)](https://foodcheckai-89c88.web.app)
[![SDG 2](https://img.shields.io/badge/SDG-2%20Zero%20Hunger-DDA63A)](https://sdgs.un.org/goals/goal2)
[![SDG 3](https://img.shields.io/badge/SDG-3%20Good%20Health-4C9F38)](https://sdgs.un.org/goals/goal3)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

🌐 **Live Demo:** [foodcheckai-89c88.web.app](https://foodcheckai-89c88.web.app)
📦 **Repository:** [github.com/devkev2k6/FoodInspectionDevkev](https://github.com/devkev2k6/FoodInspectionDevkev)

---

## 📌 Problem Statement

Every year, **600 million people** fall ill from unsafe food — and over **420,000 die** as a result (WHO, 2022). In homes, small restaurants, and street kitchens across the developing world, there is no affordable, accessible way to verify food quality before it reaches a plate.

Professional food inspectors are expensive, scarce, and unavailable in real time. The result: contaminated, spoiled, or improperly prepared food silently harms millions of people who have no means to know any better.

**Kitchen AI Inspector solves this** by putting a professional-grade food quality inspector in everyone's pocket — completely free and powered by Groq's ultra-fast AI inference.

---

## 💡 Solution

Kitchen AI Inspector is a Flutter web app that uses **Groq's Llama 4 Scout multimodal vision model** to analyse photos of food plates and kitchen items in real time.

A user simply points their camera at a dish or ingredient, taps **Scan Plate**, and within seconds receives:

- A **PASS / FAIL** safety verdict
- A **hygiene score out of 100**
- A breakdown of specific **issues found** (contamination, spoilage, poor plating hygiene)
- Actionable **recommendations** to correct problems

No training required. No expensive equipment. No waiting for an inspector.

---

## 🌍 UN Sustainable Development Goals

### SDG 2 — Zero Hunger
> *"End hunger, achieve food security and improved nutrition, and promote sustainable agriculture"*

Food spoilage and contamination are among the leading causes of food waste globally. By identifying unsafe food **before it is served or discarded unnecessarily**, Kitchen AI Inspector helps:

- Reduce food waste from incorrectly identified spoilage
- Empower small food businesses and home cooks to maintain quality standards
- Enable safer food handling in communities with limited access to formal food safety education

### SDG 3 — Good Health and Well-Being
> *"Ensure healthy lives and promote well-being for all at all ages"*

Foodborne illnesses disproportionately affect low-income communities that cannot afford professional food safety services. Kitchen AI Inspector helps:

- Prevent foodborne illness by catching contamination before consumption
- Democratise access to food safety knowledge previously available only to large businesses
- Provide actionable health guidance instantly

---

## 📸 Screenshots

<!-- Add your screenshots here after UI update -->

| Home Screen | Inspection Result | Scan History |
|:-----------:|:-----------------:|:------------:|
| *Coming soon* | *Coming soon* | *Coming soon* |

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🤖 AI-powered inspection | Llama 4 Scout analyses food images with expert-level criteria |
| ✅ Pass / Fail verdict | Instant binary safety decision with a confidence score |
| 📊 Hygiene score (0–100) | Granular quality rating for tracking improvement over time |
| 🔍 Issues & recommendations | Specific problems identified with corrective actions |
| 🕐 Scan history | Full session history with thumbnails, scores, and timestamps |
| 📈 Live stats banner | Pass/fail counts and average score across all scans |
| 📋 Detail bottom sheet | Tap any history item to review its full AI report |
| ⚡ Shimmer loading | Polished loading state while AI processes the image |
| 🔄 Auto retry | Automatically retries on rate limits with exponential backoff |
| 🔐 Secure API key | Key injected at build time via `--dart-define`, never hardcoded |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| AI / Vision | Groq — `meta-llama/llama-4-scout-17b-16e-instruct` |
| HTTP Client | `http` package (OpenAI-compatible REST API) |
| Image input | `image_picker` (camera + gallery) |
| UI polish | `shimmer` for loading states |
| Hosting | Firebase Hosting |
| State management | Flutter `setState` (built-in) |
| Target platforms | Web (Flutter Web), Android, iOS |

---

## 🏗️ Architecture

```
lib/
└── main.dart                  # Single-file app (MyApp → MyHomePage → _MyHomePageState)

Key responsibilities inside _MyHomePageState:
├── _analyzeFoodQuality()      # Picks image → calls Groq API → parses JSON → updates state
├── _analyzeWithRetry()        # Retry logic with exponential backoff on rate limits
├── _parseJson()               # Strips markdown fences, decodes structured JSON response
├── _getMimeType()             # Detects image MIME type from file extension
├── _buildCurrentResultCard()  # Renders the latest scan result card
├── _buildStatsBanner()        # Live pass/fail/avg-score stats
├── _buildHistoryTile()        # Each item in the scrollable history list
└── _buildFAB()                # Animated floating action button with pulse effect
```

### How the AI inspection works

```
User taps "Scan Plate"
        │
        ▼
image_picker opens gallery / camera
        │
        ▼
Image bytes → base64 encoded
        │
        ▼
Sent to Groq API (Llama 4 Scout Vision)
with structured prompt requesting JSON:
  { pass, score, summary, issues[], recommendations[] }
        │
        ▼
Response parsed → _scanHistory updated → UI rebuilds
        │
        ▼ (on rate limit)
Auto-retry with 15s / 30s backoff (up to 3 attempts)
```

The prompt instructs the model to act as a professional food safety inspector with 20 years of experience, evaluating five criteria: **freshness, colour, contamination, plating hygiene, and portion presentation**.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0` — [Install Flutter](https://flutter.dev/docs/get-started/install)
- Dart SDK `>=3.0.0` (bundled with Flutter)
- A free **Groq API key** — [Get one free at console.groq.com](https://console.groq.com) (no credit card required)

### 1. Clone the repository

```bash
git clone https://github.com/devkev2k6/FoodInspectionDevkev.git
cd FoodInspectionDevkev
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Verify `pubspec.yaml` dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  image_picker: ^1.0.0
  shimmer: ^3.0.0
```

### 4. Run the app

Replace `YOUR_GROQ_KEY` with your actual API key from [console.groq.com](https://console.groq.com):

```bash
flutter run --dart-define=GROQ_KEY=YOUR_GROQ_KEY
```

> ⚠️ **Never commit your API key to source control.** The app reads the key via `String.fromEnvironment('GROQ_KEY')` at compile time.

### 5. Build for web

```bash
flutter build web --dart-define=GROQ_KEY=YOUR_GROQ_KEY
```

### 6. Deploy to Firebase

```bash
firebase deploy
```

---

## 🌐 Firebase Hosting Setup

### Prerequisites
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
```

### Deploy
```bash
flutter build web --dart-define=GROQ_KEY=YOUR_GROQ_KEY && firebase deploy
```

Your app will be live at your Firebase Hosting URL.

---

## 📱 Android Permissions

Add the following to `android/app/src/main/AndroidManifest.xml` inside the `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 🍏 iOS Permissions

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Kitchen AI Inspector needs camera access to scan food plates.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Kitchen AI Inspector needs gallery access to select food photos.</string>
```

---

## 🔐 API Key Security

| Environment | How to provide the key |
|---|---|
| Local development | `flutter run --dart-define=GROQ_KEY=xxx` |
| Web build | `flutter build web --dart-define=GROQ_KEY=xxx` |
| Firebase deploy | Build with key first, then `firebase deploy` |
| CI/CD | Set `GROQ_KEY` as a secret environment variable |

The key is baked into the compiled binary at build time and is never present in the Dart source code or version control.

---

## 🗺️ Roadmap

- [x] Groq Llama 4 Scout multimodal food inspection
- [x] Structured JSON response parsing (pass/fail/score/issues/recommendations)
- [x] Scan history with thumbnails and timestamps
- [x] Live stats banner (pass count, fail count, average score)
- [x] Shimmer loading animation
- [x] Auto-retry with exponential backoff on rate limits
- [x] Secure API key via `--dart-define`
- [x] Firebase web hosting
- [ ] Camera source choice (camera vs gallery bottom sheet)
- [ ] Persistent history across sessions (`shared_preferences`)
- [ ] Onboarding splash screen with SDG badges
- [ ] Multi-language support
- [ ] Export scan report as PDF
- [ ] Android / iOS native app release

---

## 👥 Team

| Name | Role | Contact |
|---|---|---|
| Debargha Sikdar | Team Leader & Developer | [deba.sik.2006@gmail.com](mailto:deba.sik.2006@gmail.com) |

**GitHub:** [github.com/devkev2k6](https://github.com/devkev2k6)
**Country:** India 🇮🇳
**Event:** Google Solution Challenge 2026

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgements

- [Groq](https://groq.com) — ultra-fast AI inference powering the inspection engine
- [Meta Llama 4](https://ai.meta.com/llama/) — multimodal vision model
- [Flutter](https://flutter.dev) — cross-platform framework
- [Firebase](https://firebase.google.com) — hosting platform
- [Google Solution Challenge](https://developers.google.com/community/gdsc-solution-challenge) — for the opportunity to build technology that matters
- [World Health Organization](https://www.who.int/news-room/fact-sheets/detail/food-safety) — food safety statistics
- [UN Sustainable Development Goals](https://sdgs.un.org) — SDG 2 and SDG 3 frameworks

---

<div align="center">

**Built with ❤️ for Google Solution Challenge 2026**

*Making food safety accessible to everyone, everywhere.*

[🌐 Live Demo](https://foodcheckai-89c88.web.app) · [📦 Repository](https://github.com/devkev2k6/FoodInspectionDevkev) · [📧 Contact](mailto:deba.sik.2006@gmail.com)

</div>
