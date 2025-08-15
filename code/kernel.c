// C kernel here:
__attribute__((section(".text"))) void kmain(void);

static inline void vm_putchar(char c) {
    asm volatile (
        "mov $0x0E, %%ah \n"   // BIOS teletype function
        "mov %[ch], %%al \n"   // Character to print
        "mov $0x0007, %%bx \n" // BH=0 (page 0), BL=07h (light gray on black)
        "int $0x10      \n"
        :
        : [ch] "r" (c)
        : "ax", "bx"
    );
}

void println(const char* s) {
    while (*s) vm_putchar(*s++);
}

void kmain(void) {
    println("Hello from my 32-bit OS!");
    for (;;) asm("hlt");
}

// Boot entry point
asm(
".code16\n"            // Ensure assembler treats it as 16-bit code
".global _start\n"
"_start:\n"
"    cli\n"
"    xor %ax, %ax\n"
"    mov %ax, %ds\n"
"    mov %ax, %es\n"
"    mov %ax, %ss\n"
"    mov $0x9000, %sp\n"   // simple stack
"    call kmain\n"
"    hlt\n"
);
