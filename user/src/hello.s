; test "hello world" which blinks all pins on port a of via 2
.segment "USER"

  .include "zeropage.cfg"

  .import prompt_loop
  .import send_message_serial

  .word $3000               ; put origin at the top of the output binary file
  .org $3000

  LDA #<message_test     ; send toggle message
  STA ZP_MESSAGE
  LDA #>message_test
  STA ZP_MESSAGE+1
  JSR send_message_serial

  JMP prompt_loop

message_test:    .byte $0d, $0a, "This is a second compiled program.", $0d, $0a, $00 ; CR LF NULL

