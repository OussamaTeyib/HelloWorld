# Hello World App

This is a simple Android application written in C that displays **"Hello, World!"** using [raylib](https://github.com/raysan5/raylib) for graphics rendering.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Android NDK**: Required for native C development.
- **CMake**: Version 3.5 or higher for building the project.
- **Build System**: Ninja is recommended for faster builds.
- **Java Development Kit (JDK)**: Required for Android development.
- **raylib**: Download and build raylib for Android following the instructions in the [raylib documentation](https://github.com/raysan5/raylib/wiki/Working-for-Android).

### Build Instructions

Replace placeholders with your values and execute the commands:

1. **Configure the project**:

   ```
   cmake -B build
         -DCMAKE_TOOLCHAIN_FILE=<NDK-Path>/build/cmake/android.toolchain.cmake
         -DANDROID_ABI=<ABI>
         -DANDROID_PLATFORM=<API-Level>
         -G <Generator>
   ```

   **Parameters:**
   - **NDK Path**: Path to your Android NDK.
   - **ABI**: Target Application Binary Interface (e.g., `arm64-v8a`, `armeabi-v7a`).
   - **API Level**: Android API level to target (e.g., `android-35`).
   - **Generator**: Build system generator, e.g., `Ninja` or `Unix Makefiles`.

2. **Build the project**:

   ```
   cmake --build build
   ```

   This command compiles the native code and generates the APK.

3. **Install on a connected device**:

   To install the APK on a connected device, run:

   ```
   cmake --build build --target install_apk
   ```

### Useful Commands

- **Create APK**: Create the APK file.

   ```
   cmake --build build --target create_apk
   ```

- **Align APK**: Optimize the APK for distribution.

   ```
   cmake --build build --target align_apk
   ```

- **Sign APK**: Sign the APK for installation on devices.

   ```
   cmake --build build --target sign_apk
   ```

- **Uninstall APK**: Remove the app from the connected device.

   ```
   cmake --build build --target uninstall_apk
   ```

- **Monitor Logs**: View the logcat output for debugging.

   ```
   cmake --build build --target logcat
   ```

- **Check Device ABI**: Confirm the ABI of the connected device.

   ```
   cmake --build build --target check_device_abi
   ```

- **List Users on Device**: Get a list of users configured on the device.

   ```
   cmake --build build --target list_users
   ```

## License

This project is licensed under the [MIT License](LICENSE).