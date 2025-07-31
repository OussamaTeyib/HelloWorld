# Minimum CMake version required for this project
cmake_minimum_required(VERSION 3.10)

# Define the project name and programming language
project(libmain LANGUAGES C)

# Ensure that ANDROID_EXTERNAL_HOME is set
if(NOT DEFINED ENV{ANDROID_EXTERNAL_HOME})
  message(FATAL_ERROR "Environment variable ANDROID_EXTERNAL_HOME is not set. Please set it to proceed.")
endif()

# Define paths for external Android libraries (raylib)
set(EXTERNAL_INCLUDE_DIR $ENV{ANDROID_EXTERNAL_HOME}/include)
set(EXTERNAL_LIB_DIR $ENV{ANDROID_EXTERNAL_HOME}/lib/${ANDROID_ABI})

# Import raylib static library
add_library(raylib STATIC IMPORTED)
set_target_properties(raylib PROPERTIES
  IMPORTED_LOCATION "${EXTERNAL_LIB_DIR}/libraylib.a"
  # Include directories that consumers of raylib should use when compiling
  INTERFACE_INCLUDE_DIRECTORIES "${EXTERNAL_INCLUDE_DIR}"
)

# Define the directory for source files
set(SOURCE_DIR ${CMAKE_SOURCE_DIR})
# Gather all .c files in the source directory
file(GLOB SOURCES "${SOURCE_DIR}/*.c")

# Define the library name
set(LIBRARY_NAME main)

# Compile source files into a shared library
add_library(${LIBRARY_NAME} SHARED ${SOURCES})

# Specify the directory for header files
target_include_directories(${LIBRARY_NAME} PRIVATE ${SOURCE_DIR})

# Specify the C standard to be used
set_property(TARGET ${LIBRARY_NAME} PROPERTY C_STANDARD 23)

# Ensure the entry point for the ANativeActivity is included for the app to launch properly
target_link_options(${LIBRARY_NAME} PRIVATE -u ANativeActivity_onCreate)

# Link against essential libraries for Android development
target_link_libraries(${LIBRARY_NAME} PRIVATE c m android log EGL GLESv2 OpenSLES raylib)

# Set output directory for the shared library
set_target_properties(${LIBRARY_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/${ANDROID_ABI})