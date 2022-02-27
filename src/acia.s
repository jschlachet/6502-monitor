;
;
;

  .include "commands.s"
  .include "zeropage.cfg"

init_acia:
  PHA
  LDA #$00
  STA ACIA_STATUS
  LDA #%00001001        ; $09 - No parity, no echo, interrupt enabled
  STA ACIA_COMMAND
  LDA #%00011111        ; $1f - 1 stop bit, 8 data bits, 19200 baud
  STA ACIA_CONTROL
  JSR init_acia_buffer  ; initialize buffer and pointers
  PLA
  RTS


init_acia_buffer:
  PHX                   ; save x
  STZ ACIA_RD_PTR       ; zero out read pointer
  STZ ACIA_WR_PTR       ; zero out write pointer
  LDX #$ff              ; start x at top of buffer
init_acia_buffer_loop:
  STZ ACIA_BUFFER,x     ; zero out buffer at x
  DEX                   ; decrement x
  BMI init_acia_buffer_done ; branch if negative (backwards past zero)
  JMP init_acia_buffer_loop
init_acia_buffer_done:
  PLX
  RTS

send_char:
  STA ACIA_DATA
  JSR delay_6551
  RTS

send_message_serial:
  PHA
  PHY
  LDY #0
send_message_serial_next:
  LDA (ZP_MESSAGE),y
  BEQ send_message_serial_done
  STA ACIA_DATA
  JSR delay_6551
  INY
  jmp send_message_serial_next
send_message_serial_done:
  BIT ACIA_STATUS       ; TRY TO CLEAR STATUS
  PLY
  PLA
  RTS

set_message_empty:
  PHA
  LDA #<message_empty
  STA $08
  LDA #>message_empty
  STA $09
  PLA
  RTS

set_message_startup:
  PHA
  LDA #<message_startup
  STA $08
  LDA #>message_startup
  STA $09
  PLA
  RTS

set_message_buffer:
  PHA
  LDA #<message_buffer
  STA $08
  LDA #>message_buffer
  STA $09
  PLA
  RTS

set_message_crlf:
  PHA
  LDA #<message_crlf
  STA $08
  LDA #>message_crlf
  STA $09
  PLA
  RTS

set_message_bufferfull:
  PHA
  LDA #<message_bufferfull
  STA $08
  LDA #>message_bufferfull
  STA $09
  PLA
  RTS

set_message_prompt:
  PHA
  LDA #<message_prompt
  STA $08
  LDA #>message_prompt
  STA $09
  PLA
  RTS

set_message_help:
  PHA
  LDA #<message_help
  STA $08
  LDA #>message_help
  STA $09
  PLA
  RTS


;
delay_6551:
  phy
  phx
delay_loop:
  ldy #1
minidly:
  ldx #$68
delay_1:
  dex
  bne delay_1
  dey
  bne minidly
  plx
  ply
delay_done:
  rts

;
; Buffer Routines
;
write_acia_buffer:      ; store char into buffer and increment pointer
  LDX ACIA_WR_PTR
  STA ACIA_BUFFER, x
  INC ACIA_WR_PTR
  RTS
read_acia_buffer:       ; read char from buffer and move pointer
  LDX ACIA_RD_PTR
  LDA ACIA_BUFFER, x
  INC ACIA_RD_PTR
  RTS
acia_buffer_diff:       ; subtract buffer pointers. if there's a difference then written and need to read
  LDA ACIA_WR_PTR
  SEC
  SBC ACIA_RD_PTR
  RTS

perform_reset:
;   JMP reset
; perform_break:
  PHA
  LDA #<message_break
  STA $08
  LDA #>message_break
  STA $09
  JSR send_message_serial
  PLA
  JMP prompt_loop

key_escape:             ; $f0
  LDA #$0               ; clear display $01
  JSR lcd_instruction_nowait
  LDA #$1
  JSR lcd_instruction
  LDA ACIA_WR_PTR       ; load write pointer
  STA ACIA_RD_PTR       ; store to read pointer (empty buffer)
  LDA #$0d              ; ASCII CR
  STA ACIA_DATA
  JSR delay_6551
  LDA #$0a              ; ASCII LF
  STA ACIA_DATA
  JSR delay_6551
  JMP irq_reset_end

key_backspace:          ; $7f
  JSR acia_buffer_diff  ; check pointers
  BEQ key_backspace_end ; if buffer empty then exit
  DEC ACIA_WR_PTR       ; decrement write pointer by one
  JSR send_backspace_serial
key_backspace_end:
  JMP irq_reset_end

key_backtick:           ; $60
  JSR print_buffer
  JSR init_acia_buffer
  JMP irq_reset_end

key_enter:              ; $0d
  ;
  PHA
  PHX
  PHY

  JSR acia_buffer_diff  ; is buffer empty?
  BEQ key_enter_exit    ; silently exit and loop

  ; pull base command into INPUT_COMMAND
  LDY #0
key_enter_loop:
  JSR read_acia_buffer
  STA INPUT_COMMAND,y
  INY
  JSR acia_buffer_diff
  BNE key_enter_loop
  ;BEQ key_enter_done
key_enter_done:
  LDA #$00                ; add NULL to end of string
  STA INPUT_COMMAND,y        ;

  JSR copy_args
  ; parse command
  JSR parse_command
  JSR init_acia_buffer
  JMP key_enter_exit
key_enter_exit:           ; ready to exit
  ;jsr lcd_clear
  ;
  PLY
  PLX
  PLA
  JMP irq_reset_end_prompt

;
; take user input, truncates it at the first space
; and copies the remainder to INPUT_ARGS
; !! no length checking here !!
;
copy_args:
  PHA
  PHX
  PHY

  LDY #0                ; position in input
copy_args_loop:
  LDA INPUT_COMMAND,y      ; inspect char
  CMP #0                ; null
  BEQ copy_args_end     ; if null then shortcut to the end

  INY
  CMP #' '              ; space
  BNE copy_args_loop    ; if no space yet then keep going
  DEY                   ; decrement y once
  ; at the space now
  LDA #0                ;
  STA INPUT_COMMAND,Y      ; put null where the space was
  INY                   ; forward to first char of arguments

  JSR set_message_crlf
  JSR send_message_serial

  LDX #0                ; position in args
copy_to_args_loop:
  LDA INPUT_COMMAND,Y      ; load char from input
  STA INPUT_ARGS,X      ; store char in args
  INY
  INX
  CMP #0                ; was it a null?
  BNE copy_to_args_loop
copy_args_end:
  PLY
  PLX
  PLA
  RTS

send_backspace_serial:
  LDA #$08              ; ASCII BS
  STA ACIA_DATA
  JSR delay_6551
  LDA #$20              ; ASCII space
  STA ACIA_DATA
  JSR delay_6551
  LDA #$08              ; ASCII BS
  STA ACIA_DATA
  JSR delay_6551
  RTS

print_buffer_contents:
  PHA
  PLA
  RTS



print_buffer:
  PHA
  PHX
  ;
  JSR acia_buffer_diff
  BEQ print_buffer_empty
  JSR set_message_buffer      ; set message to output
  JSR send_message_serial            ; send message
read_acia_buffer_loop:
  JSR read_acia_buffer        ; read char from buffer
  STA ACIA_DATA               ; output to serial console
  JSR delay_6551
  ;
  JSR acia_buffer_diff        ; check pointer different
  BEQ read_acia_buffer_done   ; if buffer empty then exit
  JMP read_acia_buffer_loop
read_acia_buffer_done:
  ;
  JSR set_message_crlf        ; set message to CRLF
  JSR send_message_serial

print_buffer_end:
  PLX
  PLA
  RTS

print_buffer_empty:
  JSR set_message_empty
  JSR send_message_serial
  JMP print_buffer_end
