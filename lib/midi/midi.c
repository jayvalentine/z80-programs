#include "midi_table.inc"

unsigned char psg_port;

void out(unsigned char b) __z88dk_fastcall;

void midi_init(unsigned char port)
{
    psg_port = port;
}

void midi_note_on(unsigned char note)
{
    unsigned char byte0 = midi_table[note << 1];
    unsigned char byte1 = midi_table[(note << 1) + 1];

    out(byte0);
    out(byte1);
    out(0b00000000);
}

#asm
_out:
    push    HL
    push    BC
    push    AF

    ld      A, (_psg_port)
    ld      C, A
    out     (C), L

    pop     AF
    pop     BC
    pop     HL
    ret
#endasm
