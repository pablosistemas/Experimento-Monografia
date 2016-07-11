#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <unistd.h>
#include <ctype.h>
#include <strings.h>

#include <arpa/inet.h>

#include "reg_defines_novo_reference_nic.h"
#include "/root/netfpga/lib/C/common/nf2.h"
#include "/root/netfpga/lib/C/common/nf2util.h"

#define DEFAULT_IFACE "nf2c0"

static struct nf2device nf2;
int limite  =10;
int offset  =1024;
char *nome_arq = NULL;

/* Global vars */
static struct nf2device nf2;

/*
 *  Describe usage of this program.
 */
void usage (void)
{
  printf("Usage: ./counterdump <options> \n\n");
  printf("Options:\n\t\t\t-i <iface> : interface name (default nf2c0)\n");
  printf("\t\t\t-f : arquivo de saida\n");
  printf("\t\t\t-l : no endereços lidos da SRAM\n");
  printf("\t\t\t-o : offset \n");
  printf("\t\t\t-h : Print this message and exit.\n");
}

/*
 *  Process the arguments.
 */
void processArgs (int argc, char **argv )
{
   char c;

   /* don't want getopt to main - I can do that just fine thanks! */
   opterr = 0;

   while ((c = getopt (argc, argv, "f:l:ho:")) != -1){
      switch (c){
         case 'f':
            nome_arq = optarg;
            break;
         case 'l':
            limite   = atoi(optarg);
            break;
         case 'o':
            offset   = atoi(optarg);
            break;
         case '?':
           if (isprint (optopt))
             fprintf (stderr, "Unknown option `-%c'.\n", optopt);
           else
             fprintf (stderr,
                 "Unknown option character `\\x%x'.\n",
                 optopt);
         
         case 'h':

         default:
           usage();
           exit(1);
      }
   }
}

void dec2bin(uint32_t v){

   char bin[33];
   bzero(bin,33);
   
   for(int i=1; i<=32; i++) {
      sprintf(bin+i-1,"%d",((v>>(32-i))&1));
   }

   printf("%x: %s\n",v,bin);
}

void ip_nf2_to_str(uint32_t ip, char *buf) {
   bzero(buf,INET_ADDRSTRLEN);
   sprintf(buf,"%d.%d.%d.%d",(ip>>24)&0xff,(ip>>16)&0xff,(ip>>8)&0xff,ip&0xff);
}

int main(int argc, char **argv) {

   nf2.device_name = DEFAULT_IFACE;

   FILE *arq;

   // Open the interface if possible
   if (check_iface(&nf2))
      exit(1);

   if (openDescriptor(&nf2))
      exit(1);

   processArgs(argc, argv);

   uint32_t val1,val2;
   uint32_t addr1, addr2, addr3, addr4, portas, med;
   float medicao;
   char ip_src_bf[INET_ADDRSTRLEN], ip_dst_bf[INET_ADDRSTRLEN];

   if(nome_arq == NULL) {
      printf("Defina o nome do arquivo de saida\n");
      exit(EXIT_FAILURE);
   } else {
      arq = fopen(nome_arq, "a");
      if(arq == NULL) {
         printf("Arquivo nao existe\n");
         exit(EXIT_FAILURE);
      }
   }

   for(int i=0; i < limite; i+=4) {

      val1 = val2 = med = 0; 

      addr1 = SRAM_BASE_ADDR + (offset<<3) + (i<<2);
      addr2 = SRAM_BASE_ADDR + (offset<<3) + ((i+1)<<2);
      addr3 = SRAM_BASE_ADDR + (offset<<3) + ((i+2)<<2);
      addr4 = SRAM_BASE_ADDR + (offset<<3) + ((i+3)<<2);

      readReg(&nf2,addr1,(uint32_t*)&val1);
      readReg(&nf2,addr2,(uint32_t*)&val2);
      readReg(&nf2,addr3,(uint32_t*)&med);
      readReg(&nf2,addr4,(uint32_t*)&portas);

      ip_nf2_to_str(val1,ip_src_bf);
      ip_nf2_to_str(val2,ip_dst_bf);
      
      //fprintf(arq,"addr: %d ", offset+(i<<2));
      medicao = (((int)(med&0xff))*23+((med>>16)&0xffff)*0.008);
      //fprintf(arq,"Medicao %s %d %s %d %f\n",ip_src_bf,(portas>>16)&0xffff,
      //      ip_dst_bf,portas&0xffff,medicao);
      fprintf(arq,"%15s %05d %15s %05d %10d %10d %10d\n",ip_src_bf,(portas>>16)&0xffff,
            ip_dst_bf,portas&0xffff,(int)(med&0xff),(med>>16)&0xffff,1);
      // 0.000000008 us = 0.000008ms *1000 granularidade = 0.008
   }

   closeDescriptor(&nf2);

   fclose(arq);

   return 0;
}
