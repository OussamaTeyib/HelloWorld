#include <android_native_app_glue.h>
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