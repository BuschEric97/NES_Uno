.segment "ZEROPAGE"

.segment "CODE"
draw_sprites:
    jsr wait_for_vblank

    ; draw all sprites to screen
    lda #$02
    sta $4014

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