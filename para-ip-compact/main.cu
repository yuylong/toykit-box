/*-
 * GNU GENERAL PUBLIC LICENSE, version 3
 * See LICENSE file for detail.
 *
 * Author: Yulong Yu
 * Copyright(c) 2018 Yulong Yu. All rights reserved.
 */

#include <stdio.h>
#include <string.h>

#include "ipcompact.h"

#define IP_LIST_MAX_SIZE    2048

static unsigned int parse_ip_string (const char *str);
static void print_ip_list (unsigned int ip_list[], int num);

static unsigned int h_ip_list [IP_LIST_MAX_SIZE] = { 0 };
static struct ipnode h_out_list [IP_LIST_MAX_SIZE];
static int ip_list_cnt = 0, out_list_cnt;

int main (int argc, char **argv)
{
    FILE *fp;
    const char *filename = "iplist.txt";
    char chbuf[128];
    int i;

    if ( argc > 1 ) {
        printf ("IP Address = %08X\n", parse_ip_string(argv[1]));
    }
    if ( argc > 2 ) {
        filename = argv[2];
    }

    fp = fopen (filename, "r");
    if ( fp == NULL ) {
        printf ("Error while opening the IP list file!\n");
        return -1;
    }

    while ( fgets (chbuf, 128, fp) ) {
        if ( ip_list_cnt >= IP_LIST_MAX_SIZE )
            break;

        h_ip_list[ip_list_cnt] = parse_ip_string (chbuf);
        if ( h_ip_list[ip_list_cnt] != 0 )
            ip_list_cnt++;
    }

    fclose (fp);

    print_ip_list (h_ip_list, ip_list_cnt);

    ip_compact (h_ip_list, ip_list_cnt, h_out_list, &out_list_cnt);

    return 0;
}

static unsigned int parse_ip_string (const char *str)
{
    union {
        unsigned int val;
        char bval[4];
    } retval;
    int i = 3;
    const char *p = str;

    retval.val = 0;
    while ( *p != '\0' ) {
        if ( *p >= '0' && *p <= '9' )
            retval.bval[i] = retval.bval[i] * 10 + *p - '0';
        else if ( *p == '.' )
            i--;
        else
            break;

        p++;
    }
    return retval.val;
}

static void print_ip_list (unsigned int ip_list[], int num)
{
    int i;

    printf ("IP List [%d]: ", num);
    for ( i = 0; i < num; i++ ) {
        printf ("%s %08X", (i == 0 ? "" : ","), ip_list[i]);
    }
    printf ("\n");
}

