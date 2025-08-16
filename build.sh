#!/bin/bash
# build.sh - build a single-file 32-bit C program into flat binary

# Name of your source file
SRC="code/kernel.c"

# Name of output file
ELF="build/kernel.elf"
BIN="build/kernel.bin"

# Clean previous builds
rm $BIN

# Step 1: compile and link to ELF
arm-none-eabi-gcc -nostdlib -ffreestanding -Os -marm -mcpu=arm7tdmi \
  -Wl,-Ttext=0x0 \
  -o $ELF $SRC

# Step 2: convert ELF to raw binary
arm-none-eabi-objcopy -O binary $ELF $BIN
cp vm.lua build/vm.lua
cp startup.lua build/startup.lua

echo "Build complete! Binary: $BIN"
