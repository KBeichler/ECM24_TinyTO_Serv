#define GPIO_ADDR 0x40000000

int main(void)
{
    volatile unsigned int *gpio = (unsigned int *)GPIO_ADDR;

    // Initialize outputs to 0
    *gpio = 0x0;

    while (1)
    {
        // Read GPIO register
        unsigned int v = *gpio;

        // Extract input bits [7:4]
        unsigned char in = (v >> 4) & 0xF;

        // Drive outputs [3:0] with inputs
        *gpio = in;
        while(1){
            // 
            in ^= 0xF;
            *gpio = in;
        }
        // Small delay (roughly a few ms @ ~1 MHz SERV)
        volatile int delay = 10;
        while (delay--) ;
    }
}
