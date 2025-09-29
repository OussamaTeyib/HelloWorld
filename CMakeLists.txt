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

# Target Android ABIs
if(DEFINED ABIS)
  set(APP_TARGET_ABIS ${ABIS})
else()
  set(APP_TARGET_ABIS "armeabi-v7a;arm64-v8a;x86;x86_64;riscv64" CACHE STRING "Target Android ABIs")
endif()

# Debug symbols level
if(DEFINED DEBUG_SYMBOLS_LEVEL)
  set(APP_DEBUG_SYMBOLS_LEVEL ${DEBUG_SYMBOLS_LEVEL})
else()
  set(APP_DEBUG_SYMBOLS_LEVEL "FULL" CACHE STRING "Debug symbols level")
endif()

# Minimum SDK version
if(DEFINED MIN_SDK)
  set(APP_MIN_SDK ${MIN_SDK})
else()
  set(APP_MIN_SDK "21" CACHE STRING "Minimum SDK version")
endif()

# Compile SDK version
if(DEFINED COMPILE_SDK)
  set(APP_COMPILE_SDK ${COMPILE_SDK})
else()
  set(APP_COMPILE_SDK "36" CACHE STRING "Compile SDK version")
endif()

# Target SDK version
if(DEFINED TARGET_SDK)
  set(APP_TARGET_SDK ${TARGET_SDK})
else()
  set(APP_TARGET_SDK "36" CACHE STRING "Target SDK version")
endif()

# App version code
if(DEFINED VERSION_CODE)
  set(APP_VERSION_CODE ${VERSION_CODE})
else()
  set(APP_VERSION_CODE "1" CACHE STRING "App version code")
endif()

# App version name
if(DEFINED VERSION_NAME)
  set(APP_VERSION_NAME ${VERSION_NAME})
else()
  set(APP_VERSION_NAME "${PROJECT_VERSION}" CACHE STRING "App version name")
endif()

# App output file name
if(DEFINED OUTPUT_NAME)
  set(APP_OUTPUT_NAME ${OUTPUT_NAME})
else()
  set(APP_OUTPUT_NAME "${PROJECT_NAME}_v${APP_VERSION_NAME}" CACHE STRING "App output file name")
endif()

# App package name
if(DEFINED PACKAGE_NAME)
  set(APP_PACKAGE_NAME ${PACKAGE_NAME})
else()
  set(APP_PACKAGE_NAME "com.oussamateyib.helloworld" CACHE STRING "App package name")
endif()

# Native library name
if(DEFINED LIB_NAME)
  set(APP_LIB_NAME ${LIB_NAME})
else()
  set(APP_LIB_NAME "main" CACHE STRING "Native library name")
endif()

# Target user for APK installation
if(DEFINED USER)
  set(DEVICE_USER ${USER})
else()
  set(DEVICE_USER "current" CACHE STRING "Target user for APK installation")
endif()

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
               -DAPP_LIB_NAME=${APP_LIB_NAME}.unstripped
    BUILD_BYPRODUCTS "lib/${ABI}/lib${APP_LIB_NAME}.unstripped.so"
    BUILD_ALWAYS 1
    INSTALL_COMMAND ""
  )
endforeach()

# Strip debug symbols
foreach(ABI IN LISTS APP_TARGET_ABIS)
  if(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    add_custom_command(
      OUTPUT "lib/${ABI}/lib${APP_LIB_NAME}.so"
      COMMAND llvm-strip --strip-unneeded
              -o "lib/${ABI}/lib${APP_LIB_NAME}.so"
              "lib/${ABI}/lib${APP_LIB_NAME}.unstripped.so" 
      DEPENDS "lib/${ABI}/lib${APP_LIB_NAME}.unstripped.so"
      COMMENT "Stripping debug symbols (${ABI})"
    )
  else()
    # Do nothing
    add_custom_command(
      OUTPUT "lib/${ABI}/lib${APP_LIB_NAME}.so"
      COMMAND ${CMAKE_COMMAND} -E copy
              "lib/${ABI}/lib${APP_LIB_NAME}.unstripped.so"
              "lib/${ABI}/lib${APP_LIB_NAME}.so"
      DEPENDS "lib/${ABI}/lib${APP_LIB_NAME}.unstripped.so"
      COMMENT "Copying unstripped library (${ABI})"
    )
  endif()
  add_custom_target(strip_debug_symbols_${ABI} ALL DEPENDS "lib/${ABI}/lib${APP_LIB_NAME}.so")
endforeach()

# Extract and package debug symbols in release builds
if(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
  set(APP_EXTRACTED_DEBUG_SYMBOLS "")
  # Full debug information extraction
  if(APP_DEBUG_SYMBOLS_LEVEL STREQUAL "FULL")
    foreach(ABI IN LISTS APP_TARGET_ABIS)
      add_custom_command(
        OUTPUT "lib/${ABI}/lib${APP_LIB_NAME}.so.dbg"
        COMMAND llvm-objcopy --only-keep-debug
                "lib/${ABI}/lib${APP_LIB_NAME}.unstripped.so"
                "lib/${ABI}/lib${APP_LIB_NAME}.so.dbg"
        DEPENDS "lib/${ABI}/lib${APP_LIB_NAME}.unstripped.so"
        COMMENT "Extracting debug symbols (${ABI})"
      )
      add_custom_target(extract_debug_symbols_${ABI} ALL DEPENDS "lib/${ABI}/lib${APP_LIB_NAME}.so.dbg")

      list(APPEND APP_EXTRACTED_DEBUG_SYMBOLS "lib/${ABI}/lib${APP_LIB_NAME}.so.dbg")
    endforeach()
  # Strip down to symbol table only
  elseif(APP_DEBUG_SYMBOLS_LEVEL STREQUAL "SYMBOL_TABLE")
        foreach(ABI IN LISTS APP_TARGET_ABIS)
      add_custom_command(
        OUTPUT "lib/${ABI}/lib${APP_LIB_NAME}.so.sym"
        COMMAND llvm-objcopy --strip-debug
                "lib/${ABI}/lib${APP_LIB_NAME}.unstripped.so"
                "lib/${ABI}/lib${APP_LIB_NAME}.so.sym"
        DEPENDS "lib/${ABI}/lib${APP_LIB_NAME}.unstripped.so"
        COMMENT "Extracting debug symbols (${ABI})"
      )
      add_custom_target(extract_debug_symbols_${ABI} ALL DEPENDS "lib/${ABI}/lib${APP_LIB_NAME}.so.sym")

      list(APPEND APP_EXTRACTED_DEBUG_SYMBOLS "lib/${ABI}/lib${APP_LIB_NAME}.so.sym")
    endforeach()
  endif()

  # Package all extracted debug symbols into a single zip archive
  add_custom_command(
    OUTPUT "${APP_OUTPUT_DIR}/native-debug-symbols.zip"
    COMMAND zip
            -r "${APP_OUTPUT_DIR}/native-debug-symbols.zip"
            ${APP_EXTRACTED_DEBUG_SYMBOLS}
    DEPENDS ${APP_EXTRACTED_DEBUG_SYMBOLS}
    COMMENT "Packaging extracted debug symbols"
  )
  add_custom_target(package_debug_symbols ALL DEPENDS "${APP_OUTPUT_DIR}/native-debug-symbols.zip") 
endif()

# Collect all ABI-specific shared libraries into a single list
set(APP_ALL_SHARED_LIBS "")
foreach(ABI IN LISTS APP_TARGET_ABIS)
  list(APPEND APP_ALL_SHARED_LIBS "lib/${ABI}/lib${APP_LIB_NAME}.so")
endforeach()

# Get the number of target ABIs
list(LENGTH APP_TARGET_ABIS ABI_COUNT)
# If more than one ABI is targeted, create a fat APK
if(ABI_COUNT GREATER 1)
    list(APPEND APP_TARGET_ABIS "universal")
endif()

# Set up the manifest file
if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
  add_custom_command(
    OUTPUT "${APP_INTERM_DIR}/AndroidManifest.xml"
    COMMAND manifest-merger
            --main "${CMAKE_SOURCE_DIR}/app/src/main/AndroidManifest.xml"
            --property PACKAGE=${APP_PACKAGE_NAME}
            --property VERSION_CODE=${APP_VERSION_CODE}
            --property VERSION_NAME=${APP_VERSION_NAME}
            --property MIN_SDK_VERSION=${APP_MIN_SDK}
            --property TARGET_SDK_VERSION=${APP_TARGET_SDK}
            --out "${APP_INTERM_DIR}/AndroidManifest.xml"
    DEPENDS "${CMAKE_SOURCE_DIR}/app/src/main/AndroidManifest.xml"
    COMMENT "Merging main manifest"
  )
else()
  # Merge the main manifest with debug-specific overlay
  add_custom_command(
    OUTPUT "${APP_INTERM_DIR}/AndroidManifest.xml"
    COMMAND manifest-merger
            --main "${CMAKE_SOURCE_DIR}/app/src/main/AndroidManifest.xml"
            --overlays "${CMAKE_SOURCE_DIR}/app/src/debug/AndroidManifest.xml"
            --property PACKAGE=${APP_PACKAGE_NAME}
            --property VERSION_CODE=${APP_VERSION_CODE}
            --property VERSION_NAME=${APP_VERSION_NAME}
            --property MIN_SDK_VERSION=${APP_MIN_SDK}
            --property TARGET_SDK_VERSION=${APP_TARGET_SDK}
            --out "${APP_INTERM_DIR}/AndroidManifest.xml"
    DEPENDS "${CMAKE_SOURCE_DIR}/app/src/main/AndroidManifest.xml"
            "${CMAKE_SOURCE_DIR}/app/src/debug/AndroidManifest.xml"
    COMMENT "Merging main and debug manifests"
  )
endif()
add_custom_target(merge_manifest ALL DEPENDS "${APP_INTERM_DIR}/AndroidManifest.xml")

# Define resource directories
set(APP_RES_DIR "${CMAKE_SOURCE_DIR}/app/src/main/res")
set(APP_COMPILED_RES_DIR "${CMAKE_BINARY_DIR}/${APP_INTERM_DIR}/compiled_res")

# Collect all resource files and convert paths to native format (required by aapt2)
file(GLOB_RECURSE _raw_APP_RES_FILES "${APP_RES_DIR}/*")
set(APP_RES_FILES "")
foreach(_raw_app_res_file IN LISTS _raw_APP_RES_FILES)
  file(TO_NATIVE_PATH "${_raw_app_res_file}" app_res_file)
  list(APPEND APP_RES_FILES "${app_res_file}")
endforeach()

# Compile and link resource files
add_custom_command(
  OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.ap_"
  COMMAND ${CMAKE_COMMAND} -E make_directory "${APP_COMPILED_RES_DIR}"
  COMMAND aapt2 compile
          ${APP_RES_FILES}
          -o "${APP_COMPILED_RES_DIR}"
  COMMAND fd
          . "${APP_COMPILED_RES_DIR}"
          -I -tf -e flat
          --exec-batch aapt2 link
          -o "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.ap_"
          --manifest "${APP_INTERM_DIR}/AndroidManifest.xml"
          -I "${ANDROID_HOME}/platforms/android-${APP_COMPILE_SDK}/android.jar"
  DEPENDS ${APP_RES_FILES}
          "${APP_INTERM_DIR}/AndroidManifest.xml"
          "${ANDROID_HOME}/platforms/android-${APP_COMPILE_SDK}/android.jar"
  COMMENT "Linking resources and manifest"
)
add_custom_target(link_res ALL DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.ap_")

# Optimize linked resources
if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
  add_custom_command(
    OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.optimized.ap_"
    COMMAND aapt2 optimize
            -o "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.optimized.ap_"
            --enable-sparse-encoding
            --collapse-resource-names
            --shorten-resource-paths
            "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.ap_"
    DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.ap_"
    COMMENT "Optimizing linked resources"
  )
else()
  # Do nothing
  add_custom_command(
    OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.optimized.ap_"
    COMMAND ${CMAKE_COMMAND} -E copy
            "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.ap_"
            "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.optimized.ap_"
    DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.ap_"
    COMMENT "Copying unoptimized linked resources"
  )
endif()
add_custom_target(optimize_res ALL DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.optimized.ap_")  

# Add compiled code to produce APK packages
foreach(ABI IN LISTS APP_TARGET_ABIS)
  # For ABI-specific APKs, add ABI-specific shared library
  if(NOT ABI STREQUAL "universal")
    add_custom_command(
      OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
	  COMMAND ${CMAKE_COMMAND} -E copy
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.optimized.ap_"
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      COMMAND zip
              -u "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
              "lib/${ABI}/lib${APP_LIB_NAME}.so"
      DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.optimized.ap_"
              "lib/${ABI}/lib${APP_LIB_NAME}.so"
      COMMENT "Creating APK package (${ABI})"
    )
  else()
    # For the universal APK, add all shared libraries
    add_custom_command(
      OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      COMMAND ${CMAKE_COMMAND} -E copy
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.optimized.ap_"
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      COMMAND zip
              -u "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
              ${APP_ALL_SHARED_LIBS}
      DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.optimized.ap_"
              ${APP_ALL_SHARED_LIBS}
      COMMENT "Creating APK package (${ABI})"
    )
  endif()
  add_custom_target(create_apk_${ABI} ALL DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk")
endforeach()

# Align the APK packages for optimized installation
foreach(ABI IN LISTS APP_TARGET_ABIS)
  # For release builds, recompress using Zopfli
  if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug") 
    add_custom_command(
      OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
      COMMAND zipalign
              -f -P 16 -z 4
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
      DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      COMMENT "Aligning recompressed APK package (${ABI})"
    )
  else()
    add_custom_command(
      OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
      COMMAND zipalign
              -f -P 16 4
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
              "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.aligned.apk"
      DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.unaligned.apk"
      COMMENT "Aligning APK package (${ABI})"
    )
  endif()
  add_custom_target(align_apk_${ABI} ALL DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_${ABI}.aligned.apk")
endforeach()

# For release builds, use environment variables if provided
if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug" AND DEFINED ENV{STORE_FILE} AND DEFINED ENV{STORE_PASSWORD} AND DEFINED ENV{KEY_ALIAS})
  # Use credentials from environment variables
  set(APP_STORE_FILE "$ENV{STORE_FILE}")
  set(APP_STORE_PASSWORD "$ENV{STORE_PASSWORD}")
  set(APP_KEY_ALIAS "$ENV{KEY_ALIAS}")

  # For key password, use KEY_PASSWORD environment variable if provided
  if(DEFINED ENV{KEY_PASSWORD})
    set(APP_KEY_PASSWORD "$ENV{KEY_PASSWORD}")
  # Fallback to keystore password
  else()
    set(APP_KEY_PASSWORD "$ENV{STORE_PASSWORD}")
  endif()
else()
  # Determine the user's home directory based on platform
  if(WIN32)
    set(USER_HOME "$ENV{USERPROFILE}")
  else()
    set(USER_HOME "$ENV{HOME}")
  endif()

  # Use SDK debug keystore
  set(APP_STORE_FILE "${USER_HOME}/.android/debug.keystore")
  set(APP_STORE_PASSWORD "android")
  set(APP_KEY_ALIAS "androiddebugkey")
  set(APP_KEY_PASSWORD "android")

  # Create the keystore if it doesn't exist
  if(NOT EXISTS ${APP_STORE_FILE})
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E make_directory "${USER_HOME}/.android"
      COMMAND keytool
              -genkeypair
              -keystore ${APP_STORE_FILE}
              -storepass ${APP_KEY_PASSWORD}
              -alias ${APP_KEY_ALIAS}
              -keypass ${APP_KEY_PASSWORD}
              -dname "CN=Android Debug,O=Android,C=US"
              -keyalg RSA
              -keysize 2048
              -validity 10000
    )
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
  add_custom_target(sign_apk_${ABI} ALL DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk")
endforeach()

# Install the APK packages on the connected device
foreach(ABI IN LISTS APP_TARGET_ABIS)
  add_custom_target(install_apk_${ABI}
    COMMAND adb install
            -t -d
            --user ${DEVICE_USER}
            "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk"
    DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_${ABI}.apk"
    COMMENT "Installing APK package (${ABI})"
  )
endforeach()

# Create an Android App Bundle (AAB) from linked resources and native libraries
add_custom_command(
  OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.proto-format.optimized.ap_"
         "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.zip"
         "${APP_INTERM_DIR}/manifest/AndroidManifest.xml"
         "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.unsigned.aab"
         "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
  # Convert linked resources to Protocol Buffers format
  COMMAND aapt2 convert
          -o "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.proto-format.optimized.ap_"
          --output-format proto
          "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.optimized.ap_"
  # Create the zip archive expected by bundeltool
  COMMAND ${CMAKE_COMMAND} -E copy
          "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.proto-format.optimized.ap_"
          "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.zip"
  # Move the manifest to its expected location within the archive
  COMMAND ${CMAKE_COMMAND} -E make_directory "${APP_INTERM_DIR}/manifest"
  COMMAND unzip
          -o "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.zip"
          -d "${APP_INTERM_DIR}/manifest"
          "AndroidManifest.xml"
  COMMAND zip
          -d "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.zip"
          "AndroidManifest.xml"
  COMMAND ${CMAKE_COMMAND} -E chdir "${APP_INTERM_DIR}" zip
          -u "${APP_OUTPUT_NAME}.zip"
          "manifest/AndroidManifest.xml"
  # Add native shared libraries to the archive
  COMMAND zip
          -u "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.zip"
          ${APP_ALL_SHARED_LIBS}
  # Build the AAB bundle from the archive
  COMMAND bundletool build-bundle
          --modules="${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.zip"
          --output="${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.unsigned.aab"
          --overwrite
  # Sign the AAB bundle
  COMMAND jarsigner
          -keystore "${APP_STORE_FILE}" -storepass "${APP_STORE_PASSWORD}"
          -signedjar "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
          "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.unsigned.aab"
          "${APP_KEY_ALIAS}"
  DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}.binary-format.optimized.ap_"
          ${APP_ALL_SHARED_LIBS}
  COMMENT "Creating AAB bundle"
)
add_custom_target(create_aab DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab")

# Ensure debug symbols are generated along with the bundle in release builds
if(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
  add_dependencies(create_aab package_debug_symbols) 
endif()

# Install the AAB bundle
add_custom_target(install_aab
  COMMENT "Installing AAB bundle"
)
add_dependencies(install_aab install_apks_connected_device)

# Generate a universal APK set
add_custom_command(
  OUTPUT "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_universal.apks"
  COMMAND bundletool build-apks
          --bundle="${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
          --output="${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_universal.apks"
          --ks "${APP_STORE_FILE}" --ks-pass pass:"${APP_STORE_PASSWORD}"
          --ks-key-alias "${APP_KEY_ALIAS}" --key-pass pass:"${APP_KEY_PASSWORD}"
          --overwrite
  DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
  COMMENT "Creating universal APK set"
)
add_custom_target(create_apks_universal DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_universal.apks")

# Generate an APK set specific to the connected device
add_custom_command(
  OUTPUT "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_connected_device.apks"
  COMMAND bundletool build-apks
          --bundle="${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
          --output="${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_connected_device.apks"
          --ks "${APP_STORE_FILE}" --ks-pass pass:"${APP_STORE_PASSWORD}"
          --ks-key-alias "${APP_KEY_ALIAS}" --key-pass pass:"${APP_KEY_PASSWORD}"
          --connected-device
          --overwrite
  DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}.aab"
  COMMENT "Creating connected device's APK set"
)
add_custom_target(create_apks_connected_device DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_connected_device.apks")

# Install the universal APK set on the connected device
add_custom_target(install_apks_universal
  COMMAND bundletool extract-apks
          --apks="${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_universal.apks"
          --output-dir="${APP_INTERM_DIR}/extracted_apks/universal"
          --device-spec="${APP_INTERM_DIR}/connected-device-spec.json"
  COMMAND fd
          . "${APP_INTERM_DIR}/extracted_apks/universal"
          -I -tf -e apk
          --exec-batch adb install-multiple
          -t -d
          --user ${DEVICE_USER}
  DEPENDS "${APP_OUTPUT_DIR}/${APP_OUTPUT_NAME}_universal.apks"
          "${APP_INTERM_DIR}/connected-device-spec.json"
  COMMENT "Installing universal APK set"
)

# Install the connected device's APK set
add_custom_target(install_apks_connected_device
  COMMAND bundletool extract-apks
          --apks="${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_connected_device.apks"
          --output-dir="${APP_INTERM_DIR}/extracted_apks/connected_device"
          --device-spec="${APP_INTERM_DIR}/connected-device-spec.json"
  COMMAND fd
          . "${APP_INTERM_DIR}/extracted_apks/connected_device"
          -I -tf -e apk
          --exec-batch adb install-multiple
          -t -d
          --user ${DEVICE_USER}
  DEPENDS "${APP_INTERM_DIR}/${APP_OUTPUT_NAME}_connected_device.apks"
          "${APP_INTERM_DIR}/connected-device-spec.json"
  COMMENT "Installing connected device's APK set"
)

# Uninstall the application from the connected device
add_custom_target(uninstall_app
  COMMAND adb uninstall ${APP_PACKAGE_NAME}
  COMMENT "Uninstalling the application"
)

# Display the ABIs supported by the connected device
add_custom_target(check_abis
  COMMAND ${CMAKE_COMMAND} -E echo "Primary ABI:"
  COMMAND adb shell getprop ro.product.cpu.abi
  COMMAND ${CMAKE_COMMAND} -E echo "Supported ABIs:"
  COMMAND adb shell getprop ro.product.cpu.abilist
  COMMENT "Querying device ABIs"
)

# Export the connected device specifications to a JSON file
add_custom_command(
  OUTPUT "${APP_INTERM_DIR}/connected-device-spec.json"
  COMMAND bundletool get-device-spec
          --output="${APP_INTERM_DIR}/connected-device-spec.json"
          --overwrite
  COMMENT "Exporting device spec"
)
add_custom_target(export_spec DEPENDS "${APP_INTERM_DIR}/connected-device-spec.json")

# Register untracked intermediate files for cleanup
set(APP_UNTRACKED_INTERM_FILES
  "${APP_COMPILED_RES_DIR}"
  "${APP_INTERM_DIR}/manifest"
  "${APP_INTERM_DIR}/extracted_apks"
)
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES "${APP_UNTRACKED_INTERM_FILES}")