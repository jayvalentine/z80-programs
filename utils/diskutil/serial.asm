    ; Some high-performance code for reading files from the serial line.
    
    PUBLIC  _read512

    ; void read512(char * buf) __z88dk_fastcall
_read512:
    ; Destination in HL.
    ld      BC, 512

__read512_loop:
    ld      A, 2
    rst     48
    ld      (HL), A
    inc     HL

    dec     BC
    jp      nz, __read512_loop

__read512_done:
    ret
