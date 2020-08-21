// MIDI file player for Z80
// By Jay Valentine.

#include <stdio.h>
#include <midi.h>

char file[4096];

#define NOTE_ON (char)0x0f
#define NOTE_OFF (char)0x0e
#define MIDI_EOF (char)0x00

void sleep_ticks(unsigned int ticks) __z88dk_fastcall;

int main()
{
    midi_init(0b01000110);

    puts("Waiting for file transfer:\r\n");

    char * file_ptr = &file[0];
    while (1)
    {
        char type;
        char note;
        char byte0;
        char byte1;
        
        type = getchar();
        if (type == MIDI_EOF) break;

        note = getchar();
        byte0 = getchar();
        byte1 = getchar();

        *file_ptr++ = type;
        *file_ptr++ = note;
        *file_ptr++ = byte0;
        *file_ptr++ = byte1;

        // Get terminating line feed.
        getchar();
        putchar('.');
    }

    puts("File transfer complete.\r\n");

    // Process commands in file.
    file_ptr = &file[0];
    while (1)
    {
        char type = *file_ptr++;

        if (type == MIDI_EOF) break;

        char note = *file_ptr++;
        unsigned int byte0 = *file_ptr++;
        unsigned int byte1 = ((unsigned int)(*file_ptr++)) << 8;

        sleep_ticks(byte1 | byte0);

        if (type == NOTE_ON)
        {
            midi_note_on(note);
            putchar('!');
        }
        else if (type == NOTE_OFF)
        {
            midi_note_off(note);
            putchar('.');
        }
    }

    puts("Done\r\n");

    return 0;
}
