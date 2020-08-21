// MIDI handling library for a 76489 PSG.
// By Jay Valentine

void midi_init(unsigned char port);
void midi_note_on(unsigned char note);
void midi_note_off(unsigned char note);
