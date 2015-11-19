package Ifeffit::Plugins::Filetype::Athena::PFBL12C;  # -*- cperl -*-

=head1 NAME

Ifeffit::Plugin::Filetype::Athena::Lambda - filetype plugin for Photon Factory BL12C

=head1 SYNOPSIS

This plugin converts data recorded as a function of mono angle to data
as a function of energy.

=cut

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
use File::Basename;
use File::Copy;
@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw();

use vars qw($is_binary $description);
$is_binary = 1;
$description = "Read files from Photon Factory Beamline 12C.";


use constant PI      => 4 * atan2 1, 1;
use constant HBARC   => 1973.27053324;
use constant TWODONE => 6.2712;	# Si(111)
use constant TWODTHR => 3.275;	# Si(311)


=head1 Methods

=over 4

=item C<is>

A PFBL12C file is identified by the string "KEK-PF BL12C" in the first
line of the file.

=cut


sub is {
  shift;
  my $data = shift;
  open D, $data or die "could not open $data as data (PFBL12C)\n";
  my $line = <D>;
  close D;
  return 1 if ($line =~ m{KEK-PF\s+BL12C});
  return 0;
};

=item C<fix>

Convert the wavelength array to energy using the formula

   data.energy = 2 * pi * hbarc / 2D * sin(data.angle)

where C<hbarc=1973.27053324> is the the value in eV*angstrom units and
D is the Si(111) plane spacing.

=cut



sub fix {
  shift;
  my ($data, $stash_dir, $top, $r_hash) = @_;
  my ($nme, $pth, $suffix) = fileparse($data);
  my $new = File::Spec->catfile($stash_dir, $nme);
  ($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);
  open my $D, $data or die "could not open $data as data (fix in PFBL12C)\n";
  open my $N, ">".$new or die "could not write to $new (fix in PFBL12C)\n";

  my ($header, $twod) = (1,TWODONE);
  my @offsets;
  while (<$D>) {
    last if ($_ =~ m{});
    chomp;
    if ($header and ($_ =~ m{\A\s+offset}i)) {
      my $this = $_;
      @offsets = split(" ", $this);
      print $N '# ', $_, $/;
      print $N '# --------------------------------------------------', $/;
      print $N '# energy_requested   energy_attained  time  i0  i1  ', $/;
      $header = 0;
    } elsif ($header) {
      my $this = $_;
      if ($this =~ m{mono.+\( (\d+) \)}ix) {
	$twod = ($1 == 111) ? TWODONE : TWODTHR;
      };
      print $N '# ', $_, $/;
    } else {
      my @list = split(" ", $_);
      $list[0] = (2*PI*HBARC) / ($twod * sin($list[0] * PI / 180));
      $list[1] = (2*PI*HBARC) / ($twod * sin($list[1] * PI / 180));
      my $ndet = $#list-2;
      foreach my $i (1..$ndet) {
	$list[2+$i] = $list[2+$i] - $offsets[2+$i];
      };
      my $pattern = "  %9.3f  %9.3f  %6.2f" . "  %12.3f" x $ndet . $/;
      printf $N $pattern, @list;
    };
  };
  close $N;
  close $D;
  return $new;
};


=head1 AUTHOR

  Bruce Ravel <bravel@anl.gov>
  http://feff.phys.washington.edu/~ravel/software/exafs/
  Athena copyright (c) 2001-2006

=cut



1;
__END__

