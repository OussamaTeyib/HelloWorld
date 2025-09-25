// Apply Android application plugin
plugins {
    alias(libs.plugins.android.application)
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
        versionName = "1.1.0"

        // CMake build arguments
        externalNativeBuild {
            cmake {
                arguments(
                    "-DCMAKE_C_STANDARD=23",
                    "-DCMAKE_C_EXTENSIONS=OFF",
                    "-DPLATFORM=Android",
                    "-DBUILD_EXAMPLES=OFF",
                    "-DAPP_LIB_NAME=main"
                )
            }
        }
    }

    // CMake configuration
    externalNativeBuild {
        cmake {
            path = file("src/main/c/CMakeLists.txt")
            // CMake minimum required version
            version = "4.0.2"
        }
    }

    // Java configuration
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Detect if the current build is for an Android App Bundle (AAB)           
    val isBuildingBundle = gradle.startParameter.taskNames.any { it.lowercase().contains("bundle") }
            
    // ABI splits configuration
    splits {
        abi {
            // Disable ABI splits when building an App Bundle to avoid conflicts
            isEnable = !isBuildingBundle
            // Reset previous ABI split configuration
            reset()
            // Specify the supported ABIs
            include("x86", "x86_64", "armeabi-v7a", "arm64-v8a", "riscv64")
            // Generate a universal APK when ABI splits are enabled
            isUniversalApk = true
        }
    }

    // Signing configuration
    signingConfigs {
        create("release") {
            if (System.getenv("STORE_FILE") != null &&
                System.getenv("STORE_PASSWORD") != null &&
                System.getenv("KEY_ALIAS") != null
            ) {
                storeFile = file(System.getenv("STORE_FILE"))
                storePassword = System.getenv("STORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD") ?: System.getenv("STORE_PASSWORD")
            } else {
                initWith(getByName("debug"))
            }
        }
    }

    // Build types configuration
    buildTypes {
        getByName("debug") {
            isJniDebuggable = true
        }

        getByName("release") {
            // Enable code shrinking and obfuscation
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))

            // Remove unused resources
            isShrinkResources = true

            // Extract native debug symbols
            ndk {
                debugSymbolLevel = "FULL"
            }

            // Apply release signing
            signingConfig = signingConfigs.getByName("release")

            // Exclude dependency metadata
            dependenciesInfo {
                includeInApk = false
                includeInBundle = false
            }

            // Exclude VCS metadata
            vcsInfo.include = false
        }
    }
}