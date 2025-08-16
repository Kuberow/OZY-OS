#!/bin/bash
# build.sh - build a single-file 32-bit C program into flat binary

# Name of your source file
SRC="code/kernel.c"

# Name of output file
# ELF="build/kernel.elf"
BIN="build/kernel.bin"

# Clean previous builds
rm $BIN

# Compile to 32-bit object (freestanding optional)
arm-none-eabi-gcc -nostdlib -ffreestanding -Os -marm -mcpu=arm7tdmi \
  -Wl,-Ttext=0x0 -Wl,--oformat=binary code/kernel.c -o build/kernel.bin


# Link to ELF starting at 0x10000 (adjust if your VM wants a different address)
# ld -m elf_i386 -Ttext 0x10000 -o $ELF main.o -e main

# Convert ELF to flat binary
# objcopy -O binary $ELF $BIN
cp vm.lua build/vm.lua
cp startup.lua build/startup.lua

echo "Build complete! Binary: $BIN"
