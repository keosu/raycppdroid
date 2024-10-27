#include <cstdlib>
#include <raylib.h>

int
main()
{
  InitWindow(480, 480, "raylib-android");

  while (!WindowShouldClose()) {
    BeginDrawing();

    ClearBackground(RAYWHITE);

    EndDrawing();
  }

  CloseWindow();

  return EXIT_SUCCESS;
}