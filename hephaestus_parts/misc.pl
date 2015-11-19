#! /usr/bin/perl -w

sub BindMouseWheel {		# Mastering Perl/Tk ch. 15, p. 370
  my ($w) = @_;
  if ($^O eq 'MSWin32') {
    $w->bind('<MouseWheel>' =>
	     [ sub { $_[0]->yview('scroll', -($_[1]/120)*3, 'units') },
	       Ev('D') ]
	     );
  } elsif ($^O eq 'linux') {
    ## on linux the mousewheel works by mapping to buttons 4 and 5
    $w->bind('<4>' => sub { $_[0]->yview('scroll', -1, 'units') unless $Tk::strictMotif; });
    $w->bind('<5>' => sub { $_[0]->yview('scroll', +1, 'units') unless $Tk::strictMotif; });
  };
};

sub switch {
  my ($rhash) = @_;
  if ($current) {
    $bottom{$current} -> packForget;
    $frames{$current} -> configure(-relief=>'flat');
  };
  $current = $$rhash{page};
  $frames{$current} -> configure(-relief=>'ridge');
  $bottom{$current} -> pack(-side=>'top', -anchor=>'n', -fill=>'both', -expand=>1);
  $title->configure(-text=>$$rhash{text});
  return $current;
};

sub e2l {
  ($_[0] and ($_[0] > 0)) or return "";
  return 2*PI*HBARC / $_[0];
};


sub swap_energy_units {
  ## fix labels
  my $units = $data{units};
  my @edges = (qw(K L1 L2 L3 M1 M2 M3 M4 M5 N1 N2 N3 N4 N5 N6 N7
		    O1 O2 O3 O4 O5 P1 P2 P3));
  my @data_style_params = ('text', -font=>'Helvetica 10', -anchor=>'e', -foreground=>'black');
  if ($units eq 'Energies') {
    #$data{abs_energy_label}  -> configure(-text=>'Energy');
    #$data{abs_units_label}   -> configure(-text=>'eV');
    $data{form_energy_label} -> configure(-text=>'Energy:');
    $data{form_energy_units} -> configure(-text=>'eV');
    $data{ion_energy_label}  -> configure(-text=>'Photon energy');
    $energies{edges} -> headerConfigure(1, -text=>'Energy');
    $energies{lines} -> headerConfigure(2, -text=>'Energy');
    if ($data{sample_energy} < 8000) {
      ## swap energy values
      map {$energies{$_} = ($_ =~ /edges|lines/) ? $energies{$_} : &e2l($energies{$_})} keys(%energies);
      map {$data{$_}     = &e2l($data{$_})} (qw(abs_energy form_energy ion_energy));
    };
    $data{sample_energy} = 9000;
    my $data_style = $energies{edges} -> ItemStyle(@data_style_params);
    foreach my $e (@edges) {
	$energies{edges} -> itemConfigure($e, 1, -text=>$energies{$e}, -style=>$data_style);
    };
    $energies{edges} -> selectionClear;
    $energies{edges} -> anchorClear;
    $data_style = $energies{lines} -> ItemStyle(@data_style_params);
    foreach my $l (@LINELIST) {
	$energies{lines} -> itemConfigure($l, 2, -text=>$energies{$l}, -style=>$data_style);
	$energies{lines} -> itemConfigure($l, 3, -text=>$probs{$l}, -style=>$data_style);
    };
  } elsif ($units eq 'Wavelengths') {
    #$data{abs_energy_label}  -> configure(-text=>'Wavelength');
    #$data{abs_units_label}   -> configure(-text=>'Å');
    $data{form_energy_label} -> configure(-text=>'Wavelength:');
    $data{form_energy_units} -> configure(-text=>'Å');
    $data{ion_energy_label}  -> configure(-text=>'Photon wavelength');
    $energies{edges} -> headerConfigure(1, -text=>'Wavelength');
    $energies{lines} -> headerConfigure(2, -text=>'Wavelength');
    if ($data{sample_energy} > 8000) {
      ## swap energy values
      map {$energies{$_} = ($_ =~ /edges|lines/) ? $energies{$_} : &e2l($energies{$_})} keys(%energies);
      map {$data{$_}     = &e2l($data{$_})} (qw(abs_energy form_energy ion_energy));
    };
    $data{sample_energy} = e2l(9000);
    my $data_style = $energies{edges} -> ItemStyle(@data_style_params);
    foreach my $e (@edges) {
	$energies{edges} -> itemConfigure($e, 1, -text=>$energies{$e}, -style=>$data_style);
    };
    $energies{edges} -> selectionClear;
    $energies{edges} -> anchorClear;
    $data_style = $energies{lines} -> ItemStyle(@data_style_params);
    foreach my $l (@LINELIST) {
	$energies{lines} -> itemConfigure($l, 2, -text=>$energies{$l}, -style=>$data_style);
	$energies{lines} -> itemConfigure($l, 3, -text=>$probs{$l}, -style=>$data_style);
    };
  };
};


sub set_xsec {
  my $resource = $_[0];
  $xsec_menu -> menu -> entryconfigure($_, -state=>"normal") foreach (1 .. 4);
  if (($resource eq "henke") or ($resource eq "cl")) {
    $data{cross_section} = "Total";
    $data{xsec} = "xsec";
    $xsec_menu -> menu -> entryconfigure($_, -state=>"disabled") foreach (1 .. 4);
  };
};

sub set_pt_explain {
  my $which = lc($data{cross_section});
  ($which = "scattering") if (($data{resource} eq "Chantler") and ($data{cross_section} =~ /oherent/));
  $data{pt_explain} = "Using $data{resource} database\nComputing $which cross-section";
  $data{ion_resource} = "Using $data{resource} database";
};

## validation callback.  enforce positive numbers
sub set_variable {
  #print join(" | ", @_, $/);
  my ($k, $entry, $prop) = (shift, shift, shift);
  #print $k, $/;
  return 1 unless defined $entry;
  ($entry =~ /^\s*$/) and ($entry = '1');	# error checking ...
  if ($k eq 'width') {
    ($entry =~ /^\s*-$/) and return 1; # error checking ...
    ($entry =~ /^\s*-?(\d+\.?\d*|\.\d+|\.)\s*$/) or return 0;
  } else {
    ($entry =~ /^\s*(\d+\.?\d*|\.\d+|\.)\s*$/) or return 0;
  };
  ##get_ion_data(0) if (defined($entry) and ($k eq 'ion_energy'));
  return 1;
};

## I got this off of Usenet.  Do a search at groups.google.com for the
## package to find discussions of slow dialog boxes.  The text of this
## will be among the discussions.
package Patch::SREZIC::Tk::Wm;

use Tk::Wm;
package Tk::Wm;

sub Post
{
 my ($w,$X,$Y) = @_;
 $X = int($X);
 $Y = int($Y);
 $w->positionfrom('user');
 # $w->geometry("+$X+$Y");
 $w->MoveToplevelWindow($X,$Y);
 $w->deiconify;
# $w->idletasks; # to prevent problems with KDE's kwm etc.
# $w->raise;
}

package Patch::Workaround::_HistoryEntry;
no warnings;
sub _HistoryEntry::create {
  my $o = shift->new;
#    my($what, $index) = @_;
#    if (ref $what eq 'HASH') {
#	$o->file($what->{file});
#	$o->text($what->{text});
#    } else {
#	$o->file($what);
#    }
#    $o->index($index);
  $o;
};


1;
