#!/bin/bash

DIRPADRAO="/root/experimentos";
DIR="$DIRPADRAO/resultados/graficos";

ARQSAIDA="$DIRPADRAO/resultados/latencias";

while getopts "f:h" opt; do
   case $opt in
      f) ARQENT=$OPTARG ;;
      h) echo "-f arquivo entrada (s)" && \
         echo "-h ajuda" && exit;;
      \?) echo "Opcao invalida: -$OPTARG" && exit ;;
   esac
done


if [ -d $DIR ]; then rm -rf $DIR; fi

mkdir $DIR   

perl $DIRPADRAO/src/sw/calc_lat.pl -f $ARQENT -t 3 > $ARQSAIDA

sh $DIRPADRAO/src/sw/divide_fluxos_por_arquivo.sh -f $ARQSAIDA


COUNT=1;
for i in $DIRPADRAO/resultados/latencia/*
do
   Rscript geraGraficos.R -f $i -g $COUNT -d $DIR 
   COUNT=$(( $COUNT+1 ))
done
