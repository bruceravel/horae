#!/usr/bin/perl -w
use Fatal qw(open close);
my $mode = 0755;

## ----- build ARTEMIS
(-e "bin/artemis") and unlink "bin/artemis";
open my $TO, ">bin/artemis";
foreach my $p (qw(top head main_window gds2 feff atoms2 path file athena firstshell
		  data palettes fit plot zip project record macro mru
		  prefs log logview feffit rc misc)) {
  open my $FROM, "artemis_parts/$p.pl";
  foreach my $line (<$FROM>) { print $TO $line };
  close $FROM
};
close $TO;
print "===> Assembled bin/artemis from its parts (artemis_parts/) and wrote to bin/artemis.\n";
chmod $mode, 'bin/artemis';
