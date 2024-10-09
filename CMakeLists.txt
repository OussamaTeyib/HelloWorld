# Minimun version of CMake required to build the project
cmake_minimum_required(VERSION 3.5)

# Define the project name
project(HelloWorld)

# Specify the path of raylib headers
include_directories($ENV{RAYLIB_ANDROID}/include)	

# Compile C code into a shared library
add_library(hello_world SHARED src/main.c)

# Import raylib
add_library(raylib STATIC IMPORTED)

# Specify the path of raylib
set_target_properties(raylib PROPERTIES IMPORTED_LOCATION $ENV{RAYLIB_ANDROID}/lib/arm64/libraylib.a)

# Link with necessary libraries
target_link_libraries(hello_world raylib android log EGL GLESv2)