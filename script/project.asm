.data
msg:	.asciiz	"test dialog"
array: .word	0:100
clear:  .byte   0x1B,0x5B,0x33,0x3B,0x4A,0x1B,0x5B,0x48,0x1B,0x5B,0x32,0x4A

.text

input_char:

# test read character 
#	li	$v0,	12
#	syscall
#	
#	move	$a0,	$v0
#	li	$v0,	11
#	syscall
	
# test MIDI	
#	li	$v0,	31
#	li	$a0,	100
#	li	$a1,	1000
#	li	$a2,	80
#	li	$a3,	50
#	syscall

# test confirm dialog
#	li	$v0,	50
#	la	$a0,	msg
#	syscall

# test InputDialogInt
#	li	$v0,	51
#	la	$a0,	msg
#	syscall

# test
#	li	$v0,	52
#	la	$a0,	msg
#	syscall


# test messageDialog
	li	$v0,	55
	la	$a0,	msg
	li	$a1,	3
	syscall

# test clear screen => not work
#	la	$a0,	clear
#	li	$v0,	4
#	syscall


	j input_char
	
	
	