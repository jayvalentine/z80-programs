    PUBLIC  _main
    EXTERN  _puts
    EXTERN  _putchar

    DEFC    DISKPORT = $18
_main:
_init:
    call    _wait
    ld      A, $04
    out     (DISKPORT+7), A
    call    _wait

    ld      A, $01
    out     (DISKPORT+1), A

    ld      A, $ef
    out     (DISKPORT+7), A

    call    _chkerr

_info:
    ld      A, %10100000
    out     (DISKPORT+6), A

    call    _wait_cmd
    ld      A, $ec
    out     (DISKPORT+7), A

    ld      IX, $9000
    ld      B, 0
_info_read:
    ld      HL, _waiting_dat
    call    _puts

    call    _wait_data
    in      A, (DISKPORT)
    ld      (IX+1), A

    call    _wait_data
    in      A, (DISKPORT)
    ld      (IX), A
    
    inc     IX
    inc     IX
    
    djnz    _info_read

_info_read_done:
    ld      DE, $9000
    ld      B, 0

_info_read_print:
    ld      A, (DE)
    inc     DE

    ld      L, '.'

    cp      $20
    jp      c, _not_printable
    ld      L, A

_not_printable:
    call    _putchar

    ld      A, (DE)
    inc     DE

    ld      L, '.'

    cp      $20
    jp      c, _not_printable_2
    ld      L, A

_not_printable_2:
    call    _putchar

    djnz    _info_read_print

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
