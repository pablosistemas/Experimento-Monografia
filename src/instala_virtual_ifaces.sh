#!/bin/bash

DIRPADRAO='/root/experimentos';

ARQUIVO_FLUXOS='';
IP_TERMINAL_DST='';
PCAP_SAIDA='meupcap.pcap';

# mude as interfaces de acordo com o ambiente
IFACESRC='nf2c0';
IFACEDST='nf2c0';
IP_TERMINAL_DST='200.131.239.34' # netfpga-server Racyus

while getopts "d:g:hi:j:" opt; do
   case $opt in
      d) IP_TERMINAL_DST=$OPTARG ;; 
      g) ARQUIVO_FLUXOS=$OPTARG ;; 
      i) IFACESRC=$OPTARG ;;   
      j) IFACEDST=$OPTARG ;;   
      h)    echo "-d ip do destino" && \
            echo "-g arquivo interfaces" && \
            echo "-i iface origem" && \
            echo "-j iface destino" && \
            echo "-h ajuda" && exit ;;
      \?) echo "Invalid option: -$OPTARG" >&2 ;;
   esac
done

########### cria virtual ifaces no destino ###########
echo 'preparando o ambiente origem'
sh $DIRPADRAO/src/cria_regra_virtual_iface_origem.sh -i $IFACESRC -g $ARQUIVO_FLUXOS

source $DIRPADRAO/regras/regras_virtual_iface_origem

echo 'preparando o ambiente destino'
sh $DIRPADRAO/src/cria_regra_virtual_iface_destino.sh -i $IFACEDST -g $ARQUIVO_FLUXOS

scp $DIRPADRAO/regras/regras_virtual_iface_destino root@$IP_TERMINAL_DST:/root
ssh root@$IP_TERMINAL_DST 'source /root/regras_virtual_iface_destino'

exit 0
