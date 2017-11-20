.data
.equ ADDR_TIMER, 0xff202000
.equ ADDR_LEDS, 0xff200000
.equ ADDR_7SEG, 0xfff00020
.equ ADDR_KEYBOARD 0xff200100

.align 2
COUNTER:
	.word 0
STATE: 
	.word 0

.section .exceptions, "ax"
ISR:
	# Check pending register
	rdctl et, ctl4

	# Timer interrupt
	movi r8, 1
	and r8, r8, et
	bne r8, r0, GAME_LOOP

	# Keyboard interrupt
	movi r8, 0x80
	and r8, r8, et
	bne r8, r0, INPUT

GAME_LOOP:
	# Clear timout
	movia r8, ADDR_TIMER
	ldwio r9, 0(r8)
	andi r9, r9, 2
	stwio r9, 0(r8)
	br EXIT_HANDLER

INPUT:
	# poll bit 15 until valid
	movia r8, ADDR_KEYBOARD
NOT_VALID:
	ldwio r9, 0(r8)
	andi r10, r19, 0x8000
	beq r10, r0, NOT_VALID
	# Data is valid
	# Get how many characters left to read
	movia r10, 0xffff0000
	and r10, r9, r10
	srli, r10, r10, 16
	# r10 has pending number of characters
READ_CHAR:
	// Get the data
	andi r11, r9, 0xff
	// Check what key it is
	// Decrement counter
	subi r10, r10 1
	bgt r10, r0, READ_CHAR
	br EXIT_HANDLER
EXIT_HANDLER:
	subi ea, ea, 4
	eret

.text
.global _start
_start:
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
	movi, r9, 1
	stwio r9, 0(r8)
	
	# Enable IRQ for timer/keyboard (IRQ 7 and IRQ 0)
	movia r9, 0x81
	wrctl ctl3, r9
	# Enable interrupts globally
	movia r9, 1
	wrctl ctl0, r9

LOOP:
	br LOOP

