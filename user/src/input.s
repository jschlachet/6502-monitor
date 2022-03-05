; test "hello world" which blinks all pins on port a of via 2
.segment "USER"

  .include "zeropage.cfg"
  .include "globals.cfg"
  .include "macros.cfg"

  .import prompt_loop
  .import send_message_serial

  .import sys_lcd_init
  .import sys_lcd_clear
  .import sys_lcd_printchar
  .import sys_user_input
  .import copy_buffer_to_input_args


  sys_start_userprogram

  sys_serial_print message_test

  JSR sys_user_input              ; user input

  sys_serial_print message_test2

  JSR copy_buffer_to_input_args   ; debug

  sys_serial_print INPUT_ARGS
 
  sys_end_userprogram


message_test:    .byte "Input text prompt: ", $00 ; CR LF NULL
message_test2:   .byte $0d, $0a, "Text was: ", $00, $0d, $0a
