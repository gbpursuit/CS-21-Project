    # PROMPT
    prompt: .asciiz "Choose [1] or [2]:\n[1] New Game\n[2] Start from a State\n"
    action_prompt: .asciiz "\nEnter move (w, a, s, d, or q (quit)):\n"
    end_game: .asciiz "No valid moves left. Please try again.\n"
    quit_game: .asciiz "\nGame over.\n"
    winner: .asciiz " Congratulations! You won.\n"

    loopGame:
        jal  can_move
        move $t0, $v0
	    beqz $t0, exit
	
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
        
        # Cbeck for Q key (Quit) -- dinagdag ko
        li $t1, 81
        beq $t0, $t1, quit
        li $t1, 113
        beq $t0, $t1, quit
        
        j loopGame

# ============================================================== lagay after ng spawn tiles
# Get Empty and Spawn tiles
    can_move:
        la $s0, grid
        li $t0, 0   # row
        li $t2, 3   # grid
	
        outer_loop:
            bge $t0, 3, exit_0  
            li  $t1, 0   # column
        
        inner_loop: 
            bge $t1, 3, go_outer
            mul $t3, $t0, $t2   # row * grid
            add $t3, $t3, $t1   # cur = t3 + col

            sll $t4, $t3, 2     # Byte offset for cur
            add $t5, $s0, $t4   # Address of arr[cur]
            lw  $t5, 0($t5)     # Load arr[cur]

            beqz $t5, exit_1        # arr[cur] == 0
            beq  $t5, 512, exit_0   # arr[cur] == 512
            blt  $t0, 2, next_1_row # row < GRID - 1
            blt  $t1, 2, next_1_column # col < GRID - 

            addi $t1, $t1, 1
            j inner_loop

        go_outer:
            addi $t0, $t0, 1
            j outer_loop

        #MOVE DOWN = 3; MOVE RIGHT = 1        
        next_1_row: 			# arr[cur] == arr[cur + MOVE_DOWN]
            addi $t6, $t3, 3       	# cur + MOVE DOWN
            sll  $t6, $t6, 2       	# Byte offset for cur + MOVE DOWN
            add  $t6, $s0, $t6     	# Address of arr[cur + MOVE DOWN]
            lw   $t6, 0($t6)       	# Load arr[cur + MOVE_DOWN]
            beq  $t5, $t6, exit_1  	# return 1
      
        next_1_column: 			# arr[cur] == arr[cur + MOVE_RIGHT]
            addi $t6, $t3, 1       	# cur + MOVE RIGHT
            sll  $t6, $t6, 2       	# Byte offset for cur + MOVE RIGHT
            add  $t6, $s0, $t6     	# Address of arr[cur + MOVE RIGHT]
            lw   $t6, 0($t6)       	# Load arr[cur + MOVE_RIGHT]
            beq  $t5, $t6, exit_1	# return 1	
            
            addi $t1, $t1, 1
            j inner_loop

        exit_0: 
            li $v0, 0
            jr $ra

        exit_1:
            li $v0, 1
            jr $ra

    exit:
    	print_string(end_game)
        exit()
       
    quit:
    	print_string(quit_game)
    	exit()