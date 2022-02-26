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
  .include "functions.s"



reset:
  ldx #$ff                  ; initiatlize stack pointer
  txs

  jsr init_ram
  jsr init_run_vector       ; initialize code at run location   (init to prompt_loop)

  jsr init_via

  jsr sound_mute

  jsr set_via1
  jsr lcd_init

  STZ LED_STATUS            ;
  STZ MODE                  ; monitor state 0=NONE
  STZ LCDPOS                ;

  LDA #<INPUT_ARGS
  STA ZP_ARGS
  LDA #>INPUT_ARGS
  STA ZP_ARGS+1

  jsr init_acia

  jsr set_message_startup
  jsr send_message_serial

  jsr init_display


prompt_loop:
  jsr clear_input
  jsr show_prompt
  cli                       ; clear interrupt (enable)
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
perform_reset_continue:

  ; all other keys, ...
  JSR write_acia_buffer
  ;JSR print_char  ; display char on lcd 

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


init_ram:
  STZ ZP_POINTER        ; $0000 zero page
  STZ ZP_POINTER+1
  JSR init_ram_block

  LDA #$02              ; $0200 (acia buffer)
  STA ZP_POINTER+1
  JSR init_ram_block

  LDA #$03              ; $0300 (global variables)
  STA ZP_POINTER+1
  JSR init_ram_block

  LDX #$30              ; $3000 - $3fff (user program space)
init_ram_loop:          ;
  STX ZP_POINTER+1      ;
  JSR init_ram_block    ;
  INX                   ; next page
  CPX #$40              ; stop if we've reached $4000
  BNE init_ram_loop     ;

init_ram_done:
  RTS

init_run_vector:
  LDA #$4C              ; JMP 
  STA RUN_ADDR+0 
  LDA #<prompt_loop     ; store low byte of prompt_loop address
  STA RUN_ADDR+1
  LDA #>prompt_loop     ; store high byte of prompt_loop address
  STA RUN_ADDR+2
  RTS

  ; Modified from http://www.6502.org/source/general/clearmem.htm
init_ram_block:
  PHA
  PHX
  PHY
  LDA #$ff
  TAX
  LDA #$00                ; Set up zero value
  TAY                     ; Initialize index pointer
init_ram_block_loop:
  STA (ZP_POINTER),Y             ; Clear memory location
  INY                     ; Advance index pointer
  DEX                     ; Decrement counter
  BNE init_ram_block_loop ; Not zero, continue checking
  PLY
  PLX
  PLA
  RTS                     ; Return

clear_input:
  ; clear input variables, INPUT_COMMAND and INPUT_ARGS both 16 bytes
  PHA

  LDA #<INPUT_COMMAND
  STA ZP_POINTER
  LDA #>INPUT_COMMAND
  STA ZP_POINTER+1
  JSR clear_16bytes       ; clear input_command

  STZ INPUT_ARGS
  STZ INPUT_ARGS+1
  STZ INPUT_ARGS+2
  STZ INPUT_ARGS+3

  ; TODO not sure if this is effective
  STZ ZP_POINTER          ; clear our pointer
  STZ ZP_POINTER+1

  PLA
  RTS

clear_16bytes:
  PHY
  LDA #$00                ; store zero in A and Y
  TAY                     ;
clear_16bytes_loop:
  STA (ZP_POINTER),y
  INY
  CPY #$10
  BNE clear_16bytes_loop
  PLY
  RTS

  
  .include "xmodem-crc.s"

  .segment "VECTORS"
  .word nmi
  .word reset
  .word irq
