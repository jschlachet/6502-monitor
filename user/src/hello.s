; test "hello world" which blinks all pins on port a of via 2
.segment "USER"

  .include "zeropage.cfg"
  .include "macros.cfg"


  .import prompt_loop
  .import send_message_serial

  .import sys_lcd_init
  .import sys_lcd_clear
  .import sys_lcd_printchar

  sys_start_userprogram
  sys_serial_print message_test

  
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

  sys_end_userprogram



message_test:    .byte "Hello, world.", $00 ; CR LF NULL

