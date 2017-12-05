.data
.equ ADDR_TIMER, 0xff202000
.equ ADDR_LEDS, 0xff200000
.equ ADDR_7SEG, 0xfff00020
.equ ADDR_KEYBOARD, 0xff200100
.equ ADDR_7SEG, 0xff200020

.equ RIGHT_ARROW_KEY, 0x1
.equ UP_ARROW_KEY, 0x2
.equ LEFT_ARROW_KEY, 0x4
.equ SPACE_KEY, 0x8

.align 1
INPUT_STATE: 
	.hword 0

.align 1
TICK_STATE:
  .hword 0

.global INPUT_STATE
.global RIGHT_ARROW_KEY
.global LEFT_ARROW_KEY
.global UP_ARROW_KEY
.global SPACE_KEY
.global ADDR_LEDS
.global ADDR_TIMER
.global ADDR_KEYBOARD
.global ADDR_7SEG
.global TICK_STATE
.global ParseKey


.text
.global main
#
# Main
#
	main:

	# Initialize sp
	#movia sp, 0x03FFFFFC

	# Zero tick
	movia r8, TICK_STATE
	sth r0, 0(r8)

	# Timer
	movia r8, ADDR_TIMER
	stwio r0, 0(r8)

	# Zero out leds for testing
	movia r8, ADDR_LEDS
	stwio r0, 0(r8)

	# Set timer delay and start it
	movia r8, ADDR_TIMER
	stwio r0, 0(r8)
	movia r9, 0x6e6b # 60 fps = 1.666 mhz step = 0x00196e6b
	movia r10, 0x0019
	#movia r9, 0x6500 # 0.3 fps = 300 mhz step = 0x1DCD6500
	#movia r10, 0x1DCD
	stwio r9, 8(r8)
	stwio r10, 12(r8)
	movi r9, 7
	stwio r9, 4(r8)

	# Set read interrupts for keyboard
	movia r8, ADDR_KEYBOARD
	movi r9, 1
	stwio r9, 4(r8)

	# Enable IRQ for timer/keyboard (IRQ 0 and IRQ 7 respectively)
	movia r9, 0x81
	wrctl ctl3, r9

	# Enable interrupts globally
	movia r9, 1
	wrctl ctl0, r9

	# "Restart" the game which will initialize
	addi sp, sp, -4
	stw ra, 0(sp)
	
	call RestartGame

	movia r4, 0x01000000
	call drawing_init
	ldw ra, 0(sp)
	addi sp, sp, 4

LOOP:

	movia r8, INPUT_STATE
	ldw r9, 0(r8)
	movia r8, ADDR_LEDS
	stwio r9, 0(r8)

  	# Game tick checker
  	movia r8, TICK_STATE
  	ldh r9, 0(r8)
 	 beq r9, r0, LOOP
  	# Clear tick, call gameloop
  	sth r0, 0(r8)

	addi sp, sp, -4
	stw ra, 0(sp)
  	call GameLoop
	ldw ra, 0(sp)
	addi sp, sp, 4

	br LOOP

#
# Parse a set of make or break codes from a keyboard interrupt
#
ParseKey:
	# r4 has number of arguments on the stack

	# We're only looking for very specific conditions 
	# Either 1 argument and 0x2D (R) or 3 arguments 0xE0/0xE0,0xF0 and 0x75/0x6B/0x72/0x74 for up/left/down/right down/up


FIRST_ARGUMENT:
	# Move pointer to the first argument
	mov r10, r4
	addi r10, r10, -1
	slli r10, r10, 2
	add r10, r10, sp
	ldw r8, 0(r10)

	# R restart game
	movi r9, 0x2D
	beq r8, r9, KEY_RESTART

	# Space fire
	movi r9, 0x29
	beq r8, r9, KEY_FIRE

	# If thats the only arg, we're done
	movi r9, 1
	beq r4, r9, DONE

	# Otherwise it has to be E0 (make/break)
	movi r9, 0xE0
	bne r8, r9, DONE

SECOND_ARGUMENT:
	# Second argument
	addi r10, r10, -4
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
	beq r4, r9, DONE

	# Otherwise the second arg has to be F0 (break-code)
	movi r9, 0xF0
	bne r8, r9, DONE

THIRD_ARGUMENT:
	# Third argument
	addi r10, r10, -4
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
	xori r9, r8, 0xF
	and r8, r8, r9
	sth r8, 0(r10)
	br DONE

KEY_FIRE:
	movi r8, SPACE_KEY
	br KEY_DOWN
	#addi sp, sp, -4
	#stw ra, 0(sp)
	#call Fire
	#ldw ra, 0(sp)
	#addi sp, sp, 4
	#br DONE

KEY_RESTART:
	addi sp, sp, -4
	stw ra, 0(sp)
	call RestartGame
	ldw ra, 0(sp)
	addi sp, sp, 4
	br DONE

DONE:
	ret

