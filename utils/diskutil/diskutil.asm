    PUBLIC  _main

    ; stdio.h
    EXTERN  _puts
    EXTERN  _printf
    EXTERN  _putchar

    DEFC    DISKPORT = $18
_main:
_init:
    call    _wait
    ld      A, $04
    out     (DISKPORT+7), A
    
    call    _wait
    ld      A, $e0
    out     (DISKPORT+6), A

    call    _wait
    ld      A, $01
    out     (DISKPORT+1), A

    call    _wait
    ld      A, $ef
    out     (DISKPORT+7), A

    call    _chkerr

_print_info:
    call    _wait_cmd
    ld      A, $ec
    out     (DISKPORT+7), A

    ; Location of info read from CF-card.
    ld      DE, $9000

_print_sector0:
    ; Set LBA to sector 0.
    push    DE
    ld      DE, $0000
    ld      HL, $0000
    call    _set_lba
    pop     DE

    ; Transfer one sector
    ld      A, $01
    out     (DISKPORT+2), A

    ; Read sector command
    call    _wait_cmd
    ld      A, $20
    out     (DISKPORT+7), A

    ; Location of data read from sector 0
    ld      DE, $9200

    ld      HL, _data
    call    _puts

    call    _read_data
    call    _chkerr
    
    call    _print_data

    ret

    ; Set the LBA for the CF-card, stored as a 28-bit value
    ; in DEHL (the top 4 bits of D are ignored).
_set_lba:
    push    AF
    
    ; Special handling for register 6, as only the bottom half is used
    ; for LBA.
    ld      A, D

    ; We only care about the bottom half of this top byte.
    and     A, %00001111

    ; Master, LBA mode.
    or      A, %11100000
    out     (DISKPORT+6), A

    ; Now we can set the rest of the LBA via the other 3 registers.
    ld      A, E
    out     (DISKPORT+5), A
    ld      A, H
    out     (DISKPORT+4), A
    ld      A, L
    out     (DISKPORT+3), A
    
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
    ld      HL, _waiting
    call    _puts

_wait_loop:
    in      A, (DISKPORT+7)
    and     %10000000
    jp      nz, _wait_loop

    ld      HL, _waiting_done
    call    _puts

    ret

_wait_data:
_wait_data_loop:
    in      A, (DISKPORT+7)
    and     %10001000
    xor     %00001000
    jp      nz, _wait_data_loop

    ret

_wait_cmd:
    ld      HL, _waiting_cmd
    call    _puts

_wait_cmd_loop:
    in      A, (DISKPORT+7)
    and     %11000000
    xor     %01000000
    jp      nz, _wait_cmd_loop

    ld      HL, _waiting_done
    call    _puts

    ret

    ; Reads 512 bytes (one sector) from the CF card.
    ; Reads the data into the location pointed to by DE.
    ; Assumes a read command has been previously initiated.
_read_data:
    push    AF
    push    BC
    push    HL
    push    DE

    ld      B, 0

__read_data_loop:
    call    _wait_data
    in      A, (DISKPORT)
    ld      (DE), A
    inc     DE

    call    _wait_data
    in      A, (DISKPORT)
    ld      (DE), A
    inc     DE
    
    djnz    __read_data_loop

__read_data_done:
    pop     DE
    pop     HL
    pop     BC
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
    push    BC
    ld      B, 16

__print_line_loop:
    ld      A, (DE)
    inc     DE

    ; One arg to format - value loaded from memory.
    ld      L, A
    ld      H, 0
    push    HL

    ; Pointer to format string
    ld      HL, _byte_format
    push    HL

    ; One variadic arg to printf
    ld      A, 1
    call    _printf

    ; Discard arguments.
    pop     HL
    pop     HL

    djnz    __print_line_loop

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
