    ; CRT0 for modularz80 platform.
    ; For running code in user-memory.
    EXTERN  _main

start:
    call    _main
    ret
