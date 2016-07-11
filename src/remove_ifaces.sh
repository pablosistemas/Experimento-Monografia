#!/bin/bash

ARQUIVO_FLUXOS='';
IP_TERMINAL_DST='';
PCAP_SAIDA='meupcap.pcap';
DIRPADRAO='/root/experimentos';


# mude as interfaces de acordo com o ambiente
IFACESRC='nf2c0'
IFACEDST='enp3s1'
IP_TERMINAL_DST='200.131.239.34' # netfpga-server Racyus

while getopts "d:g:hi:j:" opt; do
   case $opt in
      d) IP_TERMINAL_DST=$OPTARG ;; 
      g) ARQUIVO_IFACES=$OPTARG ;; 
      i) IFACESRC=$OPTARG ;; 
      j) IFACEDST=$OPTARG ;; 
      h)    echo "-d ip do destino" && \
            echo "-g arquivo ifaces" && \
            echo "-i iface origem" && \
            echo "-j iface destino" && \
            echo "-h ajuda" && exit ;;
      \?) echo "Invalid option: -$OPTARG" >&2 ;;
   esac
done

########### remove virtual ifaces no destino ###########
echo 'removendo as ifaces virtuais origem'
sh $DIRPADRAO/src/cria_regra_remove_virtual_iface_origem.sh -i $IFACESRC -f $ARQUIVO_IFACES
source $DIRPADRAO/regras/regras_remove_virtual_iface_origem

echo 'removendo as ifaces virtuais destino'
sh $DIRPADRAO/src/cria_regra_remove_virtual_iface_destino.sh -i $IFACEDST -f $ARQUIVO_IFACES

# testes locais nao precisam de sshpass
scp $DIRPADRAO/regras/regras_remove_virtual_iface_destino \
   root@$IP_TERMINAL_DST:/root/
ssh root@$IP_TERMINAL_DST 'source /root/regras_remove_virtual_iface_destino && rm /root/regras_remove_virtual_iface_destino'
