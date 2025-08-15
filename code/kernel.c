// C kernel here:
__attribute__((section(".text"))) void kmain(void);

static inline void vm_putchar(char c) {
    // Replace this with your VM’s syscall or console write
    __asm__ volatile ("int $0x10" : : "a"(0x0E00 | c));
}

void println(const char *s) {
    while (*s) vm_putchar(*s++);
}

void kmain(void) {
    println("Hello from my 32-bit OS!");
    for(;;) __asm__("hlt");
}

__asm__(
".global _start\n"
"_start:\n"
"cli\n"
"xor %ax,%ax\n"
"mov %ax,%ds\n"
"mov %ax,%es\n"
"mov %ax,%ss\n"
"mov $0x90000,%sp\n"   // simple stack
"call kmain\n"
"hlt\n"
);
