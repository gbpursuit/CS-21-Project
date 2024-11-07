# CS 21 WFR/FYZ -- S1 AY 2024-2025
# Lorraine Castrillon || Gavril Coronel -- 11/07/2024
# fivetwelve.asm -- 2048 in MIPS

.macro do_syscall(%n)
    	li $v0, %n
    	syscall
.end_macro

.macro movement
	do_syscall(12)		# read movement key
	move $t0, $v0
.end_macro

.macro get_input(%option)
    	do_syscall(5)
    	move %option, $v0
.end_macro

.macro print_string(%string)
    	la $a0, %string
    	do_syscall(4)
.end_macro

.macro newline
    	li $a0, 10
    	do_syscall(11)
.end_macro

.macro exit
	do_syscall(10)
.end_macro

.data
	prompt: .asciiz "Choose [1] or [2]:\n[1] New Game\n[2] Start from a State\n"
	grid_divider: .asciiz "+---+---+---+\n"
	
	.align 2
	grid: .space 36
	width: .word 3

.text
main:
	print_string(prompt)
	get_input($s0)
	
	li $t0, 1
	li $t1, 2
	beq $s0, $t0, initializeGame
	beq $s0, $t1, startState

	j main	
	
initializeGame:
	la $s0, grid
	li $t0, 0		# counter for array
	li $t1, 9
	
random_values:
	do_syscall(30)
	move $t4, $a0
	rem  $t4, $t4, 9
	
	do_syscall(30)
	move $t5, $a0
	rem  $t5, $t5, 9
	
	beq  $t4, $t5, random_values	
	
newGame: 
	bge  $t0, $t1, loopGame		# done if i >= 9
	sll  $t2, $t0, 2		# i * 4 (byte offset)
	add  $t2, $t2, $s0		# address of grid[i]
	lw   $t3, 0($t2)		# $t3 = array[i]
	
	beq  $t0, $t4, insert_value 
	beq  $t0, $t5, insert_value
	
	li   $t9, 0			# empty cell -- 0
	move $t3, $t9
	sw   $t3, 0($t2)		# store back to array
	
	addi $t0, $t0, 1
	j newGame
	
insert_value:
    	do_syscall(30)
    	rem  $t9, $a0, 2             	# Randomize 0 or 1
    	beq  $t9, 0, load_two        	# If 0, set value to 2
    	li   $t3, 4                  	# If 1, set value to 4
    	j store_value

load_two:
    	li   $t3, 2                  	# Set value to 2

store_value:
    	sw   $t3, 0($t2)             	# Store the value in the array
    	addi $t0, $t0, 1             	# Increment grid position
	j newGame                    	# Continue filling grid
		
loopGame:
	movement()
	
    	# Check for W key (Move Up)
    	li $t1, 87               # ASCII value of 'W'
    	beq $t0, $t1, move_up
    	li $t1, 119              # ASCII value of 'w'
	beq $t0, $t1, move_up
	
    	# Check for A key (Move Left)
    	li $t1, 65               # ASCII value of 'A'
    	beq $t0, $t1, move_left
    	li $t1, 97               # ASCII value of 'a'
	beq $t0, $t1, move_left

    	# Check for S key (Move Down)
    	li $t1, 83               # ASCII value of 'S'
    	beq $t0, $t1, move_down
    	li $t1, 115              # ASCII value of 's'
	beq $t0, $t1, move_down

    	# Check for D key (Move Right)
    	li $t1, 68               # ASCII value of 'D'
    	beq $t0, $t1, move_right
    	li $t1, 100              # ASCII value of 'd'
	beq $t0, $t1, move_right
    	
    	j loopGame
    	
move_up:
	# Code
	j loopGame
	
	
move_left:
	# Code
	j loopGame
	
move_down:
	# Code
	j loopGame

move_right:
	# Code
	j loopGame
	
startState:
	exit()

	
