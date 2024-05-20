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
SCRATCH	equ	08000H		;Upper 32K memory, first location

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

	ORG	0100H		;Start in CP/M TPA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PATTRN -- Phantom RTC access pattern
;
;Dallas/Maxim/Analog states that this bitstream pattern has
;been chosen as it has less than a 1 in 10^19 chance of 
;appearing in random data.
;
;Unlock pattern is shifted into D0 in the phantom RTC memory
;region, LSB to MSB.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PATTRN:	db 0C5H, 03AH, 0A3H, 05CH, 0C5H, 03AH, 0A3H, 05CH

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RTCBUF -- Buffer space for phantom RTC operations
;
;This buffer is used to store data for serialization and
;deserialization when reading and writing to the phantom RTC
;registers. All eight 8-bit registers must be read or
;written.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RTCBUF:	ds 8

	END