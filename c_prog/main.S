	.file	"main.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	li	a5,1073741824
	li	a4,1
	sb	a4,0(a5)
	lui	a4,%hi(.LANCHOR0)
	addi	a4,a4,%lo(.LANCHOR0)
	li	a5,72
	li	a3,1073741824
.L2:
	slli	a5,a5,1
	ori	a5,a5,512
	addi	a4,a4,1
 #APP
# 9 "main.c" 1
	1: sb a5, 0(a3)
	   srli a5, a5, 1
	   nop
	   nop
	   bnez a5, 1b
	
# 0 "" 2
 #NO_APP
	lbu	a5,0(a4)
	bne	a5,zero,.L2
	li	a5,-1879048192
	sw	zero,0(a5)
.L3:
	j	.L3
	.size	main, .-main
	.globl	str
	.section	.rodata
	.align	2
	.set	.LANCHOR0,. + 0
	.type	str, @object
	.size	str, 13
str:
	.string	"Hello UART!\n"
	.ident	"GCC: (13.2.0-11ubuntu1+12) 13.2.0"
