;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CHARLIB -- General Character and String Handling Library
;
;This library contains routines for printing NULL-terminated
;strings, converting and printing BCD data, etc.
;
;Programs that INCLUDE this library must define a COUT
;character output routine, which takes a character in the A
;register and outputs it to the display device.
;
;Copyright (c) 2024 Glitch Works, LLC
;http://www.glitchwrks.com
;
;See LICENSE included in the project root for licensing
;information.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
	JMP	COUT		;Print, return through COUT
