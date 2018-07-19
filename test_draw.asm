.macro	GET_PLOT_ADDRESS(%x, %y, %addr)
	lw	$a0,	display_width
	mulu 	%addr,	%y,	$a0
	addu	%addr,	%addr,	%x
	sll	%addr,	%addr,	2
	addu	%addr,	%addr,	$gp
.end_macro

.macro	DRAW_SEGMENT_BY_POINT(%x, %y, %len, %color)
	GET_PLOT_ADDRESS(%x, %y, $a1)
	li	$a0,	0
	move	$a2,	%len
	DRAW_SEGMENT_loop:
		sw	%color,	($a1)
		addi	$a0,	$a0,	1
		addi	$a1,	$a1,	4
		blt	$a0,	$a2,	DRAW_SEGMENT_loop
.end_macro

.macro	DRAW_SEGMENT_BY_ADDR(%addr, %len, %color)
	li	$a0,	0
	move	$a1,	%addr
	move	$a2,	%len
	DRAW_SEGMENT_loop:
		sw	%color,	($a1)
		addi	$a0,	$a0,	1
		addi	$a1,	$a1,	4
		blt	$a0,	$a2,	DRAW_SEGMENT_loop
.end_macro


	.data
mat_nrow:	.word	4	
mat_length:	.word	16

display_width:	.word	64
frame_width:	.word	2
frame_color:	.word	0x6E2C00
back_color:	.word	0x000000

level_color:	.word	0xFF0000, 0x00FF00, 0x0000FF
level_size:	.word	1, 2, 4

	.text

	jal	drawFrame
	
	li	$s0,	0
	lw	$s1,	mat_nrow
#	lw	$s1,	mat_length
loop:	
	move	$a0,	$s0
	jal	index2Position

	move	$a0,	$v0
	move	$a1,	$v1
	
	addi	$a2,	$s0,	2
	
	li	$a3,	0xFF0000
	jal	drawSquare
	
	addi	$s0,	$s0,	1
	blt	$s0,	$s1,	loop

exit:
	li	$v0,	10
	syscall

# input: $a0: position index
# output: $v0:x, $v1:y
index2Position:
	lw	$t0,	mat_nrow
	divu	$a0,	$t0
	mfhi	$t1	# $t1=R
	mflo	$t2	# $t2=Q
	lw	$t3,	display_width
	lw	$t4,	frame_width
	sll	$t5,	$t4,	1	
	sub	$t3,	$t3,	$t5	# $t3: width w/o frame
	divu	$t3,	$t0
	mflo	$t6			# $t6: mat width
	srl	$t7,	$t6,	1	# $t7: center offset
	add	$t7,	$t7,	$t4
	mul	$v0,	$t1,	$t6
	add	$v0,	$v0,	$t7
	mul	$v1,	$t2,	$t6
	add	$v1,	$v1,	$t7
	
	jr	$ra




drawFrame:
	li	$t0,	0	
	li	$t1,	0	
	lw	$t2,	display_width
	sll	$t5,	$t2,	1
	lw	$t3,	frame_color
	DRAW_SEGMENT_BY_POINT($t0, $t1, $t5, $t3)
	
	lw	$t6,	frame_width
	sub	$t1,	$t2,	$t6
	DRAW_SEGMENT_BY_POINT($t0, $t1, $t5, $t3)

	sll	$t4,	$t6,	1
drawFrame_loop:
	DRAW_SEGMENT_BY_POINT($t1, $t0, $t4, $t3)
	addi	$t0,	$t0,	1
	blt	$t0,	$t2,	drawFrame_loop
	
	jr	$ra

### clean display to back_color
cleanDisplay:
	move	$t0,	$gp
	lw	$t1,	display_width
	mul	$t1,	$t1,	$t1
	sll	$t1,	$t1,	2
	add	$t1,	$t0,	$t1
	lw	$t2,	back_color
	
cleanDisplay_loop:
	sw	$t2,	($t0)
	addi	$t0,	$t0,	4
	blt	$t0,	$t1,	cleanDisplay_loop
	
	jr	$ra

### drawSquare
# input: $a0:x, $a1:y, $a2:size, $a3:color
drawSquare:
	sub	$t0,	$a0,	$a2	# $t0: top-left x
	sub	$t1,	$a1,	$a2	# $t1: top-left y
	GET_PLOT_ADDRESS($t0, $t1, $a1)
	move	$t2,	$a0
	sll	$t2,	$t2,	2	# $t2: display_width in bytes
	move	$t0,	$a1		# $t0: top-left address
	move	$t3,	$a3		# $t3: color
	sll	$t1,	$a2,	1
	addi	$t1,	$t1,	1	# $t1: length
	li	$t4,	0

drawSquare_loop:
	DRAW_SEGMENT_BY_ADDR($t0, $t1, $t3)
	addi	$t4,	$t4,	1
	add	$t0,	$t0,	$t2
	blt	$t4,	$t1,	drawSquare_loop

	jr	$ra



