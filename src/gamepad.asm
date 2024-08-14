; These are the bit flags the are used by the vars
.define PRESS_A        #%00000001
.define PRESS_B        #%00000010
.define PRESS_SELECT   #%00000100
.define PRESS_START    #%00001000
.define PRESS_UP       #%00010000
.define PRESS_DOWN     #%00100000
.define PRESS_LEFT     #%01000000
.define PRESS_RIGHT    #%10000000

.segment "ZEROPAGE"
    gamepad_press: .res 2
    gamepad_last_press: .res 2
    gamepad_new_press: .res 2
    gamepad_release: .res 2

.segment "CODE"

; initialize the gamepad.  this is called from the set_gamepad
gamepad_init:
    ; save gamepad_press to gamepad_last_press
    lda gamepad_press
    sta gamepad_last_press
    lda gamepad_press+1
    sta gamepad_last_press+1

    ; Setup the gamepad register so we can start pulling gamepad data
    lda #1
    sta $4016
    lda #0
    sta $4016

    ; the prior set call set the A register to #0, so no need to load it again
    sta gamepad_press ; clear out our gamepad press byte
    sta gamepad_press+1

    rts 

; initialize and set the gamepad values
set_gamepads:
    jsr gamepad_init ; prepare the gamepad register to pull data serially

    ;gamepad_a
    lda $4016
    and #%00000001
    sta gamepad_press

    ;gamepad_b
    lda $4016
    and #%00000001
    beq b_poll_not_pressed
        lda PRESS_B
        ora gamepad_press
        sta gamepad_press
    b_poll_not_pressed:

    ;gamepad_select
    lda $4016
    and #%00000001
    beq select_poll_not_pressed
        lda PRESS_SELECT
        ora gamepad_press
        sta gamepad_press
    select_poll_not_pressed:

    ;gamepad_start
    lda $4016
    and #%00000001
    beq start_poll_not_pressed
        lda PRESS_START
        ora gamepad_press
        sta gamepad_press
    start_poll_not_pressed:

    ;gamepad_up
    lda $4016
    and #%00000001
    beq up_poll_not_pressed
        lda PRESS_UP
        ora gamepad_press
        sta gamepad_press
    up_poll_not_pressed:

    ;gamepad_down
    lda $4016
    and #%00000001
    beq down_poll_not_pressed
        lda PRESS_DOWN
        ora gamepad_press
        sta gamepad_press
    down_poll_not_pressed:

    ;gamepad_left
    lda $4016
    and #%00000001
    beq left_poll_not_pressed
        lda PRESS_LEFT
        ora gamepad_press
        sta gamepad_press
    left_poll_not_pressed:

    ;gamepad_right
    lda $4016
    and #%00000001
    beq right_poll_not_pressed
        lda PRESS_RIGHT
        ora gamepad_press
        sta gamepad_press
    right_poll_not_pressed:
    
    ; to find out if this is a newly pressed button, load the last buttons pressed, and 
    ; flipp all the bits with an eor #$ff.  Then you can AND the results with current
    ; gamepad pressed.  This will give you what wasn't pressed previously, but what is
    ; pressed now.  Then store that value in the gamepad_new_press
    lda gamepad_last_press 
    eor #$FF
    and gamepad_press

    sta gamepad_new_press ; all these buttons are new presses and not existing presses

    ; in order to find what buttons were just released, we load and flip the buttons that
    ; are currently pressed  and and it with what was pressed the last time.
    ; that will give us a button that is not pressed now, but was pressed previously
    lda gamepad_press       ; reload original gamepad_press flags
    eor #$FF                ; flip the bits so we have 1 everywhere a button is released

    ; anding with last press shows buttons that were pressed previously and not pressed now
    and gamepad_last_press  

    ; then store the results in gamepad_release
    sta gamepad_release  ; a 1 flag in a button position means a button was just released

    ; repeat reading gamepad for controller port 2 (register $4017)
    ;gamepad_a
    lda $4017
    and #%00000001
    sta gamepad_press+1

    ;gamepad_b
    lda $4017
    and #%00000001
    beq b1_poll_not_pressed
        lda PRESS_B
        ora gamepad_press+1
        sta gamepad_press+1
    b1_poll_not_pressed:

    ;gamepad_select
    lda $4017
    and #%00000001
    beq select1_poll_not_pressed
        lda PRESS_SELECT
        ora gamepad_press+1
        sta gamepad_press+1
    select1_poll_not_pressed:

    ;gamepad_start
    lda $4017
    and #%00000001
    beq start1_poll_not_pressed
        lda PRESS_START
        ora gamepad_press+1
        sta gamepad_press+1
    start1_poll_not_pressed:

    ;gamepad_up
    lda $4017
    and #%00000001
    beq up1_poll_not_pressed
        lda PRESS_UP
        ora gamepad_press+1
        sta gamepad_press+1
    up1_poll_not_pressed:

    ;gamepad_down
    lda $4017
    and #%00000001
    beq down1_poll_not_pressed
        lda PRESS_DOWN
        ora gamepad_press+1
        sta gamepad_press+1
    down1_poll_not_pressed:

    ;gamepad_left
    lda $4017
    and #%00000001
    beq left1_poll_not_pressed
        lda PRESS_LEFT
        ora gamepad_press+1
        sta gamepad_press+1
    left1_poll_not_pressed:

    ;gamepad_right
    lda $4017
    and #%00000001
    beq right1_poll_not_pressed
        lda PRESS_RIGHT
        ora gamepad_press+1
        sta gamepad_press+1
    right1_poll_not_pressed:
    
    ; to find out if this is a newly pressed button, load the last buttons pressed, and 
    ; flipp all the bits with an eor #$ff.  Then you can AND the results with current
    ; gamepad pressed.  This will give you what wasn't pressed previously, but what is
    ; pressed now.  Then store that value in the gamepad_new_press
    lda gamepad_last_press+1
    eor #$FF
    and gamepad_press+1

    sta gamepad_new_press+1 ; all these buttons are new presses and not existing presses

    ; in order to find what buttons were just released, we load and flip the buttons that
    ; are currently pressed  and and it with what was pressed the last time.
    ; that will give us a button that is not pressed now, but was pressed previously
    lda gamepad_press+1     ; reload original gamepad_press flags
    eor #$FF                ; flip the bits so we have 1 everywhere a button is released

    ; anding with last press shows buttons that were pressed previously and not pressed now
    and gamepad_last_press+1

    ; then store the results in gamepad_release
    sta gamepad_release+1   ; a 1 flag in a button position means a button was just released

    rts