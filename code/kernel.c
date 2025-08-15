// C kernel here:
__attribute__((section(".text"))) void kmain(void);

// Output a character to the VM console
static inline void vm_putchar(char c) {
    // This uses your VM's OUT Rm instruction (adapt as needed)
    __asm__ volatile (
        "movl %0, %%eax\n\t" // Put character in EAX (or whichever register your VM OUT uses)
        "out"                // OUT instruction in your VM
        :
        : "r"((int)c)
        : "%eax"
    );
}

// Print a string
void print(const char *s) {
    while (*s) {
        vm_putchar(*s++);
    }
}

// Print a string followed by a newline
void println(const char *s) {
    print(s);
    vm_putchar('\n');
}

// Kernel entry point
void kmain(void) {
    print("works\n")
    for (;;); // Infinite loop
}

// Startup assembly — sets up stack and calls kmain
__asm__(
".global _start\n"
"_start:\n"
"    mov $0x90000, %esp\n" // Set stack pointer
"    call kmain\n"
"    halt\n"
