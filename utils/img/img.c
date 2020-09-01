// Bitmap image viewer for the ModularZ80.
// By Jay Valentine.

#include <stdio.h>

#define WIDTH 10
#define HEIGHT 10

char red[HEIGHT][WIDTH];
char green[HEIGHT][WIDTH];
char blue[HEIGHT][WIDTH];

int main()
{
    for (unsigned int r = 0; r < HEIGHT; r++)
    {
        for (unsigned int c = 0; c < WIDTH; c++)
        {
            printf("\033[38;2;%d;%d;%dm#", 40);
        }

        puts("\n");
    }
}