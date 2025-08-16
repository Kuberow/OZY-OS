// prog.c
// Simple program for your ARMvCPU emulator
// Provides print() using svc #0 as putchar(R0)

static inline void svc_putchar(char c) {
    register int r0 __asm__("r0") = (unsigned char)c;
    __asm__ __volatile__("svc #0" : "+r"(r0));
}

void print(const char *s) {
    while (*s) {
        svc_putchar(*s++);
    }
}

__attribute__((naked)) void _start(void) {
    __asm__ __volatile__(
        "ldr sp, =0x00100000\n" // set up a stack
    );

    print("Hello, World!\n");
    print("- Kuberow")

    __asm__ __volatile__("mov pc, lr"); // exit: PC = LR (your VM halts)
}
