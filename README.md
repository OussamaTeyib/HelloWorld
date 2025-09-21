# HelloWorld

This is a simple Android application written in C that displays **"Hello, World!"** using [raylib](https://github.com/raysan5/raylib) for graphics rendering.

---

## Getting Started

> [!WARNING]
> This version uses a CMake-only workflow and is only maintained occasionally. For the latest actively maintained version, which uses Gradle and modern Android tools, see [this](https://github.com/OussamaTeyib/HelloWorld).

### Prerequisites

Before you begin, ensure you have the following installed:

- **Java Development Kit (JDK)** — JDK 17
- **Android SDK**
- **Android NDK** — r28c or newer
- **Android Manifest Merger** — Download the latest release from [GitHub](https://github.com/distriqt/android-manifest-merger/releases)
- **CMake** version 4.0.2 or higher
- **Build System** (Ninja is recommended for faster builds)
- **zip** version 2.32 or higher

If you plan to create Android App Bundles (AAB) or APK sets, the following must also be installed:
- **AAPT2** — Follow the [official instructions](https://developer.android.com/build/building-cmdline#download_aapt2) to download an AAB-compatible version of AAPT2
- **unzip** version 5.52 or higher
- **Bundletool** version 1.18.1 or higher

> ✅ Make sure all required tools are available in your system's `PATH`.

### Environment Variables

Before building the project, ensure the following environment variables are set:

- **ANDROID_HOME** — Path to the Android SDK installation
- **ANDROID_NDK_HOME** — Path to the Android NDK installation

If you plan to build a release version of the app, the following variables must also be set:
- **STORE_FILE** — Path to the keystore used for signing
- **STORE_PASSWORD** — Keystore password
- **KEY_ALIAS** — Alias of the key in the keystore
- **KEY_PASSWORD** *(optional)* — Key password (default: **STORE_PASSWORD**)

### Build Instructions

1. **Set up the repository**

   - Clone the repository and automatically initialize and update all submodules:
     ```
     git clone --recurse-submodules https://github.com/OussamaTeyib/HelloWorld.git
     ```
   - Switch to the CMake-only workflow:
     ```
     git checkout v1.0.x
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

   > All output files are located in `<Build-Directory>/outputs/`.

   - Generate APKs:
     ```
     cmake --build <Build-Directory>
     ```

   - Install an ABI-specific APK on the connected device:
     ```
     cmake --build <Build-Directory> --target install_apk_<ABI-Name>
     ```
     > Replace `<ABI-Name>` with one of the configured ABIs.

   - Install the universal APK on the connected device:
     ```
     cmake --build <Build-Directory> --target install_apk_universal
     ```

   - Generate an AAB:
     ```
     cmake --build <Build-Directory> --target create_aab
     ```

   - Install the AAB on the connected device:
     ```
     cmake --build <Build-Directory> --target install_aab
     ```

   - Generate a universal APK set:
     ```
     cmake --build <Build-Directory> --target create_apks_universal
     ```

   - Install the universal APK set on the connected device:
     ```
     cmake --build <Build-Directory> --target install_apks_universal
     ```

   - Generate an APK set specific to the connected device:
     ```
     cmake --build <Build-Directory> --target create_apks_connected_device
     ```

   - Install the connected device's APK set:
     ```
     cmake --build <Build-Directory> --target install_apks_connected_device
     ```

   - Uninstall the app from the connected device:
     ```
     cmake --build <Build-Directory> --target uninstall_app
     ```

   - Display the ABIs supported by the connected device:
     ```
     cmake --build <Build-Directory> --target check_abis
     ```

   - Export the connected device specifications to a JSON file:
     ```
     cmake --build <Build-Directory> --target export_spec
     ```

   - Clean the project:
     ```
     cmake --build <Build-Directory> --target clean
     ```

---

## License

This project is licensed under the [MIT License](LICENSE).