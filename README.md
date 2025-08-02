# Hello World App

This is a simple Android application written in C that displays **"Hello, World!"** using [raylib](https://github.com/raysan5/raylib) for graphics rendering.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Android SDK**: Version 26.0.2 or higher.
- **Android NDK**: Version r25 or higher.
- **zip**
- **CMake**: Version 3.22.1 or higher.
- **Build System**: Ninja is recommended for faster builds.
- **Java Development Kit (JDK)**: JDK 11 or newer.
- **raylib**: Follow the [official instructions](https://github.com/raysan5/raylib/wiki/Working-for-Android) to download and build raylib as a static library for Android.
> ✅ Make sure all required tools are available in your system's PATH.

> [!NOTE]
> By default:
> - Application name: `Hello World`
> - Native library name: `main`
> - Application package name: `com.oussamateyib.helloworld`
> - Target SDK version: `36`
> - Minimum SDK version: `21`
> 
> Any changes to these defaults require corresponding updates to CMake and XML configuration files.

### Environment Variables

Before building the project, ensure the following environment variables are set:

- **ANDROID_HOME**: Path to the Android SDK installation.
- **ANDROID_NDK_HOME**: Path to the Android NDK installation.
- **ANDROID_EXTERNAL_HOME**: Path to the installation of external Android libraries. This directory must have the following structure:

  ```plaintext
  ANDROID_EXTERNAL_HOME/
  ├── include/              # Contains header files for external libraries
  │   └── raylib.h          # Raylib header files
  └── lib/                  # Contains library files for different ABIs
      ├── <ABI>/            # ABI name (e.g., armeabi-v7a, arm64-v8a)
      │   └── libraylib.a   # Raylib static library for the specified ABI
  ```
- **KEYSTORE_FILE**: Path to the keystore file used for signing the APK.
- **KEYSTORE_PASS**: Password for the keystore.
- **KEY_ALIAS**: Alias of the key within the keystore.
- **KEY_PASS** *(optional)*: Password for the key; defaults to **KEYSTORE_PASS**.

### Build Instructions

Replace placeholders with your own values before running the commands.

---

1. **Configure the Project Using CMake**:

   ```
   cmake -B <Build-Directory> \
         -G "<Build-System>" \
         [-DCMAKE_BUILD_TYPE=<Build-Type>] \
         [-DABIS="<ABI-List>"] \
         [-DAPI_Level=<API-Level>] \
         [-DUSER_ID=<User-ID>]
   ```

   **Explanation of Parameters:**
   - `-B <Build-Directory>`: Specifies the build output directory (e.g., `Build`).
   - `-G "<Build-System>"`: Generator name (e.g., `Ninja`, `Unix Makefiles`, etc.).
   - `-DCMAKE_BUILD_TYPE=<Build-Type>` *(optional)*: Set to `Debug`, `Release`, `RelWithDebInfo`, or `MinSizeRel`. Default is `Debug`.
   - `-DABIS="<ABI-List>"` *(optional)*: Semicolon-separated list of target ABIs. Default: `armeabi-v7a;arm64-v8a;x86;x86_64`.
   - `-DAPI_Level=<API-Level>` *(optional)*: Minimum Android API level. Default: `21`.
   - `-DUSER_ID=<User-ID>` *(optional)*: Target Android user ID for app installation. Default: `0` (primary user).

2. **Build the project**:

   ```
   cmake --build <Build-Directory>
   ```

   This command compiles the native code and builds APKs for all ABIs specified in the `ABIS` variable.

3. **Install on a connected device or emulator**:

   To install the APK on a connected device or emulator, run:

   ```
   cmake --build <Build-Directory> --target install_apk_<ABI-Name>
   ```
   
   This command builds the native code and APK for the specified ABI (if not already built), and installs it on the connected target.
   > Replace `<ABI-Name>` with one of the build's supported ABIs.

### Useful Commands

- **Clean**: Clean all output files (including binaries and APKs)
   ```
   cmake --build <Build-Directory> --target clean
   ```

- **Uninstall APK**: Remove the app from the connected device or emulator.

   ```
   cmake --build <Build-Directory> --target uninstall_apk
   ```

- **Check Device ABI**: Get the ABI of the connected device or emulator.

   ```
   cmake --build <Build-Directory> --target check_device_abi
   ```

- **List Users on Device**: Get a list of users configured on the device.

   ```
   cmake --build <Build-Directory> --target list_users
   ```

## License

This project is licensed under the [MIT License](LICENSE).
