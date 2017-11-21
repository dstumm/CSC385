.data
.equ ADDR_TIMER, 0xff202000
.equ ADDR_LEDS, 0xff200000
.equ ADDR_7SEG, 0xfff00020
.equ ADDR_KEYBOARD, 0xff200100

.equ RIGHT_ARROW_KEY, 0x1
.equ UP_ARROW_KEY, 0x2
.equ LEFT_ARROW_KEY, 0x4

.align 1
INPUT_STATE: 
	.hword 0

.align 2
# Player state has first byte as life, second byte as score, third and forth as position
PLAYER_STATE: 
  .word 0

.section .exceptions, "ax"
ISR:

  # Save callee
  addi sp, sp, -8
  stw r16, 0(sp)
  stw r17, 4(sp)

	# Check pending register
	rdctl et, ctl4

	# Timer interrupt
	movi r8, 1
	and r8, r8, et
	bne r8, r0, TIMER_INTR

	# Keyboard interrupt
	movi r8, 0x80
	and r8, r8, et
	bne r8, r0, KEYBOARD_INTR

#
# Process timer interrupt
#
TIMER_INTR:
	# Clear timout
	movia r8, ADDR_TIMER
	ldwio r9, 0(r8)
	andi r9, r9, 2
	stwio r9, 0(r8)
  # Process game loop
  call GameLoop
	br EXIT_HANDLER

#
# Process keyboard interrupt
#
KEYBOARD_INTR:
	# poll bit 15 until valid
	movia r8, ADDR_KEYBOARD
NOT_VALID:
	ldwio r9, 0(r8)
	andi r10, r9, 0x8000
	beq r10, r0, NOT_VALID
	# Data is valid
	# Get how many characters left to read
  mov r16, r9
	srli r16, r16, 16
	# r16 has pending number of codes

# Read command may consist of consequtive codes
READ_COMMAND:
  # Starting there is zero codes
  mov r17, r0

READ_CODE:
	# Get the make/break code.
	andi r8, r9, 0xff

  # Add code to stack and record code addition
  addi sp, sp, -4
  stw r8, 0(sp)
  addi r17, r17, 1

	# Decrement data counter
	subi r16, r16, 1

  # If its EO is non-single code command, so we read another code in
  movi r10, 0xE0
  beq r8, r10, NEXT_CODE

  # If its FO its part of a break command 
  movi r10, 0xF0
  beq r8, r10, NEXT_CODE

  # Otherwise were at the end of the command, call parse, r2 holds number of arguments on stack
  mov r2, r17
  call ParseKey

  # Restore stack pointer by multiply r2 by 4 and adding
  slli r17, r17, 2
  add sp, sp, r17

  # After parse if there's another code, it means there are more commands so read another, otherwise exit
	bgt r16, r0, NEXT_COMMAND
	br EXIT_HANDLER

NEXT_COMMAND:
  movia r8, ADDR_KEYBOARD
  ldwio r9, 0(r8)
  br READ_COMMAND

NEXT_CODE:
  movia r8, ADDR_KEYBOARD
  ldwio r9, 0(r8)
  br READ_CODE

EXIT_HANDLER:
  # Restore callee
  ldw r16, 0(sp)
  ldw r17, 4(sp)
  addi sp, sp, 8

	subi ea, ea, 4
	eret

.text
.global _start

#
# Main
#
_start:

	# Initialize sp
	movia sp, 0x03FFFFFC

  # Zero out leds for testing
	movia r8, ADDR_LEDS
	stwio r0, 0(r8)

	# Set timer delay and start it
	movia r8, ADDR_TIMER
	stwio r0, 0(r8)
	movia r9, 0x6e6b # 60 fps = 1.666 mhz step = 0x00196e6b
	movia r10, 0x0019
	stwio r9, 8(r8)
	stwio r10, 12(r8)
	movi r9, 7
	stwio r9, 4(r8)

	# Set read interrupts for keyboard
	movia r8, ADDR_KEYBOARD
	movi r9, 1
	stwio r9, 0(r8)
	
	# Enable IRQ for timer/keyboard (IRQ 0 and IRQ 7 respectively)
	movia r9, 0x81
	wrctl ctl3, r9

	# Enable interrupts globally
	movia r9, 1
	wrctl ctl0, r9

  # "Restart" the game which will initialize
  call RestartGame

LOOP:
	br LOOP

#
# Restart the game
#
RestartGame:
  # Initialize player
  # Position 160, score 0, life 3
  movia r8, 0x00A00003
  movia r9, PLAYER_STATE
  stw r8, 0(r9)

  # Initialize the enemies

  # Initialize shields
  
  ret

# 
# Game logic here
#
GameLoop:
  movi sp, sp -4
  stw ra, 0(sp)

  call UpdatePlayer

  ldw ra, 0(sp)
  movi sp, sp 4
  ret

# 
# Playerlogic
#
UpdatePlayer: 
  # Check pending input
  movia r9, INPUT_STATE
  ldh r8, 0(r9)

  # Check if player should move left, move left or fire
  andi r10, r8, LEFT_ARROW_KEY
  bne r10, r0, MOVE_LEFT
  andi r10, r8, RIGHT_ARROW_KEY
  bne r10, r0, MOVE_RIGHT
  andi r10, r8, UP_ARROW_KEY
  bne r10, r0, FIRE

MOVE_LEFT:

MOVE_RIGHT:

FIRE:
  # Clear the input on fire so key needs to be release and re-pressed
  movi r11, 0xFF
  # Get the NOT of KEY_UP
  xor r10, r10, r11
  and r10, r10, r8
  sth r10, 0(r9)

  ret

#
# Parse a set of make or break codes from a keyboard interrupt
#
ParseKey:
  # r2 has number of arguments on the stack

  # We're only looking for very specific conditions 
  # Either 1 argument and 0x2D (R) or 3 arguments 0xE0/0xE0,0xF0 and 0x75/0x6B/0x72/0x74 for up/left/down/right down/up

FIRST_ARGUMENT:
  mov r10, sp
  ldw r8, 0(r10)

  # If its equal to r call restart game
  movi r9, 0x2D
  beq r8, r9, RESTART

  # If thats the only arg, we're done
  movi r9, 1
  beq r2, r9, DONE

  # Otherwise it has to be E0 (make/break)
  movi r9, 0xE0
  bne r8, r9, DONE

SECOND_ARGUMENT:
  # Second argument
  addi r10, r10, 4
  ldw r8, 0(r10)

  # If its 75 its up arrow
  movi r9, 0x75
  beq r8, r9, UP_ARROW_DOWN

  # If its 6B its left arrow
  movi r9, 0x6B
  beq r8, r9, LEFT_ARROW_DOWN

  # If its 74 its right arrow
  movi r9, 0x74
  beq r8, r9, RIGHT_ARROW_DOWN

  # If those are the only args, we're done
  movi r9, 2
  beq r2, r9, DONE

  # Otherwise the second arg has to be F0 (break-code)
  movi r9, 0xF0
  bne r8, r9, DONE

THIRD_ARGUMENT:
  # Third argument
  addi r10, r10, 4
  ldw r8, 0(r10)

  # If its 75 its up arrow
  movi r9, 0x75
  beq r8, r9, UP_ARROW_UP

  # If its 6B its left arrow
  movi r9, 0x6B
  beq r8, r9, LEFT_ARROW_UP

  # If its 74 its right arrow
  movi r9, 0x74
  beq r8, r9, RIGHT_ARROW_UP
  br DONE

UP_ARROW_DOWN:
  movi r8, UP_ARROW_KEY
  br KEY_DOWN

LEFT_ARROW_DOWN:
  movi r8, LEFT_ARROW_KEY
  br KEY_DOWN

RIGHT_ARROW_DOWN:
  movi r8, RIGHT_ARROW_KEY
  br KEY_DOWN

UP_ARROW_UP:
  movi r8, UP_ARROW_KEY
  br KEY_UP

LEFT_ARROW_UP:
  movi r8, LEFT_ARROW_KEY
  br KEY_UP

RIGHT_ARROW_UP:
  movi r8, RIGHT_ARROW_KEY
  br KEY_UP

KEY_DOWN:
  # r8 stores key we want, turn that bit ON in input_state
	movia r10, INPUT_STATE
  ldh r9, 0(r10)
  or r8, r8, r9
  sth r8, 0(r10)
  br DONE

KEY_UP:
	movia r10, INPUT_STATE
  #r8 stores key we want, turn that bit OFF in INPUT_STATE
  ldh r9, 0(r10)
  movia r10, 0xFFFF
  xor r8, r8, r10
  and r8, r8, r9
  sth r8, 0(r10)
  br DONE

RESTART:
  call RestartGame
  br DONE
  
DONE:
  ret

