;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CPMLIB -- CP/M Utilities and Interfacing Library
;
;This library provides some CP/M convenience routines.
;
;Copyright (c) 2024 Glitch Works, LLC
;http://www.glitchwrks.com
;
;See LICENSE included in the project root for licensing
;information.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CP/M Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WBOOT	equ	0000H		;CP/M warm boot address
BDOS	equ	0005H		;CP/M BDOS entry point
CWRITE	equ	02H		;BDOS console output

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
;CPMLIB Variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CPMFLG:	ds 1			;CP/M flag, nonzero if CP/M detected
