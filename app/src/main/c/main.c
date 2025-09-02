#include <raylib.h>

// Calculates the largest font size that fits the text within the given width and height
int CalculateFontSize(const int width, const int height, const char *text) {
    if (!text || width <= 0 || height <= 0)
        return 0;
    
    // Use 80% of available width and height to leave margins
    const int maxWidth = width * 4 / 5;
    const int maxHeight = height * 4 / 5;

    int low = 1;
    int high = maxHeight;

    // Binary search to find the maximum fitting font size
    while (low <= high) {
        const int candidate = (low + high) / 2; // Candidate font size
        const int textWidth = MeasureText(text, candidate);

        // If it fits, search higher. Otherwise, search lower.
        if (textWidth <= maxWidth && candidate <= maxHeight)
            low = candidate + 1;
        else
            high = candidate - 1;
    }

    return high; // Largest valid font size
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

    // Center the text based on calculated font size
    const int posX = (screenWidth - MeasureText(text, fontSize)) / 2;
    const int posY = (screenHeight - fontSize) / 2;

    // Set target frame rate
    SetTargetFPS(60);

    // Main application loop
    while (!WindowShouldClose()) {
        // Begin the drawing process
        BeginDrawing();

        // Clear the background with white
        ClearBackground(WHITE);

        // Draw centered text
        DrawText(text, posX, posY, fontSize, BLACK);

        // End the drawing process
        EndDrawing();
    }

    // Clean up and close the window
    CloseWindow();
    return 0;
}