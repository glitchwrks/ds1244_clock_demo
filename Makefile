RMFLAGS		= -f

ASM		= a85
RM		= rm

all: READ1244 SET1244

CPMRELOC.BIN: CPMRELOC.HEX
	srec_cat CPMRELOC.HEX -intel -offset -256 -o CPMRELOC.BIN -binary

CPMRELOC.HEX: CPMRELOC.ASM
	$(ASM) CPMRELOC.ASM -o CPMRELOC.HEX -l CPMRELOC.PRN

READ1244: READ1244.HEX

READ1244.HEX: READ1244.BIN CPMRELOC.BIN
	cat CPMRELOC.BIN READ1244.BIN > READ1244_LOADED.BIN
	srec_cat READ1244_LOADED.BIN -binary -offset 256 -o READ1244.HEX -intel -address-length=2
	$(RM) READ1244_LOADED.BIN

READ1244.BIN: READ1244_4000.HEX
	srec_cat READ1244_4000.HEX -intel -offset -16384 -o READ1244.BIN -binary

READ1244_4000.HEX: READ1244.ASM CHARLIB.INC CPMLIB.INC 1244COMM.INC 1244DISP.INC 4KCHECK.INC
	$(ASM) READ1244.ASM -o READ1244_4000.HEX -l READ1244.PRN

SET1244: SET1244.HEX

SET1244.HEX: SET1244.ASM
	$(ASM) SET1244.ASM -o SET1244_4000.HEX -l SET1244.PRN

clean:
	$(RM) $(RMFLAGS) *.HEX *.PRN *.BIN

distclean: clean
