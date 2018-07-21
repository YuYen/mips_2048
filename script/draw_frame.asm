	.data

frame_width:	.word	2
frame_size:	.word	64
frame_num:	.word	5
frame_index:	.word	0,15,30,45,60
frame_color:	.word	0x6E2C00

	.text
	lw	$t0,	frame_size
	lw	$t1,	frame_width
	la	$t2,	frame_index
	mul	$t3,	$t0,	$t1	# $t3 = 1 block length
	sll	$t3,	$t3,	2	
	
	li	$t9,	0
	move	$s0,	$gp		# $s0 = current base
	lw	$s1,	frame_color
	lw	$s2,	frame_num
loop0:
	lw	$t4,	($t2)		# $t4 = line number

loop1:
	mul	$t5,	$t4,	$t0	
	sll	$t5,	$t5,	2
	add	$t5,	$t5,	$s0	# $t5 = start position
	add	$t6,	$t3,	$t5	# $t6 = end position
	
loop2:
	sw	$s1,	($t5)
	addiu	$t5,	$t5,	4
	blt	$t5,	$t6,	loop2
	addi	$t9,	$t9,	1
	addi	$t2,	$t2,	4
	blt	$t9,	$s2,	loop0
	
	
	
exit:
	li	$v0,	10
	syscall
		

	
	
	
	
	