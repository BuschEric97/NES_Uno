.define DECKXPOS            #$0C
.define DECKYPOS            #$0E

.define DISCARDXPOS         #$10
.define DISCARDYPOS         #$0E

.define CPU0XPOS            #$02
.define CPU0YPOS            #$0E

.define CPU1XPOS            #$0E
.define CPU1YPOS            #$02

.define CPU2XPOS            #$1C
.define CPU2YPOS            #$0E

.define PLAYERHANDLEFTXPOS  #$04
.define PLAYERHANDYPOS      #$18
.define PLAYERHANDVISLIMIT  #12

.segment "ZEROPAGE"
    BGCARDID: .res 1
    BGCARDPOS: .res 2       ; first byte == X pos, second byte == Y pos
    BGCARDBYTES: .res 2
    BGCARDATTLBYTE: .res 1
    BGCARDATTRIBUTE: .res 1
    BGCARDATTTEMP: .res 1
    CURSORTRANS: .res 1     ; helper byte for translate_cursors_pos subroutine

.segment "CODE"
draw_sprites:
    jsr wait_for_vblank

    ; draw all sprites to screen
    lda #$02
    sta $4014

    rts 

draw_cursor:
    lda CURSORTILEPOS+1
    asl 
    asl 
    asl 
    sta $0200               ; cursor Y pos

    lda #$00
    sta $0201               ; cursor tile number

    lda #%00000000
    sta $0202               ; cursor attributes

    lda CURSORTILEPOS
    asl 
    asl 
    asl 
    sta $0203               ; cursor X pos

    jsr draw_sprites

    rts 

draw_sel_cursor:
    lda FRAMECOUNTER
    and #%00001000
    bne sel_cursor_odd_frame
    sel_cursor_even_frame:
        lda #$FF
        sta $0204
        sta $0207

        lda #$00
        sta $0205

        lda #%00000000
        sta $0206

        jmp done_drawing_sel_cursor
    
    sel_cursor_odd_frame:
        lda SELCURSTILEPOS+1
        asl
        asl
        asl
        sta $0204

        lda #$00
        sta $0205

        lda #%00000000
        sta $0206

        lda SELCURSTILEPOS
        asl
        asl
        asl
        sta $0207

    done_drawing_sel_cursor:
    rts

draw_player_hand:
    ldx #0
    ldy #0
    player_hand_loop:
        cpy PLAYERHANDVISLIMIT
        beq player_hand_loop_end    ; break out of loop if we hit visible hand limit
        lda PLAYERHAND, x 
        beq player_hand_loop_end    ; break out of loop once we hit an empty card slot
        sta BGCARDID

        txa 
        asl 
        clc 
        adc PLAYERHANDLEFTXPOS
        sta BGCARDPOS
        lda PLAYERHANDYPOS
        sta BGCARDPOS+1

        txa 
        pha 
        tya 
        pha 
        jsr draw_bg_card
        pla 
        tay 
        pla 
        tax 

        inx 
        iny 
        jmp player_hand_loop
    player_hand_loop_end:

    rts 

draw_cpu_hands:
    ; CPU0
    lda #%10000000
    sta BGCARDID
    lda CPU0XPOS
    sta BGCARDPOS
    lda CPU0YPOS
    sta BGCARDPOS+1
    jsr draw_bg_card

    ; CPU1
    lda #%10000000
    sta BGCARDID
    lda CPU1XPOS
    sta BGCARDPOS
    lda CPU1YPOS
    sta BGCARDPOS+1
    jsr draw_bg_card

    ; CPU2
    lda #%10000000
    sta BGCARDID
    lda CPU2XPOS
    sta BGCARDPOS
    lda CPU2YPOS
    sta BGCARDPOS+1
    jsr draw_bg_card

    rts

draw_cpu0_count:
    jsr wait_for_vblank

    ; disable sprites and background rendering
    lda #%00000000
    sta $2001

    lda $2002
    lda #$22
    sta $2006
    lda #$01
    sta $2006

    lda #$2E
    sta $2007
    lda CPU0COUNT+1
    clc
    adc #$20
    sta $2007
    lda CPU0COUNT
    clc
    adc #$20
    sta $2007

    ; enable sprites and background rendering
    lda #%00011110
    sta $2001

    ; reset scrolling
    lda #$00
    sta $2005
    sta $2005

    rts

draw_cpu1_count:
    jsr wait_for_vblank

    ; disable sprites and background rendering
    lda #%00000000
    sta $2001

    lda $2002
    lda #$20
    sta $2006
    lda #$8D
    sta $2006

    lda #$2E
    sta $2007
    lda CPU1COUNT+1
    clc
    adc #$20
    sta $2007
    lda CPU1COUNT
    clc
    adc #$20
    sta $2007

    ; enable sprites and background rendering
    lda #%00011110
    sta $2001

    ; reset scrolling
    lda #$00
    sta $2005
    sta $2005

    rts

draw_cpu2_count:
    jsr wait_for_vblank

    ; disable sprites and background rendering
    lda #%00000000
    sta $2001

    lda $2002
    lda #$22
    sta $2006
    lda #$1B
    sta $2006

    lda #$2E
    sta $2007
    lda CPU2COUNT+1
    clc
    adc #$20
    sta $2007
    lda CPU2COUNT
    clc
    adc #$20
    sta $2007

    ; enable sprites and background rendering
    lda #%00011110
    sta $2001

    ; reset scrolling
    lda #$00
    sta $2005
    sta $2005

    rts

draw_discard:
    ldx DISCARDINDEX
    lda DISCARD, x
    beq done_drawing_discard
        sta BGCARDID

        lda DISCARDXPOS
        sta BGCARDPOS
        lda DISCARDYPOS
        sta BGCARDPOS+1

        jsr draw_bg_card

    done_drawing_discard:
    rts 

draw_deck:
    ldx DECKINDEX
    lda DECK, x
    beq done_drawing_deck
        sta BGCARDID

        lda DECKXPOS
        sta BGCARDPOS
        lda DECKYPOS
        sta BGCARDPOS+1

    jsr draw_bg_card

    done_drawing_deck:
    rts 

draw_bg_card:
    jsr wait_for_vblank

    ; disable sprites and background rendering
    lda #%00000000
    sta $2001

    ; set bg attributes for card color

    ; get needed attribute byte
    lda BGCARDPOS+1
    asl                 ; Y_POS * 2
    and #%11111000      ; round down to nearest 8
    sta BGCARDATTLBYTE  ; store result temporarily
    lda BGCARDPOS
    lsr 
    lsr                 ; X_POS / 4
    clc 
    adc BGCARDATTLBYTE  ; ADD to stored result
    sta BGCARDATTLBYTE  ; store final result

    ; determine which half-nybble to modify
    lda BGCARDPOS+1
    and #%00000010
    tax 
    lda BGCARDPOS
    lsr 
    lsr                 ; carry has what we need to add now
    txa 
    adc #0
    tax                 ; X now has the number of times we need to shift left twice
    tay                 ; copy A to Y as well

    ; modify the corresponding bg attribute
    lda BGCARDID
    and #%10000000
    beq bg_card_att_card_not_back
        ; the color of the card should always be red when drawing the card back
        lda #0
        jmp bg_card_att_left_shift_loop_0_done
    bg_card_att_card_not_back:
    lda BGCARDID
    and #%00000011
    bg_card_att_left_shift_loop_0:
        cpx #0
        beq bg_card_att_left_shift_loop_0_done
        dex 
        asl 
        asl 
        jmp bg_card_att_left_shift_loop_0
    bg_card_att_left_shift_loop_0_done:
    sta BGCARDATTRIBUTE

    lda $2002
    lda #$23
    sta $2006
    lda #$C0
    clc 
    adc BGCARDATTLBYTE
    sta $2006
    lda $2007           ; first read is invalid
    lda $2007           ; load current attributes

    sta BGCARDATTTEMP
    lda #%00000011
    bg_card_att_left_shift_loop_1:
        cpy #0
        beq bg_card_att_left_shift_loop_1_done
        dey 
        asl 
        asl 
        jmp bg_card_att_left_shift_loop_1
    bg_card_att_left_shift_loop_1_done:
    eor #%11111111      ; invert the mask
    and BGCARDATTTEMP
    clc 
    adc BGCARDATTRIBUTE
    sta BGCARDATTRIBUTE

    lda $2002
    lda #$23
    sta $2006
    lda #$C0
    clc 
    adc BGCARDATTLBYTE
    sta $2006
    lda BGCARDATTRIBUTE
    sta $2007           ; store attributes

    ; get the high and low byte of the card position
    ; BGCARDBYTES == BGCARDPOS + (BGCARDPOS+1 * 32)

    ; BGCARDPOS+1 * 32
    lda #0
    ldx #8
    bg_card_mult_loop:
        lsr BGCARDPOS+1
        bcc bg_card_mult_no_add
        clc 
        adc #32
    bg_card_mult_no_add:
        ror A
        ror BGCARDBYTES
        dex 
        bne bg_card_mult_loop
    sta BGCARDBYTES+1
    
    ; result + BGCARDPOS
    lda BGCARDBYTES
    clc 
    adc BGCARDPOS
    sta BGCARDBYTES
    lda BGCARDBYTES+1
    adc #0
    sta BGCARDBYTES+1

    ; and #$20 to high byte
    lda BGCARDBYTES+1
    clc 
    adc #$20
    sta BGCARDBYTES+1

    ; draw card

    ; draw top of card
    lda $2002
    lda BGCARDBYTES+1
    sta $2006
    lda BGCARDBYTES
    sta $2006

    lda BGCARDID
    and #%10000000
    bne top_back
        lda BGCARDID
        and #%01000000
        bne top_wild_card
            ;top_color_card:
            lda BGCARDID
            and #%00111100
            lsr 
            lsr 
            clc 
            adc #$2F
            sta $2007
            lda #$41
            sta $2007
            jmp top_done
        top_wild_card:
            lda BGCARDID
            and #%00000100
            lsr 
            lsr 
            clc 
            adc #$3D
            sta $2007
            lda #$3F
            sta $2007
        top_done:
        jmp top_back_done
    top_back:
        lda #$42
        sta $2007
        lda #$43
        sta $2007
    top_back_done:

    ; draw bottom of card
    lda BGCARDBYTES
    clc 
    adc #$20
    sta BGCARDBYTES
    lda BGCARDBYTES+1
    adc #0
    sta BGCARDBYTES+1

    lda $2002
    lda BGCARDBYTES+1
    sta $2006
    lda BGCARDBYTES
    sta $2006

    lda BGCARDID
    and #%10000000
    bne bottom_back
        lda BGCARDID
        and #%01000000
        bne bottom_wild_card
            ;bottom_color_card:
            lda #$50
            sta $2007
            lda #$51
            sta $2007
            jmp bottom_done
        bottom_wild_card:
            lda #$3F
            sta $2007
            sta $2007
        bottom_done:
        jmp bottom_back_done
    bottom_back:
        lda #$52
        sta $2007
        lda #$53
        sta $2007
    bottom_back_done:

    done_drawing_bg_card:
    ; enable sprites and background rendering
    lda #%00011110
    sta $2001

    ; reset scrolling
    lda #$00
    sta $2005
    sta $2005

    rts 

clear_background:
    jsr wait_for_vblank

    ; disable sprites and background rendering
    lda #%00000000
    sta $2001

    lda $2002               ; read PPU status to reset the high/low latch
    lda #$20
    sta $2006               ; write the high byte of $2000 address
    lda #$00
    sta $2006               ; write the low byte of $2000 address
    ldx #$00                ; start out at 0
    load_background_clear_loop_0:
        lda #$FF
        sta $2007               ; write to PPU
        inx                     ; increment x by 1
        cpx #$00                ; compare x to hex $00 - copying 256 bytes
        bne load_background_clear_loop_0
    load_background_clear_loop_1:     ; loop for 2nd set of background data
        lda #$FF
        sta $2007
        inx 
        cpx #$00
        bne load_background_clear_loop_1
    load_background_clear_loop_2:     ; loop for 3rd set of background data
        lda #$FF
        sta $2007
        inx 
        cpx #$00
        bne load_background_clear_loop_2
    load_background_clear_loop_3:     ; loop for 4th set of background data
        lda #$FF
        sta $2007
        inx 
        cpx #$C0
        bne load_background_clear_loop_3

    ; enable sprites and background rendering
    lda #%00011110
    sta $2001

    ; reset scrolling
    lda #$00
    sta $2005
    sta $2005

    rts 

draw_turn_order:
    jsr wait_for_vblank

    ; disable sprites and background rendering
    lda #%00000000
    sta $2001

    lda $2002
    lda #$21
    sta $2006
    lda #$CE
    sta $2006

    lda GAMEFLAG
    and #%00000100
    bne draw_turn_order_counter
    draw_turn_order_clockwise:
        lda #$44
        sta $2007
        lda #$45
        sta $2007

        lda $2002
        lda #$21
        sta $2006
        lda #$EE
        sta $2006

        lda #$54
        sta $2007
        lda #$55
        sta $2007

        jmp done_drawing_turn_order
    draw_turn_order_counter:
        lda #$46
        sta $2007
        lda #$47
        sta $2007

        lda $2002
        lda #$21
        sta $2006
        lda #$EE
        sta $2006

        lda #$56
        sta $2007
        lda #$57
        sta $2007
    
    done_drawing_turn_order:

    ; enable sprites and background rendering
    lda #%00011110
    sta $2001

    ; reset scrolling
    lda #$00
    sta $2005
    sta $2005

    rts

translate_cursors_pos:
    ; uses CURSORSPOS (#%XXXXYYYY)
    ; for YYYY == 0000; always map to [CPU1 hand location]
    ; for YYYY == 0001; XXXX == xx00 maps to [CPU0 hand location], XXXX == xx01 maps to [deck location], XXXX == xx10 maps to [discard location], XXXX == xx11 maps to [CPU2 hand location]
    ; for YYYY == 0010; XXXX corresponds to offset from leftmost card in player hand where XXXX == 0000 maps to [player hand location]
    lda CURSORSPOS
    and #%00000011
    beq cursor_pos_y_0
        sec
        sbc #1
    beq cursor_pos_y_1
        sec
        sbc #1
    beq cursor_pos_y_2
        jmp done_translating_cursors_pos    ; return from subroutine if YYYY is out of bounds
    cursor_pos_y_0:
        lda CPU1XPOS
        clc 
        adc #1
        sta CURSORTILEPOS
        
        lda CPU1YPOS
        clc
        adc #1
        sta CURSORTILEPOS+1

        jmp done_translating_cursors_pos
    cursor_pos_y_1:
        lda CURSORSPOS
        and #%11110000
        lsr
        lsr
        lsr
        lsr
        beq cursor_pos_cpu0
            sec
            sbc #1
        beq cursor_pos_deck
            sec
            sbc #1
        beq cursor_pos_discard
            sec
            sbc #1
        beq cursor_pos_cpu2
            ; fix XXXX if greater than 3 here then jump to cursor_pos_cpu2
            lda CURSORSPOS
            and #%00001111
            clc
            adc #%00110000
            sta CURSORSPOS
            jmp cursor_pos_cpu2
        cursor_pos_cpu0:
            lda CPU0XPOS
            clc 
            adc #1
            sta CURSORTILEPOS
            
            lda CPU0YPOS
            clc
            adc #1
            sta CURSORTILEPOS+1

            jmp done_translating_cursors_pos
        cursor_pos_deck:
            lda DECKXPOS
            clc 
            adc #1
            sta CURSORTILEPOS
            
            lda DECKYPOS
            clc
            adc #1
            sta CURSORTILEPOS+1

            jmp done_translating_cursors_pos
        cursor_pos_discard:
            lda DISCARDXPOS
            clc 
            adc #1
            sta CURSORTILEPOS
            
            lda DISCARDYPOS
            clc
            adc #1
            sta CURSORTILEPOS+1

            jmp done_translating_cursors_pos
        cursor_pos_cpu2:
            lda CPU2XPOS
            clc 
            adc #1
            sta CURSORTILEPOS
            
            lda CPU2YPOS
            clc
            adc #1
            sta CURSORTILEPOS+1

            jmp done_translating_cursors_pos
    cursor_pos_y_2:
        lda CURSORSPOS
        and #%11110000
        lsr
        lsr
        lsr
        sec ; replaces adc #1
        adc PLAYERHANDLEFTXPOS
        sta CURSORTILEPOS
        
        lda PLAYERHANDYPOS
        clc
        adc #1
        sta CURSORTILEPOS+1

    done_translating_cursors_pos:
    rts