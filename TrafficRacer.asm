###################################################################### 
# CSCB58 Summer 2022 Project 
# University of Toronto, Scarborough 
# 
# Student Name: Siyi Wang, Student Number: 1005984302, UTorID: wangsi93
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 8 (update this as needed) 
# - Unit height in pixels: 8 (update this as needed) 
# - Display width in pixels: 256 (update this as needed) 
# - Display height in pixels: 256 (update this as needed) 
# - Base Address for Display: 0x10008000 
# 
# Basic features that were implemented successfully 
# - Basic feature a/b/c (choose the ones that apply) 
#	a) Display the number of remaining lives
#	b) Different cars move in different speed
#	c) Display a GAME OVER screen when there are no more remaining lives, restart the game by pressing 'q'
# 
# Additional features that were implemented successfully 
# - Additional feature a/b/c (choose the ones that apply) 
#	a) Add two types of pickups: extra lives, shield mode
#	b) Display live score
#	c) Add a more challenging level when the first level completed
#  
# Link to the video demo 
# - Insert YouTube/MyMedia/other URL here and make sure the video is accessible
# https://drive.google.com/file/d/1i2BBs4dAxCDxjeGwRuyQgP-luk7MMUSC/view?usp=sharing 
# 
# Any additional information that the TA needs to know: 
# - Write here, if any 
# Hi, my video might be a little long because I talk slow, you can play it double speed and it will be clear :)
# Please email me if the video link does not work :)
# bias.wang@mail.utoronto.ca
#  
###################################################################### 
.data 
displayAddress:      .word 0x10008000  
carHead:	.word 0x10008D84 # top-left wheel
ub1:	.word 0x10008104 # the upper bound for the first drive lane
ub2:	.word 0x10008124
ub3:	.word 0x10008144
ub4:	.word 0x10008164 #also right bound
lb1:	.word 0x10008D84 # also left bound
lb2:	.word 0x10008DA4
lb3:	.word 0x10008DC4
lb4:	.word 0x10008DE4
displayScoreStartAddr:	.word 0x1000807C

brickToUL:	.word 0x10008FFC

eCar1:	.word 0x10008004 # starting adress of car in lane1
eCar2:	.word 0x10008024 # starting adress of car in lane2
eCar3:	.word 0x10008FC4 # starting adress of car in lane3
eCar4:	.word 0x10008FE4 # starting adress of car in lane4

.text  
main:	

#paint background
	lw $t0, displayAddress # load base address
	lw $s7, carHead # load car address
	li $t1, 4096 # save 256*256 pixels
	li $t2, 0x00808080 #load color grey into $t2
	li $s0, 5 # store the number of lives player has initially, but we have one free try, so 6 initial lives if included the free try
	li $s1, 0 # set a initial score
	lw $s4, displayScoreStartAddr
	lw $s3, displayAddress #set default extra live address, to avoid be eaten by myCar at beginning
	lw $s2, displayAddress #set default shield address, to avoid be eaten by myCar at beginning
	li $a2, 0 #set initial shield loop
	
	jal getRandomAddressLeft
	jal getRandomAddressRight
	jal setBackground

	
#paint two yellow line in the middle
	lw $t0, displayAddress
	li $t1, 64 # the length is 64
	li $t2, 0x00FFFF00 # load color yellow
setCentreline:
	sw $t2, 56($t0)	# 64 is the centre, so we draw line on 60 and 68
	sw $t2, 64($t0)
	addi $t0, $t0, 128
	addi $t1, $t1, -1
	bnez $t1, setCentreline

#paint two dot white linw
	lw $t0, displayAddress
	li $t1, 64 # the length is 64
	li $t2, 0x00FFFFFF # load color white	
setWhiteline: # draw two row, then skip one row
	sw $t2, 28($t0)
	sw $t2, 96($t0)
	addi $t0, $t0, 128
	sw $t2, 28($t0)
	sw $t2, 96($t0)
	addi $t0, $t0, 256
	addi $t1, $t1, -1
	bnez $t1, setWhiteline
setBaseHP: # set base HP of 5
	li $t2, 0xff0000 # load color red
	lw $t0, displayAddress
	sw $t2, 0($t0)
	sw $t2, 128($t0)
	sw $t2, 256($t0)
	sw $t2, 384($t0)
	sw $t2, 512($t0)
	


gameLoop:
	add $t8, $zero, $zero # reset user input every loop
	li $t9, 0xffff0000 # takes user input
	lw $t8, 0($t9)
	beq $t8, 1, readInput # if there is input, jump to readInput
	lw $t1, brickToUL 
	lw $t2, 0($t1)
	beq $t2, 0x00FFC0CB, upperLevel


updatePos:
	jal drawCar
	jal drawECarLeft # draw enemy car in lane 1, 2 (i.e., left lane)
	jal drawECarRight # draw enemy car in lane 3, 4 (i.e., right lane)

	addi $v0, $zero, 32	# syscall sleep
	addi $a0, $zero, 100	# 100 ms
	syscall
	
	jal presentExtraLive
	jal checkEatExtraLive
	jal presentShield
	jal checkShield
	bgtz $a2, enterShieldMode # if shield loop did not end, skip detect collision
	
	jal detectCollision
	
upperLevel: 
	jal drawCar
	#jal getRandomAddressLeft #get a random position of left lane car 
	jal drawECarLeft
	jal drawECarRight

	addi $v0, $zero, 32	# syscall sleep
	addi $a0, $zero, 50	# 50 ms
	syscall
	
	jal presentExtraLive
	jal checkEatExtraLive
	jal presentShield
	jal checkShield
	bgtz $a2, enterShieldMode
	jal detectCollision
	
skipCol:
	jal clearOldCar
	jal moveECarLeft
	jal moveECarRight
	j gameLoop

readInput:	
	lw $t8, 0xffff0004		# get keypress from keyboard input
	
	beq $t8, 113, main	# if key press = 'q' branch to main, i.e., restart game
	beq $t8, 119, moveForward	# if key press = 'w' branch to moveForward
	beq $t8, 115, moveBackward	# else if key press = 's' branch to moveBackward
	beq $t8, 100, moveRight	# if key press = 'd' branch to moveright
	beq $t8, 97, moveLeft	# else if key press = 'a' branch to moveLeft
	j updatePos
	
	
moveForward:
	addi $s7, $s7, -128
	# check upperbound of the car
	lw $t4, ub1
	sub $t4, $s7, $t4
	bgtz, $t4, exitMove # if not reach the upper bound, go to updatePos and draw car
	addi $s7, $s7, 128 # reach the upperbound, so move the address back
	j exitMove

moveBackward:
	addi $s7, $s7, 128	
	# check lowerbound of the car
	lw $t4, lb1
	sub $t4, $s7, $t4
	blez, $t4, exitMove # if not reach the lower bound, go to updatePos and draw car
	addi $s7, $s7, -128 # reach the lowerbound, so move the address back
	j exitMove
	
moveRight:
# check if x-coord of car is on the edge(i.e., lane 4)
# if on lane 4 already, j resetCarAfterCol
	li $t1, 128
	div $s7, $t1
	mfhi $t1 # store x-coord of myCar into $t1

	addi $t1, $t1, 4
	beq $t1, 104, resetCarAfterCol

# otherwise do the follow, move right
	addi $s7, $s7, 32
	j exitMove
	
moveLeft:
# check if x-coord of car is on the edge(i.e., lane 1)
# if on lane 1 already, j resetCarAfterCol
	li $t1, 128
	div $s7, $t1
	mfhi $t1 # store x-coord of myCar into $t1
	
	addi $t1, $t1, -4
	beqz $t1, resetCarAfterCol

# otherwise do the follow, move left
	addi $s7, $s7, -32

	j exitMove

exitMove:
	j updatePos
		
#draw car
drawCar:
	li $t1, 0x000000FF # load blue for car body
	li $t2, 0x00000000 # load black for car wheel
	
	bgtz $a2, drawShield
	
	sw $t2, 0($s7) # head of the car, i.e., the top-left wheel
	sw $t1, -124($s7)
	sw $t1, -120($s7)
	sw $t1, -116($s7)
	sw $t1, 4($s7)
	sw $t1, 8($s7)
	sw $t1, 12($s7)
	
	sw $t2, 16($s7)
	
	
	sw $t1, 132($s7)
	sw $t1, 136($s7)
	sw $t1, 140($s7)
	
	sw $t1, 260($s7)
	sw $t1, 264($s7)
	sw $t1, 268($s7)

	sw $t1, 388($s7)
	sw $t1, 392($s7)
	sw $t1, 396($s7)
	sw $t2, 384($s7)
	sw $t2, 400($s7)
	j doneDraw
	
drawShield:
	li $t1, 0x0087CEFA #light blue
	sw $t2, 0($s7) # head of the car, i.e., the top-left wheel
	sw $t1, -124($s7)
	sw $t1, -120($s7)
	sw $t1, -116($s7)
	sw $t1, 4($s7)
	sw $t1, 8($s7)
	sw $t1, 12($s7)
	
	sw $t2, 16($s7)
	
	
	sw $t1, 132($s7)
	sw $t1, 136($s7)
	sw $t1, 140($s7)
	
	sw $t1, 260($s7)
	sw $t1, 264($s7)
	sw $t1, 268($s7)

	sw $t1, 388($s7)
	sw $t1, 392($s7)
	sw $t1, 396($s7)
	sw $t2, 384($s7)
	sw $t2, 400($s7)
	j doneDraw
doneDraw:
	jr $ra

clearOldCar:
#**---------clear my car----------------------
	li $t2, 0x00808080 #load color grey into $t2
	# clear ship
	sw $t2, 0($s7) # head of the car, i.e., the top-left wheel
	sw $t2, -124($s7)
	sw $t2, -120($s7)
	sw $t2, -116($s7)
	sw $t2, 4($s7)
	sw $t2, 8($s7)
	sw $t2, 12($s7)
	
	sw $t2, 16($s7)
	
	
	sw $t2, 132($s7)
	sw $t2, 136($s7)
	sw $t2, 140($s7)
	
	sw $t2, 260($s7)
	sw $t2, 264($s7)
	sw $t2, 268($s7)

	sw $t2, 388($s7)
	sw $t2, 392($s7)
	sw $t2, 396($s7)
	sw $t2, 384($s7)
	sw $t2, 400($s7)
	
#**---------clear lane 1,2 car----------------------	
	sw $t2, 0($s6)
	sw $t2, 4($s6)
	sw $t2, 8($s6)
	sw $t2, 12($s6)
	sw $t2, 16($s6)
	sw $t2, 132($s6)
	sw $t2, 136($s6)
	sw $t2, 140($s6)
	sw $t2, -124($s6)
	sw $t2, -120($s6)
	sw $t2, -116($s6)
	sw $t2, -252($s6)
	sw $t2, -248($s6)
	sw $t2, -244($s6)
	
	sw $t2, -384($s6)
	sw $t2, -380($s6)
	sw $t2, -376($s6)
	sw $t2, -372($s6)
	sw $t2, -368($s6)

#**---------clear lane 3,4 car----------------------
	sw $t2, 0($s5) # head of the car, i.e., the top-left wheel
	sw $t2, -124($s5)
	sw $t2, -120($s5)
	sw $t2, -116($s5)
	sw $t2, 4($s5)
	sw $t2, 8($s5)
	sw $t2, 12($s5)
	
	sw $t2, 16($s5)
	
	
	sw $t2, 132($s5)
	sw $t2, 136($s5)
	sw $t2, 140($s5)
	
	sw $t2, 260($s5)
	sw $t2, 264($s5)
	sw $t2, 268($s5)

	sw $t2, 388($s5)
	sw $t2, 392($s5)
	sw $t2, 396($s5)
	sw $t2, 384($s5)
	sw $t2, 400($s5)
	
	jr $ra

getRandomAddressLeft:
	# get random car address for left two lanes
	li $v0, 42
	li $a0, 0	
	li $a1, 2 # get a random number between 0 and 1 store the number in $a0
	syscall
	
	beq $a0, 0, getLeftLaneCar # $s6 stores the address of left lane cars, either coming from lane 1 or lane 2
	lw $s6, eCar2 
	j goDrawLeftCar
getLeftLaneCar:
	lw $s6, eCar1	
	j goDrawLeftCar
		
goDrawLeftCar:
	jr $ra

getRandomAddressRight:
	# get random car address for right two lanes
	li $v0, 42
	li $a0, 0	
	li $a1, 2 # get a random number between 0 and 1 store the number in $a0
	syscall
	
	beq $a0, 0, getRightLaneCar # $s5 stores the address of left lane cars, either coming from lane 3 or lane 4
	lw $s5, eCar3 
	j goDrawRightCar
getRightLaneCar:
	lw $s5, eCar4	
	j goDrawRightCar
		
goDrawRightCar:
	jr $ra
	
drawECarLeft:
	li $t1, 0x00800080 # load purple for car body
	li $t2, 0x00000000 # load black for car wheel
	
	sw $t2, 0($s6)
	sw $t1, 4($s6)
	sw $t1, 8($s6)
	sw $t1, 12($s6)
	sw $t2, 16($s6)
	sw $t1, 132($s6)
	sw $t1, 136($s6)
	sw $t1, 140($s6)
	sw $t1, -124($s6)
	sw $t1, -120($s6)
	sw $t1, -116($s6)
	sw $t1, -252($s6)
	sw $t1, -248($s6)
	sw $t1, -244($s6)
	
	sw $t2, -384($s6)
	sw $t1, -380($s6)
	sw $t1, -376($s6)
	sw $t1, -372($s6)
	sw $t2, -368($s6)
	
	jr $ra


drawECarRight:
	li $t1, 0x0000FF7F # load green for car body
	li $t2, 0x00000000 # load black for car wheel
	
	sw $t2, 0($s5) # head of the car, i.e., the top-left wheel
	sw $t1, -124($s5)
	sw $t1, -120($s5)
	sw $t1, -116($s5)
	sw $t1, 4($s5)
	sw $t1, 8($s5)
	sw $t1, 12($s5)
	
	sw $t2, 16($s5)
	
	
	sw $t1, 132($s5)
	sw $t1, 136($s5)
	sw $t1, 140($s5)
	
	sw $t1, 260($s5)
	sw $t1, 264($s5)
	sw $t1, 268($s5)

	sw $t1, 388($s5)
	sw $t1, 392($s5)
	sw $t1, 396($s5)
	sw $t2, 384($s5)
	sw $t2, 400($s5)
	
	jr $ra
	
moveECarLeft: 
# move car in lane 1, 2, by moving down a row each time
	addi $s6, $s6, 256
#check if the car goes to an end
	lw $t1, carHead 
	addi $t1, $t1, 512 # set a lower bound for lane 1
	addi $t2, $t1, 32
	addi $t2, $t2, -128 # set a lower bound for lane 2
	
	addi $t1, $t1, 128

	beq $t1, $s6, updateLeftCar
	beq $t2, $s6, updateLeftCar
	
	j endMoveECar
	
	
moveECarRight: # move car in lane 3, 4, by moving up a row each time
	addi $s5, $s5, -128
#check if the car goes to an end
	lw $t1, ub3
	addi $t1, $t1, -1024 # set a lower bound for lane 3
	addi $t2, $t1, 32
	addi $t2, $t2, 512 # set a lower bound for lane 4
	
	beq $t1, $s5, updateRightCar
	beq $t2, $s5, updateRightCar
	
	j endMoveECar

updateLeftCar: # update address of left lane cars
	addi $s1, $s1, 1 # since we are getting a new ECar, we can increment score by 1
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	add $t4, $s1, $zero # set a looping variable
	lw $t5, displayScoreStartAddr
	jal increaseLiveScore
	jal getRandomAddressLeft
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
updateRightCar: # update address of right lane cars
	addi $s1, $s1, 1 # since we are getting a new ECar, we can increment score by 1
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	add $t4, $s1, $zero # set a looping variable
	lw $t5, displayScoreStartAddr
	jal increaseLiveScore
	jal getRandomAddressRight
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

endMoveECar:
	jr $ra

detectCollision: 
	addi $t1, $s7, -128 # compare this point of my car to all the other corresponding points of other cars
	addi $t3, $s7, 384
# ECarLeft
# case 1
	addi $t2, $s6, 128
	beq $t1, $t2, resetCarAfterCol
# case 2
	addi $t2, $s6, 0
	beq $t1, $t2, resetCarAfterCol
	beq $t3, $t2, resetCarAfterCol
# case 3
	addi $t2, $s6, -128
	beq $t1, $t2, resetCarAfterCol
	beq $t3, $t2, resetCarAfterCol
# case 4
	addi $t2, $s6, -256
	beq $t1, $t2, resetCarAfterCol
	beq $t3, $t2, resetCarAfterCol
# case 5
	addi $t2, $s6, -384
	beq $t1, $t2, resetCarAfterCol
	beq $t3, $t2, resetCarAfterCol
	
# ECarRight
# case 1
	addi $t2, $s5, 384
	beq $t1, $t2, resetCarAfterCol
# case 2
	addi $t2, $s5, 256
	beq $t1, $t2, resetCarAfterCol
	beq $t3, $t2, resetCarAfterCol
# case 3
	addi $t2, $s5, 128
	beq $t1, $t2, resetCarAfterCol
	beq $t3, $t2, resetCarAfterCol
# case 4
	addi $t2, $s5, 0
	beq $t1, $t2, resetCarAfterCol
	beq $t3, $t2, resetCarAfterCol
# case 5
	addi $t2, $s5, -128
	beq $t1, $t2, resetCarAfterCol
	beq $t3, $t2, resetCarAfterCol
	
	jr $ra

resetCarAfterCol:
	#addi $s1, 0 # reset score to zero if collide
	jal decreaseLiveScore
	jal decreaseHP
	jal clearOldCar
	jal drawECarLeft
	jal drawECarRight
	lw $s7, carHead
	jal drawCar
	j gameLoop
	
decreaseHP:
	li $t2, 0x00808080 # color grey
	lw $t0, displayAddress
	li $t3, 128
	mult $s0, $t3 
	mflo $t4 # to get the address of the downmost HP block
	add $t0, $t0, $t4
	sw $t2, 128($t0)
	sw $t2, 0($t0)

	
	addi $s0, $s0, -1
	beq $s0, -1, endGame
	
	jr $ra

increaseLiveScore:
	li $t2, 0x00FFC0CB # color pink
	sw $t2, 0($t5)
	addi $t5, $t5, 128
	addi $t4, $t4, -1
	bnez $t4, increaseLiveScore
	
	jr $ra

decreaseLiveScore:
	li $t2, 0x00808080 # color grey
	lw $t0, displayScoreStartAddr
	li $t3, 128
	mult $s1, $t3 
	mflo $t4 # to get the address of the downmost HP block
	add $t0, $t0, $t4
	sw $t2, 128($t0)
	sw $t2, 0($t0)
	
	addi $s1, $s1, -1
	#beq $s1, -1, endGame	
	jr $ra

presentExtraLive:
	li $v0, 42 # get a random number between 0 and 60
	li $a0, 0
	li $a1, 60
	syscall
	
	beq $a0, 11, getExtraLiveAddr1
	beq $a0, 7, getExtraLiveAddr2
	j noLiveGoBack
getExtraLiveAddr1: # display the extra live in lane 1
	lw $s3, lb1
	addi $s3, $s3, -512
	li $t2, 0x00DB7093 # color violet red
	sw $t2, 0($s3)
	j noLiveGoBack
getExtraLiveAddr2: # diaplay the extra live in lane3
	lw $s3, lb3
	addi $s3, $s3, -1024
	li $t2, 0x00DB7093 # color violet red
	sw $t2, 0($s3)
	j noLiveGoBack
noLiveGoBack:
	jr $ra
	
checkEatExtraLive: # check if myCar successfully eat the extralive
# check if the left points of myCar touches $s3
	lw $t0, displayAddress
	
	addi $t1, $s7, -128
	beq $t1, $s3, increaseHP
	
	addi $t1, $s7, 0
	beq $t1, $s3, increaseHP
	
	addi $t1, $s7, 128
	beq $t1, $s3, increaseHP
	
	addi $t1, $s7, 256
	beq $t1, $s3, increaseHP
	
	addi $t1, $s7, 384
	beq $t1, $s3, increaseHP
	
	j doneHP
	
increaseHP:
	addi $s0, $s0, 1
	add $t4, $s0, $zero # set a looping variable
	lw $s3, displayAddress
	j increaseHPLoop
	#lw $s3, displayAddress
increaseHPLoop:
	li $t2, 0xff0000 # color red
	sw $t2, 0($t0)
	addi $t0, $t0, 128
	addi $t4, $t4, -1
	#lw $s3, displayAddress
	bnez $t4, increaseHPLoop
	j doneHP
	
doneHP:
	jr $ra




presentShield:
	li $v0, 42 # get a random number between 0 and 60
	li $a0, 0
	li $a1, 100
	syscall
	
	beq $a0, 15, getShieldAddr1
	beq $a0, 27, getShieldAddr2
	j noShieldGoBack
getShieldAddr1: # display the extra live in lane 1
	lw $s2, lb2
	#addi $s2, $s2, 128
	li $t2, 0x0087CEFA # color light blue
	sw $t2, 0($s2)
	j noShieldGoBack
getShieldAddr2: # diaplay the extra live in lane3
	lw $s2, lb4
	addi $s2, $s2, -384
	li $t2, 0x0087CEFA # color light blue
	sw $t2, 0($s2)
	j noShieldGoBack
noShieldGoBack:
	jr $ra
	
checkShield: # check if myCar successfully eat the shield
# check if the left points of myCar touches $s2
	lw $t0, displayAddress
	
	addi $t1, $s7, -128
	beq $t1, $s2, shieldBuffer
	
	addi $t1, $s7, 0
	beq $t1, $s2, shieldBuffer
	
	addi $t1, $s7, 128
	beq $t1, $s2, shieldBuffer
	
	addi $t1, $s7, 256
	beq $t1, $s2, shieldBuffer
	
	addi $t1, $s7, 384
	beq $t1, $s2, shieldBuffer
	
	j noShield
	
shieldBuffer:
	li $a2, 20 # load a shield buffer of 3
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal drawCar
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j noShield 
		
noShield:
	jr $ra	

enterShieldMode:
	addi $a2, $a2, -1
	j skipCol
	

setBackground:
	sw $t2, 0($t0) #paint grey on background
	addi $t0, $t0, 4
	addi $t1, $t1, -1
	bnez $t1, setBackground
	jr $ra
	
endGame:
#----------clear screen-------------
	li $t2, 0x00000000 # load color black
	lw $t0, displayAddress
	li $t1, 4096
	jal setBackground

#----------draw game over------------
	li $t2, 0xff0000 # load color red
	
	li $t0, 0x10008804 # draw O
	sw $t2, 0($t0)
	sw $t2, -128($t0)
	sw $t2, -256($t0)
	sw $t2, -384($t0)
	sw $t2, -380($t0)
	sw $t2, -376($t0)
	sw $t2, -372($t0)
	sw $t2, -244($t0)
	sw $t2, -116($t0)
	sw $t2, 12($t0)
	sw $t2, 140($t0)
	sw $t2, 268($t0)
	sw $t2, 264($t0)
	sw $t2, 260($t0)
	sw $t2, 256($t0)
	sw $t2, 128($t0)

	# draw V
	sw $t2, -352($t0)
	sw $t2, -224($t0)
	sw $t2, -96($t0)
	sw $t2, 32($t0)
	sw $t2, 160($t0)
	sw $t2, 292($t0)
	sw $t2, 296($t0)
	sw $t2, 172($t0)
	sw $t2, 44($t0)
	sw $t2, -84($t0)
	sw $t2, -212($t0)
	sw $t2, -340($t0)
	
	# draw E
	sw $t2, -320($t0)
	sw $t2, -316($t0)
	sw $t2, -312($t0)
	sw $t2, -308($t0)
	sw $t2, -192($t0)
	sw $t2, -64($t0)
	sw $t2, -60($t0)
	sw $t2, -56($t0)
	sw $t2, 64($t0)
	sw $t2, 192($t0)
	sw $t2, 320($t0)
	sw $t2, 324($t0)
	sw $t2, 328($t0)
	sw $t2, 332($t0)
	
	# draw R
	sw $t2, -288($t0)
	sw $t2, -284($t0)
	sw $t2, -280($t0)
	sw $t2, -276($t0)
	sw $t2, -160($t0)
	sw $t2, -148($t0)
	sw $t2, -32($t0)
	sw $t2, -28($t0)
	sw $t2, -24($t0)
	sw $t2, -20($t0)
	sw $t2, 96($t0)
	sw $t2, 100($t0)
	sw $t2, 104($t0)
	sw $t2, 224($t0)
	sw $t2, 236($t0)
	sw $t2, 352($t0)
	sw $t2, 364($t0)
	
	# draw G
	sw $t2, -640($t0)
	sw $t2, -636($t0)
	sw $t2, -632($t0)
	sw $t2, -628($t0)
	sw $t2, -756($t0)
	sw $t2, -884($t0)
	sw $t2, -888($t0)
	sw $t2, -768($t0)
	sw $t2, -896($t0)
	sw $t2, -1024($t0)
	sw $t2, -1152($t0)
	sw $t2, -1280($t0)
	sw $t2, -1276($t0)
	sw $t2, -1272($t0)
	sw $t2, -1268($t0)
	
	#draw A
	sw $t2, -608($t0)
	sw $t2, -736($t0)
	sw $t2, -864($t0)
	sw $t2, -992($t0)
	sw $t2, -1120($t0)
	sw $t2, -1244($t0)
	sw $t2, -1240($t0)
	sw $t2, -1108($t0)
	sw $t2, -980($t0)
	sw $t2, -852($t0)
	sw $t2, -860($t0)
	sw $t2, -856($t0)
	sw $t2, -724($t0)
	sw $t2, -596($t0)
	
	# draw M
	sw $t2, -576($t0)
	sw $t2, -704($t0)
	sw $t2, -832($t0)
	sw $t2, -960($t0)
	sw $t2, -1088($t0)
	sw $t2, -1212($t0)
	sw $t2, -1204($t0)
	sw $t2, -1080($t0)
	sw $t2, -952($t0)
	sw $t2, -824($t0)
	sw $t2, -1072($t0)
	sw $t2, -944($t0)
	sw $t2, -816($t0)
	sw $t2, -688($t0)
	sw $t2, -560($t0)
	
	# draw E
	sw $t2, -544($t0)
	sw $t2, -540($t0)
	sw $t2, -536($t0)
	sw $t2, -532($t0)
	sw $t2, -672($t0)
	sw $t2, -800($t0)
	sw $t2, -928($t0)
	sw $t2, -924($t0)
	sw $t2, -920($t0)
	sw $t2, -1056($t0)
	sw $t2, -1184($t0)
	sw $t2, -1180($t0)
	sw $t2, -1176($t0)
	sw $t2, -1172($t0)

#----------check input-----------#

END: # if there is another input of q, then restart the game, otherwise, end
	lw $t3, 0xffff0000 
	beq $t3, 0, EXIT

	lw $t3, 0xffff0004	
	beq $t3, 113, main
	
EXIT: 
	### Sleep for 66 ms so frame rate is about 15
	addi $v0, $zero, 32	# syscall sleep
	addi $a0, $zero, 100	# 66 ms
	syscall
	j END



	
