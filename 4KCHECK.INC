;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;4KCHECK -- Check Program Size is Under 4K
;
;Programs used with CPMRELOC need to be under 4K, or they
;will get truncated. Print a warning if it exceeds 4K.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRGEND	equ	*
	IF	PRGEND GT 04FFFH
	PRINT	"*** PROGRAM EXCEEDS 4K, CANNOT BE USED WITH CPMRELOC ***"
	ENDIF
