.segment "ZEROPAGE"
    DECKSWAP: .res 3

.segment "CODE"
generate_deck:
    ; red cards
    lda #%10000100  ; 0
    sta DECK
    lda #%10001000  ; 1
    sta DECK+1
    sta DECK+2
    lda #%10001100  ; 2
    sta DECK+3
    sta DECK+4
    lda #%10010000  ; 3
    sta DECK+5
    sta DECK+6
    lda #%10010100  ; 4
    sta DECK+7
    sta DECK+8
    lda #%10011000  ; 5
    sta DECK+9
    sta DECK+10
    lda #%10011100  ; 6
    sta DECK+11
    sta DECK+12
    lda #%10100000  ; 7
    sta DECK+13
    sta DECK+14
    lda #%10100100  ; 8
    sta DECK+15
    sta DECK+16
    lda #%10101000  ; 9
    sta DECK+17
    sta DECK+18
    lda #%10101100  ; skip
    sta DECK+19
    sta DECK+20
    lda #%10110000  ; reverse
    sta DECK+21
    sta DECK+22
    lda #%10110100  ; draw 2
    sta DECK+23
    sta DECK+24

    ; blue cards
    lda #%10000101  ; 0
    sta DECK+25
    lda #%10001001  ; 1
    sta DECK+26
    sta DECK+27
    lda #%10001101  ; 2
    sta DECK+28
    sta DECK+29
    lda #%10010001  ; 3
    sta DECK+30
    sta DECK+31
    lda #%10010101  ; 4
    sta DECK+32
    sta DECK+33
    lda #%10011001  ; 5
    sta DECK+34
    sta DECK+35
    lda #%10011101  ; 6
    sta DECK+36
    sta DECK+37
    lda #%10100001  ; 7
    sta DECK+38
    sta DECK+39
    lda #%10100101  ; 8
    sta DECK+40
    sta DECK+41
    lda #%10101001  ; 9
    sta DECK+42
    sta DECK+43
    lda #%10101101  ; skip
    sta DECK+44
    sta DECK+45
    lda #%10110001  ; reverse
    sta DECK+46
    sta DECK+47
    lda #%10110101  ; draw 2
    sta DECK+48
    sta DECK+49

    ; yellow cards
    lda #%10000110  ; 0
    sta DECK+50
    lda #%10001010  ; 1
    sta DECK+51
    sta DECK+52
    lda #%10001110  ; 2
    sta DECK+53
    sta DECK+54
    lda #%10010010  ; 3
    sta DECK+55
    sta DECK+56
    lda #%10010110  ; 4
    sta DECK+57
    sta DECK+58
    lda #%10011010  ; 5
    sta DECK+59
    sta DECK+60
    lda #%10011110  ; 6
    sta DECK+61
    sta DECK+62
    lda #%10100010  ; 7
    sta DECK+63
    sta DECK+64
    lda #%10100110  ; 8
    sta DECK+65
    sta DECK+66
    lda #%10101010  ; 9
    sta DECK+67
    sta DECK+68
    lda #%10101110  ; skip
    sta DECK+69
    sta DECK+70
    lda #%10110010  ; reverse
    sta DECK+71
    sta DECK+72
    lda #%10110110  ; draw 2
    sta DECK+73
    sta DECK+74

    ; green cards
    lda #%10000111  ; 0
    sta DECK+75
    lda #%10001011  ; 1
    sta DECK+76
    sta DECK+77
    lda #%10001111  ; 2
    sta DECK+78
    sta DECK+79
    lda #%10010011  ; 3
    sta DECK+80
    sta DECK+81
    lda #%10010111  ; 4
    sta DECK+82
    sta DECK+83
    lda #%10011011  ; 5
    sta DECK+84
    sta DECK+85
    lda #%10011111  ; 6
    sta DECK+86
    sta DECK+87
    lda #%10100011  ; 7
    sta DECK+88
    sta DECK+89
    lda #%10100111  ; 8
    sta DECK+90
    sta DECK+91
    lda #%10101011  ; 9
    sta DECK+92
    sta DECK+93
    lda #%10101111  ; skip
    sta DECK+94
    sta DECK+95
    lda #%10110011  ; reverse
    sta DECK+96
    sta DECK+97
    lda #%10110111  ; draw 2
    sta DECK+98
    sta DECK+99

    ; wild cards
    lda #%11000000  ; wild draw 4
    sta DECK+100
    sta DECK+101
    sta DECK+102
    sta DECK+103
    lda #%11000100  ; wild
    sta DECK+104
    sta DECK+105
    sta DECK+106
    sta DECK+107

    rts 

swap_2_deck_cards:
    ; swap 2 cards in the deck for shuffling
    ldx DECKSWAP
    lda DECK, x 
    sta DECKSWAP+2

    ldx DECKSWAP+1
    lda DECK, x 
    ldx DECKSWAP
    sta DECK, x 

    ldx DECKSWAP+1
    lda DECKSWAP+2
    sta DECK, x 

    rts 

shuffle_deck:
    ldx #0
    deck_shuffle_loop:
        txa 
        pha 

        ; get random number modulus 108 and store in DECKSWAP
        jsr prng 
        sec 
        deck_shuffle_mod_0:
            sbc #108
            bcs deck_shuffle_mod_0
        adc #108
        sta DECKSWAP

        ; get random number modulus 108 and store in DECKSWAP+1
        jsr prng 
        sec 
        deck_shuffle_mod_1:
            sbc #108
            bcs deck_shuffle_mod_1
        adc #108
        sta DECKSWAP+1

        jsr swap_2_deck_cards

        pla 
        tax 
        inx 
        cpx #$FF
        bne deck_shuffle_loop

    rts 

deal_board:
    ; generate an initial ordered deck
    jsr generate_deck

    ; shuffle deck twice for better randomness at start of game
    jsr shuffle_deck
    jsr shuffle_deck

    ; set initial top deck index
    lda #107
    sta DECKINDEX

    ; set initial top discard index
    lda #0
    sta DISCARDINDEX

    ; deal cards to each player
    ; player
    ldx DECKINDEX
    lda DECK, x 
    sta PLAYERHAND
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta PLAYERHAND+1
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta PLAYERHAND+2
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta PLAYERHAND+3
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta PLAYERHAND+4
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta PLAYERHAND+5
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta PLAYERHAND+6
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX
    
    ; cpu0
    ldx DECKINDEX
    lda DECK, x 
    sta CPU0HAND
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU0HAND+1
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU0HAND+2
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU0HAND+3
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU0HAND+4
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU0HAND+5
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU0HAND+6
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ; cpu1
    ldx DECKINDEX
    lda DECK, x 
    sta CPU1HAND
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU1HAND+1
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU1HAND+2
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU1HAND+3
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU1HAND+4
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU1HAND+5
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU1HAND+6
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ; cpu2
    ldx DECKINDEX
    lda DECK, x 
    sta CPU2HAND
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU2HAND+1
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU2HAND+2
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU2HAND+3
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU2HAND+4
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU2HAND+5
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    ldx DECKINDEX
    lda DECK, x 
    sta CPU2HAND+6
    lda #0
    sta DECK, x 
    dex 
    stx DECKINDEX

    rts 