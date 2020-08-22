// MIDI file player for Z80
// By Jay Valentine.

#include <stdio.h>
#include <midi.h>

char file[20000];

#define NOTE_ON (char)0x0f
#define NOTE_OFF (char)0x0e
#define DELAY (char)0x0d
#define TEMPO (char)0x0c
#define MIDI_EOF (char)0x00

#define NO_NOTE (char)0

#define TRACK0 (char)0b00000000
#define TRACK1 (char)0b00100000
#define TRACK2 (char)0b01000000

char half_ms_per_tick;

void sleep_ticks(char ticks) __z88dk_fastcall;

int main()
{
    midi_init(0b01000110);

    puts("Waiting for file transfer:\r\n");

    char * file_ptr = &file[0];
    while (1)
    {
        char type;
        char note;
        char channel;
        char delay;
        
        type = getchar();
        if (type == MIDI_EOF)
        {
            *file_ptr++ = MIDI_EOF;
            break;
        }

        note = getchar();
        channel = getchar();
        delay = getchar();

        *file_ptr++ = type;
        *file_ptr++ = note;
        *file_ptr++ = channel;
        *file_ptr++ = delay;

        // Get terminating line feed.
        getchar();
        putchar('.');
    }

    puts("File transfer complete.\r\n");

    // Process commands in file.
    file_ptr = &file[0];

    char current_note0 = NO_NOTE;
    char current_note1 = NO_NOTE;
    char current_note2 = NO_NOTE;
    while (1)
    {
        char type = *file_ptr++;

        if (type == MIDI_EOF) break;

        char note = *file_ptr++;
        char channel = *file_ptr++;
        char delay = *file_ptr++;

        sleep_ticks(delay);

        if (type == NOTE_ON)
        {
            if (current_note0 == NO_NOTE)
            {
                current_note0 = note;
                midi_note_on(TRACK0, note);
                putchar('!');
                putchar('0');
            }
            else if (current_note1 == NO_NOTE)
            {
                current_note1 = note;
                midi_note_on(TRACK1, note);
                putchar('!');
                putchar('1');
            }
            else if (current_note2 == NO_NOTE)
            {
                current_note2 = note;
                midi_note_on(TRACK2, note);
                putchar('!');
                putchar('2');
            }
        }
        else if (type == NOTE_OFF)
        {
            if (current_note0 == note)
            {
                current_note0 = NO_NOTE;
                midi_note_off(TRACK0, note);
                putchar('.');
                putchar('0');
            }
            else if (current_note1 == note)
            {
                current_note1 = NO_NOTE;
                midi_note_off(TRACK1, note);
                putchar('.');
                putchar('1');
            }
            else if (current_note2 == note)
            {
                current_note2 = NO_NOTE;
                midi_note_off(TRACK2, note);
                putchar('.');
                putchar('2');
            }
        }
        else if (type == DELAY)
        {
            putchar('~');
        }
        else if (type == TEMPO)
        {
            half_ms_per_tick = note;
            putchar('#');
        }
    }

    puts("Done\r\n");

    return 0;
}
