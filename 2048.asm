#####################################################################
#	MIPS 2048 on MARS
# Program require 
#   1. Bitmap Display
#   2. Keyboary and Display MMIO Simulator
#
# Setting in Bitmap Display
#	unit width: 8,	
#	unit height: 8,
#	display width: 512,
#	display height: 512,
#	base address: $gp
# 
# Play Using Keyboard and Display MMIO Simulator
#	up: "w", 
#	down: "s",
#	left: "a", 
#	right: "d"
#
#####################################################################

	.include "macros.asm"
	.data
moving_step:	.word	15		# number of frame involve in each motion
					# set to 3 if display cannot flash fluently	
main_matrix:	.space	64
tmp_matrix:	.space	64		# privious state 
cur_max:	.word	2		# current maximum
upgrade_flag:	.word	0		# flag: whether cur_max has been updated
tar_score:	.word	512		# score for finish the game

tmp_moving:	.space	64		# record the moving pattern
moving_pairs:	.space	288		# srcX,srcY,tarX,tarY,color,size
moving_len:	.word	0		# length of moving_pairs


### 
ava_count:	.word	0	# available count
ava_index:	.space	64	# available index array
left_index:	.space	64	# index read the matrix from different direction
right_index:	.space 	64
up_index:	.space	64
down_index:	.space	64
left_addr:	.space	64	# address of matrix read in different direction
right_addr:	.space 	64
up_addr:	.space	64
down_addr:	.space	64

### constants
mat_nrow:	.word	4	# total number of row
mat_length:	.word	16	# total length of matrix
keybroad_addr:	.word	0xffff0000

display_width:	.word	64
frame_width:	.word	2
frame_color:	.word	0x6E2C00
back_color:	.word	0x000000

level_count:	.word	3
level_color:	.word	0xFF0000, 0x00FF00, 0x0000FF
level_size:	.word	1, 2, 4

msg_mat_boundry:	.asciiz	"================================="
msg_win_congrad:	.asciiz	"YOU WIN"
msg_fail:	.asciiz	"GAME OVER"

#####################################################################
##################      Main Process    #############################
	.text
Main:

	jal	cleanDisplay
	jal	initializeIndex
	jal	addNextRandom2Matrix
	jal	printMainMatrix	
	jal	drawFrame
	jal	drawMainMat

Main_loop:
	la	$t0,	main_matrix
	la	$t1,	tmp_matrix
	lw	$t2,	mat_length
	COPY_SEQ($t1, $t0, $t2)
	
	WAIT_NEXT_KEY($t0)
	PRINT_CHAR($t0)
	PRINT_CHARI(0xa)
	bne	$t0,	0x77,	check_down	# w = up
	la	$a0,	up_addr
	la	$s0,	up_index
	j	move_direction
	
check_down:
	bne	$t0,	0x73,	check_left	# s = down
	la	$a0,	down_addr
	la	$s0,	down_index
	j	move_direction
	
check_left:
	bne	$t0,	0x61,	check_right	# a = left
	la	$a0,	left_addr
	la	$s0,	left_index
	j	move_direction

check_right:
	bne	$t0,	0x64,	Main_loop	# d = right
	la	$a0,	right_addr
	la	$s0,	right_index
	j	move_direction

move_direction:	
	jal	moveOperation
	la	$a0,	main_matrix
	la	$a1,	tmp_matrix
	lw	$a2,	mat_length
	jal	compareSequence
	bne	$v0,	$zero,	Main_loop	# no state change movement
	
	###	animation
	# move index conversion
	move	$a0,	$s0
	jal	convertTmpMoving
	move	$a0,	$s0
	jal	calculateMovingPairs
	jal	drawAnimation
	jal	playAudio
	###
	
	jal	addNextRandom2Matrix
	jal	drawMainMat
	jal	printMainMatrix	
	jal	checkGameState
	j	Main_loop
	
	
Win:
	la	$a0,	msg_win_congrad
	li	$a1,	1
	li	$v0,	55
	syscall
	j	Exit

Fail:
	la	$a0,	msg_fail
	li	$a1,	0
	li	$v0,	55
	syscall
	j	Exit

Exit:
	li	$v0,	10
	syscall

####################################################################
############################# function #############################
### play audio if update the current maximum value
playAudio:
	lw	$t0,	upgrade_flag
	bne	$t0,	1,	playAudio_skip
	lw	$t1,	cur_max
	MAKE_SOUND($t1)
	sw	$zero,	upgrade_flag
	playAudio_skip:
	jr	$ra

### draw animation through the moving records
drawAnimation:
	addi	$sp,	$sp,	-28
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	sw	$s1,	8($sp)
	sw	$s2,	12($sp)
	sw	$s3,	16($sp)	
	sw	$s4,	20($sp)
	sw	$s5,	24($sp)	
	
	la	$s0,	moving_pairs
	lw	$s1,	moving_len
	lw	$s2,	moving_step
	
	li	$s3,	0		# $s3=i current moving step

	drawAnimat_loop0:
		li	$s4,	0		# $s4=j	element
		drawAnimat_remove_loop:
			li	$t0,	6
			mul	$t0,	$t0,	$s4
			SHIFT_WORD($s0, $t0, $s5)	# $s5= address of j moving pair
			
			move	$a0,	$s5
			move	$a1,	$s3
			jal	calculateCurrentPosition
		
			li	$t0,	5	
			LOAD_ARRAY_ELEMENT($s5, $t0, $t0)
			move	$a0,	$v0
			move	$a1,	$v1
			move	$a2,	$t0
			lw	$a3,	back_color
			jal	drawSquare
		
			addi	$s4,	$s4,	1
			blt	$s4,	$s1,	drawAnimat_remove_loop

		addi	$s3,	$s3,	1
		li	$s4,	0		# $s4=j	element	
		drawAnimat_plot_loop:
			li	$t0,	6
			mul	$t0,	$t0,	$s4
			SHIFT_WORD($s0, $t0, $s5)	# $s5= address of j moving pair		

			move	$a0,	$s5
			move	$a1,	$s3
			jal	calculateCurrentPosition

			li	$t0,	4	#color
			li	$t1,	5	#size
			LOAD_ARRAY_ELEMENT($s5, $t0, $t0)
			LOAD_ARRAY_ELEMENT($s5, $t1, $t1)
			move	$a0,	$v0
			move	$a1,	$v1
			move	$a3,	$t0
			move	$a2,	$t1
			jal	drawSquare

			addi	$s4,	$s4,	1
			blt	$s4,	$s1,	drawAnimat_plot_loop
		SLEEP(2500)
		blt	$s3,	$s2,	drawAnimat_loop0
	
	li	$s4,	0		# $s4=j	element
	drawAnimat_remove_final_loop:
		li	$t0,	6
		mul	$t0,	$t0,	$s4
		SHIFT_WORD($s0, $t0, $s5)	# $s4= address of j moving pair
		
		move	$a0,	$s5
		move	$a1,	$s3
		jal	calculateCurrentPosition
		
		li	$t0,	5	
		LOAD_ARRAY_ELEMENT($s5, $t0, $t0)
		move	$a0,	$v0
		move	$a1,	$v1
		move	$a2,	$t0
		lw	$a3,	back_color
		jal	drawSquare
		
		addi	$s4,	$s4,	1
		blt	$s4,	$s1,	drawAnimat_remove_final_loop
	
	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)
	lw	$s2,	12($sp)
	lw	$s3,	16($sp)	
	lw	$s4,	20($sp)
	lw	$s5,	24($sp)	
	addi	$sp,	$sp,	28	
	jr	$ra

		

# input: $a0: address of a moving pair element, $a1:step
# output: $v0=x, $v1=y
calculateCurrentPosition:
	move	$t0,	$a0	# $t0=moving pair
	move	$t1,	$a1	# $t1=current step
	
	li	$t2,	0	# srcX
	li	$t3,	1	# srcY
	li	$t4,	2	# tarX
	li	$t5,	3	# tarY
	LOAD_ARRAY_ELEMENT($t0, $t2, $t2)
	LOAD_ARRAY_ELEMENT($t0, $t3, $t3)
	LOAD_ARRAY_ELEMENT($t0, $t4, $t4)
	LOAD_ARRAY_ELEMENT($t0, $t5, $t5)
	
	lw	$t9,	moving_step

	beq	$t2,	$t4,	y_shift
		move	$v1,	$t3
		sub	$t6,	$t4,	$t2
		div	$t6,	$t9
		mflo	$v0
		mul	$v0,	$v0,	$t1
		add	$v0,	$v0,	$t2
		j	return
		
	y_shift:
		move	$v0,	$t2
		sub	$t6,	$t5,	$t3
		div	$t6,	$t9
		mflo	$v1
		mul	$v1,	$v1,	$t1
		add	$v1,	$v1,	$t3

	return:
		jr	$ra


### convert tmp_moving to index
# input: $a0=direction index
convertTmpMoving:
	move	$t0,	$a0			# $t0= direction index
	move	$t9,	$t0
	la	$t1,	tmp_moving
	lw	$t2,	mat_nrow
	li	$t3,	0			# $t3=i
	convertTmpMoving_loop0:
		li	$t4,	0		# $t4=j
		convertTmpMoving_loop1:
			LOAD_ARRAY_ELEMENT($t1, $t4, $t5)
			LOAD_ARRAY_ELEMENT($t0, $t5, $t5)
			STORE_ARRAY_ELEMENT($t1, $t4, $t5)
			addi	$t4,	$t4,	1
			blt	$t4,	$t2,	convertTmpMoving_loop1

		SHIFT_WORD($t0, $t2, $t0)	
		SHIFT_WORD($t1, $t2, $t1)
		addi	$t3,	$t3,	1
		blt	$t3,	$t2,	convertTmpMoving_loop0
		
	jr	$ra

### calculate moving pairs
# input: $a0=direction index
calculateMovingPairs:
	addi	$sp,	$sp,	-36
	sw	$ra,	0($sp)
	sw	$s0,	4($sp)
	sw	$s1,	8($sp)
	sw	$s2,	12($sp)
	sw	$s3,	16($sp)	
	sw	$s4,	20($sp)
	sw	$s5,	24($sp)
	sw	$s6,	28($sp)	
	sw	$s7,	32($sp)		
		
	move	$s0,	$a0		# $s0 = moving direction index (source)
	la	$s1,	tmp_moving	# $s1 = moving target index
	lw	$s2,	mat_length
	la	$s3,	moving_pairs
	li	$s4,	0		# moving pairs length
	li	$s5,	0		# $s5=i
	
	calculateMovingPairs_loop0:
		LOAD_ARRAY_ELEMENT($s0, $s5, $s6)	# $s6 = src index
		LOAD_ARRAY_ELEMENT($s1, $s5, $s7)	# $s7 = tar index
		beq	$s6,	$s7,	 calculateMovingPairs_next	# not moving case
	
		move	$a0,	$s6
		jal	index2Position
		li	$t0,	0
		li	$t1,	1
		STORE_ARRAY_ELEMENT($s3, $t0, $v0)	# store srcX, srcY
		STORE_ARRAY_ELEMENT($s3, $t1, $v1)
	
		move	$a0,	$s7
		jal	index2Position
		li	$t0,	2
		li	$t1,	3
		STORE_ARRAY_ELEMENT($s3, $t0, $v0)	# store tarX, tarY
		STORE_ARRAY_ELEMENT($s3, $t1, $v1)
	
		la	$t0,	tmp_matrix
		LOAD_ARRAY_ELEMENT($t0, $s6, $t1)
		GET_COLOR_SIZE($t1, $t2, $t3)		# $t2 = color, $t3 = size
		li	$t0,	4
		li	$t1,	5
		STORE_ARRAY_ELEMENT($s3, $t0, $t2)
		STORE_ARRAY_ELEMENT($s3, $t1, $t3)
		addi	$s3,	$s3,	24
		addi	$s4,	$s4,	1
	
		calculateMovingPairs_next:
		addi	$s5,	$s5,	1
		blt	$s5,	$s2,	calculateMovingPairs_loop0

	sw	$s4,	moving_len

	lw	$ra,	0($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)
	lw	$s2,	12($sp)
	lw	$s3,	16($sp)	
	lw	$s4,	20($sp)
	lw	$s5,	24($sp)
	lw	$s6,	28($sp)	
	lw	$s7,	32($sp)		
	addi	$sp,	$sp,	36
	jr	$ra


### checkGameState
# return if game can continue
checkGameState:

	addi	$sp,	$sp,	-12
	sw	$ra,	($sp)
	sw	$s0,	4($sp)
	sw	$s1,	8($sp)	
	
	# win
	lw	$t0,	cur_max
	lw	$t1,	tar_score
	bge	$t0,	$t1,	Win
	
	# available space
	lw	$t0,	ava_count
	bgt	$t0,	$zero,	 checkGameState_alive
	
	# available operation
	lw	$s0,	cur_max
	lw	$s1,	upgrade_flag
	
	la	$a0,	left_addr
	jal	checkDirectionWork
	beq	$v0,	$zero,	checkGameState_restore_max
	
	la	$a0,	right_addr
	jal	checkDirectionWork
	beq	$v0,	$zero,	checkGameState_restore_max
	
	la	$a0,	up_addr
	jal	checkDirectionWork
	beq	$v0,	$zero,	checkGameState_restore_max
	
	la	$a0,	down_addr
	jal	checkDirectionWork
	beq	$v0,	$zero,	checkGameState_restore_max
	j	Fail	
	checkGameState_restore_max:
		sw	$s0,	cur_max
		sw	$s1,	upgrade_flag

checkGameState_alive:

	lw	$ra,	($sp)
	lw	$s0,	4($sp)
	lw	$s1,	8($sp)	
	addi	$sp,	$sp,	12
	jr	$ra


### checkDirectionWork
# input: $a0: direction address
# output: $v0: 1=stock,	0=can move
checkDirectionWork:
	STORE_RA

	move	$t0,	$a0	# move direction
	la	$t1,	main_matrix
	la	$t2,	tmp_matrix
	lw	$t3,	mat_length
	COPY_SEQ($t2, $t1, $t3)
	
	move	$a0,	$t0
	jal	moveOperation
	
	la	$a0,	main_matrix
	la	$a1,	tmp_matrix
	lw	$a2,	mat_length
	jal	compareSequence		
	
	la	$t0,	main_matrix
	la	$t1,	tmp_matrix
	lw	$t2,	mat_length
	COPY_SEQ($t0, $t1, $t2)
	
	RESTORE_RA
	jr	$ra


#######################################################
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

	lw	$t0,	ava_count
	addi	$t0,	$t0,	-1
	sw	$t0,	ava_count

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
	li	$t3,	0		# $t3 = i 
moveOperation_loop1:
	LOAD_ARRAY_ELEMENT($s1, $t3, $t5)
	lw	$t5,	($t5)		# $t5 = current value

	move	$t7,	$t3
	move	$t4,	$t2
	beq	$t5,	$zero,	moveOperation_next1	# case [i]==0
	
	addi	$t4,	$t3,	-1	# $t4 = j
	blt	$t4,	$zero,	moveOperation_next1
	moveOperation_loop2:

		LOAD_ARRAY_ELEMENT($s1, $t4, $t6)	
		lw	$t6,	($t6)			# $t6 = comparing value
		move	$t7,	$t4			# $t7 = target index
		beq	$t6,	$zero,	moveOperation_pass_through_zero
		# not equal to zero => check merge
		bne	$t5,	$t6,	moveOperation_stock
		# merge equal value 
		sll	$t5,	$t5,	1		# $t5 = new value to store
		
		lw	$t8,	cur_max
		ble	$t5,	$t8,	moveOperation_merge_not_update_max
		sw	$t5,	cur_max
		li	$t9,	1
		sw	$t9,	upgrade_flag
	
		moveOperation_merge_not_update_max:
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
	#jal	cleanDisplay
	jal	drawFrame

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
