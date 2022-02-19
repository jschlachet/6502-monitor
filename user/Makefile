#

CA65_BINARY=ca65
LD65_BINARY=ld65

FIRMWARE_CFG=firmware.cfg

CA65_FLAGS=--cpu 65C02
LD65_FLAGS=-C $(FIRMWARE_CFG)

SOURCE_DIR=.
BUILD_DIR=../build
INCLUDE_DIR=../../include/
CONFIG_DIR=../config/
OBJ_DIR=../obj
BIN_DIR=../bin

OBJS = hello.o

all: hello

hello:
	$(CA65_BINARY) $(CA65_FLAGS) --include-dir $(CONFIG_DIR) -o hello.o src/hello.s
	$(LD65_BINARY) $(LD65_FLAGS) -o hello $(OBJ_DIR)/monitor.o hello.o



