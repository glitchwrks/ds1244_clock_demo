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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GWMON	equ	0F000H		;Start of GWMON-80
MONOUT	equ	GWMON+6H	;Monitor character out routine
MONIN	equ	GWMON+9H	;Monitor character in routine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CP/M Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WBOOT	equ	0000H		;CP/M warm boot address
BDOS	equ	0005H		;CP/M BDOS entry point
CWRITE	equ	02H		;BDOS console output

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

	INCLUDE	'1244COMM.INC'	;Phantom RTC communications library
	INCLUDE	'1244DISP.INC'	;Phantom RTC register display library

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CHKCPM -- Check for CP/M in memory
;
;Determine if we're currently running under CP/M. Set CPMFLG
;depending on the result.
;
;CP/M is assumed if there is a JMP at 0x0000 and the
;destination address points to five more JMPs.
;
;post: CPMFLG is nonzero if running under CP/M
;post: CPMFLG is zero if not running under CP/M
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHKCPM:	XRA	A
	STA	CPMFLG		;Clear CP/M flag to FALSE

	LDA	WBOOT		;Get byte at CP/M warm start address
	CPI	0C3H		;Check for JMP instruction
	RNZ			;No, definitely not CP/M

	LXI	H, WBOOT+1	;HL = LSB of JMP operand
	MOV	E, M		;E = low byte of JMP destination
	INX	H		;HL = MSB of JMP operand
	MOV	D, M		;D = high byte of JMP destination
	MVI	B, 5		;Look for 5 more JMPs -- CP/M JMP table
CHKCP1:	LDAX	D		;A = opcode at JMP destination
	CPI	0C3H		;JMP present?
	RNZ			;No, not CP/M
	INX	D		;Move to next JMP
	INX	D
	INX	D
	DCR	B		;Decrement JMP counter
	JNZ	CHKCP1		;More JMPs to check for

	MVI	A, 0FFH		;Set CP/M flag to TRUE
	STA	CPMFLG
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;COUT -- Character output routine
;
;This routine uses CP/M's console I/O routines via BDOS call
;if CPMFLG indicates CP/M is in memory, or GWMON-80 COUT if
;CP/M is not running.
;
;pre: A register contains character to output
;post: character in A register output to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COUT:	PUSH	PSW		;Save character on stack
	LDA	CPMFLG		;Running under CP/M?
	ORA	A		;Set flags
	JNZ	COUT1		;Yes, use BDOS character output
	
	POP	PSW		;No use GWMON-80 COUT
	JNZ	MONOUT		;Return through COUT

COUT1:	POP	PSW		;Restore A
	PUSH	B		;Save registers on stack
	PUSH	D
	PUSH	H
	MVI	C, CWRITE	;C = BDOS function
	MOV	E, A		;E = character to output
	CALL	BDOS		;Make BDOS call
	POP	H		;Restore registers from stack
	POP	D
	POP	B
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Variable Storage Area
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OLDSTK:	ds 2			;Two bytes for stack pointer storage
CPMFLG:	ds 1			;CP/M flag, nonzero if CP/M detected

	END
