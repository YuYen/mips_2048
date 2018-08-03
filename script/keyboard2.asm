.macro	PRINT_CHAR (%val)
	li	$v0,	11
	move	$a0,	%val
	syscall
.end_macro

#################
.macro	SLEEP_SYSCALL(%val)	# sleep using syscall
	li	$v0,	32
	li	$a0,	%val
	syscall
.end_macro

#################
.macro	SLEEP_NOP(%val)		# sleep using nop loop
	li	$a0,	0
	SLEEP_NOP_loop:	
		nop
		addi	$a0,	$a0,	1
		blt	$a0,	%val,	SLEEP_NOP_loop
.end_macro

############################################################################
	.text
	li	$t0,	0xffff0000

wait:	
	lw	$t1,	($t0)		# check whether keybroad has been used
	#SLEEP_NOP(100)
	SLEEP_SYSCALL(10)
	beq	$t1,	$zero,	wait

	lw	$t1,	4($t0)		# load the typed word
	PRINT_CHAR($t1)
	j	wait
