.data
.equ ADDR_TIMER, 0xFF202000

RECT:
	.hword 1
	.hword 2
	.hword 3
	.hword 4

.text
.global main

main:
	call drawing_print_buffer_info
	movia r4, 0x01000000
	call drawing_init

	movia r8, ADDR_TIMER
	stwio r0, 0(r8)
	movia r9, 0x6e6b
	movia r10, 0x0019
	stwio r9, 8(r8)
	stwio r10, 12(r8)
	movi r9, 7
	stwio r9, 4(r8)

	movia r9, 0x1
	wrctl ctl3, r9

	movia r9, 1
	wrctl ctl0, r9

	#call drawing_print_buffer_info
	#call drawing_clear_buffer
	#call drawing_swap_buffers
	#call drawing_print_buffer_info
	#call drawing_clear_buffer
	#movia r4, RECT
	#movia r5, 0x0FF0
	#call drawing_fill_rect

	call drawing_clear_buffer
	movi r4, 0
	call INIT_INVASION
	call DRAW_INVASION
	call drawing_swap_buffers

LOOP:
	br LOOP
	ret

TICK:
	subi sp, sp, 4
	stw ra, 0(sp)

	#call drawing_clear_buffer
	#movia r4, RECT
	#movia r5, 0x0FF0
	#call drawing_fill_rect

	#movi r4, 0
	#movi r5, 319
	#movi r6, 230
	#movi r7, 0xFF
	#call drawing_draw_hline

	#call drawing_swap_buffers

	#movia r4, RECT
	#ldw r5, 0(r4)
	#addi r5, r5, 1
	#stw r5, 0(r4)

	#ldw ra, 0(sp)
	#addi sp, sp, 4
	
	ret

.section .exceptions, "ax"

ISR:
	#call TICK
	movia r8, ADDR_TIMER
	ldwio r9, 0(r8)
	andi r9, r9, 2
	stwio r9, 0(r8)
	
	subi ea, ea, 4
	eret

