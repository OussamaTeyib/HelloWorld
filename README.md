# HelloWorld

This is a simple Android application written in C that displays **"Hello, world!"** using [raylib](https://github.com/raysan5/raylib).

---

## Getting Started
> [!TIP]
> This workflow uses Gradle. For a CMake-only workflow, which offers greater flexibility, see [this](https://github.com/OussamaTeyib/HelloWorld/tree/v1.0.x).

### Prerequisites

Before you begin, ensure you have the following installed:

- **Java Development Kit (JDK)** — JDK 17
- **CMake** version 4.0.2 or higher

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

2. **Using Android Studio**

   - Open the project in **Android Studio**.
   - Let Gradle sync.
   - Use **Run** to launch on a device or emulator.
   - Use **Build** > **Build Bundle(s) / APK(s)** to generate APK or AAB.

3. **Using Terminal**

   > `<Build-Type>` can be either `Debug` or `Release`.

   - Generate APKs:
     ```
     gradlew assemble<Build-Type>
     ```

   - Install the APKs on a connected device or emulator:
     ```
     gradlew install<Build-Type>
     ```

   - Uninstall the APKs:
     ```
     gradlew uninstall<Build-Type>
     ```

   - Generate AABs:
     ```
     gradlew bundle<Build-Type>
     ```

   - Clean the project
     ```
     gradlew clean
     ```

---

## License

This project is licensed under the [MIT License](LICENSE).
