#!/bin/bash

while getopts "f:ho:" opt; do
   case $opt in
      f) ARQ_ENTRADA=$OPTARG ;;
      o) IMG_SAIDA=$OPTARG ;;
      h) echo "-f entrada" && \
         echo "-o nome imagem saida" && \
         echo "-h ajuda" && exit;;
      \?) echo "Opcao invalida: -$OPTARG" && exit ;;
   esac
done


R_ARG="tab <- read.table('$ARQ_ENTRADA',col.names='diferenca');"
R_ARG="$R_ARG jpeg('$IMG_SAIDA.jpg'); plot(ecdf(tab\$diferenca),"
R_ARG="$R_ARG (1:length(tab))/length(tab), "
R_ARG="$R_ARG xlab='Diferença das latências medidas em sw e hw (ms)', "
R_ARG="$R_ARG ylab='Percentual', main='CDF da diferença entre SW e HW'); dev.off();"

echo "$R_ARG" | R --no-save
