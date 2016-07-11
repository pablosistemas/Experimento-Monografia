#!/bin/bash

declare -A dicio_latencias;
declare -A dicio_contador;

ARQ_ENT="medicoesHW/medicao_hw";

while getopts "f:h" opt; do
   case $opt in
      f) ARQ_ENT=$OPTARG ;;
      h) echo "-f arquivo entrada (s)" && \
         echo "-h ajuda" && exit;;
      \?) echo "Opcao invalida: -$OPTARG" && exit ;;
   esac
done

while read line
do
# formato do arquivo
# addrlabel addr Medicaolabel dstIP dstPort srcIP srcPort latencia
   LINHA=($line); 

# Formato indice: IPorigem.portaOrigem.IPdestino.portaDestino
   INDEX="${LINHA[5]}.${LINHA[6]}.${LINHA[3]}.${LINHA[4]}"
   # echo "$INDEX"

   if [ ! ${dicio_latencias[$INDEX]} ]; then
      dicio_latencias[$INDEX]=0;
      dicio_contador[$INDEX]=0;
   fi

   LATENCIA=${LINHA[7]};
   
   #echo "${dicio_contador[$INDEX]} ${dicio_latencias[$INDEX]}"

   dicio_latencias[$INDEX]=`printf "scale=4; %f+%f\n" ${dicio_latencias[$INDEX]} $LATENCIA | bc`; 
   dicio_contador[$INDEX]=$(( ${dicio_contador[$INDEX]} + 1 ));

done < $ARQ_ENT

# imprime na saida padrao as medicoes por fluxo
for i in "${!dicio_latencias[@]}"
do
   printf "%s: " $i 
   echo "scale=4; ${dicio_latencias[$i]}/${dicio_contador[$i]}" | bc;
done      
