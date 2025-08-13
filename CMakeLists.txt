# Minimum CMake version required for this project
cmake_minimum_required(VERSION 3.22.1)

# Define the project name and version
project(HelloWorld VERSION 1.0.0 LANGUAGES NONE)

# Default build type (if not set)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Build type (default Debug)" FORCE)
endif()

# Ensure that ANDROID_HOME is set
if(DEFINED ENV{ANDROID_HOME})
  set(ANDROID_HOME "$ENV{ANDROID_HOME}")
else()
  message(FATAL_ERROR "Environment variable ANDROID_HOME is not set. Please set it to proceed.")
endif()

# Ensure that ANDROID_NDK_HOME is set
if(DEFINED ENV{ANDROID_NDK_HOME})
  set(ANDROID_NDK_HOME "$ENV{ANDROID_NDK_HOME}")
else()
  message(FATAL_ERROR "Environment variable ANDROID_NDK_HOME is not set. Please set it to proceed.")
endif()

# Ensure that ANDROID_EXTERNAL_HOME is set
if(DEFINED ENV{ANDROID_EXTERNAL_HOME})
  set(ANDROID_EXTERNAL_HOME "$ENV{ANDROID_EXTERNAL_HOME}")
else()
  message(FATAL_ERROR "Environment variable ANDROID_EXTERNAL_HOME is not set. Please set it to proceed.")
endif()

# Default Android ABIs (if not set)
if(NOT DEFINED ABIS)
  set(APP_TARGET_ABIS "armeabi-v7a;arm64-v8a;x86;x86_64" CACHE STRING "Target ABIs")
endif()

# Default minSdkVersion (if not set)
if(NOT DEFINED API_LEVEL)
  set(APP_MIN_API "21" CACHE STRING "Minimum API level (minSdkVersion)")
endif()

# Set the app output file name
set(APP_OUTPUT_NAME "${PROJECT_NAME}_v${PROJECT_VERSION}")

# Set the app package name
set(APP_PACKAGE_NAME "com.oussamateyib.helloworld")

# Set the native library name
set(APP_LIB_NAME "main")

# Load the ExternalProject module
include(ExternalProject)

# Build the native library for each ABI
foreach(ABI IN LISTS APP_TARGET_ABIS)
  ExternalProject_Add(${APP_LIB_NAME}_${ABI}
    SOURCE_DIR "${CMAKE_SOURCE_DIR}/app/src/main/c"
    BINARY_DIR "${CMAKE_BINARY_DIR}/lib/${ABI}"
    CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake
               -DANDROID_ABI=${ABI}
               -DANDROID_PLATFORM=${APP_MIN_API}
               -DAPP_LIB_NAME=${APP_LIB_NAME}
               -DANDROID_EXTERNAL_HOME=${ANDROID_EXTERNAL_HOME}
               -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
               -DCMAKE_C_STANDARD=23
               -DCMAKE_C_EXTENSIONS=OFF
    BUILD_BYPRODUCTS "lib/${ABI}/lib${APP_LIB_NAME}.so"
    BUILD_ALWAYS 1
    INSTALL_COMMAND ""
  )
endforeach()

# Gather all ABI-specific shared libraries into a list
set(APP_SHARED_LIBS "")
foreach(ABI IN LISTS APP_TARGET_ABIS)
  list(APPEND APP_SHARED_LIBS "lib/${ABI}/lib${APP_LIB_NAME}.so")
endforeach()

# Append 'universal' to APP_TARGET_ABIS to support generating a fat APK
list(APPEND APP_TARGET_ABIS "universal")
	  
# Define the output directory for APKs and ensure it exists
set(APP_OUTPUT_DIR "outputs")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/${APP_OUTPUT_DIR}")

# Ensure the temporary directory exists for intermediate files
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/${APP_OUTPUT_DIR}/temp")

# Define the resource directory
set(APP_RES_DIR "${CMAKE_SOURCE_DIR}/app/src/main/res")

# Define the directory for compiled resources and ensure it exists
set(APP_COMPILED_RES_DIR "${CMAKE_BINARY_DIR}/${APP_OUTPUT_DIR}/compiled_res")
file(MAKE_DIRECTORY "${APP_COMPILED_RES_DIR}")

# Recursively collect all files under the resource directory
file(GLOB_RECURSE _raw_APP_RES_FILES "${APP_RES_DIR}/*")

# Convert resource file paths to native format (required by aapt2)
set(APP_RES_FILES "")
foreach(_raw_app_res_file IN LISTS _raw_APP_RES_FILES)
  file(TO_NATIVE_PATH "${_raw_app_res_file}" app_res_file)
  list(APPEND APP_RES_FILES "${app_res_file}")
endforeach()

# Compile the app resource files
execute_process(
  COMMAND aapt2 compile
          ${APP_RES_FILES}
          -o "${APP_COMPILED_RES_DIR}"
)
# Re-run configuration if any resource file changes
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${APP_RES_FILES})

# Collect all compiled resource files (*.flat)
file(GLOB APP_COMPILED_RES_FILES "${APP_COMPILED_RES_DIR}/*.flat")

# Path to the AndroidManifest.xml file
set(APP_MANIFEST_FILE "${CMAKE_SOURCE_DIR}/app/src/main/AndroidManifest.xml")

# Target SDK version
set(APP_TARGET_API "36")
# Path to the Android SDK platform JAR for linking
set(ANDROID_JAR_FILE "${ANDROID_HOME}/platforms/android-${APP_TARGET_API}/android.jar")

# Create APK packages by linking togather compiled resources, manifest, and JAR file 
foreach(ABI IN LISTS APP_TARGET_ABIS)
  add_custom_command(
    OUTPUT "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.base.apk"
    COMMAND aapt2 link
            -o "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.base.apk"
            ${APP_COMPILED_RES_FILES}                       # Compiled resources
            -I "${ANDROID_JAR_FILE}"                        # Android platform JAR
            --manifest "${APP_MANIFEST_FILE}"               # AndroidManifest.xml
    DEPENDS "${APP_MANIFEST_FILE}"                          # Manifest file as a dependency
            ${APP_COMPILED_RES_FILES}                       # Compiled resources as dependencies
    COMMENT "Creating APK package (${ABI})"
  )
  add_custom_target(create_apk_${ABI} ALL DEPENDS "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.base.apk")
endforeach()

# Add compiled code to APK packages for each ABI
foreach(ABI IN LISTS APP_TARGET_ABIS)
  # For ABI-specific APKs (excluding "universal")
  if(NOT ABI STREQUAL "universal")
    add_custom_command(
      OUTPUT "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      COMMAND zip -u "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.base.apk" "lib/${ABI}/lib${APP_LIB_NAME}.so"
	  COMMAND ${CMAKE_COMMAND} -E copy
              "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.base.apk"
              "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      DEPENDS "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.base.apk" # Base APK as a dependency
              "lib/${ABI}/lib${APP_LIB_NAME}.so"                          # Shared library as a dependencies
      COMMENT "Adding shared libraries (${ABI})"
    )
  # For the universal APK (includes shared libraries for all ABIs)
  else()
    add_custom_command(
      OUTPUT "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      COMMAND zip -u "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.base.apk" ${APP_SHARED_LIBS}
      COMMAND ${CMAKE_COMMAND} -E copy
              "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.base.apk"
              "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      DEPENDS "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.base.apk"  # Base APK as a dependency
              ${APP_SHARED_LIBS}                                                               # Shared libraries as dependencies
      COMMENT "Adding shared libraries (${ABI})"
    )
  endif()
  add_custom_target(add_compiled_code_${ABI} ALL DEPENDS "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk")
endforeach()

# Align the APK packages for optimized installation on Android
foreach(ABI IN LISTS APP_TARGET_ABIS)
  add_custom_command(
    OUTPUT "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
    COMMAND zipalign -f -p 4
            "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
            "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
    DEPENDS "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
    COMMENT "Aligning APK package (${ABI})"
  )
  add_custom_target(align_apk_${ABI} ALL DEPENDS "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.aligned.apk")
endforeach()

# Check if the build type is Debug
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  # Determine the user's home directory based on platform
  if(WIN32)
    set(USER_HOME "$ENV{USERPROFILE}")
  else()
    set(USER_HOME "$ENV{HOME}")
  endif()

  # Use the default Android debug keystore for debug builds
  set(APP_KEYSTORE_FILE "${USER_HOME}/.android/debug.keystore")
  set(APP_KEYSTORE_PASS "android")              # Default password for debug keystore
  set(APP_KEY_ALIAS "androiddebugkey")          # Default alias for debug key
  set(APP_KEY_PASS "android")                   # Default password for debug key

# For release builds, require all signing credentials via environment variables
else()
  # Keystore path (must be set)
  if(DEFINED ENV{KEYSTORE_FILE})
    set(APP_KEYSTORE_FILE "$ENV{KEYSTORE_FILE}")
  else()
    message(FATAL_ERROR "Environment variable KEYSTORE_FILE is not set. Please set it to proceed.")
  endif()

  # Keystore password (must be set)
  if(DEFINED ENV{KEYSTORE_PASS})
    set(APP_KEYSTORE_PASS "$ENV{KEYSTORE_PASS}")
  else()
    message(FATAL_ERROR "Environment variable KEYSTORE_PASS is not set. Please set it to proceed.")
  endif()

  # Key alias (must be set)
  if(DEFINED ENV{KEY_ALIAS})
    set(APP_KEY_ALIAS "$ENV{KEY_ALIAS}")
  else()
    message(FATAL_ERROR "Environment variable KEY_ALIAS is not set. Please set it to proceed.")
  endif()

  # Key password (optional: fallback to keystore password if not set)
  if(DEFINED ENV{KEY_PASS})
    set(APP_KEY_PASS "$ENV{KEY_PASS}")
  elseif(DEFINED ENV{KEYSTORE_PASS})
    set(APP_KEY_PASS "$ENV{KEYSTORE_PASS}")
  else()
    message(FATAL_ERROR "Neither KEY_PASS nor KEYSTORE_PASS environment variables are set. One of them must be defined.")
  endif()

endif()

# Sign the APK packages
foreach(ABI IN LISTS APP_TARGET_ABIS)
  add_custom_command(
    OUTPUT "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk"
           "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk.idsig"
    COMMAND apksigner sign
            --ks "${APP_KEYSTORE_FILE}" --ks-pass pass:"${APP_KEYSTORE_PASS}"
            --ks-key-alias "${APP_KEY_ALIAS}" --key-pass pass:"${APP_KEY_PASS}"
            --out "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk"
            "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
    DEPENDS "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
    COMMENT "Signing APK package (${ABI})"
  )
  add_custom_target(sign_apk_${ABI} ALL
    DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk"
            "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk.idsig"
  )
endforeach()

# Install the APK packages
# Use -e (emulator) or -d (device) flags with adb if needed
foreach(ABI IN LISTS APP_TARGET_ABIS)
  add_custom_target(install_apk_${ABI}
    COMMAND adb install "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk"
    DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk"
    COMMENT "Installing APK package (${ABI})"
  )
endforeach()

# Create an Android App Bundle (AAB) from compiled resources and native libraries
add_custom_command(
  OUTPUT "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
  # Link compiled resource files into an APK (intermediate step)
  COMMAND aapt2 link
          --proto-format                               # Use proto format for compatibility with bundletool
          -o "${APP_OUTPUT_DIR}/temp/output.apk"       # Output intermediate APK
          ${APP_COMPILED_RES_FILES}                    # Compiled resource files
          --auto-add-overlay                           # Automatically overlay resources
          -I "${ANDROID_JAR_FILE}"                     # Android platform JAR
          --manifest "${APP_MANIFEST_FILE}"            # AndroidManifest.xml
  # Unzip the APK into the base module directory structure
  COMMAND unzip -o -qq "${APP_OUTPUT_DIR}/temp/output.apk" -d "${APP_OUTPUT_DIR}/temp/base"
  # Create the 'manifest' subdirectory as expected by bundletool
  COMMAND ${CMAKE_COMMAND} -E make_directory "${APP_OUTPUT_DIR}/temp/base/manifest"
  # Move the manifest to its expected location under 'manifest/' in the base module
  COMMAND ${CMAKE_COMMAND} -E rename
          "${APP_OUTPUT_DIR}/temp/base/AndroidManifest.xml"
          "${APP_OUTPUT_DIR}/temp/base/manifest/AndroidManifest.xml"
  # Remove any existing zip to avoid conflicts
  COMMAND ${CMAKE_COMMAND} -E remove -f "${APP_OUTPUT_DIR}/temp/base.zip"
  # Re-zip the base module contents into base.zip (required by bundletool)
  COMMAND ${CMAKE_COMMAND} -E chdir "${APP_OUTPUT_DIR}/temp/base" zip -r ../base.zip *
  # Add native shared libraries to the zip
  COMMAND zip -u "${APP_OUTPUT_DIR}/temp/base.zip" ${APP_SHARED_LIBS}
  # Build the AAB file from base.zip
  COMMAND bundletool build-bundle
          --modules="${APP_OUTPUT_DIR}/temp/base.zip"
          --output="${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}.unsigned.aab"
          --overwrite
  # Sign the AAB bundle
  COMMAND jarsigner
          -keystore "${APP_KEYSTORE_FILE}" -storepass "${APP_KEYSTORE_PASS}"
          -signedjar "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
          "${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}.unsigned.aab"
          "${APP_KEY_ALIAS}"
  DEPENDS "${APP_MANIFEST_FILE}"                       # Manifest file as a dependency
          ${APP_COMPILED_RES_FILES}                    # Compiled resources as dependencies
          ${APP_SHARED_LIBS}                           # Shared libraries as dependencies
  COMMENT "Creating AAB bundle"
)
add_custom_target(create_aab DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab")

# Install the AAB bundle
add_custom_target(install_aab
  # Build the APK set (.apks) from the AAB bundle
  COMMAND bundletool build-apks
          --bundle="${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
          --output="${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}.apks"
          --ks "${APP_KEYSTORE_FILE}" --ks-pass pass:"${APP_KEYSTORE_PASS}"
          --ks-key-alias "${APP_KEY_ALIAS}" --key-pass pass:"${APP_KEY_PASS}"
          --connected-device
          --overwrite
  # Install the generated .apks to the connected device
  COMMAND bundletool install-apks --apks="${APP_OUTPUT_DIR}/temp/${APP_OUTPUT_NAME}.apks"
  DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
  COMMENT "Installing the AAB bundle"
)

# Uninstall the application from the connected device/emulator
add_custom_target(uninstall_app
  COMMAND adb uninstall ${APP_PACKAGE_NAME}
  COMMENT "Uninstalling the app package"
)

# Display the supported ABIs on the connected device/emulator
add_custom_target(check_abi
  COMMAND ${CMAKE_COMMAND} -E echo "Primary ABI:"
  COMMAND adb shell getprop ro.product.cpu.abi
  COMMAND ${CMAKE_COMMAND} -E echo "Supported ABIs:"
  COMMAND adb shell getprop ro.product.cpu.abilist
  COMMENT "Checking ABI compatibility"
)

# Register untracked intermediate files for cleanup
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES "${APP_OUTPUT_DIR}/temp")