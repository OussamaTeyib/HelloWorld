#include <raylib.h>

int main(void) {
    InitWindow(0, 0, "My App");

    SetTargetFPS(60);
    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(WHITE);
        DrawText("Hello, World!", GetScreenWidth() * 0.3, GetScreenHeight() * 0.45, 50, BLACK);
        EndDrawing();
    }

    CloseWindow();
    return 0;
}