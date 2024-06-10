;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;1244DISP -- Library with Display Routines for DS1244
;
;Included in this library are routines for processing the
;RTC registers in Dallas DS1244 Phantom RTC modules.
;
;1244DISP uses CHARLIB.INC, programs which INCLUDE 1244DISP
;must define a COUT routine. See CHARLIB.INC for details.
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

	INCLUDE	'CHARLIB.INC'	;Needs PRTSTR, PRTBCD

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
	CALL	COUT

	LDA	RTCBUF+2	;A = minutes register
	CALL	PRTBCD		;Print BCD minutes
	MVI	A, ':'		;Print colon separator
	CALL	COUT
	LDA	RTCBUF+1	;A = seconds register
	CALL	PRTBCD		;Print BCD seconds
	MVI	A, '.'		;Print centiseconds separator
	CALL	COUT
	LDA	RTCBUF		;A = centiseconds register
	CALL	PRTBCD		;Print BCD centiseconds

	LDA	RTCBUF+3	;A = hour register
	ORA	A		;Set flags
	JP	IS24		;24-hour mode, done
	MVI	A, ' '		;12-hour mode, print AM/PM separator
	CALL	COUT
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
	CALL	COUT
	LDA	RTCBUF+6	;A = month register
	CALL	PRTBCD
	MVI	A, '-'		;Print dash separator
	CALL	COUT
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
