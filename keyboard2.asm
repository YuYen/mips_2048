.macro	PRINT_CHAR (%val)
	li	$v0,	11
	move	$a0,	%val
	syscall
.end_macro

.macro	SLEEP(%val)
	li	$v0,	32
	li	$a0,	%val
	syscall
.end_macro

	.text
	li	$t0,	0xffff0000

wait:	
	lw	$t1,	($t0)
	SLEEP(100)
	beq	$t1,	$zero,	wait

	lw	$t1,	4($t0)
	PRINT_CHAR($t1)
	j	wait
