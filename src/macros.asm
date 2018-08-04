# make sound based on the current maximum
.macro	MAKE_SOUND(%val)
	li	$a0,	0
	move	$a1,	%val
	beq	$a1,	$zero,	MAKE_SOUND_return
	MAKE_SOUND_loopx:
		srl	$a1,	$a1,	1
		addi	$a0,	$a0,	1
		and	$a2,	$a1,	1
		bne	$a2,	1,	MAKE_SOUND_loopx
	
	MAKE_SOUND_return:
	mul	$a2,	$a0,	8
	addi	$a0,	$a0,	60
	li	$a1,	2000
	li	$a3,	100
	li	$v0,	31
	syscall
.end_macro

# get color & size based on the current maximum
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

# convert x, y axis to plot address
.macro	GET_PLOT_ADDRESS(%x, %y, %addr)
	lw	$a0,	display_width
	mulu 	%addr,	%y,	$a0
	addu	%addr,	%addr,	%x
	sll	%addr,	%addr,	2
	addu	%addr,	%addr,	$gp
.end_macro

# draw a segment which starts from (x, y) 
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

# draw a segment which starts from the address
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

# copy sequence from src to tar
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

# sleep implement with nop loop
.macro	SLEEP(%val)
	li	$a0,	0
	SLEEP_loopx:
		nop
		addi	$a0,	$a0,	1
		blt	$a0,	%val,	SLEEP_loopx
.end_macro

# wait next key from keybroad simulator
.macro	WAIT_NEXT_KEY(%val)
	lw	$a1,	keybroad_addr
	WAIT_NEXT_KEY_wait:
		SLEEP(1000)
		lw	%val,	($a1)
		beq	%val,	$zero,	WAIT_NEXT_KEY_wait
	lw	%val,	4($a1)
.end_macro

# shift address in unit of word
.macro	SHIFT_WORD(%add, %pos, %res)
	sll	$a0,	%pos,	2
	add	%res,	%add,	$a0
.end_macro

# load a word from an array
.macro	LOAD_ARRAY_ELEMENT(%add, %pos, %res)
	SHIFT_WORD(%add, %pos, %res)
	lw	%res,	(%res)
.end_macro

# store a word into an array
.macro	STORE_ARRAY_ELEMENT(%add, %pos, %val)
	SHIFT_WORD(%add, %pos, $a1)
	sw	%val,	($a1)
.end_macro

# push $ra into stack
.macro	STORE_RA
	addi	$sp,	$sp,	-4
	sw	$ra,	0($sp)
.end_macro

# pop $ra from stack
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
