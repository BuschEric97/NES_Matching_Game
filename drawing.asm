.segment "ZEROPAGE"
    DRAWCARD0: .res 1
    CARD0ID: .res 1
    CARD0XPOS: .res 1
    CARD0YPOS: .res 1

    DRAWCARD1: .res 1
    CARD1ID: .res 1
    CARD1XPOS: .res 1
    CARD1YPOS: .res 1

    CURSORXPOS: .res 1
    CURSORYPOS: .res 1

    DRAWBGCARD: .res 1
    BGCARDXPOS: .res 1
    BGCARDYPOS: .res 1
    BGCARDHBYTE: .res 1
    BGCARDLBYTE: .res 1

.segment "CODE"

; draw a card with the given card ID in the virtual position (X,Y)
;   - virtual position meaning a spot on the 14 x 11 grid of cards
;     not the actual graphics grid of the NES!
draw_cards:
    lda DRAWCARD0
    cmp #1
    beq draw_0 ; if DRAWCARD0 = 1 draw card 0, else erase card 0

    ; erase card 0
    erase_0:
        lda #$00
        ldx #$00
        erase_0_loop:
            sta $0204, x
            inx 
            cpx #$10
            bne erase_0_loop

        jmp draw_1_chk

    ; draw card 0
    draw_0:
        jsr draw_card_0
        ;jmp draw_1_chk

    draw_1_chk:
        lda DRAWCARD1
        cmp #1
        beq draw_1 ; if DRAWCARD1 = 1 draw card 1, else erase card 1

    ; erase card 1
    erase_1:
        lda #$00
        ldx #$00
        erase_1_loop:
            sta $0214, x
            inx 
            cpx #$10
            bne erase_1_loop
        
        jmp draw_sp

    ; draw card 1
    draw_1:
        jsr draw_card_1
        ;jmp draw_sp

    ; draw all sprites
    draw_sp:
        jsr draw_sprites

    rts 

draw_card_0:
    ; calculate virtual_Y
    lda CARD0YPOS
    asl a
    asl a
    asl a
    asl a
    clc 
    adc #$1F

    sta $0204       ; sprite 1 Y pos
    sta $0208       ; sprite 2 Y pos
    clc 
    adc #$08
    sta $020C       ; sprite 3 Y pos
    sta $0210       ; sprite 4 Y pos

    lda CARD0ID
    and #%00000011
    sta $0205       ; sprite 1 tile number
    lda CARD0ID
    and #%00001100
    lsr a
    lsr a
    sta $0209       ; sprite 2 tile number
    lda CARD0ID
    and #%00110000
    lsr a
    lsr a
    lsr a
    lsr a
    sta $020D       ; sprite 3 tile number
    lda CARD0ID 
    and #%11000000
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    sta $0211       ; sprite 4 tile number

    lda #%00000000
    sta $0206       ; sprite 1 attributes
    lda #%01000000
    sta $020A       ; sprite 2 attributes
    lda #%10000000
    sta $020E       ; sprite 3 attributes
    lda #%11000000
    sta $0212       ; sprite 4 attributes

    ; calculate virtual_X
    lda CARD0XPOS
    asl a
    asl a
    asl a
    asl a
    clc 
    adc #$10

    sta $0207       ; sprite 1 X pos
    sta $020F       ; sprite 3 X pos
    clc 
    adc #$08
    sta $020B       ; sprite 2 X pos
    sta $0213       ; sprite 4 X pos

    rts 

draw_card_1:
    ; calculate virtual_Y
    lda CARD1YPOS
    asl a
    asl a
    asl a
    asl a
    clc 
    adc #$1F

    sta $0214       ; sprite 1 Y pos
    sta $0218       ; sprite 2 Y pos
    clc 
    adc #$08
    sta $021C       ; sprite 3 Y pos
    sta $0220       ; sprite 4 Y pos

    lda CARD1ID
    and #%00000011
    sta $0215       ; sprite 1 tile number
    lda CARD1ID
    and #%00001100
    lsr a
    lsr a
    sta $0219       ; sprite 2 tile number
    lda CARD1ID
    and #%00110000
    lsr a
    lsr a
    lsr a
    lsr a
    sta $021D       ; sprite 3 tile number
    lda CARD1ID 
    and #%11000000
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    sta $0221       ; sprite 4 tile number

    lda #%00000000
    sta $0216       ; sprite 1 attributes
    lda #%01000000
    sta $021A       ; sprite 2 attributes
    lda #%10000000
    sta $021E       ; sprite 3 attributes
    lda #%11000000
    sta $0222       ; sprite 4 attributes

    ; calculate virtual_X
    lda CARD1XPOS
    asl a
    asl a
    asl a
    asl a
    clc 
    adc #$10

    sta $0217       ; sprite 1 X pos
    sta $021F       ; sprite 3 X pos
    clc 
    adc #$08
    sta $021B       ; sprite 2 X pos
    sta $0223       ; sprite 4 X pos

    rts 

draw_cursor:
    lda CURSORYPOS
    asl a
    asl a
    asl a
    asl a
    clc 
    adc #$27
    sta $0200       ; cursor Y pos

    lda #$20
    sta $0201       ; cursor tile number

    lda #%00000000
    sta $0202       ; cursor attributes

    lda CURSORXPOS
    asl a
    asl a
    asl a
    asl a
    clc 
    adc #$18
    sta $0203       ; cursor X pos

    jsr draw_sprites

    rts 

draw_sprites:
    ; wait for vblank
    bit $2002
    vblank_wait:
        bit $2002
        bpl vblank_wait
    
    ; draw all sprites to screen
    lda #$02
    sta $4014
    
    rts 

draw_bg_card:
    ; wait for vblank
    bit $2002
    vblank_wait_bg:
        bit $2002
        bpl vblank_wait_bg

    ; disable sprites and background rendering
    lda #%00000000
    sta $2001

    ; write new background card
    ;   if vY 0-1: high byte $20
    ;   if vY 2-5: high byte $21
    ;   if vY 6-9: high byte $22
    lda BGCARDYPOS
    cmp #9
    bne less_9
        lda #$22
        sta BGCARDHBYTE
        lda BGCARDXPOS
        asl a
        clc 
        adc #194
        sta BGCARDLBYTE
        jmp drawing_bg_card
    less_9:
    cmp #8
    bne less_8
        lda #$22
        sta BGCARDHBYTE
        lda BGCARDXPOS
        asl a
        clc 
        adc #130
        sta BGCARDLBYTE
        jmp drawing_bg_card
    less_8:
    cmp #7
    bne less_7
        lda #$22
        sta BGCARDHBYTE
        lda BGCARDXPOS
        asl a
        clc 
        adc #66
        sta BGCARDLBYTE
        jmp drawing_bg_card
    less_7:
    cmp #6
    bne less_6
        lda #$22
        sta BGCARDHBYTE
        lda BGCARDXPOS
        asl a
        clc 
        adc #2
        sta BGCARDLBYTE
        jmp drawing_bg_card
    less_6:
    cmp #5
    bne less_5
        lda #$21
        sta BGCARDHBYTE
        lda BGCARDXPOS
        asl a
        clc 
        adc #194
        sta BGCARDLBYTE
        jmp drawing_bg_card
    less_5:
    cmp #4
    bne less_4
        lda #$21
        sta BGCARDHBYTE
        lda BGCARDXPOS
        asl a
        clc 
        adc #130
        sta BGCARDLBYTE
        jmp drawing_bg_card
    less_4:
    cmp #3
    bne less_3
        lda #$21
        sta BGCARDHBYTE
        lda BGCARDXPOS
        asl a
        clc 
        adc #66
        sta BGCARDLBYTE
        jmp drawing_bg_card
    less_3:
    cmp #2
    bne less_2
        lda #$21
        sta BGCARDHBYTE
        lda BGCARDXPOS
        asl a
        clc 
        adc #2
        sta BGCARDLBYTE
        jmp drawing_bg_card
    less_2:
    cmp #1
    bne less_1
        lda #$20
        sta BGCARDHBYTE
        lda BGCARDXPOS
        asl a
        clc 
        adc #194
        sta BGCARDLBYTE
        jmp drawing_bg_card
    less_1:
        lda #$20
        sta BGCARDHBYTE
        lda BGCARDXPOS
        asl a
        clc 
        adc #130
        sta BGCARDLBYTE

    drawing_bg_card:

        lda DRAWBGCARD
        cmp #1
        bne erase_from_bg
        draw_on_bg:
            ; draw top half of card
            lda $2002
            lda BGCARDHBYTE
            sta $2006
            lda BGCARDLBYTE
            sta $2006

            lda #$00
            sta $2007
            lda #$01 
            sta $2007

            ; draw bottom half of card
            lda $2002
            lda BGCARDHBYTE
            sta $2006
            lda BGCARDLBYTE
            clc 
            adc #$20
            sta $2006

            lda #$02 
            sta $2007
            lda #$03 
            sta $2007
            jmp done_drawing_bg_card
        erase_from_bg:
            ; erase top half of card
            lda $2002
            lda BGCARDHBYTE
            sta $2006
            lda BGCARDLBYTE
            sta $2006

            lda #$3F
            sta $2007
            sta $2007

            ; erase bottom half of card
            lda $2002
            lda BGCARDHBYTE
            sta $2006
            lda BGCARDLBYTE
            clc 
            adc #$20
            sta $2006

            lda #$3F
            sta $2007
            sta $2007

    done_drawing_bg_card:
    ; enable sprites and background rendering
    lda #%00011110
    sta $2001

    ; reset scrolling
    lda #$00
    sta $2005
    sta $2005

    rts 

draw_board:
    ; wait for vblank
    bit $2002
    vblank_wait_full_board:
        bit $2002
        bpl vblank_wait_full_board

    ; disable sprites and background rendering
    lda #%00000000
    sta $2001

    load_board_background:
        lda $2002               ; read PPU status to reset the high/low latch
        lda #$20
        sta $2006               ; write the high byte of $2000 address
        lda #$00
        sta $2006               ; write the low byte of $2000 address
    ldx #$00                    ; start out at 0
    load_board_background_loop_0:
        lda background_data_full_board, x   ; load data from address (background + the value in x register)
        sta $2007               ; write to PPU
        inx                     ; increment x by 1
        cpx #$00                ; compare x to hex $00 - copying 256 bytes
        bne load_board_background_loop_0
    load_board_background_loop_1:     ; loop for 2nd set of background data
        lda background_data_full_board+256, x
        sta $2007
        inx 
        cpx #$00
        bne load_board_background_loop_1
    load_board_background_loop_2:     ; loop for 3rd set of background data
        lda background_data_full_board+512, x
        sta $2007
        inx 
        cpx #$00
        bne load_board_background_loop_2
    load_board_background_loop_3:     ; loop for 4th set of background data
        lda background_data_full_board+768, x
        sta $2007
        inx 
        cpx #$C0
        bne load_board_background_loop_3

    load_board_attributes:
        lda $2002               ; read PPU status to reset the high/low latch
        lda #$23
        sta $2006               ; write the high byte of $23C0 address
        lda #$C0
        sta $2006               ; write the low byte of $23C0 address
    ldx #$00                    ; start out at 0
    load_board_attributes_loop:
        lda bg_attributes, x    ; load data from address (attribute + the value in x register)
        sta $2007               ; write to PPU
        inx                     ; increment x by 1
        cpx #$40                ; compare x to hex $40 - copying 64 bytes
        bne load_board_attributes_loop

    ; enable sprites and background rendering
    lda #%00011110
    sta $2001

    ; reset scrolling
    lda #$00
    sta $2005
    sta $2005

    rts 


;------------------------------------------------------ actual playable area of board: 28 x 20 byte grid (14 x 10 cards)

background_data_full_board:
    .byte $3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E
    .byte $3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E
    .byte $3E,$08,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$09,$3E
    .byte $3E,$0E,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$0F,$3E
    .byte $3E,$0E,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$0F,$3E
    .byte $3E,$0E,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$0F,$3E
    .byte $3E,$0E,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$0F,$3E
    .byte $3E,$0E,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$0F,$3E
    .byte $3E,$0E,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$0F,$3E
    .byte $3E,$0E,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$0F,$3E
    .byte $3E,$0E,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$0F,$3E
    .byte $3E,$0E,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$0F,$3E
    .byte $3E,$0E,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$0F,$3E
    .byte $3E,$0E,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$0F,$3E
    .byte $3E,$0E,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$0F,$3E
    .byte $3E,$0E,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$0F,$3E
    .byte $3E,$0E,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$0F,$3E
    .byte $3E,$0E,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$0F,$3E
    .byte $3E,$0E,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$0F,$3E
    .byte $3E,$0E,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$0F,$3E
    .byte $3E,$0E,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$0F,$3E
    .byte $3E,$0E,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$0F,$3E
    .byte $3E,$0E,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$0F,$3E
    .byte $3E,$0E,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$02,$03,$0F,$3E
    .byte $3E,$0E,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$0F,$3E
    .byte $3E,$0E,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$0F,$3E
    .byte $3E,$0E,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$0F,$3E
    .byte $3E,$0A,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0B,$3E
    .byte $3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E
    .byte $3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E

bg_attributes:
    .byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
    .byte %00010001, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %01000100
    .byte %00010001, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %01000100
    .byte %00010001, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %01000100
    .byte %00010001, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %01000100
    .byte %00010001, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %01000100
    .byte %01010001, %01010000, %01010000, %01010000, %01010000, %01010000, %01010000, %01010100
    .byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101