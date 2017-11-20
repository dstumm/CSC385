#include <stdio.h>

volatile unsigned int *BUFFER_REGISTER = (unsigned int *)0xFF203020;
volatile unsigned int *BACK_BUFFER_REGISTER = (unsigned int *)0xFF203024;
volatile unsigned int *RESOLUTION_REGISTER = (unsigned int *)0xFF203028;
volatile unsigned int *STATUS_REGISTER = (unsigned int *)0xFF20302C;

typedef struct buffer_t {
    unsigned int base;
    unsigned int addressing_mode;
    unsigned int color_mode;
    unsigned int x_resolution;
    unsigned int y_resolution;
    unsigned int wib;
    unsigned int hib;
} buffer_t;

buffer_t buffer;

/**
 * Prints info about the buffer.
 */
int drawing_print_buffer_info() {
    unsigned int resolution = *RESOLUTION_REGISTER;
    unsigned int status = *STATUS_REGISTER;
    
    unsigned int addressing_mode = (status >> 1) & 0x1;
    unsigned int color_mode = (status >> 4) & 0xFF;
    unsigned int x_resolution = resolution & 0xFFFF;
    unsigned int y_resolution = (resolution >> 16) & 0xFFFF;
    unsigned int wib = (status >> 16) & 0xFF;
    unsigned int hib = (status >> 24) & 0xFF;

    printf("Front Buffer: 0x%x\n", *BUFFER_REGISTER);
    printf("Back Buffer: 0x%x\n", *BACK_BUFFER_REGISTER);
    printf("Addressing Mode: %d\n", addressing_mode);
    printf("Color Mode: %d", color_mode);
    printf("X Resolution: %d\n", x_resolution);
    printf("Y Resolution: %d\n", y_resolution);
    printf("X Width in Bits: %d\n", wib);
    printf("Y Width in Bits: %d\n", hib);

    return 0;
}

/**
 * Init buffer info and back buffer.
 */
int drawing_init(unsigned int back_buffer_addr) {
    // set back buffer address
    *BACK_BUFFER_REGISTER = back_buffer_addr;
    
    // assume defaults for now
    buffer.base = back_buffer_addr;
    buffer.addressing_mode = 1;
    buffer.color_mode = 2;
    buffer.x_resolution = 320;
    buffer.y_resolution = 240;
    buffer.wib = 9;
    buffer.hib = 8;

    return 0;
}

/**
 * Swap front and back buffers.
 */
int drawing_swap_buffers() {
    buffer.base = *BUFFER_REGISTER;
    *BUFFER_REGISTER = 1;
    return 0;
}

/**
 * Clear the back buffer.
 */
int drawing_clear_buffer() {
    volatile short *addr = (short *)buffer.base;
    unsigned int x, y, offset;

    for (y = 0; y < buffer.y_resolution; y++) {
        for (x = 0; x < buffer.x_resolution; x++) {
            offset = (y << buffer.wib) + x;
            *(addr + offset) = 0x0000;
        }
    }

    return 0;
}

/**
 * Draw a single pixel to the back buffer.
 */
int drawing_draw_pixel(unsigned int x, unsigned int y, unsigned int color) {
    // boundary check
    if (x >= buffer.x_resolution || y >= buffer.y_resolution) {
        return -1;
    }

    volatile short *addr = (short *)buffer.base;
    unsigned offset = (y << buffer.wib) + x;
    *(addr + offset) = (short)color;

    return 0;
}

/**
 * Fill a rectangle in the back buffer.
 * Truncates to fit the screen.
 */
int drawing_fill_rect(unsigned int x_start, unsigned int y_start, unsigned int width, unsigned int height, unsigned int color) {
    // boundary check
    if (x_start >= buffer.x_resolution || y_start >= buffer.y_resolution) {
        return -1;
    }

    volatile short *addr = (short *)buffer.base;
    unsigned int x, y, x_end, y_end, x_limit, y_limit, y_offset;
    
    // clip x coordinates to the screen
    x_limit = buffer.x_resolution;
    x_end = x + width;
    if (x_end >= x_limit) {
        x_end = x_limit;
    }

    // clip y coordinates to the screen
    y_limit = buffer.y_resolution;
    y_end = y + height;
    if (y_end >= y_limit) {
        y_end = y_limit;
    }
    
    addr += (y << buffer.wib);
    for (y = y_start; y < y_end; y++) {
        for (x = x_start; x < x_end; x++) {
            *(addr + x) = (short)color;
        }
        addr += (1 << buffer.wib);
    }
 
    return 0;
}
