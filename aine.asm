.macro get_input(%option)
    do_syscall(5)
    move %option, $v0
.end_macro

.macro movement
    do_syscall(12)
    move $t0, $v0
.end_macro

.macro print_string(%string)
    la $a0, %string
    do_syscall(4)
.end_macro

.macro print_int(%int)
    move $a0, %int
    do_syscall(1)
.end_macro

.macro newline
    li $a0, 10
    do_syscall(11)
.end_macro

.macro do_syscall(%n)
    li $v0, %n
    syscall
.end_macro

.macro exit
    do_syscall(10)
.end_macro

.data
    prompt: .asciiz "Choose [1] or [2]:\n[1] New Game\n[2] Start from a State\n"
    grid_divider: .asciiz "+---+---+---+\n"
    space: .asciiz "   "     # Space for empty cells
    one_space: .asciiz " "
    bar: .asciiz "|"

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
        li $t0, 0              		# $t0: array counter
        li $t1, 9              		# $t1: grid counter
        
    random_values:
        do_syscall(30)
        move $t4, $a0
        rem  $t4, $t4, 9       	    # $t4: first random cell index
        
        do_syscall(30)
        move $t5, $a0
        rem  $t5, $t5, 9		    # $t5: second random cell index
        
        beq  $t4, $t5, random_values  
        
    newGame: 
        bge  $t0, $t1, displayGrid	# i >= 9
        sll  $t2, $t0, 2
        add  $t2, $t2, $s0		    # $t2: address of grid[$t0]
        
        beq  $t0, $t4, insert_value
        beq  $t0, $t5, insert_value
        
        li   $t3, 0			        # empty cell -- 0
        sw   $t3, 0($t2)		    # store back to grid[$t0]
        
        addi $t0, $t0, 1
        j newGame

    insert_value:
        li   $t3, 2			        # $t3 = 2
        sw   $t3, 0($t2)
        addi $t0, $t0, 1		    # increment array counter
        j newGame

    displayGrid:
        li $t0, 0			        # $t0: Reset array counter
        li $t1, 3			        # $t1: grid width
        
    display_row:
        print_string(grid_divider)
        print_string(bar)
        li $t2, 0			        # $t2: Column counter

    display_cell:
        sll  $t3, $t0, 2		    # Byte offset for grid[$t0]
        la   $s0, grid
        add  $t3, $s0, $t3
        lw   $t4, 0($t3)		    # Load grid[$t0] into $t4

        bne  $t4, $zero, print_value
        print_string(space)		    # Print empty space if value is 0
        j skip_value

    print_value:
        li   $t3, 3			        # set the number of spaces
        print_string(one_space)
        print_int($t4)
        print_string(one_space)

    skip_value:
        print_string(bar)
        addi $t0, $t0, 1            # increment array counter
        addi $t2, $t2, 1		    # increment column counter
        li $t5, 3
        bne $t2, $t5, display_cell
        
        newline
        li $t6, 9			        # $t6: array end checker
        bne $t0, $t6, display_row	# if not end
        
        print_string(grid_divider)
        j loopGame

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
        # Code for moving up
        j loopGame

    move_left:
        # Code for moving left
        j loopGame

    move_down:
        # Code for moving down
        j loopGame

    move_right:
        # Code for moving right
        j loopGame

    startState:
        exit()
