;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CHARLIB -- General Character and String Handling Library
;
;This library contains routines for printing NULL-terminated
;strings, converting and printing BCD data, etc.
;
;If CPMLIB is included before CHARLIB, CHARLIB will include
;routines that can perform I/O using CP/M BDOS calls when
;CP/M is detected in memory.
;
;If CP/M is not present, CHARLIB will use GWMON-80 I/O.
;Including programs must define GWMON as the start of the
;GWMON-80 jump table.
;
;Copyright (c) 2024 Glitch Works, LLC
;http://www.glitchwrks.com
;
;See LICENSE included in the project root for licensing
;information.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GWMON-80 Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MONOUT	equ	GWMON+6H	;Monitor character out routine
MONIN	equ	GWMON+9H	;Monitor character in routine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ASCII Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CTLC	equ	03
BS	equ	08
LF	equ	10
CR	equ	13

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PRTSTR -- Print a NULL-terminated string
;
;pre: HL points to a NULL-terminated string
;post: string printed to console
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRTSTR: MOV	A, M		;Character to print in A
	ORA	A		;Set flags
	RZ			;NULL terminator, done
	CALL	COUT		;Print it to console
	INX	H		;Increment string pointer
	JMP	PRTSTR		;Print next character

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PRTBCD -- Print BCD representation of number in A
;
;Falls through to COUT.
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
	CALL	COUT		;Print ASCII representation of A
	POP	PSW		;Restore A from stack
	ANI	0FH		;Mask off low nybble
	ADI	30H		;Add ASCII bias

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
COUT:				;This line blank, no label on IFDEF
	IFDEF	CPMFLG		;CP/M detector present?
	PUSH	PSW		;Save character on stack
	LDA	CPMFLG		;Running under CP/M?
	ORA	A		;Set flags
	JNZ	CPMOUT		;Yes, use BDOS character output
	POP	PSW		;No use GWMON-80 COUT

	JNZ	MONOUT		;Return through MONOUT
	ELSE
	JMP	MONOUT		;Return through MONOUT
	ENDIF
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CPMOUT -- CP/M BDOS console output
;
;This routine is conditionally assembled if CPMFLG is
;defined, indicating the presence of CP/M detection routines
;from CPMLIB.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	IFDEF	CPMFLG		;CP/M detector present?
CPMOUT:	POP	PSW		;Restore A
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
	ENDIF
