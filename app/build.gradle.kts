// Apply Android application plugin
plugins {
    alias(libs.plugins.android.application)
}

// Android configuration
android {
    // Application configuration
    namespace = "com.oussamateyib.helloworld"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.oussamateyib.helloworld"
        minSdk = 21
        targetSdk = 36
        versionCode = 4
        versionName = "1.1.2"

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
            // Minimum required version
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
            // Use environment variables if provided
            if (System.getenv("STORE_FILE") != null &&
                System.getenv("STORE_PASSWORD") != null &&
                System.getenv("KEY_ALIAS") != null
            ) {
                storeFile = file(System.getenv("STORE_FILE"))
                storePassword = System.getenv("STORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD") ?: System.getenv("STORE_PASSWORD")
            } else {
                // Fallback to debug keystore
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

    // lint configuration
    lint {
        checkAllWarnings = true
        warningsAsErrors = true
    }
}