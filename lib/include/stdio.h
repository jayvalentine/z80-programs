// stdio.h.
// Implementation for Modular-Z80 platform.
// Copyright (c) Jay Valentine 2020.

#define NULL 0
#define EOF -1

// puts
// Prints a string to standard output (serial port).
int     puts(const char *s) __z88dk_fastcall;

// putchar
// Prints a character to standard output (serial port).
int     putchar(int c) __z88dk_fastcall;

// getchar
// Returns a character from standard input (serial port), or EOF if end of stream.
int     getchar(void);
