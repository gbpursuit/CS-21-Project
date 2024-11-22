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
    # PROMPT
    prompt: .asciiz "Choose [1] or [2]:\n[1] New Game\n[2] Start from a State\n"
    action_prompt: .asciiz "\nEnter move (w, a, s, d, or q (quit)):\n"
    
    # GRID
    grid_divider: .asciiz "+---+---+---+\n"
    space: .asciiz "   "
    one_space: .asciiz " "
    bar: .asciiz "|"

    # GRID SPACING
    .align 2
    grid: .space 36
    width: .word 3

    # DIRECTION MOVES
    MOVE_UP:    .word -3    # -GRID (3x3 grid)
    MOVE_DOWN:  .word 3     # GRID
    MOVE_LEFT:  .word -1
    MOVE_RIGHT: .word 1

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
        li $t0, 0              			# $t0: array counter
        li $t1, 9              			# $t1: grid counter
        
    random_values:
        do_syscall(30)
        move $t4, $a0
        rem  $t4, $t4, 9       	    	# $t4: first random cell index
        
        do_syscall(30)
        move $t5, $a0
        rem  $t5, $t5, 9		    	# $t5: second random cell index
        
        beq  $t4, $t5, random_values  
        
    newGame: 
        bge  $t0, $t1, displayGrid		# i >= 9
        sll  $t2, $t0, 2
        add  $t2, $t2, $s0		    	# $t2: address of grid[$t0]
        
        beq  $t0, $t4, insert_value
        beq  $t0, $t5, insert_value
        
        li   $t3, 0			        # empty cell -- 0
        sw   $t3, 0($t2)		    	# store back to grid[$t0]
        
        addi $t0, $t0, 1
        j newGame

    insert_value:
        li   $t3, 2			        # $t3 = 2
        sw   $t3, 0($t2)
        addi $t0, $t0, 1		    	# increment array counter
        j newGame

    displayGrid:
        li $t0, 0			        # $t0: Reset array counter
        li $t1, 3			        # $t1: grid width
        
    display_row:
        print_string(grid_divider)
        print_string(bar)
        li $t2, 0			        # $t2: Column counter

    display_cell:
        sll  $t3, $t0, 2		    	# Byte offset for grid[$t0]
        la   $s0, grid
        add  $t3, $s0, $t3
        lw   $t4, 0($t3)		    	# Load grid[$t0] into $t4

        bne  $t4, $zero, print_value
        print_string(space)		    	# Print empty space if value is 0
        j skip_value

    print_value:
        li   $t3, 3			        # set the number of spaces
        print_string(one_space)
        print_int($t4)
        print_string(one_space)

    skip_value:
        print_string(bar)
        addi $t0, $t0, 1            		# increment array counter
        addi $t2, $t2, 1		    	# increment column counter
        li $t5, 3
        bne $t2, $t5, display_cell
        
        newline
        li $t6, 9			        # $t6: array end checker
        bne $t0, $t6, display_row		# if not end
        
        print_string(grid_divider)
        j loopGame

    loopGame:
        movement()

        # Check for W key (Move Up)
        li $t1, 87             
        beq $t0, $t1, move_up
        li $t1, 119            
        beq $t0, $t1, move_up
        
        # Check for A key (Move Left)
        li $t1, 65              
        beq $t0, $t1, move_left
        li $t1, 97              
        beq $t0, $t1, move_left

        # Check for S key (Move Down)
        li $t1, 83               
        beq $t0, $t1, move_down
        li $t1, 115              
        beq $t0, $t1, move_down

        # Check for D key (Move Right)
        li $t1, 68               
        beq $t0, $t1, move_right
        li $t1, 100              
        beq $t0, $t1, move_right
        
        j loopGame

# ==============================================================

    move_up:
        # Iterate over each column
        li $t0, 0                     # Column counter (0, 1, 2 for each column)

    move_up_column_loop:
        li $t1, 0                     # Row counter within each column
        li $t2, 0                     # Position to place non-zero values at the top of each column

    move_up_shift_loop:
        # Calculate index in grid for the current cell
        mul $t3, $t1, 3               # Row offset (row * width)
        add $t3, $t3, $t0             # Add column offset
        sll $t4, $t3, 2               # Byte offset for grid[$t3]
        la $s0, grid
        add $t4, $s0, $t4
        lw $t5, 0($t4)                # Load grid[$t3] into $t5

        bnez $t5, handle_non_zero     # If cell is non-zero, handle it
        j skip_zero                   # If cell is zero, move to next row

    handle_non_zero:
        # Place non-zero value at position indicated by $t2
        mul $t6, $t2, 3               # Calculate target row offset for non-zero cell
        add $t6, $t6, $t0             # Add column offset
        sll $t7, $t6, 2               # Byte offset for grid[$t6]
        la $s0, grid
        add $t7, $s0, $t7
        sw $t5, 0($t7)                # Store non-zero value in new position

        # Increment target position only if we moved the value
        addi $t2, $t2, 1

    skip_zero:
        addi $t1, $t1, 1              # Move to next row in the column
        li $t8, 3
        blt $t1, $t8, move_up_shift_loop   # Repeat for all rows in column

        # Clear remaining cells in column after the shifted elements
        move $t9, $t2                 # Start clearing from the current $t2 position

    move_up_clear_loop:
        mul $t6, $t9, 3               # Row offset for clearing
        add $t6, $t6, $t0             # Column offset
        sll $t7, $t6, 2               # Byte offset for grid[$t6]
        la $s0, grid
        add $t7, $s0, $t7
        sw $zero, 0($t7)              # Set cell to 0

        addi $t9, $t9, 1              # Move to the next row for clearing
        li $t8, 3
        blt $t9, $t8, move_up_clear_loop

        # Move to the next column
        addi $t0, $t0, 1
        li $t8, 3
        blt $t0, $t8, move_up_column_loop   # Repeat for all columns

        # Display updated grid after moving up
        j displayGrid


# ==============================================================

    move_left:
        # Code for moving left
        j loopGame

    move_down:
        # Code for moving down
        j loopGame

    move_right:
        # Code for moving right
        j loopGame	

# OPTION 2: 
    startState:
        la $s0, grid
        li $t0, 0              			# $t0: array counter
        li $t1, 9              			# $t1: grid counter
        
    getInput:
        bge  $t0, $t1, displayGrid		# i >= 9
        sll  $t2, $t0, 2
        add  $t2, $t2, $s0		    	# $t2: address of grid[$t0]
        
        get_input($t3)
        sw   $t3, 0($t2)		    	# store back to grid[$t0]
        
        addi $t0, $t0, 1
        j getInput
