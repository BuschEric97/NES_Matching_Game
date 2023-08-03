.segment "HEADER"
    .byte "NES"     ; identification string
    .byte $1A
    .byte $02       ; amount of PRG ROM in 16K units
    .byte $01       ; amount of CHR ROM in 8K units
    .byte $00       ; mapper and mirroring
    .byte $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00

.segment "VECTORS"
    ; specialized hardware inerupts
    .word NMI
    .word RESET
    .word IRQ