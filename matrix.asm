#####################################################################
#####################################################################

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

tmp_value:	.space	64
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

### constants
mat_nrow:	.word	4	# total number of row
mat_length:	.word	16

msg_mat_boundry:	.asciiz	"================================="

#####################################################################
#####################################################################
	.text
Main:

	jal	initializeIndex

#loop:
	jal	addNextRandom2Matrix
	jal	addNextRandom2Matrix
	jal	addNextRandom2Matrix
	jal	addNextRandom2Matrix
	jal	addNextRandom2Matrix
#	jal	printMainMatrix
#	j	loop


	jal	printMainMatrix
	la	$a0,	left_index
	jal	moveOperation
	jal	printMainMatrix	

	la	$a0,	up_index
	jal	moveOperation
	jal	printMainMatrix		
	
	




#	la	$a0,	left_index
#	jal	printSequenceByIndex


Exit:
	li	$v0,	10
	syscall

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
	la	$a0,	left_index
	jal	indexArray2AddressArray
	la	$a0,	right_index
	jal	indexArray2AddressArray
	la	$a0,	up_index
	jal	indexArray2AddressArray
	la	$a0,	down_index
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

