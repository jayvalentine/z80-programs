    PUBLIC  _sleep_ticks

_sleep_ticks:
    push    HL
    push    BC
    push    AF

_outer:
    ld      A, '~'
    out     (1), A
    ld      A, 0
    or      A, L
    jp      z, _done

    ld      B, 0    ; 256 loops is one tick.
_inner:
    ; We want this inner loop to take 257 cycles.
    push    BC      ; 11 cycles
    ld      B, 11   ; 7 cycles

_inner_inner:       ; ~21 cycles
    nop
    nop
    djnz    _inner_inner

    pop     BC ; 10 cycles

    djnz    _inner

    dec     HL
    jp      _outer

_done:
    pop     AF
    pop     BC
    pop     HL
    ret
