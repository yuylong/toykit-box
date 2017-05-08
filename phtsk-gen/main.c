/*-
 * GNU GENERAL PUBLIC LICENSE, version 3
 * See LICENSE file for detail.
 *
 * Author: Yulong Yu, May 7th, 2017
 * Copyright(c) 2017 Yulong Yu. All rights reserved.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <ctype.h>

struct ptg_line {
    uint32_t ls_magic;
    uint32_t ls2_magic;
    uint32_t start_ip;
    uint32_t end_ip;
    uint32_t sp_magic;
    uint32_t start_port;
    uint32_t end_port;
};

static inline void
ptg_write_file_magic (int fd)
{
    static const uint8_t magic[2] = { '\x11', '\x03' };
    write (fd, magic, sizeof (magic));
}

static inline void
ptg_gen_line (uint32_t startip, uint32_t endip,
              uint16_t startport, uint16_t endport,
              struct ptg_line *outline)
{
    static const uint32_t lsmagic = 0x02;
    static const uint32_t ls2magic = 0x00;
    static const uint32_t spmagic = 0x01;

    outline->ls_magic = lsmagic;
    outline->ls2_magic = ls2magic;
    outline->start_ip = startip;
    outline->end_ip = endip;
    outline->sp_magic = spmagic;
    outline->start_port = (uint32_t)startport;
    outline->end_port = (uint32_t)endport;
}

static inline void
ptg_write_line (int fd, struct ptg_line *outline)
{
    static const uint8_t lemagic[] = "HTTP\r\n";
    static const uint32_t le2magic = 0x01;

    write (fd, outline, sizeof (struct ptg_line));
    write (fd, lemagic, sizeof (lemagic) - 1);
    write (fd, &le2magic, sizeof (uint32_t));
}

static inline uint32_t
ptg_parse_ip_string (const char *ipstr)
{
    uint32_t subnum = 0, retip = 0;
    const char *p = ipstr;

    while ( *p != '\0' && *p != '\n' ) {
        if ( isdigit (*p) ) {
            subnum = subnum * 10 + *p - '0';
        } else if ( *p == '.' ) {
            retip = (retip << 8) + subnum;
            subnum = 0;
        }
        p++;
    }
    retip = (retip << 8) + subnum;
    return retip;
}

static void
ptg_parse_ip_line (const char *lnstr, uint32_t *ip1, uint32_t *ip2)
{
    char ipbuf[64] = { '\0' };
    char *sp;

    sp = strchr (lnstr, '-');
    if ( sp == NULL ) {
        *ip1 = *ip2 = ptg_parse_ip_string (lnstr);
    } else {
        strncpy (ipbuf, lnstr, sp - lnstr);
        *ip1 = ptg_parse_ip_string (ipbuf);
        *ip2 = ptg_parse_ip_string (sp + 1);
    }
}

static int
ptg_file_lines (const char *filename) {
    FILE *fp;
    static char lnbuf[128];
    int i = 0;

    fp = fopen (filename, "r");
    if ( fp == NULL )
        return 0;

    while ( fgets (lnbuf, 127, fp) != NULL ) {
        i++;
    }
    fclose (fp);
    return i;
}

static void
ptg_read_ip_file (const char *filename, int *lncnt,
                  uint32_t **startips, uint32_t **endips)
{
    FILE *fp;
    char lnbuf[128];
    int i = 0;

    *lncnt = ptg_file_lines (filename);
    if ( *lncnt <= 0 ) {
        *startips = *endips = NULL;
        return;
    }
    *startips = malloc (2 * (*lncnt) * sizeof (uint32_t));
    *endips = (*startips) + (*lncnt);

    fp = fopen (filename, "r");
    if ( fp == NULL ) {
        *lncnt = 0;
        *startips = *endips = NULL;
        return;
    }

    while ( fgets (lnbuf, 127, fp) != NULL ) {
        ptg_parse_ip_line (lnbuf, &(*startips)[i], &(*endips)[i]);
        i++;
    }
    fclose (fp);
}

static void
ptg_read_port_file (const char *filename, int *lncnt,
                    uint16_t **ports)
{
    FILE *fp;
    char lnbuf[128];
    int i = 0;

    *lncnt = ptg_file_lines (filename);
    if ( *lncnt <= 0 ) {
        *ports = NULL;
        return;
    }
    *ports = malloc ((*lncnt) * sizeof (uint32_t));

    fp = fopen (filename, "r");
    if ( fp == NULL ) {
        *lncnt = 0;
        *ports = NULL;
        return;
    }

    while ( fgets (lnbuf, 127, fp) != NULL ) {
        (*ports)[i] = (uint16_t)atoi (lnbuf);
        i++;
    }
    fclose (fp);
}

static void
ptg_gen_phtsk (const char *ipfile, const char *portfile,
               const char *tskfile)
{
    int ipcnt, portcnt, ipidx, portidx;
    uint32_t lncnt;
    uint32_t *stips, *enips;
    uint16_t *ports;
    int fd;
    struct ptg_line fnline;

    ptg_read_ip_file (ipfile, &ipcnt, &stips, &enips);
    ptg_read_port_file (portfile, &portcnt, &ports);
    lncnt = (uint32_t)(ipcnt * portcnt);
    if ( lncnt == 0 )
        return;

    fd = open (tskfile, O_WRONLY | O_BINARY | O_CREAT | O_TRUNC);
    ptg_write_file_magic (fd);
    write (fd, &lncnt, sizeof (uint32_t));

    for ( ipidx = 0; ipidx < ipcnt; ipidx++ ) {
        for ( portidx = 0; portidx < portcnt; portidx++ ) {
            ptg_gen_line (stips[ipidx], enips[ipidx],
                          ports[portidx], ports[portidx],
                          &fnline);
            ptg_write_line (fd, &fnline);
        }
    }

    close (fd);
}

int main(int argc, char *argv[])
{
    static const char def_ipfile[] = "ipranges.txt";
    static const char def_portfile[] = "ports.txt";
    static const char def_outfile[] = "iptask.tsk";
    const char *ipfile = def_ipfile, *portfile = def_portfile;
    const char *outfile = def_outfile;

    if ( argc >= 2 )
        ipfile = argv[1];
    if ( argc >= 3 )
        portfile = argv[2];
    if ( argc >= 4 )
        outfile = argv[3];

    ptg_gen_phtsk (ipfile, portfile, outfile);

    printf ("OK!\n");
    return 0;
}
