#!/bin/bash

DIRPADRAO='/root/experimentos';

# defina os enderecos MAC aki
MAC1='';
MAC2='';

# duracao default (em segundos)
DURACAO_EXP=10;

# numero do experimento
NUM_EXPERIMENTO=1;

# numero de pacotes por fluxo por segundo
NUM_PKTS_SEG=40;

# dados TERMINAL A
IP_PUB_A='150.164.10.56';
IFACE_A='nf2c0'

# dados TERMINAL B
IP_PUB_B='150.164.10.77';

PAYLOADLEN=40;

while getopts "hi:m:p:t:x:" opt; do
   case $opt in
      i) IFACE_A=$OPTARG ;;
      m) NUM_PKTS_SEG=$OPTARG ;; 
      p) PAYLOADLEN=$OPTARG ;; 
      t) DURACAO_EXP=$OPTARG ;; 
      x) NUM_EXPERIMENTO=$OPTARG ;;
      h) echo "-i iface origem" && \
         echo "-m numero pacotes por fluxo por segundo" && \
         echo "-p tamanho do payload em bytes" && \
         echo "-t duracao experimento (seg)" && \
         echo "-x numero do experimento" && \
         echo "-h ajuda" && exit;;
      \?) echo "Invalid option: -$OPTARG" && exit ;;
   esac
done

PCAP_SAIDA="$DIRPADRAO/pcaps/trafego_${NUM_EXPERIMENTO}.pcap";

screen -S tcpdumpse -d -m tcpdump -i $IFACE_A tcp \
   -w $PCAP_SAIDA && sleep 1

# dispara hping3 para cada um dos fluxos
sh $DIRPADRAO/src/enviaHping.sh -f $DIRPADRAO/regras/regras_fluxo_lat -g $DIRPADRAO/regras/regras_interfaces -n $NUM_PKTS_SEG -i $IFACE_A -t $DURACAO_EXP -p $PAYLOADLEN;

# inicializa arquivo com 0: ultimo addr lido eh addr inicial
echo "0" > $DIRPADRAO/defines/ARQ_ULTIMO_ADDR;

# endereco inicial de leitura na SRAM
INICIO_ADDR_SRAM=`cat $DIRPADRAO/defines/ARQ_ULTIMO_ADDR`;

# retorna o endereco apos o ultimo endereco gravado na SRAM
#ULTIMO_ADDR_SRAM=`/root/netfpga/projects/novo_reference_nic/sw/le_ultimo_end`

ARQ_MED_HW="$DIRPADRAO/medicoesHW/resultado${NUM_EXPERIMENTO}.txt";

sleep $DURACAO_EXP;

# finaliza TCPDUMP para gravar os pcaps
killall tcpdump
