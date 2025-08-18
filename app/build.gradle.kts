// Apply Android application plugin
plugins {
    id("com.android.application")
}

// Android configuration block
android {
    // App namespace
    namespace = "com.oussamateyib.helloworld"
    // Compile SDK version
    compileSdk = 36

    // Default app config
    defaultConfig {
        // Application ID
        applicationId = "com.oussamateyib.helloworld"
        // Minimum SDK version
        minSdk = 21
        // Target SDK version
        targetSdk = 36
        // Version code
        versionCode = 2
        // Version name
        versionName = "2.0.0"

        // CMake build arguments
        externalNativeBuild {
            cmake {
                arguments(
                    "-DANDROID_EXTERNAL_HOME=${System.getenv("ANDROID_EXTERNAL_HOME")}",
                    "-DAPP_LIB_NAME=main",
                    "-DCMAKE_C_STANDARD=23",
                    "-DCMAKE_C_EXTENSIONS=OFF"
                )
            }
        }
    }

    // External CMake build config
    externalNativeBuild {
        cmake {
            path = file("src/main/c/CMakeLists.txt")
            // CMake minimum required version
            version = "3.22.1"
        }
    }

    // ABI splits config
    splits {
        abi {
            // Enable ABI splits
            isEnable = true
            reset()
            // Supported ABIs
            include("x86", "x86_64", "armeabi-v7a", "arm64-v8a", "riscv64")
            // Create a universal APK
            isUniversalApk = true
        }
    }

    // Signing configuration
    signingConfigs {
        create("release") {
            // Keystore file
            storeFile = file(System.getenv("STORE_FILE"))
            // Keystore password
            storePassword = System.getenv("STORE_PASSWORD")
            // Key alias
            keyAlias = System.getenv("KEY_ALIAS")
            // Key password
            keyPassword = System.getenv("STORE_PASSWORD")
        }
    }

    // Build types
    buildTypes {
        getByName("release") {
            // Enable code shrinking
            isMinifyEnabled = true
            // ProGuard config
            proguardFiles(getDefaultProguardFile("proguard-android.txt"))
            // Apply release signing
            signingConfig = signingConfigs.getByName("release")
        }
    }
}