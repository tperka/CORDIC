.data
text_initial:		.asciiz "Podaj wartoœæ k¹ta (wspó³czynnik a w a*PI) dla którego chcesz obliczyæ sinus: \n"

result_1:		.asciiz "sin("
result_2:		.asciiz ") = "
scale:			.float 1073741824.0	#2^30 scale, as we using first one bit for sign, one bit for 1 or 0 and rest for fractions
pi:			.float 3373259426.0
half:			.word 1073741824
cordic_K_value:		.word 652032874		#limited precision, no sense in creating lookup table
negative_half_pi:	.word 0xE0000000
error_out_of_range:	.asciiz "Poda³eœ wartoœæ spoza zasiêgu!"
arctan_tab:	.word	#arctan(2^(-i)) lookup table after appling scale
	843314856
	497837829
	263043836
	133525158
	67021686
	33543515
	16775850
	8388437
	4194282
	2097149
	1048575
	524287
	262143
	131071
	65535
	32767
	16383
	8191
	4095
	2047
	1023
	511
	255
	127
	63
	31
	15
	8
	4
	2
	1
	0
	
.text
.globl main
main:
	la $a0, text_initial
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	move $s0, $v0
	li $s6, 1073741824
	li $s7, 0xe0000000
	
check_range:
	bgt $s0,$s6, above_range
	blt $s0,$s7, below_range
	
prepare_angle:
	mtc1 $s0, $f0
	cvt.s.w $f0, $f0
	l.s $f2, pi
	l.s $f1, scale
	div.s $f0, $f0, $f1
	mul.s $f0, $f0, $f2
	cvt.w.s $f0, $f0
	mfc1 $s0, $f0
	
prepare_loop:
	li $t0, 0			#setting loop iterator
	li $s1, 32			#32 iterations for max precision	
	lw $t1, cordic_K_value		#x initial value
	li $t2, 0			#y initial value
	move $t3, $s0			#z initial value
	
loop:
	bgeu $t0, $s1, display_results
	li $t4, 1		#sign of angle flag (if angle >= 0)
	bgez $t3, above_zero
	li $t4, -1		#if angle < 0

above_zero:
	#x(i+1) = x(i) - ((y(i)/(2^i) *sign(angle))
	#y(i)/(2^i) = y(i)>>i (arithmetic shift)
	srav $t5, $t2, $t0	#5 lower order bits are okay since i <= 31
	mul $t5, $t5, $t4
	sub $s2, $t1, $t5
	
	#y(i+1) = y(i) + ((x(i)>>i)*sign(angle))	
 	srav $t5, $t1, $t0
	mul $t5, $t5, $t4
	add $s3, $t2, $t5
	
	#z(i+1) = z(i) - (arctan_tab[i]*sign(angle))
	mulu  $t5, $t0, 4		#every integer takes 4 bytes, so we need to move 4 bytes further every iteration in our lookup table, so i*4 will point on needed value
	la $t6, arctan_tab
	addu $t6, $t5, $t6	#getting the value we want
	lw  $t5, ($t6)		#reading the value
	mul $t5, $t5, $t4	#multiplicate by sign
	sub $s4, $t3, $t5
	
	#appling new values
	move $t1, $s2
	move $t2, $s3
	move $t3, $s4
	addiu $t0, $t0, 1	#i++
	b loop

above_range:
	li $t2, 0x40000000
	sub $s0, $t2, $s0
	bgt $s0, $s6, above_range
	b check_range
	
below_range:
	li $t2, 0xD0000000
	sub $s0, $t2, $s0
	blt $s0, $s7, below_range
	b check_range

display_results:
	la $a0, result_1
	li $v0, 4
	syscall
	mtc1 $s0, $f12
	li $v0, 2
	syscall
	la $a0, result_2
	li $v0, 4
	syscall
	
	mtc1 $s3, $f0
	cvt.s.w $f0, $f0
	l.s $f2, scale
	div.s $f12, $f0, $f2
	
	li $v0, 2
	syscall
end:
	li $v0, 10
	syscall
	
	