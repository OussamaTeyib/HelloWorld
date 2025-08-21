// Apply Android application plugin
plugins {
    id("com.android.application")
}

// Android configuration
android {
    // App namespace
    namespace = "com.oussamateyib.helloworld"
    // Compile SDK version
    compileSdk = 36
    // NDK version
    ndkVersion = "28.2.13676358"

    // Default app configuration
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

    // CMake build configuration
    externalNativeBuild {
        cmake {
            path = file("src/main/c/CMakeLists.txt")
            // CMake minimum required version
            version = "3.22.1"
        }
    }

    // ABI splits configuration
    splits {
        abi {
            // Detect if the current build is for an Android App Bundle (AAB)           
            val isBuildingBundle = gradle.startParameter.taskNames.any { it.lowercase().contains("bundle") }
            // Disable ABI splits when building an App Bundle to avoid conflicts
            isEnable = !isBuildingBundle
            // Reset previous ABI split configuration
            reset()
            // Specify the supported ABIs
            include("x86", "x86_64", "armeabi-v7a", "arm64-v8a")
            // Generate a universal APK when ABI splits are enabled
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
            keyPassword = System.getenv("KEY_PASSWORD") ?: System.getenv("STORE_PASSWORD")
        }
    }

    // Build types configuration
    buildTypes {
        getByName("release") {
            // Enable code shrinking and obfuscation
            isMinifyEnabled = true
            // Remove unused resources
            isShrinkResources = true
            // ProGuard configuration
            proguardFiles(getDefaultProguardFile("proguard-android.txt"))
            // Apply release signing
            signingConfig = signingConfigs.getByName("release")
        }
    }
}