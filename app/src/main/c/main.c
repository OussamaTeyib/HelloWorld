#include <raylib.h>
#include <stddef.h>

// Compute maximum font size that allows text to fit within given bounds
static int CalculateFontSize(int width, int height, const char *text) {
    int result = 0;

    if ((text != NULL) && (width > 0) && (height > 0)) {
        // Reserve 80% of area for text to provide margins
        const int maxWidth = (width * 4) / 5;
        const int maxHeight = (height * 4) / 5;

        int low = 1;
        int high = maxHeight;

        // Binary search for largest valid font size
        while (low <= high) {
            const int mid = low + (high - low) / 2; // Candidate font size
            const int textWidth = MeasureText(text, mid);

            // If it fits, search higher. Otherwise, search lower.
            if (textWidth <= maxWidth) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }

        result = high;
    }

    return result;
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