# 6502 Monitor

A simple monitor for my homebrew computer. 


## Hardware Requirements

The monitor is custon designed for my [6502-board-rev2](https://github.com/jschlachet/6502-board-rev2) computer. Its design is largely based on Garth Wilson's [6502 Primer](https://wilsonminesco.com/6502primer/). 

Interaction is through the serial port via the ACIA headers.  I'm using a [DSD Tech SH-U09C5 USB to TTL](https://www.amazon.com/DSD-TECH-SH-U09C5-Converter-Support/dp/B07WX2DSVB) adapter.

## Software Requirements
1. [cc65](https://cc65.github.io) for its assembler and linker.
1. [minipro](https://gitlab.com/DavidGriffith/minipro) for writing the image to EEPROM
1. make

## Build

To build the monitor, run `make clean && make`. This should produce `rom/monitor` which can then be written to an EEPROM. 

User space programs are in the `user/` directory, and in that directory you can run `make` to compile them.

Once the computer is booted into the monitor, you can upload programs using xmodem and invoking the program with the `run` command.

## Capabilities

The monitor provides basic functionality to inspect memory, and to load and run programs.

It provides rudimentary system functions, listed in [config/funcions.cfg](config/funcions.cfg)

Monitor commands
* `dump [addr]` will display 256 bytes starting at `$0000` unless a starting address is specified. Specify an address like this: `dump 8000` 
* `jmp addr` will jump to the address specified
* `led` will toggle the onboard LED 
* `load` will start the xmodem protocol receiver, so you can upload a program to the computer
* `read addr` will display 16 bytes starting at the address specified 
* `reboot` will perform a soft reset of the system
* `run` will invoke the program at `$3000` (the system's default program address)
* `write addr value` will write the byte `value` in the location `addr`. An example is `write 3010 ff`, the results of which can be seen from `dump 3000` or `read 3010` output


## Inspirations

Some other projects from which I've gained inspiration and guidance

* Dawid Buchwald's [DB6502](https://github.com/dbuchwald/6502)
* Kris Foster's [krisos](https://github.com/transitorykris/krisos)


## Hardware Notes

VIA (6522) Port and Pin assignments on Rev2 hardware.

| VIA | Port | Pin | Connection |
| --- | ---- | --- | ---------- |
|VIA1|Port A|A0..A7|SN76489|
|    |Port B|B0    | SN76489 /WE|
|    |      |B1    | SN76489 RDY|
|    |      |B2..B7| none |
|VIA2|PortA|A0..A3| LCD D7..D0|
|    |     |A4    | LCD E     |
|    |     |A5    | LCD RW    |
|    |     |A6    | LCD RS    |
|    |     |A7    | USER LED  |

