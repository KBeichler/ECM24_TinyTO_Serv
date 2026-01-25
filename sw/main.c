#define GPIO_ADDR 0x40000000
#define HALT_ADDR 0x90000000

const char str[] = "Hello UART!\n";

static inline void send_char(volatile unsigned char *gpio, unsigned char ch) {
    // Bitbang UART with timing matched to reference hello_uart.S (57600 baud @16 MHz)
    register unsigned int t0 = ((unsigned int)ch | 0x100u) << 1; // start(0)+data+stop(1)
    __asm__ volatile(
        "1: sb %[t0], 0(%[gpio])\n\t"
        "   srli %[t0], %[t0], 1\n\t"
        "   nop\n\t"
        "   nop\n\t"
        "   bnez %[t0], 1b\n\t"
        : [t0] "+r" (t0)
        : [gpio] "r" (gpio)
        : "memory");
}

int main(void) {
    volatile unsigned char *gpio = (unsigned char *)GPIO_ADDR;

    // Set GPIO high initially (idle)
    *gpio = 1;

    const char *p = str;
    while (*p) {
        send_char(gpio, (unsigned char)*p++);
    }

    // Halt simulation
    volatile unsigned int *halt = (unsigned int*)HALT_ADDR;
    *halt = 0;

    while (1); // infinite loop for safety on real hardware
}
