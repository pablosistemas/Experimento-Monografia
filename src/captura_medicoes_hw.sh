#!/bin/bash

DIRBASE="/root/experimentos";

INICIO_ADDR_SRAM=1024;

while getopts "ho:" opt; do
   case $opt in
      o) INICIO_ADDR_SRAM=$OPTARG ;;
      h) echo "-o endereco inicial" && \
         echo "-h ajuda" && exit;;
      \?) echo "Opcao invalida: -$OPTARG" && exit ;;
   esac
done

PROX_ADDR=$INICIO_ADDR_SRAM;
DIR="$DIRBASE/src/sw/";
ARQ_SAIDA="$DIRBASE/medicoesHW/medicao_hw";

# le as medicoes dessa rodada
# counterdump deve abrir arq para concatenacao

# remove arquivo antigo
if [ -f $ARQ_SAIDA ]; then rm $ARQ_SAIDA; fi

while true
do
   #COUNTER=0;
# evita que o programa rode lendo linhas antigas
   ULTIMO_ADDR_SRAM=`${DIR}/le_prox 2> /dev/null`;
   while [ $ULTIMO_ADDR_SRAM -eq $PROX_ADDR ]
   do
      #echo "waiting start!";   
      #if [ $COUNTER -eq 10 ]; then exit 0; fi
      #COUNTER=$(( $COUNTER+1 ));   
      ULTIMO_ADDR_SRAM=`${DIR}/le_prox 2> /dev/null`;
   done

   #usleep 50000; # 50ms

   if [ $ULTIMO_ADDR_SRAM -le $PROX_ADDR ]; then
      
      NUM_ADDR_TO_READ=$(( 2**19 - 1 - $PROX_ADDR ));

      $DIR/le_mem -o $PROX_ADDR -l $NUM_ADDR_TO_READ -f $ARQ_SAIDA 2> /dev/null 

      NUM_ADDR_TO_READ=$(( $ULTIMO_ADDR_SRAM - $INICIO_ADDR_SRAM ));

      $DIR/le_mem -o $INICIO_ADDR_SRAM -l $NUM_ADDR_TO_READ -f $ARQ_SAIDA 2> /dev/null  

      printf "lendo1 %d até %d e %d até %d\n" $PROX_ADDR $((2**19-1)) $INICIO_ADDR_SRAM $ULTIMO_ADDR_SRAM;

   else
      $DIR/le_mem -o $PROX_ADDR -l $(( $ULTIMO_ADDR_SRAM - $PROX_ADDR)) -f $ARQ_SAIDA 2> /dev/null  
      printf "lendo2 %d até %d\n" $PROX_ADDR $ULTIMO_ADDR_SRAM;
   fi

   PROX_ADDR=$ULTIMO_ADDR_SRAM;

done
