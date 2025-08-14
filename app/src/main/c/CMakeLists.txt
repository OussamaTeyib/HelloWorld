# Minimum required CMake version for this project
cmake_minimum_required(VERSION 3.22.1)

# Set default library name if not provided
set(APP_LIB_NAME "main" CACHE STRING "Name of the native library")

# Define project name and programming language
project(${APP_LIB_NAME} LANGUAGES C)

# Verify that ANDROID_ABI is set
if(NOT DEFINED ANDROID_ABI)
  message(FATAL_ERROR "ANDROID_ABI is not set. Make sure it's passed to CMake")
endif()

# Verify that ANDROID_EXTERNAL_HOME is set
if(NOT DEFINED ANDROID_EXTERNAL_HOME)
  message(FATAL_ERROR "ANDROID_EXTERNAL_HOME is not set. Make sure it's passed to CMake")
endif()

# Paths for external Android libraries (e.g., raylib)
set(EXTERNAL_INCLUDE_DIR "${ANDROID_EXTERNAL_HOME}/include")
set(EXTERNAL_LIB_DIR "${ANDROID_EXTERNAL_HOME}/lib/${ANDROID_ABI}")

# Import raylib static library
add_library(raylib STATIC IMPORTED)
set_target_properties(raylib PROPERTIES
  IMPORTED_LOCATION "${EXTERNAL_LIB_DIR}/libraylib.a"
  # Include directories that consumers of raylib should use
  INTERFACE_INCLUDE_DIRECTORIES "${EXTERNAL_INCLUDE_DIR}"
)

# Source directory
set(SOURCE_DIR "${CMAKE_SOURCE_DIR}")
# Gather all C source files in the source directory
file(GLOB SOURCE_FILES "${SOURCE_DIR}/*.c")

# Compile source files into a shared library
add_library(${APP_LIB_NAME} SHARED ${SOURCE_FILES})

# Include directory for this library
target_include_directories(${APP_LIB_NAME} PRIVATE "${SOURCE_DIR}")

# Force inclusion of ANativeActivity_onCreate, expected by NativeActivity
target_link_options(${APP_LIB_NAME} PRIVATE -u ANativeActivity_onCreate)

# Link against essential Android libraries and raylib
target_link_libraries(${APP_LIB_NAME} PRIVATE c m android log EGL GLESv2 OpenSLES raylib)