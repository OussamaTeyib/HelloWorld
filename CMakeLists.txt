# Minimum version of CMake required to build the project
cmake_minimum_required(VERSION 3.5)

# Define the project name and language 	 	
project(HelloWorld C)

# Define raylib paths
set(RAYLIB_INCLUDE_DIR $ENV{ANDROID_RAYLIB_HOME}/include)
set(RAYLIB_LIB_DIR $ENV{ANDROID_RAYLIB_HOME}/lib/${ANDROID_ABI})

# App info
set(APP_PACKAGE_NAME "com.oussamateyib.helloworld")

# Source files
set(SOURCE_DIR ${CMAKE_SOURCE_DIR}/src)
file(GLOB SOURCES "${SOURCE_DIR}/*.c")

# Compile source files into a shared library
add_library(main SHARED ${SOURCES})

# Include paths
target_include_directories(main PUBLIC ${SOURCE_DIR} ${RAYLIB_INCLUDE_DIR})

# Linker paths
target_link_directories(main PUBLIC ${RAYLIB_LIB_DIR})

# Compiler flags
target_compile_options(main PUBLIC
    -std=c17
    -ffunction-sections -funwind-tables -fstack-protector-strong -fPIC
    -Wall -Wa,--noexecstack -Wformat -Werror=format-security -no-canonical-prefixes 
)
if(ANDROID_ABI STREQUAL "armeabi-v7a")
    target_compile_options(main PUBLIC -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16)
elseif(ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_options(main PUBLIC -march=armv8-a -mfix-cortex-a53-835769)
endif()

# Compiler definitions
target_compile_definitions(main PUBLIC
    -D__ANDROID__
    -DPLATFORM_ANDROID
)

# Linker flags
target_link_options(main PUBLIC
    -Wl,-soname,libmain.so -Wl,--exclude-libs,libatomic.a
    -Wl,--build-id -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now
    -Wl,--warn-shared-textrel -Wl,--fatal-warnings
    -u ANativeActivity_onCreate
)

# Link against required libraries
target_link_libraries(main PUBLIC m c raylib log android EGL GLESv2 OpenSLES)

# Define output directory
set_target_properties(main PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/${ANDROID_ABI})

# TBD
set(APK_OUTPUT_DIR outputs)
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR})

# TBD
set(ANDROID_MANIFEST_FILE ${CMAKE_SOURCE_DIR}/AndroidManifest.xml)
set(RESOURCES_PATH ${CMAKE_SOURCE_DIR}/res)
file(GLOB_RECURSE RESOURCE_FILES "${RESOURCES_PATH}/*")
set(ANDROID_JAR_PATH $ENV{ANDROID_HOME}/platforms/${ANDROID_PLATFORM}/android.jar)

# TBD
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk
    COMMAND aapt package -f -M ${ANDROID_MANIFEST_FILE}
            -S ${RESOURCES_PATH}
            -I ${ANDROID_JAR_PATH}
            -F ${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk
    COMMAND aapt add ${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk lib/${ANDROID_ABI}/libmain.so
    DEPENDS ${CMAKE_BINARY_DIR}/lib/${ANDROID_ABI}/libmain.so
            ${ANDROID_MANIFEST_FILE}
            ${RESOURCE_FILES}
    COMMENT "Creating APK package"
)
add_custom_target(create_apk ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk)

# TBD
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.aligned.apk
    COMMAND zipalign -p -f 4
            ${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk
            ${APK_OUTPUT_DIR}/${PROJECT_NAME}.aligned.apk
    DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.unaligned.apk
    COMMENT "Aligning APK package"
)
add_custom_target(align_apk ALL DEPENDS ${CMAKE_BINARY_DIR}/${APK_OUTPUT_DIR}/${PROJECT_NAME}.aligned.apk)

# Keystore info
set(KEYSTORE_FILE ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.keystore)
set(KEYSTORE_PASS "291199")
set(COMMON_NAME "Oussama Teyib")
set(ORGANIZATION "oussamateyib")
set(COUNTRY "MR")

# TBD
if (NOT EXISTS ${KEYSTORE_FILE})
    add_custom_command(
        OUTPUT ${KEYSTORE_FILE}
        COMMAND keytool -genkeypair -validity 10000 -keyalg RSA
                -dname "CN=${COMMON_NAME},O=${ORGANIZATION},C=${COUNTRY}"
                -storepass ${KEYSTORE_PASS} -keypass ${KEYSTORE_PASS}
                -alias ${PROJECT_NAME}Key
                -keystore ${KEYSTORE_FILE}
        COMMENT "Generating keystore"
    )
endif()
add_custom_target(generate_key ALL DEPENDS ${KEYSTORE_FILE})