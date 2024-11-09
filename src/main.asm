.segment "IMG"
    .incbin "rom.chr"

.segment "ZEROPAGE"
    GAMEFLAG: .res 1        ; #%00000OWG (W == win flag, G == game flag, O == turn order (0 == clockwise, 1 == counter-clockwise))
    CURCARD: .res 1         ; #%BWVVVVCC (B == back showing indicator, W == wild indicator, VVVV == value (1-indexed), CC == color)
    DECKINDEX: .res 1       ; number between 0-107 inclusive for the index offset of top card of deck, equals #$FF if deck is empty
    DISCARDINDEX: .res 1    ; number between 0-107 inclusive for the index offset of top card of discard pile
    CURSORSPOS: .res 1      ; #%XXXXYYYY (XXXX == relative X pos of base cursor, YYYY == relative Y pos of base cursor), default value == #%00000010
    CURSORTILEPOS: .res 2   ; first byte == X pos, second byte == Y pos
    SELCURSTILEPOS: .res 2  ; first byte == X pos, second byte == Y pos
    FRAMECOUNTER: .res 1    ; keep track of if we're on an even or odd frame in order to animate selection cursor

.segment "VARS"
DECK: .res 108
DISCARD: .res 108
PLAYERHAND: .res 50
CPU0HAND: .res 50
CPU0COUNT: .res 2
CPU1HAND: .res 50
CPU1COUNT: .res 2
CPU2HAND: .res 50
CPU2COUNT: .res 2

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
        jsr draw_turn_order
        jsr draw_discard
        jsr draw_player_hand
        jsr draw_cpu_hands
        jsr draw_cpu0_count
        jsr draw_cpu1_count
        jsr draw_cpu2_count

        ; initialize CURSORSPOS with default value
        lda #%00000010
        sta CURSORSPOS
    title_start_not_pressed:

    rts 

; this subroutine is called when GAMEFLAG G bit is 1
main_game:
    ; get cursor movement from DPAD input
    lda gamepad_new_press
    and PRESS_UP
    cmp PRESS_UP
    bne up_not_pressed
        lda CURSORSPOS
        and #%00000011
        beq up_not_pressed
            lda CURSORSPOS
            sec 
            sbc #%00000001
            sta CURSORSPOS
    up_not_pressed:
    lda gamepad_new_press
    and PRESS_RIGHT
    cmp PRESS_RIGHT
    bne right_not_pressed
        lda CURSORSPOS
        and #%11110000
        lsr
        lsr
        lsr
        lsr
        cmp PLAYERHANDVISLIMIT
        beq right_not_pressed
            lda CURSORSPOS
            clc 
            adc #%00010000
            sta CURSORSPOS
    right_not_pressed:
    lda gamepad_new_press
    and PRESS_DOWN
    cmp PRESS_DOWN
    bne down_not_pressed
        lda CURSORSPOS
        and #%00000011
        cmp #%00000010
        beq down_not_pressed
            lda CURSORSPOS
            clc 
            adc #%00000001
            sta CURSORSPOS
    down_not_pressed:
    lda gamepad_new_press
    and PRESS_LEFT
    cmp PRESS_LEFT
    bne left_not_pressed
        lda CURSORSPOS
        and #%11110000
        beq left_not_pressed
            lda CURSORSPOS
            sec 
            sbc #%00010000
            sta CURSORSPOS
    left_not_pressed:

    jsr translate_cursors_pos

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

    lda gamepad_new_press
    and PRESS_B
    cmp PRESS_B
    bne b_not_pressed
        lda GAMEFLAG
        eor #%00000100
        sta GAMEFLAG

        jsr draw_turn_order
    b_not_pressed:

    rts 