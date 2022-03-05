; test "hello world" which blinks all pins on port a of via 2
  .include "functions.cfg"
  .include "macros.cfg"


  .segment "USER"

  .import prompt_loop
  .import sys_led_on
  .import sys_led_off

  sys_start_userprogram

  JSR sys_led_on

  LDA #$FF
  LDY #$FF
  JSR delay_ay

  JSR sys_led_off

  sys_end_userprogram


delay_ay:
  CPY #1                ; (2)
  DEY                   ; (2)
  SBC #0                ; (2)
  BCS delay_ay          ; (3)
  RTS
