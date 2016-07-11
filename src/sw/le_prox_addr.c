/* ****************************************************************************
 * vim:set shiftwidth=2 softtabstop=2 expandtab:
 * $Id: counterdump.c 5455 2009-05-05 18:18:16Z g9coving $
 *
 * Module:  counterdump.c
 * Project: NetFPGA NIC
 * Description: dumps the MAC Rx/Tx counters to stdout
 * Author: Jad Naous
 *
 * Change history:
 *
 */
/*Testa escrita e leitura na SRAM utilizando interfaces de registradores*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <net/if.h>

#include "../lib/C/reg_defines_novo_reference_nic.h"
#include "../../../lib/C/common/nf2.h"
#include "../../../lib/C/common/nf2util.h"

#define PATHLEN		80

#define DEFAULT_IFACE	"nf2c0"

/* Global vars */
static struct nf2device nf2;

/* Function declarations */
void dumpCounts();
void processArgs (int , char **);
void usage (void);

int main(int argc, char *argv[])
{
  nf2.device_name = DEFAULT_IFACE;

  processArgs(argc, argv);

  // Open the interface if possible
  if (check_iface(&nf2))
    {
      exit(1);
    }
  if (openDescriptor(&nf2))
    {
      exit(1);
    }

  dumpCounts();

  closeDescriptor(&nf2);

  return 0;
}

void dumpCounts()
{
  unsigned val;

  readReg(&nf2, BLOOM_PROX_ENDERECO_REG, &val);
  printf("%u\n", val);
}

/*
 *  Process the arguments.
 */
void processArgs (int argc, char **argv )
{
  char c;

  /* don't want getopt to moan - I can do that just fine thanks! */
  opterr = 0;

   while ((c = getopt (argc, argv, "i:h")) != -1) {
      switch (c) {
         case 'i':	/* interface name */
           nf2.device_name = optarg;
           break;
         case 'h':
         default:
           usage();
           exit(1);
      }
   }
}


/*
 *  Describe usage of this program.
 */
void usage (void)
{
  printf("Usage: ./counterdump <options> \n\n");
  printf("Options: -i <iface> : interface name (default nf2c0)\n");
  printf("         -h : Print this message and exit.\n");
}
