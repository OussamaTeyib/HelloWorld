# HelloWorld

This is a simple Android application written in C that displays **"Hello, World!"** using [raylib](https://github.com/raysan5/raylib) for graphics rendering.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Java Development Kit (JDK)** — JDK 17
- **CMake** version 4.0.2 or higher

If you plan to build a release version of the app, the following environment variables must be set:
- **STORE_FILE** — Path to the keystore used for signing
- **STORE_PASSWORD** — Keystore password
- **KEY_ALIAS** — Alias of the key in the keystore
- **KEY_PASSWORD** *(optional)* — Key password (default: **STORE_PASSWORD**)

### Build Instructions

1. **Clone the repository**

   - To clone the repository and automatically initialize and update all submodules:
     ```
     git clone --recurse-submodules https://github.com/OussamaTeyib/HelloWorld.git
     ```

> [!TIP]
> This workflow uses Gradle. For a CMake-based workflow, see [this](https://github.com/OussamaTeyib/HelloWorld/releases/tag/v1.0.0+).

> [!NOTE]
> For windows, use `gradlew.bat` instead of `./gradlew`.

2. **Build the project**

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

3. **Install on a connected device or emulator**

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
