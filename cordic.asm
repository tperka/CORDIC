.data
text_initial:		.asciiz "Podaj wartosc kata (wspolczynnik a w a*PI) dla ktorego chcesz obliczyc sinus (oraz cosinus): \n"
result_1:		.asciiz "sinus tego kata wynosi: "
result_2:		.asciiz "\ncosinus tego kata wynosi: "
scale:			.float 1073741824.0	#2^30 scale, as we using first one bit for sign, one bit for 1 or 0 and rest for fractions
pi:			.float 3373259426.0	#pi value after appling scale
half:			.float 0.5
cordic_K_value:		.word 652032874		#limited precision, no sense in creating lookup table
negative_half:		.float -0.5
error_out_of_range:	.asciiz "Poda�e� warto�� spoza zasi�gu!"
arctan_tab:		.word	#arctan(2^(-i)) lookup table after appling scale
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
	li $v0, 6
	syscall
	l.s $f1, half
	l.s $f2, negative_half
	
check_range:
	c.lt.s $f1,$f0
	bc1t above_range
	c.lt.s $f0,$f2
	bc1t below_range
	
prepare_angle:
	l.s $f1, pi
	mul.s $f0, $f0, $f1
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
	add.s $f3, $f1, $f1		#1 float
	sub.s $f0, $f3, $f0
	c.lt.s $f1, $f0
	bc1t above_range
	b check_range
	
below_range:
	add.s $f4, $f2, $f2		#-1 float
	sub.s $f0, $f4, $f0
	c.lt.s $f0, $f2
	bc1t below_range
	b check_range

display_results:
	mtc1 $s3, $f12		#preparing sin value
	cvt.s.w $f12, $f12
	l.s $f2, scale
	div.s $f12, $f12, $f2
	
	la $a0, result_1
	li $v0, 4
	syscall
	li $v0, 2
	syscall
	
	mtc1 $s2, $f12		#preparing cos value
	cvt.s.w $f12, $f12
	div.s $f12, $f12, $f2
	
	la $a0, result_2
	li $v0, 4
	syscall
	li $v0, 2
	syscall
	
end:
	li $v0, 10
	syscall
	
	
