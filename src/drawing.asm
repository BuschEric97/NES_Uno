.define DECKXPOS            #$0C
.define DECKYPOS            #$0E

.define DISCARDXPOS         #$10
.define DISCARDYPOS         #$0E

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