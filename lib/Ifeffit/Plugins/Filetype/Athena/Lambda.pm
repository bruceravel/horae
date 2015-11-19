package Ifeffit::Plugins::Filetype::Athena::Lambda;  # -*- cperl -*-


=head1 NAME

Ifeffit::Plugin::Filetype::Athena::Lambda - filetype plugin for data recorded in wavelength

=head1 SYNOPSIS

This plugin converts data recorded as a function of wavelength to data
as a function of energy.

This plugin uses Ifeffit to read the data, so the original data file
must be in a form that can be read by Ifeffit.  If the original data
cannot be read by Ifeffit, you will need to use a plugin specifically
designed for these data.

=cut


use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
use Ifeffit;
use File::Basename;
use File::Copy;
@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw();

use vars qw($is_binary $description);
$is_binary = 0;
$description = "Import data recorded by photon wavelength.";

=head1 Methods

=over 4

=item C<is>

A Lambda file is identified as one which has small values in the first
column which are monotonically descending.  The value chosen (10
invAng) means that this plugin will recognize a file recorded in
wavelength for any K edge starting with Mg, any L edge starting with
As, and any M edge starting with Tb.  This only checks the first 10
data points.

=cut

sub is {
  shift;
  my $data = shift;		# use Ifeffit to query first column
  Ifeffit::ifeffit("read_data(file=\"$data\", group=l___am)\n");
  my $suff = (split(" ", Ifeffit::get_string('$column_label')))[0];
  my @e = Ifeffit::get_array("l___am.$suff");
  my ($small, $descending) = (1,1);
  foreach my $i (0 .. 9) {	# check first 10 data points
    $small &&= ($e[$i] < 10);
    $descending &&= ($e[$i] > $e[$i+1]);
  };
  Ifeffit::ifeffit("erase \@group l___am\n");
  return ($small and $descending);
};


=item C<fix>

Convert the wavelength array to energy using the formula

   data.energy = 2 * pi * hbarc / data.wavelength

where C<hbarc=1973.27053324> is the the value in eV*angstrom units.

=cut

sub fix {
  shift;
  my ($data, $stash_dir, $top, $r_hash) = @_;
  my ($nme, $pth, $suffix) = fileparse($data);
  my $new = File::Spec->catfile($stash_dir, $nme);
  ($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);
  open D, $data or die "could not open $data as data (fix in Encoder)\n";
  copy($data, $new);

  ## use Ifeffit to read in the encoder data, perform the conversion, and write the data back out
  my $prefactor = 2 * 3.14159265358979323844 * 1973.27053324;
  my $command = "read_data(file=\"$new\", group=l___am)\n";
  my @labels = split(" ", Ifeffit::get_string('$column_label'));
  $command .= "set l___am.energy = $prefactor/l___am.$labels[0]\n";
  $labels[0] = "energy";
  $command .= "write_data(file=\"$new\", l___am." . join(", l___am.", @labels) . ")\n";
  $command .= "erase \@group l___am\n";
  ##print $command;
  Ifeffit::ifeffit($command);

  return $new;
}

=back


=head1 AUTHOR

  Bruce Ravel <bravel@anl.gov>
  http://feff.phys.washington.edu/~ravel/software/exafs/
  Athena copyright (c) 2001-2006

=cut



1;
__END__
