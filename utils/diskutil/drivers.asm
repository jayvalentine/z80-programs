    ; Compact-Flash IDE drivers.

    ; Definitions and externs.

    ; stdio.h
    EXTERN  _puts

    ; IO port for CF-card.
    DEFC    DISKPORT = $18

    ; Exported functions.
    PUBLIC  _read_sector
    PUBLIC  _init_disk

    ; **************************
    ; HIGH-LEVEL ROUTINES
    ;
    ; These subroutines are the high-level
    ; driver routines that a program
    ; uses to read/write the CF-card.
    ; **************************

    ; void init_disk(void)
    ;
    ; Initialises CF-card.
_init_disk:
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

    ; Sector number, little-endian.
    ; Lowest 16 bytes is at the top of the stack.
    ld      C, (HL)
    inc     HL
    ld      B, (HL)
    inc     HL
    ld      E, (HL)
    inc     HL
    ld      D, (HL)
    inc     HL

    ; Sector number now in DEBC, so we just need
    ; to call the set_lba subroutine.
    call    _wait_cmd
    call    _set_lba

    ; Transfer one sector
    ld      A, $01
    out     (DISKPORT+2), A

    ; Read sector command.
    ld      A, $20
    out     (DISKPORT+7), A

    ; Get pointer param (buf) into HL.
    ld      E, (HL)
    inc     HL
    ld      D, (HL)
    ld      L, E
    ld      H, D

    ; Read 512 bytes from CF-card.
    call    _read_data

    ret

    ; **************************
    ; DATA TRANSFER ROUTINES
    ;
    ; These subroutines transfer blocks to or from
    ; the CF-card.
    ; **************************

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

    ; **************************
    ; UTILITY ROUTINES
    ;
    ; Shorthands for functionality of the CF-card.
    ; **************************

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

    ; **************************
    ; WAIT ROUTINES
    ;
    ; These subroutines implement waits for various
    ; conditions of the CF-card.
    ; **************************
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

    ; **************************
    ; ERROR CHECKING ROUTINES
    ;
    ; These subroutines check for and report
    ; errors from the CF-card.
    ; **************************
_chkerr:
    in      A, (DISKPORT+7)
    bit     0, A
    jp      z, _chkerr_noerr

    ld      HL, _error
    call    _puts

_chkerr_noerr:
    ret

    ; **************************
    ; DATA
    ; **************************
_error:
    defm    "Error in CF-card!\n\r"
    defb    0

