#!/bin/bash

DIRPADRAO='/root/experimentos';
PAYLEN=40;
while getopts "d:f:g:i:n:p:ht:" opt; do
   case $opt in
      f) ARQUIVO_FLUXOS=$OPTARG ;; 
      g) ARQUIVO_IFACES=$OPTARG ;; 
      i) SRC_IFACE=$OPTARG ;; 
      n) NUM_PKTS_POR_FLUXO=$OPTARG ;;
      p) PAYLEN=$OPTARG ;;
      t) TEMPO_EXPERIMENTO=$OPTARG ;;
      h) echo "-f arquivo fluxos" && \
         echo "-g arquivo ifaces" && \
         echo "-i iface de origem" && \
         echo "-n nº pacotes por fluxos por segundo" && \
         echo "-p tamanho do payload em bytes" && \
         echo "-t tempo de experimento" && \
         echo "-h ajuda" && exit ;;
      \?) echo "Invalid option: -$OPTPKTS_POR_SEG" >&2 && exit ;;
   esac
done

TMP=$((10**6/$NUM_PKTS_POR_FLUXO))
PKTS_POR_SEG="u$TMP"

# declara o dicionario
declare -A prefix_2_iface;

COUNT=0;
# cria um dicionario de prefixo de IP para interface de saida
# do pacote
while read line
do
   # transforma em array	
   ARR=($line)
   
   # se comentario ou linha vazia, pula
   if [[ ${ARR[0]} == '#' || ${ARR[0]} == '' ]]; then 
      continue; 
   fi

   prefix_2_iface[$(sh $DIRPADRAO/src/capturaPrefixo.sh -a ${ARR[0]})]="${SRC_IFACE}:${COUNT}";

   COUNT=$(($COUNT+1));

done < $ARQUIVO_IFACES;

# teste
#for i in "${!prefix_2_iface[@]}"; do echo $i: ${prefix_2_iface[$i]}; done && exit 0;

while read line
do
# transforma em array	
   ARR=($line)
# se comentario ou linha vazia, pula
   if [[ ${ARR[0]} == '#' || ${ARR[0]} == '' ]]; then 
      continue; 
   fi
   
   IPSRC=${ARR[0]};
   IPDST=${ARR[1]}; 
   PORTASRC=${ARR[2]}; 
   PORTADST=${ARR[3]}; 

# envia pacotes de 40 bytes
# keep impede de incrementar porta origem 
hping3 --quiet -p $PORTADST --keep -s $PORTASRC -i $PKTS_POR_SEG \
   -c $(( $NUM_PKTS_POR_FLUXO*$TEMPO_EXPERIMENTO )) $IPDST \
   --data $PAYLEN -I ${prefix_2_iface[$(sh $DIRPADRAO/src/capturaPrefixo.sh -a $IPSRC)]} &
   #--keep --data 40 -I $SRC_IFACE &

done < $ARQUIVO_FLUXOS

wait
