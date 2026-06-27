# WebFuseX

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
</p>

**WebFuseX** is a cutting-edge Android application built to seamlessly transform any website into a powerful, native-like mobile app experience. Say goodbye to the clunky mobile browser experience and embrace the true potential of your favorite web services as fully integrated applications on your phone.

Built with **Flutter** and powered by a robust **Native Android (Kotlin)** engine, WebFuseX blends the best of both worlds to deliver an unparalleled browsing experience.

## ✨ Key Features

*   **Native App Experience:** Instantly install and pin web apps to your home screen. They launch directly into a beautifully optimized fullscreen mode without any annoying browser address bars.
*   **The Default Library:** A curated, categorized library of amazing websites ready to be installed with a single tap. (Includes Anime, K-Dramas, Movies, Cartoons, Manga, and more!)
*   **WebFuseX Shield:** An integrated ad & privacy blocker that strips out malicious popups and trackers, allowing for an incredibly smooth and safe viewing experience.
*   **Desktop Mode Override:** Force a website to render its full desktop version instantly.
*   **Video Fullscreen Optimization:** Native handling of fullscreen video intent, seamlessly maintaining surface views and state without disrupting the layout or audio.
*   **Category Management:** Intuitive filtering and category tabs to keep your installed apps and the default library perfectly organized.

## 🏗️ Architecture & Technology Stack

WebFuseX is strictly designed around **Feature-First Clean Architecture** principles to guarantee a scalable, modular, and performant codebase.

- **Presentation Layer**: Flutter + Riverpod state management.
- **Data Layer**: Robust Repository Pattern implementations.
- **Platform Engine**: Custom Kotlin backend interfacing with advanced Android WebView capabilities, PIP (Picture-in-Picture), and Secure Storage.

## 🚀 Getting Started (Development)

1. Ensure **Flutter** (latest stable release) and the **Android SDK** are installed and configured on your machine.
2. Clone this repository:
   ```bash
   git clone https://github.com/jinsu-2005/WebFuseX.git
   ```
3. Navigate into the directory and install dependencies:
   ```bash
   cd WebFuseX
   flutter pub get
   ```
4. Run the app on a connected device or emulator:
   ```bash
   flutter run
   ```

## 📦 Releases

You can download the compiled production-ready `.apk` directly from the `releases` folder in this repository or from the GitHub Releases tab!

---

*Transform the web, fuse it into native.*
