#!/bin/bash

DIRPADRAO="/root/experimentos";
DIR="$DIRPADRAO/resultados/graficos";

while getopts "d:f:h" opt; do
   case $opt in
      d) DIR_LAT=$OPTARG ;;
      h) echo "-d diretorio das latencias (s)" && \
         echo "-h ajuda" && exit;;
      \?) echo "Opcao invalida: -$OPTARG" && exit ;;
   esac
done


if [ -d $DIR ]; then rm -rf $DIR; fi

mkdir $DIR   

for i in $DIR_LAT/*
do
   #echo $i;
   BNAME=`basename $i`;
   Rscript $DIRPADRAO/src/sw/geraGraficosEnviaPkt.R -f $i -g $BNAME -d $DIR \
      -l `cat $DIRPADRAO/regras/regras_interfaces | awk -v bname=$BNAME '$0 ~ bname {print $5}'`;

done
