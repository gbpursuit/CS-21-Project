# CS 21 WFR/HYZ & FYZ -- S1 AY 2024-2025
# Lorraine castrillon and Gavril Coronel -- 11/11/2024
# project1.asm -- 3x3 2048 game in MIPS

# Macros
.macro get_input(%option)
    do_syscall(5)
    move %option, $v0
.end_macro

.macro movement 
    la $a0, buffer
    li $a2, 2
    do_syscall(8)
    lb $t0, 0($a0)
.end_macro

# .macro movement
#     do_syscall(12)
#     move $t0, $v0
# .end_macro

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
    end_game: .asciiz "\nNo valid moves left. Please try again.\n"
    quit_game: .asciiz "\nYou quitted the game.\n"
    winner: .asciiz "\nCongratulations! You won.\n"

    # GRID
    grid_divider: .asciiz "+---+---+---+\n"
    space: .asciiz "   "
    one_space: .asciiz " "
    bar: .asciiz "|"

    # GRID SPACING
    .align 2
    grid: .space 36
    empty:.space 36
    temp: .space 12
    buffer: .space 2
    
.text
    main:
        print_string(prompt)
        get_input($s0)
        
        li $t0, 1
        li $t1, 2
        beq $s0, $t0, initializeGame
        beq $s0, $t1, startState

        j main    

# ============================= OPTION 1 ================================

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
        
        li   $t3, 0			            # empty cell -- 0
        sw   $t3, 0($t2)		    	# store back to grid[$t0]
        
        addi $t0, $t0, 1
        j newGame

    insert_value:
        li   $t3, 2			            # $t3 = 2
        sw   $t3, 0($t2)
        addi $t0, $t0, 1		    	# increment array counter
        j newGame

# ============================= PRINTING GRID ================================

    displayGrid:
        li $t0, 0			            # $t0: Reset array counter
        li $t1, 3			            # $t1: grid width
        
    display_row:
        print_string(grid_divider)
        print_string(bar)
        li $t2, 0			            # $t2: Column counter

    display_cell:
        sll  $t3, $t0, 2		    	# Byte offset for grid[$t0]
        la   $s0, grid
        add  $t3, $s0, $t3
        lw   $t4, 0($t3)		    	# Load grid[$t0] into $t4

        bne  $t4, $zero, print_value
        print_string(space)		    	# Print empty space if value is 0
        j skip_value

    print_value:
        li   $t3, 10
        blt  $t4, $t3, print_two_space   # If $t4 < 10, go to print_two_space

        li   $t3, 100
        blt  $t4, $t3, print_one_space   # If $t4 < 100, go to print_one_space

        j    print_no_space              # If $t4 >= 100, print_no_space

    print_two_space:                     # | 2 |
        print_string(one_space)             
        print_int($t4)
        print_string(one_space)

        j skip_value
    
    print_one_space:                     # | 16|
        print_string(one_space)
        print_int($t4)

        j skip_value
    
    print_no_space:                      # |256|
        print_int($t4)

    skip_value:
        print_string(bar)
        addi $t0, $t0, 1            	# increment array counter
        addi $t2, $t2, 1		    	# increment column counter
        li $t5, 3
        bne $t2, $t5, display_cell
        
        newline
        li $t6, 9			            # $t6: array end checker
        bne $t0, $t6, display_row		# if not end
        
        print_string(grid_divider)
        j loopGame

# ============================= MOVEMENT OPTIONS ================================

    loopGame:
        jal can_move	
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
        
        # Cbeck for Q key (Quit)
        li $t1, 81
        beq $t0, $t1, quit
        li $t1, 113
        beq $t0, $t1, quit
        
        j loopGame

# ============================= MOVE UP ================================

    move_up:
        newline()
        jal shift_up
        jal combine_up
        jal shift_up
        j spawn_get_empty

    shift_up:
        la $s0, grid
        li $t0, 0                       # $t0: col = 0

        up_shift_column_loop:
            bge $t0, 3, up_shift_done   # col < 3
            la  $s2, temp               # temp[GRID]             
            li  $t1, 0                  # 0 to store at temp
            li  $t2, 0                  # loop counter for temp[GRID] initialization

        up_init_temp:                    # temp initialization
            bge  $t2, 3, up_done_init_temp
            sll  $t3, $t2, 2        
            add  $t3, $s2, $t3
            sw   $t1, 0($t3)            # Store 0 
            addi $t2, $t2, 1            # t2++
            j up_init_temp
        #changes
        up_done_init_temp:
            li $t1, 0                   # $t1: pos = 0
            li $t2, 3                   # GRID = 3
            li $t3, 0                   # $t3: row = 0

        up_shift_row_loop:
            bge  $t3, $t2, up_next_init # row < 3
            mul  $t4, $t3, $t2          # row * GRID // 
            add  $t4, $t4, $t0          # row * GRID + col //

            sll  $t5, $t4, 2
            add  $t5, $s0, $t5
            lw   $t5, 0($t5)            # Load arr[index]

            bnez $t5, up_arr_to_temp  # arr[index] != 0
            #changes
            addi $t3, $t3, 1            # row++
            j up_shift_row_loop

        up_arr_to_temp:
            sll  $t6, $t1, 2
            add  $t6, $s2, $t6          # address of temp[pos]
            sw   $t5, 0($t6)            # temp[pos] = arr[index]
            #changes
            addi $t1, $t1, 1            # pos++
            #changes
            addi $t3, $t3, 1            # col++
            j up_shift_row_loop
        #second loop
        up_next_init:
            li  $t3, 0                   # row = 0
        
        up_next_row_loop:
            bge	 $t3, $t2, up_shift_increment_row # row < 3
            mul  $t4, $t3, 3            # row * GRID //
            add  $t4, $t4, $t0          # row * GRID + col //
            sll  $t5, $t4, 2
            add  $t5, $s0, $t5          # address of arr[index]

            sll  $t6, $t3, 2
            add  $t6, $s2, $t6
            lw   $t6, 0($t6)            # Load temp[col]

            sw   $t6, 0($t5)            # arr[row * GRID + col] = temp[col]
            addi $t3, $t3, 1

            j up_next_row_loop        

        up_shift_increment_row:
            addi $t0, $t0, 1            # col++
            j up_shift_column_loop
    
        up_shift_done:
            jr $ra                      # shift function done

    combine_up:
        la $s0, grid
        li $t0, 0                       # $t0: col = 0
        li $t1, 3                       # t1 = GRID

        up_combine_column_loop:
            bge $t0, $t1, up_combine_done # col < 3
            #changes
            li  $t2, 0                  # $t2: row = 0

        up_combine_row_loop:
            bge  $t2, 2, up_combine_increment_column
            # $t4: curr_index
            mul  $t3, $t2, $t1           # row * GRID //
            add  $t4, $t3, $t0           # row * GRID + col //
            
            sll  $t5, $t4, 2
            add  $t5, $s0, $t5
            lw   $t7, 0($t5)            # Load arr[curr_index]
            
            #changes: next_index (row + 1) * 3 + col
            addi $t6, $t2, 1            # row + 1         
            mul  $t3, $t6, $t1          # (row + 1) * 3
            add  $t3, $t3, $t0          # (row + 1) * 3 + col
            
            # add  $t3, $t3, $t6          # row * GRID + (row + 1)
            
            sll  $t6, $t3, 2
            add  $t6, $s0, $t6
            lw   $t8, 0($t6)            # Load arr[next_index]

            beq  $t7, $t8, up_combine_next_condition # arr[curr_index] == arr[next_index]
            
            #changes
            addi $t2, $t2, 1            # row++
            j up_combine_row_loop     
        
        up_combine_next_condition:
            beqz $t7, up_combine_increment_row    # arr[curr_index] != 0

            sll $t7, $t7, 1             # * 2
            sw  $t7, 0($t5)             # arr[curr_index] *= 2

            li  $t8, 0
            sw  $t8, 0($t6)             # arr[next_index] = 0

        up_combine_increment_row:
            #change: second for loop row
            addi $t2, $t2, 1            # row++
            j up_combine_row_loop    

        up_combine_increment_column:
            #changes: top for loop col
            addi $t0, $t0, 1            # col++
            j up_combine_column_loop

        up_combine_done:
            jr $ra                      # combine function done
        
# ============================= MOVE LEFT ================================

    move_left:
    	newline()
        jal shift_left
        jal combine_left
        jal shift_left
        j spawn_get_empty

    shift_left:
        la $s0, grid
        li $t0, 0                       # t0 = row

        l_shift_row_loop:
            bge $t0, 3, l_shift_done
            la  $s2, temp               # temp[GRID]             
            li  $t1, 0                  # 0 to store at temp
            li  $t2, 0                  # loop counter for temp[GRID] initialization

        l_init_temp:                    # temp initialization
            bge  $t2, 3, l_done_init_temp
            sll  $t3, $t2, 2        
            add  $t3, $s2, $t3
            sw   $t1, 0($t3)            # Store 0 
            addi $t2, $t2, 1            # t2++
            j l_init_temp
        #changes
        l_done_init_temp:
            li $t1, 0                   # $t1: pos = 0
            li $t2, 3                   # GRID = 3
            li $t3, 0                   # $t3: col = 0

        l_shift_column_loop:
            bge  $t3, $t2, l_next_init  # col < 3
            mul  $t4, $t0, $t2          # row * GRID
            add  $t4, $t4, $t3          # row * GRID + col

            sll  $t5, $t4, 2
            add  $t5, $s0, $t5
            lw   $t5, 0($t5)            # Load arr[index]

            bnez $t5, left_arr_to_temp  # arr[index] != 0
            #changes
            addi $t3, $t3, 1            # col++
            j l_shift_column_loop

        left_arr_to_temp:
            sll  $t6, $t1, 2
            add  $t6, $s2, $t6          # address of temp[pos]
            sw   $t5, 0($t6)            # temp[pos] = arr[index]
            #changes
            addi $t1, $t1, 1            # pos++
            #changes
            addi $t3, $t3, 1            # col++
            j l_shift_column_loop
        #second loop
        l_next_init:
            li  $t3, 0                   # col = 0
        
        l_next_column_loop:
            bge	 $t3, $t2, l_shift_increment_row # col < 3
            mul  $t4, $t0, 3            # row * GRID
            add  $t4, $t4, $t3          # row * GRID + col
            sll  $t5, $t4, 2
            add  $t5, $s0, $t5          # address of arr[index]

            sll  $t6, $t3, 2
            add  $t6, $s2, $t6
            lw   $t6, 0($t6)            # Load temp[col]

            sw   $t6, 0($t5)            # arr[row * GRID + col] = temp[col]
            addi $t3, $t3, 1

            j l_next_column_loop        

        l_shift_increment_row:
            addi $t0, $t0, 1            # row++
            j l_shift_row_loop
    
        l_shift_done:
            jr $ra                      # shift function done

    combine_left:
        la $s0, grid
        li $t0, 0                       # t0 = row
        li $t1, 3                       # t1 = GRID

        l_combine_row_loop:
            bge $t0, $t1, l_combine_done # row < 3
            #changes
            li  $t2, 0                  # $t2: col = 0

        l_combine_column_loop:
            bge  $t2, 2, l_combine_increment_row

            mul  $t3, $t0, $t1           # row * GRID
            add  $t4, $t3, $t2           # row * GRID + col
            
            sll  $t5, $t4, 2
            add  $t5, $s0, $t5
            lw   $t7, 0($t5)            # Load arr[curr_index]
            
            #changes: next_index
            addi $t6, $t2, 1            # col + 1         
            add  $t3, $t3, $t6          # row * GRID + (col + 1)
            sll  $t6, $t3, 2
            add  $t6, $s0, $t6
            lw   $t8, 0($t6)            # Load arr[next_index]

            beq  $t7, $t8, l_combine_next_condition # arr[curr_index] == arr[next_index]
            
            #changes
            addi $t2, $t2, 1            # col++
            j l_combine_column_loop     
        
        l_combine_next_condition:
            beqz $t7, l_combine_increment_column    # arr[curr_index] != 0

            sll $t7, $t7, 1             # * 2
            sw  $t7, 0($t5)             # arr[curr_index] *= 2

            li  $t8, 0
            sw  $t8, 0($t6)             # arr[next_index] = 0

        l_combine_increment_column:
            #change: second for loop col
            addi $t2, $t2, 1            # col++
            j l_combine_column_loop    

        l_combine_increment_row:
            #changes: top for loop row
            addi $t0, $t0, 1            # row++
            j l_combine_row_loop

        l_combine_done:
            jr $ra                      # combine function done

# ============================= MOVE DOWN ================================

    move_down:
        newline()
        jal shift_down
        jal combine_down
        jal shift_down
        j spawn_get_empty

    shift_down:
        la $s0, grid
        li $t0, 0                       # $t0: col = 0

        down_shift_column_loop:
            bge $t0, 3, down_shift_done   # col < 3
            la  $s2, temp               # temp[GRID]             
            li  $t1, 0                  # 0 to store at temp
            li  $t2, 0                  # loop counter for temp[GRID] initialization

        down_init_temp:                    # temp initialization
            bge  $t2, 3, down_done_init_temp
            sll  $t3, $t2, 2        
            add  $t3, $s2, $t3
            sw   $t1, 0($t3)            # Store 0 
            addi $t2, $t2, 1            # t2++
            j down_init_temp
        #changes
        down_done_init_temp:
            li $t2, 3
            subi $t1, $t2, 1              # $t1: pos = GRID - 1 = 2
            move $t3, $t1                 # $t3: row = 2

        down_shift_row_loop:
            #changes
            bltz  $t3, down_next_init   # row >= 0 
            mul  $t4, $t3, $t2          # row * GRID // 
            add  $t4, $t4, $t0          # row * GRID + col //

            sll  $t5, $t4, 2
            add  $t5, $s0, $t5
            lw   $t5, 0($t5)            # Load arr[index]

            bnez $t5, down_arr_to_temp  # arr[index] != 0
            #changes
            subi $t3, $t3, 1            # row--
            j down_shift_row_loop

        down_arr_to_temp:
            sll  $t6, $t1, 2
            add  $t6, $s2, $t6          # address of temp[pos]
            sw   $t5, 0($t6)            # temp[pos] = arr[index]
            #changes
            subi $t1, $t1, 1            # pos--
            #changes
            subi $t3, $t3, 1            # row--
            j down_shift_row_loop
        #second loop
        down_next_init:
            li  $t3, 0                   # row = 0
        
        down_next_row_loop:
            bge	 $t3, $t2, down_shift_increment_row # row < 3
            mul  $t4, $t3, 3            # row * GRID //
            add  $t4, $t4, $t0          # row * GRID + col //
            sll  $t5, $t4, 2
            add  $t5, $s0, $t5          # address of arr[index]

            sll  $t6, $t3, 2
            add  $t6, $s2, $t6
            lw   $t6, 0($t6)            # Load temp[col]

            sw   $t6, 0($t5)            # arr[row * GRID + col] = temp[col]
            addi $t3, $t3, 1

            j down_next_row_loop        

        down_shift_increment_row:
            addi $t0, $t0, 1            # col++
            j down_shift_column_loop
    
        down_shift_done:
            jr $ra                      # shift function done

    combine_down:
        la $s0, grid
        li $t0, 0                       # $t0: col = 0
        li $t1, 3                       # t1 = GRID

        down_combine_column_loop:
            bge $t0, 3, down_combine_done # col < 3 //
            #changes
            subi $t2, $t1, 1            # $t2: row = GRID - 1 = 2

        down_combine_row_loop:
            blez  $t2, down_combine_increment_column
            # $t4: curr_index
            mul  $t3, $t2, $t1           # row * GRID //
            add  $t4, $t3, $t0           # row * GRID + col //
            
            sll  $t5, $t4, 2
            add  $t5, $s0, $t5
            lw   $t7, 0($t5)            # Load arr[curr_index]
            
            #changes: next_index (row + 1) * 3 + col
            subi $t6, $t2, 1            # row - 1         
            mul  $t3, $t6, $t1          # (row - 1) * 3
            add  $t3, $t3, $t0          # (row - 1) * 3 + col
            
            # add  $t3, $t3, $t6          # row * GRID + (row + 1)
            
            sll  $t6, $t3, 2
            add  $t6, $s0, $t6
            lw   $t8, 0($t6)            # Load arr[next_index]

            beq  $t7, $t8, down_combine_next_condition # arr[curr_index] == arr[next_index]
            
            #changes
            subi $t2, $t2, 1            # row-- 
            j down_combine_row_loop     
        
        down_combine_next_condition:
            beqz $t7, down_combine_increment_row    # arr[curr_index] != 0

            sll $t7, $t7, 1             # * 2
            sw  $t7, 0($t5)             # arr[curr_index] *= 2

            li  $t8, 0
            sw  $t8, 0($t6)             # arr[next_index] = 0

        down_combine_increment_row:
            #change: second for loop row
            subi $t2, $t2, 1            # row--
            j down_combine_row_loop    

        down_combine_increment_column:
            #changes: top for loop col
            addi $t0, $t0, 1            # col++
            j down_combine_column_loop

        down_combine_done:
            jr $ra                      # combine function done

# ============================= MOVE RIGHT ================================

    move_right:
    	newline()
        jal shift_right
        jal combine_right
        jal shift_right
        j spawn_get_empty

    shift_right:
        la $s0, grid
        li $t0, 0               # t0 = row

        r_shift_row_loop:
            bge $t0, 3, r_shift_done
            la  $s2, temp        # temp[GRID]             
            li  $t1, 0           # 0 to store at temp
            li  $t2, 0           # loop counter for temp[GRID] initialization

        r_init_temp:
            bge  $t2, 3, r_done_init_temp
            sll  $t3, $t2, 2
            add  $t3, $s2, $t3
            sw   $t1, 0($t3)        # Store 0
            addi $t2, $t2, 1        # t2++
            j r_init_temp

        r_done_init_temp:
            li   $t2, 3             # GRID
            subi $t1, $t2, 1        # $t1: pos = GRID - 1 = 2
            move $t3, $t1           # $t3: col = 2

        r_shift_column_loop:
            bltz $t3, r_next_init
            mul  $t4, $t0, $t2          # row * GRID
            add  $t4, $t4, $t3          # row * GRID + col

            sll  $t5, $t4, 2
            add  $t5, $s0, $t5
            lw   $t5, 0($t5)            # Load arr[index]

            bnez $t5, right_arr_to_temp # arr[index] != 0
            subi $t3, $t3, 1            # col--
            j r_shift_column_loop

        right_arr_to_temp:
            sll  $t6, $t1, 2
            add  $t6, $s2, $t6
            sw   $t5, 0($t6)            # temp[pos] = arr[index]
            
            subi $t1, $t1, 1            # pos--

            subi $t3, $t3, 1            # col--
            j r_shift_column_loop

        r_next_init:
            li  $t3, 0                   # col = 0
        
        r_next_column_loop:
            bge	 $t3, $t2, r_shift_increment_row 
            mul  $t4, $t0, 3            # row * GRID
            add  $t4, $t4, $t3          # row * GRID + col
            sll  $t5, $t4, 2
            add  $t5, $s0, $t5          # address of arr[index]

            sll  $t6, $t3, 2
            add  $t6, $s2, $t6
            lw   $t6, 0($t6)            # Load temp[col]

            sw   $t6, 0($t5)            # arr[row * GRID + col] = temp[col]
            addi $t3, $t3, 1

            j r_next_column_loop        

        r_shift_increment_row:
            addi $t0, $t0, 1            # row++
            j r_shift_row_loop
    
        r_shift_done:
            jr $ra                      # shift function done

    combine_right:
        la $s0, grid
        li $t0, 0                       # t0 = row
        li $t1, 3                       # GRID

        r_combine_row_loop:
            bge  $t0, 3, r_combine_done
            subi $t2, $t1, 1            # $t2: col = GRID - 1 = 2

        r_combine_column_loop:
            blez $t2, r_combine_increment_row
            
            mul  $t3, $t0, 3            # row * GRID
            add  $t4, $t3, $t2          # row * GRID + col

            sll  $t5, $t4, 2
            add  $t5, $s0, $t5
            lw   $t7, 0($t5)            # Load arr[curr_index]

            subi $t6, $t2, 1            # col - 1         
            add  $t3, $t3, $t6          # row * GRID + (col - 1)
            sll  $t6, $t3, 2
            add  $t6, $s0, $t6
            lw   $t8, 0($t6)            # Load arr[next_index]

            beq  $t7, $t8, r_combine_next_condition # arr[curr_index] == arr[next_index]

            subi $t2, $t2, 1            # col--
            j r_combine_column_loop     
        
        r_combine_next_condition:
            beqz $t7, l_combine_increment_column # arr[curr_index] != 0

            sll  $t7, $t7, 1            # * 2
            sw   $t7, 0($t5)            # arr[curr_index] *= 2

            li   $t8, 0
            sw   $t8, 0($t6)            # arr[next_index] = 0

        r_combine_increment_column:
            subi $t2, $t2, 1            # col--
            j r_combine_column_loop     

        r_combine_increment_row:
            addi $t0, $t0, 1            # row++
            j r_combine_row_loop

        r_combine_done:
            jr $ra                      # combine function done

# ============================= OPTION 2 ================================

    startState:
        la $s0, grid
        li $t0, 0              			# $t0: array counter
        li $t1, 9              			# $t1: grid counter
        
    getInput:
        bge  $t0, $t1, displayGrid		# i >= 9
        sll  $t2, $t0, 2
        add  $t2, $s0, $t2		    	# $t2: address of grid[$t0]
        
        get_input($t3)
        sw   $t3, 0($t2)		    	# store back to grid[$t0]
        
        addi $t0, $t0, 1
        j getInput

# ============================= SPAWN TILES ================================

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

# ============================= CAN MOVE ================================

    can_move:
        la $s0, grid
        li $t0, 0                               # row
        li $t2, 3                               # grid
        li $t8, 0                               # flag to check if there is an empty space
        li $t9, 512                             # winning number !!
	
        outer_loop:
            bge $t0, 3, check_flag
            li  $t1, 0                          # column
        
        inner_loop: 
            bge $t1, 3, go_outer
            mul $t3, $t0, $t2                   # row * grid
            add $t3, $t3, $t1                   # cur = t3 + col

            sll $t4, $t3, 2                     # Byte offset for cur
            add $t5, $s0, $t4                   # Address of arr[cur]
            lw  $t5, 0($t5)                     # Load arr[cur]
            
            beq  $t5, $t9, win                  # arr[cur] == 512
            beqz $t5, set_flag                  # arr[cur] == 0 
            blt  $t0, 2, next_1_row             # row < GRID - 1
            blt  $t1, 2, next_1_column          # col < GRID - 1

            j next_cell

        set_flag:
            li $t8, 1

        next_cell:
            addi $t1, $t1, 1
            j inner_loop

        go_outer:
            addi $t0, $t0, 1
            j outer_loop        

        #MOVE DOWN = 3; MOVE RIGHT = 1        
        next_1_row: 			                # arr[cur] == arr[cur + MOVE_DOWN]
            addi $t6, $t3, 3       	            # cur + MOVE DOWN
            sll  $t6, $t6, 2                	    
            add  $t6, $s0, $t6     	            # Address of arr[cur + MOVE DOWN]
            lw   $t6, 0($t6)       	            # Load arr[cur + MOVE_DOWN]
            beq  $t5, $t6, continue_game	    # game continues
      
        next_1_column: 			                # arr[cur] == arr[cur + MOVE_RIGHT]
            addi $t6, $t3, 1       	            # cur + MOVE RIGHT
            sll  $t6, $t6, 2                	    
            add  $t6, $s0, $t6     	            # Address of arr[cur + MOVE RIGHT]
            lw   $t6, 0($t6)       	            # Load arr[cur + MOVE_RIGHT]
            beq  $t5, $t6, continue_game        # game continues	
            
            addi $t1, $t1, 1
            j inner_loop
            
        check_flag:
            beqz $t8, exit          # no 0 found -- end game
            
        continue_game:
            jr $ra                  # continue game 

    win:
        print_string(winner)
        exit()

    exit:
    	print_string(end_game)
        exit()
       
    quit:
    	print_string(quit_game)
    	exit()
