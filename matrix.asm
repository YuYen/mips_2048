#####################################################################
#####################################################################

.macro	GET_COLOR_SIZE(%val, %color, %size)
	li	$a0,	2
	li	$a2,	0

	GET_COLOR_SIZE_loop:	
		and	$a1,	$a0,	%val
		sll	$a0,	$a0,	1
		addi	$a2,	$a2,	1
		beq	$a1,	$zero,	GET_COLOR_SIZE_loop
	
	addi	$a2,	$a2,	-1
	lw	$a0,	level_count
	divu	$a2,	$a0
	mfhi	%size
	mflo	%color
	la	$a1,	level_size
	LOAD_ARRAY_ELEMENT($a1,	%size, %size)
	la	$a1,	level_color
	LOAD_ARRAY_ELEMENT($a1,	%color, %color)
.end_macro

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

.macro	COPY_SEQ(%tar, %src, %len)
	li	$a0,	0
	move	$a1,	%tar
	move	$a2,	%src
	COPY_SEQ_next:
		lw	$a3,	($a2)
		sw	$a3,	($a1)
		addi	$a0,	$a0,	1
		addi	$a1,	$a1,	4
		addi	$a2,	$a2,	4
		blt	$a0,	%len,	COPY_SEQ_next
.end_macro

.macro	SLEEP(%val)
	li	$a0,	0
	loopx:
		nop
		addi	$a0,	$a0,	1
		blt	$a0,	%val,	loopx
.end_macro

.macro	WAIT_NEXT_KEY(%val)
	lw	$a1,	keybroad_addr

#	li	$a3,	1000000
#	li	$a3,	100000
	WAIT_NEXT_KEY_wait:
		SLEEP(100000)
#		li	$a2,	0
#		loopx:
#			addi	$a2,	$a2,	1
#			blt	$a2,	$a3,	loopx
		lw	%val,	($a1)
		beq	%val,	$zero,	WAIT_NEXT_KEY_wait
	lw	%val,	4($a1)
.end_macro

.macro	SHIFT_WORD(%add, %pos, %res)
	sll	$a0,	%pos,	2
	add	%res,	%add,	$a0
.end_macro

.macro	LOAD_ARRAY_ELEMENT(%add, %pos, %res)
	SHIFT_WORD(%add, %pos, %res)
	lw	%res,	(%res)
.end_macro

.macro	STORE_ARRAY_ELEMENT(%add, %pos, %val)
	SHIFT_WORD(%add, %pos, $a1)
	sw	%val,	($a1)
.end_macro

.macro	CHECKBIT(%val, %pos, %res)
	srlv 	$a0,	%val,	%pos
	and	%res,	$a0,	1
.end_macro

.macro	SETBIT (%val, %pos)
	li	$a0,	1
	sllv 	$a0,	$a0,	%pos
	or	%val,	%val,	$a0
.end_macro

.macro	STORE_RA
	addi	$sp,	$sp,	-4
	sw	$ra,	0($sp)
.end_macro
	
.macro	RESTORE_RA
	lw	$ra,	0($sp)
	addi	$sp,	$sp,	4
.end_macro

.macro	PRINT_INT (%val)
	li	$v0,	1
	move	$a0,	%val
	syscall
.end_macro

.macro	PRINT_CHARI (%val)
	li	$v0,	11
	li	$a0,	%val
	syscall
.end_macro

.macro	PRINT_CHAR (%val)
	li	$v0,	11
	move	$a0,	%val
	syscall
.end_macro

.macro	PRINT_STR (%val)
	li	$v0,	4
	move	$a0,	%val
	syscall
.end_macro

#####################################################################
#####################################################################
	.data
main_matrix:	.space	64
tmp_matrix:	.space	64

# tmp_value:	.space	64
tmp_moving:	.space	64

#test_value:	.word	2, 2, 4, 0
test_value:	.word	0, 0, 2, 2

### 
ava_count:	.word	0	# available count
ava_index:	.space	64	# available index array
left_index:	.space	64
right_index:	.space 	64
up_index:	.space	64
down_index:	.space	64
left_addr:	.space	64
right_addr:	.space 	64
up_addr:	.space	64
down_addr:	.space	64

### constants
mat_nrow:	.word	4	# total number of row
mat_length:	.word	16
keybroad_addr:	.word	0xffff0000

display_width:	.word	64
frame_width:	.word	2
frame_color:	.word	0x6E2C00
back_color:	.word	0x000000

level_count:	.word	3
level_color:	.word	0xFF0000, 0x00FF00, 0x0000FF
level_size:	.word	1, 2, 4

msg_mat_boundry:	.asciiz	"================================="

#####################################################################
#####################################################################
	.text
Main:

	jal	initializeIndex
	jal	addNextRandom2Matrix
	jal	printMainMatrix	
	jal	drawFrame
	jal	drawMainMat

loop:
	
	la	$t0,	main_matrix
	la	$t1,	tmp_matrix
	lw	$t2,	mat_length
	COPY_SEQ($t1, $t0, $t2)
	
	WAIT_NEXT_KEY($t0)
	PRINT_CHAR($t0)
	PRINT_CHARI(0xa)
	bne	$t0,	0x77,	check_down	# w = up
	la	$a0,	up_addr
	j	move_direction
	
check_down:
	bne	$t0,	0x73,	check_left	# s = down
	la	$a0,	down_addr
	j	move_direction
	
check_left:
	bne	$t0,	0x61,	check_right	# a = left
	la	$a0,	left_addr
	j	move_direction

check_right:
	bne	$t0,	0x64,	loop		# d = right
	la	$a0,	right_addr
	j	move_direction

move_direction:	
	jal	moveOperation
	la	$a0,	main_matrix
	la	$a1,	tmp_matrix
	lw	$a2,	mat_length
	jal	compareSequence
	bne	$v0,	$zero,	loop
	jal	addNextRandom2Matrix
	
	### check GG condition
	jal	drawMainMat
	jal	printMainMatrix	
	j	loop
	

Exit:
	li	$v0,	10
	syscall



###
# input: $a0: src1, $a1: src2,	$a2: length
# output: $v0: 0:different, 1:the same
compareSequence:
	li	$t0,	0
	li	$v0,	1
	compareSequence_loop:
		lw	$t1,	($a0)
		lw	$t2,	($a1)
		beq	$t1,	$t2,	compareSequence_next
		li	$v0,	0
		j	compareSequence_return
		
		compareSequence_next:
		addi	$t0,	$t0,	1
		addi	$a0,	$a0,	4
		addi	$a1,	$a1,	4
		blt	$t0,	$a2,	compareSequence_loop
		
compareSequence_return:
	jr	$ra

####################################################################
############################# function #############################

### initialize the indexes of different order
initializeIndex:
	STORE_RA
	la	$t9,	left_index
	la	$t8,	right_index
	la	$t7,	up_index
	la	$t6,	down_index

	lw	$t0,	mat_length
	addi	$t0,	$t0,	-1
	lw	$t1,	mat_nrow

	li	$t2,	0	# $t2 = current position
	li	$t3,	0	# $t3 = i
	
	initializeIndex_loop1:
		li	$t4,	0	# $t4 = j
		initializeIndex_loop2:
			# store left & right index
			sll	$t5,	$t3,	2
			add	$t5,	$t5	$t4
			sw	$t5,	($t9)
			sub	$t5,	$t0,	$t5
			sw	$t5,	($t8)
			# store up & down index
			sll	$t5,	$t4,	2
			add 	$t5,	$t5,	$t3
			sw	$t5,	($t7)
			sub	$t5,	$t0,	$t5
			sw	$t5,	($t6)
	
			addi	$t9,	$t9,	4
			addi	$t8,	$t8,	4
			addi	$t7,	$t7,	4
			addi	$t6,	$t6,	4	
			addi	$t4,	$t4,	1
			blt	$t4,	$t1,	initializeIndex_loop2
		
		addi	$t3,	$t3,	1
		blt	$t3,	$t1,	initializeIndex_loop1
	
	# convert order index to actual address
	la	$t0,	left_index
	lw	$s0,	mat_length
	la	$t1,	left_addr
	COPY_SEQ($t1, $t0, $s0)
	move	$a0,	$t1
	jal	indexArray2AddressArray
	
	la	$t0,	right_index
	lw	$s0,	mat_length
	la	$t1,	right_addr
	COPY_SEQ($t1, $t0, $s0)
	move	$a0,	$t1
	jal	indexArray2AddressArray
	
	la	$t0,	up_index
	lw	$s0,	mat_length
	la	$t1,	up_addr
	COPY_SEQ($t1, $t0, $s0)
	move	$a0,	$t1
	jal	indexArray2AddressArray
	
	la	$t0,	down_index
	lw	$s0,	mat_length
	la	$t1,	down_addr
	COPY_SEQ($t1, $t0, $s0)
	move	$a0,	$t1
	jal	indexArray2AddressArray

	RESTORE_RA
	jr	$ra


### convert index array to actual address array
# current version only change 4, but can be extended to change whole
indexArray2AddressArray:
	la	$t0,	main_matrix
	lw	$t1,	mat_length

	li	$t2,	0
	indexArray2AddressArray_loop: 
		lw	$t3,	($a0)
		sll	$t3,	$t3,	2
		add	$t3,	$t3,	$t0
		sw	$t3,	($a0)
		addi	$t2,	$t2,	1
		addi	$a0,	$a0,	4
		blt	$t2,	$t1,	indexArray2AddressArray_loop
	
	jr	$ra

### print a sequence of int
# input: $a0: target array, $a1: length
printSequence:
	move	$t9,	$a0
	move	$t0,	$a1
	li	$t1,	0xa
	PRINT_CHAR($t1)
	li	$t1,	0
	
	printSequen_loop:
		lw	$t3,	($t9)
		
		PRINT_INT( $t3)
		addi	$t1,	$t1,	1
		addi	$t9,	$t9,	4
		blt	$t1,	$t0,	printSequen_loop
	jr	$ra

### print main matrix using different order sequence
printSequenceByIndex:
	move	$t9,	$a0
	li	$t0,	0xa
	PRINT_CHAR($t0)
	lw	$t0,	mat_length
	li	$t1,	0
	
	printSequenceByIndex_loop:
		lw	$t2,	($t9)
		lw	$t3,	($t2)
		
		PRINT_INT( $t3)
		addi	$t1,	$t1,	1
		addi	$t9,	$t9,	4
		blt	$t1,	$t0,	printSequenceByIndex_loop
	jr	$ra

### print current main matrix
printMainMatrix:
	li	$t4,	0xa
	PRINT_CHAR($t4)
	la	$t5,	msg_mat_boundry
	PRINT_STR($t5)
	li	$t4,	0xa
	PRINT_CHAR($t4)

	la	$t0,	main_matrix
	lw	$t1,	mat_nrow
	li	$t2,	0	# $t2 = i

	printMainMatrix_loop:
		li	$t3,	0	# $t3 = j	
		
		printMainMatrix_loop2:	
			li	$t4,	0x7c
			PRINT_CHAR($t4)
			li	$t4,	0x20
			PRINT_CHAR($t4)
			lw	$t4,	($t0)
			PRINT_INT($t4)
			li	$t4,	0x9
			PRINT_CHAR($t4)	
				
			addi	$t0,	$t0,	4
			addi	$t3,	$t3,	1
			blt	$t3,	$t1,	printMainMatrix_loop2
	
		addi	$t2,	$t2,	1
		li	$t4,	0x7c
		PRINT_CHAR($t4)
		li	$t4,	0xa
		PRINT_CHAR($t4)
		blt	$t2,	$t1,	printMainMatrix_loop

	PRINT_STR($t5)
	jr	$ra


### add next random 2 to matrix
addNextRandom2Matrix:
	STORE_RA
	jal	findAvailableIndex	
	lw	$a0,	ava_count
	jal	generateRandom
	sll	$v0,	$v0,	2
	la	$t0,	main_matrix	# $t0 = address of target element
	la	$t1,	ava_index	# $t1 = available index of main_martix
	add	$t1,	$t1,	$v0
	lw	$t1,	($t1)
	sll	$t1,	$t1,	2
	add	$t0,	$t0,	$t1
	
	lw	$t2,	($t0)
	li	$t2,	2
	sw	$t2,	($t0)
	
	RESTORE_RA
	jr	$ra

### find available space
# find the index and number of zero in main_matrix
# result store in ava_count, ava_index
findAvailableIndex:
	la	$t0,	main_matrix		
	la	$t1,	ava_index
	lw	$t2,	mat_length
	li	$t3,	0	# $t3 = available count
	li	$t4,	0	# $t4 = i
	
	findAvailableIndex_loop:	
		lw	$t5,	($t0)
		bne	$t5,	$zero,	findAvailableIndex_skip
		addi	$t3,	$t3,	1	# available count++
		sw	$t4,	($t1)
		addi	$t1,	$t1,	4
	findAvailableIndex_skip:	
		addi	$t4,	$t4,	1	# i++
		addi	$t0,	$t0,	4
		blt	$t4,	$t2,	findAvailableIndex_loop
		sw	$t3,	ava_count
	
	jr	$ra
	
### generate random int in range [0, $a0)
# output: $v0
generateRandom:
	li	$v0,	42
	move	$a1,	$a0
	syscall
	move	$v0,	$a0
	jr	$ra

### move the plate
# input: $a0 address array of the target direction
moveOperation:
	addi	$sp,	$sp,	-12	# store registors
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	sw	$s1,	8($sp)	
	
	la	$s0,	tmp_moving
	move	$s1,	$a0		# $s1 = array start address
	lw	$t0,	mat_nrow
	li	$t1,	0		# $t1 = outer loop

moveOperation_loop0:	
	li	$t2,	0		# $t2 = lowest bound
	li	$t3,	1		# $t3 = i skip first 
moveOperation_loop1:
	LOAD_ARRAY_ELEMENT($s1, $t3, $t5)
	lw	$t5,	($t5)		# $t5 = current value

	move	$t7,	$t3
	move	$t4,	$t2
	beq	$t5,	$zero,	moveOperation_next1	# case [i]==0
	
	addi	$t4,	$t3,	-1	# $t4 = j
	moveOperation_loop2:

		LOAD_ARRAY_ELEMENT($s1, $t4, $t6)	
		lw	$t6,	($t6)			# $t6 = comparing value
		move	$t7,	$t4			# $t7 = target index
		beq	$t6,	$zero,	moveOperation_pass_through_zero
		# not equal to zero => check merge
		bne	$t5,	$t6,	moveOperation_stock
		# merge equal value ### audio may add here
		sll	$t5,	$t5,	1		# $t5 = new value to store
		addi	$t4,	$t4,	1
		j	moveOperation_store_value

		moveOperation_stock:
			addi	$t7,	$t7,	1
			j	moveOperation_store_value

		moveOperation_pass_through_zero:
			addi	$t4,	$t4,	-1
			blt	$t4,	$t2,	moveOperation_store_value		# if(j<lowest) next1
			j	moveOperation_loop2

	moveOperation_store_value:
		LOAD_ARRAY_ELEMENT($s1, $t7, $t6)
		sw	$t5,	($t6)
		beq	$t3,	$t7,	moveOperation_next1		# value not moved
		LOAD_ARRAY_ELEMENT($s1, $t3, $t6)	# moved value => set previous to zero
		sw	$zero,	($t6)

	moveOperation_next1:
		STORE_ARRAY_ELEMENT($s0, $t3, $t7)	# store moving target
		move	$t2,	$t4		
		addi	$t3,	$t3,	1		# i++
		blt	$t3,	$t0,	moveOperation_loop1
	
	addi	$t1,	$t1,	1
	SHIFT_WORD( $s0, $t0, $s0)			# move to next column
	SHIFT_WORD( $s1, $t0, $s1)
	blt	$t1,	$t0,	moveOperation_loop0
	
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)	
	addi	$sp,	$sp,	12
	jr	$ra


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



########################################################
### draw
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

removeMoved:
	la	$t0,	tmp_moving
	lw	$t1,	mat_nrow
	li	$t2,	0	# i
	li	$t3,	0	# 
loop0:
	
	

### drawMainMat
drawMainMat:
	addi	$sp,	$sp,	-24
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	sw	$s1,	8($sp)
	sw	$s2,	12($sp)
	sw	$s3,	16($sp)
	sw	$s4,	20($sp)
	
	la	$s0,	main_matrix
	lw	$s1,	mat_length
	li	$s2,	0
	
	# draw background
	jal	cleanDisplay
	jal	drawFrame
#	lw	$a2,	display_width
#	srl	$a0,	$a2,	1
#	srl	$a1,	$a2,	1
#	srl	$a2,	$a2,	1
#	lw	$a3,	frame_width
#	sub	$a2,	$a2,	$a3
#	lw	$a3,	back_color
#	jal	drawSquare
	# input: $a0:x, $a1:y, $a2:size, $a3:color
	

drawMainMat_loop:

	LOAD_ARRAY_ELEMENT($s0, $s2, $t0)
	beq	$t0,	$zero,	drawMainMat_next
	
	GET_COLOR_SIZE($t0, $s3, $s4)
	
	move	$a0,	$s2
	jal	index2Position
	
	move	$a0,	$v0
	move	$a1,	$v1
	move	$a2,	$s4
	move	$a3,	$s3
	jal	drawSquare
	
drawMainMat_next:
	addi	$s2,	$s2,	1
	blt	$s2,	$s1,	drawMainMat_loop
	
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)
	lw	$s2,	12($sp)
	lw	$s3,	16($sp)
	lw	$s4,	20($sp)
	addi	$sp,	$sp,	24
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
