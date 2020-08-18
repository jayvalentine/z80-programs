    ; A simple program for controlling an SN76489
    ; programmable sound generator.
    
    ; Helper macro for making a ZBoot syscall.
    macro   zsys, number
    ld      A, \number << 1
    rst     48
    endmacro

    ; ZBoot syscall numbers.
SWRITE  = 0
SREAD   = 1

    ; I/O address of SN76489 sound generator.
SOUND_PORT = 0b01000110
    
    org     $8000
loop:
    ld      DE, select_message_main
    call    print

    call    getc

    cp      'o'
    jp      z, oscillator
    cp      'n'
    jp      z, noise
    cp      'q'
    ret     z

    ld      DE, invalid_message
    call    print
    jp      loop

oscillator:
    ld      DE, select_message_oscillator
    call    print

    call    getc

    cp      'c'
    jp      z, oscillator_control
    cp      'a'
    jp      z, oscillator_attenuation

    ld      DE, invalid_message
    call    print
    jp      loop

noise:
    ld      DE, select_message_noise
    call    print

    call    getc

    jp      loop

oscillator_control:
    jp      loop

oscillator_attenuation:
    jp      loop

getc:
    push    HL

    zsys    SREAD
    ld      H, A

    ld      L, A
    zsys    SWRITE
    ld      L, $0d
    zsys    SWRITE
    ld      L, $0a
    zsys    SWRITE

    ld      A, H
    pop     HL
    ret

print:
    push    HL
_print_loop:
    ld      A, (DE)

    cp      0
    jp      z, _print_done

    inc     DE
    ld      L, A
    zsys    SWRITE
    jp      _print_loop

_print_done:
    pop     HL
    ret

select_message_main:
    string  "Select: (o)scillator or (n)oise generator, or (q) to quit? "
select_message_oscillator:
    string  "Select: (c)ontrol or (a)ttenuation? "
select_message_noise:
    string  "Select: (r)ate or (a)attenuation? "

invalid_message:
    string "Invalid selection.\r\n\r\n"
