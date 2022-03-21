;
; SPI Playground
;
; Device is ENC28J60,
; "Stand-Alone Ethernet Controller with SPI Interface"
; from Microchip

; VIA                 DIR SPI_DEVICE  Scopy
; ---- -------------- --- ----------- -----
; PA2  SELECT_BAR     ->  CS_B         4/green
; PA7  MISO           <-  SO           2/purple
; PA1  MOSI           ->  SI           3/blue
; PA0  SER CLK        ->  CLK          1/yellow

; As suggested by the datasheet, SP and INT_NB
; are put through a 74HCT08 to help level shift

; "You can use any I/O bits you want, but I chose the ones above 
; because again bit 0 of a port is the easiest and quickest to 
; pulse in software (using INC and DEC), and bit 6 or 7 of a port
; are easiest to test (using the BIT instruction)."  Garth Wilson

; ref: http://wilsonminesco.com/6502primer/potpourri.html

VIA3 = $4800

VIA3_PORTB = VIA3
VIA3_PORTA = VIA3+1
VIA3_DDRB  = VIA3+2
VIA3_DDRA  = VIA3+3
VIA3_T1C_L = VIA3+4
VIA3_T1C_H = VIA3+5
VIA3_T1L_L = VIA3+6
VIA3_T1L_H = VIA3+7
VIA3_T2C_L = VIA3+8
VIA3_T2C_H = VIA3+9
VIA3_SR    = VIA3+10 ; shift register
VIA3_ACR   = VIA3+11 ; aux control register
VIA3_PCR   = VIA3+12 ; peripheral control register
VIA3_IFR   = VIA3+13 ; interrupt flag register
VIA3_IER   = VIA3+14 ; interrupt enable register
VIA3_REG1  = VIA3+15 ; PORTA without handshake

.macro ENC28J60_SELECTED
  LDA VIA3_PORTA
  AND #%11111011            ; set pa2 low
  STA VIA3_PORTA
.endmacro

.macro ENC28J60_UNSELECTED
  LDA VIA3_PORTA
  ORA #%00000100            ; set pa2 high
  STA VIA3_PORTA
  JSR small_delay
  JSR small_delay
  JSR small_delay

.endmacro



ENC28J60_REG_ECON1_DFLTS = %000000000 ; 

; instructions              ; descr                     5 bit arg   byte 1 and following
ENC28J60_RCR    = %00000000 ; read control register     address     N/A
ENC28J60_RBM    = %00111010 ; read buffer memory        --          N/A
ENC28J60_WCR    = %01000000 ; write control register    address     data
ENC28J60_WBM    = %01111010 ; write buffer memory       --          data
ENC28J60_BFS    = %10000000 ; bit field set             address     data
ENC28J60_BFC    = %10100000 ; bit field clear           address     data
ENC28J60_SRC    = %11111111 ; soft reset                --          N/A

; registers - bank 0
ENC28J60_REG_ETXSTL   = $04
ENC28J60_REG_ETXSTH   = $05
ENC28J60_REG_ERXSTL   = $08 
ENC28J60_REG_ERXSTH   = $09
ENC28J60_REG_EIE      = $1B
ENC28J60_REG_EIR      = $1C
ENC28J60_REG_ESTAT    = $1D
ENC28J60_REG_ECON2    = $1E
ENC28J60_REG_ECON1    = $1F

; registers - bank 1
ENC28J60_REG_ERXFCON  = $18

; registers - bank 2
ENC28J80_REG_MACON1   = $00
ENC28J80_REG_MACON3   = $02
ENC28J80_REG_MACON4   = $03
ENC28J60_REG_MABBIPG  = $04
ENC28J60_REG_MAIPGL   = $06
ENC28J60_REG_MAMXFLL  = $0a
ENC28J60_REG_MAMXFLH  = $0b

; registers - bank 3
ENC28J60_REG_EREVID   = $12


BSEL_BANK3 = $03 ; %00000011
BSEL_BANK2 = $02 ; %00000010
BSEL_BANK1 = $01 ; %00000001
BSEL_BANK0 = $00 ; %00000000



; register 6-1 macon1: mac control register 1
MACON1_TXPAUS       = %00001000
MACON1_RXPAUS       = %00000100
MACON1_PASSALL      = %00000010
MACON1_MARXEN       = %00000001


 ; 6.5.2 Configure the PADCFG, TXCRCEN and FULDPX bits of MACON3. 
  ; Most applications should enable automatic padding to at least 60 
  ; bytes and always append a valid CRC

; register 6-2 macon3: mac control register 3
MACON3_PADCFG_DFLT  = %11100000 ; all short frames zero padded to 64 bytes and valid crc appended
MACON3_TXCRCEN      = %00010000
MACON3_PHDREN       = %00001000
MACON3_HFRMEN       = %00000100
MACON3_FRMLNEN      = %00000010
MACON3_FULDPX       = %00000001

; register 6-3 macon4: mac control register 4
MACON4_DEFER        = %01000000

; register 8-1 erxfcon: ethernet receive filter control register
ERXFCON_UCEN        = %10000000
ERXFCON_ANDOR       = %01000000
ERXFCON_CRCEN       = %00100000
ERXFCON_PMEN        = %00010000
ERXFCON_MPEN        = %00001000
ERXFCON_HTEN        = %00000100
ERXFCON_MCEN        = %00000010
ERXFCON_BCEN        = %00000001


.segment "USER"

  .include "zeropage.cfg"
  .include "globals.cfg"
  .include "macros.cfg"





  .import prompt_loop
  .import send_message_serial


  sys_start_userprogram

  sys_serial_print message_spi_start

  JSR spi_init
  JSR get_rev_id
  
  sys_serial_print message_spi_end

  sys_end_userprogram


; MAC ADDRESS
mac_address: .byte $11, $22, $33, $44, $55, $66
;


get_rev_id:
  LDA #BSEL_BANK3
  JSR select_bank                           ; 0x5F
  ENC28J60_SELECTED
  LDA #(ENC28J60_RCR|ENC28J60_REG_EREVID)   ; 0x12
  JSR enc28j60_write_byte
  ;
  JSR enc28j60_read_byte
 ;
  ENC28J60_UNSELECTED


  RTS


spi_tx_broadcast:
  ; 1. Appropriately program the ETXST pointer to point to an unused
  ;    location in memory. It will point to the per packet control
  ;    byte. In the example, it would be programmed to 0120h. It is
  ;    recommended that an even address be used for ETXST.
  ; 2. Use the WBM SPI command to write the per packet control byte,
  ;    the destination address, the source MAC address, the
  ;    type/length and the data payload.
  ; 3. Appropriately program the ETXND pointer. It should point to the
  ;    last byte in the data payload.  In the example, it would be
  ;    programmed to 0156h.
  ; 4. Clear EIR.TXIF, set EIE.TXIE and set EIE.INTIE to enable an
  ;    interrupt when done (if desired).
  ; 5. Start the transmission process by setting
  ;    ECON1.TXRTS.
  RTS


spi_init: 
  LDA #%00000100 ; CS high (inactive) everything else low
  STA VIA3_PORTA
  LDA #%00000111  ; CLK, MOSI, CS outputs, MISO (pa7) input
  STA VIA3_DDRA

  ; section numbers refer to the ENC28J60 datasheet.

  ; 6.1 receive buffer must be initialized by programming the ERXST 
  ; and ERXND Pointers. All memory between and including the ERXST 
  ; and ERXND addresses will be dedicated to the receive hardware

  ; these start at ERXSTL and go in this order: 
  ; 1. ERXST low    (receive buffer start)
  ; 2. ERXST high
  ; 3. ERXND low    (receive buffer end)
  ; 4. ERXND high

  LDA #BSEL_BANK0
  JSR select_bank
   
  ENC28J60_SELECTED

  LDA #(ENC28J60_WCR|ENC28J60_REG_ERXSTL)   ; start at erxst low byte
  JSR enc28j60_write_byte                   ;
  LDA #$00                                  ; ERXST LO
  JSR enc28j60_write_byte                   ;
  LDA #$00                                  ; ERXST HI
  JSR enc28j60_write_byte                   ;
  LDA #$ff                                  ; ERXND LO
  JSR enc28j60_write_byte                   ;
  LDA #$0f                                  ; ERXND HI
  JSR enc28j60_write_byte                   ;

  ENC28J60_UNSELECTED

  ; 6.2 All memory which is not used by the receive buffer is 
  ; considered the transmission buffer
 
  ; 6.3 The appropriate receive filters should be enabled or disabled
  ; by writing to the ERXFCON register. See Section 8.0 "Receive 
  ; Filters" for information on how to configure it.

  LDA #BSEL_BANK1
  JSR select_bank
  ENC28J60_SELECTED
  ; select erxst low byte
  LDA #(ENC28J60_WCR|ENC28J60_REG_ERXFCON)
  JSR enc28j60_write_byte
  ; enable unicast filter
  ; discard invalid crc
  ; enable broadcast
  LDA #(ERXFCON_UCEN|ERXFCON_CRCEN|ERXFCON_BCEN)
  JSR enc28j60_write_byte
  ;
  ENC28J60_UNSELECTED

  ; 6.5.1 Set the MARXEN bit in MACON1 to enable the MAC to receive
  ; frames. If using full duplex, most applications should also set 
  ; TXPAUS and RXPAUS to allow IEEE defined flow control to function.

  LDA #BSEL_BANK2
  JSR select_bank
  ENC28J60_SELECTED
  ; select macon1 low byte
  LDA #(ENC28J60_WCR|ENC28J80_REG_MACON1)
  JSR enc28j60_write_byte
  ; enable pause control frame tx
  ; enable pause control frame rx
  ; enable mac receive
  LDA #(MACON1_TXPAUS|MACON1_RXPAUS|MACON1_MARXEN)
  JSR enc28j60_write_byte
  ;
  ENC28J60_UNSELECTED


  ; 6.5.2 Configure the PADCFG, TXCRCEN and FULDPX bits of MACON3. 
  ; Most applications should enable automatic padding to at least 60 
  ; bytes and always append a valid CRC

  ; (still bank 2)
  ; LDX #BSEL_BANK2
  ; JSR select_bank
  ENC28J60_SELECTED
  ; select macon1 low byte
  LDA #(ENC28J60_WCR|ENC28J80_REG_MACON3)
  JSR enc28j60_write_byte
  ; all short frames will be zero padded to 64 bytes and a valid CRC will then be appended
  ; enable transmit crc 
  LDA #(MACON3_PADCFG_DFLT|MACON3_TXCRCEN)
  JSR enc28j60_write_byte
  ;
  ENC28J60_UNSELECTED


  ; 6.5.3 Configure the bits in MACON4. For conformance to the IEEE
  ; 802.3 standard, set the DEFER bit

  ; (still bank 2)
  ; LDX #BSEL_BANK2
  ; JSR select_bank
  ENC28J60_SELECTED
  ; select macon1 low byte
  LDA #(ENC28J60_WCR|ENC28J80_REG_MACON4)
  JSR enc28j60_write_byte
  ; all short frames will be zero padded to 64 bytes and a valid CRC will then be appended
  ; enable transmit crc 
  LDA #(MACON4_DEFER)
  JSR enc28j60_write_byte
  ;
  ENC28J60_UNSELECTED

  ; 6.5.4 Program the MAMXFL registers with the maximum frame 
  ; length to be permitted to be received or transmitted. [max 1518]

  ; (still bank 2)
  ; LDX #BSEL_BANK2
  ; JSR select_bank
  ENC28J60_SELECTED
  LDA #(ENC28J60_WCR|ENC28J60_REG_MAMXFLL)
  JSR enc28j60_write_byte
  LDA #$ee
  JSR enc28j60_write_byte
  LDA #$05
  JSR enc28j60_write_byte
  ENC28J60_UNSELECTED

  ; 6.5.5 Configure the Back-to-Back Inter-Packet Gap register, 
  ; MABBIPG. Most applications will program this register with 15h
  ; when Full-Duplex mode is used and 12h when Half-Duplex mode is 
  ; used.

  ; (still bank 2)
  ; LDX #BSEL_BANK2
  ; JSR select_bank
  ENC28J60_SELECTED
  LDA #(ENC28J60_WCR|ENC28J60_REG_MABBIPG)
  JSR enc28j60_write_byte
  LDA #$15; recommendation from datasheet
  JSR enc28j60_write_byte
  ENC28J60_UNSELECTED

  

  ; 6.5.6 Configure the Non-Back-to-Back Inter-Packet Gap register 
  ; low byte, MAIPGL. Most applications will program this register 
  ; with 12h

  ; (still bank 2)
  ; LDX #BSEL_BANK2
  ; JSR select_bank
  ENC28J60_SELECTED
  LDA #(ENC28J60_WCR|ENC28J60_REG_MAIPGL)
  JSR enc28j60_write_byte
  LDA #$12 ; recommendation from datasheet
  JSR enc28j60_write_byte
  ENC28J60_UNSELECTED


  ; 6.5.7 If half duplex is used, the Non-Back-to-Back Inter-Packet 
  ; Gap register high byte, MAIPGH, should be programmed. Most 
  ; applications will program this register to 0Ch.

  ; 6.7.8. If Half-Duplex mode is used, program the Retransmission 
  ; and Collision Window registers, MACLCON1 and MACLCON2. Most 
  ; applications will not need to change the default Reset values. 
  ; If the network is spread over exceptionally long cables, the 
  ; default value of MACLCON2 may need to be increased.

  ; 6.5.9. Program the local MAC address into the MAADR1:MAADR6 
  ; registers.

  ENC28J60_SELECTED
  ; set register bank
  LDA #BSEL_BANK3
  JSR select_bank
  LDA mac_address+4 
  JSR enc28j60_write_byte
  LDA mac_address+5
  JSR enc28j60_write_byte
  LDA mac_address+2 
  JSR enc28j60_write_byte
  LDA mac_address+3 
  JSR enc28j60_write_byte
  LDA mac_address
  JSR enc28j60_write_byte
  LDA mac_address+1 
  JSR enc28j60_write_byte
  ;
  ENC28J60_UNSELECTED
  sys_serial_print message_enc28j60_init
  RTS


; ============================================================================================================




select_bank:
  PHA
  ; bank number in X
  ENC28J60_SELECTED
  LDA #(ENC28J60_WCR|ENC28J60_REG_ECON1)  ; write econ1
  JSR enc28j60_write_byte
  PLA
  ORA #ENC28J60_REG_ECON1_DFLTS
  JSR enc28j60_write_byte
  ENC28J60_UNSELECTED
  RTS


; ETH_BYTE ($0305)
enc28j60_read_byte:
  STZ ETH_BYTE              ; initialize byte
  LDX #$08

erb_loop:
  JSR enc28j60_clock_pulse
  
  BIT VIA3_PORTA            ; read pa7 on via3 (MOSI) [bit 7 goes to N)
  BMI erb_bit_one
erb_bit_zero:
  CLC                       ; clear carry
  JMP erb_shift
erb_bit_one:
  SEC                       ; set carry
erb_shift:
  ROL ETH_BYTE              ; rotate left, LSB inherits carry bit
  DEX
  BNE erb_loop
erb_done:
  RTS


enc28j60_write_byte:
  ; byte expected in accumulator
  LDX #$08                  ; counter for bit loop
ewb_loop:
  ASL                       ; shift left, high bit into carry
  BCS ewb_bit_one
ewb_bit_zero:
  PHA                       ; put a aside, we need to send pa1 low
  LDA #%00000000            ; 
  STA VIA3_PORTA
  JMP ewb_done
ewb_bit_one:
  PHA                       ; put a aside, we need to send pa1 low
  LDA #%00000010            ; pa1 high
  STA VIA3_PORTA
ewb_done:
  JSR enc28j60_clock_pulse
 
  PLA
  DEX
  BNE ewb_loop
  RTS

enc28j60_clock_pulse:
  INC VIA3_PORTA
  JSR small_delay
  DEC VIA3_PORTA
  JSR small_delay
  RTS


small_delay:
  PHX
  LDX #$02
sd_loop:
  NOP
  DEX
  BNE sd_loop
  PLX
  RTS


message_spi_start:      .byte "SPI test starting.", $0d, $0a, $00
message_spi_end:        .byte "SPI test exiting.", $0d, $0a, $00
message_enc28j60_init:  .byte  "ENC28J60 intialized.", $0d, $0a, $00
message_enc28j60_rev:   .byte "Ethernet Revisoin ID ", $00
