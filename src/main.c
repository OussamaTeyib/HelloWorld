#include <raylib.h>

int CalculateFontSize(const int width, const int height, const char *text)
{
    // Leave some padding
    const int maxWidth = width * 0.8;
    const int maxHeight = height * 0.8;

    int low = 1; // Minimum font size
    int high = maxHeight; // Maximum font size
    int fontSize = 1;

    // Search for the maximum font size that fits
    while (low <= high) {
        fontSize = (low + high) / 2;
        const int textWidth = MeasureText(text, fontSize);

        if (textWidth <= maxWidth && fontSize <= maxHeight)
            low = fontSize + 1; // Increase font size
        else
            high = fontSize - 1; // Decrease font size
    }
    // Use the maximum valid font size found
    fontSize = high;
    return fontSize;
}

int main(void) {
    InitWindow(0, 0, "Hello World App");

    const char *text = "Hello, World!";

    // Calculate the font size based on screen dimensions
    int fontSize = CalculateFontSize(GetScreenWidth(), GetScreenHeight(), text);

    // Set the target frames per second (FPS)
    SetTargetFPS(60);

    // Main game loop
    while (!WindowShouldClose()) {
        // Begin drawing to the screen
        BeginDrawing();

        // Clear the background with a white color
        ClearBackground(WHITE);

        // Calculate positions for centring
        const int posX = (GetScreenWidth() - MeasureText(text, fontSize)) / 2;
        const int posY = (GetScreenHeight() - fontSize) / 2;

        // Draw the text on the screen
        DrawText(text, posX, posY, fontSize, BLACK);

        // End the drawing process
        EndDrawing();
    }

    // Close the window and unload resources
    CloseWindow();
    return 0;
}