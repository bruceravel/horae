package Ifeffit::Plugins::Filetype::Athena::BESSRC;  # -*- cperl -*-


=head1 NAME

Ifeffit::Plugin::Filetype::Athena::BESSRC - APS BESSRC filetype plugin

=head1 SYNOPSIS

This plugin directly reads the binary files written by APS BESSRC
beamline 12BM.  See the document for the X10C plugin for full details
about B<Athena>'s filetype plugins.

=head1 BESSRC files

This plugin strips blank lines and the line containing only a plus (+)
sign from the header.  It also removes the first data column, which is
a fairly useless count of the number of data points.

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

use vars qw($is_binary $description);
$is_binary = 0;
$description = "Read old style files from APS beamline 12BM.";


sub is {
  shift;
  my $data = shift;
  open D, $data or die "could not open $data as data (BESSRC)\n";
  my $maybe = 0;
  while (<D>) {
    ++$maybe if /^\s*ioc12bmfoe/;
    close D, return 1 if ($maybe and (/^\s*\+\s*$/));
  };
  close D;
  return 0;
};

sub fix {
  shift;
  my ($data, $stash_dir, $top, $r_hash) = @_;
  my ($nme, $pth, $suffix) = fileparse($data);
  my $new = File::Spec->catfile($stash_dir, $nme);
  ($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);
  open D, $data or die "could not open $data as data (fix in BESSRC)\n";
  open N, ">".$new or die "could not write to $new (fix in BESSRC)\n";
  my $header = 1;
  while (<D>) {
    ($header = 0), next if ($_ =~ /^\+\s*$/);
    next if ($_ =~ /^\s*$/);
    print N "# " . $_ if $header; # comment headers
    next if ($header);
    chomp;
    my @line = split(" ", $_);
    shift @line;
    my $prefix = "  ";
    if (/Number/) {
      print N "# -----------------------$/";
      @line = grep {! /^\-$/} @line;
      $prefix = "# ";
    };
    print N $prefix, join(" ", @line), $/;
  };
  close N;
  close D;
  return $new;
}


1;
__END__
