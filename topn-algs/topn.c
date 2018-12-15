/*-
 * GNU GENERAL PUBLIC LICENSE, version 3
 * See LICENSE file for detail.
 *
 * Author: Yulong Yu
 * Copyright(c) 2018 Yulong Yu. All rights reserved.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <fcntl.h>

static int
_topnsel_quicksort (long *data, int startidx, int endidx)
{
	long pivot = data[startidx];
	int p = startidx + 1;
	int q = endidx;
	long swapbuf;
	
	if ( startidx == endidx )
		return startidx;
	
	while ( 1 ) {
		while ( 1 ) {
			if ( p == q || data[p] < pivot )
				break;
			p++;
		}
		if ( p == q )
			break;
		
		while ( 1 ) {
			if ( p == q || data[q] > pivot )
				break;
			q--;
		}
		if ( p == q )
			break;
		
		swapbuf = data[p];
		data[p] = data[q];
		data[q] = swapbuf;
	}
	
	if ( data[p] < pivot )
		p--;
	if ( p != startidx ) {
		swapbuf = data[p];
		data[p] = data[startidx];
		data[startidx] = swapbuf;
	}
	return p;
}

static void 
topnsel_quicksort (long *data, int insize, int outsize)
{
	int startidx = 0;
	int endidx = insize - 1;
	int pivotidx = -2;
	
	if ( insize <= outsize )
		return;
	
	while ( pivotidx < outsize - 1 || pivotidx > outsize + 1 ) {
		pivotidx = _topnsel_quicksort (data, startidx, endidx);
		if ( pivotidx > outsize )
			endidx =  pivotidx - 1;
		else
			startidx = pivotidx + 1;
	}
}

static void
topnsel_selsort (long *data, int insize, int outsize)
{
	int run, i, maxidx;
	long swapbuf;
	
	if ( insize <= outsize )
		return;
	
	for ( run = 0; run < outsize; run++ ) {
		maxidx = run;
		
		for ( i = run + 1; i < insize; i++ ) {
			if ( data[i] > data[maxidx] )
				maxidx = i;
		}
		
		if ( maxidx != run ) {
			swapbuf = data[maxidx];
			data[maxidx] = data[run];
			data[run] = swapbuf;
		}
	}
}

static void
topnsel_inssort (long *data, int insize, int outsize)
{
	int run, posidx, i;
	long swapbuf;
	
	if ( insize <= outsize )
		return;

	topnsel_selsort (data, outsize, outsize - 1);
	for ( run = outsize; run < insize; run++ ) {
		for ( posidx = outsize - 1; posidx >= 0; posidx-- ) {
			if ( data[posidx] >= data[run] )
				break;
		}
		posidx += 1;
		if ( posidx == outsize )
			continue;
		
		swapbuf = data[outsize - 1];
		for ( i = outsize - 1; i > posidx; i-- ) {
			data[i] = data[i - 1];
		}
		data[posidx] = data[run];
		data[run] = swapbuf;
	}
}

typedef void (*topnsel_func) (long *data, int insize, int outsize);

static inline void
generate_rand (long *data, int size)
{
	int i;
	for ( i = 0; i < size; i++ )
		data[i] = rand ();
}

static void
test_topn_perf (const char *title, topnsel_func worker, 
				long *data, int insize, int outsize)
{
    struct timespec t1, t2;
    uint64_t diff;

	generate_rand (data, insize);
	
    clock_gettime(CLOCK_MONOTONIC, &t1);
    worker (data, insize, outsize);
    clock_gettime(CLOCK_MONOTONIC, &t2);

    diff = (t2.tv_sec * 1000000000 + t2.tv_nsec - 
            t1.tv_sec * 1000000000 - t1.tv_nsec);
    printf ("%16s: elapsed %16lu ns\n", title, diff);
}

int
main (int argc, char **argv)
{
	int insize = 100000, outsize = 100;
	long *data = NULL;

	if ( argc >= 2 ) {
		sscanf (argv[1], "%d", &insize);
		sscanf (argv[2], "%d", &outsize);
		
	}

	srand (time (0));
	data = malloc (insize * sizeof (long));
	if ( data == NULL )
		exit (1);
	
	test_topn_perf ("Quick Sort", topnsel_quicksort, data, insize, outsize);
	test_topn_perf ("Select Sort", topnsel_selsort, data, insize, outsize);
	test_topn_perf ("Insertion Sort", topnsel_inssort, data, insize, outsize);
	
	return 0;
}