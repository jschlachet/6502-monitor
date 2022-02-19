.ifndef _XMODEM_S_
_XMODEM_S_ = 1

; XMODEM/CRC Receiver for the 65C02
;
; By Daryl Rictor & Ross Archer  Aug 2002
;
; 21st century code for 20th century CPUs (tm?)
;
; A simple file transfer program to allow upload from a console device
; to the SBC utilizing the x-modem/CRC transfer protocol.  Requires just
; under 1k of either RAM or ROM, 132 bytes of RAM for the receive buffer,
; and 8 bytes of zero page RAM for variable storage.
;
;**************************************************************************
; This implementation of XMODEM/CRC does NOT conform strictly to the
; XMODEM protocol standard in that it (1) does not accurately time character
; reception or (2) fall back to the Checksum mode.

; (1) For timing, it uses a crude timing loop to provide approximate
; delays.  These have been calibrated against a 1MHz CPU clock.  I have
; found that CPU clock speed of up to 5MHz also work but may not in
; every case.  Windows HyperTerminal worked quite well at both speeds!
;
; (2) Most modern terminal programs support XMODEM/CRC which can detect a
; wider range of transmission errors so the fallback to the simple checksum
; calculation was not implemented to save space.
;**************************************************************************
;
; Files uploaded via XMODEM-CRC must be
; in .o64 format -- the first two bytes are the load address in
; little-endian format:
;  FIRST BLOCK
;     offset(0) = lo(load start address),
;     offset(1) = hi(load start address)
;     offset(2) = data byte (0)
;     offset(n) = data byte (n-2)
;
; Subsequent blocks
;     offset(n) = data byte (n)
;
; The TASS assembler and most Commodore 64-based tools generate this
; data format automatically and you can transfer their .obj/.o64 output
; file directly.
;
; The only time you need to do anything special is if you have
; a raw memory image file (say you want to load a data
; table into memory). For XMODEM you'll have to
; "insert" the start address bytes to the front of the file.
; Otherwise, XMODEM would have no idea where to start putting
; the data.

;-------------------------- The Code ----------------------------
;
; zero page variables (adjust these to suit your needs)
;
;
;7D00
crc			=	$38 ; 38		; CRC lo byte  (two byte variable)
crch		=	$39 ; 39		; CRC hi byte

ptr			=	$3a		; data pointer (two byte variable)
ptrh		=	$3b		;   "    "

blkno		=	$3c		; block number
retry		=	$3d		; retry counter
retry2	=	$3e		; 2nd counter
bflag		=	$3f		; block flag
;
;
; non-zero page variables and buffers
;
;
Rbuff		=	$0600      	; temp 132 byte receive buffer
;(place anywhere, page aligned)
;
;
;  tables and constants
;
;
; The crclo & crchi labels are used to point to a lookup table to calculate
; the CRC for the 128 byte data blocks.  There are two implementations of these
; tables.  One is to use the tables included (defined towards the end of this
; file) and the other is to build them at run-time.  If building at run-time,
; then these two labels will need to be un-commented and declared in RAM.
;
; crclo		=	$7D00      	; Two 256-byte tables for quick lookup
; crchi		= $7E00      	; (should be page-aligned for speed)
;
;
;
; XMODEM Control Character Constants
SOH		=	$01		; start block
EOT		=	$04		; end of text marker
ACK		=	$06		; good block acknowledged
NAK		=	$15		; bad block acknowledged
CAN		=	$18		; cancel (not standard, not supported)
CR		=	$0d		; carriage return
LF		=	$0a		; line feed
ESC		=	$1b		; ESC to exit

;
;^^^^^^^^^^^^^^^^^^^^^^ Start of Program ^^^^^^^^^^^^^^^^^^^^^^
;
; Xmodem/CRC upload routine
; By Daryl Rictor, July 31, 2002
;
; v0.3  tested good minus CRC
; v0.4  CRC fixed!!! init to $0000 rather than $FFFF as stated
; v0.5  added CRC tables vs. generation at run time
; v 1.0 recode for use with SBC2
; v 1.1 added block 1 masking (block 257 would be corrupted)

;		*= 	$7B00		; Start of program (adjust to your needs)
;
XModem:
		SEI											; prevent interrupts
		LDA #'X'
		JSR send_char
		JSR lcd_clear
		JSR print_char

		jsr	PrintMsg	; send prompt and info
		lda	#$01
		sta	blkno		; set block # to 1
		sta	bflag		; set flag to get address from block 1
StartCrc:
		lda	#'C'		; "C" start with CRC mode
		JSR	Put_Chr		; send it
		JSR print_char					; debug print to lcd
		lda	#$FF
		sta	retry2		; set loop counter for ~3 sec delay
		lda	#$00
		sta	crc
		sta	crch		; init CRC value
		jsr	GetByte		; wait for input
		bcs	GotByte		; byte received, process it
		bcc	StartCrc	; resend "C"

StartBlk:
		PHA											; debug
		LDA #'B'								; debug
		JSR print_char					; debug
		PLA											; debug
		lda	#$FF								;
		sta	retry2							; set loop counter for ~3 sec delay
		lda	#$00								;
		sta	crc									;
		sta	crch								; init CRC value
		jsr	GetByte							; get first byte of block
		bcc	StartBlk						; timed out, keep waiting...
GotByte:
		cmp	#ESC		; quitting?
		bne	GotByte1	; no
;		lda	#$FE		; Error code in "A" of desired
		brk			; YES - do BRK or change to RTS if desired
GotByte1:
		cmp	#SOH			; start of block?
		beq	BegBlk		; yes
		cmp	#EOT			;
		bne	BadCrc		; Not SOH or EOT, so flush buffer & send NAK
		jmp	Done			; EOT - all done!
BegBlk:
		ldx	#$00
GetBlk:
		lda	#$ff			; 3 sec window to receive characters
		sta 	retry2		;
GetBlk1:
		jsr	GetByte		; get next character
		bcc	BadCrc		; chr rcv error, flush and send NAK
GetBlk2:
		sta	Rbuff,x		; good char, save it in the rcv buffer
		inx				   	; inc buffer pointer
		cpx	#$84			; <01> <FE> <128 bytes> <CRCH> <CRCL>
		bne	GetBlk		; get 132 characters
		ldx	#$00			;
		lda	Rbuff,x		; get block # from buffer
		cmp	blkno			; compare to expected block #
		beq	GoodBlk1	; matched!
		jsr	Print_Err	; Unexpected block number - abort
		jsr	Flush			; mismatched - flush buffer and then do BRK
;		lda	#$FD		; put error code in "A" if desired
		brk						; unexpected block # - fatal error - BRK or RTS
GoodBlk1:
		eor	#$ff			; 1's comp of block #
		inx			;
		cmp	Rbuff,x		; compare with expected 1's comp of block #
		beq	GoodBlk2 	; matched!
		jsr	Print_Err	; Unexpected block number - abort
		jsr 	Flush		; mismatched - flush buffer and then do BRK
;		lda	#$FC		; put error code in "A" if desired
		brk						; bad 1's comp of block#
GoodBlk2:
		PHA											; debug
		LDA #'Y'								; debug
		JSR print_char					; debug
		PLA											; debug
		ldy	#$02		;
CalcCrc:
		lda	Rbuff,y		; calculate the CRC for the 128 bytes of data
		jsr	UpdCrc		; could inline sub here for speed
		iny			;
		cpy	#$82			; 128 bytes
		bne	CalcCrc		;
		lda	Rbuff,y		; get hi CRC from buffer
		cmp	crch		; compare to calculated hi CRC
		bne	BadCrc		; bad crc, send NAK
		iny			;
		lda	Rbuff,y		; get lo CRC from buffer
		cmp	crc				; compare to calculated lo CRC
		beq	GoodCrc		; good CRC
BadCrc:
		jsr	Flush			; flush the input port
		PHA											; debug
		LDA #'N'								; debug
		JSR print_char 					; debug
		PLA											; debug
		lda	#NAK			;
		jsr	Put_Chr		; send NAK to resend block
		jmp	StartBlk	; start over, get the block again
GoodCrc:
		PHA											; debug
		LDA #'Y'								; debug
		JSR print_char 					; debug
		PLA											; debug

		ldx	#$02			;
		lda	blkno			; get the block number
		cmp	#$01			; 1st block?
		bne	CopyBlk		; no, copy all 128 bytes
		lda	bflag			; is it really block 1, not block 257, 513 etc.
		beq	CopyBlk		; no, copy all 128 bytes
		lda	Rbuff,x		; get target address from 1st 2 bytes of blk 1
		sta	ptr				; save lo address
		inx						;
		lda	Rbuff,x		; get hi address
		sta	ptr+1			; save it
		inx						; point to first byte of data
		dec	bflag			; set the flag so we won't get another address
CopyBlk:
		ldy	#$00		; set offset to zero
CopyBlk3:
		lda	Rbuff,x		; get data byte from buffer
		sta	(ptr),y		; save to target
		inc	ptr		; point to next address
		bne	CopyBlk4	; did it step over page boundary?
		inc	ptr+1		; adjust high address for page crossing
CopyBlk4:
		inx			; point to next data byte
		cpx	#$82		; is it the last byte
		bne	CopyBlk3	; no, get the next one
IncBlk:
		inc	blkno		; done.  Inc the block #
		lda	#ACK		; send ACK
		jsr	Put_Chr		;
		jmp	StartBlk	; get next block
Done:
		lda	#ACK		; last block, send ACK and exit.
		jsr	Put_Chr		;
		jsr	Flush		; get leftover characters, if any
		jsr	Print_Good	;
		CLI							; clear interrupt disable                                JSS
		rts			;
;
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;
; subroutines
;
;					
;

; from krisos
acia_get_char:
	CLC                         ; no chr present
	LDA ACIA_STATUS             ; get Serial port status
	AND #$08                    ; mask rcvr full bit
	BEQ acia_get_char_done      ; if not chr, done
	LDA ACIA_DATA               ; else get chr
	SEC                         ; and set the Carry Flag
acia_get_char_done:
	RTS                         ; done
;
;
;
;


; JSR acia_buffer_diff        ; check pointer different
; BEQ read_acia_buffer_done   ; if buffer empty then exit
; JSR read_acia_buffer

GetByte:
		; LDA #'.'								; print debug
		; JSR print_char					;
		lda	#$00								; wait for chr input and cycle timing loop
		sta	retry								; set low value of timing loop
StartCrcLp:
    JSR acia_get_char       ; get chr from serial port, don't wait
    BCS GetByte1            ; got one, so exit
    DEC retry               ; no character received, so dec counter
    BNE StartCrcLp          ;
    DEC retry2              ; dec hi byte of counter
    BNE StartCrcLp          ; look for character again
    CLC                     ; if loop times out, CLC, else SEC and return
GetByte1:
		; PHA											;
		; LDA #'.'								; print debug
		; JSR print_char					;
		; PLA											;
		rts			; with character in "A"
;
Flush:
		lda	#$70		; flush receive buffer
		sta	retry2		; flush until empty for ~1 sec.
Flush1:
		jsr	GetByte		; read the port
		bcs	Flush		; if chr recvd, wait for another
		rts			; else done
;
PrintMsg:
		ldx	#$00		; PRINT starting message
PrtMsg1:
		lda   	Msg,x
		beq	PrtMsg2
		JSR send_char
		;jsr	Put_Chr
		inx
		bne	PrtMsg1
PrtMsg2:
		rts
Msg:
		.byte	"Begin XMODEM/CRC transfer.  Press <Esc> to abort..."
		.BYTE  	CR, LF
		.byte   0
;
Print_Err:
		ldx	#$00		; PRINT Error message
PrtErr1:
		lda   	ErrMsg,x
		beq	PrtErr2
		jsr	Put_Chr
		inx
		bne	PrtErr1
PrtErr2:
		rts
ErrMsg:
		.byte 	"Upload Error!"
		.BYTE  	CR, LF
		.byte   0
;
Print_Good:
		ldx	#$00		; PRINT Good Transfer message
Prtgood1:
		lda   	GoodMsg,x
		beq	Prtgood2
		jsr	Put_Chr
		inx
		bne	Prtgood1
Prtgood2:
		rts
GoodMsg:
		.byte 	"Upload Successful!"
		.BYTE  	CR, LF
		.byte   0
;
;
;======================================================================
;  I/O Device Specific Routines
;
;  Two routines are used to communicate with the I/O device.
;
; "Get_Chr" routine will scan the input port for a character.  It will
; return without waiting with the Carry flag CLEAR if no character is
; present or return with the Carry flag SET and the character in the "A"
; register if one was present.
;
; "Put_Chr" routine will write one byte to the output port.  Its alright
; if this routine waits for the port to be ready.  its assumed that the
; character was send upon return from this routine.
;
; Here is an example of the routines used for a standard 6551 ACIA.
; You would call the ACIA_Init prior to running the xmodem transfer
; routine.
;
; these are in acia.cfg
	.include "acia.cfg"
; ACIA_DATA	=	$7F70		; Adjust these addresses to point
; ACIA_STATUS	=	$7F71		; to YOUR 6551!
; ACIA_COMMAND	=	$7F72		;
; ACIA_CONTROL	=	$7F73		;

; ACIA_Init:
; 	lda	#$1F           	; 19.2K/8/1
; 	sta	ACIA_CONTROL   	; control reg
; 	lda	#$0B           	; N parity/echo off/rx int off/ dtr active low
; 	sta	ACIA_COMMAND   	; command reg
; 	rts                  	; done
;
; input chr from ACIA (no waiting)
;
Get_chr:
	clc									; no chr present
	lda	ACIA_STATUS     ; get Serial port status
	and	#$08            ; mask rcvr full bit
	beq	Get_chr2				; if not chr, done
	Lda	ACIA_DATA       ; else get chr
	sec									; and set the Carry Flag
Get_chr2:
	rts			; done
;
; output to OutPut Port
;
Put_Chr:
acia_put_char:
    PHA
acia_put_char_loop:
Put_Chr1:
    LDA ACIA_STATUS             ; serial port STA tus
    AND #$10                    ; is tx buffer empty
    BEQ acia_put_char_loop      ; no, go back and test it again
    PLA                         ; yes, get chr to send
    STA ACIA_DATA               ; put character to Port
    RTS                         ; done


;=========================================================================
;
;
;  CRC subroutines
;
;
UpdCrc:
	eor 	crc+1 				; Quick CRC computation with lookup tables
	tax		 							; updates the two bytes at crc & crc+1
	lda 	crc						; with the byte send in the "A" register
	eor 	CRCHI,X
	sta 	crc+1
	lda 	CRCLO,X
	sta 	crc
	rts
;
; Alternate solution is to build the two lookup tables at run-time.  This might
; be desirable if the program is running from ram to reduce binary upload time.
; The following code generates the data for the lookup tables.  You would need to
; un-comment the variable declarations for crclo & crchi in the Tables and Constants
; section above and call this routine to build the tables before calling the
; "xmodem" routine.
;
;MAKECRCTABLE
;		ldx 	#$00
;		LDA	#$00
;zeroloop	sta 	crclo,x
;		sta 	crchi,x
;		inx
;		bne	zeroloop
;		ldx	#$00
;fetch		txa
;		eor	crchi,x
;		sta	crchi,x
;		ldy	#$08
;fetch1		asl	crclo,x
;		rol	crchi,x
;		bcc	fetch2
;		lda	crchi,x
;		eor	#$10
;		sta	crchi,x
;		lda	crclo,x
;		eor	#$21
;		sta	crclo,x
;fetch2		dey
;		bne	fetch1
;		inx
;		bne	fetch
;		rts
;
;
;
; End of File
;
.endif
