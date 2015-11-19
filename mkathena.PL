#!/usr/bin/perl -w
use Fatal qw(open close);
my $mode = 0755;

## ----- build ATHENA
(-e "bin/athena") and unlink "bin/athena";
open my $TO, ">bin/athena";
foreach my $p (qw(top head main_window draw_properties set_properties file
		  group_ops align pixel calibrate deglitch truncate sa_fluo
		  mee diff lograt peakfit lcf rebin smooth convolve demo
		  macro palettes plot plotstyles project report rc
		  setup mru prefs registry keys teach_ft series misc)) {
  open my $FROM, "athena_parts/$p.pl";
  foreach my $l (<$FROM>) { print $TO $l };
  close $FROM
};
close $TO;
print "===> Assembled athena from its parts (athena_parts/) and wrote to bin/athena.\n";
chmod $mode, 'bin/athena';
