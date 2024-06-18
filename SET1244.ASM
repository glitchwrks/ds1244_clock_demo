;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SET1244 -- Set Dallas Phantom RTC Date and Time
;
;This program sets the date and time for Dallas Phantom RTC
;modules. It can be loaded directly into GWMON-80, or used 
;with the CP/M relocator.
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
;GWMON-80 Equates
;
;CHARLIB uses the GWMON equate to locate monitor I/O
;subroutines.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GWMON	equ	0F000H		;Start of GWMON-80

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Program Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRVSTK	equ	5FFFH		;Private stack location, A14 high

	ORG	4000H		;A14 must be high since *RST may not be
				;disabled yet.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SAVSTK -- Save the current stack and set up a private one
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SAVSTK:	LXI	H, 0		;Zero HL
	DAD	SP		;HL = old stack pointer
	SHLD	OLDSTK		;Save for later
	LXI	SP, PRVSTK	;Set up private stack

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;START -- Get ready to interact with Phantom RTC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:	CALL	CHKCPM		;Check if we're running under CP/M
	
	LXI	H, SIGN$	;Newline before printout
	CALL	PRTSTR

;	CALL	UNLOCK		;Send the unlock sequence	
;	LXI	H, INIRTC	;Set the RTC to defaults
;	CALL	RTCWR

	CALL	UNLOCK		;Send the unlock sequence
	LXI	H, RTCBUF	;Read the RTC registers into a buffer
	CALL	RTCRD

	CALL	PRTBUF		;Print the RTC registers to console

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;QUIT -- Exit to calling program
;
;Restore the stack this program was entered with, and exit
;via RET. This works correctly with both CP/M and GWMON-80.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
QUIT:	LHLD	OLDSTK		;HL = saved stack pointer
	SPHL			;Restore old stack
	RET			;Return to caller

	INCLUDE	'CPMLIB.INC'	;CP/M utilities library

	INCLUDE	'1244COMM.INC'	;Phantom RTC communications library
	INCLUDE	'1244DISP.INC'	;Phantom RTC register display library,
				;brings in CHARLIB

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
;String Constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SIGN$:	db CR, LF, 'DS1244 Setup', CR, LF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Variable Storage Area
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OLDSTK:	ds 2			;Two bytes for stack pointer storage

	INCLUDE	"4KCHECK.INC"	;Make sure program is not over 4K

	END
