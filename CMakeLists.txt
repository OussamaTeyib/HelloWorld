# Minimum version of CMake required to build the project
cmake_minimum_required(VERSION 3.5)

# Define the project name and language 	 	
project(HelloWorld C)

# Specify raylib paths
set(RAYLIB_INCLUDE_DIR $ENV{ANDROID_RAYLIB_HOME}/include)
set(RAYLIB_LIB_DIR $ENV{ANDROID_RAYLIB_HOME}/lib/${ANDROID_ABI})

# Specify project source files
set(SOURCE_DIR ${CMAKE_SOURCE_DIR}/src)
file(GLOB SOURCES "${SOURCE_DIR}/*.c")

# Compile source files into a shared library
add_library(main SHARED ${SOURCES})

# TBD
target_include_directories(main PUBLIC ${SOURCE_DIR} ${RAYLIB_INCLUDE_DIR})

# TBD
target_link_directories(main PUBLIC ${RAYLIB_LIB_DIR})

# TBD
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

# TBD
target_compile_definitions(main PUBLIC
    -D__ANDROID__
    -DPLATFORM_ANDROID
)

# TBD
target_link_options(main PUBLIC
    -Wl,-soname,libmain.so -Wl,--exclude-libs,libatomic.a 
    -Wl,--build-id -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--warn-shared-textrel -Wl,--fatal-warnings 
    -u ANativeActivity_onCreate
)

# TBD
target_link_libraries(main PUBLIC m c raylib log android EGL GLESv2 OpenSLES)

# TBD
set_target_properties(main PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/${ANDROID_ABI})