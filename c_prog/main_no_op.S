	.file	"main.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	str
	.section	.rodata
	.align	2
	.type	str, @object
	.size	str, 13
str:
	.string	"Hello UART!\n"
	.text
	.align	2
	.type	send_char, @function
send_char:
	addi	sp,sp,-32
	sw	s0,28(sp)
	sw	s1,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	mv	a5,a1
	sb	a5,-21(s0)
	lbu	a5,-21(s0)
	slli	a5,a5,1
	ori	s1,a5,512
	lw	a4,-20(s0)
	mv	a5,s1
 #APP
# 9 "main.c" 1
	1: sb a5, 0(a4)
	   srli a5, a5, 1
	   nop
	   nop
	   bnez a5, 1b
	
# 0 "" 2
 #NO_APP
	nop
	lw	s0,28(sp)
	lw	s1,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	send_char, .-send_char
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	li	a5,1073741824
	sw	a5,-24(s0)
	lw	a5,-24(s0)
	li	a4,1
	sb	a4,0(a5)
	lui	a5,%hi(str)
	addi	a5,a5,%lo(str)
	sw	a5,-20(s0)
	j	.L3
.L4:
	lw	a5,-20(s0)
	addi	a4,a5,1
	sw	a4,-20(s0)
	lbu	a5,0(a5)
	mv	a1,a5
	lw	a0,-24(s0)
	call	send_char
.L3:
	lw	a5,-20(s0)
	lbu	a5,0(a5)
	bne	a5,zero,.L4
	li	a5,-1879048192
	sw	a5,-28(s0)
	lw	a5,-28(s0)
	sw	zero,0(a5)
.L5:
	j	.L5
	.size	main, .-main
	.ident	"GCC: (13.2.0-11ubuntu1+12) 13.2.0"
