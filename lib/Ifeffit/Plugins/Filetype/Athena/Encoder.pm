package Ifeffit::Plugins::Filetype::Athena::Encoder;  # -*- cperl -*-


=head1 NAME

Ifeffit::Plugin::Filetype::Athena::Encoder - filetype plugin for encoder data

=head1 SYNOPSIS

This plugin converts data recorded as a function of encoder to data as
a function of energy.  To do this, a GUI element is popped up which
prompts the user for the d-spacing of the monochromator, the number of
steps per degree on the mono motor, and the zero-angle encoder
reading.  The values for these parameters persist by being written to
the plugin registry.

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
use Tk::DialogBox;
@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw();

use vars qw($is_binary $description);
$is_binary = 0;
$description = "Import data recorded by encoder position.";

=head1 Methods

=over 4

=item C<is>

An encoder file is identified as one which has large integer values in
the first column which are monotonically descending.  Only the first
10 data points are checked.

=cut

sub is {
  shift;
  my $data = shift;		# use Ifeffit to query first column
  Ifeffit::ifeffit("read_data(file=\"$data\", group=e___nc)\n");
  my $suff = (split(" ", Ifeffit::get_string('$column_label')))[0];
  my @e = Ifeffit::get_array("e___nc.$suff");
  my ($large, $descending) = (1,1);
  foreach my $i (0 .. 9) {	# check first 10 data points
    $large &&= (($e[$i] > 100) and ($e[$i] =~ /^\d+$/));
    $descending &&= ($e[$i] > $e[$i+1]);
  };
  Ifeffit::ifeffit("erase \@group e___nc\n");
  return ($large and $descending);
};


=item C<fix>

Assuming the first column is the encoder reading, pop up some widgets
for specifying d-spacing, steps/degree, and the zero offset, then
convert encoder values to energy using a macro.

This is an example of a plugin which uses a GUI element (built off of
the third argument to C<fix>) and persistence (using the fourth
argument).  The syntax for the persistence is a bit tricky.  The
argument is a referecne to a hash, so all parameters stored in this
hash have to be dereferenced.  That's what's going on just after the
call to C<copy> in Encoder's C<fix> method.

=cut

sub fix {
  shift;
  my ($data, $stash_dir, $top, $r_hash) = @_;
  my ($nme, $pth, $suffix) = fileparse($data);
  my $new = File::Spec->catfile($stash_dir, $nme);
  ($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);
  open D, $data or die "could not open $data as data (fix in Encoder)\n";
  copy($data, $new);

  ## setting these params this way assures theior persistence
  $$r_hash{dspacing} ||= 3.13560137;
  $$r_hash{stpdeg}   ||= 4000;
  $$r_hash{dzerooff} ||= 0;

  ## build a pop-up to prompt for the three parameter values
  my $d = $top -> DialogBox(-title   => "Athena: Import encoder data",
			    -buttons => ["OK", "Cancel"]);

  my $rot = $d -> add("ROText",
		      -relief => 'flat',
		      -wrap   => 'word',
		      -width  => 50,
		      -height => 9) -> pack();
  $rot -> insert('0.0', "These data were measured as a function of encoder position rather than energy.  You need to provide 3 parameters to convert encoder readings to energy:

1. The d-spacing of the crystal
2. The number of motor steps per degree
3. The encoder reading of the zero-angle position

");
  my @swap_bindtags = $rot->bindtags; # this 3-line idiom disables mouse-3 in the ROText wdiget
  $rot -> bindtags([@swap_bindtags[1,0,2,3]]);
  $rot -> bind('<Button-3>' => sub{$rot->break});

  ## this is a stack of frames with labels and entries
  my $fr = $d -> add("Frame") -> pack();
  $fr -> Label(-text=>"d-spacing:", -width=>13, -anchor=>'e')
    -> pack(-side=>'left');
  $fr -> Entry(-textvariable => \$$r_hash{dspacing}, -width => 10)
    -> pack(-side=>'left');

  $fr = $d -> add("Frame") -> pack();
  $fr -> Label(-text=>"steps/degree:", -width=>13, -anchor=>'e')
    -> pack(-side=>'left');
  $fr -> Entry(-textvariable => \$$r_hash{stpdeg}, -width => 10)
    -> pack(-side=>'left');

  $fr = $d -> add("Frame") -> pack();
  $fr -> Label(-text=>"zero offset:", -width=>13, -anchor=>'e')
    -> pack(-side=>'left');
  $fr -> Entry(-textvariable => \$$r_hash{dzerooff}, -width => 10)
    -> pack(-side=>'left');

  my $button = $d->Show;
  return q{} if ($button eq 'Cancel');


  my $title_line = sprintf("^^ Encoder to energy: d-spacing=%.5f steps/deg=%d zero offset=%.5f",
			   $$r_hash{dspacing}, $$r_hash{stpdeg}, $$r_hash{dzerooff});

  ## use Ifeffit to read in the encoder data, perform the conversion, and write the data back out
  my $command = "read_data(file=\"$new\", group=e___nc)\n";
  my @labels = split(" ", Ifeffit::get_string('$column_label'));
  $command .= "set e___nc.energy = 12398.61 / (2*$$r_hash{dspacing}) / sin( (e___nc.$labels[0] - $$r_hash{dzerooff}) / (57.29577951*$$r_hash{stpdeg}))\n";
  $command .= "\$title1 = \"$title_line\"\n";
  $labels[0] = "energy";
  $command .= "write_data(file=\"$new\", \$e___nc_title_*, \$title1, e___nc." . join(", e___nc.", @labels) . ")\n";
  $command .= "erase \@group e___nc\n";
  $command .= "erase \$title1 \$e___nc_title_*\n";
  Ifeffit::ifeffit($command);

  return $new;
}

=back

=head1 The conversion algorithm

Here is an Ifeffit macro that does the same thing as this plugin

  macro step2energy
     "convert encoder readings to energy in eV"
     set rad2deg   = 57.29577951    # radians to degrees
     set hc        = 12398.61       # hc in eV*Ang
     set dspace    = $3             # mono lattice spacing
     set stpdeg    = $4             # steps/degree for mono motor
     set zeroff    = $5             # zero-angle value of encoder
     set $1.energy =  hc / (2*dspace) / sin( ($1.$2 - zeroff) / (rad2deg*stpdeg) )
  end macro

Assuming the encoder column has the column label "1" and assuming
values for the parameters, this would be called in Ifeffit as

  step2energy(e___nc, 1, 1.92017, 4000, 0)


=head1 AUTHOR

  Bruce Ravel <bravel@anl.gov>
  http://feff.phys.washington.edu/~ravel/software/exafs/
  Athena copyright (c) 2001-2006


=cut



1;
__END__
