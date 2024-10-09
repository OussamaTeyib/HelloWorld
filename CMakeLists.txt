# Minimun version of CMake required to build the project
cmake_minimum_required(VERSION 3.5)

# Define the project name
project(HelloWorld)

# Specify the path of android ndk headers
include_directories($ENV{ANDROID_NDK_HOME}/sources/android/native_app_glue)

# Specify the path of raylib headers
include_directories($ENV{RAYLIB_ANDROID}/include)	

# Compile C code into a shared library
add_library(hello_world SHARED src/main.c)

# Build native_app_glue
add_library(native_app_glue STATIC C:/Programs/Android/SDK/ndk/27.0.12077973/sources/android/native_app_glue/android_native_app_glue.c)

# Import raylib
add_library(raylib STATIC IMPORTED)

# Specify the path of raylib
set_target_properties(raylib PROPERTIES IMPORTED_LOCATION $ENV{RAYLIB_ANDROID}/lib/arm64/libraylib.a)

# Link with necessary libraries
target_link_libraries(hello_world raylib android log EGL GLESv2 native_app_glue)