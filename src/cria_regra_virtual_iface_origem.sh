#!/bin/bash

# achar comando mais eficiente p/ contar no linhas validas arquivo
# recebe nome do arq como parametro
function contaLinhas() {
   N=0
   while read line
   do
      ARR=($line)
      # se comentario ou linha vazia, pula
      if [[ ${ARR[0]} == '#' || ${ARR[0]} == '' ]]; then 
         continue; 
      fi
      N=$(($N+1));
   done < $1
   return $N;
}

# Presume iface do enp3s1. Mude caso contrario
IFACE='enp3s1'
ARQUIVO_FLUXOS='';
IS_DST=0;
N=0;

DIRPADRAO='/root/experimentos';

while getopts "i:g:ho:" opt; do
   case $opt in
      g) ARQUIVO_FLUXOS=$OPTARG ;; 
      i) IFACE=$OPTARG ;; 
      o) IS_DST=$OPTARG ;; 
      h) echo "-i para nome da iface" && \
         echo "-g nome do arquivo de interfaces" && \
         echo "-o usar colunas do IP de destino" && \
         echo "-h ajuda" && exit;;
      \?) echo "Invalid option: -$OPTARG" && exit ;;
   esac
done

ARQ_IFACES_ORG="$DIRPADRAO/regras/regras_virtual_iface_origem";

if [ -f $ARQ_IFACES_ORG ]; then rm -f $ARQ_IFACES_ORG; fi
# cria o arquivo com as linha
# Ex: source regras/regras_virtual_iface

# chama funcao 
contaLinhas $ARQUIVO_FLUXOS
# captura valor de retorno
N=$?

LINHA=0
while read line
do
   ARR=($line)
   # se comentario ou linha vazia, pula
   if [[ ${ARR[0]} == '#' || ${ARR[0]} == '' ]]; then 
      continue; 
   fi

   # pega o IP
   IP=${ARR[0]} 
   # retorna os 3 primeiros octetos do ip
   PREFIX=$(sh $DIRPADRAO/src/capturaPrefixo.sh -a $IP);

   # cria ifaces com mascara 255.255.0.0
   echo "ifconfig $IFACE:${LINHA} ${PREFIX}.1 netmask 255.255.0.0" >> $ARQ_IFACES_ORG

   LINHA=$(($LINHA+1));

done < $ARQUIVO_FLUXOS

if [[ -f $ARQ_IFACES_ORG ]]; then 
    echo "Arquivo de regras criado com sucesso";
else 
    echo "erro na criacao do arquivo"; fi
