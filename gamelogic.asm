.segment "ZEROPAGE"
    CARDXPOS: .res 1
    CARDYPOS: .res 1
    GETCARDFLAG: .res 1

    BRDCARDID: .res 1
    BRDCARDSPOT: .res 1
    BRDGENINDEX: .res 1

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

clear_board:
    ldx #0
    loop_thru_clear_board:
        lda #0
        sta GAMEBOARDDATA, x
        inx 
        cpx #140
        bne loop_thru_clear_board

generate_board:
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
            jsr prng 
            sec 
            gen_brd_mod_0:
            sbc #140
            bcs gen_brd_mod_0
            adc #140
            sta BRDCARDSPOT
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
            jsr prng 
            sec 
            gen_brd_mod_1:
            sbc #140
            bcs gen_brd_mod_1
            adc #140
            sta BRDCARDSPOT
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
        cpy #70
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