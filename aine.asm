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
    empty:.space 36
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
        print_string(action_prompt)
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
        li $t0, 0                     # $t0: column counter (col = 0)

    move_up_column_loop:
        li $t1, 0                     # $t1: row counter (each column)
        li $t2, 0                     # $t2: position = 0

    move_up_shift_loop:
        mul $t3, $t1, 3               # Row offset (row * width)
        add $t3, $t3, $t0             # Add column offset
        sll $t4, $t3, 2               # Byte offset for grid[$t3]

        la $s0, grid
        add $t4, $s0, $t4
        lw $t5, 0($t4)                # Load grid[$t3] into $t5

        bnez $t5, up_handle_non_zero     # If cell is non-zero, handle it
        j up_skip_zero                   # If cell is zero, move to next row

    up_handle_non_zero:
        # Place non-zero value at position indicated by $t2
        mul $t6, $t2, 3               # Calculate target row offset for non-zero cell
        add $t6, $t6, $t0             # Add column offset
        sll $t7, $t6, 2               # Byte offset for grid[$t6]
        la $s0, grid
        add $t7, $s0, $t7
        sw $t5, 0($t7)                # Store non-zero value in new position

        # Increment target position only if we moved the value
        addi $t2, $t2, 1

    up_skip_zero:
        addi $t1, $t1, 1              # Move to next row in the column
        li $t8, 3
        blt $t1, $t8, move_up_shift_loop   # Repeat for all rows in column

        # Clear remaining cells in column after the shifted elements
        # move $t9, $t2                 # Start clearing from the current $t2 position

    # Combine adjacent elements if they are the same
    move_up_combine_loop:
        li $t1, 0                      # Reset row counter for combining

    up_combine_check_loop:
        mul $t3, $t1, 3                # Row offset (row * width)
        add $t3, $t3, $t0              # Add column offset
        sll $t4, $t3, 2                # Byte offset for grid[$t3]
        la $s0, grid
        add $t4, $s0, $t4
        lw $t5, 0($t4)                 # Load grid[$t3] (current cell)

        addi $t9, $t1, 1               # $t9 = row + 1 (next row)
        mul $t6, $t9, 3                # Next row offset (next_row * width)
        add $t6, $t6, $t0              # Add column offset
        sll $t7, $t6, 2                # Byte offset for grid[next_row]
        la $s0, grid
        add $t7, $s0, $t7
        lw $t6, 0($t7)                 # Load grid[next_row] (next cell)

        # If current and next cell are the same and non-zero, combine
        bne $t5, $t6, up_skip_combine     # Skip if cells are not equal
        beq $t5, $zero, up_skip_combine   # Skip if cells are zero

        # Combine: multiply current cell by 2, set next cell to 0
        add $t5, $t5, $t5              # Double the value in the current cell
        sw $t5, 0($t4)                 # Store doubled value back in current cell
        sw $zero, 0($t7)               # Set next cell to 0

    up_skip_combine:
        addi $t1, $t1, 1               # Move to the next row
        li $t8, 2
        blt $t1, $t8, up_combine_check_loop   # Repeat until the second-last row

        move $t9, $t2

    # Clear remaining cells in column after the shifted elements
    move_up_clear_loop:
        #move $t9, $t2                  # Start clearing from the current $t2 position
        mul $t6, $t9, 3                # Row offset for clearing
        add $t6, $t6, $t0              # Column offset
        sll $t7, $t6, 2                # Byte offset for grid[$t6]
        la $s0, grid
        add $t7, $s0, $t7
        sw $zero, 0($t7)               # Set cell to 0

        addi $t9, $t9, 1               # Move to the next row for clearing
        li $t8, 3
        blt $t9, $t8, move_up_clear_loop

        # Move to the next column
        addi $t0, $t0, 1
        li $t8, 3
        blt $t0, $t8, move_up_column_loop   # Repeat for all columns

        j spawn_get_empty
# ==============================================================

    move_left:
        # Code for moving left
        j loopGame

# ==============================================================

    move_down:
        li $t0, 0                     # $t0: column counter (col = 0)

    move_down_column_loop:
        li $t1, 2                     # $t1: row counter (start from the bottom, row = 2)
        li $t2, 2                     # $t2: position = 2 (starting from bottom row)

    move_down_shift_loop:
        mul $t3, $t1, 3               # Row offset (row * width)
        add $t3, $t3, $t0             # Add column offset
        sll $t4, $t3, 2               # Byte offset for grid[$t3]
        la $s0, grid
        add $t4, $s0, $t4
        lw $t5, 0($t4)                # Load grid[$t3] into $t5

        bnez $t5, down_handle_non_zero     # If cell is non-zero, handle it
        j down_skip_zero                   # If cell is zero, move to next row

    down_handle_non_zero:
        # Place non-zero value at position indicated by $t2
        mul $t6, $t2, 3               # Calculate target row offset for non-zero cell
        add $t6, $t6, $t0             # Add column offset
        sll $t7, $t6, 2               # Byte offset for grid[$t6]
        la $s0, grid
        add $t7, $s0, $t7
        sw $t5, 0($t7)                # Store non-zero value in new position

        # Decrement target position only if we moved the value
        addi $t2, $t2, -1             # Decrement position as we are moving down

    down_skip_zero:
        addi $t1, $t1, -1             # Move to the next row in the column
        li $t8, -1
        bgt $t1, $t8, move_down_shift_loop  # Repeat for all rows in column

    # Combine adjacent cells if they are the same
    move_down_combine_loop:
        li $t1, 2                     # Start from row 2, second last row (bottom-up)
        
    down_combine_check_loop:
        mul $t3, $t1, 3                # Row offset (row * width)
        add $t3, $t3, $t0              # Add column offset
        sll $t4, $t3, 2                # Byte offset for grid[$t3]
        la $s0, grid
        add $t4, $s0, $t4
        lw $t5, 0($t4)                 # Load grid[$t3] (current cell)

        addi $t9, $t1, -1              # $t9 = row - 1 (previous row)
        mul $t6, $t9, 3                # Previous row offset
        add $t6, $t6, $t0              # Add column offset
        sll $t7, $t6, 2                # Byte offset for grid[previous_row]
        la $s0, grid
        add $t7, $s0, $t7
        lw $t6, 0($t7)                 # Load grid[previous_row] (next cell)

        # If current and previous cells are the same and non-zero, combine
        bne $t5, $t6, down_skip_combine     # Skip if cells are not equal
        beq $t5, $zero, down_skip_combine   # Skip if cells are zero

        # Combine: multiply current cell by 2, set previous cell to 0
        add $t5, $t5, $t5              # Double the value in the current cell
        sw $t5, 0($t4)                 # Store doubled value back in current cell
        sw $zero, 0($t7)               # Set previous cell to 0

    down_skip_combine:
        addi $t1, $t1, -1              # Move to the next row
        li $t8, 0
        bgt $t1, $t8, down_combine_check_loop   # Repeat until the second row

        # Clear remaining cells in column after the shifted elements
        move $t9, $t2                 # Start clearing from the current $t2 position

    move_down_clear_loop:
        mul $t6, $t9, 3               # Row offset for clearing
        add $t6, $t6, $t0             # Column offset
        sll $t7, $t6, 2               # Byte offset for grid[$t6]
        la $s0, grid
        add $t7, $s0, $t7
        sw $zero, 0($t7)              # Set cell to 0

        addi $t9, $t9, -1             # Move to the next row for clearing
        li $t8, -1
        bgt $t9, $t8, move_down_clear_loop

        # Move to the next column
        addi $t0, $t0, 1
        li $t8, 3
        blt $t0, $t8, move_down_column_loop  # Repeat for all columns

        j spawn_get_empty

# ==============================================================

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

# ==============================================================
# Get Empty and Spawn tiles

    spawn_get_empty:
        la $s0, grid          # Base address of arr[]
        la $s1, empty         # Base address of empty_space[]

        # Initialize variables
        li $t0, 0             # i = 0
        li $t1, 0             # count = 0
        li $t2, 9             # max grid (MAX_GRID)

        for_loop:
            bge $t0, $t2, end_loop 

            # Check if arr[i] == 0
            sll $t3, $t0, 2        # Byte offset for arr[i]
            add $t3, $s0, $t3      # Address of arr[i]
            lw  $t4, 0($t3)        # Load arr[i] into $t4
            beqz $t4, init_empty   

            addi $t0, $t0, 1       # i++
            j for_loop             

        init_empty:
            sll $t5, $t1, 2        # Byte offset for empty_space[count]
            add $t5, $s1, $t5      # Address of empty_space[count]
            sw  $t0, 0($t5)        # empty_space[count] = i

            addi $t1, $t1, 1       # count++
            addi $t0, $t0, 1       # i++
            j for_loop            

        end_loop:
            beqz $t1, displayGrid  

            do_syscall(30)         # Generate random number
            move $t0, $a0          # Random number in $t0
            div  $t0, $t1          # rand() / count
            mfhi $t0               # $t0 = rand() % count

            # Get random_pos = empty_space[rand() % count]
            sll $t0, $t0, 2        # Byte offset for index
            add $t0, $s1, $t0      # Address of empty_space[rand() % count]
            lw  $t2, 0($t0)        # Load random_pos

            # Update arr[random_pos] = 2
            li  $t4, 2
            sll $t3, $t2, 2        # Byte offset for random_pos
            add $t3, $s0, $t3      # Address of arr[random_pos]
            sw  $t4, 0($t3)        # Store 2 in arr[random_pos]

            j displayGrid          # Jump to displayGrid




