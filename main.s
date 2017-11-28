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

.align 1
TICK_STATE:
  .hword 0

.global INPUT_STATE
.global RIGHT_ARROW_KEY
.global LEFT_ARROW_KEY
.global UP_ARROW_KEY
.global ADDR_LEDS
.global ADDR_TIMER
.global ADDR_KEYBOARD
.global TICK_STATE


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

	movia r4, 0x08000000
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
