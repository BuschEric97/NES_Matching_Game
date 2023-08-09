.segment "IMG"
    .incbin "rom.chr"

.segment "ZEROPAGE"
    GAMEBOARDDATA: .res 140     ; 1 byte for each card on the board (a card ID of $00 means the card is gone)
    SHOWCARDSBUFFER: .res 1     ; When greater than 0, decrement and skip game logic (in order to show the selected cards)

.segment "VARS"

.include "header.asm"
.include "utils.asm"
.include "gamepad.asm"
.include "ppu.asm"
.include "palette.asm"

.include "random.asm"
.include "drawing.asm"
.include "gamelogic.asm"

.include "nmi.asm"
.include "irq.asm"
.include "reset.asm"

.segment "CODE"
game_loop:
    lda nmi_ready
    bne game_loop

    ; increment seed to enhance pseudo-randomness
    ldx seed+1
    inx 
    stx seed+1

    ;---------------------------;
    ; Show Cards Buffer Code    ;
    ;---------------------------;
    ; decrement buffer if above 0
    lda SHOWCARDSBUFFER
    beq buffer_is_0
        ldx SHOWCARDSBUFFER
        dex 
        stx SHOWCARDSBUFFER
        jmp buffer_finished
    buffer_is_0:
        ; check if DRAWCARD1 is set, if so erase both cards
        lda DRAWCARD1
        beq buffer_finished
            lda CARD0ID
            cmp CARD1ID
            bne cards_not_match ; erase background cards and update GAMEBOARDDATA if cards match
                ; erase card 0's background card and set its card ID to 0
                lda CARD0XPOS
                sta BGCARDXPOS
                sta CARDXPOS
                lda CARD0YPOS
                sta BGCARDYPOS
                sta CARDYPOS
                lda #0
                sta DRAWBGCARD
                sta GETCARDFLAG
                jsr draw_bg_card
                jsr get_set_card_id
                ; erase card 1's background card and set its card ID to 0
                lda CARD1XPOS
                sta BGCARDXPOS
                sta CARDXPOS
                lda CARD1YPOS
                sta BGCARDYPOS
                sta CARDYPOS
                lda #0
                sta DRAWBGCARD
                sta GETCARDFLAG
                jsr draw_bg_card
                jsr get_set_card_id
            cards_not_match:
                lda #0
                sta DRAWCARD0
                sta DRAWCARD1
                jsr draw_cards
            ; TODO: check if cards match, if so update GAMEBOARDDATA and background cards
    buffer_finished:

    ; get gamepad input
    jsr set_gamepad

    ;-------------------;
    ; Move Cursor Code  ;
    ;-------------------;
    ; see if dpad UP was pressed
    lda gamepad_new_press
    and PRESS_UP
    cmp PRESS_UP
    bne up_not_pressed
        lda CURSORYPOS
        cmp #0
        beq up_limit
            sbc #1
            jmp set_up
        up_limit:
            lda #9
        set_up:
            sta CURSORYPOS
    up_not_pressed:
    ; see if dpad DOWN was pressed
    lda gamepad_new_press
    and PRESS_DOWN
    cmp PRESS_DOWN
    bne down_not_pressed
        lda CURSORYPOS
        cmp #9
        beq down_limit
            clc 
            adc #1
            jmp set_down
        down_limit:
            lda #0
        set_down:
            sta CURSORYPOS
    down_not_pressed:
    ; see if dpad LEFT was pressed
    lda gamepad_new_press
    and PRESS_LEFT
    cmp PRESS_LEFT
    bne left_not_pressed
        lda CURSORXPOS
        cmp #0
        beq left_limit
            sbc #1
            jmp set_left
        left_limit:
            lda #13
        set_left:
            sta CURSORXPOS
    left_not_pressed:
    ; see if dpad RIGHT was pressed
    lda gamepad_new_press
    and PRESS_RIGHT
    cmp PRESS_RIGHT
    bne right_not_pressed
        lda CURSORXPOS
        cmp #13
        beq right_limit
            clc 
            adc #1
            jmp set_right
        right_limit:
            lda #0
        set_right:
            sta CURSORXPOS
    right_not_pressed:

    ; always draw the cursor
    jsr draw_cursor

    ;---------------------------;
    ; A Button Handling Code    ;
    ;---------------------------;
    ; see if button A was pressed
    lda gamepad_new_press
    and PRESS_A
    cmp PRESS_A
    bne a_not_pressed
        lda SHOWCARDSBUFFER
        bne a_not_pressed   ; don't allow button A actions when buffer is greater than 0
        lda DRAWCARD0
        bne card_1_select
        ;card_0_select:
            lda CURSORXPOS
            sta CARD0XPOS
            sta CARDXPOS
            lda CURSORYPOS
            sta CARD0YPOS
            sta CARDYPOS
            lda #1
            sta GETCARDFLAG
            jsr get_set_card_id
            sta CARD0ID
            lda #1
            sta DRAWCARD0
            jmp draw_a_card
        card_1_select:
            ; first check if cursor is above card 0
            lda CURSORXPOS
            cmp CARD0XPOS
            bne card_1_proceed
                lda CURSORYPOS
                cmp CARD0YPOS
                beq a_not_pressed   ; don't allow button A actions when cursor is above card 0
            card_1_proceed:
                lda CURSORXPOS
                sta CARD1XPOS
                sta CARDXPOS
                lda CURSORYPOS
                sta CARD1YPOS
                sta CARDYPOS
                lda #1
                sta GETCARDFLAG
                jsr get_set_card_id
                sta CARD1ID
                lda #1
                sta DRAWCARD1
                lda #$30
                sta SHOWCARDSBUFFER
        draw_a_card:
            jsr draw_cards
    a_not_pressed:

    ; see if button START was pressed
    lda gamepad_new_press
    and PRESS_START
    cmp PRESS_START
    bne start_not_pressed
        jsr clear_board
        jsr generate_board
    start_not_pressed:

    ; return to start of game loop
    jmp game_loop