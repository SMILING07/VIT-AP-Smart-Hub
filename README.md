# VIT-AP Smart Hub 🎓📱

![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)
![Rust Version](https://img.shields.io/badge/Rust-1.75%2B-orange.svg?logo=rust)
![Platform](https://img.shields.io/badge/Platform-Android-green.svg?logo=android)
![Shorebird](https://img.shields.io/badge/OTA_Updates-Shorebird-purple.svg)

**VIT-AP Smart Hub** is an advanced, high-performance mobile application designed exclusively for the students of VIT-AP University. Built with a beautiful, reactive **Flutter** frontend and a blazingly fast **Rust** backend, it provides seamless access to your VTOP data—ranging from attendance tracking to real-time mess menus—all wrapped in a premium UI.

## ✨ Key Features

*   📊 **Dashboard Overview**: At-a-glance view of your most critical academic metrics.
*   📅 **Smart Timetable**: Dynamic class schedules with automated "Next Class" calculations.
*   ✅ **Attendance Tracker**: Real-time attendance monitoring to ensure you never fall below the threshold.
*   📝 **Marks & Grades**: Detailed insights into internal marks and final semester grades.
*   🗺️ **Floor Maps**: Interactive campus navigation to easily find your classes.
*   🍴 **Mess Menu**: Daily mess schedules (including Night Mess), completely decoupled and easy to read.
*   ⚡ **Rust-Powered Backend**: Utilizes `flutter_rust_bridge` for incredibly fast and secure API interactions and data parsing natively on device.
*   🔄 **OTA Updates**: Integrated with **Shorebird** for instantaneous over-the-air patches without re-downloading the APK.
*   🌙 **Adaptive Theming**: Full support for both ultra-sleek Dark Mode and premium Light Mode.

## 🛠️ Technology Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Frontend** | Flutter | Cross-platform UI toolkit emphasizing smooth 60fps animations. |
| **Backend / FFI** | Rust | Memory-safe, high-performance native parsing and API management. |
| **Bridge** | `flutter_rust_bridge` (v2) | Seamless bridging between Dart and Rust code. |
| **State Management** | `Provider` | Efficient reactive data binding across the app. |
| **CI/CD & DevOps** | GitHub Actions & Shorebird | Automated native builds and live code deployments. |

## 🚀 Getting Started

### Prerequisites

To build and run this project locally, you must have the following installed:
1.  [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable Channel)
2.  [Rust Toolchain](https://rustup.rs/) (Stable)
3.  **Android Studio** / Android SDK with **NDK** installed.
4.  **Cargo NDK**: Required for cross-compiling the Rust backend for Android.
    ```bash
    cargo install cargo-ndk
    rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
    ```

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/DARKSAPRO3x42/VIT-AP-Smart-Hub.git
    cd VIT-AP-Smart-Hub
    ```

2.  **Install Flutter dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Build the Rust backend (Optional, usually handled automatically via Gradle/Cargokit):**
    ```bash
    cargo build --manifest-path rust/Cargo.toml
    ```

4.  **Run the application:**
    ```bash
    flutter run
    ```

## 📦 Building Releases & OTA Patches

We utilize a custom PowerShell script to manage versioning and Shorebird deployments on Windows.

To release a new version or push an instant patch, use the interactive `build_and_bump.ps1` script:

```powershell
.\build_and_bump.ps1
```

*   **Option 1 (Major Release):** Automatically bumps the `pubspec.yaml` version and triggers `shorebird release android`.
*   **Option 2 (Minor Patch):** Triggers `shorebird patch android` to instantly push fixes to all existing users.

## 🤝 Contributing

Contributions are always welcome! Whether it's submitting a bug report, optimizing the Rust FFI, or designing a new UI component.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

> **Note:** Ensure you run `dart format .` and `flutter analyze` before opening a pull request to satisfy the GitHub Actions CI checks.

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
*Built with ❤️ for the students of VIT-AP.*
