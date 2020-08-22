    PUBLIC  _sleep_ticks
    EXTERN  _half_ms_per_tick

_sleep_ticks:
    push    HL
    push    BC
    push    AF

_sleep_ticks_loop:
    ld      A, L
    cp      0
    jp      z, _done

    ld      A, (_half_ms_per_tick)
    cp      0
    jp      z, _done

    ld      B, A

_sleep_ticks_inner:
    call    _sleep_half_ms
    djnz    _sleep_ticks_inner

    dec     L
    jp      _sleep_ticks_loop

_done:
    pop     AF
    pop     BC
    pop     HL
    ret

    ; Loop that takes exactly half a millisecond.
_sleep_half_ms:
    push    BC
    ld      B, 64
_sleep_ms_inner:
    nop
    nop
    nop
    nop
    djnz    _sleep_ms_inner
_sleep_ms_done:
    pop     BC
    ret
