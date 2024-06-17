;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;READ1244 -- Read and Display DS1244 Phantom RTC Registers
;
;This program will read from a Dallas Phantom RTC and
;display the value of the RTC registers on the console. It
;can be loaded directly into GWMON-80, or used with the CP/M
;relocator.
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
	
	LXI	H, CRLF$	;Newline before printout
	CALL	PRTSTR

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
;Variable Storage Area
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OLDSTK:	ds 2			;Two bytes for stack pointer storage

	INCLUDE	"4KCHECK.INC"	;Make sure program is not over 4K

	END
