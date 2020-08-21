    ; Implementation of stdio portion of standard library.

    PUBLIC  _puts
    PUBLIC  _putchar
    PUBLIC  _getchar

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

_putchar:
    push    AF

    ; Character to send is in HL.
    ; Because it's a character, we can ignore H.
    zsys(SWRITE)
    
    pop     AF
    ret

_getchar:
    push    AF
    zsys(SREAD)
    ld      H, 0
    ld      L, A
    pop     AF
    ret
