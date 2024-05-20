# DS1244 Clock Demo

This demo program interfaces to a DS1244 Phantom RTC (or our [GW-1244-1 replacement](https://www.tindie.com/products/23132/)) under CP/M 2.2 or without CP/M on a Glitch Works [8085 SBC rev 3](https://www.tindie.com/products/21816/) or [8085 SBC rev 4 Mini](https://www.tindie.com/products/34563/). It can also optionally display date and time on a Glitchbus ASCII display board.

### Building

You will need [our port of the A85 assembler](https://github.com/glitchwrks/a85) and `make`. The included `Makefile` will build the project.