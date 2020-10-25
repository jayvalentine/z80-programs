    PUBLIC  _main

    ; stdio.h
    EXTERN  _puts
    EXTERN  _printf
    EXTERN  _putchar

    DEFC    DISKPORT = $18
_main:
    call    _init

    ld      BC, 128
    ld      DE, 0
    ld      HL, $9200
    call    _read_sector
    
    ld      DE, $9200
    call    _print_data

    push    HL
    ld      L, $0d
    call    _putchar
    ld      L, $0a
    call    _putchar
    pop     HL

    ret

_init:
    push    AF
    call    _wait
    ld      A, $04
    out     (DISKPORT+7), A

    call    _wait
    ld      A, $01
    out     (DISKPORT+1), A

    call    _wait
    ld      A, $ef
    out     (DISKPORT+7), A

    call    _chkerr
    pop     AF
    ret

    ; Set the LBA for the CF-card, stored as a 28-bit value
    ; in DEBC (the top 4 bits of D are ignored).
_set_lba:
    push    AF

    ; Set the lower 3/4ths of the LBA via registers 3-5.
    ld      A, C
    out     (DISKPORT+3), A
    ld      A, B
    out     (DISKPORT+4), A
    ld      A, E
    out     (DISKPORT+5), A
    
    ; Special handling for register 6, as only the bottom half is used
    ; for LBA.
    ld      A, D

    ; We only care about the bottom half of this top byte.
    and     A, %00001111

    ; Master, LBA mode.
    or      A, %11100000
    out     (DISKPORT+6), A
    
    pop     AF
    ret

_chkerr:
    in      A, (DISKPORT+7)
    bit     0, A
    jp      z, _chkerr_noerr

    ld      HL, _error
    call    _puts

_chkerr_noerr:
    ret

_wait:
    in      A, (DISKPORT+7)
    and     %10000000
    jp      nz, _wait

    ret

_wait_data:
    in      A, (DISKPORT+7)
    and     %10001000
    xor     %00001000
    jp      nz, _wait_data

    ret

_wait_cmd:
    in      A, (DISKPORT+7)
    and     %11000000
    xor     %01000000
    jp      nz, _wait_cmd

    ret

    ; Reads 512 bytes (one sector) from the CF card.
    ; Reads the data into the location pointed to by HL.
    ; Assumes a read command has been previously initiated.
_read_data:
    push    AF
    push    BC
    push    HL

    call    _wait_data
    call    _chkerr

    ld      C, DISKPORT
    ld      B, 0

    ; Load 512 bytes into HL.
    inir
    inir

__read_data_done:
    pop     HL
    pop     BC
    pop     AF
    ret

    ; Read the sector indicated by DEBC,
    ; into the location pointed to by HL.
    ; HL must contain 512 bytes of space for the sector.
_read_sector:
    push    AF

    ; Sector number already in DEBC, so we just need
    ; to call the set_lba subroutine.
    call    _set_lba

    ; Transfer one sector
    ld      A, $01
    out     (DISKPORT+2), A

    ; Drive ID command
    call    _wait_cmd
    ld      A, $20
    out     (DISKPORT+7), A

    ; Read 512 bytes from CF-card.
    call    _read_data

    pop     AF
    ret

    ; Prints the ASCII values of 512 bytes, starting at the location in DE.
    ; Prints any characters below $20 (i.e. control characters/non-printable) as '.'.
_print_data:
    push    AF
    push    BC
    push    DE
    push    HL

    ; 16 loops, printing 32 bytes each time
    ld      B, 32

__print_data_loop:
    ; We want to print two 'views' of the data.
    ; One is the hex representation of each byte,
    ; the other is the ASCII view.

    ; At this point, DE points to the line.

    push    BC
    ld      B, 16

    push    DE
    call    _hex_view

    ld      HL, _view_seperator
    call    _puts

    pop     DE
    call    _ascii_view

    ld      L, $0d
    call    _putchar
    ld      L, $0a
    call    _putchar

    pop     BC

    djnz    __print_data_loop

    pop     HL
    pop     DE
    pop     BC
    pop     AF

    ret

_hex_view:
    push    AF
    push    HL
    push    BC

__hex_view_loop:
    ld      A, (DE)
    inc     DE

    ; Pointer to format string
    ld      HL, _byte_format
    push    HL

    ; One arg to format - value loaded from memory
    ld      L, A
    ld      H, 0
    push    HL

    ; Is this a z88dk bug or expected behaviour?
    ; Seems the "variadic args" count includes the fixed argument.
    ld      A, 2
    call    _printf
    
    ; Discard args
    pop     HL
    pop     HL

    djnz    __hex_view_loop

    pop     BC
    pop     HL
    pop     AF
    ret

_ascii_view:
    ld      A, (DE)
    inc     DE

    ; Default character if actual character is non-printable
    ld      L, '.'

    ; Printable or non-printable?
    cp      $20
    jp      c, __ascii_nonprintable

    ld      L, '.'

    cp      $7f
    jp      nc, __ascii_nonprintable

    ld      L, A

__ascii_nonprintable:
    call    _putchar

    djnz    _ascii_view
    ret

_info:
    defm    "Disk info:\n\r\n\r"
    defb    0

_data:
    defm    "Sector 0:\n\r\n\r"
    defb    0

_waiting:
    defm    "Waiting... "
    defb    0

_waiting_cmd:
    defm    "Waiting (command)... "
    defb    0

_waiting_dat:
    defm    "Waiting (data)...\n\r"
    defb    0

_waiting_done:
    defm    "Done\n\r"
    defb    0

_error:
    defm    "Error!\n\r"
    defb    0

_byte_format:
    defm    "%x "
    defb    0

_view_seperator:
    defm    " | "
    defb    0
