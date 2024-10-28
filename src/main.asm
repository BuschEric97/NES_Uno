.segment "IMG"
    .incbin "rom.chr"

.segment "ZEROPAGE"
    GAMEFLAG: .res 1        ; #%000000WG (W == win flag, G == game flag)
    CURCARD: .res 1         ; #%BWVVVVCC (B == back showing indicator, W == wild indicator, VVVV == value (1-indexed), CC == color)
    DECKINDEX: .res 1       ; number between 0-107 inclusive for the index offset of top card of deck, equals #$FF if deck is empty
    DISCARDINDEX: .res 1    ; number between 0-107 inclusive for the index offset of top card of discard pile
    CURSORTILEPOS: .res 2   ; first byte == X pos, second byte == Y pos
    SELCURSTILEPOS: .res 2  ; first byte == X pos, second byte == Y pos
    FRAMECOUNTER: .res 1    ; keep track of if we're on an even or odd frame in order to animate selection cursor

.segment "VARS"
DECK: .res 108
DISCARD: .res 108
PLAYERHAND: .res 50
CPU0HAND: .res 50
CPU1HAND: .res 50
CPU2HAND: .res 50

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

    ; increment frame counter every frame
    lda FRAMECOUNTER
    clc
    adc #1
    sta FRAMECOUNTER

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

        ; initially hide selection cursor
        lda #$FF
        sta SELCURSTILEPOS
        sta SELCURSTILEPOS+1

        jsr clear_background    ; clear title screen from background

        jsr deal_board          ; set initial game state

        lda #0
        sta DECKINDEX
        sta DISCARDINDEX
        
        ; display initial game state
        jsr draw_deck
        jsr draw_discard
        jsr draw_player_hand
    title_start_not_pressed:

    rts 

; this subroutine is called when GAMEFLAG G bit is 1
main_game:
    ; get cursor movement from DPAD input
    lda gamepad_new_press
    and PRESS_UP
    cmp PRESS_UP
    bne up_not_pressed
        lda CURSORTILEPOS+1
        sec 
        sbc #2
        sta CURSORTILEPOS+1
    up_not_pressed:
    lda gamepad_new_press
    and PRESS_RIGHT
    cmp PRESS_RIGHT
    bne right_not_pressed
        lda CURSORTILEPOS
        clc 
        adc #2
        sta CURSORTILEPOS
    right_not_pressed:
    lda gamepad_new_press
    and PRESS_DOWN
    cmp PRESS_DOWN
    bne down_not_pressed
        lda CURSORTILEPOS+1
        clc 
        adc #2
        sta CURSORTILEPOS+1
    down_not_pressed:
    lda gamepad_new_press
    and PRESS_LEFT
    cmp PRESS_LEFT
    bne left_not_pressed
        lda CURSORTILEPOS
        sec 
        sbc #2
        sta CURSORTILEPOS
    left_not_pressed:

    jsr draw_cursor
    jsr draw_sel_cursor

    lda gamepad_new_press
    and PRESS_A
    cmp PRESS_A
    bne a_not_pressed
        ; spawn or despawn selection cursor at current cursor position
        lda SELCURSTILEPOS+1
        cmp #$FF
        beq spawn_sel_cursor
        despawn_sel_cursor:
            lda #$FF
            sta SELCURSTILEPOS
            sta SELCURSTILEPOS+1
            jmp done_handle_sel_cursor
        spawn_sel_cursor:
            lda CURSORTILEPOS
            sta SELCURSTILEPOS
            lda CURSORTILEPOS+1
            sta SELCURSTILEPOS+1
        done_handle_sel_cursor:
    a_not_pressed:

    rts 