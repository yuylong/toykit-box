/*-
 * GNU GENERAL PUBLIC LICENSE, version 3
 * See LICENSE file for detail.
 *
 * Author: Yulong Yu
 * Copyright(c) 2018 Yulong Yu. All rights reserved.
 */

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <time.h>


static inline uint64_t
get_start_partial_csum64 (uint16_t **ptr, uint32_t *len)
{
    uint64_t csum = 0;

    if ( *len < 2 )
        return 0;
    if ( (uint64_t)(*ptr) & 0x03 ) {
        csum = *(*ptr)++;
        *len -= 2;
    }

    if ( *len < 4 )
        return csum;
    if ( (uint64_t)(*ptr) & 0x07 ) {
        csum += *((uint32_t *)(*ptr));
        *ptr += 2;
        *len -= 4;
    }
    return csum;
}

static inline uint16_t
get_end_partial_csum64 (uint64_t sum, uint16_t *ptr16, uint32_t len)
{
    sum = ((sum >> 32) + (sum & 0xFFFFFFFF));
    if ( len >= 4 ) {
        sum += *((uint32_t *)ptr16);
        ptr16 += 2;
        len -= 4;
    }
    sum = ((sum >> 16) + (sum & 0xFFFF));
    if ( len >= 2 ) {
        sum += *ptr16++;
        len -= 2;
    }
    if ( len >= 1 )
        sum += *(uint8_t *)ptr16;

    sum = ((sum >> 16) + (sum & 0xFFFF));
    return (uint16_t)sum;
}

uint16_t get_16b_sum64 (uint16_t *ptr16, uint32_t len)
{
    uint64_t sum = 0;
    uint64_t *ptr64;

    sum = get_start_partial_csum64 (&ptr16, &len);
    ptr64 = (uint64_t *)ptr16;
    while ( len > 7 ) {
        uint64_t newsum = sum + *ptr64++;
        len -= 8;
        if ( newsum < sum )
            sum = newsum + 1;
        else
            sum = newsum;
    }
    
    return get_end_partial_csum64 (sum, (uint16_t *)ptr64, len);
}

static inline uint64_t
get_start_partial_csum32 (uint16_t **ptr, uint32_t *len)
{
    uint64_t csum = 0;

    if ( *len < 2 )
        return 0;
    if ( (uint64_t)(*ptr) & 0x03 ) {
        csum = *(*ptr)++;
        *len -= 2;
    }
    return csum;
}

static inline uint16_t
get_end_partial_csum32 (uint64_t sum, uint16_t *ptr16, uint32_t len)
{
    if ( len >= 2 ) {
        sum += *ptr16++;
        len -= 2;
    }
    if ( len >= 1 )
        sum += *(uint8_t *)ptr16;

    sum = ((sum >> 32) + (sum & 0xFFFFFFFF));
    sum = ((sum >> 16) + (sum & 0xFFFF));
    sum = ((sum >> 16) + (sum & 0xFFFF));
    return (uint16_t)sum;
}

uint16_t get_16b_sum32 (uint16_t *ptr16, uint32_t len)
{
    uint64_t sum = 0;
    uint32_t *ptr32;

    sum = get_start_partial_csum32 (&ptr16, &len);
    ptr32 = (uint32_t *)ptr16;
    while ( len > 3 ) {
        sum += *ptr32++;
        len -= 4;
    }
    return get_end_partial_csum32 (sum, (uint16_t *)ptr32, len);
}

typedef uint16_t (*get_sum_func) (uint16_t *ptr16, uint32_t len);

void 
test_func (uint16_t *buf, uint32_t len, uint32_t sublen, int repeat, 
           get_sum_func worker)
{
    uint32_t curoff = 0;
    uint16_t csum;
    struct timespec t1, t2;
    uint64_t diff;

    clock_gettime(CLOCK_MONOTONIC, &t1);
    for ( repeat--; repeat >= 0; repeat-- ) {
        if ( sublen == 0 ) {
            csum = worker (buf, len);
        } else {
            for ( curoff = 0; len - curoff >= sublen; curoff += sublen ) {
                csum = worker (buf + curoff / sizeof (uint16_t), sublen);
            }
        }
    }
    clock_gettime(CLOCK_MONOTONIC, &t2);

    diff = (t2.tv_sec * 1000000000 + t2.tv_nsec - 
            t1.tv_sec * 1000000000 - t1.tv_nsec);
    printf ("Checksum = 0x%hX\n", csum);
    printf ("Elapsed %lu ns\n", diff);
}

uint16_t csumbuf[65536];

int 
main (int argc, char **argv)
{
    uint8_t *buf = (uint8_t *)csumbuf;
    int fd, repeat = 1;
    uint32_t len = 0, sublen = 0;
    get_sum_func worker = NULL;

    if ( argc <= 2 ) {
        printf ("Usage: checksum 32|64 filename [sublen] [repeat]");
        return 0;
    }
    if ( argc > 3 )
        sublen = atoi (argv[3]);
    if ( argc > 4 )
        repeat = atoi (argv[4]);

    fd = open (argv[2], O_RDONLY | O_NONBLOCK);
    if ( fd < 0 ) {
        printf ("Cannot open file!\n");
        exit (0);
    }

    len = read (fd, buf, 65536 * sizeof (uint16_t));
    if ( len < 0 ) {
        printf ("Read file failed!\n");
        close (fd);
        exit (0);
    }
    close (fd);

    if ( strcmp (argv[1], "32") == 0 )
        worker = get_16b_sum32;
    else if ( strcmp (argv[1], "64") == 0 )
        worker = get_16b_sum64;

    test_func (csumbuf, len, sublen, repeat, worker);
    return 0;
}
