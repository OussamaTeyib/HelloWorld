#include <raylib.h>

int main(int argc, char *argv[]) {
    InitWindow(0, 0, "My App");
    SetWindowSize(GetScreenWidth(), GetScreenHeight());

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("Hello, World!", 190, 200, 20, LIGHTGRAY);
        EndDrawing();
    }

    CloseWindow();
    return 0;
}