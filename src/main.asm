.segment "IMG"
    .incbin "rom.chr"

.segment "ZEROPAGE"
    GAMEFLAG: .res 1        ; #%000000WG (W == win flag, G == game flag)
    CURCARD: .res 1         ; #%BWVVVVCC (B == back showing indicator, W == wild indicator, VVVV == value (1-indexed), CC == color)

.segment "VARS"

.include "header.asm"
.include "utils.asm"
.include "gamepad.asm"
.include "ppu.asm"
.include "palette.asm"

.include "random.asm"
.include "drawing.asm"
.include "gamelogic.asm"

.include "title.asm"
.include "nmi.asm"
.include "irq.asm"
.include "reset.asm"

.segment "CODE"
DECK: .byte 108
PLAYERHAND: .byte 50
CPU1HAND: .byte 50
CPU2HAND: .byte 50
CPU3HAND: .byte 50

game_loop:
    lda nmi_ready
    bne game_loop

    ; get gamepad inputs
    jsr set_gamepads

    ; increment seed to enhance pseudo-randomness
    lda seed+1
    clc 
    adc #1
    sta seed+1
    lda seed
    adc #0
    sta seed

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

        jsr generate_deck
        ; shuffle deck twice for better randomness at start of game
        jsr shuffle_deck
        jsr shuffle_deck

        jsr clear_background
    title_start_not_pressed:

    rts 

; this subroutine is called when GAMEFLAG G bit is 1
main_game:
    lda gamepad_new_press
    and PRESS_A
    cmp PRESS_A
    bne a_not_pressed
        lda #%00110001
        sta BGCARDID
        lda #8
        sta BGCARDPOS
        sta BGCARDPOS+1
        jsr draw_bg_card
    a_not_pressed:

    rts 