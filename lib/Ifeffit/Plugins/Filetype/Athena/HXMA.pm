package Ifeffit::Plugins::Filetype::Athena::HXMA;  # -*- cperl -*-

### Place this file in
###  Windows: C:\Program Files\Ifeffit\horae\Ifeffit\Plugins\Filetype\Athena
###  unix: ~/.horae/Ifeffit/Plugins/Filetype/Athena/

=head1 NAME

Ifeffit::Plugin::Filetype::Athena::HXMA - Demystify files from the HXMA beamline at the CLS

=head1 SYNOPSIS

This plugin strips the many columns not normally needed from a file
from the CLS HXMA beamline.  Most significantly, this strips the
leading 1 from every line of data, a feature which confuses Athena's
column selection dialog.  It also chooses the Energy:sp column as the
energy axis.

=cut

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
use File::Basename;
use File::Copy;
@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw();


use vars qw($is_binary $description);
$is_binary = 1;
$description = "Demystify files from the HXMA beamline at the CLS.";

=head1 Methods

=over 4

=item C<is>

Recognize the HXMA file by the first line, which contains the phrase
"CLS Data Acquisition".

=cut

sub is {
  shift;
  my $data = shift;
  open D, $data or die "could not open $data as data (HXMA)\n";
  my $first = <D>;
  close D, return 1 if ($first =~ m{CLS Data Acquisition});
  close D;
  return 0;
};

=item C<fix>

Strip out all columns except for energy, I0, I1, I2, and the Lytle
detector.  Also write sensible column labels to the output data file.

=cut


sub fix {
  shift;
  my ($data, $stash_dir, $top, $hash) = @_;
  my ($nme, $pth, $suffix) = fileparse($data);
  my $new = File::Spec->catfile($stash_dir, $nme);
  ($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);
  open D, $data or die "could not open $data as data (fix in HXMA)\n";
  open N, ">".$new or die "could not write to $new (fix in HXMA)\n";

  print N "# $data demystified:", $/;
  print N "# ", "-" x 60, $/;
  print N "# Energy        I0        It        Ir        Lytle$/";

  my $found_headers = 0;
  my ($energy, $lytle, $i0, $it, $ir) = (0,0,0,0,0);
  while (<D>) {
    if ((not $found_headers) and ($_ =~ m{Event-ID})) {
      $found_headers = 1;
      my @headers = split(/\s+/, $_);
      foreach my $i (1 .. $#headers) {
	($energy = $i-1) if ($headers[$i] =~ m{Energy:sp});
	($lytle  = $i-1) if ($headers[$i] =~ m{mcs03:fbk});
	($i0     = $i-1) if ($headers[$i] =~ m{mcs04:fbk});
	($it     = $i-1) if ($headers[$i] =~ m{mcs05:fbk});
	($ir     = $i-1) if ($headers[$i] =~ m{mcs06:fbk});
      };
    };

    if ($_ !~ m{^\#}) {
      my @data = split(/,?\s+/, $_);
      printf N "  %s  %s  %s  %s  %s$/",
	$data[$energy], $data[$i0], $data[$it], $data[$ir], $data[$lytle];
    };
  };

  close N;
  close D;
  return $new;
}

=back

=head1 AUTHOR

  Bruce Ravel <bravel@bnl.gov>
  http://xafs.org/BruceRavel/
  Athena copyright (c) 2001-2008


=cut



1;
__END__
