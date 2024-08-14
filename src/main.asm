.segment "IMG"
    .incbin "rom.chr"

.segment "ZEROPAGE"
    GAMEFLAG: .res 1        ; #%000000WG (W == win flag, G == game flag)

.segment "VARS"

.include "header.asm"
.include "utils.asm"
.include "gamepad.asm"
.include "ppu.asm"
.include "palette.asm"

.include "drawing.asm"
.include "gamelogic.asm"

.include "title.asm"
.include "nmi.asm"
.include "irq.asm"
.include "reset.asm"

.segment "CODE"
game_loop:
    lda nmi_ready
    bne game_loop

    ; get gamepad inputs
    jsr set_gamepads

    lda GAMEFLAG
    and #%00000001
    bne run_main_game
        ;run_title_screen:
        jsr title_screen_game
        jmp game_loop
    run_main_game:
        jsr main_game

    ; return to start of game loop
    jmp game_loop

; this subroutine is called when GAMEFLAG G bit is 0
title_screen_game:
    ; handle START button press on controller port 0
    lda gamepad_new_press
    and PRESS_START
    cmp PRESS_START
    bne title_start_not_pressed
        lda #%00000001
        sta GAMEFLAG    ; set GAMEFLAG to 1 to indicate a game is being played

        jsr clear_background
    title_start_not_pressed:

    rts 

; this subroutine is called when GAMEFLAG G bit is 1
main_game:
    rts 