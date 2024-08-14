.segment "CODE"
RESET:
	sei                 ; mask interrupts

	lda #0              ; clear the A register
	sta PPU_CTRL        ; $2000 ; disable NMI
	sta PPU_MASK        ; $2001 ; disable rendering
    sta PPU_SCROLL
    sta PPU_SCROLL

	cld                 ; disable decimal mode
	ldx #$FF
	txs                 ; initialize stack

    ; execute this code during first vblank after reset
    jsr wait_for_vblank                             ; utils.asm

    ; clear out all the ram by setting everything to 0
    clear_ram                                       ; utils.asm

    ; move all the sprites in oam memory offscreen by setting y to #$ff
    jsr clear_sprites                               ; utils.asm

    ; wait for next vblank
    jsr wait_for_vblank                             ; utils.asm

    jsr clear_background_all

    ;======================================================================================
    ; PPU CTRL FLAGS
    ; VPHB SINN
    ; 7654 3210
    ; |||| ||||
    ; |||| |||+----\
    ; |||| |||      |---> Nametable Select  (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
    ; |||| ||+-----/
    ; |||| |+----> Increment Mode (0: increment by 1, across; 1: increment by 32, down)
    ; |||| +-----> Sprite Tile Address Select (0: $0000; 1: $1000)
    ; ||||                              
    ; |||+-------> Background Tile Address Select (0: $0000; 1: $1000)
    ; ||+--------> Sprite Hight (0: 8x8; 1: 8x16)
    ; |+---------> PPU Master / Slave (not sure if this is used)
    ; +----------> NMI enable (0: off; 1: on)
    ;======================================================================================

    ; set the ppu control register to enable nmi and sprite tile rendering

;    set palette_init, #0
;    lda palette_init
;;    cmp #2
;    bne palette_loaded ; bcs palette_loaded
;        jsr load_palettes
;        inc palette_init
;    palette_loaded:
    
    jsr load_palettes

    jsr load_attribute

;    set PPU_CTRL, #%10010000; PPU_CTRL_NMI_ENABLE

    lda PPU_STATUS ; $2002
    set PPU_SCROLL, #0
    sta PPU_SCROLL
    set PPU_CTRL, PPU_CTRL_DEFAULT 

    ;-------------------------------;
    ; initial setup of background   ;
    ;-------------------------------;

    ; disable NMI
    lda #%00000000
    sta $2000
    ; disable sprites and background rendering
    lda #%00000000
    sta $2001

    load_background:
        lda $2002               ; read PPU status to reset the high/low latch
        lda #$20
        sta $2006               ; write the high byte of $2000 address
        lda #$00
        sta $2006               ; write the low byte of $2000 address
    ldx #$00                    ; start out at 0
    load_background_loop_0:
        lda background_data_title, x   ; load data from address (background + the value in x register)
        sta $2007               ; write to PPU
        inx                     ; increment x by 1
        cpx #$00                ; compare x to hex $00 - copying 256 bytes
        bne load_background_loop_0
    load_background_loop_1:     ; loop for 2nd set of background data
        lda background_data_title+256, x
        sta $2007
        inx 
        cpx #$00
        bne load_background_loop_1
    load_background_loop_2:     ; loop for 3rd set of background data
        lda background_data_title+512, x
        sta $2007
        inx 
        cpx #$00
        bne load_background_loop_2
    load_background_loop_3:     ; loop for 4th set of background data
        lda background_data_title+768, x
        sta $2007
        inx 
        cpx #$C0
        bne load_background_loop_3

    load_attributes:
        lda $2002               ; read PPU status to reset the high/low latch
        lda #$23
        sta $2006               ; write the high byte of $23C0 address
        lda #$C0
        sta $2006               ; write the low byte of $23C0 address
    ldx #$00                    ; start out at 0
    load_attributes_loop:
        lda bg_attributes_title, x    ; load data from address (attribute + the value in x register)
        sta $2007               ; write to PPU
        inx                     ; increment x by 1
        cpx #$40                ; compare x to hex $40 - copying 64 bytes
        bne load_attributes_loop

    ; enable NMI, sprites from pattern 0, background from pattern 1
    lda #%10010000
    sta $2000
    ; enable sprites and background rendering
    lda #%00011110
    sta $2001

    ; tell PPU to not do any scrolling at end of NMI
    lda #$00
    sta $2005
    sta $2005

    jmp game_loop   ; start the wait loop