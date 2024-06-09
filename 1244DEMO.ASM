;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;1244DEMO -- DS1244 Phantom RTC Demo Program
;
;Copyright (c) 2024 Glitch Works, LLC
;http://www.glitchwrks.com
;
;See LICENSE included in the project root for licensing
;information.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Phantom RTC Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCRATCH	equ	0C000H		;Upper 32K memory, A14 high

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CP/M Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ASCII Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CTLC	equ	03
BS	equ	08
LF	equ	10
CR	equ	13

	ORG	4000H		;A14 must be high since *RST may not be
				;disabled yet.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;START -- Get ready to interact with Phantom RTC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:	LXI	SP, 5000H	;Private stack, A14 high
	
;	CALL	UNLOCK		;Send the unlock sequence	
;	LXI	H, SETTIM	;Set the time
;	CALL	SHIFTO

	CALL	UNLOCK		;Send the unlock sequence
	LXI	H, RTCBUF	;Read the RTC registers into a buffer
	CALL	SHIFTI

	JMP	0F000H		;Back to GWMON, cold start to restore
				;stack

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CLEAR -- Ensure the Phantom RTC interface is clear
;
;Read 65 bytes from the NVRAM/RTC scratch area to ensure
;any pending RTC register interaction is definitely cleared.
;After 65 reads, the RTC is ready for UNLOCK.
;
;Destroys contents of A and B registers.
;
;pre: none
;post: phantom RTC is ready for unlock sequence
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CLEAR:	MVI	B, 65
CLEAR1:	LDA	SCRATCH
	DCR	B
	JNZ	CLEAR1
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;UNLOCK -- Unlock Phantom RTC for access
;
;Falls into SHIFTO.
;
;pre: none
;post: phantom RTC is unlocked and ready for read or write
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UNLOCK:	CALL	CLEAR		;Clear the RTC pattern pointer
	LXI	H, PATTRN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SHIFTO -- Shift buffer out to Phantom RTC
;
;This routine shifts out 8 bytes at HL to the phantom RTC.
;
;Destroys contents of registers A, B, C.
;
;pre: HL points to 8 bytes to shift out
;post: 64 bits shifted out to phantom RTC
;post: HL points to end of shift buffer + 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SHIFTO:	MVI	B, 8		;D = buffer counter
SHFTO1:	MVI	C, 8		;C = byte shift counter
	MOV	A, M		;A = byte to shift out
SHFTO2:	STA	SCRATCH		;Write to RTC DQ0
	RRC			;Rotate right for next bit
	DCR	C		;Decrement shift counter
	JNZ	SHFTO2		;Not done with byte, shift more
	INX	H		;Increment buffer pointer
	DCR	B		;Decrement buffer counter
	JNZ	SHFTO1		;More bytes in buffer to shift
	RET			;All bytes shifted, done

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SHIFTI -- Shift Phantom RTC data into buffer
;
;This routine reads 64 bits from the phantom RTC and shfits
;it into the buffer at HL as 8 bytes.
;
;pre: HL points to 8-byte buffer
;pre: phantom RTC is ready to be read
;post: buffer contains 8 bytes shifted in from phantom RTC
;post: HL point to end of shift buffer + 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SHIFTI:	MVI	D, 8		;D = buffer counter
SHFTI1:	MVI	C, 8		;C = byte shift counter
SHFTI2:	LDA	SCRATCH		;Get bit to shift in
	RRC			;Store DQ0 in CY flag
	MOV	A, M		;Get current buffer byte
	RAR			;Rotate CY into high bit
	MOV	M, A		;Store it in buffer
	DCR	C		;Decrement shift counter
	JNZ	SHFTI2		;Not done with byte, shift more
	INX	H		;Increment buffer pointer
	DCR	D		;Decrement buffer counter
	JNZ	SHFTI1		;More bytes in buffer to shift
	RET			;All bytes shifted, done

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PATTRN -- Phantom RTC access pattern
;
;Dallas/Maxim/Analog states that this bitstream pattern has
;been chosen as it has less than a 1 in 10^19 chance of 
;appearing in random data.
;
;Unlock pattern is shifted into DQ0 in the phantom RTC
;memory region, LSB to MSB.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PATTRN:	db 0C5H, 03AH, 0A3H, 05CH, 0C5H, 03AH, 0A3H, 05CH

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SETTIM -- Set the time to start of UNIX epoch
;
;This data block will set the Phantom RTC to 00:00:00.00 on
;01 JAN 1970. It sets 24-hour mode, enables the RTC 
;oscillator, and disables the *RST input, which is shared 
;with address line A14.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SETTIM:	db 00H			;0 fractional sections
	db 00H			;0 seconds
	db 00H			;0 minutes
	db 00H			;Midnight, 24-hour mode
	db 15H			;Oscillator on, reset disabled, Thursday
	db 01H			;First day of the month
	db 01H			;January
	db 70H			;1970 (no century)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RTCBUF -- Buffer space for phantom RTC operations
;
;This buffer is used to store data for serialization and
;deserialization when reading and writing to the phantom RTC
;registers. All eight 8-bit registers must be read or
;written.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RTCBUF	equ	05000H		;Hardcoded for debug
;RTCBUF:	ds 8		;Dynamic buffer allocation

	END