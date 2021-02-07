    !to "x.prg",cbm
    *= $1000
    
    lda #$80
    sta $d40f
    sta $d412
loop:
    lda $d41b
    and #1
    adc #$6d
    jsr $ffd2
    bne loop