
  .include "globals.cfg"
  .include "functions.cfg"


sys_led_on:
  PHA
  PHX
  LDX #0
  LDA (ZP_VIA_DDRA,x)   ; read ddr for port b and save on stack
  PHA
  ORA #%1000000         ; set pin 7 to 1  (output)
  STA (ZP_VIA_DDRA,x)   ;
  LDA (ZP_VIA_PORTA,x)
  ORA #%10000000        ; set bit 7 to 1
  STA (ZP_VIA_PORTA,x)
  STA LED_STATUS        ; ensure led_status is always only ever bit 7
  PLA                   ; restore ddr and send
  STA (ZP_VIA_DDRA,x)
  PLX
  PLA
  RTS


sys_led_off:
  PHA
  PHX
  LDX #0
  LDA (ZP_VIA_DDRA,x)   ; read ddr for port b and save on stack
  PHA
  ORA #%10000000        ; set pin 7 to 1  (output)
  STA (ZP_VIA_DDRA,x)   ;
  LDA (ZP_VIA_PORTA,x)
  AND #%01111111        ; set bit 7 to 0
  STA (ZP_VIA_PORTA,x)
  STA LED_STATUS        ; ensure led_status is always only ever bit 7
  PLA                   ; restore ddr and send
  STA (ZP_VIA_DDRA,x)
  PLX
  PLA
  RTS


