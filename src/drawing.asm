.segment "ZEROPAGE"
    BGCARDID: .res 1
    BGCARDPOS: .res 2       ; first byte == X pos, second byte == Y pos
    BGCARDBYTES: .res 2

.segment "CODE"
draw_sprites:
    jsr wait_for_vblank

    ; draw all sprites to screen
    lda #$02
    sta $4014

    rts 

draw_bg_card:
    jsr wait_for_vblank

    ; disable sprites and background rendering
    lda #%00000000
    sta $2001

    ; get card position
    lda #8
    sta BGCARDPOS
    sta BGCARDPOS+1

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
    
    ; result + BGCARDTILEX
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