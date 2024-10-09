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

```