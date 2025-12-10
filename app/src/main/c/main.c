#include <raylib.h>

// Compute maximum font size that allows text to fit within given bounds
int CalculateFontSize(const int width, const int height, const char *text) {
    if (!text || width <= 0 || height <= 0)
        return 0;

    // Reserve 80% of area for text to provide margins
    const int maxWidth = width * 4 / 5;
    const int maxHeight = height * 4 / 5;

    int low = 1;
    int high = maxHeight;

    // Binary search for largest valid font size
    while (low <= high) {
        const int candidate = (low + high) / 2; // Candidate font size
        const int textWidth = MeasureText(text, candidate);

        // If it fits, search higher. Otherwise, search lower.
        if (textWidth <= maxWidth && candidate <= maxHeight)
            low = candidate + 1;
        else
            high = candidate - 1;
    }

    return high;
}

int main(void) {
    // Initialize a window
    InitWindow(0, 0, "HelloWorld");

    // Text to render
    const char *text = "Hello, world!";

    // Get screen dimensions
    const int screenWidth = GetScreenWidth();
    const int screenHeight = GetScreenHeight();

    // Compute font size based on available space
    const int fontSize = CalculateFontSize(screenWidth, screenHeight, text);

    // Compute centered text position
    const int posX = (screenWidth - MeasureText(text, fontSize)) / 2;
    const int posY = (screenHeight - fontSize) / 2;

    // Configure target frame rate
    SetTargetFPS(60);

    // Main loop
    while (!WindowShouldClose()) {
        // Begin drawing process
        BeginDrawing();

        // Clear background with white
        ClearBackground(WHITE);

        // Render centered text
        DrawText(text, posX, posY, fontSize, BLACK);

        // End drawing process
        EndDrawing();
    }

    // Clean up and close window
    CloseWindow();
    return 0;
}