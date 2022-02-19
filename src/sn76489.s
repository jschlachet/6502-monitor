.ifndef _SN76489_S_
_SN76489_S_ = 1


; Connected to VIA1 (right)
;
; Port A  ----> PA0 PA1 PA2 PA3 PA4 PA5 PA6 PA7 PB0 PB1
; SN76489 ---->  D7  D6  D5  D4  D3  D2  D1  D0 /WE RDY
;

; SN76489 Register Writes
;
; %lcctdddd
;             l    = data/latch (0=data, 1=latch)
;             cc   = channel
;             t    = type (0=data, 1=tone/noise)
;             dddd = data



  .include "via.s"
SN_READY = %00000010 ; ready pin


sound_mute:
  PHA

  jsr set_via2
  LDX #0
  ;
  ; set all volumes to off (full attenuation)
  ;
  LDA #%10011111  ; latch channel 00 volume 1111
  STA (ZP_VIA_PORTA,x)

  JSR strobe_we_bar
  JSR delay_200us
  JSR delay_200us

  LDA #%10111111  ; latch channel 01 volume 1111
  STA (ZP_VIA_PORTA,x)

  JSR strobe_we_bar
  JSR delay_200us
  JSR delay_200us

  LDA #%11011111  ; latch channel 10 volume 1111
  STA (ZP_VIA_PORTA,x)

  JSR strobe_we_bar
  JSR delay_200us
  JSR delay_200us

  LDA #%11111111  ; latch channel 11 volume 1111
  STA (ZP_VIA_PORTA,x)

  JSR strobe_we_bar
  JSR delay_200us
  JSR delay_200us

  jsr set_via1

  PLA
  RTS

many_delays:
  JSR delay_25ms
  JSR delay_25ms
  RTS

strobe_we_bar:
  PHA
  PHX
  LDX #0
  LDA #%00000001  ; strobe /we
  STA (ZP_VIA_PORTB,x)
  LDA #%00000000
  STA (ZP_VIA_PORTB,x)
  LDA #%00000001  ; strobe /we
  STA (ZP_VIA_PORTB,x)
  PLX
  PLA
  RTS

wait_sn_ready:
  PHA
  PHX
  LDX #0
wait_sn_ready_loop:
  LDA (ZP_VIA_PORTB,x)
  AND #%00000010 ; #SN_READY
  BNE wait_sn_ready_loop
  PHX
  PHA
  RTS

  ;                      Input clock (Hz) (3579545)
  ;  Frequency (Hz) = ----------------------------------
  ;                    2 x register value x divider (16)

; N = 125000/f

beep:
  ; 440 ->     125000/440=284 -> 010001 1100
  PHA
  PHX
  JSR set_via2

  LDX #0
  LDA #%10001100        ; latch, channel 00, 0=tone, 1110= low 4 bits
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR many_delays
  LDA #%00010001        ; data, channel 00, 0=tone, 001111= high 6 bits
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR many_delays

  LDA #%10010000        ; latch, channel 00, 1=vol, 0000 = full volume
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR delay_200us

  JSR many_delays
  JSR many_delays

  JSR sound_mute        ; mute
  JSR set_via1
  PLX
  PLA
  RTS

sound_chord:
  PHA
  PHX
  JSR set_via2

  LDX #0

  ;
  ; chord (N=125000/freq)
  ; C4	261.63 = 448 -> 011100 0000
  ; E4	329.63 = 379 -> 010111 1011
  ; G4	392.00 = 319 -> 010011 1111
  LDA #%10000000        ; latch, channel 00, 0=tone, 1110= low 4 bits
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR many_delays
  LDA #%00011100        ; data, channel 00, 0=tone, 001111= high 6 bits
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR many_delays

  LDA #%10101011        ; latch, channel 01, 0=tone, 1110= low 4 bits
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR many_delays
  LDA #%00010111        ; data, channel 01, 0=tone, 001111= high 6 bits
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR many_delays

  LDA #%11001111        ; latch, channel 10, 0=tone, 1110= low 4 bits
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR many_delays
  LDA #%00010011        ; data, channel 10, 0=tone, 001111= high 6 bits
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR many_delays

  LDA #%10010000        ; latch, channel 00, 1=vol, 0000 = full volume
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR delay_200us
  LDA #%10110000        ; latch, channel 01, 1=vol, 0000 = full volume
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR delay_200us
  LDA #%11010000        ; latch, channel 01, 1=vol, 0000 = full volume
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR many_delays
  JSR many_delays
  JSR many_delays

  JSR sound_mute      ; mute

  JSR set_via1
  PLX
  PLA
  RTS

sound_crash:
  PHA
  PHX
  PHY
  JSR set_via2

  LDX #0

  LDA #%11100101        ; latch, channel 11, noise, data 0101
  STA (ZP_VIA_PORTA,x)

  JSR strobe_we_bar
  JSR many_delays

  LDA #%11110000        ; latch channel 11 volume 0000 (max)
  STA (ZP_VIA_PORTA,x)

  JSR strobe_we_bar
  JSR many_delays

  LDY #0
sound_crash_loop:       ; increase attenuation from $0 to $f
  TYA
  STA (ZP_VIA_PORTA,x)
  JSR strobe_we_bar
  JSR many_delays
  INY
  CPY #$10
  BNE sound_crash_loop

  JSR sound_mute        ; make sure all channels are muted
  JSR set_via1
  PLY
  PLX
  PLA
  RTS

.endif
