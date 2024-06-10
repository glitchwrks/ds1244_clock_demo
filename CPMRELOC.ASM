;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CPMRELOC -- CP/M Relocator for DS1244 Programs
;
;Moves DS1244 utility programs to 0x4000 - 0x4FFF so that
;CP/M can load them. This is necessary so that we do not
;cause the A14 line to go low while reading or writing to
;the Phantom RTC chip, in case *RST on pin 1 has not been
;disabled.
;
;This program is not useful on its own, and should be joined
;with the target program. See Makefile.
;
;Copyright (c) 2024 Glitch Works, LLC
;http://www.glitchwrks.com
;
;See LICENSE included in the project root for licensing
;information.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Miscellaneous Equates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TARGET	equ	04000H		;Destination for program relocation

	ORG	0100H		;Start in CP/M TPA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RELOC -- Move the 4K after this program into higher memory
;
;pre: program to relocate is immediately after RELEND
;post: program relocated to TARGET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RELOC:	LXI	H, RELEND	;HL = start of program to move
	LXI	D, TARGET	;DE = destination
RELOC1:	MOV	A, M		;Get byte from program
	STAX	D		;Store it in destination
	INX	H		;Increment source address
	INX	D		;Increment destination address
	MOV	A, D		;A = high destination address
	CPI	(HIGH TARGET)+10H
	JNZ	RELOC1		;Haven't moved 4K yet, do more
	JMP	TARGET		;Moved 4K, jump into it

RELEND	equ	*

	END