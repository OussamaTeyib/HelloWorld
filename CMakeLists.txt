# Minimum required CMake version for this project
cmake_minimum_required(VERSION 4.0.2)

# Define the project name and version
project(HelloWorld VERSION 1.0.0 LANGUAGES NONE)

# Set default build type to Debug if none specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Build type (default Debug)" FORCE)
endif()

# Verify that ANDROID_HOME is set
if(DEFINED ENV{ANDROID_HOME})
  set(ANDROID_HOME "$ENV{ANDROID_HOME}")
else()
  message(FATAL_ERROR "Environment variable ANDROID_HOME is not set. Please set it to proceed.")
endif()

# Verify that ANDROID_NDK_HOME is set
if(DEFINED ENV{ANDROID_NDK_HOME})
  set(ANDROID_NDK_HOME "$ENV{ANDROID_NDK_HOME}")
else()
  message(FATAL_ERROR "Environment variable ANDROID_NDK_HOME is not set. Please set it to proceed.")
endif()

# Supported Android ABIs
if(DEFINED ABIS)
  set(APP_TARGET_ABIS ${ABIS})
else()
  set(APP_TARGET_ABIS "armeabi-v7a;arm64-v8a;x86;x86_64;riscv64" CACHE STRING "Target ABIs")
endif()

# Minimum SDK version
if(DEFINED MIN_SDK)
  set(APP_MIN_SDK ${MIN_SDK})
else()
  set(APP_MIN_SDK "21" CACHE STRING "Minimum SDK version")
endif()

# Set app output file name
set(APP_OUTPUT_NAME "${PROJECT_NAME}_v${PROJECT_VERSION}")

# Set app package name
set(APP_PACKAGE_NAME "com.oussamateyib.helloworld")

# Set native library name
set(APP_LIB_NAME "main")

# Define output directories for APKs, AABs, and intermediate files
set(APP_OUTPUT_DIR "outputs")
set(APP_INTERM_DIR "intermediates")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/${APP_OUTPUT_DIR}")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/${APP_INTERM_DIR}")

# Include the ExternalProject module
include(ExternalProject)

# Build the native library for each ABI
foreach(ABI IN LISTS APP_TARGET_ABIS)
  ExternalProject_Add(${APP_LIB_NAME}_${ABI}
    SOURCE_DIR "${CMAKE_SOURCE_DIR}/app/src/main/c"
    BINARY_DIR "${CMAKE_BINARY_DIR}/lib/${ABI}"
    CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake
               -DANDROID_ABI=${ABI}
               -DANDROID_PLATFORM=${APP_MIN_SDK}
               -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
               -DCMAKE_C_STANDARD=23
               -DCMAKE_C_EXTENSIONS=OFF
               -DPLATFORM=Android
               -DBUILD_EXAMPLES=OFF
               -DAPP_LIB_NAME=${APP_LIB_NAME}
    BUILD_BYPRODUCTS "lib/${ABI}/lib${APP_LIB_NAME}.so"
    BUILD_ALWAYS 1
    INSTALL_COMMAND ""
  )
endforeach()

# Collect all ABI-specific shared libraries into a single list
set(APP_ALL_SHARED_LIBS "")
foreach(ABI IN LISTS APP_TARGET_ABIS)
  list(APPEND APP_ALL_SHARED_LIBS "lib/${ABI}/lib${APP_LIB_NAME}.so")
endforeach()

# Get the number of target ABIs
list(LENGTH APP_TARGET_ABIS ABI_COUNT)
# If more than one ABI is targeted, add a 'universal' option for fat APK
if(ABI_COUNT GREATER 1)
    list(APPEND APP_TARGET_ABIS "universal")
endif()

# Define resource directories
set(APP_RES_DIR "${CMAKE_SOURCE_DIR}/app/src/main/res")
set(APP_COMPILED_RES_DIR "${CMAKE_BINARY_DIR}/${APP_INTERM_DIR}/compiled_res")
file(MAKE_DIRECTORY "${APP_COMPILED_RES_DIR}")

# Collect all resource files and convert paths to native format (required by aapt2)
file(GLOB_RECURSE _raw_APP_RES_FILES "${APP_RES_DIR}/*")
set(APP_RES_FILES "")
foreach(_raw_app_res_file IN LISTS _raw_APP_RES_FILES)
  file(TO_NATIVE_PATH "${_raw_app_res_file}" app_res_file)
  list(APPEND APP_RES_FILES "${app_res_file}")
endforeach()

# Compile resource files
execute_process(
  COMMAND aapt2 compile
          ${APP_RES_FILES}
          -o "${APP_COMPILED_RES_DIR}"
)
# Re-run configuration if any resource file changes
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${APP_RES_FILES})

# Collect all compiled resource files (*.flat)
file(GLOB APP_COMPILED_RES_FILES "${APP_COMPILED_RES_DIR}/*.flat")

# Define the path to manifest file
set(APP_MANIFEST_FILE "${CMAKE_SOURCE_DIR}/app/src/main/AndroidManifest.xml")

# Set compile SDK version
set(APP_COMPILE_SDK "36")
# Define the path to Android SDK platform JAR
set(ANDROID_JAR_FILE "${ANDROID_HOME}/platforms/android-${APP_COMPILE_SDK}/android.jar")

# Create APK packages for each ABI from compiled resources and manifest
foreach(ABI IN LISTS APP_TARGET_ABIS)
  add_custom_command(
    OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.base.apk"
    COMMAND aapt2 link
            -o "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.base.apk"
            ${APP_COMPILED_RES_FILES}
            -I "${ANDROID_JAR_FILE}"
            --manifest "${APP_MANIFEST_FILE}"
    DEPENDS "${APP_MANIFEST_FILE}"
            ${APP_COMPILED_RES_FILES}
    COMMENT "Creating APK package (${ABI})"
  )
  add_custom_target(create_apk_${ABI} ALL DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.base.apk")
endforeach()

# Add compiled code to APK packages for each ABI
foreach(ABI IN LISTS APP_TARGET_ABIS)
  # For ABI-specific APKs, add ABI-specific shared library
  if(NOT ABI STREQUAL "universal")
    add_custom_command(
      OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      COMMAND zip -u "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.base.apk" "lib/${ABI}/lib${APP_LIB_NAME}.so"
	  COMMAND ${CMAKE_COMMAND} -E copy
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.base.apk"
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.base.apk"
              "lib/${ABI}/lib${APP_LIB_NAME}.so"
      COMMENT "Adding compiled code (${ABI})"
    )
  # For the universal APK, add all shared libraries
  else()
    add_custom_command(
      OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      COMMAND zip -u "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.base.apk" ${APP_ALL_SHARED_LIBS}
      COMMAND ${CMAKE_COMMAND} -E copy
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.base.apk"
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.base.apk"
              ${APP_ALL_SHARED_LIBS}
      COMMENT "Adding compiled code (${ABI})"
    )
  endif()
  add_custom_target(add_compiled_code_${ABI} ALL DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk")
endforeach()

# Align the APK packages for optimized installation
foreach(ABI IN LISTS APP_TARGET_ABIS)
  add_custom_command(
    OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
    COMMAND zipalign -f -p 4
            "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
            "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
    DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
    COMMENT "Aligning APK package (${ABI})"
  )
  add_custom_target(align_apk_${ABI} ALL DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.aligned.apk")
endforeach()

# For debug builds, use default keystore
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  # Determine the user's home directory based on platform
  if(WIN32)
    set(USER_HOME "$ENV{USERPROFILE}")
  else()
    set(USER_HOME "$ENV{HOME}")
  endif()

  # Use the default Android debug keystore
  set(APP_STORE_FILE "${USER_HOME}/.android/debug.keystore")
  set(APP_STORE_PASSWORD "android")
  set(APP_KEY_ALIAS "androiddebugkey")
  set(APP_KEY_PASSWORD "android")
# For release builds, use credentials from environment variables
else()
  # Keystore path (must be set)
  if(DEFINED ENV{STORE_FILE})
    set(APP_STORE_FILE "$ENV{STORE_FILE}")
  else()
    message(FATAL_ERROR "Environment variable STORE_FILE is not set. Please set it to proceed.")
  endif()

  # Keystore password (must be set)
  if(DEFINED ENV{STORE_PASSWORD})
    set(APP_STORE_PASSWORD "$ENV{STORE_PASSWORD}")
  else()
    message(FATAL_ERROR "Environment variable STORE_PASSWORD is not set. Please set it to proceed.")
  endif()

  # Key alias (must be set)
  if(DEFINED ENV{KEY_ALIAS})
    set(APP_KEY_ALIAS "$ENV{KEY_ALIAS}")
  else()
    message(FATAL_ERROR "Environment variable KEY_ALIAS is not set. Please set it to proceed.")
  endif()

  # Key password (optional: fallback to keystore password if not set)
  if(DEFINED ENV{KEY_PASSWORD})
    set(APP_KEY_PASSWORD "$ENV{KEY_PASSWORD}")
  elseif(DEFINED ENV{STORE_PASSWORD})
    set(APP_KEY_PASSWORD "$ENV{STORE_PASSWORD}")
  else()
    message(FATAL_ERROR "Neither KEY_PASSWORD nor STORE_PASSWORD environment variables are set. One of them must be defined.")
  endif()

endif()

# Sign the APK packages
foreach(ABI IN LISTS APP_TARGET_ABIS)
  add_custom_command(
    OUTPUT "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk"
           "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk.idsig"
    COMMAND apksigner sign
            --ks "${APP_STORE_FILE}" --ks-pass pass:"${APP_STORE_PASSWORD}"
            --ks-key-alias "${APP_KEY_ALIAS}" --key-pass pass:"${APP_KEY_PASSWORD}"
            --out "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk"
            "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
    DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
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
  # Link compiled resource files, manifest, and platform JAR into a zip
  COMMAND aapt2 link
          --proto-format                          # Generate resource table in protobuf format
          -o "${APP_INTERM_DIR}/base.zip"
          ${APP_COMPILED_RES_FILES}
          --auto-add-overlay                      # Automatically overlay resources
          -I "${ANDROID_JAR_FILE}"
          --manifest "${APP_MANIFEST_FILE}"
  # Move the manifest to its expected path within the zip
  COMMAND ${CMAKE_COMMAND} -E make_directory "${APP_INTERM_DIR}/manifest"
  COMMAND unzip -o "${APP_INTERM_DIR}/base.zip" "AndroidManifest.xml" -d "${APP_INTERM_DIR}/manifest"
  COMMAND zip -d "${APP_INTERM_DIR}/base.zip" "AndroidManifest.xml"
  COMMAND ${CMAKE_COMMAND} -E chdir "${APP_INTERM_DIR}" zip -u "base.zip" "manifest/AndroidManifest.xml"
  # Add native shared libraries to the zip
  COMMAND zip -u "${APP_INTERM_DIR}/base.zip" ${APP_ALL_SHARED_LIBS}
  # Build the AAB bundle from the zip
  COMMAND bundletool build-bundle
          --modules="${APP_INTERM_DIR}/base.zip"
          --output="${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.unsigned.aab"
          --overwrite
  # Sign the AAB bundle
  COMMAND jarsigner
          -keystore "${APP_STORE_FILE}" -storepass "${APP_STORE_PASSWORD}"
          -signedjar "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
          "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.unsigned.aab"
          "${APP_KEY_ALIAS}"
  DEPENDS "${APP_MANIFEST_FILE}"
          ${APP_COMPILED_RES_FILES}
          ${APP_ALL_SHARED_LIBS}
  COMMENT "Creating AAB bundle"
)
add_custom_target(create_aab DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab")

# Install the AAB bundle
add_custom_target(install_aab
  # Build the APK set (.apks) from the AAB bundle
  COMMAND bundletool build-apks
          --bundle="${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
          --output="${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.apks"
          --ks "${APP_STORE_FILE}" --ks-pass pass:"${APP_STORE_PASSWORD}"
          --ks-key-alias "${APP_KEY_ALIAS}" --key-pass pass:"${APP_KEY_PASSWORD}"
          --connected-device
          --overwrite
  # Install the generated .apks to the connected device
  COMMAND bundletool install-apks --apks="${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.apks"
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
set(APP_INTERM_FILES
  "${APP_INTERM_DIR}/base.zip"
  "${APP_INTERM_DIR}/manifest/AndroidManifest.xml"
  "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.unsigned.aab"
  "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.apks"
)
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES "${APP_INTERM_FILES}")