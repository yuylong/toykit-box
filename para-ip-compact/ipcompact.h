/*-
 * GNU GENERAL PUBLIC LICENSE, version 3
 * See LICENSE file for detail.
 *
 * Author: Yulong Yu
 * Copyright(c) 2018 Yulong Yu. All rights reserved.
 */

#ifndef __IPCOMPACT_H__
#define __IPCOMPACT_H__

enum ipnode_type
{
    IPNODE_TYPE_DUMMY = 0,
    IPNODE_TYPE_SINGLE,
    IPNODE_TYPE_SCOPE,
    IPNODE_TYPE_NET
};

struct ipnode
{
    int type;
    unsigned int ip;
    union {
        unsigned int end_ip;
        unsigned int masklen;
    } u;
};

int ip_compact (unsigned int iplist[], int num, 
                struct ipnode outlist[], int *outnum);

#endif

