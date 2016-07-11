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
   echo $N;
}

# Presume iface do enp3s1. Mude caso contrario
IFACE='enp3s1'
N=0;

while getopts "i:g:h" opt; do
   case $opt in
      g) ARQUIVO_IFACES=$OPTARG ;; 
      i) IFACE=$OPTARG ;; 
      h) echo "-i para nome da iface" && \
         echo "-g nome do arquivo de ifaces virtuais" && \
         echo "-h ajuda" && exit;;
      \?) echo "Invalid option: -$OPTARG" && exit ;;
   esac
done

DIRPADRAO='/root/experimentos';
ARQ_DEST="$DIRPADRAO/regras/regras_virtual_iface_destino";

if [ -f $ARQ_DEST ]; then rm -f $ARQ_DEST; fi

# conta numero de ifbs 
N=$(contaLinhas $ARQUIVO_IFACES);

echo "Criando interfaces"

# cria handle para 'incoming traffic'
echo "tc qdisc add dev $IFACE handle ffff: ingress" \
   >> $ARQ_DEST; 

# cria interfaces virtuais no terminal
echo "modprobe ifb numifbs=$N 2> /dev/null" \
   >>$ARQ_DEST; 

echo "" >> $ARQ_DEST; 

LINHA=0
OFFSET=0;
#formato: srcip dstip unused unused delay
while read line
do
   ARR=($line)
   # se comentario ou linha vazia, pula
   if [[ ${ARR[0]} == '#' || ${ARR[0]} == '' ]]; then 
      continue; 
   fi
   
   PREFIX=$(sh $DIRPADRAO/src/capturaPrefixo.sh -a ${ARR[0]}); 

   # cria ifaces para tratar todos os ips no range X e Y (seq X Y)
   for i in `seq 10 20`
   do
      echo "ip addr add ${PREFIX}.${i}/24 dev $IFACE" >> $ARQ_DEST;
      OFFSET=$(($OFFSET+1));
   done

   LINHA=$(($LINHA+1));

done < $ARQUIVO_IFACES

echo "" >> $ARQ_DEST;

LINHA=0
while read line
do
   ARR=($line);
   # se comentario ou linha vazia, pula
   if [[ ${ARR[0]} == '#' || ${ARR[0]} == '' ]]; then 
      continue; 
   fi

   # pega o IP
   IP1=${ARR[0]} 
   IP2=${ARR[1]} 

   SUFFIX="ms"

   # add atraso (em ms)    
   NETEMARG="${ARR[4]}$SUFFIX";

   # atrasos normalmente distribuidos, se houver variancia
   if [[ ${ARR[5]} ]]; then
      NETEMARG="$NETEMARG ${ARR[5]}$SUFFIX" ;
      NETEMARG="$NETEMARG distribution normal"
   fi
   
  echo "" >> $ARQ_DEST; 
   echo "ip link set dev ifb$LINHA up" \
      >> $ARQ_DEST;

   printf "tc filter add dev $IFACE protocol " >> $ARQ_DEST;
   printf "ip parent ffff: " >> $ARQ_DEST;
   printf "pref 1 u32 match ip dst " >> $ARQ_DEST;
   printf "$(sh $DIRPADRAO/src/capturaPrefixo.sh -a $IP2).0/24 " >> $ARQ_DEST;
   printf "action mirred " >> $ARQ_DEST;
   printf "egress redirect dev ifb$LINHA\n" >> $ARQ_DEST; 

   printf "tc qdisc add dev ifb$LINHA root netem ">> $ARQ_DEST;
   printf "delay $NETEMARG\n" >> $ARQ_DEST;

   # se houver erro (codigo 2) entao muda (ao inves de add) a regra - regra ja existia anteriormente
   printf "if [ \$? == 2 ]; then tc qdisc change ">> $ARQ_DEST;
   printf "dev ifb$LINHA root netem delay " >> $ARQ_DEST;
   printf "$NETEMARG; fi" >> $ARQ_DEST;

   echo "" >> $ARQ_DEST;

   LINHA=$(($LINHA+1));

done < $ARQUIVO_IFACES;

if [[ -f $ARQ_DEST ]]; then 
    echo "Arquivo de regras criado com sucesso";
else 
    echo "erro na criacao do arquivo"; fi
