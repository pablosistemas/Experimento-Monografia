#!/bin/bash

IP="192.168.0.0";
while getopts "a:h" opt; do
   case $opt in
   a) IP=$OPTARG ;;
   h) echo "-a IP" && \
      echo "-h ajuda" && exit ;;
   \?) echo "Opcao Invalida: -$OPTARG" && exit ;;
   esac
done

function capturaPrefixo() {
   IFS=".";
   set -- $1;
   echo "$1.$2.$3";
}

PREFIX=$(capturaPrefixo $IP);
echo $PREFIX;
