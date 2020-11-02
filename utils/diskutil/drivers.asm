    ; Compact-Flash IDE drivers.

    ; Definitions and externs.

    ; Exported functions.
    PUBLIC  _read_sector
    PUBLIC  _write_sector

    ; void read_sector(char * buf, unsigned long sector)
    ;
    ; Read the sector indicated by <sector>,
    ; into the location pointed to by <buf>.
    ;
    ; <buf> must contain 512 bytes of space for the sector.
_read_sector:
    ; Get parameters.
    ld      HL, 2
    add     HL, SP

    push    HL
    pop     IX

    ; Sector number, little-endian.
    ; Lowest 16 bytes is at the top of the stack.
    ld      C, (IX+0)
    ld      B, (IX+1)
    ld      E, (IX+2)
    ld      D, (IX+3)
    ld      L, (IX+4)
    ld      H, (IX+5)

    ; Call dread syscall.
    ld      A, 3 << 1
    rst     48

    ret

    ; void write_sector(char * buf, unsigned long sector)
    ;
    ; Write 512 bytes from <buf> into the sector indicated by <sector>.
_write_sector:
    ; Get parameters.
    ld      HL, 2
    add     HL, SP

    push    HL
    pop     IX

    ; Sector number, little-endian.
    ; Lowest 16 bytes is at the top of the stack.
    ld      C, (IX+0)
    ld      B, (IX+1)
    ld      E, (IX+2)
    ld      D, (IX+3)
    ld      L, (IX+4)
    ld      H, (IX+5)

    ; Call dwrite syscall.
    ld      A, 2 << 1
    rst     48

    ret
