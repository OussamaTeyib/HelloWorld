# Minimum CMake version required for this project
cmake_minimum_required(VERSION 4.0.2)

# Define project name and programming language
project(${APP_LIB_NAME} LANGUAGES C)

# Import raylib
add_subdirectory("raylib")

# Source directory
set(SOURCE_DIR "${CMAKE_SOURCE_DIR}")

# Gather all C source files recursively
file(GLOB_RECURSE SOURCE_FILES CONFIGURE_DEPENDS "${SOURCE_DIR}/*.c")

# Exclude files under raylib directory
list(FILTER SOURCE_FILES EXCLUDE REGEX ".*/raylib/.*")

# Compile source files into a shared library
add_library(${APP_LIB_NAME} SHARED ${SOURCE_FILES})

# Include directory for this library
target_include_directories(${APP_LIB_NAME} PRIVATE "${SOURCE_DIR}")

# Force inclusion of ANativeActivity_onCreate, expected by NativeActivity
target_link_options(${APP_LIB_NAME} PRIVATE -u ANativeActivity_onCreate)

# Link against essential Android libraries and raylib
target_link_libraries(${APP_LIB_NAME} PRIVATE c m android log EGL GLESv2 OpenSLES raylib)
