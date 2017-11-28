#include <stdio.h>
#include <string.h>

volatile unsigned int *BUFFER_REGISTER = (unsigned int *)0xFF203020;
volatile unsigned int *BACK_BUFFER_REGISTER = (unsigned int *)0xFF203024;
volatile unsigned int *RESOLUTION_REGISTER = (unsigned int *)0xFF203028;
volatile unsigned int *STATUS_REGISTER = (unsigned int *)0xFF20302C;

typedef struct point_t {
	unsigned short x;
	unsigned short y;
} point_t;

typedef struct rect_t {
	unsigned short x;
	unsigned short y;
	unsigned short width;
	unsigned short height;
} rect_t;

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
    // set back buffer address (if it hasn't already been set)
	if (*BACK_BUFFER_REGISTER == *BUFFER_REGISTER) {
		*BACK_BUFFER_REGISTER = back_buffer_addr;
	}

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
    volatile void *addr = (void *)buffer.base;
	memset((void*)addr, 0, 0x3ffff);
	return 0;
}
/**
 * Draw a single pixel to the back buffer.
 */
int drawing_draw_pixel(unsigned short x, unsigned short y, unsigned short color) {
    // boundary check
    if (x >= buffer.x_resolution || y >= buffer.y_resolution) {
        return -1;
    }

    volatile short *addr = (short *)buffer.base;
    unsigned int offset = (y << buffer.wib) + x;
    *(addr + offset) = color;

    return 0;
}

/**
 * Fill a rectangle in the back buffer.
 * Truncates to fit the screen.
 */
int drawing_fill_rect(rect_t *rect, unsigned short color) {
	//printf("x: %d\n", rect->x);
	//printf("y: %d\n", rect->y);
	//printf("width: %d\n", rect->width);
	//printf("height: %d\n", rect->height);
    // boundary check
    if (rect->x >= buffer.x_resolution || rect->y >= buffer.y_resolution) {
        return -1;
    }

    volatile short *addr = (short *)buffer.base;
	unsigned short x, y, y_offset,
				   x1 = rect->x,
				   y1 = rect->y,
				   x2 = x1 + rect->width,
				   y2 = y1 + rect->height;
    
    // clip x coordinates to the screen
   	if (x2 >= buffer.x_resolution){
		x2 = buffer.x_resolution - 1;
    }

    // clip y coordinates to the screen
    if (y2 >= buffer.y_resolution) {
        y2 = buffer.y_resolution - 1;
    }
    
    addr += (y1 << buffer.wib);
    for (y = y1; y < y2; y++) {
        for (x = x1; x < x2; x++) {
//printf("addr: %x\n", addr + x);
            *(addr + x) = color;
        }
        addr += (1 << buffer.wib);
    }
 
    return 0;
}

/**
 * Draw a horizontal line to the back buffer.
 */
int drawing_draw_hline(unsigned short x1, unsigned short x2, unsigned short y, unsigned short color) {
	if (x1 > x2) {
		unsigned short temp = x1;
		x1 = x2;
		x2 = x1;
	}
	
	// boundary check	
	if (x1 >= buffer.x_resolution || y >= buffer.y_resolution) {
		return -1;
	}
	
	// clip to screen
	if (x2 >= buffer.x_resolution) {
		x2 = buffer.x_resolution - 1;
	}
	

	volatile short *addr = (short *)buffer.base + (y << buffer.wib);
	for (; x1 <= x2; x1++) {
		*(addr + x1) = color;
	}
	
	return 0;
}

/**
 * Draw a bitmap to the back buffer.
 */
int drawing_draw_bitmap(struct rect_t *rect, char *bitmap, unsigned short color) {

	//printf("x: %d\n", rect->x);
	//printf("y: %d\n", rect->y);
	//printf("width: %d\n", rect->width);
	//printf("height: %d\n", rect->height);

	// boundary check
	if (rect->x >= buffer.x_resolution || rect->y >= buffer.y_resolution) {
		return -1;
	}

    volatile short *addr = (short *)buffer.base;
	unsigned short x, y, y_offset,
				   x1 = rect->x,
				   y1 = rect->y,
				   x2 = x1 + rect->width,
				   y2 = y1 + rect->height;
    
    // clip x coordinates to the screen
   	if (x2 >= buffer.x_resolution){
		x2 = buffer.x_resolution - 1;
    }

    // clip y coordinates to the screen
    if (y2 >= buffer.y_resolution) {
        y2 = buffer.y_resolution - 1;
    }
    
    addr += (y1 << buffer.wib);
    for (y = y1; y < y2; y++) {
        for (x = x1; x < x2; x++) {
//printf("addr: %x\n", addr + x);
			if (*bitmap > 0) {
            	*(addr + x) = color;
			}
			bitmap++;
        }
        addr += (1 << buffer.wib);
    }

	return 0;
}
