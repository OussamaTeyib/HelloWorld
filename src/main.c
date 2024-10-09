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