
<img align="left" width="540" height="410" src="https://github.com/YuYen/mips_2048/blob/assets/gaming_animation.gif">

## MARS Environment Setup 

#### Bitmap Display

	unit width: 8
	unit height: 8
	display width: 512 
	display height: 512
	base address: $gp

#### Keyboard and Display MMIO Simulator

	up: "w"
	down: "s"
	left: "a"
	right: "d"

- The mips 2048 program require mips simulator, [MARS](http://courses.missouristate.edu/KenVollmar/mars/), to execute.
- "Bitmap Display" and "Keyboard and Display MMIO Simulator" are used to display and control the direction.

## File Description 

- src/2048.asm: main procedures of the game
- src/marcos.asm: marcos used in the program

