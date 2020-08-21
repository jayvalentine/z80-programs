    ; Implementation of stdio portion of standard library.

    ; Syscall macro.
define(zsys, `ld      A, $1 << 1
    rst     48')

    defc    SWRITE = 0
    defc    SREAD  = 1

_puts:
    push    AF
    push    DE

    push    HL
    pop     DE

__puts_loop:
    ; src in DE.
    ld      A, (DE)
    inc     DE
    cp      0
    jp      z, __puts_done

    ; Not null, print to serial port.
    ld      L, A
    zsys(SWRITE)

    ; Loop.
    jp      __puts_loop

__puts_done:
    pop     DE
    pop     AF

    ; Successful, return 0.
    ld      HL, 0
    ret
