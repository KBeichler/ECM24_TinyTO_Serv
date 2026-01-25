#define GPIO_ADDR 0x40000000

int main(void) {
    volatile unsigned char *gpio = (unsigned char *)GPIO_ADDR;

    // Set GPIO high initially (idle)
    *gpio = 1;

    while (1)
    {
        // ~ 7 ms @ 1 MHz CPU and SPI clock
        volatile int delay = 10;
        while(delay--) ;
        *gpio = 0;
        delay = 10;
        while(delay--) ;
        *gpio = 1;
    } // infinite loop for safety on real hardware
}
