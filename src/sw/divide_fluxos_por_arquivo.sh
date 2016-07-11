#!/bin/bash

FILE="";
while getopts "f:h" opt; do
   case $opt in
      f) FILE=$OPTARG ;;
      h) echo "-f nome arquivo" && \
         echo "-h ajuda" && exit;;
      \?) echo "Opcao invalida: -$OPTARG" && exit ;;
   esac
done

DIRPADRAO="/root/experimentos";
DIR=${DIRPADRAO}/resultados/latencia;

# se existir alguma pasta com mesmo nome, limpa
if [ -d $DIR ]; then rm -rf $DIR ; fi

mkdir -p $DIR;
   
while read line
do
   ARR=($line)
   
   # se comentario ou linha vazia, pula
   if [[ ${ARR[0]} == '#' || ${ARR[0]} == '' ]]; then 
      continue; 
   fi

   PREFIX=$(sh $DIRPADRAO/src/capturaPrefixo.sh -a ${ARR[0]});
   
# coluna latencia: tipo em calc_lat.pl deve ser 3 para gerar formato adequado
# de entrada
   echo ${ARR[5]} >> "$DIR/$PREFIX";

done < $FILE
