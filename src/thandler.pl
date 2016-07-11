use strict;
use warnings;
use sigtrap qw(handler my_handler USR1);

my $global = 0;

sub my_handler {
   my $signal = shift;
   $global = 1;
}

while (1) {
   if($global == 1) {
      last;
   }
}

print $global,"\n";
