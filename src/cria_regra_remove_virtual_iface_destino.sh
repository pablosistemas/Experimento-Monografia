#!/bin/bash

# Presume iface do enp3s1. Mude caso contrario
IFACE='enp3s1'

ARQUIVO_FLUXOS='';

while getopts "i:f:h" opt; do
   case $opt in
      f) ARQUIVO_FLUXOS=$OPTARG ;; 
      i) IFACE=$OPTARG ;; 
      h) echo "-i para nome da iface" && \
         echo "-f nome do arquivo de interfaces" && \
         echo "-h ajuda" && exit;;
      \?) echo "Invalid option: -$OPTARG" && exit ;;
   esac
done

DIRPADRAO='/root/experimentos';
ARQ_SAIDA="$DIRPADRAO/regras/regras_remove_virtual_iface_destino";
if [ -f $ARQ_SAIDA ]; then rm $ARQ_SAIDA; fi

# remove ingress handle da interface
echo "tc qdisc del dev $IFACE ingress" >>\
   $ARQ_SAIDA;

# remove intermediate funtional blocks (ifb)
echo "modprobe -r ifb" >> $ARQ_SAIDA;

# MODIFICADO AKI IPROUTE2
echo "ip addr flush dev $IFACE" >> $ARQ_SAIDA;

exit 0;

LINHA=0;
OFFSET=0;

while read line
do
   ARR=($line)
   
   # se comentario ou linha vazia, pula
   if [[ ${ARR[0]} == '#' || ${ARR[0]} == '' ]]; then 
      continue; 
   fi

   # cria ifaces para tratar todos os ips no range 10 até 254
   for i in `seq 10 254`
   do
      echo "ifconfig $IFACE:$(($OFFSET)) down" >> $ARQ_SAIDA;

      OFFSET=$(($OFFSET+1));
   done

   # desliga a iface
   # echo "ip link set dev ifb$LINHA down" >> $ARQ_SAIDA;

   LINHA=$(($LINHA+1))

done < $ARQUIVO_FLUXOS
