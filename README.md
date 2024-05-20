# DS1244 Clock Demo

This demo program interfaces to a DS1244 Phantom RTC (or our [GW-1244-1 replacement](https://www.tindie.com/products/23132/)) under CP/M 2.2 or without CP/M on a Glitch Works [8085 SBC rev 3](https://www.tindie.com/products/21816/) or [8085 SBC rev 4 Mini](https://www.tindie.com/products/34563/). It can also optionally display date and time on a Glitchbus ASCII display board.

### What is a Phantom RTC?

A "phantom RTC" is a real-time clock that does not normally exist in memory space. By sending a special serial bit stream, the RTC can be activated, and will appear in memory as a read/write serial device. This allows a module like the DS1244 to be plugged into a system memory socket without affecting existing software.

The DS1244 completely replaces 32K of system memory in the Glitch Works 8085 SBC rev 3 or rev 4 Mini. In addition to the phantom RTC functionality, it adds nonvolatility to the 32K of static RAM it replaces.

The [DS1244 datasheet](DS1244_datasheet.pdf) covers pinout, operation, the serial bitstream used for RTC activation, and more.

### Building

You will need [our port of the A85 assembler](https://github.com/glitchwrks/a85) and `make`. The included `Makefile` will build the project.