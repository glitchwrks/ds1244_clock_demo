# DS1244 Clock Demo

This demo program interfaces to a DS1244 Phantom RTC (or our [GW-1244-1 replacement](https://www.tindie.com/products/23132/)) under CP/M 2.2 or without CP/M on a Glitch Works [8085 SBC rev 3](https://www.tindie.com/products/21816/) or [8085 SBC rev 4 Mini](https://www.tindie.com/products/34563/). It can also optionally display date and time on a Glitchbus ASCII display board.

### What is a Phantom RTC?

A "phantom RTC" is a real-time clock that does not normally exist in memory space. By sending a special serial bit stream, the RTC can be activated, and will appear in memory as a read/write serial device. This allows a module like the DS1244 to be plugged into a system memory socket without affecting existing software.

The DS1244 completely replaces 32K of system memory in the Glitch Works 8085 SBC rev 3 or rev 4 Mini. In addition to the phantom RTC functionality, it adds nonvolatility to the 32K of static RAM it replaces.

The [DS1244 datasheet](DS1244_datasheet.pdf) covers pinout, operation, the serial bitstream used for RTC activation, and more.

### Building

You will need [our port of the A85 assembler](https://github.com/glitchwrks/a85) and `make`. The included `Makefile` will build the project.

### `READ1244`

`READ1244` will read the RTC registers from a Dallas Phantom RTC and print them to the console. It expects to run with GWMON-80 or CP/M, and has been tested on the 8085 SBC rev 3 and rev 4M.

After building, `READ1244.HEX` can be loaded directly with GWMON-80 using the `L` Intel HEX loader command. Once it is loaded, jump into it with `G 0100`. `READ1244.HEX` is also CP/M compatible, and can be turned into a CP/M executable with `LOAD READ1244`.
