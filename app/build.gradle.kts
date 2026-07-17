plugins {
    alias(libs.plugins.android.application)
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

// Detect if the current build is for an Android App Bundle (AAB)
val isBuildingBundle = gradle.startParameter.taskNames.any { it.lowercase().contains("bundle") }

android {
    namespace = "com.oussamateyib.helloworld"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.oussamateyib.helloworld"
        minSdk = 21
        targetSdk = 37
        versionCode = 5
        versionName = "1.1.3"

        externalNativeBuild {
            cmake {
                // CMake build arguments
                arguments(
                    "-DCMAKE_C_STANDARD=23",
                    "-DCMAKE_C_EXTENSIONS=OFF",
                    "-DPLATFORM=Android",
                    "-DBUILD_EXAMPLES=OFF",
                    "-DAPP_LIB_NAME=main",
                )
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/c/CMakeLists.txt")
            // Minimum required version
            version = "3.25.0+"
        }
    }

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
            }
        }
    }

    buildTypes {
        debug {
            isJniDebuggable = true
        }

        release {
            // Enable code shrinking and obfuscation
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
            )

            // Remove unused resources
            isShrinkResources = true

            // Enable link-time optimization
            externalNativeBuild {
                cmake {
                    arguments(
                        "-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON",
                    )
                }
            }

            // Extract native debug symbols
            ndk {
                debugSymbolLevel = "FULL"
            }

            // Apply release signing
            signingConfig = if (System.getenv("STORE_FILE") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug") // Fallback to debug keystore
            }

            // Exclude dependency metadata
            dependenciesInfo {
                includeInApk = false
                includeInBundle = false
            }

            // Exclude VCS metadata
            vcsInfo.include = false
        }
    }

    androidResources {
        generateLocaleConfig = true
    }

    lint {
        checkAllWarnings = true
        checkDependencies = true
        warningsAsErrors = true
    }
}

androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        // Strip Kotlin builtins and metadata
        variant.packaging.resources.excludes.add("kotlin/**")
    }
}
