// MIDI file player for Z80
// By Jay Valentine.

#include <stdio.h>

unsigned char file[256];
unsigned int file_ptr;

int main()
{
    file_ptr = 0;
    puts("Waiting for file transfer:\r\n");

    for (unsigned int i = 0; i < 256; i++)
    {
        int in = getchar();
        if (in == EOF) break;

        file[file_ptr++] = (char)in;
    }

    puts("File transfer complete.\r\n");

    return 0;
}
