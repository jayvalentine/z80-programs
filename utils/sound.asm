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
program:
    ; Turn off oscillators 1 and 2.
    ; These stay off for the duration of the program.
    ld      A, 0b10111111
    out     (SOUND_PORT), A
    ld      A, 0b11011111
    out     (SOUND_PORT), A

    ; Turn off oscillator 0. This can be changed by user.
    ld      A, 0b10011111
    out     (SOUND_PORT), A

    ; Turn off noise generator. This can be changed by user.
    ld      A, 0b11111111
    out     (SOUND_PORT), A

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

    cp      'r'
    jp      z, noise_rate
    cp      'a'
    jp      z, noise_attenuation


    jp      loop

oscillator_control:
    jp      loop

oscillator_attenuation:
    ; Get attenuation value from user.
    ld      DE, attenuation_message
    call    print

    call    getc
    call    getnybble

    ld      E, A
    ld      A, 0b10010000
    or      E
    out     (SOUND_PORT), A

    ld      DE, done_message
    call    print

    jp      loop

noise_rate:
    ld      DE, rate_message
    call    print

    call    getc
    cp      '1'
    jp      z, set_512
    cp      '2'
    jp      z, set_1024
    cp      '3'
    jp      z, set_2048

    ld      DE, invalid_message
    call    print
    jp      loop

set_512:
    ld      A, 0b11100100
    jp      noise_rate_done

set_1024:
    ld      A, 0b11100101
    jp      noise_rate_done

set_2048
    ld      A, 0b11100110

noise_rate_done:
    out     (SOUND_PORT), A
    jp      loop

noise_attenuation:
    ; Get attenuation value from user.
    ld      DE, attenuation_message
    call    print

    call    getc
    call    getnybble

    ld      E, A
    ld      A, 0b11110000
    or      E
    out     (SOUND_PORT), A

    ld      DE, done_message
    call    print

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

    ; Helper subroutine. Assumes hex character in A register,
    ; returns that character's value in A.
getnybble:
    ; Is it a decimal digit?
    cp      ':'
    jp      nc, _getnybble_isupper

    sub     $30
    ret

_getnybble_isupper:
    ; Is it uppercase char?
    cp      'G'
    jp      nc, _getnybble_islower

    sub     $37
    ret

_getnybble_islower:
    ; Let's assume it's lowercase at this point.
    sub     $57
    ret

select_message_main:
    string  "Select: (o)scillator or (n)oise generator, or (q) to quit? "
select_message_oscillator:
    string  "Select: (c)ontrol or (a)ttenuation? "
select_message_noise:
    string  "Select: (r)ate or (a)attenuation? "

rate_message:
    string  "Select rate: (1): /512 (2): /1024 (3): /2048: "
attenuation_message:
    string  "Enter attenuation value ($0-$f): $"

done_message:
    string  "Done.\r\n\r\n"

invalid_message:
    string "Invalid selection.\r\n\r\n"
