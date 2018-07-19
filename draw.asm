
	.text
	li	$t0,	32
	li	$t1,	0x00FFFFFF
	
	move	$t2,	$t0
	sll	$t2,	$t2,	2
	add	$t2,	$t2,	$gp
	move	$t0,	$gp
	
FillLoop:
	beq	$t0,	$t2,	End
	sll	$t1,	$t1,	1
	sw	$t1,	($t0)
	addiu	$t0,	$t0,	4
	j FillLoop
	
End:
	li	$v0,	10
	syscall	
