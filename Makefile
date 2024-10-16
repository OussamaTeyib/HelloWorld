SHELL = cmd

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
ANDROID_HOME           ?= C:\Programs\Android\SDK
ANDROID_NDK            ?= C:\Programs\Android\SDK\ndk\27.0.12077973
ANDROID_TOOLCHAIN      ?= $(ANDROID_NDK)\toolchains\llvm\prebuilt\windows-x86_64
RAYLIB_LIB_PATH        ?= C:\Programs\Android\raylib\lib\$(ANDROID_ARCH_NAME)
RAYLIB_INCLUDE_PATH    ?= C:\Programs\Android\raylib\include

# Android configuration variables
PROJECT_NAME           ?= Hello_World
PROJECT_LIBRARY_NAME   ?= main
PROJECT_BUILD_PATH     ?= build
PROJECT_SOURCE_PATH     ?= src
APP_PACKAGE_NAME       ?= com.oussamateyib.helloworld
USER_ID                ?= 0

# Key generaration variables
COMMON_NAME            ?= Oussama Teyib
ORGANIZATION           ?= oussamateyib
COUNTRY                ?= MR
APP_KEYSTORE_PASS      ?= 291199

# Compiler and archiver
ifeq ($(ANDROID_ARCH),ARM)
    CC = $(ANDROID_TOOLCHAIN)/bin/armv7a-linux-androideabi$(ANDROID_API_VERSION)-clang
endif
ifeq ($(ANDROID_ARCH),ARM64)
    CC = $(ANDROID_TOOLCHAIN)/bin/aarch64-linux-android$(ANDROID_API_VERSION)-clang
endif
ifeq ($(ANDROID_ARCH),x86)
    CC = $(ANDROID_TOOLCHAIN)/bin/i686-linux-android$(ANDROID_API_VERSION)-clang
endif
ifeq ($(ANDROID_ARCH),x86_64)
    CC = $(ANDROID_TOOLCHAIN)/bin/x86_64-linux-android$(ANDROID_API_VERSION)-clang
endif

# Define Compiler flags
CFLAGS = -std=c17
# Compilation functions attributes options
CFLAGS += -ffunction-sections -funwind-tables -fstack-protector-strong -fPIC
# Compiler options for the linker
CFLAGS += -Wall -Wa,--noexecstack -Wformat -Werror=format-security -no-canonical-prefixes
# Preprocessor macro definitions
CFLAGS += -D__ANDROID__ -DPLATFORM_ANDROID -D__ANDROID_API__=$(ANDROID_API_VERSION)
# Compiler flags for architecture
ifeq ($(ANDROID_ARCH),ARM)
    CFLAGS += -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16
endif
ifeq ($(ANDROID_ARCH),ARM64)
    CFLAGS += -std=c17 -march=armv8-a -mfix-cortex-a53-835769
endif

# Paths containing required header files
INCLUDE_PATHS = -I$(PROJECT_SOURCE_PATH) -I$(RAYLIB_INCLUDE_PATH)

# Linker options
LDFLAGS = -Wl,-soname,lib$(PROJECT_LIBRARY_NAME).so -Wl,--exclude-libs,libatomic.a 
LDFLAGS += -Wl,--build-id -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--warn-shared-textrel -Wl,--fatal-warnings 
# Force linking of library module to define symbol
LDFLAGS += -u ANativeActivity_onCreate
# Library paths containing required libs
LDFLAGS += -L$(PROJECT_BUILD_PATH)/obj -L$(RAYLIB_LIB_PATH)

# Define any libraries to link
LDLIBS = -lm -lc -lraylib -llog -landroid -lEGL -lGLESv2 -lOpenSLES -ldl

# Get source files
PROJECT_SOURCE_FILES = $(wildcard $(PROJECT_SOURCE_PATH)/*.c)
# Generate target objects list from PROJECT_SOURCE_FILES
OBJS = $(patsubst $(PROJECT_SOURCE_PATH)/%.c, $(PROJECT_BUILD_PATH)/obj/%.o, $(PROJECT_SOURCE_FILES))

# Android APK building process... some steps required...
# NOTE: typing 'make' will invoke the default target entry called 'all',
all: clear \
     create_temp_project_dirs \
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

# Generate storekey for APK signing: $(PROJECT_NAME).keystore
generate_apk_keystore: 
	if not exist $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).keystore keytool -genkeypair -validity 10000 -dname "CN=$(COMMON_NAME),O=$(ORGANIZATION),C=$(COUNTRY)" -keystore $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).keystore -storepass $(APP_KEYSTORE_PASS) -keypass $(APP_KEYSTORE_PASS) -alias $(PROJECT_NAME)Key -keyalg RSA

# Compile project code into a shared library: lib/lib$(PROJECT_LIBRARY_NAME).so 
compile_project_code: $(OBJS)
	$(CC) -o $(PROJECT_BUILD_PATH)/lib/$(ANDROID_ARCH_NAME)/lib$(PROJECT_LIBRARY_NAME).so $(OBJS) -shared $(INCLUDE_PATHS) $(LDFLAGS) $(LDLIBS)

# Compile all .c files required into object (.o) files
# NOTE: Those files will be linked into a shared library
$(PROJECT_BUILD_PATH)/obj/%.o:$(PROJECT_SOURCE_PATH)/%.c
	$(CC) -c $^ -o $@ $(INCLUDE_PATHS) $(CFLAGS) --sysroot=$(ANDROID_TOOLCHAIN)/sysroot 

# Create Android APK package: bin/$(PROJECT_NAME).unaligned.apk
create_project_apk_package:
	aapt package -f -M AndroidManifest.xml -S res -I $(ANDROID_HOME)/platforms/android-$(ANDROID_API_VERSION)/android.jar -F $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).unaligned.apk
	cd $(PROJECT_BUILD_PATH) && aapt add bin/$(PROJECT_NAME).unaligned.apk lib/$(ANDROID_ARCH_NAME)/lib$(PROJECT_LIBRARY_NAME).so

# Create zip-aligned APK package: bin/$(PROJECT_NAME).aligned.apk 
zipalign_project_apk_package:
	zipalign -p -f 4 $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).unaligned.apk $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).aligned.apk

# Create signed APK package using generated Key: $(PROJECT_NAME).apk 
sign_project_apk_package:
	apksigner sign --ks $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).keystore --ks-pass pass:$(APP_KEYSTORE_PASS) --key-pass pass:$(APP_KEYSTORE_PASS) --out $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).apk --ks-key-alias $(PROJECT_NAME)Key $(PROJECT_BUILD_PATH)/bin/$(PROJECT_NAME).aligned.apk

# Install $(PROJECT_NAME).apk to default emulator/device
# NOTE: Use -e (emulator) or -d (device) parameters if required
install:
	adb install --user $(USER_ID) $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).apk
    
# Check supported ABI for the device (armeabi-v7a, arm64-v8a, x86, x86_64)
check_device_abi:
	adb shell getprop ro.product.cpu.abi

# List current users on the emulator/device
list_users:
	adb shell pm list users

# Monitorize output log coming from device, only raylib tag
logcat:
	adb logcat -c
	adb logcat raylib:V *:S
    
# Install and monitorize $(PROJECT_NAME).apk to default emulator/device
deploy:
	adb install --user $(USER_ID) $(PROJECT_BUILD_PATH)/$(PROJECT_NAME).apk
	adb logcat -c
	adb logcat raylib:V *:S

uninstall:
	adb uninstall --user $(USER_ID) $(APP_PACKAGE_NAME)

# Clean everything
clean:
	del $(PROJECT_BUILD_PATH)\* /f /s /q
	rmdir $(PROJECT_BUILD_PATH) /s /q
	@echo Cleaning done