#include <raylib.h>

// Calculates the optimal font size that fits the text within the given width and height
int CalculateFontSize(const int width, const int height, const char *text)
{
    // Leave some padding (use 80% of the given dimensions)
    const int maxWidth = (int)(width * 0.8f);
    const int maxHeight = (int)(height * 0.8f);

    int low = 1; // Minimum font size
    int high = maxHeight; // Maximum font size
    int fontSize = 1;

    // Binary search for the largest font size that fits
    while (low <= high) {
        fontSize = (low + high) / 2;
        const int textWidth = MeasureText(text, fontSize);

        // Check if current font size meets width and height requirements
        if (textWidth <= maxWidth && fontSize <= maxHeight)
            low = fontSize + 1; // Try larger font size
        else
            high = fontSize - 1; // Try smaller font size
    }
    // Maximum valid font size found
    fontSize = high;
    return fontSize;
}

int main(void) {
    // Initialize a window that scales to the screen dimensions
    InitWindow(0, 0, "Hello World App");

    // The text to display
    const char *text = "Hello, World!";

    // Get screen dimensions
    const int screenWidth = GetScreenWidth();
    const int screenHeight = GetScreenHeight();
    // Calculate the font size based on screen dimensions
    const int fontSize = CalculateFontSize(screenWidth, screenHeight, text);

    // Set frame rate
    SetTargetFPS(60);

    // Main application loop
    while (!WindowShouldClose()) {
        // Center the text based on calculated font size
        const int posX = (screenWidth - MeasureText(text, fontSize)) / 2;
        const int posY = (screenHeight - fontSize) / 2;

        // Begin the drawing process
        BeginDrawing();
        // Clear background with white color
        ClearBackground(WHITE);
        // Draw centred text
        DrawText(text, posX, posY, fontSize, BLACK);
        // End the drawing process
        EndDrawing();
    }

    // Clean up and close the window
    CloseWindow();
    return 0;
}