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
MODEMSK	equ	10000000B	;12/24 hour mode bit mask
AMPMMSK	equ	00100000B	;AM/PM bit mask
HRMSK12	equ	00011111B	;Hour bits mask
HRMSK24	equ	00111111B	;Hour bits mask
OSCMSK	equ	00100000B	;Oscillator control bit mask
RSTMSK	equ	00010000B	;*RST control bit mask
DAYMSK	equ	00000111B	;Day-of-week bits mask
SCRATCH	equ	0C000H		;Upper 32K memory, A14 high

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GWMON-80 Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GWMON	equ	0F000H		;Start of GWMON-80
MONOUT	equ	GWMON+6H	;Monitor character out routine
MONIN	equ	GWMON+9H	;Monitor character in routine

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
;	LXI	H, INIRTC	;Set the RTC to defaults
;	CALL	RTCWR

	LXI	H, CRLF$	;Newline before printout
	CALL	PRTSTR

	CALL	UNLOCK		;Send the unlock sequence
	LXI	H, RTCBUF	;Read the RTC registers into a buffer
	CALL	RTCRD

	CALL	PRTBUF		;Print the RTC registers to console

	JMP	GWMON		;Back to GWMON, cold start to restore
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
;pre: HL points to 8 byte buffer to write
;post: 64 bits shifted out to phantom RTC
;post: HL points to end of shift buffer + 1
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
;pre: HL points to 8-byte buffer to read into
;pre: phantom RTC is unlocked and ready to be read
;post: buffer contains 8 bytes shifted in from phantom RTC
;post: HL point to end of shift buffer + 1
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
;PRTBUF -- Print Phantom RTC information
;
;pre: RTCBUF contains valid RTC data
;post: phantom RTC information printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRTBUF:	CALL	PRTTIM		;Print the time
	CALL	PRTDAT		;Print the date
	CALL	PRTMOD		;Print 12/24 hour mode status
	CALL	PRTOSC		;Print oscillator status
	CALL	PRTRST		;Print *RST operation status
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PRTTIM -- Print time to console
;
;This routine correctly handles 12/24 hour mode, and prints
;AM/PM when in 12-hour mode.
;
;pre: RTCBUF contains valid RTC information
;post: date printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRTTIM:	LXI	H, TIME$	;Print time string
	CALL	PRTSTR

	LDA	RTCBUF+3	;A = hour register
	ORA	A		;Set flags
	JM	PRT12		;12-hour mode
	ANI	HRMSK24		;Mask off 24-hour bits
	JMP	PRT24		;Print hours
PRT12:	ANI	HRMSK12		;Mask off 12-hour bits
PRT24:	CALL	PRTBCD		;Print BCD hours
	MVI	A, ':'		;Print colon separator
	CALL	MONOUT

	LDA	RTCBUF+2	;A = minutes register
	CALL	PRTBCD		;Print BCD minutes
	MVI	A, ':'		;Print colon separator
	CALL	MONOUT
	LDA	RTCBUF+1	;A = seconds register
	CALL	PRTBCD		;Print BCD seconds
	MVI	A, '.'		;Print centiseconds separator
	CALL	MONOUT
	LDA	RTCBUF		;A = centiseconds register
	CALL	PRTBCD		;Print BCD centiseconds

	LDA	RTCBUF+3	;A = hour register
	ORA	A		;Set flags
	JP	IS24		;24-hour mode, done
	MVI	A, ' '		;12-hour mode, print AM/PM separator
	CALL	MONOUT
	LDA	RTCBUF+3	;A = hour register
	ANI	AMPMMSK		;Mask off AM/PM indicator
	JZ	ISAM		;0, AM
	LXI	H, PM$		;1, PM
	JMP	ISPM
ISAM:	LXI	H, AM$
ISPM:	CALL	PRTSTR

IS24:	LXI	H, CRLF$	;Print newline
	JMP	PRTSTR		;Return through PRTSTR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PRTDAT -- Print date to console
;
;The Phantom RTC supports two digit years only. Year values
;greater than 69 are assumed to be 20th century (e.g. 1970
;to 1999), year values less than 70 are assumed to be 21st
;century (2000 to 2069). This strategy allows the start of
;the UNIX epoch (1970-01-01) to be a valid date for the
;Phantom RTC.
;
;pre: RTCBUF contains valid RTC information
;post: date printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRTDAT:	LXI	H, DATE$	;Print date string
	CALL	PRTSTR
	LDA	RTCBUF+4	;A = options/day register
	ANI	DAYMSK		;Mask of day-of-week bits
	MOV	C, A		;C = day of week
	MVI	B, 0		;Zero upper byte of BC
	LXI	H, DAYTAB	;HL = start of day-of-week table
	DAD	B		;HL + (2 * A) = offset into table
	DAD	B
	MOV	E, M		;E = low byte of day string address
	INX	H
	MOV	D, M		;D = high byte of day string address
	XCHG			;HL = day string address
	CALL	PRTSTR		;Print it

	LXI	H, CMSPC$	;Print a comma and space
	CALL	PRTSTR

	LDA	RTCBUF+7	;A = year register
	CPI	06FH		;70 or greater?
	JNC	IS20		;Yes, 20th century date
	MVI	A, 020H		;No, 21st century date
	JMP	IS21
IS20:	MVI	A, 019H		;Print 20th century
IS21:	CALL	PRTBCD

	LDA	RTCBUF+7	;A = year register
	CALL	PRTBCD		;Print BCD year
	MVI	A, '-'		;Print dash separator
	CALL	MONOUT
	LDA	RTCBUF+6	;A = month register
	CALL	PRTBCD
	MVI	A, '-'		;Print dash separator
	CALL	MONOUT
	LDA	RTCBUF+5	;A = date register
	CALL	PRTBCD
	LXI	H, CRLF$	;Print newline
	JMP	PRTSTR		;Return through PRTSTR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PRTMOD -- Print 12/24 hour mode operation
;
;pre: RTCBUF contains valid RTC information
;post: 12/24 status printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRTMOD:	LXI	H, MODE$	;Print 12/24 hour mode string
	CALL	PRTSTR
	LDA	RTCBUF+3	;A = hour register
	ANI	MODEMSK		;Mask off 12/24 mode bit
	JZ	HR24		;0, 24-hour mode
	LXI	H, HR12$	;1, 12-hour mode
	CALL	PRTSTR
	RET			;Skip 24-hour message
HR24:	LXI	H, HR24$
	JMP	PRTSTR		;Return through PRTSTR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PRTOSC -- Print oscillator status
;
;pre: RTCBUF contains valid RTC information
;post: oscillator status printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRTOSC:	LXI	H, OSC$		;Print oscillator string
	CALL	PRTSTR
	LDA	RTCBUF+4	;A = options/day register
	ANI	OSCMSK		;Mask off *OSC bit
	JZ	RUNNG		;0, oscillator running
	LXI	H, STOP$	;1, oscillator not running
	CALL	PRTSTR
	RET			;Skip RUNNING message
RUNNG:	LXI	H, RUN$
	JMP	PRTSTR		;Return through PRTSTR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PRTRST -- Print *RST pin function
;
;pre: RTCBUF contains valid RTC information
;post: pin 1 functionality printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRTRST:	LXI	H, PIN1$	;Print reset string
	CALL	PRTSTR
	LDA	RTCBUF+4	;A = options/day register
	ANI	RSTMSK		;Mask off *RST bit
	JZ	ISRST		;0, *RESET pin enabled
	LXI	H, ONLY$	;1, *RESET pin disabled
	CALL	PRTSTR
	RET
ISRST:	LXI	H, RESET$
	JMP	PRTSTR		;Return through PRTSTR


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PRTSTR -- Print a NULL-terminated string
;
;pre: HL points to a NULL-terminated string
;post: string printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRTSTR: MOV	A, M		;Character to print in A
	ORA	A		;Set flags
	RZ			;NULL terminator, done
	CALL	MONOUT		;Print it to console
	INX	H		;Increment string pointer
	JMP	PRTSTR		;Print next character

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PRTBCD -- Print BCD representation of number in A
;
;pre: A register contains BCD number to print
;post: BCD representation of A printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRTBCD:	PUSH	PSW		;Save A on stack
	RRC			;Shift high digit down
	RRC
	RRC
	RRC
PRTBC1:	ANI	0FH		;Mask off low nybble
	ADI	30H		;Add ASCII bias
	CALL	MONOUT		;Print ASCII representation of A
	POP	PSW		;Restore A from stack
	ANI	0FH		;Mask off low nybble
	ADI	30H		;Add ASCII bias
	JMP	MONOUT		;Print, return through MONOUT

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
;INIRTC -- Set the Phantom RTC to defaults
;
;This data block will set the Phantom RTC to 00:00:00.00 on
;1970-01-01. It sets 24-hour mode, enables the RTC 
;oscillator, and disables the *RST input, which is shared 
;with address line A14.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIRTC:	db 00H			;0 centiseconds
	db 00H			;0 seconds
	db 00H			;0 minutes
	db 00H			;Midnight, 24-hour mode
	db 14H			;Oscillator on, reset disabled, Thursday
	db 01H			;First day of the month
	db 01H			;January
	db 70H			;1970 (no century)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DAYTAB -- Days of the week string table
;
;Day-of-week mapping is in accordance with POSIX standards.
;
;While this table necessarily begins at 0, that is not a
;valid day for this RTC, nor in the POSIX standard.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DAYTAB:	dw INV$, MON$, TUE$, WED$
	dw THU$, FRI$, SAT$, SUN$

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Day-of-Week String Constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INV$:	db 'INVALID DAY OF WEEK', 0
MON$:	db 'Monday', 0
TUE$:	db 'Tuesday', 0
WED$:	db 'Wednesday', 0
THU$:	db 'Thursday', 0
FRI$:	db 'Friday', 0
SAT$:	db 'Saturday', 0
SUN$:	db 'Sunday', 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;String Constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TIME$:	db 'Current time:      ', 0
DATE$:	db 'Date:              ', 0
MODE$:	db '12/24 hour mode:   ', 0
HR12$:	db '12 HOUR', CR, LF, 0
HR24$:	db '24 HOUR', CR, LF, 0
AM$:	db 'AM', 0
PM$:	db 'PM', 0
OSC$:	db 'Oscillator is:     ', 0
RUN$:	db 'RUNNING', CR, LF, 0
STOP$:	db 'STOPPED', CR, LF, 0
PIN1$:	db 'Pin 1 function is: A14', 0
ONLY$: 	db ' ONLY', CR, LF, 0
RESET$:	db ' AND *RESET'	;Terminated by CRLF$
CRLF$:	db CR, LF, 0
CMSPC$:	db ', ', 0

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