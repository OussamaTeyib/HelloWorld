# Hello World App

This is a simple Android application written in C that displays **"Hello, World!"** using [raylib](https://github.com/raysan5/raylib) for graphics rendering.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Android SDK**
- **Android NDK**
- **CMake**: Version 3.10 or higher for building the project.
- **Build System**: Ninja is recommended for faster builds.
- **Java Development Kit (JDK)**
- **raylib**: Download and build raylib for Android following the instructions in the [raylib documentation](https://github.com/raysan5/raylib/wiki/Working-for-Android).

### Environment Variables

Before building the project, ensure the following environment variables are set:

- **ANDROID_HOME**: Path to the Android SDK installation.
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

Replace placeholders with your values and execute the commands:

1. **Configure the project**:

   ```
   cmake -B <Build-Directory> \
         -DCMAKE_TOOLCHAIN_FILE=<NDK-Path>/build/cmake/android.toolchain.cmake \
         -DANDROID_ABI=<ABI> \
         -DANDROID_PLATFORM=<API-Level> \
         -DUSER_ID=<User-ID>
   ```

   **Parameters:**
   - **Build Directory**: Name of the build directory (e.g., `Build/arm64-v8a`).
   - **NDK Path**: Path to the Android NDK installation.
   - **ABI**: Target Application Binary Interface (e.g., `arm64-v8a`, `armeabi-v7a`).
   - **API Level**: Minimum Android API level to support (e.g., `21`).
   - **USER_ID** *(optional)*: Android user ID to install the app for; defaults to `0`, the primary user.

2. **Build the project**:

   ```
   cmake --build <Build-Directory>
   ```

   This command compiles the native code and generates the APK.

3. **Install on a connected device**:

   To install the APK on a connected device, run:

   ```
   cmake --build <Build-Directory> --target install_apk
   ```

### Useful Commands

- **Clean**: Clean all output files (including binaries and APKs)
   ```
   cmake --build <Build-Directory> --target clean
   ```

- **Uninstall APK**: Remove the app from the connected device.

   ```
   cmake --build <Build-Directory> --target uninstall_apk
   ```

- **Check Device ABI**: Confirm the ABI of the connected device.

   ```
   cmake --build <Build-Directory> --target check_device_abi
   ```

- **List Users on Device**: Get a list of users configured on the device.

   ```
   cmake --build <Build-Directory> --target list_users
   ```

## License

This project is licensed under the [MIT License](LICENSE).