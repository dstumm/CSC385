.section .exceptions, "ax"
ISR:
	# Save every register used 
	addi sp, sp, -28
	stw r4, 0(sp)
	stw r8, 4(sp)
	stw r9, 8(sp)
	stw r10, 12(sp)
	stw r16, 16(sp)
	stw r17, 20(sp)
	stw ra, 24(sp)

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

	br EXIT_HANDLER

#
# Process timer interrupt
#
TIMER_INTR:
	# Clear timout
	movia r8, ADDR_TIMER
	ldwio r9, 0(r8)
	andi r9, r9, 2
	stwio r0, 0(r8)
  # Set tick to go
  movia r8, TICK_STATE
  movi r9, 1
  sth r9, 0(r8)
	br EXIT_HANDLER

#
# Process keyboard interrupt
#
KEYBOARD_INTR:
	# Read command may consist of consequtive codes
READ_COMMAND:
	# Starting there is zero codes
	mov r17, r0
NOT_VALID:
	# poll bit 15 until valid
	movia r8, ADDR_KEYBOARD
	ldwio r9, 0(r8)
	andi r10, r9, 0x8000
	beq r10, r0, NOT_VALID
	# Data is valid
	# Get how many characters left to read
	mov r16, r9
	srli r16, r16, 16
	# r16 has pending number of codes

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

	# Otherwise were at the end of the command, call parse, r4 holds number of arguments on stack
	mov r4, r17
	call ParseKey

	# Restore stack pointer by multiply r2 by 4 and adding
	slli r17, r17, 2
	add sp, sp, r17

	# After parse if there's another code, it means there are more commands so read another, otherwise exit
	bgt r16, r0, READ_COMMAND
	br EXIT_HANDLER

NEXT_CODE:
	br NOT_VALID

EXIT_HANDLER:
	# Restore them
	ldw r4, 0(sp)
	ldw r8, 4(sp)
	ldw r9, 8(sp)
	ldw r10, 12(sp)
	ldw r16, 16(sp)
	ldw r17, 20(sp)
	ldw ra, 24(sp)
	addi sp, sp, 28

	subi ea, ea, 4
	eret

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
	xori r8, r9, 0xFFFF
	and r8, r8, r9
	sth r8, 0(r10)
	br DONE

KEY_FIRE:
	addi sp, sp, -4
	stw ra, 0(sp)
	call Fire
	ldw ra, 0(sp)
	addi sp, sp, 4
	br DONE

KEY_RESTART:
	addi sp, sp, -4
	stw ra, 0(sp)
	call RestartGame
	ldw ra, 0(sp)
	addi sp, sp, 4
	br DONE

DONE:
	ret

