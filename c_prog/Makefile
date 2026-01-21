TOOLCHAIN_PREFIX ?= riscv64-unknown-elf-
CC      = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
OPT     ?= -O2

# Default target builds a binary from start.S + main.c
TARGET ?= main
all: $(TARGET).bin

# Explicit link rule for our startup + C main
$(TARGET).elf: start.S main.c link.ld
	$(CC) $(OPT) -nostartfiles -nostdlib -march=rv32i -mabi=ilp32 -Tlink.ld -o $@ start.S main.c

%.elf: %.S link.ld
	$(CC) $(OPT) -nostartfiles -nostdlib -march=rv32i -mabi=ilp32 -Tlink.ld -o $@ $<

%.elf: %.c link.ld
	$(CC) $(OPT) -nostartfiles -nostdlib -march=rv32i -mabi=ilp32 -Tlink.ld -o $@ $<

# Convert ELF to binary
%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

# Convert binary to hex (via python script)
%.hex: %.bin
	python3 makehex.py $< > $@

%.S: %.c
	$(CC) -S $(OPT) -nostdlib -march=rv32i -mabi=ilp32 -o $@ $<

# Clean build artifacts
clean:
	rm -f *.elf *.bin *.hex
