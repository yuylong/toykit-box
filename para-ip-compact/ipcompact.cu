/*-
 * GNU GENERAL PUBLIC LICENSE, version 3
 * See LICENSE file for detail.
 *
 * Author: Yulong Yu
 * Copyright(c) 2018 Yulong Yu. All rights reserved.
 */

#include <stdio.h>
#include <stdlib.h>

#include "ipcompact.h"

#define CUDA_BLOCK_SIZE    8

#define IP_STR_MAXLEN     16
#define IP_CONTI_THRES     2

__global__ void ip_str_to_bin (char ipstr[], int iplist[], int num)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if ( idx >= num )
        return;
        
    int ipbin = 0, ipsect = 0;
    char *p = &ipstr[idx * IP_STR_MAXLEN];
    
    // Iterate. Any unvisible char will terminate the process.
    while ( *p >= 32 && *p <= 127 ) {
        if ( *p == '.' ) {
            ipbin = ipbin << 8 + ipsect;
            ipsect = 0;
        } else if ( *p >= '0' && *p <= '9' ) {
            ipsect = ipsect * 10 + *p - '0';
        } else {
            ipbin = ipsect = 0;
            break;
        }
        p++;
    }
    ipbin = ipbin << 8 + ipsect;
    iplist[idx] = ipbin;
}

__global__ void ip_conti_label (unsigned int iplist[], unsigned int label[], int num)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int step = 1;
    __shared__ unsigned int shd_label[CUDA_BLOCK_SIZE];
    __shared__ bool shd_dead[CUDA_BLOCK_SIZE];
    //extern __shared__ unsigned int shd_label[/*CUDA_BLOCK_SIZE * 2*/];
    //bool *shd_dead = (bool *)(shd_label + CUDA_BLOCK_SIZE);

    if ( idx >= num )
        return;

    if ( iplist[idx + 1] - iplist[idx] <= IP_CONTI_THRES && idx < num - 1 ) {
        shd_label[threadIdx.x] = 1;
        if ( threadIdx.x == CUDA_BLOCK_SIZE - 1 )
            shd_dead[threadIdx.x] = true;
        else
            shd_dead[threadIdx.x] = false;
    } else {
        shd_label[threadIdx.x] = 0;
        shd_dead[threadIdx.x] = true;
    }

    __syncthreads ();

    while ( !shd_dead[threadIdx.x] ) {
       shd_label[threadIdx.x] += shd_label[threadIdx.x + step];
       shd_dead[threadIdx.x] = shd_dead[threadIdx.x + step];

       step *= 2;
       __syncthreads ();
    }

    label[idx] = shd_label[threadIdx.x];
}

__global__ void ip_conti_label_finish (unsigned int label[], int blocknum, int blocksize)
{
    if ( blockIdx.x > 0 )
        return;
    int blkidx = threadIdx.x;
    
    while ( blkidx < blocknum - 1 ) {
        int idx = (blkidx + 1) * blocksize;
        int valf = label[idx];
        if ( valf == blocksize )
            goto iter_skip;
        
        while ( idx > 0 ) {
            if ( label[idx - blocksize] == blocksize ) {
                valf += blocksize;
                idx -= blocksize;
            } else {
                break;
            }
        }

        if ( label[idx - 1] == 0 ) {
            label[idx] = valf;
            goto iter_skip;
        }
        
        idx--;
        while ( idx > 0 ) {
            if ( label[idx - 1] == 0 )
                break;
            idx--;
        }
        label[idx] += valf;
        
    iter_skip:
        blkidx += blockDim.x;
    }
}

__global__ void ip_conti_gather (unsigned int label[], unsigned int glbl_pos[], unsigned int glbl_siz[], int blk_gther_size[], int num)
{
    int blkoff = blockIdx.x * blockDim.x;
    int idx = blkoff + threadIdx.x;
    __shared__ int shd_gth_idx[1];

    if ( threadIdx.x == 0 )
        shd_gth_idx[0] = 0;
    __syncthreads();

    if ( idx >= num )
        return;

    if ( idx == 0 || label[idx - 1] == 0 ) {
        int gth_idx = atomicAdd (&shd_gth_idx[0], 1);
        glbl_pos[blkoff + gth_idx] = idx;
        glbl_siz[blkoff + gth_idx] = label[idx] + 1;
    }

    if ( threadIdx.x != 0 )
        return;
    blk_gther_size[blockIdx.x] = shd_gth_idx[0];
}

__global__ void ip_conti_gather_idxscan (int blk_gther_size[], int out_blk_gther_size[], int blknum)
{
    if ( blockIdx.x > 0 )
        return;

    int idx = threadIdx.x, step = 1;
    int gtherbase = 0;
    __shared__ int shdarray[CUDA_BLOCK_SIZE];
    
    while ( idx < blknum ) {
        shdarray[threadIdx.x] = blk_gther_size[idx];
        __syncthreads();
        
        printf("tid=%u, idx=%u, AAA\n", threadIdx.x, idx);
        
        step = 1;
        while ( step < CUDA_BLOCK_SIZE ) {
            if ( threadIdx.x >= step )
                shdarray[threadIdx.x] += shdarray[threadIdx.x - step];
            step *= 2;
            __syncthreads();
        }
        
        out_blk_gther_size[idx] = shdarray[threadIdx.x] + gtherbase;
        if ( threadIdx.x == blockDim.x - 1 )
            gtherbase += shdarray[threadIdx.x];
            
        idx += blockDim.x;
    }
}

__global__ void ip_conti_gather_finish (unsigned int iplist[],
                                        unsigned int glbl_pos[], unsigned int glbl_siz[], int blk_gther_size[], 
                                        struct ipnode outlist[])
{
    __shared__ int localinfo[2];
    if ( threadIdx.x == 0 ) {
        localinfo[0] = ( blockIdx.x >= 1 ? blk_gther_size[blockIdx.x - 1] : 0 );
        localinfo[1] = blk_gther_size[blockIdx.x] - localinfo[0];
    }
    __syncthreads();
    
    if ( threadIdx.x >= localinfo[1] )
        return;

    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int outidx = localinfo[0] + threadIdx.x;
    int sidx = glbl_pos[idx];
    int eidx = sidx + glbl_siz[idx] - 1;
    
    outlist[outidx].ip = iplist[sidx];
    if ( eidx == sidx ) {
        outlist[outidx].type = IPNODE_TYPE_SINGLE;
    } else {
        outlist[outidx].type = IPNODE_TYPE_SCOPE;
        outlist[outidx].u.end_ip = iplist[eidx];
    }
}


int ip_compact (unsigned int iplist[], int num,
                struct ipnode outlist[], int *outnum)
{
    unsigned int *dev_iplist;
    unsigned int *dev_label;
    unsigned int *dev_gath_label, *dev_glbl_pos, *dev_glbl_siz;
    int *dev_blk_gther_size, *dev_out_blk_gther_size;
    struct ipnode *dev_outlist;
    int gridsize, blocksize;

    unsigned int *hst_label;
    unsigned int *hst_gath_label, *hst_glbl_pos, *hst_glbl_siz;
    int *hst_blk_gther_size, *hst_out_blk_gther_size;
    int i, j;

    cudaMalloc ((void **)&dev_iplist, sizeof (unsigned int) * num);
    cudaMalloc ((void **)&dev_label, sizeof (unsigned int) * num);
    cudaMalloc ((void **)&dev_glbl_pos, sizeof (unsigned int) * num);
    cudaMalloc ((void **)&dev_glbl_siz, sizeof (unsigned int) * num);
    cudaMalloc ((void **)&dev_outlist, sizeof (struct ipnode) * num);

    cudaMemcpy (dev_iplist, iplist, sizeof (unsigned int) * num,
                cudaMemcpyHostToDevice);

    blocksize = CUDA_BLOCK_SIZE;
    gridsize = (num + blocksize - 1) / blocksize;
    cudaMalloc ((void **)&dev_blk_gther_size, sizeof (int) * gridsize);
    cudaMalloc ((void **)&dev_out_blk_gther_size, sizeof (int) * gridsize);

    ip_conti_label <<<gridsize, blocksize>>> (dev_iplist, dev_label, num);
    if ( gridsize > 1 )
        ip_conti_label_finish <<<1, blocksize>>> (dev_label, gridsize, blocksize);
    ip_conti_gather <<<gridsize, blocksize>>> (dev_label, dev_glbl_pos, dev_glbl_siz, dev_blk_gther_size, num);
    ip_conti_gather_idxscan <<<1, blocksize>>> (dev_blk_gther_size, dev_out_blk_gther_size, gridsize);
    ip_conti_gather_finish <<<gridsize, blocksize>>> (dev_iplist, dev_glbl_pos, dev_glbl_siz, dev_out_blk_gther_size, dev_outlist);

    hst_label = (unsigned int *)malloc (sizeof (unsigned int) * num);
    cudaMemcpy (hst_label, dev_label, sizeof (unsigned int) * num,
                cudaMemcpyDeviceToHost);

    
    hst_glbl_pos = (unsigned int *)malloc (sizeof (unsigned int) * num);
    hst_glbl_siz = (unsigned int *)malloc (sizeof (unsigned int) * num);
    cudaMemcpy (hst_glbl_pos, dev_glbl_pos, sizeof (unsigned int) * num,
                cudaMemcpyDeviceToHost);
    cudaMemcpy (hst_glbl_siz, dev_glbl_siz, sizeof (unsigned int) * num,
                cudaMemcpyDeviceToHost);

    hst_blk_gther_size = (int *)malloc (sizeof (int) * gridsize);
    hst_out_blk_gther_size = (int *)malloc (sizeof (int) * gridsize);
    cudaMemcpy (hst_blk_gther_size, dev_blk_gther_size, sizeof (int) * gridsize,
                cudaMemcpyDeviceToHost);
    cudaMemcpy (hst_out_blk_gther_size, dev_out_blk_gther_size, sizeof (int) * gridsize,
                cudaMemcpyDeviceToHost);
                
    cudaMemcpy (outlist, dev_outlist, sizeof (struct ipnode) * num,
                cudaMemcpyDeviceToHost);

    for ( i = 0; i < num; i++ ) {
        printf ("%s%d", (i == 0 ? "" : ", "), hst_label[i]);
    }
    printf ("\n");

    printf ("Gathered Info:\n");
    for ( i = 0; i < gridsize; i++ ) {
        printf("Block-%d (%d/%d): ", i, hst_blk_gther_size[i], hst_out_blk_gther_size[i]);
        int blkoff = i * blocksize;
        for ( j = 0; j < hst_blk_gther_size[i]; j++ ) {
            printf("%s%u@%u", (j == 0 ? "" : ", "), hst_glbl_siz[blkoff + j] , hst_glbl_pos[blkoff + j]);
        }
        printf("\n");
    }

    printf ("Result:\n");
    for ( i = 0; i < hst_out_blk_gther_size[gridsize - 1]; i++ ) {
        printf ("%s", (i == 0 ? "" : ", "));
        
        if ( outlist[i].type == IPNODE_TYPE_DUMMY )
            printf ("ERROR");
        else
            printf ("%08X", outlist[i].ip);
        
        if ( outlist[i].type == IPNODE_TYPE_SCOPE)
            printf ("--%08X", outlist[i].u.end_ip);
        else if ( outlist[i].type == IPNODE_TYPE_NET)
            printf ("/%u", outlist[i].u.masklen);
    }
    printf ("\n");

    free (hst_label);
    free (hst_glbl_pos);
    free (hst_glbl_siz);
    free (hst_blk_gther_size);
    free (hst_out_blk_gther_size);

    return 0;
}
