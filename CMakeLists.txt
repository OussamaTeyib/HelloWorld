# Minimum CMake version required for this project
cmake_minimum_required(VERSION 3.10)

# Define the project name, version, and programming language
project(HelloWorld VERSION 1.0.0 LANGUAGES C)

# Set default build type
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Build type (default Debug)" FORCE)
endif()

# Ensure that ANDROID_EXTERNAL_HOME is set
if(NOT DEFINED ENV{ANDROID_EXTERNAL_HOME})
  message(FATAL_ERROR "Environment variable ANDROID_EXTERNAL_HOME is not set. Please set it to proceed.")
endif()

# Define paths for external Android libraries (raylib)
set(EXTERNAL_INCLUDE_DIR $ENV{ANDROID_EXTERNAL_HOME}/include)
set(EXTERNAL_LIB_DIR $ENV{ANDROID_EXTERNAL_HOME}/lib/${ANDROID_ABI})

# Import raylib static library
add_library(raylib STATIC IMPORTED)
set_target_properties(raylib PROPERTIES
  IMPORTED_LOCATION "${EXTERNAL_LIB_DIR}/libraylib.a"
  # Include directories that consumers of raylib should use when compiling
  INTERFACE_INCLUDE_DIRECTORIES "${EXTERNAL_INCLUDE_DIR}"
)

# Define the directory for source files
set(SOURCE_DIR ${CMAKE_SOURCE_DIR}/src)
# Gather all .c files in the source directory
file(GLOB SOURCES "${SOURCE_DIR}/*.c")

# Define the library name
set(LIBRARY_NAME main)

# Compile source files into a shared library
add_library(${LIBRARY_NAME} SHARED ${SOURCES})

# Specify the directory for header files
target_include_directories(${LIBRARY_NAME} PRIVATE ${SOURCE_DIR})

# Specify the C standard to be used
set_property(TARGET ${LIBRARY_NAME} PROPERTY C_STANDARD 23)

# Ensure the entry point for the ANativeActivity is included for the app to launch properly
target_link_options(${LIBRARY_NAME} PRIVATE -u ANativeActivity_onCreate)

# Link against essential libraries for Android development
target_link_libraries(${LIBRARY_NAME} PRIVATE c m android log EGL GLESv2 OpenSLES raylib)

# Set output directory for the shared library
set_target_properties(${LIBRARY_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/${ANDROID_ABI})

# Ensure that ANDROID_HOME is set
if(NOT DEFINED ENV{ANDROID_HOME})
  message(FATAL_ERROR "Environment variable ANDROID_HOME is not set. Please set it to proceed.")
endif()

# Set the APK output file name
set(APK_OUTPUT_NAME ${PROJECT_NAME}_v${PROJECT_VERSION}_${ANDROID_ABI})

# Define the output directory for APKs and ensure it exists
set(APK_OUTPUT_DIR outputs)
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR})

# Define the directory for compiled resources and ensure it exists
set(APK_COMPILED_RES_DIR ${APK_OUTPUT_DIR}/compiled_res)
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${APK_COMPILED_RES_DIR})

# Define the resource directory
set(RES_DIR ${CMAKE_SOURCE_DIR}/res)

# Recursively collect all files under the resource directory
file(GLOB_RECURSE _raw_RES_FILES "${RES_DIR}/*")

# Convert resource file paths to native format (required by aapt2)
set(RES_FILES "")
foreach(_raw_res_file IN LISTS _raw_RES_FILES)
  file(TO_NATIVE_PATH "${_raw_res_file}" res_file)
  list(APPEND RES_FILES "${res_file}")
endforeach()

# Generate a list of expected compiled resource files (.flat)
set(COMPILED_RES_FILES "")
foreach(res_file IN LISTS RES_FILES)
  # Compute path relative to the resource root (res/)
  file(RELATIVE_PATH res_file_relative_path "${RES_DIR}" "${res_file}")
  # Replace path separators with underscores for .flat file naming
  string(REPLACE "/" "_" res_file_relative_path "${res_file_relative_path}")
  string(REPLACE "\\" "_" res_file_relative_path "${res_file_relative_path}")
	
  # Special handling for XML files under res/values/
  if(res_file_relative_path MATCHES "values_.*$")
    # Rename .xml to .arsc for values resources
    string(REGEX REPLACE "\\.xml$" ".arsc" res_file_relative_path "${res_file_relative_path}")
  endif()
	
  # Append expected compiled .flat file
  list(APPEND COMPILED_RES_FILES "${APK_COMPILED_RES_DIR}/${res_file_relative_path}.flat")
endforeach()

# Compile APK resource files
add_custom_command(
  OUTPUT ${COMPILED_RES_FILES}
  COMMAND aapt2 compile
          ${RES_FILES}
          -o ${CMAKE_BINARY_DIR}/${APK_COMPILED_RES_DIR}
  DEPENDS ${RES_FILES}                    # Resource files as dependencies
  COMMENT "Compiling APK resources"
)

# Path to the AndroidManifest.xml file
set(ANDROID_MANIFEST_FILE ${CMAKE_SOURCE_DIR}/AndroidManifest.xml)

# Target SDK version
set(TARGET_SDK 36)
# Path to the Android SDK platform JAR for linking
set(ANDROID_JAR_PATH $ENV{ANDROID_HOME}/platforms/android-${TARGET_SDK}/android.jar)

# Create an APK by linking compiled resources, manifest, and shared library
add_custom_command(
  OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk
  COMMAND aapt2 link
          -o ${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk
          ${COMPILED_RES_FILES}                        # Compiled resources
          -I ${ANDROID_JAR_PATH}                       # Android platform JAR
          --manifest ${ANDROID_MANIFEST_FILE}          # AndroidManifest.xml
  COMMAND zip -u ${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk lib/${ANDROID_ABI}/lib${LIBRARY_NAME}.so
  DEPENDS ${CMAKE_BINARY_DIR}/lib/${ANDROID_ABI}/lib${LIBRARY_NAME}.so  # Shared library as a dependency
          ${ANDROID_MANIFEST_FILE} ${COMPILED_RES_FILES}                # Manifest and compiled resources as dependencies
  COMMENT "Creating APK package"
)
add_custom_target(create_apk ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk)

# Align the APK package for optimized installation on Android
add_custom_command(
  OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.aligned.apk
  COMMAND zipalign -f                                  # Force overwrite
          -p                                           # Page aligns uncompressed data
          4                                            # Align ZIP to 4-byte boundaries
          ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk
          ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.aligned.apk
  DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.unaligned.apk
  COMMENT "Aligning APK package"
)
add_custom_target(align_apk ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.aligned.apk)

# Set keystore file path
if(DEFINED ENV{KEYSTORE_FILE})
  set(KEYSTORE_FILE $ENV{KEYSTORE_FILE})
else()
  message(FATAL_ERROR "Environment variable KEYSTORE_FILE is not set. Please set it to proceed.")
endif()

# Set keystore password
if(DEFINED ENV{KEYSTORE_PASS})
  set(KEYSTORE_PASS $ENV{KEYSTORE_PASS})
else()
  message(FATAL_ERROR "Environment variable KEYSTORE_PASS is not set. Please set it to proceed.")
endif()

# Set key alias for signing
if(DEFINED ENV{KEY_ALIAS})
  set(KEY_ALIAS $ENV{KEY_ALIAS})
else()
  message(FATAL_ERROR "Environment variable KEY_ALIAS is not set. Please set it to proceed.")
endif()

# Set key password or fallback to keystore password
if(DEFINED ENV{KEY_PASS})
  set(KEY_PASS $ENV{KEY_PASS})
elseif(DEFINED ENV{KEYSTORE_PASS})
  set(KEY_PASS $ENV{KEYSTORE_PASS})
else()
  message(FATAL_ERROR "Neither KEY_PASS nor KEYSTORE_PASS environment variables are set. One of them must be defined.")
endif()

# Sign the APK package
add_custom_command(
  OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk
         ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk.idsig
  COMMAND apksigner sign
          --ks ${KEYSTORE_FILE} --ks-pass pass:${KEYSTORE_PASS}
          --ks-key-alias ${KEY_ALIAS} --key-pass pass:${KEY_PASS}
          --out ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk
          ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.aligned.apk
  DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.aligned.apk
  COMMENT "Signing APK package"
)
add_custom_target(sign_apk ALL
  DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk
          ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}.apk.idsig
)

# Set default USER_ID if not specified by user
if(NOT DEFINED USER_ID)
  set(USER_ID 0 CACHE STRING "User ID (default 0)")
endif()

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