.ifndef _VIA_S_
_VIA_S_ = 1


save_via:
  PHA
  LDA $00
  STA VIA_PORTB_LO
  LDA $01
  STA VIA_PORTB_HI
  LDA $02
  STA VIA_PORTA_LO
  LDA $03
  STA VIA_PORTA_HI
  LDA $04
  STA VIA_DDRB_LO
  LDA $05
  STA VIA_DDRB_HI
  LDA $06
  STA VIA_DDRA_LO
  LDA $07
  STA VIA_DDRA_HI
  PLA
  RTS

restore_via:
  PHA
  LDA VIA_PORTB_LO
  STA $00
  LDA VIA_PORTB_HI
  STA $01
  LDA VIA_PORTA_LO
  STA $02
  LDA VIA_PORTA_HI
  STA $03
  LDA VIA_DDRB_LO
  STA $04
  LDA VIA_DDRB_HI
  STA $05
  LDA VIA_DDRA_LO
  STA $06
  LDA VIA_DDRA_HI
  STA $07
  PLA
  RTS



set_via1:
  pha

  lda #<VIA1_PORTB      ; via_portb
  sta $00
  lda #>VIA1_PORTB
  sta $01

  lda #<VIA1_PORTA      ; via_porta
  sta $02
  lda #>VIA1_PORTA
  sta $03

  lda #<VIA1_DDRB       ; via_ddrb
  sta $04
  lda #>VIA1_DDRB
  sta $05

  lda #<VIA1_DDRA       ; via_ddra
  sta $06
  lda #>VIA1_DDRA
  sta $07

  pla
  rts

;
;

set_via2:
  pha

  lda #<VIA2_PORTB      ; via_portb
  sta $00
  lda #>VIA2_PORTB
  sta $01

  lda #<VIA2_PORTA      ; via_porta
  sta $02
  lda #>VIA2_PORTA
  sta $03

  lda #<VIA2_DDRB       ; via_ddrb
  sta $04
  lda #>VIA2_DDRB
  sta $05

  lda #<VIA2_DDRA       ; via_ddra
  sta $06
  lda #>VIA2_DDRA
  sta $07

  pla
  rts


set_via3:
  pha

  lda #<VIA3_PORTB      ; via_portb
  sta $00
  lda #>VIA3_PORTB
  sta $01

  lda #<VIA3_PORTA      ; via_porta
  sta $02
  lda #>VIA3_PORTA
  sta $03

  lda #<VIA3_DDRB       ; via_ddrb
  sta $04
  lda #>VIA3_DDRB
  sta $05

  lda #<VIA3_DDRA       ; via_ddra
  sta $06
  lda #>VIA3_DDRA
  sta $07

  pla
  rts

.endif
