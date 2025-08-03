# Minimum CMake version required for this project
cmake_minimum_required(VERSION 3.22.1)

# Define the project name and version
project(HelloWorld VERSION 1.0.0 LANGUAGES NONE)

# Set default build type
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Build type (default Debug)" FORCE)
endif()

# Ensure that ANDROID_HOME is set
if(DEFINED ENV{ANDROID_HOME})
  set(ANDROID_HOME $ENV{ANDROID_HOME})
else()
  message(FATAL_ERROR "Environment variable ANDROID_HOME is not set. Please set it to proceed.")
endif()

# Ensure that ANDROID_NDK_HOME is set
if(DEFINED ENV{ANDROID_NDK_HOME})
  set(ANDROID_NDK_HOME $ENV{ANDROID_NDK_HOME})
else()
  message(FATAL_ERROR "Environment variable ANDROID_NDK_HOME is not set. Please set it to proceed.")
endif()

# Ensure that ANDROID_EXTERNAL_HOME is set
if(DEFINED ENV{ANDROID_EXTERNAL_HOME})
  set(ANDROID_EXTERNAL_HOME $ENV{ANDROID_EXTERNAL_HOME})
else()
  message(FATAL_ERROR "Environment variable ANDROID_EXTERNAL_HOME is not set. Please set it to proceed.")
endif()

# Set default ABIs
if(NOT DEFINED ABIS)
  set(ABIS "armeabi-v7a;arm64-v8a;x86;x86_64" CACHE STRING "Android ABIs")
endif()

# Set default API level (minSdkVersion)
if(NOT DEFINED API_LEVEL)
  set(API_LEVEL "21" CACHE STRING "API level (minSdkVersion)")
endif()

# Define the native library name
set(APP_LIB_NAME main)

# Load the ExternalProject module
include(ExternalProject)

# Build the native library for each ABI
foreach(ABI IN LISTS ABIS)
  ExternalProject_Add(${APP_LIB_NAME}_${ABI}
    SOURCE_DIR ${CMAKE_SOURCE_DIR}/app/src/main/c/
    BINARY_DIR ${CMAKE_BINARY_DIR}/lib/${ABI}
    CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake
               -DANDROID_ABI=${ABI}
               -DANDROID_PLATFORM=${API_LEVEL}
               -DAPP_LIB_NAME=${APP_LIB_NAME}
               -DANDROID_EXTERNAL_HOME=${ANDROID_EXTERNAL_HOME}
               -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    BUILD_BYPRODUCTS ${CMAKE_BINARY_DIR}/lib/${ABI}/lib${APP_LIB_NAME}.so
    BUILD_ALWAYS 1
    INSTALL_COMMAND ""
  )
endforeach()

# Append "universal" to ABIS to support fat APKs
set(ORIGINAL_ABIS ${ABIS})
list(APPEND ABIS "universal")

# Set APK output file name
set(APK_OUTPUT_NAME ${PROJECT_NAME}_v${PROJECT_VERSION})

# Define the output directory for APKs and ensure it exists
set(APK_OUTPUT_DIR outputs)
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR})

# Define the directory for compiled resources and ensure it exists
set(APK_COMPILED_RES_DIR ${APK_OUTPUT_DIR}/compiled_res)
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${APK_COMPILED_RES_DIR})

# Define the resource directory
set(RES_DIR ${CMAKE_SOURCE_DIR}/app/src/main/res)

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
set(ANDROID_MANIFEST_FILE ${CMAKE_SOURCE_DIR}/app/src/main/AndroidManifest.xml)

# Target SDK version
set(TARGET_SDK 36)
# Path to the Android SDK platform JAR for linking
set(ANDROID_JAR_PATH ${ANDROID_HOME}/platforms/android-${TARGET_SDK}/android.jar)

# Create APK packages by linking togather compiled resources, manifest, and JAR file 
foreach(ABI IN LISTS ABIS)
  add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.base.apk
    COMMAND aapt2 link
            -o ${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.base.apk
            ${COMPILED_RES_FILES}                        # Compiled resources
            -I ${ANDROID_JAR_PATH}                       # Android platform JAR
            --manifest ${ANDROID_MANIFEST_FILE}          # AndroidManifest.xml
    DEPENDS ${ANDROID_MANIFEST_FILE}                     # Manifest file as a dependency
            ${COMPILED_RES_FILES}                        # Compiled resources as dependencies
    COMMENT "Creating APK package (${ABI})"
  )
  add_custom_target(create_apk_${ABI} ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.base.apk)
endforeach()

# Add shared libraries to APK packages for each ABI
foreach(ABI IN LISTS ABIS)
  # For ABI-specific APKs (excluding "universal")
  if(NOT ABI STREQUAL "universal")
    add_custom_command(
      OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.unaligned.apk
      COMMAND zip -u ${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.base.apk lib/${ABI}/lib${APP_LIB_NAME}.so
	  COMMAND ${CMAKE_COMMAND} -E copy
              "${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.base.apk"
              "${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.unaligned.apk"
      DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.base.apk  # Base APK as a dependency
              ${CMAKE_BINARY_DIR}/lib/${ABI}/lib${APP_LIB_NAME}.so                      # Shared libraries as dependencies
      COMMENT "Adding shared libraries (${ABI})"
    )
  # For the universal APK (includes shared libraries for all ABIs)
  else()
    # Gather all ABI-specific shared libraries into a list
    set(SHARED_LIBS "")
    foreach(ORIGINAL_ABI IN LISTS ORIGINAL_ABIS)
	  list(APPEND SHARED_LIBS "lib/${ORIGINAL_ABI}/lib${APP_LIB_NAME}.so")
	endforeach()
	  
    add_custom_command(
      OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.unaligned.apk
      COMMAND zip -u ${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.base.apk ${SHARED_LIBS}
      COMMAND ${CMAKE_COMMAND} -E copy
              "${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.base.apk"
              "${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.unaligned.apk"
      DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.base.apk  # Base APK as a dependency
              ${SHARED_LIBS}                                                            # Shared libraries as dependencies
      COMMENT "Adding shared libraries (${ABI})"
    )
  endif()
  add_custom_target(add_shared_libs_${ABI} ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.unaligned.apk)
endforeach()

# Align the APK packages for optimized installation on Android
foreach(ABI IN LISTS ABIS)
  add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.aligned.apk
    COMMAND zipalign -f                                  # Force overwrite
            -p                                           # Page aligns uncompressed data
            4                                            # Align ZIP to 4-byte boundaries
            ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.unaligned.apk
            ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.aligned.apk
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.unaligned.apk
    COMMENT "Aligning APK package (${ABI})"
  )
  add_custom_target(align_apk_${ABI} ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.aligned.apk)
endforeach()

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

# Sign the APK packages
foreach(ABI IN LISTS ABIS)
  add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.apk
           ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.apk.idsig
    COMMAND apksigner sign
            --ks ${KEYSTORE_FILE} --ks-pass pass:${KEYSTORE_PASS}
            --ks-key-alias ${KEY_ALIAS} --key-pass pass:${KEY_PASS}
            --out ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.apk
            ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.aligned.apk
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.aligned.apk
    COMMENT "Signing APK package (${ABI})"
  )
  add_custom_target(sign_apk_${ABI} ALL
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.apk
            ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.apk.idsig
  )
endforeach()

# Set default user ID
if(NOT DEFINED USER_ID)
  set(USER_ID 0 CACHE STRING "User ID (default 0, the primary user)")
endif()

# Install the APK packages
# Use -e (emulator) or -d (device) flags with adb if needed
foreach(ABI IN LISTS ABIS)
  add_custom_target(install_apk_${ABI}
    COMMAND adb install --user ${USER_ID} ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.apk
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${APK_OUTPUT_NAME}_${ABI}.apk
    COMMENT "Installing APK package (${ABI})"
  )
endforeach()

# Define the application package name
set(APK_PACKAGE_NAME "com.oussamateyib.helloworld")

# Uninstall the application from the connected device/emulator
add_custom_target(uninstall_apk
  COMMAND adb uninstall --user ${USER_ID} ${APK_PACKAGE_NAME}
  COMMENT "Uninstalling APK package"
)

# Display the ABI of the connected device/emulator
add_custom_target(check_device_abi
  COMMAND adb shell getprop ro.product.cpu.abi
  COMMENT "Checking device ABI compatibility"
)

# List all current users on the connected Android device/emulator
add_custom_target(list_users
  COMMAND adb shell pm list users
  COMMENT "Listing current users on device"
)
