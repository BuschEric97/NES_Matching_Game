.segment "IMG"
    .incbin "rom.chr"

.segment "ZEROPAGE"
    GAMEBOARDDATA: .res 140     ; 1 byte for each card on the board (a card ID of $00 means the card is gone)
    SHOWCARDSBUFFER: .res 1     ; When greater than 0, decrement and skip game logic (in order to show the selected cards)
    MOVEMENTBUFFER: .res 1      ; When greater than 0, decrement and disallow movement via holding down dpad direction
    FIRSTMOVBUFFER: .res 1      ; When greater than 0, decrement and disallow movement via holding down dpad direction
    GAMEFLAG: .res 1            ; Flag to indicate when a game is being played
    LEVELFLAG: .res 1           ; Variable to indicate which difficulty the game is being played at
    SCOREMISSES: .res 4         ; Variable to track how many unsuccessful matches have been made

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

    ; decrement movement buffer if above 0
    lda MOVEMENTBUFFER
    beq mov_buffer_is_0
        ldx MOVEMENTBUFFER
        dex 
        stx MOVEMENTBUFFER
    mov_buffer_is_0:

    ; decrement first movement buffer if above 0
    lda FIRSTMOVBUFFER
    beq first_mov_buffer_is_0
        ldx FIRSTMOVBUFFER
        dex 
        stx FIRSTMOVBUFFER
    first_mov_buffer_is_0:

    ; get gamepad input
    jsr set_gamepad

    ; skip cursor code when game is not running
    lda GAMEFLAG
    bne do_cursor_logic
        jmp skip_cursor
    do_cursor_logic:

    ;-------------------;
    ; Move Cursor Code  ;
    ;-------------------;
    ; see if dpad UP was pressed
    lda gamepad_press
    and PRESS_UP
    cmp PRESS_UP
    bne up_not_pressed
        lda gamepad_last_press
        and PRESS_UP
        cmp PRESS_UP
        bne check_new_up
            lda MOVEMENTBUFFER
            bne up_not_pressed  ; skip movement if holding down direction and buffer is greater than 0
                lda FIRSTMOVBUFFER
                bne up_not_pressed
                    jmp move_up
        check_new_up:
            lda gamepad_new_press
            and PRESS_UP
            cmp PRESS_UP
            bne up_not_pressed
                lda #$10
                sta FIRSTMOVBUFFER
        move_up:
            lda #0
            sta CURSORNEWDIR
            jsr set_new_cursor_pos
            lda #$04
            sta MOVEMENTBUFFER
    up_not_pressed:
    ; see if dpad RIGHT was pressed
    lda gamepad_press
    and PRESS_RIGHT
    cmp PRESS_RIGHT
    bne right_not_pressed
        lda gamepad_last_press
        and PRESS_RIGHT
        cmp PRESS_RIGHT
        bne check_new_right
            lda MOVEMENTBUFFER
            bne right_not_pressed  ; skip movement if holding down direction and buffer is greater than 0
                lda FIRSTMOVBUFFER
                bne right_not_pressed
                    jmp move_right
        check_new_right:
            lda gamepad_new_press
            and PRESS_RIGHT
            cmp PRESS_RIGHT
            bne right_not_pressed
                lda #$10
                sta FIRSTMOVBUFFER
        move_right:
            lda #1
            sta CURSORNEWDIR
            jsr set_new_cursor_pos
            lda #$04
            sta MOVEMENTBUFFER
    right_not_pressed:
    ; see if dpad DOWN was pressed
    lda gamepad_press
    and PRESS_DOWN
    cmp PRESS_DOWN
    bne down_not_pressed
        lda gamepad_last_press
        and PRESS_DOWN
        cmp PRESS_DOWN
        bne check_new_down
            lda MOVEMENTBUFFER
            bne down_not_pressed  ; skip movement if holding down direction and buffer is greater than 0
                lda FIRSTMOVBUFFER
                bne down_not_pressed
                    jmp move_down
        check_new_down:
            lda gamepad_new_press
            and PRESS_DOWN
            cmp PRESS_DOWN
            bne down_not_pressed
                lda #$10
                sta FIRSTMOVBUFFER
        move_down:
            lda #2
            sta CURSORNEWDIR
            jsr set_new_cursor_pos
            lda #$04
            sta MOVEMENTBUFFER
    down_not_pressed:
    ; see if dpad LEFT was pressed
    lda gamepad_press
    and PRESS_LEFT
    cmp PRESS_LEFT
    bne left_not_pressed
        lda gamepad_last_press
        and PRESS_LEFT
        cmp PRESS_LEFT
        bne check_new_left
            lda MOVEMENTBUFFER
            bne left_not_pressed  ; skip movement if holding down direction and buffer is greater than 0
                lda FIRSTMOVBUFFER
                bne left_not_pressed
                    jmp move_left
        check_new_left:
            lda gamepad_new_press
            and PRESS_LEFT
            cmp PRESS_LEFT
            bne left_not_pressed
                lda #$10
                sta FIRSTMOVBUFFER
        move_left:
            lda #3
            sta CURSORNEWDIR
            jsr set_new_cursor_pos
            lda #$04
            sta MOVEMENTBUFFER
    left_not_pressed:

    ; always draw the cursor when a game is being played
    jsr draw_cursor
    skip_cursor:

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
        lda DRAWCARD1
        bne a_not_pressed   ; don't allow button A actions when both cards are visible
        lda CURSORXPOS
        sta CARDXPOS
        lda CURSORYPOS
        sta CARDYPOS
        lda #1
        sta GETCARDFLAG
        jsr get_set_card_id
        beq a_not_pressed   ; don't allow button A actions when cursor on empty spot
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
        lda GAMEFLAG
        bne start_not_pressed   ; don't allow button START actions when game is being played
            jsr initialize_level_vars
            jsr clear_board
            jsr generate_board
            jsr draw_board
            lda #1
            sta GAMEFLAG    ; set GAMEFLAG to 1 to indicate a game is being played
    start_not_pressed:

    lda gamepad_new_press
    and PRESS_SELECT
    cmp PRESS_SELECT
    bne select_not_pressed
        lda GAMEFLAG
        bne select_not_pressed  ; don't allow button SELECT actions when game is being played
            lda LEVELFLAG
            cmp #4
            beq level_limit
                lda LEVELFLAG
                clc 
                adc #1
                jmp set_level
            level_limit:
                lda #0
            set_level:
                sta LEVELFLAG
                jsr draw_level_select
    select_not_pressed:

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
                ; skip incrementing misses score
                jmp card_check_finish
            cards_not_match:
                ; increment misses score
                jsr increment_score
                jsr draw_score
            card_check_finish:
                ; erase the drawn card sprites
                lda #0
                sta DRAWCARD0
                sta DRAWCARD1
                jsr draw_cards
            ; TODO: check if cards match, if so update GAMEBOARDDATA and background cards
    buffer_finished:

    ; return to start of game loop
    jmp game_loop