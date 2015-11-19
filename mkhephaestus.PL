#!/usr/bin/perl -w
use Fatal qw(open close);
my $mode = 0755;

## ----- build HEPHAESTUS
(-e "bin/hephaestus") and unlink "bin/hephaestus";
open my $TO, ">bin/hephaestus";
foreach my $p (qw(head absorption formula data f1f2 ion transition find line misc)) {
  open my $FROM, "hephaestus_parts/$p.pl" or die "could not open parts/$p.pl for reading\n";
  foreach my $line (<$FROM>) { print $TO $line };
  close $FROM
};
close $TO;
print "===> Assembled bin/hephaestus from its parts (hephaestus_parts/) and wrote to bin/hephaestus.\n";
chmod $mode, 'bin/hephaestus';
