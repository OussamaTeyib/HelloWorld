# Hello World App

This is a simple Android application written in C that displays **"Hello, World!"** using [raylib](https://github.com/raysan5/raylib) for graphics rendering.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Android SDK**
- **Android NDK** — r27d  or newer
- **zip** version 2.32 or higher
- **CMake** version 3.22.1 or higher
- **Build System** (Ninja is recommended for faster builds)
- **Java Development Kit (JDK)** — JDK 11 or newer.
- **raylib** — Follow the [official instructions](https://github.com/raysan5/raylib/wiki/Working-for-Android) to download and build raylib as a static library for Android

If you plan to create Android App Bundles (AAB), the following must also be installed:
- **AAPT2** — Follow the [official instructions](https://developer.android.com/build/building-cmdline#download_aapt2) to download an AAB-compatible version of AAPT2
- **unzip** version 1.38.0 or higher
- **Bundletool**

> ✅ Make sure all required tools are available in your system's PATH.

> [!NOTE]
> **By default**:
> - Application name: `Hello World`
> - Native library name: `main`
> - Application package name: `com.oussamateyib.helloworld`
> - Target SDK version: `36`
> - Minimum SDK version: `21`
> 
> If you change these defaults, you must update related CMake and XML configuration files.

### Environment Variables

Before building the project, ensure the following environment variables are set:

- **ANDROID_HOME** — Path to the Android SDK installation
- **ANDROID_NDK_HOME** — Path to the Android NDK installation
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
- **KEY_PASSWORD** *(optional)* — Key password (default: **KEYSTORE_PASS**)

### Build Instructions

Replace placeholders with your values before running the commands.

---

1. **Configure the Project Using CMake**

   ```
   cmake -B <Build-Directory> \
         -G "<Build-System>" \
         [-DCMAKE_BUILD_TYPE=<Build-Type>] \
         [-DABIS="<ABI-List>"] \
         [-DAPI_Level=<API-Level>] \
   ```

   **Explanation of Parameters:**
   - `-B <Build-Directory>` — Output directory (e.g., `Build`)
   - `-G "<Build-System>"` — Generator (e.g., `Ninja`, `Unix Makefiles`)
   - `-DCMAKE_BUILD_TYPE=<Build-Type>` *(optional)* — One of: `Debug`, `Release`, `RelWithDebInfo`, `MinSizeRel` (default: `Debug`)
   - `-DABIS="<ABI-List>"` *(optional)* — ABIs to build for (default: `armeabi-v7a;arm64-v8a;x86;x86_64;riscv64`)
   - `-DAPI_Level=<API-Level>` *(optional)* — Minimum Android API (default: `21`)

2. **Build the project**

   - To generate APKs:
     ```
     cmake --build <Build-Directory>
     ```
     This command compiles the native code and generates APKs for all configured ABIs, as well as a universal APK that works across all supported devices.

   - To generate an Android App Bundle (AAB):
     ```
     cmake --build <Build-Directory> --target create_aab
     ```
     This command compiles the native code (if not already built) and generates an Android App Bundle (AAB).

3. **Install on a connected device or emulator**

   - To install the APK for a specific ABI:
     ```
     cmake --build <Build-Directory> --target install_apk_<ABI-Name>
     ```
     This command builds the native code and the APK for the specified ABI (if not already built), then installs it on the connected device or emulator.
     > Replace `<ABI-Name>` with one of the configured ABIs.

   - To install the universal APK:
     ```
     cmake --build <Build-Directory> --target install_apk_universal
     ```
     This command builds the native code and a universal APK that supports all configured ABIs (if not already built), and installs it on the connected device or emulator.

   - To install the AAB (Android App Bundle):
     ```
     cmake --build <Build-Directory> --target install_aab
     ```
     This command builds the native code and the AAB (if not already built), then installs it on the connected device or emulator.

### Useful Commands

- **Clean the project**
  ```
  cmake --build <Build-Directory> --target clean
  ```

- **Uninstall the app**
  ```
  cmake --build <Build-Directory> --target uninstall_app
  ```

- **Check supported ABIs on the connected device or emulator**
  ```
  cmake --build <Build-Directory> --target check_abi
  ```

## License

This project is licensed under the [MIT License](LICENSE).
