.macro	PRINT_CHAR (%val)
	li	$v0,	11
	move	$a0,	%val
	syscall
.end_macro

.macro	SLEEP(%val)
	li	$v0,	32
	move	$a0,	%val
	syscall
.end_macro


	.text
	li	$t0,	0xffff0004

	li	$t1,	0
	li	$t2,	0
wait:
	lw	$t1,	($t0)
	li	$t3,	100

#	SLEEP($t3)
	li	$v0,	32
	move	$a0,	$t3
	syscall
	
	beq	$t1,	$t2,	wait
	
loop:
	lw	$t1,	($t0)
#	PRINT_CHAR($t1)
	li	$v0,	11
	move	$a0,	$t1
	syscall
	
	
	move	$t2,	$t1
	j	wait
	
#	li	$t2,	200
#	SLEEP($t2)
#	j	loop
