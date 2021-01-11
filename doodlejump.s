#####################################################################
#
# CSCB58 Fall 2020 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Jimmy Yu, 1005499060
#
# Bitmap Display Configuration:
# - Unit width in pixels: 16					     
# - Unit height in pixels: 16
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 3 
#
# Link to video demonstration for final submission:
# - https://youtu.be/WrxncjKj2dw
#
# Any additional information that the TA needs to know:
# - Instead of scrolling the screen, I am randomly generating three new platforms and display them to the screen,
#   everytime the doodler hits the top of the screen. This was allowed based off this piazza post: https://piazza.com/class/kemxsy9by7o707?cid=292 
# - If the doodler hits the bottom of the screen, press r to restart, or q to quit.
#
#####################################################################

initializeData:
.data
	displayAddress:	.word	0x10008000
.text
# Dedicated registers used: 
#	$t0: Base address, top left pixel
#	$s0, s1, s2: Store our color used for doodler, background, platform
#	$s3: +/- 1 to control jumping/falling of doodler
#	$s4: Jump/fall height. Tracks how high the doodler jumped/fell
#	$t1, $t2: (x, y) location used for calculating movement
# 	(t3, t4) (t5, t6) (t7, t8): (x, y) platform locations


	lw $t0, displayAddress	# $t0 stores the base address for display
	li $s3, 1		# Flag for controlling the doodler jumping/falling
	li $s2, 0x99DA78	# Green
	li $s1, 0xFDF4CD	# BG Ivory
	li $s0, 0x4AA4C8	# Blue doodler color
		
	# Initialize positions of platforms
	li $t3, 12
	li $t4, 32
		
	li $t5, 4
	li $t6, 20
	
	li $t7, 20
	li $t8, 8
	
	# Initialize position of doodler to be middle of the screen
	move $t1, $zero
	move $t2, $zero
	addi $t1, $t1, 16
	addi $t2, $t2, 20
	
	
	
mainGameLoop:
	jal keyboardInput

	jal repaintScreen
	
	jal generateScreen
	
	jal drawDoodler
	add $t2, $t2, $s3
	
	jal checkPlatformCollision

	jal jumpHeight
			
	li $v0, 32
	li $a0, 100
 	syscall
	
	slti $at, $t2, 33	# If y > 33 then we exit
	beq $at, $zero, checkRestart
	
	j mainGameLoop
	

generateScreen:
	# If the doodler reached the top of the screen, randomly generate three new platforms
	# Else redraw the platforms at the same location
	blt $t2, $zero, generatePlatforms
	
	drawCurrentPlatforms:
		move $s6, $zero		# Loop counter variable
		addi $s7, $zero, 8
		move $t9, $t3		# Store the original position of the platform
		drawPlatformLoop1:
			lw $t0, displayAddress
			addi $t3, $t3, 1	# Add one to the length of the platform
		
			sll $v0, $t3, 2		# Calculate new position based on (x,y) and color in that pixel
			add $t0, $t0, $v0
			addi $v0, $t4, -1
			sll $v0, $v0, 7
			add $t0, $t0, $v0
			addi $t0, $t0, -4
			sw $s2, 0($t0)
		
			addi $s6, $s6, 1	# Increase loop counter
			bne $s6, $s7, drawPlatformLoop1		# Check for 8 unit length platforms
		move $t3, $t9	# Restore original platform position
		
		move $s6, $zero		# Loop counter variable
		move $t9, $t5		# Store the original position of the platform
		drawPlatformLoop2:
			lw $t0, displayAddress
			addi $t5, $t5, 1	# Add one to the length of the platform
		
			sll $v0, $t5, 2		# Calculate new position based on (x,y) and color in that pixel
			add $t0, $t0, $v0
			addi $v0, $t6, -1
			sll $v0, $v0, 7
			add $t0, $t0, $v0
			addi $t0, $t0, -4
			sw $s2, 0($t0)
		
			addi $s6, $s6, 1	# Increase loop counter
			bne $s6, $s7, drawPlatformLoop2		# Check for 8 unit length platforms
		move $t5, $t9	# Restore original platform position

		move $s6, $zero		# Loop counter variable
		move $t9, $t7		# Store the original position of the platform
		lw $t0, displayAddress
		drawPlatformLoop3:
			lw $t0, displayAddress
			addi $t7, $t7, 1	# Add one to the length of the platform
		
			sll $v0, $t7, 2		# Calculate new position based on (x,y) and color in that pixel
			add $t0, $t0, $v0
			addi $v0, $t8, -1
			sll $v0, $v0, 7
			add $t0, $t0, $v0
			addi $t0, $t0, -4
			sw $s2, 0($t0)
		
			addi $s6, $s6, 1	# Increase loop counter
			bne $s6, $s7, drawPlatformLoop3		# Check for 8 unit length platforms
		move $t7, $t9	# Restore original platform position
			
		lw $t0, displayAddress
		j drawDone
	
	generatePlatforms:
		li $v0, 42	# Generate a random value to be used as our x value
		li $a0, 0
		li $a1, 25
		syscall
		move $t3, $a0
		
		li $v0, 42	# Generate a random value to be used as our y value
		li $a0, 0
		li $a1, 4
		syscall
		addi $t4, $a0, 28	# Want a platform somewhere between 28-32 y value
	
		move $s6, $zero		# Loop counter variable
		addi $s7, $zero, 8
		move $t9, $t3		# Store the original position of the platform
		drawRandomPlatformLoop1:
			lw $t0, displayAddress
			addi $t3, $t3, 1	# Add one to the length of the platform
		
			sll $v0, $t3, 2		# Calculate new position based on (x,y) and color in that pixel
			add $t0, $t0, $v0
			addi $v0, $t4, -1
			sll $v0, $v0, 7
			add $t0, $t0, $v0
			addi $t0, $t0, -4
			sw $s2, 0($t0)
		
			addi $s6, $s6, 1	# Increase loop counter
			bne $s6, $s7, drawRandomPlatformLoop1	# Check for 8 unit length platforms
		move $t3, $t9	# Restore original platform position
	
		li $v0, 42	# Generate a random value to be used as our x value
		li $a0, 0
		li $a1, 25
		syscall
		move $t5, $a0
	
		li $v0, 42	# Generate a random value to be used as our y value
		li $a0, 0
		li $a1, 4
		syscall
		addi $t6, $a0, 16	# Want a platform somewhere between 16-20 y value
	
		move $s6, $zero		# Loop counter variable
		move $t9, $t5		# Store the original position of the platform
		lw $t0, displayAddress
		drawRandomPlatformLoop2:
			lw $t0, displayAddress
			addi $t5, $t5, 1	# Add one to the length of the platform
		
			sll $v0, $t5, 2		# Calculate new position based on (x,y) and color in that pixel
			add $t0, $t0, $v0
			addi $v0, $t6, -1
			sll $v0, $v0, 7
			add $t0, $t0, $v0
			addi $t0, $t0, -4
			sw $s2, 0($t0)
		
			addi $s6, $s6, 1	# Increase loop counter
			bne $s6, $s7, drawRandomPlatformLoop2	# Check for 8 unit length platforms
		move $t5, $t9	# Restore original platform position
		
		li $v0, 42	# Generate a random value to be used as our x value
		li $a0, 0
		li $a1, 25
		syscall
		move $t7, $a0
	
		li $v0, 42	# Generate a random value to be used as our y value
		li $a0, 0
		li $a1, 6
		syscall
		addi $t8, $a0, 4	# Want a platform somewhere between 4-10 y value
		
		move $s6, $zero		# Loop counter variable
		move $t9, $t7		# Store the original position of the platform
		lw $t0, displayAddress
		drawRandomPlatformLoop3:
			lw $t0, displayAddress
			addi $t7, $t7, 1	# Add one to the length of the platform
		
			sll $v0, $t7, 2	# Calculate new position based on (x,y) and color in that pixel
			add $t0, $t0, $v0
			addi $v0, $t8, -1
			sll $v0, $v0, 7
			add $t0, $t0, $v0
			addi $t0, $t0, -4
			sw $s2, 0($t0)
		
			addi $s6, $s6, 1	# Increase loop counter
			bne $s6, $s7, drawRandomPlatformLoop3	# Check for 8 unit length platforms
		move $t7, $t9	# Restore original platform position

		# Load 32 (y value) into t2, since the doodler will have reached the top of the screen
		li $s4, 6 	# Let the doodler jump 10 units high for some leeway once it reaches a new screen
		li $t2, 32 
		
	drawDone:
		jr $ra
	
keyboardInput:
	lw $t9, 0xffff0000
	beq $t9, 1, keyPressed
	j keyboardDone
	
	keyPressed:
		lw $t9, 0xffff0004
		beq $t9, 0x6A, respondToJ	# Key press is hex for j
		beq $t9, 0x6B, respondToK	# Key press is hex for k
		j keyboardDone
	
	respondToJ:
		addi $t1, $t1, -1	# Subtract from x dir by one unit
		j keyboardDone
	respondToK:
		addi $t1, $t1, 1	# Add to x dir by one unit
		j keyboardDone
	
	keyboardDone: jr $ra
	
	
jumpHeight:
	beq $s3, -1, checkHeight
	jr $ra
	
	checkHeight:
		addi $s4, $s4, 1	# Height counter, see how how the doodler has jumped already
		beq $s4, 16, switchFall	# Set the doodler to jump 16 pixels high
		jr $ra

	switchFall:
		li $s3, 1	# Branch here if the doodler has jumped 16 pixels, set s3 to 1 to start falling again
	jr $ra
	
checkPlatformCollision:
	addi $sp, $sp, -8
	sw $ra,  0($sp)
	sw $t3, 4($sp)
	
	jal calculateOffset	# checkPlatform collision is called after incrementing s3 in the main loop, so check the pixel below the doodler for a platform
	lw $t3, 0($t0)
	beq $t3, $s2, jump	# Check if below is a platform go to jump
	j platformCollisionDone
	
	jump:
		addi $t2, $t2, -1	# Subtract 1 from y to give doodler a 'bouncing' effect	
		jal drawDoodler
		li $s3, -1		# we switch s3 to -1 to start jumping
		li $s4, 0		# Reset the jump height counter to 0
		
	platformCollisionDone:		# Restore variables
		lw $ra, 0($sp)
		lw $t3, 4($sp)
		addi $sp, $sp, 8
		lw $t0, displayAddress
		jr $ra

repaintScreen:
	repaintLoop:
		sw $s1, 0($t0)		# Paint the pixel the background color
		addi $t0, $t0, 4
		bgt $t0, 0x10008ffc, repaintDone	# Loop until the bottom right pixel
		j repaintLoop
	repaintDone:
		lw $t0, displayAddress
		jr $ra

drawDoodler:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $v0, 4($sp)
	
	# Formula to get address based on (x,y) values (2^2)x + (y-1)*(2^7) - 4
	jal calculateOffset
	sw $s0, 0($t0)		# Color in the pixel with the base address + offset
	
	lw $ra, 0($sp)
	lw $v0, 4($sp)
	addi $sp, $sp, 8
	
	jr $ra	
	
calculateOffset:
	# Formula to get address based on (x,y) values (2^2)x + (y-1)*(2^7) - 4
	lw $t0, displayAddress
	
	sll $v0, $t1, 2
	add $t0, $t0, $v0
	
	addi $v0, $t2, -1
	sll $v0, $v0, 7
	
	add $t0, $t0, $v0
	addi $t0, $t0, -4
	
	jr $ra	


checkRestart:
	restartLoop:
		lw $t9, 0xffff0004
		beq $t9, 1, checkRestartKeyPress
		
	checkRestartKeyPress:
		lw $t9, 0xffff0004
		beq $t9, 0x72, initializeData	# If the key input is r, then restart game, by going back to the top
		beq $t9, 0x71, exit		# If the key input is q, then exit the game
		
	j checkRestart	# Loop until the key either r or q is pressed
		
exit:	
	li $v0, 10 
	syscall
