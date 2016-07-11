#!/bin/bash

# configure ifaces como: 
# 192.168.0.X netmask 255.255.255.0

NUM_EXP=1;
NUM_FLUXOS=20;

IP_PUB_A='192.168.1.2';
IP_PUB_B='192.168.1.3';

IFACE_A='nf2c0';
#'nf2c0';
IFACE_B='eth1';
#'nf2c0';

INTERVALO=1000; #us
DURACAO=10; #s
PKTS_P_SEG=100;

ARQ_FLUXOS=`pwd`/regras/regras_fluxo_lat;
ARQ_IFACES=`pwd`/regras/regras_interfaces;

while getopts "d:hi:m:n:" opt; do
   case $opt in
      d) DURACAO=$OPTARG ;;
      m) NUM_FLUXOS=$OPTARG ;;
      n) NUM_EXP=$OPTARG ;;
      i) INTERVALO=$OPTARG ;;
      h) echo "-d duracao (s)" && \
         echo "-i intervalo (us)" && \
         echo "-m numero de fluxos" && \
         echo "-n numero experimento" && \
         echo "-h ajuda" && exit;;
      \?) echo "Opcao invalida: -$OPTARG" && exit ;;
   esac
done

function removeIfaces() {

   sh cria_regra_remove_virtual_iface_origem.sh -i $IFACE_A \
      -f $ARQ_IFACES
   
   #source `pwd`/regras/regras_remove_virtual_iface_origem

   sh cria_regra_remove_virtual_iface_destino.sh -i $IFACE_B \
      -f $ARQ_IFACES

# testes locais nao precisam de sshpass
   #scp `pwd`/regras/regras_remove_virtual_iface_destino \
   #   root@$IP_PUB_B:/root/

   #ssh root@$IP_PUB_B 'source /root/regras_remove_virtual_iface_destino && rm /root/regras_remove_virtual_iface_destino'

}


# a cada rodada, cria todas as regras do zero para evitar confusao
if [ ! -d regras ]; then 
   rm -rf regras 
   mkdir regras 
fi

# se pasta de arq .pcap nao existe, cria
if [ ! -d pcaps ]; then mkdir pcaps; fi
   
# se pasta de medicoesSW nao existe, cria
if [ ! -d medicoesSW ]; then mkdir medicoesSW; fi

# se pasta de medicoesHW nao existe, cria
if [ ! -d medicoesHW ]; then mkdir medicoesHW; fi

# se pasta de resultados nao existe, cria
if [ ! -d resultados ]; then mkdir resultados; fi

# cria arquivo com os fluxos
echo "criando arquivo de ID de fluxos"

sh cria_id_fluxos.sh -n $NUM_FLUXOS #-f $ARQ_FLUXOS

# reseta nf2
#cpci_reprogram.pl
# descarrega os bitfiles
#nf_download /root/netfpga/bitfiles/novo_reference_nic05_05.bit
#ssh root@$IP_PUB_B 'cpci_reprogram.pl && nf_download /root/netfpga/bitfiles/reference_nic.bit'

nf_download bitfiles/novo_reference_nic.18_05_18bitssram.bit

# instala as regras nos dois terminais
sh instala_virtual_ifaces.sh -d $IP_PUB_B -i $IFACE_A -j \
   $IFACE_B -g $ARQ_IFACES

sh captura_medicoes_hw.sh -o `sw/le_prox` &

sh enviaPacotes.sh -i $IFACE_A -m $PKTS_P_SEG -t $DURACAO -x 1

# mata o processo
ps aux | grep captura_medicoes_hw | awk '{print $2}' | xargs kill

# formata o arquivo de saida com as medicoes HW
cat medicoesHW/medicao_hw | column -t > temp;
mv temp medicoesHW/medicao_hw;

sh remove_ifaces.sh -d $IP_PUB_B -i $IFACE_A -j $IFACE_B -g $ARQ_IFACES

exit 0;

# ou
#removeIfaces;

# provavelmente so funcionara no meu note devido as libs do perl

# executa o bloom filter SW e grava as medicoes em medicoesSW

# pasta para arquivos temporarios que podem ser uteis
if [ -d tempFiles ]; then
   rm -r tempFiles;
   mkdir tempFiles;
fi

COUNT=1;
for i in pcaps/*
do
   arqDst=MedicoesSW/medicao_${COUNT}_sw;
   if [ -f $arqDst ]; then
      rm $arqDst;
   fi  

   perl bloom_filter_sw/bloom_filter_sw.pl -p $i > tempFiles/temp${COUNT};

# imprime: srcip, dstip, srcp, dstp, medicao
   grep Medicao tempFiles/temp${COUNT} | awk '{print $2,$3,$4,$5,$6}' > $arqDst;

   COUNT=$(( COUNT+1 ));
done 

NUM_MED_SW = `ls MedicoesSW | wc -l`;
NUM_MED_HW = `ls MedicoesHW | wc -l`;

if [ $NUM_MED_SW -lt $NUM_MED_HW ]; then
   NUM_MED = $NUM_MED_SW;
else
   NUM_MED = $NUM_MED_HW;
fi

# calcula a diferença das medicoes em hw e sw
if [ ! -d CDF ]; then
   mkdir CDF;
fi

for i in `seq 1 $NUM_MED`
do
   sh calcDiff.sh MedicoesSW/medicao_${COUNT}_sw MedicoesHW/medicao_${COUNT}_hw > CDF/cdf_${i};

done
