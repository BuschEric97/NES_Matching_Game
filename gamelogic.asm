.segment "ZEROPAGE"
    CARDXPOS: .res 1
    CARDYPOS: .res 1
    GETCARDFLAG: .res 1

    CURSORNEWDIR: .res 1    ; #0 == UP, #1 == RIGHT, #2 == DOWN, #3 == LEFT
    CURSORNEWX: .res 1
    CURSORNEWY: .res 1
    UPLIMIT: .res 1
    RIGHTLIMIT: .res 1
    DOWNLIMIT: .res 1
    LEFTLIMIT: .res 1

    BRDCARDID: .res 1
    BRDCARDSPOT: .res 1
    BRDGENINDEX: .res 1
    BRDLOOPLIMIT: .res 1
    BRDNUMCARDS: .res 1

.segment "CODE"

; get the card ID of the card at position (CARDXPOS, CARDYPOS) and store in accumulator register
; THIS SUBROUTINE CLOBBERS ALL REGISTERS!
get_set_card_id:
    lda #0
    ldy #0
    mult_14_loop:
        clc 
        adc #14
        iny 
        cpy CARDYPOS
        bne mult_14_loop
    clc 
    adc CARDXPOS
    tax 

    lda GETCARDFLAG
    beq set_card_0
        lda GAMEBOARDDATA, x 
        jmp get_set_card_done
    set_card_0:
        lda #0
        sta GAMEBOARDDATA, x

    get_set_card_done:
    rts 

set_new_cursor_pos:
    ; set initial new position
    lda CURSORXPOS
    sta CURSORNEWX
    lda CURSORYPOS
    sta CURSORNEWY

    lda CURSORNEWDIR
    bne not_moving_up
        ;moving_up:
        ; get next position to check
        lda CURSORNEWY
        cmp UPLIMIT
        beq up_limit
            sec 
            sbc #1
            sta CURSORNEWY
            jmp set_up
        up_limit:
            lda DOWNLIMIT
            sta CURSORNEWY
        set_up:
        jmp write_to_cursor
    not_moving_up:
    lda CURSORNEWDIR
    cmp #1
    bne not_moving_right
        ;moving_right:
        ; get next position to check
        lda CURSORNEWX
        cmp RIGHTLIMIT
        beq right_limit
            clc 
            adc #1
            sta CURSORNEWX
            jmp set_right
        right_limit:
            lda LEFTLIMIT
            sta CURSORNEWX
        set_right:
        jmp write_to_cursor
    not_moving_right:
    lda CURSORNEWDIR
    cmp #2
    bne not_moving_down
        ;moving_down
        ; get next position to check
        lda CURSORNEWY
        cmp DOWNLIMIT
        beq down_limit
            clc  
            adc #1
            sta CURSORNEWY
            jmp set_down
        down_limit:
            lda UPLIMIT
            sta CURSORNEWY
        set_down:
        jmp write_to_cursor
    not_moving_down:
        ;moving_left:
        ; get next position to check
        lda CURSORNEWX
        cmp LEFTLIMIT
        beq left_limit
            sec 
            sbc #1
            sta CURSORNEWX
            jmp set_left
        left_limit:
            lda RIGHTLIMIT
            sta CURSORNEWX
        set_left:

    write_to_cursor:
        lda CURSORNEWX
        sta CURSORXPOS
        lda CURSORNEWY
        sta CURSORYPOS
    skip_write_to_cursor:
    rts 

clear_board:
    ldx #0
    loop_thru_clear_board:
        lda #0
        sta GAMEBOARDDATA, x
        inx 
        cpx #140
        bne loop_thru_clear_board

generate_board:
    lda BRDNUMCARDS
    lsr A
    sta BRDLOOPLIMIT
    lda #0
    sta BRDCARDID
    sta BRDCARDSPOT
    sta BRDGENINDEX
    loop_thru_board:
        ; get a random card ID
        jsr prng
        beq loop_thru_board ; prevent card ID = #$00
        sta BRDCARDID
    
        ; find an empty first spot on the board
        spot_0:
            ; get random number modulus the number of card slots on the board
            jsr prng 
            sec 
            gen_brd_mod_0:
            sbc BRDNUMCARDS
            bcs gen_brd_mod_0
            adc BRDNUMCARDS

            tax 
            sta BRDCARDSPOT
            lda GAMEBOARDDATA, x
            beq spot_0_success
                jmp spot_0
            spot_0_success:
        
        ; set BRDCARDID to first spot on the board
        lda BRDCARDID
        ldx BRDCARDSPOT
        sta GAMEBOARDDATA, x

        ldy BRDGENINDEX
        iny 
        sty BRDGENINDEX

        ; find an empty second spot on the board
        spot_1:
            ; get random number modulus the number of card slots on the board
            jsr prng 
            sec 
            gen_brd_mod_1:
            sbc BRDNUMCARDS
            bcs gen_brd_mod_1
            adc BRDNUMCARDS

            tax 
            sta BRDCARDSPOT
            lda GAMEBOARDDATA, x
            beq spot_1_success
                jmp spot_1
            spot_1_success:
        
        ; set BRDCARDID to second spot on the board
        lda BRDCARDID
        ldx BRDCARDSPOT
        sta GAMEBOARDDATA, x

        ldy BRDGENINDEX
        iny 
        sty BRDGENINDEX
        cpy BRDLOOPLIMIT
        bne loop_thru_board

    rts 

increment_score:
    ;increment_ones:
    lda SCOREMISSES
    clc 
    adc #1
    sta SCOREMISSES
    cmp #10
    bne done_increment
        ;increment_tens:
        ; set ones place to 0
        lda #0
        sta SCOREMISSES
        lda SCOREMISSES+1
        clc 
        adc #1
        sta SCOREMISSES+1
        cmp #10
        bne done_increment
            ;increment_hundreds:
            ; set tens place to 0
            lda #0
            sta SCOREMISSES+1
            lda SCOREMISSES+2
            clc 
            adc #1
            sta SCOREMISSES+2
            cmp #10
            bne done_increment
                ;increment_thousands:
                ; set hundreds place to 0
                lda #0
                sta SCOREMISSES+2
                lda SCOREMISSES+3
                clc 
                adc #1
                sta SCOREMISSES+3
                cmp #10
                bne done_increment
                    ; set thousands place back to 9
                    lda #9
                    sta SCOREMISSES+3

    done_increment:
    
    rts 

initialize_level_vars:
    lda LEVELFLAG
    bne level_not_0
        ; level 0
        lda #0
        sta UPLIMIT
        lda #13
        sta RIGHTLIMIT
        lda #1
        sta DOWNLIMIT
        lda #0
        sta LEFTLIMIT
        lda #0
        sta CURSORXPOS
        lda #0
        sta CURSORYPOS
        lda #28
        sta BRDNUMCARDS
        jmp done_inits
    level_not_0:
    lda LEVELFLAG
    cmp #1
    bne level_not_1
        ; level 1
        lda #0
        sta UPLIMIT
        lda #13
        sta RIGHTLIMIT
        lda #3
        sta DOWNLIMIT
        lda #0
        sta LEFTLIMIT
        lda #0
        sta CURSORXPOS
        lda #0
        sta CURSORYPOS
        lda #56
        sta BRDNUMCARDS
        jmp done_inits
    level_not_1:
    lda LEVELFLAG
    cmp #2
    bne level_not_2
        ; level 2
        lda #0
        sta UPLIMIT
        lda #13
        sta RIGHTLIMIT
        lda #5
        sta DOWNLIMIT
        lda #0
        sta LEFTLIMIT
        lda #0
        sta CURSORXPOS
        lda #0
        sta CURSORYPOS
        lda #84
        sta BRDNUMCARDS
        jmp done_inits
    level_not_2:
    lda LEVELFLAG
    cmp #3
    bne level_not_3
        ; level 3
        lda #0
        sta UPLIMIT
        lda #13
        sta RIGHTLIMIT
        lda #7
        sta DOWNLIMIT
        lda #0
        sta LEFTLIMIT
        lda #0
        sta CURSORXPOS
        lda #0
        sta CURSORYPOS
        lda #112
        sta BRDNUMCARDS
        jmp done_inits
    level_not_3:
        ; max level
        lda #0
        sta UPLIMIT
        lda #13
        sta RIGHTLIMIT
        lda #9
        sta DOWNLIMIT
        lda #0
        sta LEFTLIMIT
        lda #0
        sta CURSORXPOS
        lda #0
        sta CURSORYPOS
        lda #140
        sta BRDNUMCARDS
    
    done_inits:
        rts 