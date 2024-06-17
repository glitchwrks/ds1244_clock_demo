;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;1244LIB -- DS1244 Phantom RTC Communications Library
;
;This file can be included in programs that need to access
;a Dallas Phantom RTC. It includes functions for unlocking,
;reading, and writing to the Phantom RTC.
;
;Programs INCLUDEing this library must set the SCRATCH
;equate. SCRATCH should be an address in the Phantom RTC 
;memory area that keeps A14 set high, in case *RST is not
;yet disabled.
;
;RTCBUF can be located anywhere outside Phantom RTC memory.
;By default, it is reserved at the end of this file, but 
;RTCBUF can be set to a static address to make debugging 
;easier.
;
;Copyright (c) 2024 Glitch Works, LLC
;http://www.glitchwrks.com
;
;See LICENSE included in the project root for licensing
;information.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
;Falls into RTCWR.
;
;pre: none
;post: phantom RTC is unlocked and ready for read or write
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UNLOCK:	CALL	CLEAR		;Clear the RTC pattern pointer
	LXI	H, PATTRN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RTCWR -- Write buffer out to Phantom RTC
;
;This routine shifts out 8 bytes at HL to the phantom RTC.
;
;Destroys contents of registers A, B, C.
;
;pre: HL points to 8 byte buffer to write to RTC registers
;post: 64 bits shifted out to phantom RTC
;post: HL points to end of buffer + 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RTCWR:	MVI	B, 8		;D = buffer counter
RTCWR1:	MVI	C, 8		;C = byte shift counter
	MOV	A, M		;A = byte to shift out
RTCWR2:	STA	SCRATCH		;Write to RTC DQ0
	RRC			;Rotate right for next bit
	DCR	C		;Decrement shift counter
	JNZ	RTCWR2		;Not done with byte, shift more
	INX	H		;Increment buffer pointer
	DCR	B		;Decrement buffer counter
	JNZ	RTCWR1		;More bytes in buffer to shift
	RET			;All bytes shifted, done

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RTCRD -- Read Phantom RTC data into buffer
;
;This routine reads 64 bits from the phantom RTC and shfits
;it into the buffer at HL as 8 bytes.
;
;Destroys contents of registers A, B, C.
;
;pre: HL points to 8-byte buffer to read RTC registers into
;pre: phantom RTC is unlocked and ready to be read
;post: buffer contains 8 bytes shifted in from phantom RTC
;post: HL point to end of buffer + 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RTCRD:	MVI	B, 8		;D = buffer counter
RTCRD1:	MVI	C, 8		;C = byte shift counter
RTCRD2:	LDA	SCRATCH		;Get bit to shift in
	RRC			;Store DQ0 in CY flag
	MOV	A, M		;Get current buffer byte
	RAR			;Rotate CY into high bit
	MOV	M, A		;Store it in buffer
	DCR	C		;Decrement shift counter
	JNZ	RTCRD2		;Not done with byte, shift more
	INX	H		;Increment buffer pointer
	DCR	B		;Decrement buffer counter
	JNZ	RTCRD1		;More bytes in buffer to shift
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
;RTCBUF -- Buffer space for phantom RTC operations
;
;This buffer is used to store data for serialization and
;deserialization when reading and writing to the phantom RTC
;registers. All eight 8-bit registers must be read or
;written.
;
;RTCBUF must be located outside the memory area associated
;with the phantom RTC, and should reside in an address range
;that keeps A14 set high, so that phantom RTCs that have
;*RST enabled on pin 1 are not reset during accesses. 
;
;RTCBUF can be defined before 1244COMM is included.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	IFNDEF	RTCBUF
RTCBUF:	ds 8			;Dynamic buffer allocation after program
	ENDIF
