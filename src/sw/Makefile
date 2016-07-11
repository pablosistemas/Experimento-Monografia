#
# $Id: Makefile 6042 2010-04-01 05:59:23Z grg $
#

CFLAGS = -g
CC = gcc
LDFLAGS = -lncurses

all : le_mem le_prox

registers:
	$(NF_ROOT)/bin/nf_register_gen.pl --project novo_reference_nic

clean :
	rm -f le_mem

le_mem : le_memoria.c
	gcc le_memoria.c -Wall -o le_mem /root/netfpga/lib/C/common/libnf2.so -std=gnu99

le_prox : le_prox_addr.c
	gcc le_prox_addr.c -o le_prox /root/netfpga/lib/C/common/libnf2.so -std=gnu99

install:

.PHONY: all clean install
