// C kernel here:
__attribute__((section(".text"))) void kmain(void);

// VM syscall: output one character
static inline void vm_putchar(char c) {
    // Your VM uses "OUT R0" style instruction; we'll pretend the compiler knows it
    // For your VM, replace this with the opcode manually if needed
    __asm__ volatile(
        "movi r0, %0\n\t"
        "out r0\n"
        :
        : "r"(c)
    );
}

// Print a string
void print(const char *s) {
    while (*s) {
        vm_putchar(*s++);
    }
}

// Print a string + newline
void println(const char *s) {
    print(s);
    vm_putchar('\n');
}

// Kernel entry
void kmain(void) {
    println("Hello from my 32-bit VM!");
    println("It stops here.");

    // Halt the VM
    for(;;) __asm__ volatile("halt"); // infinite halt loop
}

// Startup assembly: call kmain
__asm__ (
".global _start\n"
"_start:\n"
"    mov $0x90000, %sp\n" // simple stack
"    call kmain\n"
"    hlt\n"
);
