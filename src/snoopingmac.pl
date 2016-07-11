#!/usr/bin/perl -w

use strict;
use Net::Pcap;
use NetPacket::Ethernet qw( :types :strip );
use NetPacket::IP qw( :protos :strip :versions );
use NetPacket::UDP qw( :strip );
use NetPacket::ICMP qw( :strip :types );
use Getopt::Std;
use Socket qw( inet_aton );
use sigtrap qw(handler my_handler USR1);

# global variables
our %bloom_hash      = ();
our %bloom_clock     = ();
our %bloom_counter   = ();
our $num_clks_per_bu = 2875000;
our $pcap;
our $pcap_por_pkt;

# cada medicao corresponde à 128 bits
# Esse valor DEVE ser mudado quando o tamanho do ETH FRAME mudar
our $NUM_BLOOM_IN_PACKET = 25; #50;

sub str2flowID {
   my $str = shift;

   my $src_oct_1 = hex(substr($str,0,2));
   my $src_oct_2 = hex(substr($str,2,2));
   my $src_oct_3 = hex(substr($str,4,2));
   my $src_oct_4 = hex(substr($str,6,2));

   my $dst_oct_1 = hex(substr($str,8,2));
   my $dst_oct_2 = hex(substr($str,10,2));
   my $dst_oct_3 = hex(substr($str,12,2));
   my $dst_oct_4 = hex(substr($str,14,2));

   my $port1 = hex(substr($str,16,4));
   my $port2 = hex(substr($str,20,4));
   
   return { 
      ipsrc => sprintf("%0d.%0d.%0d.%0d",$src_oct_1,$src_oct_2,$src_oct_3,$src_oct_4),
      ipdst => sprintf("%0d.%0d.%0d.%0d",$dst_oct_1,$dst_oct_2,$dst_oct_3,$dst_oct_4),
      psrc => $port1, pdst => $port2 }
}

# on signal, closes pcap and leave
sub my_handler {
   my $signal = shift;
   
# fecha o packet capturer handler e o arquivo de medicoes por fluxo
   Net::Pcap::pcap_close($pcap);
   close ($pcap_por_pkt);

   my $key;
   my @keys = keys %bloom_hash;
   
   open my $file, '>', "/root/experimentos/medicoesHW/resultadoParcial";

   foreach $key (@keys) {
      my $return = str2flowID($key);
      # srcip srcport dstip dstport mediaBuckets mediaMiliS numPktsMedidoa
      # 15 5 15 5 10 10 10
      printf $file "%15s %05d %15s %05d %10.6f %10.6f %10d\n", 
            $return->{ipsrc}, $return->{psrc}, $return->{ipdst}, $return->{pdst},
            $bloom_hash{$key}/$bloom_counter{$key},
            $bloom_clock{$key}*8e-9*1e3/$bloom_counter{$key},$bloom_counter{$key};
   }
   close $file;
   exit 0;
}

# defina aki o valor do campo ethertype do pacote
sub ETH_TYPE_PABLO() {
   return 255;
}

sub eth_debug {
   my $payload = shift;

   my $bloom_key;
   my ($src_oct_1,$src_oct_2,$src_oct_3,$src_oct_4);
   my ($dst_oct_1,$dst_oct_2,$dst_oct_3,$dst_oct_4);
   my ($port1,$port2);
   my $offset;
   my $data_length = 16; # bytes
   my $measurement;
   my $milicount;
   my ($src_ip,$dst_ip);

   for(my $i=0; $i < $NUM_BLOOM_IN_PACKET; $i++){
      $offset = 2 + $data_length * ($i);
      # bloom_key = {srcip, dstip, srcp, dstp}}
      $bloom_key = unpack("H24",substr($payload,$offset,12));

      $src_oct_1 = hex(unpack("H2",substr($payload,$offset,1)));
      $src_oct_2 = hex(unpack("H2",substr($payload,$offset+1,1)));
      $src_oct_3 = hex(unpack("H2",substr($payload,$offset+2,1)));
      $src_oct_4 = hex(unpack("H2",substr($payload,$offset+3,1)));

      $dst_oct_1 = hex(unpack("H2",substr($payload,$offset+4,1)));
      $dst_oct_2 = hex(unpack("H2",substr($payload,$offset+5,1)));
      $dst_oct_3 = hex(unpack("H2",substr($payload,$offset+6,1)));
      $dst_oct_4 = hex(unpack("H2",substr($payload,$offset+7,1)));

      $port1 = unpack("n",substr($payload,$offset+8,2));
      $port2 = unpack("n",substr($payload,$offset+10,2));

      $milicount     = unpack("H4",substr($payload,$offset+12,2));
      $measurement   = unpack("H2",substr($payload,$offset+15,1));

      $src_ip = sprintf("%0d.%0d.%0d.%0d",$src_oct_1,$src_oct_2,$src_oct_3,$src_oct_4);
      
      $dst_ip = sprintf("%0d.%0d.%0d.%0d",$dst_oct_1,$dst_oct_2,$dst_oct_3,$dst_oct_4);

      # printf "%s:%d -> %s:%d ... $measurement $milicount\n",$src_ip,$port1,$dst_ip,$port2;

      my $latencia = ($num_clks_per_bu*hex($measurement)+hex($milicount)*1000-$num_clks_per_bu/2)*8e-9*1e3;
      printf $pcap_por_pkt "%15s %05d %15s %05d %10.6f %10.6f %10d\n", $src_ip,$port1,
         $dst_ip,$port2,hex($measurement),$latencia,1;

      if(hex($measurement) != 0xff && hex($measurement) != 0x0f){
         # grava medicao em buckets (0 - 14)
         if(defined ($bloom_hash{$bloom_key})) {
            $bloom_hash{$bloom_key} += hex($measurement);   
         } else {
            $bloom_hash{$bloom_key} = hex($measurement);   
         }
         # conta numero de medicoes
         if(defined ($bloom_counter{$bloom_key})) {
            $bloom_counter{$bloom_key} += 1;   
         } else {
            $bloom_counter{$bloom_key} = 1;
         }
         # grava medicao em ms (buckets e contador de milhares - metade bucket)
         if(defined ($bloom_clock{$bloom_key})) {
            $bloom_clock{$bloom_key} +=
            ($num_clks_per_bu*hex($measurement)+hex($milicount)*1000-$num_clks_per_bu/2);  
         } else {
            $bloom_clock{$bloom_key} = 
            ($num_clks_per_bu*hex($measurement)+hex($milicount)*1000-$num_clks_per_bu/2);
         }
      }
      else {
         printf "Erro em medição: %s\n",$measurement;
      }
   }
}

sub icmp_debug {
   my $icmp_packet = shift;
   my $icmp_dgram = NetPacket::ICMP->decode($icmp_packet);
   print "Type: ",$icmp_dgram->{type},", Code: ",$icmp_dgram->{code},", ";
   print "Chksum: ",$icmp_dgram->{cksum},"\n";
}

sub ip_debug {
   my $ip_packet = shift;
   my $ip_dgram = NetPacket::IP->decode($ip_packet);

   # print "src ip: ",$ip_dgram->{src_ip},", dst ip: ",$ip_dgram->{dest_ip}," len: ",$ip_dgram->{len},"\n";

   if($ip_dgram->{proto} == NetPacket::IP::IP_PROTO_UDP){
      # udp_debug($ip_dgram->{data});
   } elsif ($ip_dgram->{proto} == NetPacket::IP::IP_PROTO_TCP){
      # print "TCP\n";

   } elsif ($ip_dgram->{proto} == NetPacket::IP::IP_PROTO_ICMP){
      # icmp_debug($ip_dgram->{data});
   } else {
      # print "IP Packet is neither TCP or UDP\n";
   }

}

sub got_a_packet {
   my ($args, $header, $packet) = @_;
   my $frame = NetPacket::Ethernet->decode( $packet );
   # print("src MAC: $frame->{src_mac} ");
   # print("dest MAC: $frame->{dest_mac}\n");

   #unless ($frame->{type} == NetPacket::Ethernet::ETH_TYPE_IP){
   #   die "Packet is not a IP packet\n";
   #}
   #foreach my $name (sort keys %{$header}){
   #   print "$name : $header->{$name}\n";
   #}

   if ($frame->{type} == NetPacket::Ethernet::ETH_TYPE_IP){
      # ip_debug($frame->{data});
      # print "IP","\n";
   } elsif ($frame->{type} == ETH_TYPE_PABLO()){
      eth_debug ($frame->{data})
   } else {
      # print "Another protocol\n";
   }
}

my $err = '';
my $dev = 'nf2c0';
my $number_of_pkts = -1; # loop forever

# parsers the command line
my %options = ();
getopts('c:hi:f:n:',\%options);

die "-c <num clks until shift>\n-i <iface>\n-f <filter EXPR>\n-n <number of packets to receive>\n-h for help\n\n" if defined $options{h};

$dev              = $options{i} if (defined $options{i});
$number_of_pkts   = $options{n} if (defined $options{n});
$num_clks_per_bu  = $options{c} if (defined $options{c});

# it sets the number of clk per bucket shift

my $is_promisc = 1;

$pcap = Net::Pcap::pcap_open_live($dev,1500,$is_promisc,0,\$err) or die "Cant open device $dev: $err\n";

# parsers filter options if there is
my $filter;

if(defined $options{f}){
   my $netmask = inet_aton "255.255.255.0";

   $err = Net::Pcap::pcap_compile($pcap, \$filter, $options{f}, 1, Net::Pcap::PCAP_IF_LOOPBACK);#$netmask);
   if($err == -1){
      die "Unable to compile the filter message\n";
   }
   Net::Pcap::pcap_setfilter($pcap, $filter);
}

open ($pcap_por_pkt, '>', "/root/experimentos/medicoesHW/resultadoParcialPorPkt");

Net::Pcap::pcap_loop($pcap,$number_of_pkts,\&got_a_packet,'');

## Nao será executado devido ao signal
Net::Pcap::pcap_close($pcap);

my $key;
my @keys = keys %bloom_hash;
foreach $key (@keys) {
   printf "bloom{$key}: Media buckets: %f. Media (em ms): %f\n\n", $bloom_hash{$key}/$bloom_counter{$key},$bloom_clock{$key}*8e-9*1e3/$bloom_counter{$key};
}
