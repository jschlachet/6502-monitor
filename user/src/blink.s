; test "hello world" which blinks all pins on port a of via 2
.include "monitor.inc"

.segment "USER"

PORTB = $6000               ; via 2
PORTA = $6001
DDRB  = $6002
DDRA  = $6003

  .word $3000               ; put origin at the top of the output binary file
  .org $3000

  LDA #$FF
  STA DDRB                  ; set all pins output
hello_loop:
  JSR delay
  ; NOP
  ; NOP
  ; NOP
  ; NOP
  ; NOP
  ; NOP
  LDA #$FF
  STA PORTA
  JSR delay
  ; NOP
  ; NOP
  ; NOP
  ; NOP
  ; NOP
  ; NOP
  LDA #$00
  STA PORTA
  JMP hello_loop


delay:
  PHA
  PHY
  LDA #$ff
  LDY #$ff
  JSR delay_ay
  PLY
  PLA
  RTS

delay_ay:
  CPY #1                ; (2)
  DEY                   ; (2)
  SBC #0                ; (2)
  BCS delay_ay          ; (3)
  RTS
