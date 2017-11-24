.text
.global INIT_INVADERS, RESET_INVADERS, DRAW_INVADERS, UPDATE_INVADERS

# Initialize invaders and state
# r4: current game tick
INIT_INVADERS:
    # only using caller saved registers, no need for stack

    movia r5, INVADERS_STATE                            # setup initial state
    stw r4, 0(r5)
    stw r0, 4(r5)

    movia r4, INVADER_TYPES                             # start of invader types array
    addi r5, r4, INVADERS_ROWS * 4                      # end of invader types array
    
    movia r6, INVADERS                                  # start of invaders array

    movia r11, 0x000F0000                               # initial y position
    INIT_INVADERS_ROW:
        addi r7, r6, INVADER_SIZE * INVADERS_COLS       # end of current row in invaders array
        ldw r9, 0(r4)                                   # get address for invader type
        ldw r13, 4(r9)                                  # get size for invader type
        ldw r14, 8(r9)                                  # get color, points, etc for invader type
        ldw r15, 12(r9)                                 # get sprite address for invader type

        movia r8, 0xFFFF                                # get width for invader type
        and r9, r13, r8

        movi r10, GRID_WIDTH                            # compute offset to center invader in grid
        sub r10, r10, r9
        movi r9, 2
        div r10, r10, r9

        addi r10, r10, (320 - (GRID_WIDTH * INVADERS_COLS)) / 2
        
        INIT_INVADER:
            or r12, r11, r10                            # combine x and y position
            stw r12, 0(r6)
            stw r13, 4(r6)
            stw r14, 8(r6)
            stw r15, 12(r6)
            addi r6, r6, INVADER_SIZE                   # move to next invader
            addi r10, r10, GRID_WIDTH                   # move x position
            blt r6, r7, INIT_INVADER
        addi r4, r4, 4                                  # end of row, move to next invader type
        srli r11, r11, 16                               # move y position
        addi r11, r11, GRID_HEIGHT
        slli r11, r11, 16
        blt r4, r5, INIT_INVADERS_ROW
    ret

# Reset invaders and state
# All invaders become alive again, are centered and move up 1 row
# Call to reset level
RESET_INVADERS:
    movia r5, INVADERS_STATE
    stw r4, 4(r5)
    stw r0, 4(r5)

        
    ret    

# Draw invaders that aren't dead
DRAW_INVADERS:
    ret

# update invader state
# r4: current tick
UPDATE_INVADERS:
    ret

.data

# sprites for invaders
INVADER_SPRITE_SMALL:
    #.string "0001100000111100011111101101101111111111001001000101101010100101"
    .string "000110000011110001111110110110111111111101011010100000010100001000000000000000000000000000000000"
    .string "000110000011110001111110110110111111111100100100010110101010010100000000000000000000000000000000"

INVADER_SPRITE_MEDIUM:
    #.string "0010000010000010001000001111111000110111011011111111111101111111011010000010100011011000"
    .string "001000001000001000100000111111100011011101101111111111110111111101101000001010001101100000000000"
    .string "001000001001001000100110111111101111011101111111111111101111111110001000001000100000001000000000"

INVADER_SPRITE_LARGE:
    .string "000011110000011111111110111111111111111001100111111111111111000110011000001101101100110000000011"
    .string "000011110000011111111110111111111111111001100111111111111111001110011100011001100110001100001100"

# INVADER:
# base      - x position
# base + 2  - y position
# base + 4  - width
# base + 6  - height
# base + 8  - state
# base + 9  - points
# base + 10 - color
# base + 12 - address to sprite

# define the different invader types
.align 2
INVADER_TYPE_SMALL:
    .word 0x00000000
    .word 0x00080008 # 8 x 8
    .word 0xFFFF1E01 # white, 30 points, alive
    .word INVADER_SPRITE_SMALL

.align 2
INVADER_TYPE_MEDIUM:
    .word 0x00000000
    .word 0x0008000B # 11 x 8
    .word 0xFFFF1401 # white, 20 points, alive
    .word INVADER_SPRITE_MEDIUM

.align 2
INVADER_TYPE_LARGE:
    .word 0x00000000
    .word 0x0008000C # 12 x 8
    .word 0xFFFF0A01 # white, 10 points, alive
    .word INVADER_SPRITE_LARGE

# define which invader type appears in each row
.align 2
INVADER_TYPES:
    .word INVADER_TYPE_SMALL
    .word INVADER_TYPE_MEDIUM
    .word INVADER_TYPE_MEDIUM
    .word INVADER_TYPE_LARGE
    .word INVADER_TYPE_LARGE

.align 2
INVADERS:
    .skip INVADER_SIZE * INVADERS_ROWS * INVADERS_COLS

.align 2
INVADERS_STATE:
    .word 0
    .word 0

.equ INVADER_SIZE, 16                                   # size of an invader in bytes
.equ INVADERS_ROWS, 5                                   # number of rows of invaders
.equ INVADERS_COLS, 11                                  # number of columns of invaders
.equ GRID_WIDTH, 14                                     # horizontal space for an invader in the grid, including padding
.equ GRID_HEIGHT, 14                                    # vertical space for an invader in the grid, including padding
.equ DROP_DISTANCE, 8                                   # how far to move invaders down when they reach the edge
.equ SPRITE_SIZE, 97                                    # size of sprite for on state

