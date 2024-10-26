## Hello World App

This is a simple Android application written entirely in C.

The app opens a window displaying the text "Hello, World!" using [raylib](https://github.com/raysan5/raylib) for graphics rendering.

### Getting Started
Build the project:
```
cmake -B build -DCMAKE_TOOLCHAIN_FILE=%ANDROID_NDK_HOME%\build\cmake\android.toolchain.cmake -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-35 -G Ninja
cmake --build build
```

### License

This project is licensed under the [MIT License](LICENSE).
