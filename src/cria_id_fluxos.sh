#!/bin/bash

DIRPADRAO='/root/experimentos';
ARQ_FLUXOS=$DIRPADRAO/regras/regras_fluxo_lat;
ARQ_SUFIX_MIN_MAX=$DIRPADRAO/defines/SUFIXO_IP_MIN_MAX;
ARQ_IFACE=$DIRPADRAO/regras/regras_interfaces;

NUM_FLUXOS=28;

while getopts "hn:" opt; do
   case $opt in
      n) NUM_FLUXOS=$OPTARG ;; 
      h) echo "-n numero fluxos" && \
         echo "-h ajuda" && exit;;
      \?) echo "Invalid option: -$OPTARG" && exit ;;
   esac
done

if [ -f $ARQ_FLUXOS ]; then rm -f $ARQ_FLUXOS; fi

NUM_IFBS=4; # fixo para obedecer limite alguns SOs
declare -a ARRAY_LAT_IFBS;
for i in `seq 0 $(( $NUM_IFBS-1 ))`
do
   ARRAY_LAT_IFBS[$i]=$(( RANDOM%320 ));
#   echo ${ARRAY_LAT_IFBS[$i]}
done

declare -a PREFIXOS;
if [ -f $ARQ_IFACE ]; then \
   rm $ARQ_IFACE; fi

for j in `seq 0 $(( $NUM_IFBS-1 ))`
do
   PREFIXOS[$j]=`printf "192.168.%d." $(( (RANDOM % 244) + 10))`;
   printf "%s%d %s%d %04d %04d %03d\n"  \
      ${PREFIXOS[$j]} 1 ${PREFIXOS[$j]} 2 0 0 \
      ${ARRAY_LAT_IFBS[$j]} >> TEMP1;
done   

# formata arquivo de saida
column -t TEMP1 > $ARQ_IFACE;
rm TEMP1;

PORTA_SUP=5000;
PORTA_INF=1024;

#10.0.1.1 10.0.1.2 unused  unused atraso ifbX 
declare -a ip_sufixo=(`cat $ARQ_SUFIX_MIN_MAX`);

for i in `seq 1 $NUM_FLUXOS`
do
   idx=$((RANDOM%${NUM_IFBS}));
   printf "%s%d\t%s%d\t%d\t%d\t%03d\tifb%d\n" \
      ${PREFIXOS[$idx]} $(( RANDOM % (${ip_sufixo[1]}-${ip_sufixo[0]}) + ${ip_sufixo[0]} )) \
      ${PREFIXOS[$idx]} $(( RANDOM % (${ip_sufixo[1]}-${ip_sufixo[0]}) + ${ip_sufixo[0]} )) \
      $(( RANDOM%$(($PORTA_SUP-$PORTA_INF))+$PORTA_INF )) \
      $(( RANDOM%$(($PORTA_SUP-$PORTA_INF))+$PORTA_INF )) \
      ${ARRAY_LAT_IFBS[$(($idx))]}  $(($idx)) >> TEMP2;
done

# formata arquivo de saida
column -t TEMP2 > $ARQ_FLUXOS;
rm TEMP2;
