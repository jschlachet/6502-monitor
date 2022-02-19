;
; VIA1 (right)
;   Port A
;           A0-A7 --> SN76489
;   Port B
;           B0    --> SN76489 /WE
;           B1    --> SN76489 RDY
;           B0-B1 --> SOUND
;           B2-B7 --> unconnected
;
; VIA2 (left)
;   Port A
;           A0-A3 --> LCD D7..D0
;           A4    --> LCD E
;           A5    --> LCD RW
;           A6    --> LCD RS
;           A7    --> USER LED
;   Port B
;           B0-B7 --> unconnected
;

  .setcpu "65C02"


  .include "acia.cfg"
  .include "lcd-4bit.cfg"
  .include "via.cfg"
  .include "zeropage.cfg"



  .code

  .include "acia.s"
  .include "lcd-4bit.s"
  .include "via.s"
  .include "sn76489.s"

  .global prompt_loop
  .global send_message_serial


reset:
  ldx #$ff
  txs

  jsr init_via

  jsr sound_mute

  jsr set_via1
  jsr lcd_init

  STZ LED_STATUS        ;
  STZ MODE              ; monitor state 0=NONE
  STZ LCDPOS            ;

  LDA #<INPUT_ARGS
  STA ZP_ARGS
  LDA #>INPUT_ARGS
  STA ZP_ARGS+1

  jsr init_acia

  jsr set_message_startup
  jsr send_message_serial

prompt_loop:
  jsr show_prompt

  cli                   ; clear interrupt (enable)
  jsr loop

init_via:
  LDX #$0
  ; bring both ports of via to a known initial state
  ;
  JSR set_via1          ; VIA1 - LCD, LED
  ;
  LDA #%11111111        ; all pins output
  STA (ZP_VIA_DDRA,x)
  STA (ZP_VIA_DDRB,x)
  LDA #%00000000        ; all pins low
  STA (ZP_VIA_PORTA,x)
  STA (ZP_VIA_PORTB,x)

  JSR set_via2          ; VIA2 - sn76489
  ;
  LDA #%00000000
  STA (ZP_VIA_PORTA,x)
  LDA #%00000011        ; init pin 0 (/WE) as high (inactive)
  STA (ZP_VIA_PORTB,x)
  ; hard set both port a and b to output
  LDA #$ff
  STA (ZP_VIA_DDRA,x)
  LDA #%00000001 ; pin 0 is /WE (output so we can write it), 1 in RDY (input)
  STA (ZP_VIA_DDRB,x)

  RTS

show_prompt:
  JSR set_message_crlf
  JSR send_message_serial
  JSR set_message_prompt
  JSR send_message_serial
  RTS

loop:
  jmp loop

nmi:
  rti

irq:
  PHA
  PHX
  LDA ACIA_STATUS
  AND #$08 ; check for rx byte available
  BEQ irq_end

  LDA MODE                            ; check monitor state
  CMP #MODE_XMODEM_RECEIVE            ; if in xmodem then skip parsing
  BNE irq_not_xmodem
  LDA ACIA_DATA                       ; read character
  JSR write_acia_buffer               ; stuff character into buffer
  JMP irq_reset_end

irq_not_xmodem:
  LDA ACIA_DATA

  CMP #$1b              ; escape
  BNE key_escape_continue
  JMP key_escape
key_escape_continue:

  CMP #$7f              ; backspace
  BNE key_backspace_continue
  JMP key_backspace
key_backspace_continue:

  CMP #$0d              ; enter
  BNE key_enter_continue
  JMP key_enter
key_enter_continue:

  CMP #$60              ; backtick
  BNE key_backtick_continue
  JMP key_backtick
key_backtick_continue:

  CMP #$03              ; Control-C
  BNE perform_reset_continue
  JMP perform_reset
  ;JMP perform_break
perform_reset_continue:

  ; all other keys, ...
  JSR write_acia_buffer
  JSR print_char

  ; special keys are done.
  ; default action is to echo back
  STA ACIA_DATA
  JSR delay_6551

  ; check how much data is in Buffer
  JSR acia_buffer_diff
  CMP #$f0
  BCC irq_end

  JSR set_message_bufferfull
  JSR send_message_serial
  ; ; less than 0x0f (15) chars left, push rts down
  LDA #$01
  STA ACIA_COMMAND
  ; TODO what else should we do here? maybe soft reset or clear buffer.

  ;sta ACIA_DATA
  ; debugging; this sends a char to the lcd.
  ; it sends the same char indefinitely.
  ; lda #$41 ; "A"
  ; jsr print_char
  JMP irq_reset_end
irq_reset_end_prompt:
  JSR show_prompt
irq_reset_end:
  BIT ACIA_STATUS ; reset interrupt of ACIA
irq_end:
  PLX
  PLA
  RTI


  .include "xmodem-crc.s"

  .segment "VECTORS"
  .word nmi
  .word reset
  .word irq
