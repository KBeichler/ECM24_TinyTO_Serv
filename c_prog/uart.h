#pragma once

#define UART_BASE 0x80000000

#define UART_TX     (*(volatile unsigned int *)(UART_BASE + 0x00))
#define UART_RX     (*(volatile unsigned int *)(UART_BASE + 0x04))
#define UART_STATUS (*(volatile unsigned int *)(UART_BASE + 0x08))

#define UART_TX_READY 0x01

static inline void uart_putc(char c)
{
    while ((UART_STATUS & UART_TX_READY) == 0);
    UART_TX = c;
}

static inline void uart_puts(const char *s)
{
    while (*s) {
        if (*s == '\n')
            uart_putc('\r');
        uart_putc(*s++);
    }
}
