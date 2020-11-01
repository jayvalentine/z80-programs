    PUBLIC  _nonboot

    ; An image for a non-bootable disk.
_nonboot:
    jr      _code
    defs    $003e-$0002
_code:
    ld      DE, $8000+_message-_nonboot
_code_loop:
    ld      A, (DE)
    inc     DE

    ; Done if we hit null.
    cp      0
    jp      z, _code_done

    ; Print character.
    ld      L, A
    ld      A, 0
    rst     48

    ; Loop.
    jr      _code_loop

_code_done:
    ret

_message:
    defm    "This is not a bootable disk.\n\rInsert a bootable disk and try again.\n\r"
    defb    0
