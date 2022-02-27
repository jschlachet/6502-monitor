; test "hello world" which blinks all pins on port a of via 2
.segment "USER"

  .include "zeropage.cfg"

  .import prompt_loop
  .import send_message_serial

  .import sys_lcd_init
  .import sys_lcd_clear
  .import sys_lcd_printchar


  .word $3000               ; put origin at the top of the output binary file
  .org $3000

  LDA #<message_test     ; send toggle message
  STA ZP_MESSAGE
  LDA #>message_test
  STA ZP_MESSAGE+1
  JSR send_message_serial
  
  
  JSR sys_lcd_init
  JSR sys_lcd_clear

  LDA #$48 ; H
  JSR sys_lcd_printchar
  LDA #$65 ; e
  JSR sys_lcd_printchar
  LDA #$6c ; l
  JSR sys_lcd_printchar
  JSR sys_lcd_printchar
  LDA #$6f ; o
  JSR sys_lcd_printchar

  JMP prompt_loop



message_test:    .byte "Hello, world.", $00 ; CR LF NULL

