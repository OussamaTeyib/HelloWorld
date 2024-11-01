# Hello World App

This is a simple Android application written in C that displays **"Hello, World!"** using [raylib](https://github.com/raysan5/raylib) for graphics rendering.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Android SDK**
- **Android NDK**
- **CMake**: Version 3.5 or higher for building the project.
- **Build System**: Ninja is recommended for faster builds.
- **Java Development Kit (JDK)**
- **raylib**: Download and build raylib for Android following the instructions in the [raylib documentation](https://github.com/raysan5/raylib/wiki/Working-for-Android).

### Environment Variables

Before building the project, ensure the following environment variables are set:

- **ANDROID_RAYLIB_HOME**: Path to the raylib installation. This directory must have the following structure:

  ```plaintext
  ANDROID_RAYLIB_HOME
  ├── include               # Contains raylib header files
  └── lib                   # Contains the library files for different ABIs
      ├── <ABI>             # ABI name (e.g., armeabi-v7a, arm64-v8a)
      │   └── libraylib.a   # The raylib library for the specified ABI
  ```
- **ANDROID_HOME**: Path to your Android SDK.
- **KEYSTORE_FILE**: Path to your keystore file for signing the APK.
- **KEYSTORE_PASS**: Password for the keystore (The password for the key is assumed to be the same).

### Build Instructions

Replace placeholders with your values and execute the commands:

1. **Configure the project**:

   ```
   cmake -B build/<ABI>
         -DCMAKE_TOOLCHAIN_FILE=<NDK-Path>/build/cmake/android.toolchain.cmake
         -DANDROID_ABI=<ABI>
         -DANDROID_PLATFORM=<API-Level>
         -DCMAKE_BUILD_TYPE=<Build-Type>
         -G <Generator>
   ```

   **Parameters:**
   - **NDK Path**: Path to your Android NDK.
   - **ABI**: Target Application Binary Interface (e.g., `arm64-v8a`, `armeabi-v7a`).
   - **API Level**: Android API level to target (e.g., `android-35`).
   - **Build Type**: Build type (e.g., `Debug`, `Release`).
   - **Generator**: Build system generator, e.g., `Ninja` or `Unix Makefiles`.

2. **Build the project**:

   ```
   cmake --build build/<ABI>
   ```

   This command compiles the native code and generates the APK.

3. **Install on a connected device**:

   To install the APK on a connected device, run:

   ```
   cmake --build build/<ABI> --target install_apk
   ```

### Useful Commands

- **Clean**: Clean all output files (including binaries and APKs)
   ```
   cmake --build build/<ABI> --target clean
   ```

- **Uninstall APK**: Remove the app from the connected device.

   ```
   cmake --build build/<ABI> --target uninstall_apk
   ```

- **Monitor Logs**: View the logcat output for debugging.

   ```
   cmake --build build/<ABI> --target logcat
   ```

- **Check Device ABI**: Confirm the ABI of the connected device.

   ```
   cmake --build build/<ABI> --target check_device_abi
   ```

- **List Users on Device**: Get a list of users configured on the device.

   ```
   cmake --build build/<ABI> --target list_users
   ```

## License

This project is licensed under the [MIT License](LICENSE).