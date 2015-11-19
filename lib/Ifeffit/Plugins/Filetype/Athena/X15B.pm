package Ifeffit::Plugins::Filetype::Athena::X15B;  # -*- cperl -*-


=head1 NAME

Ifeffit::Plugin::Filetype::Athena::X15B - NSLS X15B filetype plugin

=head1 SYNOPSIS

This plugin directly reads the binary files written by NSLS beamline
X15B.  See the document for the X10C plugin for full details about
B<Athena>'s filetype plugins.

=head1 X15B files

At X15b there is a program called x15totxt, written in Turbo Pascal by
some dude named Tim Darling.  He kindly left behind a short
explanation the format of the X15b binary data file.  It seems that
the header is 53 4-byte numbers.  Each line of data is 16 4 byte
numbers.  Thus this file is easily unpacked and processed in four byte
bites.

The resulting file is a well-labeled, well-formatted column data file
in a form that will work well with Athena or virtually any other
analysis or plotting program.  The columns are: energy, the I0 ion
chamber, the narrow and wide windows on the germanium detector, and
the transmission ion chamber.

=head1 AUTHOR

  Bruce Ravel <bravel@anl.gov>
  http://feff.phys.washington.edu/~ravel/software/exafs/
  Athena copyright (c) 2001-2006

=cut


use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
use File::Basename;
use File::Copy;
@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw();

use constant ENERGY => 0;	# columns containing the
use constant I0     => 4;	# relevant scalars
use constant NARROW => 8;
use constant WIDE   => 9;
use constant TRANS  => 10;

use vars qw($is_binary $description);
$is_binary = 1;
$description = "Read binary files from NSLS beamline X15B.";

sub is {
  shift;
  my $data = shift;
  my $Ocircumflex = chr(212);
  my $nulls = chr(0).chr(0).chr(0);
  open D, $data or die "could not open $data as data (X15B)\n";
  binmode D;
  my $first = <D>;
  close D;
  return 1 if ($first =~ /^$Ocircumflex$nulls/);
  return 0;
};

sub fix {
  shift;
  my ($data, $stash_dir, $top, $r_hash) = @_;
  my ($nme, $pth, $suffix) = fileparse($data);
  my $new = File::Spec->catfile($stash_dir, $nme);
  ($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);

  ## slurp the entire binary file into an array of 4-byte floats
  do {
    local $/ = undef;
    open D, $data or die "could not read $data as data (fix in X15B)\n";
    @blob = unpack("f*", <D>);
    close D
  };
  open N, ">".$new or die "could not write to $new (fix in X15B)\n";

  ## the header is mysterious, but the project name from scanedit is
  ## in there, so pull that out as text (pack and unpack process this
  ## mysterious header as text)
  my @header = ();
  foreach (1..53) {
    push @header, shift @blob;
  };
  my $string = pack("f*", @header);
  my $project = "??";
  foreach (unpack("A*", $string)) {
    $project = "$1 $2" if (/(\w+)\s+(\d+\/\d+\/\d+)/);
  };

  print N <<EOH
# X15B  project: $project
# original file: $data
# unpacked from original data as a sequence of 4-byte floats
# --------------------------------------------------------------------
#   energy           I0          narrow        wide           trans
EOH
  ;

  ## just pull out the relevant columns.  we are only reading the
  ## energy, i0, the narrow and wide windows from the Ge detector, and
  ## the transmission ion chmaber.  All other scalars are presumed
  ## uninteresting.  The indeces of these scalars in the line are
  ## defined as constants (see above).
  while (@blob) {
    shift @blob;
    my @line = ();
    foreach (1..15) {
      push @line, shift(@blob);
    };
    ## just write out the relevant lines
    printf N " %12.4f  %12.4f  %12.4f  %12.4f  %12.4f\n",
      @line[ENERGY, I0, NARROW, WIDE, TRANS];
  }; # loop over rows of data

  close N;
  return $new;
}


1;
__END__
