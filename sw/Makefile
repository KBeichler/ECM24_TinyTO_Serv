TOOLCHAIN_PREFIX ?= riscv64-unknown-elf-
CC      = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
OPT     ?= -O2

# 1. Define the Source file (Default to main.c if no argument is given)
SRC ?= main.c

# 2. Define Output Directory
BUILD_DIR = build

# 3. Derive the target name (strips extension and directory from input)
#    e.g., "src/test_code.c" -> "test_code"
TARGET_NAME = $(basename $(notdir $(SRC)))

# Define paths for artifacts
TARGET_ELF = $(BUILD_DIR)/$(TARGET_NAME).elf
TARGET_BIN = $(BUILD_DIR)/$(TARGET_NAME).bin
TARGET_HEX = $(TARGET_NAME).hex

# Default target
all: $(TARGET_HEX)

# 4. Create the build directory (Order-only prerequisite)
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# 5. Link Rule: Links start.S + Your Source -> Build Folder ELF
#    Uses "| $(BUILD_DIR)" to ensure folder exists before compiling
$(TARGET_ELF): start.S $(SRC) link.ld | $(BUILD_DIR)
	$(CC) $(OPT) -nostartfiles -nostdlib -march=rv32i -mabi=ilp32 -Tlink.ld -o $@ start.S $(SRC)

# 6. Convert ELF to Binary (in Build Folder)
$(TARGET_BIN): $(TARGET_ELF)
	$(OBJCOPY) -O binary $< $@

# 7. Convert Binary to Hex (in Root Folder)
$(TARGET_HEX): $(TARGET_BIN)
	python3 makehex.py $< > $@

# Optional: Generate assembly listing in build folder for inspection
$(BUILD_DIR)/%.S: %.c | $(BUILD_DIR)
	$(CC) -S $(OPT) -nostdlib -march=rv32i -mabi=ilp32 -o $@ $<

# Clean: Removes build dir and root hex files
clean:
	rm -rf $(BUILD_DIR) *.hex

.PHONY: all clean