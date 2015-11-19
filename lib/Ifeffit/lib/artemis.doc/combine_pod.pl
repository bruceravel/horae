#!/usr/bin/perl
print "Constructing monolithic pod file\n";
my $regex = join("|", @ARGV);
print $regex, $/;
open POD, ">artemisdoc.pod";
open TOP, "artemis.pod";
my $found_back = 0;
while (<TOP>) {
  next if (/=head1 SECTIONS OF THE DOCUMENT/);
  next if (/=item Modal views in the main window/);
  next if (/=item Input and Output/);
  next if (/=item Features of B<Artemis>/);
  unless (/^L.*($regex)\b.*\|\|/) {
    print POD;
    next;
  };
  open SEC, "$1.pod";
  $found_back = 0;
  while (<SEC>) {
    #($found_back=1), next if (/=back/ and not $found_back);
    #next unless $found_back;
    last if (/=over 5/);
    print POD;
  };
  close SEC;
};

close TOP;
close POD;
#rename 'artemisdoc.pdf', 'artemis.pdf'
