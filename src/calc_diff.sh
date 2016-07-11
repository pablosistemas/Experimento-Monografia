#/bin/bash
# recebe os arquivos para comparacao em ARGV

COLUNA=1;
while getopts "c:h" OPCAO; do
   case "${OPCAO}" in
   c) COLUNA=${OPTARG} ;;
   h) echo "c - coluna" && \
      echo "h - ajuda" && exit 0 ;;
   esac
done

NUM_LINES1=`cat $1 | wc -l`;
NUM_LINES2=`cat $2 | wc -l`;

if [ $NUM_LINES1 -lt $NUM_LINES2 ]; then
   NUM_LINES=$NUM_LINES1;
else
   NUM_LINES=$NUM_LINES2;
fi

while read a <&3 && read b <& 4; do
   printf "%0.4f\n" $(( `echo $a | awk '{print $6}'`-`echo $b | awk '{print $6}'`));
done 3< $1 4< $2
