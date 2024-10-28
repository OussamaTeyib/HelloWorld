# Minimum CMake version required for this project
cmake_minimum_required(VERSION 3.5)

# Define the project name and programming language
project(HelloWorld C)

# Define paths for Raylib headers and libraries, retrieved from environment variables
set(RAYLIB_INCLUDE_DIR $ENV{ANDROID_RAYLIB_HOME}/include)
set(RAYLIB_LIB_DIR $ENV{ANDROID_RAYLIB_HOME}/lib/${ANDROID_ABI})

# Define the directory for source files
set(SOURCE_DIR ${CMAKE_SOURCE_DIR}/src)
# Gather all .c files in the source directory
file(GLOB SOURCES "${SOURCE_DIR}/*.c")

# Compile source files into a shared library named "main"
add_library(main SHARED ${SOURCES})

# Specify directories for headers and libraries
target_include_directories(main PUBLIC ${SOURCE_DIR} ${RAYLIB_INCLUDE_DIR})
target_link_directories(main PUBLIC ${RAYLIB_LIB_DIR})

# Set compiler options to enforce standards and security settings
target_compile_options(main PUBLIC
    -std=c17                              # Use C17 standard
    -ffunction-sections -funwind-tables   # Optimize function sections, enable stack unwinding tables
    -fstack-protector-strong -fPIC        # Stack protection and position-independent code
    -Wall -Wa,--noexecstack               # Enable all warnings, disallow executable stack
    -Wformat -Werror=format-security      # Format security settings
    -no-canonical-prefixes                # Avoid prefix normalization for cross-compiling
)
# Define specific flags for ARM-based builds (32-bit and 64-bit)
if(ANDROID_ABI STREQUAL "armeabi-v7a")
    target_compile_options(main PUBLIC -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16)
elseif(ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_options(main PUBLIC -march=armv8-a -mfix-cortex-a53-835769)
endif()

# Define preprocessor macros for Android platform
target_compile_definitions(main PUBLIC
    -D__ANDROID__
    -DPLATFORM_ANDROID
)

# Linker options for additional security and compatibility
target_link_options(main PUBLIC
    -Wl,-soname,libmain.so                   # Set the shared object name
    -Wl,--exclude-libs,libatomic.a           # Exclude atomic library from final linking
    -Wl,--build-id -Wl,--no-undefined        # Include build ID, enforce no undefined symbols
    -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now  # Apply stack, relro, and now flags for security
    -Wl,--warn-shared-textrel -Wl,--fatal-warnings  # Warn and fail on shared text relocations
    -u ANativeActivity_onCreate              # Entry point for native Android activity
)

# Link against essential libraries for Android development
target_link_libraries(main PUBLIC m c raylib log android EGL GLESv2 OpenSLES)

# Set output directory for the shared library
set_target_properties(main PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/${ANDROID_ABI})

# Define directory for APK output and create it if it doesn't exist
set(APK_OUTPUT_DIR outputs)
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR})

# Define the path to the Android manifest file
set(ANDROID_MANIFEST_FILE ${CMAKE_SOURCE_DIR}/AndroidManifest.xml)
# Define resource directory path
set(RESOURCES_PATH ${CMAKE_SOURCE_DIR}/res)
# Gather all resource files within the resource directory
file(GLOB_RECURSE RESOURCE_FILES "${RESOURCES_PATH}/*")
# Path to the Android JAR, used for APK packaging
set(ANDROID_JAR_PATH $ENV{ANDROID_HOME}/platforms/${ANDROID_PLATFORM}/android.jar)

# Build an APK from the shared library, resources, and manifest
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk
    COMMAND aapt package -f -M ${ANDROID_MANIFEST_FILE}  # Include manifest file
            -S ${RESOURCES_PATH}                         # Add resource directory
            -I ${ANDROID_JAR_PATH}                       # Include Android JAR
            -F ${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk
    COMMAND aapt add ${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk lib/${ANDROID_ABI}/libmain.so
    DEPENDS ${CMAKE_BINARY_DIR}/lib/${ANDROID_ABI}/libmain.so  # Build library dependency
            ${ANDROID_MANIFEST_FILE} ${RESOURCE_FILES}         # Manifest and resources as dependencies
    COMMENT "Creating APK package"
)
add_custom_target(create_apk ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk)

# Align the APK package for optimized installation on Android
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.aligned.apk
    COMMAND zipalign -p -f 4  # Align ZIP to 4-byte boundaries
            ${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk
            ${APK_OUTPUT_DIR}/${PROJECT_NAME}.aligned.apk
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk
    COMMENT "Aligning APK package"
)
add_custom_target(align_apk ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.aligned.apk)

# Configure keystore details for APK signing
set(KEYSTORE_FILE ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.keystore)
set(KEYSTORE_PASS "291199")
set(COMMON_NAME "Oussama Teyib")
set(ORGANIZATION "oussamateyib")
set(COUNTRY "MR")

# Generate a keystore for APK signing if it doesn't exist
if(NOT EXISTS ${KEYSTORE_FILE})
    add_custom_command(
        OUTPUT ${KEYSTORE_FILE}
        COMMAND keytool -genkeypair -validity 10000 -keyalg RSA
                -dname "CN=${COMMON_NAME},O=${ORGANIZATION},C=${COUNTRY}"
                -storepass ${KEYSTORE_PASS} -keypass ${KEYSTORE_PASS}
                -alias ${PROJECT_NAME}Key
                -keystore ${KEYSTORE_FILE}
        COMMENT "Generating keystore"
    )
    add_custom_target(generate_key ALL DEPENDS ${KEYSTORE_FILE})
endif()

# Sign the APK package with the generated keystore
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.apk
           ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.apk.idsig
    COMMAND apksigner sign
            --ks ${KEYSTORE_FILE} --ks-key-alias ${PROJECT_NAME}Key
            --ks-pass pass:${KEYSTORE_PASS} --key-pass pass:${KEYSTORE_PASS}
            --out ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.apk
            ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.aligned.apk
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.aligned.apk
            ${KEYSTORE_FILE}
    COMMENT "Signing APK package"
)
add_custom_target(sign_apk ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.apk)

# Default user ID for APK installation
set(USER_ID 0)

# Install APK on a connected Android emulator/device using ADB
# NOTE: Use -e (emulator) or -d (device) parameters if necessary
add_custom_target(install_apk
    COMMAND adb install --user ${USER_ID} ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.apk
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.apk
    COMMENT "Installing APK package"
)

# Define application package name for uninstallation
set(APP_PACKAGE_NAME "com.oussamateyib.helloworld")

# Uninstall the application from the connected device
add_custom_target(uninstall_apk
    COMMAND adb uninstall --user ${USER_ID} ${APP_PACKAGE_NAME}
    COMMENT "Uninstalling APK package"
)

# Start monitoring log output from the device, filtered by Raylib logs only
add_custom_target(logcat
    COMMAND adb logcat -c                  # Clear previous log output
    COMMAND adb logcat raylib:V *:S        # Show only Raylib-related logs
    COMMENT "Monitoring device log output"
)

# Check the supported ABI for the connected device
add_custom_target(check_device_abi
    COMMAND adb shell getprop ro.product.cpu.abi
    COMMENT "Checking device ABI compatibility"
)

# List all current users on the connected Android emulator/device
add_custom_target(list_users
    COMMAND adb shell pm list users
    COMMENT "Listing current users on device"
)