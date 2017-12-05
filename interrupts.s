.section .exceptions, "ax"
ISR:
	# Save registers
	addi sp, sp, -4
	stw ra, 0(sp)
  	call PushAll

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
	#call GameLoop
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
	# Restore registers
  	call PopAll
	ldw ra, 0(sp)
	addi sp, sp, 4

	subi ea, ea, 4
	eret
