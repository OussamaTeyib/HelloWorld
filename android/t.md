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
#include <android_native_app_glue.h>
#include <raylib.h>

void android_main(struct android_app* state) {
    InitWindow(GetScreenWidth(), GetScreenHeight(), "My App");

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
```

**android/AndroidManifest.txt**:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.oussamateyib.helloworld"
    android:versionCode="1"
    android:versionName="1.0.0">

    <uses-sdk android:minSdkVersion="21" android:targetSdkVersion="35" />

    <application android:label="Hello World">
        <activity android:name="android.app.NativeActivity"
            android:label="Hello World"
            android:configChanges="orientation|keyboardHidden|screenSize"
            android:exported="true"
            android:hasCode="false">

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
--> `libhello_world.so` is generated successfully and i copied it to subdirectory `lib/arm64-v8a`.

Then i run:
```
aapt package -f -m -F HelloWorld-temp.apk -M ../android/AndroidManifest.xml -I %ANDROID_HOME%/platforms/android-35/android.jar
```
```
aapt add HelloWorld-temp.apk lib/arm64-v8a/libhello_world.so
```
--> apk is packaged successfully 

Then i run:
```
zipalign -v 4 HelloWorld-temp.apk 
HelloWorld.apk
```
--> apk is aligned successfully 

Then i run:
```
apksigner sign --ks my-key.jks --ks-key-alias HelloWorld HelloWorld.apk
```
--> apk is signed successfully with my previously generated key.

Then i run (with my phone connected via usb):
```
adb install HelloWorld.apk
```
Output:
```
* daemon not running; starting now at tcp:5037
* daemon strated successfully
Performing Incremental Install
Success
Install command complete in 3275 ms 
```
--> The app is installed successfully but it crashes right after opening it?

Any idea?
Note: my phone abi is indeed `arm64-v8a`.