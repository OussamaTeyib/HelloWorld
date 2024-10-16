#**************************************************************************************************
#
#   raylib makefile for Android project (APK building)
#
#   Copyright (c) 2017-2024 Ramon Santamaria (@raysan5)
#
#   This software is provided "as-is", without any express or implied warranty. In no event
#   will the authors be held liable for any damages arising from the use of this software.
#
#   Permission is granted to anyone to use this software for any purpose, including commercial
#   applications, and to alter it and redistribute it freely, subject to the following restrictions:
#
#     1. The origin of this software must not be misrepresented; you must not claim that you
#     wrote the original software. If you use this software in a product, an acknowledgment
#     in the product documentation would be appreciated but is not required.
#
#     2. Altered source versions must be plainly marked as such, and must not be misrepresented
#     as being the original software.
#
#     3. This notice may not be removed or altered from any source distribution.
#
#**************************************************************************************************
SHELL = cmd

# Define required raylib variables
PLATFORM               ?= PLATFORM_ANDROID
RAYLIB_PATH            ?= C:\Programs\Android\raylib

# Define Android architecture (armeabi-v7a, arm64-v8a, x86, x86-64) and API version
# Starting in 2019 using ARM64 is mandatory for published apps,
# Starting on August 2020, minimum required target API is Android 10 (API level 29)
ANDROID_ARCH           ?= ARM64
ANDROID_API_VERSION    ?= 35

ifeq ($(ANDROID_ARCH),ARM)
    ANDROID_ARCH_NAME   = armeabi-v7a
endif
ifeq ($(ANDROID_ARCH),ARM64)
    ANDROID_ARCH_NAME   = arm64-v8a
endif
ifeq ($(ANDROID_ARCH),x86)
    ANDROID_ARCH_NAME   = x86
endif
ifeq ($(ANDROID_ARCH),x86_64)
    ANDROID_ARCH_NAME   = x86_64
endif

# Required path variables
# NOTE: JAVA_HOME must be set to JDK (using OpenJDK 13)
JAVA_HOME              ?= C:\Programs\Java\jdk-22
ANDROID_HOME           ?= C:\Programs\Android\SDK
ANDROID_NDK            ?= C:\Programs\Android\SDK\ndk\27.0.12077973
ANDROID_TOOLCHAIN      ?= $(ANDROID_NDK)\toolchains\llvm\prebuilt\windows-x86_64
ANDROID_BUILD_TOOLS    ?= $(ANDROID_HOME)\build-tools\35.0.0-rc4
ANDROID_PLATFORM_TOOLS  = $(ANDROID_HOME)\platform-tools

# Android project configuration variables
PROJECT_NAME           ?= Hello_World
PROJECT_LIBRARY_NAME   ?= main
PROJECT_BUILD_PATH     ?= build
PROJECT_SOURCE_DIR     ?= src
PROJECT_SOURCE_FILES   ?= main.c

# Android app configuration variables
APP_LABEL_NAME         ?= Hello World
APP_COMPANY_NAME       ?= oussamateyib
APP_PRODUCT_NAME       ?= helloworld
APP_VERSION_CODE       ?= 1
APP_VERSION_NAME       ?= 1.0
APP_SCREEN_ORIENTATION ?= portrait
APP_KEYSTORE_PASS      ?= 291199

# Library path for libraylib.a/libraylib.so
RAYLIB_LIB_PATH         = $(RAYLIB_PATH)\lib\$(ANDROID_ARCH_NAME)

# Compiler and archiver
ifeq ($(ANDROID_ARCH),ARM)
    CC = $(ANDROID_TOOLCHAIN)/bin/armv7a-linux-androideabi$(ANDROID_API_VERSION)-clang
    AR = $(ANDROID_TOOLCHAIN)/bin/arm-linux-androideabi-ar
endif
ifeq ($(ANDROID_ARCH),ARM64)
    CC = $(ANDROID_TOOLCHAIN)/bin/aarch64-linux-android$(ANDROID_API_VERSION)-clang
    AR = $(ANDROID_TOOLCHAIN)/bin/aarch64-linux-android-ar
endif
ifeq ($(ANDROID_ARCH),x86)
    CC = $(ANDROID_TOOLCHAIN)/bin/i686-linux-android$(ANDROID_API_VERSION)-clang
    AR = $(ANDROID_TOOLCHAIN)/bin/i686-linux-android-ar
endif
ifeq ($(ANDROID_ARCH),x86_64)
    CC = $(ANDROID_TOOLCHAIN)/bin/x86_64-linux-android$(ANDROID_API_VERSION)-clang
    AR = $(ANDROID_TOOLCHAIN)/bin/x86_64-linux-android-ar
endif

# Compiler flags for architecture
ifeq ($(ANDROID_ARCH),ARM)
    CFLAGS = -std=c99 -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16
endif
ifeq ($(ANDROID_ARCH),ARM64)
    CFLAGS = -std=c99 -march=armv8-a -mfix-cortex-a53-835769
endif
# Compilation functions attributes options
CFLAGS += -ffunction-sections -funwind-tables -fstack-protector-strong -fPIC
# Compiler options for the linker
CFLAGS += -Wall -Wa,--noexecstack -Wformat -Werror=format-security -no-canonical-prefixes
# Preprocessor macro definitions
CFLAGS += -D__ANDROID__ -DPLATFORM_ANDROID -D__ANDROID_API__=$(ANDROID_API_VERSION)

# Paths containing required header files
INCLUDE_PATHS = -I$(RAYLIB_PATH)/include

# Linker options
LDFLAGS = -Wl,-soname,lib$(PROJECT_LIBRARY_NAME).so -Wl,--exclude-libs,libatomic.a 
LDFLAGS += -Wl,--build-id -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--warn-shared-textrel -Wl,--fatal-warnings 
# Force linking of library module to define symbol
LDFLAGS += -u ANativeActivity_onCreate
# Library paths containing required libs
LDFLAGS += -L. -L$(PROJECT_BUILD_PATH)/obj -L$(PROJECT_BUILD_PATH)/lib/$(ANDROID_ARCH_NAME)

# Define any libraries to link into executable
# if you want to link libraries (libname.so or libname.a), use the -lname
LDLIBS = -lm -lc -lraylib -llog -landroid -lEGL -lGLESv2 -lOpenSLES -ldl

# Generate target objects list from PROJECT_SOURCE_FILES
OBJS = $(patsubst %.c, $(PROJECT_BUILD_PATH)/obj/%.o, $(PROJECT_SOURCE_FILES))

# Android APK building process... some steps required...
# NOTE: typing 'make' will invoke the default target entry called 'all',
all: clear \
     create_temp_project_dirs \
     copy_project_required_libs \
     generate_apk_keystore \
     compile_project_code \
     create_project_apk_package \
     zipalign_project_apk_package \
     sign_project_apk_package

# Clear old files and directories that needs to be removed before building
clear:
	if exist $(PROJECT_BUILD_PATH)/bin rmdir $(PROJECT_BUILD_PATH)/bin

# Create required temp directories for APK building
create_temp_project_dirs:
	if not exist $(PROJECT_BUILD_PATH) mkdir $(PROJECT_BUILD_PATH) 
	if not exist $(PROJECT_BUILD_PATH)\obj mkdir $(PROJECT_BUILD_PATH)\obj
	if not exist $(PROJECT_BUILD_PATH)\lib mkdir $(PROJECT_BUILD_PATH)\lib
	if not exist $(PROJECT_BUILD_PATH)\lib\$(ANDROID_ARCH_NAME) mkdir $(PROJECT_BUILD_PATH)\lib\$(ANDROID_ARCH_NAME)
	if not exist $(PROJECT_BUILD_PATH)\bin mkdir $(PROJECT_BUILD_PATH)\bin
	$(foreach dir, $(PROJECT_SOURCE_DIRS), $(call create_dir, $(dir)))

define create_dir
    if not exist $(PROJECT_BUILD_PATH)\obj\$(1) mkdir $(PROJECT_BUILD_PATH)\obj\$(1)
endef
    
# Copy required libs for integration into APK
copy_project_required_libs:
	copy /Y $(RAYLIB_LIB_PATH)\libraylib.a $(PROJECT_BUILD_PATH)\lib\$(ANDROID_ARCH_NAME)\libraylib.a

# Generate storekey for APK signing: $(PROJECT_NAME).keystore
# NOTE: Configure here your Distinguished Names (-dname) if required!
generate_apk_keystore: 
	if not exist $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).keystore $(JAVA_HOME)/bin/keytool -genkeypair -validity 10000 -dname "CN=$(APP_COMPANY_NAME),O=Android,C=ES" -keystore $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).keystore -storepass $(APP_KEYSTORE_PASS) -keypass $(APP_KEYSTORE_PASS) -alias $(PROJECT_NAME)Key -keyalg RSA

# Compile project code into a shared library: lib/lib$(PROJECT_LIBRARY_NAME).so 
compile_project_code: $(OBJS)
	$(CC) -o $(PROJECT_BUILD_PATH)/lib/$(ANDROID_ARCH_NAME)/lib$(PROJECT_LIBRARY_NAME).so $(OBJS) -shared $(INCLUDE_PATHS) $(LDFLAGS) $(LDLIBS)

# Compile all .c files required into object (.o) files
# NOTE: Those files will be linked into a shared library
$(PROJECT_BUILD_PATH)/obj/%.o:src/%.c
	$(CC) -c $^ -o $@ $(INCLUDE_PATHS) $(CFLAGS) --sysroot=$(ANDROID_TOOLCHAIN)/sysroot 

# Create Android APK package: bin/$(PROJECT_NAME).unaligned.apk
# NOTE: Requires compiled lib$(PROJECT_LIBRARY_NAME).so
create_project_apk_package:
	$(ANDROID_BUILD_TOOLS)/aapt package -f -M AndroidManifest.xml -S res -I $(ANDROID_HOME)/platforms/android-$(ANDROID_API_VERSION)/android.jar -F $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).unaligned.apk
	cd $(PROJECT_BUILD_PATH) && $(ANDROID_BUILD_TOOLS)/aapt add bin/$(PROJECT_NAME).unaligned.apk lib/$(ANDROID_ARCH_NAME)/lib$(PROJECT_LIBRARY_NAME).so $(PROJECT_SHARED_LIBS)

# Create zip-aligned APK package: bin/$(PROJECT_NAME).aligned.apk 
zipalign_project_apk_package:
	$(ANDROID_BUILD_TOOLS)/zipalign -p -f 4 $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).unaligned.apk $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).aligned.apk

# Create signed APK package using generated Key: $(PROJECT_NAME).apk 
sign_project_apk_package:
	$(ANDROID_BUILD_TOOLS)/apksigner sign --ks $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).keystore --ks-pass pass:$(APP_KEYSTORE_PASS) --key-pass pass:$(APP_KEYSTORE_PASS) --out $(PROJECT_NAME).apk --ks-key-alias $(PROJECT_NAME)Key $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).aligned.apk

# Install $(PROJECT_NAME).apk to default emulator/device
# NOTE: Use -e (emulator) or -d (device) parameters if required
install:
	$(ANDROID_PLATFORM_TOOLS)/adb install $(PROJECT_NAME).apk
    
# Check supported ABI for the device (armeabi-v7a, arm64-v8a, x86, x86_64)
check_device_abi:
	$(ANDROID_PLATFORM_TOOLS)/adb shell getprop ro.product.cpu.abi

# Monitorize output log coming from device, only raylib tag
logcat:
	$(ANDROID_PLATFORM_TOOLS)/adb logcat -c
	$(ANDROID_PLATFORM_TOOLS)/adb logcat raylib:V *:S
    
# Install and monitorize $(PROJECT_NAME).apk to default emulator/device
deploy:
	$(ANDROID_PLATFORM_TOOLS)/adb install $(PROJECT_NAME).apk
	$(ANDROID_PLATFORM_TOOLS)/adb logcat -c
	$(ANDROID_PLATFORM_TOOLS)/adb logcat raylib:V *:S

#$(ANDROID_PLATFORM_TOOLS)/adb logcat *:W

uninstall:
	$(ANDROID_PLATFORM_TOOLS)/adb uninstall com.oussamateyib.helloworld

# Clean everything
clean:
	del $(PROJECT_BUILD_PATH)\* /f /s /q
	rmdir $(PROJECT_BUILD_PATH) /s /q
	@echo Cleaning done