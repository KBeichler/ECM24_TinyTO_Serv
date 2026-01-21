    .section .text
    .globl _start
_start:
    lui sp, 1                # set sp = 0x1000 to avoid IO aliasing on underflow
    jal ra, main             # jump into C main

hang:
    j hang                   # stay here if main ever returns