#!/bin/bash

function testaPrimeiroEnderecoIP() {
   IFS=".";
   set -- $1;
   #if [ $4 -ne 1 ]; then echo "$1.$2.$3.$4"; fi
   if [ $4 -ne 1 ]
   then 
      return 0
   else
      return 1   
   fi
}

#for i in ${ARRAY[@]}
#do
#   echo $i
#done

#testaPrimeiroEnderecoIP $1

ARGV="";

if testaPrimeiroEnderecoIP $1; then 

   IFS="";
   for i in ${BASH_ARGV[*]}; do
      ARGV="$i $ARGV";
   done   
   #echo $ARGV;
   printf "%s\n" $ARGV;
fi
