#include "midi_table.inc"

unsigned char psg_port;

void out(unsigned char b) __z88dk_fastcall;

void midi_init(unsigned char port)
{
    psg_port = port;
    out(0b10011111);
    out(0b10111111);
    out(0b11011111);
    out(0b11111111);
}

void midi_note_on(unsigned char note)
{
    unsigned char byte0 = midi_table[note << 1];
    unsigned char byte1 = midi_table[(note << 1) + 1];

    byte0 |= 10000000;
    out(byte0);

    out(byte1);

    out(0b10010000);
}

void midi_note_off(unsigned char note)
{
    out(0b10011111);
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
