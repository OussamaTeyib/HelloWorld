# Minimum CMake version required for this project
cmake_minimum_required(VERSION 3.22.1)

# Define the project name and programming language
project(${APP_LIB_NAME} LANGUAGES C)

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

# Compile source files into a shared library
add_library(${APP_LIB_NAME} SHARED ${SOURCES})

# Specify the directory for header files
target_include_directories(${APP_LIB_NAME} PRIVATE ${SOURCE_DIR})

# Specify the C standard to be used
set_property(TARGET ${APP_LIB_NAME} PROPERTY C_STANDARD 23)

# Ensure the entry point for the ANativeActivity is included for the app to launch properly
target_link_options(${APP_LIB_NAME} PRIVATE -u ANativeActivity_onCreate)

# Link against essential libraries for Android development
target_link_libraries(${APP_LIB_NAME} PRIVATE c m android log EGL GLESv2 OpenSLES raylib)