// MIDI file player for Z80
// By Jay Valentine.

#include <stdio.h>
#include <midi.h>

unsigned char file[256];

int main()
{
    midi_init(0b01000110);
    
    puts("Waiting for file transfer:\r\n");

    for (unsigned int i = 0; i < 256; i++)
    {
        int in = getchar();
        if (in == EOF) break;

        putchar(in); // Echo to user.

        file[i] = (char)in;
    }

    puts("File transfer complete.\r\n");

    for (unsigned int i = 0; i < 256; i++)
    {
        midi_note_on(file[i]);
        for (unsigned int j = 0; j < 60000; j++);
        midi_note_off(file[i]);
    }

    return 0;
}
