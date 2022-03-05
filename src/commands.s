.ifndef _COMMAND_S_
_COMMAND_S_ = 1

;
COMMAND_BEEP:     .asciiz "beep"
COMMAND_CRASH:    .asciiz "crash"
COMMAND_DUMP:     .asciiz "dump"
COMMAND_HELP:     .asciiz "help"
COMMAND_JMP:      .asciiz "jmp"
COMMAND_LED:      .asciiz "led"
COMMAND_LOAD:     .asciiz "load"
COMMAND_READ:     .asciiz "read"
COMMAND_REBOOT:   .asciiz "reboot"
COMMAND_RUN:      .asciiz "run"
COMMAND_STATUS:   .asciiz "status"
COMMAND_WRITE:    .asciiz "write"
COMMAND_VERSION:  .asciiz "version"



MODEM_RECEIVE_FAILED    = $00
MODEM_RECEIVE_SUCCESS   = $01
MODEM_RECEIVE_CANCELLED = $02

  .include "zeropage.cfg"
  .include "xmodem.s"
  .include "sn76489.s"

; ref: http://prosepoetrycode.potterpcs.net/tag/6502/
; Arguments:
; $F0-$F1: First string
; $F2-$F3: Second string
; Returns A with comparison result:
; -1: First string is less than second
; 0: Strings are equal
; 1; First string is greater than second
strcmp:
  PHY
  LDY #$00
strcmp_load:
  LDA (ZP_COMMAND), Y   ; command we're comparing with
  CMP INPUT_COMMAND, Y  ; user input
  BNE strcmp_lesser
  INY
  CMP #NULL
  BNE strcmp_load
  LDA #EQUAL
  JMP strcmp_done
strcmp_lesser:
  BCS strcmp_greater
  LDA #LT
  JMP strcmp_done
strcmp_greater:
  LDA #GT
  JMP strcmp_done
strcmp_done:
  PLY
  RTS

check_command:

parse_command:
  PHA
  PHX
  PHY

  ; help
  LDA #<COMMAND_HELP
  STA ZP_COMMAND
  LDA #>COMMAND_HELP
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_help_continue
  JMP parse_command_help
parse_command_help_continue:

  ; version
  LDA #<COMMAND_VERSION
  STA ZP_COMMAND
  LDA #>COMMAND_VERSION
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_version_continue
  JMP parse_command_version
parse_command_version_continue:

  ; led
  LDA #<COMMAND_LED
  STA ZP_COMMAND
  LDA #>COMMAND_LED
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_led_continue
  JMP parse_command_led
parse_command_led_continue:

  ; status
  LDA #<COMMAND_STATUS
  STA ZP_COMMAND
  LDA #>COMMAND_STATUS
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_status_continue
  JMP parse_command_status
parse_command_status_continue:

  ; beep
  LDA #<COMMAND_BEEP
  STA ZP_COMMAND
  LDA #>COMMAND_BEEP
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_beep_continue
  JMP parse_command_beep
parse_command_beep_continue:

  ; crash
  LDA #<COMMAND_CRASH
  STA ZP_COMMAND
  LDA #>COMMAND_CRASH
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_crash_continue
  JMP parse_command_crash
parse_command_crash_continue:

  ; read
  LDA #<COMMAND_READ
  STA ZP_COMMAND
  LDA #>COMMAND_READ
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_read_continue
  JMP parse_command_read
parse_command_read_continue:

  ; reboot
  LDA #<COMMAND_REBOOT
  STA ZP_COMMAND
  LDA #>COMMAND_REBOOT
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_reboot_continue
  JMP parse_command_reboot
parse_command_reboot_continue:

 ; jmp
  LDA #<COMMAND_JMP
  STA ZP_COMMAND
  LDA #>COMMAND_JMP
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_jmp_continue
  JMP parse_command_jmp
parse_command_jmp_continue:

 ; run
  LDA #<COMMAND_RUN
  STA ZP_COMMAND
  LDA #>COMMAND_RUN
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_run_continue
  JMP parse_command_run
parse_command_run_continue:

  ; write
  LDA #<COMMAND_WRITE
  STA ZP_COMMAND
  LDA #>COMMAND_WRITE
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_write_continue
  JMP parse_command_write
parse_command_write_continue:

  ; dump
  LDA #<COMMAND_DUMP
  STA ZP_COMMAND
  LDA #>COMMAND_DUMP
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_dump_continue
  JMP parse_command_dump
parse_command_dump_continue:

  ; load
  LDA #<COMMAND_LOAD
  STA ZP_COMMAND
  LDA #>COMMAND_LOAD
  STA ZP_COMMAND+1
  JSR strcmp
  CMP #EQUAL
  BNE parse_command_load_continue
  JMP parse_command_load
parse_command_load_continue:

  ; default - unknown
  LDA #<message_unknown
  STA ZP_MESSAGE
  LDA #>message_unknown
  STA ZP_MESSAGE+1
  JSR send_message_serial
  JMP option_done

parse_command_help:
  LDA #<message_help
  STA ZP_MESSAGE
  LDA #>message_help
  STA ZP_MESSAGE+1
  JSR send_message_serial
  JMP option_done

parse_command_beep:
  JSR beep
  JMP option_done

parse_command_crash:
  JSR sound_crash
  JMP option_done

parse_command_version:
  LDA #<message_version
  STA ZP_MESSAGE
  LDA #>message_version
  STA ZP_MESSAGE+1
  JSR send_message_serial
  JMP option_done


; assuming via2 is active (left via)
parse_command_led:      ; toggle via 2, port b, pin 7
  LDX #0

  LDA (ZP_VIA_DDRA,x)   ; read ddr for port b and save on stack
  PHA
  ORA #%10000000        ; set pin 7 to 1  (output)
  STA (ZP_VIA_DDRA,x)   ;

  LDA (ZP_VIA_PORTA,x)
  EOR #%10000000        ; reverse bit 7
  STA (ZP_VIA_PORTA,x)
  AND #%10000000        ; set other bits to 0
  STA LED_STATUS        ; ensure led_status is always only ever bit 7

  PLA                   ; restore ddr and send
  STA (ZP_VIA_DDRA,x)

  LDA #<message_led     ; send toggle message
  STA ZP_MESSAGE
  LDA #>message_led
  STA ZP_MESSAGE+1
  JSR send_message_serial
  ;
  JMP option_done


parse_command_status:
  ; assuming led pin is in output mode
  LDA #<message_status
  STA ZP_MESSAGE
  LDA #>message_status
  STA ZP_MESSAGE+1
  JSR send_message_serial
  BIT LED_STATUS
  BMI status_led_on
status_led_off:
  LDA #<message_led_off
  STA ZP_MESSAGE
  LDA #>message_led_off
  STA ZP_MESSAGE+1
  JMP status_led_done
status_led_on:
  LDA #<message_led_on
  STA ZP_MESSAGE
  LDA #>message_led_on
  STA ZP_MESSAGE+1
status_led_done:
  JSR send_message_serial
  JMP option_done


parse_command_dump:
  ; use x as count of rows to print (stop at x==$10)
  PHA
  PHX

  STZ ZP_POINTER            ; default to $0000
  STZ ZP_POINTER+1

  JSR detect_args_1_nnnn
  TXA
  CMP #$00
  BEQ parse_command_dump_run

  JSR parse_args_1_nnnn     ; store location in ZP_POINTER

parse_command_dump_run:
  ;
  LDA #<message_read        ; print output header
  STA ZP_MESSAGE
  LDA #>message_read
  STA ZP_MESSAGE+1
  JSR send_message_serial
  ;
  LDX #0
dump_address_loop:
  JSR print_memory_line     ; print one row of memory
  INX                       ; increment row count
  CPX #$10                  ; stop after 16 rows
  BNE dump_address_loop
  PLX
  PLA
  JSR clear_input
  JMP option_done


print_memory_line:
  ; use y as count of bytes printed on line
  PHA
  PHY
  PHX
  LDA ZP_POINTER+1
  JSR print_byte
  LDA ZP_POINTER
  JSR print_byte
  ;
  LDA #':'
  STA ACIA_DATA
  JSR delay_6551
  LDA #' '
  STA ACIA_DATA
  JSR delay_6551

  LDY #0
print_memory_line_loop:
  LDA (ZP_POINTER)
  JSR print_byte        ; print this byte
  LDA #' '              ; space
  STA ACIA_DATA
  JSR delay_6551
  ; now increment pointer
  CLC
  LDA ZP_POINTER
  ADC #1
  STA ZP_POINTER
  LDA ZP_POINTER+1
  ADC #0
  STA ZP_POINTER+1
  ;
  INY                       ; increment loop counter
  CPY #$10                  ; we are done when we hit $10
  BNE print_memory_line_loop

  JSR set_message_crlf      ; go to next line
  JSR send_message_serial
  PLX
  PLY
  PLA
  RTS


parse_command_load:
  JSR set_message_crlf      ; go to next line
  JSR send_message_serial
  LDA #MODE_XMODEM_RECEIVE
  STA MODE
  JSR XModem
  ;CMP #(MODEM_RECEIVE_FAILED)
  ;BEQ parse_command_load
  STZ MODE
  JMP option_done


;
; read 1st argument (address) and place contents into ZP_POINTER
;
parse_args_1_nnnn:
  ; digit 3 and digit 2 are low and high nibble of low byte
  ; LDX #0
  LDA INPUT_ARGS+3
  JSR ascii_to_byte_low
  LDA INPUT_ARGS+2
  JSR ascii_to_byte_high
  STA ZP_POINTER
  ; digit 1 and digit 0 are low and high nibble of high byte
  ; LDX #0
  LDA INPUT_ARGS+1
  JSR ascii_to_byte_low
  LDA INPUT_ARGS+0
  JSR ascii_to_byte_high
  STA ZP_POINTER+1
  ;
  RTS

detect_args_1_nnnn:
  PHA
  ; detect if there are args here. if all four positions are not NULL = yes
  ; return results in x (0=no, 1=yes). used carry but cmp affects this bit
  LDA #$00 
  TAX
  SEC                       ; set carry flag (default)
  LDA INPUT_ARGS            ; read first character of argument
  CMP #$00                  ; null
  BEQ detect_args_1_nnnn_exit
  INX                       ; set x to 1
detect_args_1_nnnn_exit:
  PLA
  RTS

; 2nd argument 1 byte value placed into ARG_VALUE
parse_args_2_nn:
  LDA INPUT_ARGS+6      ; high nibble
  JSR ascii_to_byte_low
  LDA INPUT_ARGS+5      ; low nibble
  JSR ascii_to_byte_high
  STA ARG_VALUE
  RTS

;
; for now just assume address and we will read 16 bytes from
; that point
;
parse_command_read:
  STZ ZP_POINTER
  STZ ZP_POINTER+1

  LDA #<message_read    ; print output header
  STA ZP_MESSAGE
  LDA #>message_read
  STA ZP_MESSAGE+1
  JSR send_message_serial

  JSR parse_args_1_nnnn

  JSR print_memory_line
  JMP option_done


parse_command_jmp:
  STZ ZP_POINTER
  STZ ZP_POINTER+1

  LDA #<message_jmp    ; print output header
  STA ZP_MESSAGE
  LDA #>message_jmp
  STA ZP_MESSAGE+1
  JSR send_message_serial

  JSR parse_args_1_nnnn
  LDX #$00
  JMP (ZP_POINTER,x)


parse_command_run:
  LDA #<message_jmp    ; print output header
  STA ZP_MESSAGE
  LDA #>message_jmp
  STA ZP_MESSAGE+1
  JSR send_message_serial
  ;
  LDA #<RUN_ADDR
  STA ZP_POINTER
  LDA #>RUN_ADDR
  STA ZP_POINTER+1
  LDX #$00
  JMP (ZP_POINTER,x)


parse_command_jmp_return:
  LDA #<message_jmp_return    ; print output header
  STA ZP_MESSAGE
  LDA #>message_jmp_return
  STA ZP_MESSAGE+1
  JSR send_message_serial
  ;
  JSR print_memory_line
  JMP option_done


parse_command_reboot:
  LDA #<reset
  STA ZP_POINTER
  LDA #>reset
  STA ZP_POINTER+1
  LDX #$00
  JMP (ZP_POINTER,x)


; convert hex string (2 digits) to byte value
; input A (character)
; output X
ascii_to_byte_low:
  CLC
  SBC #$2f              ; substract 47, moving 0 to $0
  CMP #$a               ; check if we are less than $a (if not then we're A..F)
  BCC ascii_to_byte_low_done
  CLC
  SBC #$6               ; subtract another 7, moving 'A' to $a
  CMP #$a               ; check our new value (if still high then probably lower case)
  BCC ascii_to_byte_low_done
  CLC
  SBC #$1f              ; subtract another 31, moving 'a' to $a
ascii_to_byte_low_done:
  TAX
  RTS


; input A - high nibble character
; input X - value of low nibble
; output A as new value
ascii_to_byte_high:
  STX TEMP_VALUE        ; copy existing value to memory
  JSR ascii_to_byte_low
  TXA                   ; copy value of high nibble character to a
  ASL                   ; shift value left 4 bits (x16)
  ASL
  ASL
  ASL
  CLC
  ADC TEMP_VALUE        ; add back original value
  RTS

; input A
print_byte:
  PHA
  LSR A
  LSR A
  LSR A
  LSR A
  JSR print_byte_nibble
  PLA
print_byte_nibble:
  AND #%00001111        ; zero out top half
  TAX
  LDA hex_table,X
  STA ACIA_DATA
  JSR delay_6551
  RTS

parse_command_write:
  JSR parse_args_1_nnnn ; store location in ZP_POINTER
  JSR parse_args_2_nn   ; store value in ARG_VALUE
  LDA ARG_VALUE
  LDX #0
  STA (ZP_POINTER,x)
  JMP option_done

option_done:
  PLY
  PLX
  PLA
  RTS


; reminder --
; ORA #%01000000 - set bit 6 to 1
; AND #%10111111 - set bit 6 to 0
; EOR #%01000000 - reverse bit 6
; AND #%01000000 - if bit 6 is 0, then set overflow flag

hex_table:
  .byte "0123456789ABCDEF"

.endif
