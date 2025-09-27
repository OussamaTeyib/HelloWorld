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
- **Android Manifest Merger** — Download the [latest release](https://github.com/distriqt/android-manifest-merger/releases)
- **CMake** version 4.0.2 or higher
- **Build System** (Ninja is recommended for faster builds)
- **fd** — Download the [latest release](https://github.com/sharkdp/fd?tab=readme-ov-file#installation)
- **zip** version 2.32 or higher

If you plan to create Android App Bundles (AAB) or APK sets, the following must also be installed:
- **AAPT2** — Follow the [official instructions](https://developer.android.com/build/building-cmdline#download_aapt2) to download an AAB-compatible version of AAPT2
- **unzip** version 5.52 or higher
- **Bundletool** version 1.18.1 or higher

> [!IMPORTANT]
> Verify that all required tools are available in your system's `PATH`. For JAR files, ensure wrapper scripts are properly configured.

### Environment Variables

Before building the project, ensure the following environment variables are set:

- **ANDROID_HOME** — Path to the Android SDK installation
- **ANDROID_NDK_HOME** — Path to the Android NDK installation

If you want to use your own signing key for release builds, set the following environment variables:
- **STORE_FILE** — Path to the keystore
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
         [-DDEBUG_SYMBOLS_LEVEL=<Debug_Symbols_Level>] \
         [-DMIN_SDK=<Min_SDK>] \
         [-DCOMPILE_SDK=<Compile_SDK>] \
         [-DTARGET_SDK=<Target_SDK>] \
         [-DPACKAGE_NAME=<Package_Name>] \
         [-DVERSION_CODE=<Version_Code>] \
         [-DVERSION_NAME=<Version_Name>] \
         [-DOUTPUT_NAME=<Output_Name>] \
         [-DLIB_NAME=<Lib_Name>] \
         [-DUSER=<User>]
   ```

   **Explanation of Parameters**:
   - `-B <Build-Directory>` — Output directory name (`Build` is recommended)
   - `-G "<Build-System>"` — Generator (e.g., `Ninja`, `Unix Makefiles`)
   - `-DCMAKE_BUILD_TYPE=<Build-Type>` *(optional)* — Build type. Options: `Debug`, `Release`, `RelWithDebInfo`, or `MinSizeRel` (default: `Debug`)
   - `-DABIS="<ABI-List>"` *(optional)* — Target Android ABIs (default: `armeabi-v7a;arm64-v8a;x86;x86_64;riscv64`)
   - `-DDEBUG_SYMBOLS_LEVEL=<Debug_Symbols_Level>` *(optional)* — Level of debug symbols. Options: `FULL` or `SYMBOL_TABLE` (default: `FULL`)
   - `-DMIN_SDK=<Min_SDK>` *(optional)* — Minimum Android API level (default: `21`)
   - `-DCOMPILE_SDK=<Compile_SDK>` *(optional)* — Android API level used for compilation (default: `36`)
   - `-DTARGET_SDK=<Target_SDK>` *(optional)* — Target Android API level (default: `36`)
   - `-DPACKAGE_NAME=<Package_Name>` *(optional)* — App package name (default: `com.oussamateyib.helloworld`)
   - `-DVERSION_CODE=<Version_Code>` *(optional)* — App version code (default: `1`)
   - `-DVERSION_NAME=<Version_Name>` *(optional)* — App version name (default: `1.0.0`)
   - `-DOUTPUT_NAME=<Output_Name>` *(optional)* — App output file name (default: `HelloWorld_v<Version_Name>`)
   - `-DLIB_NAME=<Lib_Name>` *(optional)* — Native library name (default: `main`)
   - `-DUSER=<User>` *(optional)* — Installation scope. Options: `current`, `all`, or a specific user ID (default: `current`)

   **CMake build types comparison**:

   | Feature | Debug | Release | RelWithDebInfo | MinSizeRel |
   |---------|-------|---------|----------------|------------|
   | **Default Build Type** | ✅ Yes  | ❌ No | ❌ No | ❌ No |
   | **CMake Toolchain Optimizations** | Standard Debug flags | Standard Release flags + debug info | Standard Release flags + debug info | Size-optimized Release flags + debug info |
   | **Debug Symbol Stripping** | ❌ No | ✅ Yes | ❌ No | ✅ Yes |
   | **Debug Symbol Packaging** | ❌ No | ✅ Yes | ❌ No | ✅ Yes |
   | **Manifest Merging** | ✅ Includes debug overlay | ❌ Main manifest only | ❌ Main manifest only | ❌ Main manifest only |
   | **Resource Optimization** | ❌ No | ✅ Yes  | ✅ Yes | ✅ Yes |
   | **APK Compression** | ❌ Standard compression | ✅ Zopfli recompression | ✅ Zopfli recompression | ✅ Zopfli recompression |
   | **Keystore Used** | 🔑 Debug keystore | 🔑 Production keystore or debug fallback | 🔑 Debug keystore or debug fallback | 🔑 Production keystore or debug fallback |

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