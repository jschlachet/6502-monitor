;
; LCD 1602 in 4-bit mode and connected solely to PORT A
;
; Execellent notes:
; http://web.alfredstate.edu/faculty/weimandn/lcd/lcd_initialization/lcd_initialization_index.html

; zero page pointers to hold addresses for the target via device.
;

  .include "zeropage.cfg"
  .include "acia.cfg"

lcd_init:
  PHA                   ;
  LDX #0                ; will be using X=0 repeatedly
  LDA (ZP_VIA_DDRA,x)
  PHA
  ; set port a to input except pin 7
  ; we are setting pin 7 to input so we dont change its output here
  LDA #%11111111        ; set all pins to 1 (input)
  STA (ZP_VIA_DDRA,x)   ; set direction register
  LDA #$00
  STA (ZP_VIA_PORTA,x)  ; also initialize port a

  ; 1. Wait at least 100ms after power-on
  JSR delay_25ms
  JSR delay_25ms
  JSR delay_25ms
  JSR delay_25ms

  ; 2. Write 0x03 to LCD and wait 5 msecs
  LDA #$03
  STA (ZP_VIA_PORTA,x)
  JSR lcd_instruction_nowait
  JSR delay_5ms

  ; 3. Write 0x03 to LCD and wait 200 usecs
  LDA #$03
  STA (ZP_VIA_PORTA,x)
  JSR lcd_instruction_nowait
  JSR delay_200us

  ; 4. Write 0x03 to LCD and wait 160 usecs (or poll the busy flag)
  LDA #$03
  STA (ZP_VIA_PORTA,x)
  JSR lcd_instruction_nowait
  JSR delay_200us

  ; 5. Write 0x02 to enable 4-bit mode.
  LDA #$02
  STA (ZP_VIA_PORTA,x)
  JSR lcd_instruction_nowait
  JSR delay_200us

  ; -- at this point every command will take two nibble writes --

  ; 6. function set - Write set interface length
  LDA #$02              ; 001 (Function Set_, DL=0 (4-bit)
  JSR lcd_instruction
  LDA #$08              ; N=1 (2 lines), F=0 (5x8 font), X, X
  JSR lcd_instruction_nowait

  ; 7. Write 0x01/0x00 to turn off the Display
  LDA #$00
  JSR lcd_instruction
  LDA #$08
  JSR lcd_instruction_nowait

  ; 8. Write 0x00/0x01 to clear the Display;
  LDA #$00
  JSR lcd_instruction
  LDA #$01
  JSR lcd_instruction_nowait
  JSR lcd_wait

  ; 9. Write Set Cursor Move Direction setting cursor behavior bits
  LDA #$00
  JSR lcd_instruction
  LDA #$06
  JSR lcd_instruction_nowait

  ; 10. lcd initialization is now complete
  ; lcd is busy for a while here

  ; 11. Write Enable Display/Cursor to enable display and optional cursor
  LDA #$00
  JSR lcd_instruction
  LDA #$0e
  JSR lcd_instruction_nowait

  PLA
  STA (ZP_VIA_DDRA,x)   ; restore ddra from copy saved to stack
  PLA
  RTS

lcd_clear:
  JSR set_via1
  PHA
  PHX

  LDX #0                ;
  LDA (ZP_VIA_DDRA,x)   ; save original state of ddra
  PHA

  LDA #%11111111        ; set all pins to 1 (output)
  STA (ZP_VIA_DDRA,x)   ; set direction register

  ; 8. Write 0x00/0x01 to clear the Display;
  LDA #$00
  JSR lcd_instruction
  LDA #$01
  JSR lcd_instruction_nowait
  JSR lcd_wait

  PLA
  STA (ZP_VIA_DDRA,x)   ; restore ddra from copy saved to stack

  PLX
  PLA
  RTS

; precise delay routine by dclxvi in the 6502 forums.
; A and Y are high and low bytes of a 16 bit value.
; cycle count == multiply 16bit value by 9, then add 8.
; Ref: http://forum.6502.org/viewtopic.php?f=12&t=5271&start=0#p62581
; 15ms = (9*1666)+8 --> 00000110 10000010 $06 $82
;
delay_ay:
  CPY #1                ; (2)
  DEY                   ; (2)
  SBC #0                ; (2)
  BCS delay_ay          ; (3)
  RTS

delay_5ms:
  PHA
  PHY
  LDA #$02
  LDY #$2b
  JSR delay_ay
  PLY
  PLA
  RTS

delay_200us:
  PHA
  PHY
  LDA #$00
  LDY #$11
  JSR delay_ay
  PLY
  PLA
  RTS

delay_15ms:
  PHA
  PHY
  LDA #$06
  LDY #$82
  JSR delay_ay
  PLY
  PLA
  RTS

delay_25ms:
  PHA
  PHY
  LDA #$0b
  LDY #$67
  JSR delay_ay
  PLY
  PLA
  RTS



; for now we're just going to clobber 7. we should read,
; change the bits we need to modify, and then store.
lcd_wait:
  PHA
  LDX #0
  LDA #%11110000        ; pin 7 always output, 6..4 output, 3..0 input
  STA (ZP_VIA_DDRA,x)
lcd_busy:
  LDA #RW
  JSR preserve_led_state; restore bit 7 to state from led
  STA (ZP_VIA_PORTA,x)
  LDA #(RW | E)
  JSR preserve_led_state; restore bit 7 to state from led
  STA (ZP_VIA_PORTA,x)
  LDA (ZP_VIA_PORTA,x)  ; read port a
  ; since we're in 4bit mode, reads come in as two nibbles
  ; save what we got and do another read
  ; then pull back what we read first (high nibble)
  PHA
  LDA LED_STATUS        ; load led state and apply rw
  ORA #RW
  ;
  STA (ZP_VIA_PORTA,x)
  LDA LED_STATUS
  ORA #(RW | E)
  STA (ZP_VIA_PORTA,x)
  LDA (ZP_VIA_PORTA,x)  ; read port a
  PLA                   ; pull first nibble since it should have D7 (busy)

  AND #%00001000        ; check D7 (shifted right by four)
  BNE lcd_busy

  LDA #%11111111        ; set all pins to output
  STA (ZP_VIA_DDRA,x)   ; store new state to ddr

  ; reset port a to known state
  LDA LED_STATUS
  STA (ZP_VIA_PORTA,x)

  PLA
  RTS

lcd_instruction:
  JSR lcd_wait
  JSR lcd_instruction_nowait
  RTS

lcd_instruction_nowait:
  JSR preserve_led_state; restore bit 7 to state from led
  STA (ZP_VIA_PORTA,x)
  ORA #E                ; set E bit
  STA (ZP_VIA_PORTA,x)
  AND #CLEAR_E          ; clear E bit
  STA (ZP_VIA_PORTA,x)
  RTS

preserve_led_state:
  BIT LED_STATUS
  BMI led_on
  AND #%01111111        ; clear bit 7
  JMP led_preserved
led_on:
  ORA #%10000000        ; set bit 7
led_preserved:
  RTS


print_char:
  ; wrapper for original print_char. use current lcd positon
  ; to wrap if at the end of line 1 (16) or end of line 2 (56)
  ; assuming 16x2 lcd which is internally 40x2
  PHA
  LDA LCDPOS
  CMP #$10 ; 16 (end of 1st line)
  BEQ advance_24
  LDA LCDPOS
  CMP #$38 ; 56 (end of 2nd line)
  BEQ reset_pos
  JMP now_print_char
advance_24:
  PHX
  LDX #$18
  LDA #' '
advance_25_loop:
  JSR print_char2
  DEX
  BNE advance_25_loop
  PLX
  JMP now_print_char
reset_pos:
  JSR lcd_clear
  STZ LCDPOS
now_print_char:
  PLA
  JSR print_char2
  RTS


print_char2:
  PHX
  PHA                   ; push two copies onto stack
  PHA                   ;
  JSR save_via
  JSR set_via1
  JSR lcd_wait

  ; a contrains character to print
  LDX #0                ; needed for indirect addressing

  LSR a                 ; logical shift right 4 bits
  LSR a
  LSR a
  LSR a

  JSR preserve_led_state; restore bit 7 to state from led

  ORA #RS               ; send high nibble first with RS set
  STA (ZP_VIA_PORTA,x)
  ORA #(E|RS)                ; set E bit
  STA (ZP_VIA_PORTA,x)
  AND #CLEAR_E_RW_RS          ; clear control bits
  STA (ZP_VIA_PORTA,x)

  PLA                   ; pull copy of A back from stack

  AND #%00001111        ; clear upper nibble
  JSR preserve_led_state; restore bit 7 to state from led

  ORA #RS               ; set RS bit
  STA (ZP_VIA_PORTA,x)
  ORA #(E|RS)           ; set RS and E
  STA (ZP_VIA_PORTA,x)
  AND #CLEAR_E_RW_RS          ; clear E
  STA (ZP_VIA_PORTA,x)

  PLA                   ; restore a as we return
  PLX
  JSR restore_via
  INC LCDPOS            ; increment lcd position
  RTS


; skip on $0d, $0a
send_message_lcd:
  PHA
  PHY
  LDY #0
send_message_lcd_next:
  LDA (ZP_MESSAGE),y
  BEQ send_message_lcd_done
  CMP #$0d
  BEQ send_message_lcd_skip
  CMP #$0a
  BEQ send_message_lcd_skip
  JSR print_char
send_message_lcd_skip:
  INY
  jmp send_message_lcd_next
send_message_lcd_done:
  ; go to 2nd line
  ; only if message is not prompt
  LDA #<message_prompt  ; check high byte of address
  CMP $08
  BNE send_message_lcd_exit
  LDA #>message_prompt  ; check low byte of addres
  CMP $09
  BNE send_message_lcd_exit
  LDA #$c               ; move to 2nd line on lcd
  JSR lcd_instruction_nowait
  LDA #$0               ;
  JSR lcd_instruction
send_message_lcd_exit:
  PLY
  PLA
  RTS
