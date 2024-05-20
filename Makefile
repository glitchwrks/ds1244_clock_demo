RMFLAGS		= -f

ASM		= a85
RM		= rm

all: 1244DEMO

1244DEMO:
	$(ASM) 1244DEMO.ASM -o 1244DEMO.HEX -l 1244DEMO.PRN

clean:
	$(RM) $(RMFLAGS) *.HEX *.PRN

distclean: clean
