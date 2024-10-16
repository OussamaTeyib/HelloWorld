#include <raylib.h>

int main(void) {
    InitWindow(GetScreenWidth(), GetScreenHeight(), "My App");

    SetTargetFPS(60); 
    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("Hello, World!", 190, 200, 20, LIGHTGRAY);
        EndDrawing();
    }

    CloseWindow();
    return 0;
}