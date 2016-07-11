#!/usr/bin/perl

use Getopt::Std;

my %opts;

getopts('f:ht:',\%opts);

sub TEMPO_BUCKET {
   return 23; #ms
}

if (defined $opts{h}) {
   die "-f nome arquivo de entrada\n-t 1 (prefixo), 2 (IP), 3 (fluxo)\n-h ajuda\n"
}

if (!defined $opts{f}) {
   die "Passe o nome do arquivo de entrada com -f\n";
}

my $tipo = 1;

if (defined $opts{t}) {
   $tipo = $opts{t};
}

die "Valor invalido para tipo\n" if ($tipo < 1 || $tipo > 3);

open (my $fh, '<', $opts{f}) 
   or die "cannot open < input file: $!";

my %medicoes;
my %num_medicoes;
my %med_buckets;

my %medicoes_ip_src;
my %num_medicoes_ip_src;
my %med_buckets_ip_src;

my %medicoes_pref_ip_src;
my %num_medicoes_pref_ip_src;
my %med_buckets_pref_ip_src;

while(<$fh>) {
   my ($ipsrc,$psrc,$ipdst,$pdst,$latbu,$latmi) = unpack("A15x1A5x1A15x1A5x1A10x1A10",$_);
   my (@pref) = split(/\./,$ipsrc);

   $index = sprintf("%15s %5s %15s %5s",$ipsrc,$psrc,$ipdst,$pdst);

   my $pref = $pref[0].".".$pref[1].".".$pref[2];

   #print $ipsrc,":",$psrc,":",$ipdst,":",$pdst,"\n";

   my $latencia = ($latbu*TEMPO_BUCKET())-TEMPO_BUCKET()/2+$latmi*8*10**-3;#*1000*8*10**-9*1000;
   #print "latencia: ",$latencia,"\n";
   
   #$index = $ipsrc.$psrc.$ipdst.$pdst;
   #$index = sprintf ("%14s%4s%14s%4s",$ipsrc,$psrc,$ipdst,$pdst);
   #print "indice: ", $index,"\n";

   if (! defined $num_medicoes{$index}) {
      $num_medicoes{$index} = 1;
      $medicoes{$index} = $latencia;
      $med_buckets{$index} = $latbu;
   } else {
      $num_medicoes{$index}++;
      $medicoes{$index} += $latencia;
      $med_buckets{$index} += $latbu;
   }

   if (! defined $num_medicoes_ip_src{$ipsrc}) {
      $num_medicoes_ip_src{$ipsrc} = 1;
      $medicoes_ip_src{$ipsrc} = $latencia;
      $med_buckets_ip_src{$ipsrc} = $latbu;
   } else {
      $num_medicoes_ip_src{$ipsrc}++;
      $medicoes_ip_src{$ipsrc} += $latencia;
      $med_buckets_ip_src{$ipsrc} += $latbu;
   }

   if (! defined $num_medicoes_pref_ip_src{$pref}) {
      $num_medicoes_pref_ip_src{$pref} = 1;
      $medicoes_pref_ip_src{$pref} = $latencia;
      $med_buckets_pref_ip_src{$pref} = $latbu;
   } else {
      $num_medicoes_pref_ip_src{$pref}++;
      $medicoes_pref_ip_src{$pref} += $latencia;
      $med_buckets_pref_ip_src{$pref} += $latbu;
   }
}

close ($fh);

# subtrai metade do tempo do bucket pois espera-se que o tempo de 
# chegada medio dos pacotes de dados seja na metade do tempo do 
# bucket

if ($tipo == 2) {
   my @key = keys (%medicoes_ip_src);
   foreach (@key) {
      my $ip = $_;
      printf "IP: %15s\tlatencia media: %.5f\n",$ip,
         ($medicoes_ip_src{$ip}/$num_medicoes_ip_src{$ip}); #-TEMPO_BUCKET()/2);
   }
} elsif ($tipo == 3) {
   my @key = keys (%medicoes);
   foreach (@key) {
      #my ($srcip,$srcp,$dstip,$dstp) = unpack ("A14A4A14A4",$_);
      my ($srcip,$srcp,$dstip,$dstp) = unpack ("A15x1A5x1A15x1A5",$_);
# testa se é primeiro endereco da rede
# FLUXO INVERSO NAO ENTRA NO MONITORAMENTO (SEM CONTROLE)
      my (@octs) = split(/\./,$srcip);
      #print @octs,"\n";
      if ($octs[3] != 1) {
         my $string = sprintf ("%15s %5s %15s %5s",$srcip,$srcp,$dstip,$dstp);  
         #print $string, "\n";
         printf "%s %10.6f %10.6f\n", $string, $med_buckets{$_}/$num_medicoes{$_},
           ($medicoes{$_}/$num_medicoes{$_}); #-TEMPO_BUCKET()/2);
      }
   }
} else {
   my @key = keys (%medicoes_pref_ip_src);
   foreach (@key) {
      my $ip = $_;
      printf "IP: %15s\tlatencia media: %.5f\n",$ip,
         ($medicoes_pref_ip_src{$ip}/$num_medicoes_pref_ip_src{$ip});#-TEMPO_BUCKET()/2);
   }
}
