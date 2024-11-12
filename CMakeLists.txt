# Minimum CMake version required for this project
cmake_minimum_required(VERSION 3.5)

# Define the project name, version, and programming language
project(HelloWorld VERSION 1.0.0 LANGUAGES C)

# Ensure that ANDROID_RAYLIB_HOME is set
if(NOT DEFINED ENV{ANDROID_RAYLIB_HOME})
    message(FATAL_ERROR "Environment variable ANDROID_RAYLIB_HOME is not set. Please set it to proceed.")
endif()

# Define paths for Raylib headers and libraries
set(RAYLIB_INCLUDE_DIR $ENV{ANDROID_RAYLIB_HOME}/include)
set(RAYLIB_LIB_DIR $ENV{ANDROID_RAYLIB_HOME}/lib/${ANDROID_ABI})

# Define the directory for source files
set(SOURCE_DIR ${CMAKE_SOURCE_DIR}/src)
# Gather all .c files in the source directory
file(GLOB SOURCES "${SOURCE_DIR}/*.c")

# Define the library name
set(LIBRARY_NAME main)
# Compile source files into a shared library
add_library(${LIBRARY_NAME} SHARED ${SOURCES})

# Specify directories for headers and libraries
target_include_directories(${LIBRARY_NAME} PUBLIC ${SOURCE_DIR} ${RAYLIB_INCLUDE_DIR})
target_link_directories(${LIBRARY_NAME} PUBLIC ${RAYLIB_LIB_DIR})

# Set compiler options to enforce standards and security settings
target_compile_options(${LIBRARY_NAME} PUBLIC
    -std=c17                          # Use C17 standard
    -fPIC                             # Generate position-independent code, required for shared libraries
    -fstack-protector-strong          # Enable stronger stack protection to prevent stack overflows
    -Wa,--noexecstack                 # Disallow executable stack to protect against stack-based buffer overflow attacks
    -funwind-tables                   # Generate stack unwinding tables to support stack traceability and exception handling
    -ffunction-sections               # Place each function in its own section to allow the linker to remove unused code
    -no-canonical-prefixes            # Avoid automatic prefix normalization, which can interfere with cross-compiling
    -Wformat -Werror=format-security  # Enable warnings for format string vulnerabilities and treat them as errors
    -Wall -Wextra                     # Enable all warnings
)

# Define specific flags for platform-specific builds
if(ANDROID_ABI STREQUAL "armeabi-v7a")
    target_compile_options(${LIBRARY_NAME} PUBLIC 
        -march=armv7-a                # Target ARMv7-A architecture
        -mfloat-abi=softfp            # Use softfp ABI for floating-point
        -mfpu=vfpv3-d16               # Enable VFPv3 with 16 registers
    )
elseif(ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_options(${LIBRARY_NAME} PUBLIC 
        -march=armv8-a                # Target ARMv8-A architecture (64-bit)
        -mfix-cortex-a53-835769       # Fix Cortex-A53 branch prediction bug
    )
elseif(ANDROID_ABI STREQUAL "x86")
    target_compile_options(${LIBRARY_NAME} PUBLIC 
        -march=i686                   # Target Intel i686 architecture
        -mtune=atom                   # Optimize for Intel Atom processors
        -mstackrealign                # Ensure stack is realigned to 16-byte boundaries
    )
elseif(ANDROID_ABI STREQUAL "x86_64")
    target_compile_options(${LIBRARY_NAME} PUBLIC 
        -march=x86-64                 # Target x86-64 architecture
        -mtune=intel                  # Optimize for Intel processors
        -mfpmath=sse                  # Use SSE for floating-point math
    )
endif()

# Define preprocessor macros for Android platform
target_compile_definitions(${LIBRARY_NAME} PUBLIC
    -D__ANDROID__
    -DPLATFORM_ANDROID
)

# Linker options for additional security and compatibility
target_link_options(${LIBRARY_NAME} PUBLIC
    -Wl,--no-undefined                 # Make sure all symbols used in the code are defined and available
    -u ANativeActivity_onCreate        # Ensure the entry point for the ANativeActivity is included for the app to launch properly
    -Wl,-z,noexecstack                 # Make the stack non-executable to protect against stack-based buffer overflow attacks
    -Wl,-z,relro                       # Enable Relocation Read-Only (RELRO) for added memory protection
    -Wl,-z,now                         # Force immediate symbol resolution to reduce runtime attack surface
    -Wl,--build-id                     # Include a unique build ID in the output file to aid in tracking/debugging
    -Wl,-soname,lib${LIBRARY_NAME}.so  # Set the shared object name for dynamic linking and version control
    -Wl,--exclude-libs,libatomic.a     # Exclude the atomic library since Android supports atomic operations natively
    -Wl,--warn-shared-textrel          # Warn about shared text relocations to highlight potential security and performance issues
    -Wl,--fatal-warnings               # Treat all warnings as fatal errors
)

# Link against essential libraries for Android development
target_link_libraries(${LIBRARY_NAME} PUBLIC m c raylib.a log android EGL GLESv2 OpenSLES)

# Set output directory for the shared library
set_target_properties(${LIBRARY_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/${ANDROID_ABI})

# Define directory for APK output and create it if it doesn't exist
set(APK_OUTPUT_DIR outputs)
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR})
# Define APK output name
set(APK_OUTPUT_NAME ${PROJECT_NAME}_v${PROJECT_VERSION}_${ANDROID_ABI})

# Ensure that ANDROID_HOME is set
if(NOT DEFINED ENV{ANDROID_HOME})
    message(FATAL_ERROR "Environment variable ANDROID_HOME is not set. Please set it to proceed.")
endif()

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
    OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk
    COMMAND aapt package -f -M ${ANDROID_MANIFEST_FILE}  # Include manifest file
            -S ${RESOURCES_PATH}                         # Add resource directory
            -I ${ANDROID_JAR_PATH}                       # Include Android JAR
            -F ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk
    COMMAND aapt add ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk lib/${ANDROID_ABI}/lib${LIBRARY_NAME}.so
    DEPENDS ${CMAKE_BINARY_DIR}/lib/${ANDROID_ABI}/lib${LIBRARY_NAME}.so  # Build library dependency
            ${ANDROID_MANIFEST_FILE} ${RESOURCE_FILES}                    # Manifest and resources as dependencies
    COMMENT "Creating APK package"
)
add_custom_target(create_apk ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk)

# Align the APK package for optimized installation on Android
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.aligned.apk
    COMMAND zipalign -p -f 4  # Align ZIP to 4-byte boundaries
            ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk
            ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.aligned.apk
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk
    COMMENT "Aligning APK package"
)
add_custom_target(align_apk ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.aligned.apk)

# Ensure that KEYSTORE_FILE and KEYSTORE_PASS are set
if(NOT DEFINED ENV{KEYSTORE_FILE} OR NOT DEFINED ENV{KEYSTORE_PASS})
    message(FATAL_ERROR "Environment variables KEYSTORE_FILE or KEYSTORE_PASS are not set. Please set these to proceed.")
endif()

# Set the keystore file and password
set(KEYSTORE_FILE $ENV{KEYSTORE_FILE})
set(KEYSTORE_PASS $ENV{KEYSTORE_PASS})

# Sign the APK package
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk
           ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk.idsig
    COMMAND apksigner sign
            --ks ${KEYSTORE_FILE} --ks-key-alias ${PROJECT_NAME}Key
            --ks-pass pass:${KEYSTORE_PASS} --key-pass pass:${KEYSTORE_PASS}
            --out ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk
            ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.aligned.apk
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.aligned.apk
    COMMENT "Signing APK package"
)
add_custom_target(sign_apk ALL
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk
            ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk.idsig
)

# Default user ID for APK installation
set(USER_ID 0)

# Install APK on a connected Android emulator/device using ADB
# NOTE: Use -e (emulator) or -d (device) parameters if necessary
add_custom_target(install_apk
    COMMAND adb install --user ${USER_ID} ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk
    COMMENT "Installing APK package"
)

# Define application package name for uninstallation
set(APK_PACKAGE_NAME "com.oussamateyib.helloworld")

# Uninstall the application from the connected device
add_custom_target(uninstall_apk
    COMMAND adb uninstall --user ${USER_ID} ${APK_PACKAGE_NAME}
    COMMENT "Uninstalling APK package"
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