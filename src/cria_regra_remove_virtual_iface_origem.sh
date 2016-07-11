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
ARQ_SAIDA="$DIRPADRAO/regras/regras_remove_virtual_iface_origem";

if [ -f $ARQ_SAIDA ]; then rm $ARQ_SAIDA; fi

LINHA=0
while read line
do
   ARR=($line)
   
   # se comentario ou linha vazia, pula
   if [[ ${ARR[0]} == '#' || ${ARR[0]} == '' ]]; then 
      continue; 
   fi
  
   # derruba interfaces virtuais 
   echo "ifconfig $IFACE:$LINHA down" >> $ARQ_SAIDA;

   LINHA=$(($LINHA+1))

done < $ARQUIVO_FLUXOS
