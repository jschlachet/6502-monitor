#
FIRMWARE_CFG=../firmware.cfg

CA65_BINARY=ca65
CA65_FLAGS=--cpu 65C02
LD65_BINARY=ld65
LD65_FLAGS=-C $(FIRMWARE_CFG)

SOURCE_DIR=../src
BUILD_DIR=../build
CONFIG_DIR=../../config/
OBJ_DIR=../../obj

MONITOR_OBJ=$(OBJ_DIR)/monitor.o

all: hello blink input

# general rule for building object from source
$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.s 
	$(CA65_BINARY) $(CA65_FLAGS) --include-dir $(CONFIG_DIR) -o $(BUILD_DIR)/$@ $<

# general rule for building binary from object (and linking mointor object file)
%: $(BUILD_DIR)/%.o $(FIRMWARE_CFG)  $(MONITOR_OBJ)
	$(LD65_BINARY) $(LD65_FLAGS) -o $@ $(MONITOR_OBJ) $<
