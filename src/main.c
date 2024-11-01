#include <raylib.h>

int main(void) {
    // Initialize the window with a width and height of 0 (fullscreen).
    InitWindow(0, 0, "My App");

    // Set the desired frames per second (FPS) for the game loop.
    SetTargetFPS(60);

    // Main game loop
    while (!WindowShouldClose()) {
        // Begin drawing to the screen.
        BeginDrawing();

        // Clear the background with a white color.
        ClearBackground(WHITE);

        // Draw the text on the screen at specified position.
        // The position is calculated based on the screen width and height for centering.
        DrawText("Hello, World!", GetScreenWidth() * 0.3, GetScreenHeight() * 0.45, 50, BLACK);

        // End the drawing process.
        EndDrawing();
    }

    // Close the window and unload resources
    CloseWindow();
    return 0;
}