# HelloWorld

This is a simple Android application written in C that displays **"Hello, World!"** using [raylib](https://github.com/raysan5/raylib) for graphics rendering.

## Getting Started

> [!WARNING]
> This version uses a CMake-based workflow and is only maintained occasionally. For the latest actively maintained version, which uses Gradle and modern Android tools, see [this](https://github.com/OussamaTeyib/HelloWorld).

### Prerequisites

Before you begin, ensure you have the following installed:

- **Java Development Kit (JDK)** — JDK 17 or newer
- **Android SDK**
- **Android NDK** — r28 or newer
- **zip** version 2.32 or higher
- **CMake** version 4.0.2 or higher
- **Build System** (Ninja is recommended for faster builds)

If you plan to create Android App Bundles (AAB), the following must also be installed:
- **AAPT2** — Follow the [official instructions](https://developer.android.com/build/building-cmdline#download_aapt2) to download an AAB-compatible version of AAPT2
- **unzip** version 5.52 or higher
- **Bundletool**

> ✅ Make sure all required tools are available in your system's PATH.

### Environment Variables

Before building the project, ensure the following environment variables are set:

- **ANDROID_HOME** — Path to the Android SDK installation
- **ANDROID_NDK_HOME** — Path to the Android NDK installation

If you plan to build a release version of the app, the following variables must also be set (for signing):
- **STORE_FILE** — Path to the keystore used for signing
- **STORE_PASSWORD** — Keystore password
- **KEY_ALIAS** — Alias of the key in the keystore
- **KEY_PASSWORD** *(optional)* — Key password (default: **STORE_PASSWORD**)

### Build Instructions

Replace placeholders with your values before running the commands.

---

1. **Set up the repository**

   - Clone the repository and automatically initialize and update all submodules:
     ```
     git clone --recurse-submodules https://github.com/OussamaTeyib/HelloWorld.git
     ```
   - Switch to the CMake-based workflow:
     ```
     git checkout v1.0.0++
     ```

2. **Configure the Project Using CMake**

   ```
   cmake -B <Build-Directory> \
         -G "<Build-System>" \
         [-DCMAKE_BUILD_TYPE=<Build-Type>] \
         [-DABIS="<ABI-List>"] \
         [-DMIN_SDK=<Min_SDK>] \
   ```

   **Explanation of Parameters:**
   - `-B <Build-Directory>` — Output directory (e.g., `Build`)
   - `-G "<Build-System>"` — Generator (e.g., `Ninja`, `Unix Makefiles`)
   - `-DCMAKE_BUILD_TYPE=<Build-Type>` *(optional)* — One of: `Debug`, `Release`, `RelWithDebInfo`, `MinSizeRel` (default: `Debug`)
   - `-DABIS="<ABI-List>"` *(optional)* — ABIs to build for (default: `armeabi-v7a;arm64-v8a;x86;x86_64;riscv64`)
   - `-DMIN_SDK=<Min_SDK>` *(optional)* — Minimum Android API (default: `21`)

3. **Build the project**

   - Generate the APKs:
     ```
     cmake --build <Build-Directory>
     ```
     This command compiles the native code and generates APKs for all configured ABIs, as well as a universal APK that works across all supported devices.

   - Generate an Android App Bundle (AAB):
     ```
     cmake --build <Build-Directory> --target create_aab
     ```
     This command compiles the native code (if not already built) and generates an Android App Bundle (AAB).

> [!NOTE]
> Note: All output files are located in `<Build-Directory>/outputs/`.

4. **Install on a connected device or emulator**

   - Install the APK for a specific ABI:
     ```
     cmake --build <Build-Directory> --target install_apk_<ABI-Name>
     ```
     This command builds the native code and the APK for the specified ABI (if not already built), then installs it on the connected device or emulator.
     > Replace `<ABI-Name>` with one of the configured ABIs.

   - Install the universal APK:
     ```
     cmake --build <Build-Directory> --target install_apk_universal
     ```
     This command builds the native code and a universal APK that supports all configured ABIs (if not already built), and installs it on the connected device or emulator.

   - Install the AAB (Android App Bundle):
     ```
     cmake --build <Build-Directory> --target install_aab
     ```
     This command builds the native code and the AAB (if not already built), then installs it on the connected device or emulator.

### Useful Commands

- Clean the project:
  ```
  cmake --build <Build-Directory> --target clean
  ```

- Uninstall the app:
  ```
  cmake --build <Build-Directory> --target uninstall_app
  ```

- Check supported ABIs on the connected device or emulator:
  ```
  cmake --build <Build-Directory> --target check_abi
  ```

## License

This project is licensed under the [MIT License](LICENSE).