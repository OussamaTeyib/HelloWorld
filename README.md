# HelloWorld

This is a simple Android application written in C that displays **"Hello, World!"** using [raylib](https://github.com/raysan5/raylib) for graphics rendering.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Java Development Kit (JDK)** — JDK 17
- **raylib** — Follow the [official instructions](https://github.com/raysan5/raylib/wiki/Working-for-Android) to download and build raylib as a static library for Android

> [!NOTE]
> **By default**:
> - Application name: `Hello World`
> - Native library name: `main`
> - Application package name: `com.oussamateyib.helloworld`
> - Compile SDK version: `36`
> - Target SDK version: `36`
> - Minimum SDK version: `21`
> 
> If you change these defaults, you must update related configuration files.

### Environment Variables

Before building the project, ensure the following environment variables are set:

- **ANDROID_EXTERNAL_HOME** — Path to the installation of external Android libraries. This directory must have the following structure:

  ```plaintext
  ANDROID_EXTERNAL_HOME/
  ├── include/              # Contains header files for external libraries
  │   └── raylib.h
  └── lib/                  # Contains library files for different ABIs
      ├── <ABI>/            # ABI name (e.g., armeabi-v7a, arm64-v8a)
      │   └── libraylib.a   # Static raylib library for the ABI
  ```
  
If you plan to build a release version of the app, the following variables must also be set (for signing):
- **STORE_FILE** — Path to the keystore used for signing
- **STORE_PASSWORD** — Keystore password
- **KEY_ALIAS** — Alias of the key in the keystore
- **KEY_PASSWORD** *(optional)* — Key password (default: **STORE_PASSWORD**)

### Build Instructions

Replace placeholders with your values before running the commands.

> [!NOTE]
> For windows, use `gradlew.bat` instead of `./gradlew`.

---

1. **Build the project**

   - To generate APKs:
     ```
     ./gradlew assembleDebug
     ```
     Or
     ```
     ./gradlew assembleRelease
     ```
     This command compiles the native code and generates APKs for all configured ABIs, as well as a universal APK that works across all supported devices.

   - To generate an Android App Bundle (AAB):
     ```
     ./gradlew bundleDebug
     ```
     Or
     ```
     ./gradlew bundleRelease
     ```
     This command compiles the native code and generates an Android App Bundle (AAB).

2. **Install on a connected device or emulator**

   - To install the APK:
     ```
     ./gradlew installDebug
     ```
     Or
     ```
     ./gradlew installRelease
     ```
     This command installs the APK on the connected device or emulator.

### Useful Commands

- **Clean the project**
  ```
  ./gradlew clean
  ```

- **Uninstall the app**
  ```
  ./gradlew uninstallDebug
  ```
  Or
  ```
  ./gradlew uninstallRelease
  ```

## License

This project is licensed under the [MIT License](LICENSE).
