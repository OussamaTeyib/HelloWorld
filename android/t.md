Hi, guys!
I want to create a simple HelloWorld apk in C using raylib.

My project structure:
```
HelloWorld/
    ├── CMakeLists.txt
    ├── src/
    │   ├── main.c
    ├── android/
    │   └── AndroidManifest.xml
    └── build/
```

**src/main.c**:
```c
#include <raylib.h>

int main(void) {
    InitWindow(800, 600, "My App");

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("Hello, World!", 190, 200, 20, LIGHTGRAY);
        EndDrawing();
    }

    CloseWindow();
}
```

**CMakeLists.txt**:
```make
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
```

**android/AndroidManifest.txt**:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.oussamateyib.helloworld"
    android:versionCode="1"
    android:versionName="1.0.0">

    <uses-sdk android:minSdkVersion="21" android:targetSdkVersion="35" />

    <application android:label="Hello World"
        <activity android:name="android.app.NativeActivity"
            android:label="Hello World"
            android:configChanges="orientation|keyboardHidden|screenSize"
            android:exported="true">

            <meta-data android:name="android.app.lib_name" android:value="hello_world" />

            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

In `build/`:
I run:
```
cmake -G "Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=%ANDROID_NDK_HOME%\build\cmake\android.toolchain.cmake -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-35 ..
make
```
--> libhello_world.so generated cop it
 aapt package -f -m -F HelloWorld-temp.apk -M ../android/AndroidManifest.xml -S ../res -I %ANDROID_HOME%/platforms/android-35/android.jar
aapt add HelloWorld-temp.apk lib/arm64-v8a/libhello_world.so
 'lib/arm64-v8a/libhello_world.so'...
zipalign -v 4 HelloWorld-temp.apk HelloWorld.apk
apksigner sign --ks my-key.jks --ks-key-alias HelloWorld HelloWorld.apk
adb install HelloWorld.apk
Performing Incremental Install
Serving...
All files should be loaded. Notifying the device.
Failure [INSTALL_FAILED_INVALID_APK: Scanning Failed.: Package /data/app/~~KjqkABJbYD3SKFrJm_qwcQ==/com.oussamateyib.helloworld-rmQUIQxHLXKSuzm4eo3fuw==/base.apk code is missing]
Performing Streamed Install
adb: failed to install HelloWorld.apk: Failure [INSTALL_FAILED_INVALID_APK: Scanning Failed.: Package /data/app/~~XZVZL92TWsjSrZ9uSFjbnA==/com.oussamateyib.helloworld-kNUa5nkn8bMXnGgJs30uBg==/base.apk code is





make
[ 50%] Built target native_app_glue
[ 75%] Building C object CMakeFiles/hello_world.dir/src/main.c.o
[100%] Linking C shared library libhello_world.so
ld.lld: error: duplicate symbol: android_main
>>> defined at main.c:4 (C:/C/HelloWorld/src/main.c:4)
>>>            CMakeFiles/hello_world.dir/src/main.c.o:(android_main)
>>> defined at rcore.c
>>>            rcore.o:(.text.android_main+0x0) in archive C:\Programs\Android\raylib/lib/arm64/libraylib.a
clang: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [CMakeFiles/hello_world.dir/build.make:98: libhello_world.so] Error 1
make[1]: *** [CMakeFiles/Makefile2:85: CMakeFiles/hello_world.dir/all] Error 2
make: *** [Makefile:91: all] Error 2