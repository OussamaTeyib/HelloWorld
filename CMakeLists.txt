# Minimum version of CMake required to build the project
cmake_minimum_required(VERSION 3.5)

# Define the project name and language 	 	
project(HelloWorld C)

# Define raylib paths
set(RAYLIB_INCLUDE_DIR $ENV{ANDROID_RAYLIB_HOME}/include)
set(RAYLIB_LIB_DIR $ENV{ANDROID_RAYLIB_HOME}/lib/${ANDROID_ABI})

# Keystore and app info
set(APP_PACKAGE_NAME "com.oussamateyib.helloworld")
set(COMMON_NAME "Oussama Teyib")
set(ORGANIZATION "oussamateyib")
set(COUNTRY "MR")
set(APP_KEYSTORE_PATH "291199")

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
add_custom_target(create_apk ALL
    COMMAND aapt package -f -M ${CMAKE_SOURCE_DIR}/AndroidManifest.xml
            -S ${CMAKE_SOURCE_DIR}/res
            -I $ENV{ANDROID_HOME}/platforms/android-35/android.jar
            -F ${APK_OUTPUT_DIR}/HelloWorld.unaligned.apk
    COMMAND aapt add ${APK_OUTPUT_DIR}/HelloWorld.unaligned.apk lib/${ANDROID_ABI}/libmain.so
    COMMENT "Creating APK package"
)

add_dependencies(create_apk main)

# TBD
file(GLOB FILES_TO_REMOVE "${APK_OUTPUT_DIR}/*.apk" "${APK_OUTPUT_DIR}/*.idsig")
add_custom_target(clean_outputs
    COMMAND ${CMAKE_COMMAND} -E remove ${FILES_TO_REMOVE}
    COMMENT "Cleaning output files"
)