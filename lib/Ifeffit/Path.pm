package Ifeffit::Path;                  # -*- cperl -*-
######################################################################
## Ifeffit::PathDev: Object oriented path/data manipulation for Ifeffit
##
##                     Artemis is copyright (c) 2001-2008 Bruce Ravel
##                                                     bravel@anl.gov
##                            http://feff.phys.washington.edu/~ravel/
##
##                   Ifeffit is copyright (c) 1992-2006 Matt Newville
##                                         newville@cars.uchicago.edu
##                        http://cars.uchicago.edu/~newville/ifeffit/
##
##	  The latest version of Artemis can always be found at
##	 http://feff.phys.washington.edu/~ravel/software/exafs
##
## -------------------------------------------------------------------
##     All rights reserved. This program is free software; you can
##     redistribute it and/or modify it provided that the above notice
##     of copyright, these terms of use, and the disclaimer of
##     warranty below appear in the source code and documentation, and
##     that none of the names of The Naval Research Laboratory, The
##     University of Chicago, University of Washington, or the authors
##     appear in advertising or endorsement of works derived from this
##     software without specific prior written permission from all
##     parties.
##
##     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
##     EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
##     OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
##     NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
##     HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
##     WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
##     FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
##     OTHER DEALINGS IN THIS SOFTWARE.
## -------------------------------------------------------------------
######################################################################

use strict;
use vars qw($VERSION $cvs_info $module_version @ISA @EXPORT @EXPORT_OK @indeces_used);
use constant ETOK=>0.262468292;
use File::Copy;
use File::Path;
use File::Basename;
use Text::Wrap;
$Text::Wrap::columns = 65;
use Ifeffit;
ifeffit("\&screen_echo = 0\n");
use Ifeffit::Tools;
use Ifeffit::FindFile;
use Chemistry::Elements qw(get_name get_Z get_symbol);
use Math::Round qw(round);
my $absorption_exists = (eval "require Xray::Absorption");
if ($absorption_exists) {Xray::Absorption->load('Elam')};

require Exporter;

@ISA = qw(Exporter AutoLoader Ifeffit::Tools Ifeffit::FindFile);
@EXPORT_OK = qw();

$VERSION = "0.8.013";
$cvs_info = '$Id: $ ';
$module_version = (split(' ', $cvs_info))[2] || 'pre_release';
@indeces_used = ('^^placeholder^^');

use vars qw($last_plot $last_plot_command);
$last_plot = "";
$last_plot_command = "";

my $default = Ifeffit::Path -> new(type=>'data');
my $echocmd = \&::Echo;
my @done = (" ... done!", 1);

use vars qw/$thisdir $libdir/;
use File::Spec;
$thisdir = $Ifeffit::FindFile::thisdir;
$libdir = File::Spec->catfile($thisdir, "lib", "artemis");

my %data_default = (kmin      => 2,
		    kmax      => 15,
		    dk	      => 1,
		    k1        => 0,
		    k2        => 0,
		    k3        => 0,
		    karb      => "",
		    karb_use  => 0,
		    rmin      => 1,
		    rmax      => 3,
		    dr	      => 0.1,
		    cormin    => 0.25,
		    epsilon_k => '',
		    fit_space => 'R',
		    kwindow   => 'Kaiser-Bessel',
		    rwindow   => 'Kaiser-Bessel',
		    do_bkg    => 'no',
		    use_bkg   => 0,
		    data_index=> 0,
		    include   => 1,
		    plot      => 0,
		    made_diff => 0,
		    pcpath    => 'None',
		    pcplot    => 'No',
		    pcelem    => 'H',
		    pcedge    => 'K',
		    is_rec    => 0,
		    titles    => '',
		    file      => '',
		    with_fit  => 0,
		    with_res  => 0,
		    with_bkg  => 0,
		    is_xmu    => 0,
		    is_chi    => 1,
		    do_bkg    => 0,
		    ##fix_chi   => 0,
		   );


## the next two regular expressions are use in the get method to
## recognize the parameters associate with data and with a feff
## calculation

##my $data_params_regex = join("|", sort(keys(%data_default)));
## (insert (make-regexp
## 	 '("kmin" "kmax" "dk" "k1" "k2" "k3" "karb" "karb_use" "rmin" "rmax" "dr"
## 	   "cormin" "epsilon_k" "fit_space" "kwindow" "rwindow" "do_bkg"
## 	   "use_bkg" "data_index" "include" "plot" "made_diff"
## 	   "pcpath" "pcplot" "pcelem" "pcedge" "is_rec" "titles" "file"
## 	   "with_fit" "with_res" "with_bkg"
## 	   )))
my $data_params_regex =
  "cormin|d([kr]|ata_index|o_bkg)|epsilon_k|" .
  "fi(le|t_(diff|space))|i(nclude|s_rec)|" .
  "k([123]|arb(|_use)|m(ax|in)|window)|made_diff|" .
  "p(c(e(dge|lem)|p(ath|lot))|lot)|r(m(ax|in)|window)|" .
  "titles|use_bkg|with_(bkg|fit|res)";
## (insert (make-regexp '("feff.inp" "atoms.inp" "feff.inp" "feff.run"
##                        "misc.dat" "paths.dat" "files.dat" "path" "intrp")))
my $feff_params_regex =
  "atoms\.inp|f(eff\.(inp|run)|iles\.dat)|intrp|misc\.dat|path(|s\.dat)";

## (insert (make-regexp
## 	 '("label" "s02" "e0" "delr" "sigma^2" "ei" "3rd" "4th" "dphase" "k_array"
## 	   "phase_array" "amp_array")))
my $path_params_regex =
  "3rd|4th|amp_array|d(elr|phase)|e[0i]|k_array|label|phase_array|s(02|igma\^2)";





sub new {
  my $classname = shift;
  my $self = {};

  $self->{line} = 0;	# meta data
  $self->{type} = '';
  $self->{from_project} = 0;

  bless($self, $classname);
  $self -> make(@_);
  warn "Ifeffit::Path type undefined!\n" unless ($self->{type});

 SWITCH: {
    ($self->{type} eq 'path') and do {
      foreach (qw(label s02 e0 delr sigma^2 ei 3rd 4th dphase k_array phase_array amp_array)) {
	$self->{$_} = '';
      };
      $self->{setpath} = 0;
      $self->{is_ss}   = 0;
      $self->{is_col}  = 0;
      last SWITCH;
    };
    ($self->{type} eq 'data') and do {
      ##       foreach (qw(kmin kmax dk kweight rmin rmax dr cormin
      ## 		  epsilon_k kwindow rwindow do_bkg use_bkg
      ## 		  pcplot pcelem pcedge fit_space)) {
      foreach (keys %data_default) {
	$self->{$_} = $data_default{$_};
	##$self->{$_} = (exists $default->{$_}) ? $default->{$_} : $data_default{$_};
      };
      last SWITCH;
    };
    ($self->{type} eq 'feff') and do {
      $self->{include}  = 1;
      $self->{linkto} ||= 0;
      $self->{mode}   ||= 0;
      last SWITCH;
    };
  };
  ## flags for processing chores
  $self->{do_k} = 1;
  $self->{do_r} = 1;
  $self->{do_q} = 1;

  $self->{data_showing} = 'chi';

  ($self->{lab} = $self->{group}) unless (exists $self->{lab} and $self->{lab});

  return $self;
};


sub make {
  my $self = shift;
  unless ($#_ % 2) {
    my $this = (caller(0))[3];
    die "$this error!\n";
    return;
  };
  while (@_) {
    my $att   = lc(shift);
    my $value = shift;
    ## worry about unmatched parens and quotation marks among the titles
    if ($att eq 'titles') {
      $value =~ s/\"//g;
      my $string = "";
      foreach my $l (split(/\n/, $value)) {
	$l =~ s/\s+$//;
	## walk through the title line counting open and closed parens,
	## skipping unmatched close parens
	my $count = 0;
	foreach my $i (0..length($l)) {
	  ++$count if (substr($l, $i, 1) eq '(');
	  --$count if ($count and (substr($l, $i, 1) eq ')'));
	};
	## close all unmatched parens by appending close_parens to the string
	$l .= ')' x $count;
	$string .= $l . $/;
      };
      $value = $string;
    };

    $self->{$att} = $value;
    ($att eq 'file') and ($self->{type} eq 'path') and ($self->{feff} = $self->{file});
    ($att eq 'feff') and ($self->{type} eq 'path') and ($self->{file} = $self->{feff});
    if (($att eq 'path') and ($self->{type} eq 'feff')) {
      $self->{'atoms.inp'} = File::Spec->catfile($self->{path}, 'atoms.inp');
      $self->{'feff.inp'}  = File::Spec->catfile($self->{path}, 'feff.inp');
      $self->{'feff.run'}  = File::Spec->catfile($self->{path}, 'feff.run');
      $self->{'misc.dat'}  = File::Spec->catfile($self->{path}, 'misc.dat');
      $self->{'paths.dat'} = File::Spec->catfile($self->{path}, 'paths.dat');
      (-e File::Spec->catfile($self->{path}, 'path00.dat')) and
	($self->{'paths.dat'} = File::Spec->catfile($self->{path}, 'path00.dat'));
      $self->{'files.dat'} = File::Spec->catfile($self->{path}, 'files.dat');
    };
    if (($att eq 'do_xmu') and $value) {
      $self->{do_xmu} = 1; $self->{do_k} = 1; $self->{do_r} = 1; $self->{do_q} = 1;
    };
    if (($att eq 'do_k') and $value) {
      $self->{do_k} = 1; $self->{do_r} = 1; $self->{do_q} = 1;
    };
    if (($att eq 'do_r') and $value) {
      $self->{do_r} = 1; $self->{do_q} = 1;
    };
    if (($att eq 'do_q') and $value) {
      $self->{do_q} = 1;
    };
    if (($self->{type} eq 'feff') and ($att eq 'deg')) {
      $self->{n} = $value;
    };
    if (($self->{type} eq 'feff') and ($att eq 'n')) {
      $self->{deg} = $value;
    };
    if ($self->{type} eq 'path') {
      foreach my $k (qw(label s02 e0 delr sigma^2 ei 3rd 4th dphase k_array phase_array amp_array)) {
	$self->{$k} = "" if (not defined($self->{$k}));
      };
    };

    #if ($att eq 'sameas') {
    #  $self
    #};
  };
};


sub SetDefault {
  my $self = shift;
  $default -> make(@_);
  #$default = Ifeffit::Group -> new(@_);
};


## return the data associated with this Path object
sub data {
  my $self = shift;
  my $data = $self->{id};
  ($data = $self->{data})   if ($self->{type} =~ /(feff|path)/);
  ($data = $self->{sameas}) if ($self->{type} =~ /(bkg|diff|fit|res)/);
  ($data = 'data0')         if ($self->{type} eq 'gsd');
  return $data;
};

sub feff {
  my $self = shift;
  my $feff = $self->{id};
  ($feff = $self->{parent}) if ($self->{type} eq 'path');
  ($feff = 0)               if ($self->{type} =~ /(bkg|diff|gds|fit|res)/);
  return $feff;
};

sub parent {
  my $self = shift;
  return $self->{id}     if (($self->{type} eq 'fit') and not $self->{parent});
  return $self->{parent} if ($self->{type} =~ /(fit|path)/);
  return 0;
};

## return the type of this Path object
sub type {
  my $self = shift;
  if (exists $self->{type}) {
    return $self->{type}
  } else {
    return 0;
  };
};


## returns true if this data is included in the fit
sub included {
  my $self = shift;
  return $self->{include};
};


## this method does the hard work of returning the parameter value for
## the objects parentage, when appropriate.  For instance, is the kmin
## of a path object is requested, this returns the kmin of the data
## associated with that path.  Return 0 is not found.

## extend to a list
sub get {
  my $self = shift;
  my $p = $_[0];
  my $f = $self->{family};
  if ($p eq 'include') {	# return a paths include value,
    return $self->{$p} || 0;	# not the include value of the data

  } elsif ($p =~ /^bkg/) { # bkg parameters
    return 0 unless exists $self->{$p};
    return $self->{$p};
				# fits have their own FT and fit ranges
  } elsif (($self->type eq 'fit') and
	   $self->{parent} and
	   ($p =~ /^(d[kr]|k(m(ax|in)|window)|r(m(ax|in)|window))$/) ) {
    ##(kmin kmax dk kwindow rmin rmax dr rwindow)
    return $self->{$p};
				# paths and data can have a file
  } elsif (($self->type eq 'path') and ($p eq 'file')) {
    return $self->{$p};

  } elsif ($p =~ /^($data_params_regex)$/) { # data parameters
    my $d = $self->data;
    return $f->{$d}->{$p} || 0;

  } elsif ($p =~ /^($feff_params_regex)$/) { # feff calc parameters
    my $ff = $self->feff;
    return $f->{$ff}->{$p} || 0;

  } elsif (($self->type eq 'path') and
	   ($p =~ /^($path_params_regex)$/)) {		# this is a path parameter
    return $self->{$p} || "";

  } else {			# else return this parameter
    return $self->{$p} || 0;
  };
};



## tidy up values for a group
sub fix_values {
  my $self = shift;

  ## make sure kmax and kmin are rational
  $self -> dispose("___x = ceil(" . $self->{group} . ".k)");
  my $maxk = Ifeffit::get_scalar("___x");
  ($self->{kmax}  = $maxk) if ($self->{kmax} == 0);
  ($self->{kmax} += $maxk) if ($self->{kmax} <  0);
  (($self->{kmin}, $self->{kmax}) = ($self->{kmax}, $self->{kmin})) if
    ($self->{kmin} > $self->{kmax});
  (($self->{rmin}, $self->{rmax}) = ($self->{rmax}, $self->{rmin})) if
    ($self->{rmin} > $self->{rmax});
};


## Script writing methods


## args:  $index: path index; $pathto: directory containing feff calc
##        $extpp: boolean, using extended path params?
##        $stash_dir: stash directory
sub write_path {
  my $self = shift;
  my ($index, $pathto, $extpp, $stash_dir) = @_;
  my $nnnn = File::Spec->catfile($pathto,$self->{feff});
  my $stash = $nnnn;		# deal with very long file names
  if (length($stash) > 127) {
    my $dir = File::Spec->catfile($stash_dir, $self->{parent});
    (-d $dir) or mkpath $dir;
    my $new = File::Spec->catfile($dir, $self->{feff});
    copy($stash, $new);
    $stash = $new;
  };
  my $string = "## Path #$index\n";
  if ($stash ne $nnnn) {
    $string .= "## actual path file: $nnnn\n";
    $string .= "## transfered to stash file: $stash\n";
  };
  my $prefix = "path($index, ";
  my @cleanup = ();
  $string .= $prefix . sprintf("label = \"%s\")\n", $self->{label}||$self->{lab});
    ##unless ($self->{label} =~ /^\s*$/);
  foreach (qw(feff deg S02 E0 delR sigma^2 Ei 3rd 4th dphase k_array phase_array amp_array)) {
    next if ((not $extpp) and ($_ =~ /(dphase|(amp|k|phase)_array)/));
    push(@cleanup,lc($_)), next if ($self->{lc($_)} =~ /^\s*$/);
    my $pp = lc($_);
    ($pp eq 'sigma^2') and ($pp = 'sigma2');
    ($pp eq '3rd')     and ($pp = 'third');
    ($pp eq '4th')     and ($pp = 'fourth');
    my $arg = ($pp eq 'deg') ? 'degen' : $pp;
    if ($_ eq 'feff') {
      $string .= $prefix . sprintf("%s = \"%s\")\n", $pp, $stash);
    } else {
      $string .= $prefix . sprintf("%s = %s)\n", $arg, $self->{lc($_)});
    };
  };
  $string .= $prefix . "force_read = true)\n";
  ## make sure that math expressions from previous evaluations of this
  ## path that are not used in the current evaluation are left lying
  ## around in Ifeffit's memory
  if (@cleanup) {
    $string .= "path($index";
    map {my $pp=$_;
	 ($pp eq 'sigma^2') and ($pp = 'sigma2');
	 ($pp eq '3rd')     and ($pp = 'third');
	 ($pp eq '4th')     and ($pp = 'fourth');
	 $string .= ", $pp=0"
       } @cleanup;
    $string .= ")\n";
  };
  ##$string .= "     )\n";
  return $string;
};


## @indeces_used is a table of back references for the datum in
## fit_index.  the idea is to keep track of which indeces have been
## used and what the next available one is.
sub index {
  my $self = shift;
  @indeces_used = ('^^placeholder^^') if ($#indeces_used==-1);
  my $old = $self->{fit_index} || 0;
  if ($old and ($old <= $#indeces_used)) { # @indeces_used and fit_index agree
    return $old if ($indeces_used[$old] eq $self->{id});
  };
  foreach my $i (1 .. $#indeces_used) {	# they disagree, use @indeces_used
    $self->make(fit_index=>$i), return $i if ($indeces_used[$i] eq $self->{id});
  };
  my $new = $#indeces_used + 1;	# need to assign a new one
  $indeces_used[$new] = $self->{id};
  $self->make(fit_index=>$new);
  return $new;
};

## a path and group has been deleted, splice it out of @indeces_used
sub drop {
  my $self = shift;
  my $dropit = 0;
  foreach my $i (1 .. $#indeces_used) {
    $dropit = $i, last if ($indeces_used[$i] eq $self->{id});
  };
  splice @indeces_used, $dropit, 1;
};

## we have just deleted a project and need to start counting paths
## from scratch
sub drop_all { $#indeces_used = 0 };


sub erase {
  my $self = shift;
  return $self->blank_path;
};

sub blank_path {
  my $self = shift;
  return "" unless ($self->{type} eq 'path');
  return "" unless ($self->{fit_index});
  return "erase \@path $self->{fit_index}\n";
  ##   my $string = "index=$self->{fit_index}";
  ##   foreach (qw(feff label degen s02 e0 delr sigma2 ei third fourth dphase
  ## 	      k_array phase_array amp_array)) {
  ##     $string .= ", $_=\"\"";
  ##   };
  ##   $string .= ")";
  ##   $string  = wrap("path(", "     ", $string);
  ##   return "## unsetting path $self->{fit_index}\n" . $string;
};


## get rid of all $dataN_title_MM strings
sub delete_titles {
  my $self = shift;
  my $group = $self->{group};
  ifeffit("show \@strings\n");
  my ($lines, @response) = (Ifeffit::get_scalar('&echo_lines')||0, ());
  if ($lines) {
    map {push @response, Ifeffit::get_echo()} (1 .. $lines);
  };
  foreach (@response) {
    $self -> dispose("erase $1") if (/^\s*(\$data\d+_title_\d+)/);
  };
};

## macros???
sub write_feffit {
  my $self = shift;
  my ($indeces, $iset, $nsets, $restraints) = @_;;
  ($indeces eq "1-1") and ($indeces="1");
  my $group = $self->{group};
  my ($string, $dispose) = ("","");
  my $chi = "$group.chi";
  $string .= "feffit($indeces, group=${group}_fit, chi=$chi, k=$group.k, ";

  ## determine all the k-weights to use
  my @weights = map {sprintf "kweight=%.2f", $_} ($self->group_weights);
  $string .= join(", ", @weights) . ", ";
  foreach (qw(rmin rmax kmin kmax dk kwindow fit_space do_bkg)) {
    next if ($self->get($_) =~ /^\s*$/);
    $string .= " $_=".$self->get($_).",";
  };
  $string .= " data_set=$iset, data_total=$nsets, ";
  if ($self->{epsilon_k} and ($self->{epsilon_k} > 0)) {
    ($string .= "epsilon_k=$self->{epsilon_k}, ");
  };
  $string .= $restraints;
  $string =~ s/,\s*$/\)/;
  $string = wrap("", "       ", $string) . $/;
  return $dispose.$string;
  ##return $str.$dispose.$string;
};

sub write_ff2chi {
  my $self = shift;
  my $indeces = $_[0];
  my $group = $self->{group};
  my $out = $_[1] || $group.'_fit';
  my $string = "ff2chi($indeces, group=$out,";
  ##   foreach (qw(kmin kmax)) {
  ##     next if ($self->{$_} =~ /^\s*$/);
  ##     $string .= " $_=$self->{$_},";
  ##   };
  $string =~ s/,$/\)/;
  $string = wrap("", "       ", $string) . $/;
  return $string;
};

sub write_fft {
  my $self = shift;
  my $r_paths = $self->{family};
  my $kw = $_[0] || $self->default_k_weight;
  my $rout = $_[1] || 10;
  my $group = $self->{group};
  #($self = $$r_paths{$self->{sameas}}) if ($self->{sameas} and ($self->type ne 'fit'));
  #($self = $$r_paths{$self->{data}})   if ($self->{data});
  my $string = "($group.chi, k=$group.k, ";
  foreach (qw(kmin kmax dk kwindow)) {
    $string   .= "$_=".$self->get($_).", ";
  };
  $string .= "kweight=$kw, rmax_out=$rout, ";
  ##   ($self->{pcpath} eq "Yes") and
  ##     ($string .=
  ##      ", pc_edge=\"" . lc($self->{pcelem}) . " " . lc($self->{pcedge}) . "\", pc_caps=1");
  if ($self->get('pcpath') ne "None") {
    my $pcp  = $$r_paths{$self->get('pcpath')}->{fit_index};
    $string .= "pc_feff_path=$pcp, ";
  };
  $string =~ s/, $/\)\n/;
  $string = wrap("fftf", "     ", $string);
  return $string;
};

sub write_bft {
  my $self = shift;
  my $r_paths = $self->{family};
  my $group = $self->{group};
  #($self = $$r_paths{$self->{sameas}}) if ($self->{sameas} and ($self->type ne 'fit'));
  #($self = $$r_paths{$self->{data}})   if ($self->{data});
  my $string = "(real=$group.chir_re, imag=$group.chir_im, ";
  foreach (qw(rmin rmax dr rwindow)) {
    $string   .= "$_=".$self->get($_).", ";
  };
  $string =~ s/, $/\)\n/;
  $string = wrap("fftr", "     ", $string);
  return $string;
};

sub chi_noise {
  my $self = shift;
  my $r_paths = $self->{family};
  my $group = $self->{group};
  ($self->{sameas}) and ($self = $$r_paths{$self->{sameas}});
  ($self->{data})   and ($self = $$r_paths{$self->{data}});
  my $string = "($group.chi, k=$group.k, ";
  foreach (qw(kmin kmax dk kwindow)) {
    $string   .= "$_=$self->{$_}, ";
  };
  my $kw = $_[1] || $self->default_k_weight;
  $string .= "kweight=$kw, ";
  $string =~ s/, $/\)\n/;
  $string = wrap("chi_noise", "          ", $string);
  $self->dispose($string);
  return (Ifeffit::get_scalar("epsilon_k"),
	  Ifeffit::get_scalar("epsilon_r"),
	  Ifeffit::get_scalar("kmax_suggest"),
	 );
};

## Plotting methods

# sub plot_E {
#   my $self = shift;

# };

sub plot_k {
  my $self = shift;
  my ($list, $r_pf, $r_extra, $stash_dir) = @_;
  my $r_paths = $self->{family};

  my $w = $$r_pf{kweight};

  ## plotting flags
  my $do_win = $$r_pf{win};	# plot the window function
  my $do_bkg = $$r_pf{bkg};	# plot the background for each selected fit
  my $do_res = $$r_pf{res};	# plot the residual for each selected fit

  my ($indic_min, $indic_max) = (1000000, -1000000);
  my $indic_command = "## determine indicator boundaries\n";
  $indic_command   .= "set ind___min = 1000000\nset ind___max = -1000000\n";

  ## stacking
  my $stack = ($$r_extra[0]) ? $$r_extra[1] : 0;
  my $stack_delta = ($$r_extra[0]) ? $$r_extra[2] : 0;

  ## MDS offset (over-rides stacking)
  my $ds_delta  = $$r_extra[3];
  my $ds_offset = -1 * $ds_delta;
  ($stack, $stack_delta) = (0,0) if $ds_offset;

  my $data = $self->data;
  $data = $$r_paths{$data};
  ($w eq 'w') and ($w = $data->default_k_weight());

  my ($plot, $indent) = ("newplot", "        ");
  my @p = $list -> info('selection');
  ##print "in plot_k: ", join(" ", @p), $/;
  my %hash;
  my ($key, $style, $n);
  my $i = -1;
  my $set = $self->data;	# identify this data
  $set = $$r_paths{$set}->descriptor;

  my $command = '';
  foreach my $p (@p) {
    next if ($p eq 'gsd');
    next if ($p =~ /feff\d+$/);
    next if (($p =~ /feff\d+\.\d+/) and not $$r_paths{$p}->{include});
    next if (($$r_paths{$p}->{type} eq 'data') and (not -e $$r_paths{$p}->{file}));
    my $group = pathgroup($p, $r_paths);
    next unless $group;

    my $data = $p;
    $data = $$r_paths{$p}->{data}   if ($$r_paths{$p}->{type} =~ /(feff|path)/);
    $data = $$r_paths{$p}->{sameas} if ($$r_paths{$p}->{type} =~ /(bkg|diff|fit|res)/);
    $data = $$r_paths{$data};
    $w = $$r_pf{kweight};
    ($w = $data->default_k_weight()) if ($w eq 'kw');

    ($ds_offset += $ds_delta) if ($$r_paths{$p}->type eq 'data');

    ## bring this path up to date for current plot
    ## what about multiple feff calcs and indeces?????
    #($$r_paths{$_}->{do_k}) and do {
    #  $$r_paths{$_}->{do_k} = 0;
    if ($$r_paths{$p}->{type} eq 'path') {
      #my $n = $1 + 1;
      my $ii = $$r_paths{$p}->index;
      my $parent = $$r_paths{$p}->{parent};
      my $pathto = $$r_paths{$parent}->{path};
      $command .= $$r_paths{$p} -> write_path($ii, $pathto, 0, $stash_dir);
      $command .= "ff2chi($ii, group=$group)\n";
    } elsif (($$r_paths{$p}->{type} eq 'fit') and $$r_paths{$p}->{parent}) {

      ## this is a fit, but not the parent of the fit branch
      unless ($$r_paths{$p}->get('imported')) {
	## read this fit into its group if it has not already been imported
	$command .= "read_data(file=\"" .
	  $$r_paths{$p}->get('fitfile') .
	    "\",\n" .
	      "          type=chi, group=". $$r_paths{$p}->get('group') . ")\n";
	$$r_paths{$p}->make(imported=>1);
      };
      ## bkg plot has been requested
      if (($do_bkg) and (-e $$r_paths{$p}->get('bkgfile'))) {
	unless ($$r_paths{$p}->get('imported_bkg')) {
	  (my $gr = $$r_paths{$p}->get('group')) =~ s/fit/bkg/;
	  ## read this fit into its group if it has not already been imported
	  $command .= "read_data(file=\"" .
	    $$r_paths{$p}->get('bkgfile') .
	      "\",\n          type=chi, group=$gr)\n";
	  $$r_paths{$p}->make(imported_bkg=>1);
	};
      };
      ## residual plot has been requested
      if ($do_res) {
	unless ($$r_paths{$p}->get('imported_res')) {
	  (my $gr = $$r_paths{$p}->get('group')) =~ s/fit/res/;
	  ## read this fit into its group if it has not already been imported
	  $command .= "read_data(file=\"" .
	    $$r_paths{$p}->get('resfile') .
	      "\",\n          type=chi, group=$gr)\n";
	  $$r_paths{$p}->make(imported_res=>1);
	};
      };
    };
    #};
    $key = $$r_paths{$p}->{lab};
    ##($_ =~ /^feff(\d+)\.(\d+)/) and ($n = $1+1) and ($key = sprintf("%4.4d", $2+1));
    if ($p =~ /feff(\d+)\.(\d+)/) {
      my $f = $$r_paths{$p}->{parent};
      $f = $$r_paths{$f}->{lab};
      $f =~ s/FEFF(\d+)/$1/;
      my $pa = $$r_paths{$p}->{lab};
      $pa =~ s/feff0?//;
      $pa =~ s/\.dat//;
      $key = "$f/$pa";
    };

  STYLE: {
      ($style = $$r_pf{datastyle}), last STYLE if ($$r_paths{$p}->{type} eq 'data');
      ($style = $$r_pf{fitstyle}),  last STYLE if ($$r_paths{$p}->{type} eq 'fit');
      ($style = $$r_pf{partsstyle});
    };

    ++$i;
    $i = $i % 10;
    my ($ytext, $ylabel);
    if ($w == 0) {
      $ytext = "\"" . join('.', $group, 'chi') . "\"";
      $ylabel = '\\gx(k)'
    } elsif ($w == 1) {
      $ytext = "\"" . join('.', $group, 'k') . '*' . join('.', $group, 'chi') . "\"";
      $ylabel = 'k\\gx(k)';
    } else {
      $ytext = "\"" . join('.', $group, 'k') . "^$w*" . join('.', $group, 'chi') . "\"";
      $ylabel = 'k\\u' . $w . '\\d\\gx(k)';
    };
    $stack -= $stack_delta if ($$r_paths{$p}->{type} eq 'fit');
    my $stst = $stack + $ds_offset;
    (my $yyy = $ytext) =~ s/\"$/+$stst\"/;
    %hash = (plot      => $plot,
	     'x'       => join('.', $group, 'k'),
	     'y'       => $yyy,
	     xlabel    => '"k (\\A\\u-1\\d)"',
	     ylabel    => $ylabel,
	     fg	       => $$r_pf{fg},
	     bg	       => $$r_pf{bg},
	     grid      => $$r_pf{showgrid},
	     gridcolor => $$r_pf{grid},
	     xmin      => $$r_pf{kmin},
	     xmax      => $$r_pf{kmax},
	     style     => $style,
	     color     => "\"" . $$r_pf{'c'.$i} . "\"",
	     key       => $key,
	     title     => "\"\'$set\' in k space\"");
    my $this = plotstring(\%hash);
    $this = wrap("", $indent, $this);
    $command .= $this;
    ($plot, $indent) = ('plot', "     ");

    ## determine indicator boundries
    #$indic_command .= "set i___ndic.x = $hash{'x'}\n";
    $indic_command .= "set i___ndic.y = $hash{'y'}\n";
    $indic_command .= "set ind___min = min(ind___min, 1.05*floor(i___ndic.y))\n";
    $indic_command .= "set ind___max = max(ind___max, 1.05* ceil(i___ndic.y))\n";

    $stack += $stack_delta;


    ## A fit has been selected AND bkg and/or res have been requested
    if (($$r_paths{$p}->{type} eq 'fit') and $$r_paths{$p}->{parent}) {
      if (($do_bkg) and (-e $$r_paths{$p}->get('bkgfile'))) {
	(my $gr = $group) =~ s/fit/bkg/;
	++$i;
	$i = $i % 10;
	(my $this_ytext = $ytext) =~ s/$group/$gr/g;
	$stack -= $stack_delta if ($$r_paths{$p}->{type} eq 'fit');
	$stst = $stack + $ds_offset;
	(my $yyy = $this_ytext) =~ s/\"$/+$stst\"/;
	%hash = (plot      => 'plot',
		 'x'       => join('.', $gr, 'k'),
		 'y'       => $yyy, #$this_ytext,
		 xlabel    => '"k (\\A\\u-1\\d)"',
		 ylabel    => $ylabel,
		 fg	   => $$r_pf{fg},
		 bg	   => $$r_pf{bg},
		 grid      => $$r_pf{showgrid},
		 gridcolor => $$r_pf{grid},
		 xmin      => $$r_pf{rmin},
		 xmax      => $$r_pf{rmax},
		 style     => $style,
		 color     => "\"" . $$r_pf{'c'.$i} . "\"",
		 key       => 'Bkg for '.$$r_paths{$p}->short_descriptor,
		 title     => "\"\'$set\' in k space\"");
	my $this = plotstring(\%hash);
	$this = wrap("", $indent, $this);
	$command .= $this;
	$stack += $stack_delta;
      };
      if ($do_res) {
	(my $gr = $group) =~ s/fit/res/;
	++$i;
	$i = $i % 10;
	(my $this_ytext = $ytext) =~ s/$group/$gr/g;
	$stst = $stack + $ds_offset;
	(my $yyy = $this_ytext) =~ s/\"$/+$stst\"/;
	%hash = (plot      => 'plot',
		 'x'       => join('.', $gr, 'k'),
		 'y'       => $yyy,
		 xlabel    => '"k (\\A\\u-1\\d)"',
		 ylabel    => $ylabel,
		 fg	   => $$r_pf{fg},
		 bg	   => $$r_pf{bg},
		 grid      => $$r_pf{showgrid},
		 gridcolor => $$r_pf{grid},
		 xmin      => $$r_pf{rmin},
		 xmax      => $$r_pf{rmax},
		 style     => $style,
		 color     => "\"" . $$r_pf{'c'.$i} . "\"",
		 key       => 'Resid for '.$$r_paths{$p}->short_descriptor,
		 title     => "\"\'$set\' in R space\"");
	my $this = plotstring(\%hash);
	$this = wrap("", $indent, $this);
	$command .= $this;
	$stack += $stack_delta;
      };
    };

  };
  if ($do_win) {
    ++$i;
    $i = $i % 10;
    my ($group, $kmin, $kmax, $dk, $kwin) = ($self->{group},   $self->{kmin},
					     $self->{kmax},    $self->{dk},
					     $self->{kwindow});
    my $kw = ($$r_pf{kweight} eq 'kw') ? $self->default_k_weight() : $$r_pf{kweight};
    ($self->{do_r}) and  do {
      my $this = "$group.chi, k=$group.k, kweight=$kw, kmin=$kmin, kmax=$kmax, dk=$dk, kwindow=$kwin, rmax_out=$$r_pf{rmax_out})";
      $command .= wrap('fftf(', '     ', $this) . "\n";
      $self -> make(do_r=>0);
    };
    $self -> dispose("___x = ceil($group.chi*$group.k^$kw)", 1); # scale window to plot
    my $scale = $$r_pf{window_multiplier} * Ifeffit::get_scalar("___x");
    my $color = "\"" . $$r_pf{'c'.$i} . "\"";
    my $this = sprintf("plot(%s.k, %s.win*%f, style=lines, color=%s, key=window)",
		    $group, $group, $scale, $color);
    $this = wrap("", "     ", $this) . $/;
    $command .= $this;
  };

  if ($$r_extra[5]) {
    foreach my $i (7 .. $#{$r_extra}) {
      next unless (lc($$r_extra[$i]->[1]) =~ /[kq]/);
      my $val = $$r_extra[$i]->[2];
      next if ($val < 0);
      $indic_command .= $self->plot_vertical_line($val, "", 0, 0, 1)
    };
  };
  $$r_extra[6] = $indic_command;

  $last_plot_command = $command;
  return $command;
};

sub plot_R {
  my $self    = shift;
  my ($list, $r_pf, $r_extra, $stash_dir) = @_;
  my $r_paths = $self->{family};

  my ($indic_min, $indic_max) = (1000000, -1000000);
  my $indic_command = "## determine indicator boundaries\n";
  $indic_command   .= "set ind___min = 1000000\nset ind___max = -1000000\n";

  ## stacking
  my $stack = ($$r_extra[0]==2) ? $$r_extra[1] : 0;
  my $stack_delta = ($$r_extra[0]==2) ? $$r_extra[2] : 0;

  ## inverting
  my $invert = ($$r_pf{r_pl} =~ /m/) ? $$r_extra[4] : 0;
  ($invert = 0) if ($$r_extra[0]==2);

  ## MDS offset (over-rides stacking)
  my $ds_delta  = $$r_extra[3];
  my $ds_offset = -1 * $ds_delta;
  ($stack, $stack_delta) = (0,0) if $ds_offset;

  ## plotting flags
  my $do_win = $$r_pf{win};	# plot the window function
  my $do_bkg = $$r_pf{bkg};	# plot the background for each selected fit
  my $do_res = $$r_pf{res};	# plot the residual for each selected fit

  my ($plot, $indent) = ("newplot", "        ");
  my @p = $list -> info('selection');
  ##print ">>", join("|", @p), "<<\n";
  my %hash;
  my ($key, $style, $n);
  my $i = -1;
  my $set = $self->data;	# identify this data
  $set = $$r_paths{$set}->descriptor;

  my $command = '';
  my $data_window = 0;
  foreach my $p (@p) {
    next if ($p eq 'gsd');
    next if ($p =~ /feff\d+$/);
    ## change the next line to allow plotting excluded paths??? (+ the
    ## same in the other plot_ methods)
    next if (($$r_paths{$p}->type eq 'path') and not $$r_paths{$p}->{include});

    next if (($$r_paths{$p}->type eq 'data') and (not -e $$r_paths{$p}->{file}));

    my $group = pathgroup($p, $r_paths);
    next unless $group;
    ($p =~ /(\d+)_res$/) and $$r_paths{$p} -> make(do_k=>0, do_r=>0, do_q=>0);

    my $data = $$r_paths{$p}->data;
    $data = $$r_paths{$p}->get('id') if ($$r_paths{$p}->type eq 'fit');
    $data = $$r_paths{$data};
    my ($kmin, $kmax, $dk, $kwin) =
      ($data->get('kmin'), $data->get('kmax'), $data->get('dk'), lc($data->get('kwindow')));

    my $kw = ($$r_pf{kweight} eq 'kw') ? $data->default_k_weight() : $$r_pf{kweight};

    my $pcplot = "";
    if ($data->get('pcpath') ne "None") {
      my $pcp  = $$r_paths{$data->get('pcpath')}->{fit_index};
      ($pcplot = ", pc_feff_path=$pcp") if $pcp;
    };

    ($ds_offset += $ds_delta) if ($$r_paths{$p}->type eq 'data');

    ## bring this path up to date for current plot
    #($$r_paths{$p}->{do_k}) and do {
    #  $$r_paths{$p}->{do_k} = 0;

    if ($$r_paths{$p}->{type} eq 'path') {
      #my $n = $1 + 1;
      my $ii = $$r_paths{$p}->index;
      my $parent = $$r_paths{$p}->{parent};
      my $pathto = $$r_paths{$parent}->{path};
      $command .= $$r_paths{$p} -> write_path($ii, $pathto, 0, $stash_dir);
      $command .= "ff2chi($ii, group=$group)\n";
    } elsif (($$r_paths{$p}->{type} eq 'fit') and $$r_paths{$p}->{parent}) {
      ## this is a fit, but not the parent of the fit branch
      unless ($$r_paths{$p}->get('imported')) {
	## read this fit into its group if it has not already been imported
	$command .= "read_data(file=\"" .
	  $$r_paths{$p}->get('fitfile') .
	    "\",\n" .
	      "          type=chi, group=". $$r_paths{$p}->get('group') . ")\n";
	$$r_paths{$p}->make(imported=>1);
      };
      ## bkg plot has been requested
      if (($do_bkg) and (-e $$r_paths{$p}->get('bkgfile'))) {
	unless ($$r_paths{$p}->get('imported_bkg')) {
	  (my $gr = $$r_paths{$p}->get('group')) =~ s/fit/bkg/;
	  ## read this fit into its group if it has not already been imported
	  $command .= "read_data(file=\"" .
	    $$r_paths{$p}->get('bkgfile') .
	      "\",\n          type=chi, group=$gr)\n";
	  $$r_paths{$p}->make(imported_bkg=>1);
	};
      };
      ## residual plot has been requested
      if ($do_res) {
	unless ($$r_paths{$p}->get('imported_res')) {
	  (my $gr = $$r_paths{$p}->get('group')) =~ s/fit/res/;
	  ## read this fit into its group if it has not already been imported
	  $command .= "read_data(file=\"" .
	    $$r_paths{$p}->get('resfile') .
	      "\",\n          type=chi, group=$gr)\n";
	  $$r_paths{$p}->make(imported_res=>1);
	};
      };
    };

    my $suff = "chi";
    ## needs to be generalized for multiple data sets...
    my $window;
    if ($p =~ /data\d+$/) {
      $window = "kmin=$kmin, kmax=$kmax, dk=$dk, kwindow=$kwin";
      $data_window = 1;
    } elsif ($data_window != 1) {
      $window = "kmin=$kmin, kmax=$kmax, dk=$dk, kwindow=$kwin";
    } else {
      #$window = "altwindow=data0.win";
      $window = "kmin=$kmin, kmax=$kmax, dk=$dk, kwindow=$kwin";
    };
    my $thisun = "$group.$suff, k=$group.k, kweight=$kw, rmax_out=$$r_pf{rmax_out}, $window$pcplot)";
    my $fft_command = wrap('fftf(', '     ', $thisun);
    $command .= $fft_command . "\n";

    $key = $$r_paths{$p}->{lab};
  STYLE: {
      ($style = $$r_pf{datastyle}), last STYLE if ($$r_paths{$p}->{type} eq 'data');
      ($style = $$r_pf{fitstyle}),  last STYLE if ($$r_paths{$p}->{type} eq 'fit');
      ($style = $$r_pf{partsstyle});
    };
    #($p =~ /^feff(\d+)\.(\d+)/) and ($n = $1+1) and ($key = sprintf("%4.4d", $2+1));
    if ($p =~ /feff(\d+)\.(\d+)/) {
      my $f = $$r_paths{$p}->{parent};
      $f = $$r_paths{$f}->{lab};
      $f =~ s/FEFF(\d+)/$1/;
      my $pa = $$r_paths{$p}->{lab};
      $pa =~ s/feff0?//;
      $pa =~ s/\.dat//;
      $key = "$f/$pa";
    };
    ## foreach my $p (qw(r_env r_mag r_re r_im r_pha)) {
    ##   next if ($$r_pf{$p} =~ /^\s+$/);
    my $part = 0;
    my $ylabel = '';
  SWITCH: {
      ($part, $ylabel) =
	('chir_mag', sprintf("\"Env[\\gx(R)] (\\A\\u-%s\\d)\"", $kw+1)),
	  last SWITCH if ($$r_pf{r_pl} eq 'e');
      ($part, $ylabel) =
	('chir_mag', sprintf("\"|\\gx(R)| (\\A\\u-%s\\d)\"", $kw+1)),
	  last SWITCH if ($$r_pf{r_pl} eq 'm');
      ($part, $ylabel) =
	('chir_re', sprintf("\"Re[\\gx(R)] (\\A\\u-%s\\d)\"", $kw+1)),
	  last SWITCH if ($$r_pf{r_pl} eq 'r');
      ($part, $ylabel) =
	('chir_im', sprintf("\"Im[\\gx(R)] (\\A\\u-%s\\d)\"", $kw+1)),
	  last SWITCH if ($$r_pf{r_pl} eq 'i');
      ($part, $ylabel) =
	('chir_pha', sprintf("\"Phase[\\gx(R)] (\\A\\u-%s\\d)\"", $kw+1)),
	  last SWITCH if ($$r_pf{r_pl} eq 'p');
    };
    next unless $part;
    ++$i;
    $i = $i % 10;
    my $inv = "";
    ($inv = "-1*") if ($invert and ($$r_paths{$p}->type eq 'path'));
    $stack -= $stack_delta if ($$r_paths{$p}->{type} eq 'fit');
    my $stst = $stack + $ds_offset;
    %hash = (plot      => $plot,
	     'x'       => join('.', $group, 'r'),
	     'y'       => "\"$inv" . join('.', $group, $part) . "+$stst\"",
	     xlabel    => "\"R (\\A)\"",
	     ylabel    => $ylabel,
	     fg	       => $$r_pf{fg},
	     bg	       => $$r_pf{bg},
	     grid      => $$r_pf{showgrid},
	     gridcolor => $$r_pf{grid},
	     xmin      => $$r_pf{rmin},
	     xmax      => $$r_pf{rmax},
	     style     => $style,
	     color     => "\"" . $$r_pf{'c'.$i} . "\"",
	     key       => $inv.$key,
	     title     => "\"\'$set\' in R space\"");
    my $this = plotstring(\%hash);
    $this = wrap("", $indent, $this);
    $command .= $this;
    ($plot, $indent) = ('plot', "     ");

    ## determine indicator boundries
    #$indic_command .= "set i___ndic.x = $hash{'x'}\n";
    $indic_command .= "set i___ndic.y = $hash{'y'}\n";
    $indic_command .= "set ind___min = min(ind___min, 1.05*floor(i___ndic.y))\n";
    $indic_command .= "set ind___max = max(ind___max, 1.05* ceil(i___ndic.y))\n";

    $stack += $stack_delta;

    ## A fit has been selected AND bkg and/or res have been requested
    if (($$r_paths{$p}->{type} eq 'fit') and $$r_paths{$p}->{parent}) {
      if (($do_bkg) and (-e $$r_paths{$p}->get('bkgfile'))) {
	(my $gr = $group) =~ s/fit/bkg/;
	++$i;
	$i = $i % 10;
	$inv = "";
	($inv = "-1*") if $invert;
	$stack -= $stack_delta if ($$r_paths{$p}->{type} eq 'fit');
	$stst = $stack + $ds_offset;
	%hash = (plot      => 'plot',
		 'x'       => join('.', $gr, 'r'),
		 'y'       => "\"$inv" . join('.', $gr, $part) . "+$stst\"",
		 xlabel    => "\"R (\\A)\"",
		 ylabel    => $ylabel,
		 fg	   => $$r_pf{fg},
		 bg	   => $$r_pf{bg},
		 grid      => $$r_pf{showgrid},
		 gridcolor => $$r_pf{grid},
		 xmin      => $$r_pf{rmin},
		 xmax      => $$r_pf{rmax},
		 style     => $style,
		 color     => "\"" . $$r_pf{'c'.$i} . "\"",
		 key       => $inv.'Bkg for '.$$r_paths{$p}->short_descriptor,
		 title     => "\"\'$set\' in R space\"");
	my $this = plotstring(\%hash);
	$this = wrap("", $indent, $this);
	(my $this_fft = $fft_command) =~ s/$group/$gr/g;
	$command .= $this_fft . "\n";
	$command .= $this;
	$stack += $stack_delta;
      };
      if ($do_res) {
	(my $gr = $group) =~ s/fit/res/;
	++$i;
	$i = $i % 10;
	$stst = $stack + $ds_offset;
	%hash = (plot      => 'plot',
		 'x'       => join('.', $gr, 'r'),
		 'y'       => "\"" . join('.', $gr, $part) . "+$stst\"",
		 xlabel    => "\"R (\\A)\"",
		 ylabel    => $ylabel,
		 fg	   => $$r_pf{fg},
		 bg	   => $$r_pf{bg},
		 grid      => $$r_pf{showgrid},
		 gridcolor => $$r_pf{grid},
		 xmin      => $$r_pf{rmin},
		 xmax      => $$r_pf{rmax},
		 style     => $style,
		 color     => "\"" . $$r_pf{'c'.$i} . "\"",
		 key       => 'Resid for '.$$r_paths{$p}->short_descriptor,
		 title     => "\"\'$set\' in R space\"");
	my $this = plotstring(\%hash);
	$this = wrap("", $indent, $this);
	(my $this_fft = $fft_command) =~ s/$group/$gr/g;
	$command .= $this_fft . "\n";
	$command .= $this;
	$stack += $stack_delta;
      };
    };

    ## envelope plot  NOT QUITE RIGHT WITH OFFSETS
    if ($$r_pf{r_pl} eq 'e') { #($p eq 'r_env') {
      $hash{plot} = 'plot';
      $hash{'y'}    = '-1*'.$hash{'y'};
      $hash{key}    = '';
      my $this = plotstring(\%hash);
      $this = wrap("", $indent, $this);
      $command .= $this;
    };
  };
  if ($do_win) {
    ++$i;
    $i = $i % 10;
    my ($group, $kmin, $kmax, $dk, $kwin) = ($self->{group},   $self->{kmin},
					     $self->{kmax},    $self->{dk},
					     $self->{kwindow});
    my $kw = ($$r_pf{kweight} eq 'kw') ? $self->default_k_weight() : $$r_pf{kweight};
    my ($rmin, $rmax, $dr, $rwin) = ($self->{rmin}, $self->{rmax}, $self->{dr},
				     $self->{rwindow});
    my $this = "$group.chi, k=$group.k, kweight=$kw, kmin=$kmin, kmax=$kmax, dk=$dk, kwindow=$kwin, rmax_out=$$r_pf{rmax_out})";
    $this =  wrap('fftf(', '     ', $this) . "\n";
    $command .= $this;
    ## must have the chir_mag in memory now to compute $scale
    $self -> dispose($this, 1);    # $self -> make(do_r=>0);
    ($self->{do_q}) and  do {
      my $this = "real=$group.chir_re, imag=$group.chir_im, rmin=$rmin, rmax=$rmax, dr=$dr, rwindow=$rwin)";
      $command .= wrap('fftr(', '     ', $this) . "\n";
      $self -> make(do_q=>0);
    };
    $self -> dispose("___x = ceil($group.chir_mag)", 1); # scale window to plot
    my $scale = $$r_pf{window_multiplier} * Ifeffit::get_scalar("___x");
    my $color = "\"" . $$r_pf{'c'.$i} . "\"";
    $this = sprintf("plot(%s.r, %s.rwin*%f, style=lines, color=%s, key=window)",
		    $group, $group, $scale, $color);
    $this = wrap("", "     ", $this) . $/;
    $command .= $this;
  };

  if ($$r_extra[5]) {
    foreach my $i (7 .. $#{$r_extra}) {
      next unless (lc($$r_extra[$i]->[1]) eq 'r');
      my $val = $$r_extra[$i]->[2];
      next unless $val;
      next if ($val < 0);
      $indic_command .= $self->plot_vertical_line($val, "", 0, 0, 1)
    };
  };
  $$r_extra[6] = $indic_command;


  $last_plot_command = $command;
  return $command;
};


sub plot_q {                                #}
  my $self    = shift;
  my ($list, $r_pf, $r_extra, $stash_dir) = @_;
  my $r_paths = $self->{family};

  ## plotting flags
  my $do_win = $$r_pf{win};	# plot the window function
  my $do_bkg = $$r_pf{bkg};	# plot the background for each selected fit
  my $do_res = $$r_pf{res};	# plot the residual for each selected fit

  my ($indic_min, $indic_max) = (1000000, -1000000);
  my $indic_command = "## determine indicator boundaries\n";
  $indic_command   .= "set ind___min = 1000000\nset ind___max = -1000000\n";

  ## stacking
  my $do_stack = 0;
  ($do_stack = 1) if ($$r_extra[0]==2);
  ($do_stack = 1) if (($$r_pf{q_pl} =~ /[ir]/) and ($$r_extra[0]==1));
  my $stack = ($do_stack) ? $$r_extra[1] : 0;
  my $stack_delta = ($do_stack) ? $$r_extra[2] : 0;

  ## inverting
  my $invert = (($$r_pf{q_pl} =~ /m/) and ($$r_extra[4] == 2)) ? 1 : 0;
  ($invert = 0) if $do_stack;

  ## MDS offset (over-rides stacking)
  my $ds_delta  = $$r_extra[3];
  my $ds_offset = -1 * $ds_delta;
  ($stack, $stack_delta) = (0,0) if $ds_offset;

  ##   my $pcplot = ($self->{pcplot} eq "Yes") ?
  ##     ", pc_edge=\"" . lc($self->{pcelem}) . " " . lc($self->{pcedge}) . "\", pc_caps=1" :
  ##       "";
  my $pcplot = "";
  if ($self->get('pcpath') ne "None") {
    my $pcp  = $$r_paths{$self->get('pcpath')}->{fit_index};
    $pcplot = ", pc_feff_path=$pcp";
  };


  my ($plot, $indent) = ("newplot", "        ");
  my @p = $list -> info('selection');
  my %hash;
  my ($key, $style,$n);
  my $i = -1;
  my $set = $self->data;	# identify this data
  $set = $$r_paths{$set}->descriptor;

  my $command = '';
  my $data_kwindow = 0;
  my $data_rwindow = 0;
  foreach my $p (@p) {
    next if ($p eq 'gsd');
    next if ($p =~ /feff\d+$/);
    next if (($p =~ /feff\d+\.\d+/) and not $$r_paths{$p}->{include});
    ## next if (($p =~ /(\d+)_res$/) and (lc($self->{fit_space}) ne 'r'));
    next if (($$r_paths{$p}->{type} eq 'data') and (not -e $$r_paths{$p}->{file}));
    my $group = pathgroup($p, $r_paths);
    next unless $group;
    ($p =~ /(\d+)_res$/) and $$r_paths{$p} -> make(do_k=>0, do_r=>0, do_1=>0);

    my $data = $$r_paths{$p}->data;
    $data = $$r_paths{$p}->get('id') if ($$r_paths{$p}->type eq 'fit');
    $data = $$r_paths{$data};
    my ($kmin, $kmax, $dk, $kwin) =
      ($data->get('kmin'), $data->get('kmax'), $data->get('dk'), lc($data->get('kwindow')));
    my ($rmin, $rmax, $dr, $rwin) =
      ($data->get('rmin'), $data->get('rmax'), $data->get('dr'), lc($data->get('rwindow')));

    my $kw = ($$r_pf{kweight} eq 'kw') ? $self->default_k_weight() : $$r_pf{kweight};

    ($ds_offset += $ds_delta) if ($$r_paths{$p}->type eq 'data');

    ## bring this path up to date for current plot
    #($$r_paths{$_}->{do_k}) and do {
    #  $$r_paths{$_}->{do_k} = 0;
    if ($$r_paths{$p}->{type} eq 'path') {
      #my $n = $1 + 1;
      my $ii = $$r_paths{$p}->index;
      my $parent = $$r_paths{$p}->{parent};
      my $pathto = $$r_paths{$parent}->{path};
      $command .= $$r_paths{$p} -> write_path($ii, $pathto, 0, $stash_dir);
      $command .= "ff2chi($ii, group=$group)\n";
    } elsif (($$r_paths{$p}->{type} eq 'fit') and $$r_paths{$p}->{parent}) {
      ## this is a fit, but not the parent of the fit branch
      unless ($$r_paths{$p}->get('imported')) {
	## read this fit into its group if it has not already been imported
	$command .= "read_data(file=\"" .
	  $$r_paths{$p}->get('fitfile') .
	    "\",\n" .
	      "          type=chi, group=". $$r_paths{$p}->get('group') . ")\n";
	$$r_paths{$p}->make(imported=>1);
      };
      ## bkg plot has been requested
      if (($do_bkg) and (-e $$r_paths{$p}->get('bkgfile'))) {
	unless ($$r_paths{$p}->get('imported_bkg')) {
	  (my $gr = $$r_paths{$p}->get('group')) =~ s/fit/bkg/;
	  ## read this fit into its group if it has not already been imported
	  $command .= "read_data(file=\"" .
	    $$r_paths{$p}->get('bkgfile') .
	      "\",\n          type=chi, group=$gr)\n";
	  $$r_paths{$p}->make(imported_bkg=>1);
	};
      };
      ## residual plot has been requested
      if ($do_res) {
	unless ($$r_paths{$p}->get('imported_res')) {
	  (my $gr = $$r_paths{$p}->get('group')) =~ s/fit/res/;
	  ## read this fit into its group if it has not already been imported
	  $command .= "read_data(file=\"" .
	    $$r_paths{$p}->get('resfile') .
	      "\",\n          type=chi, group=$gr)\n";
	  $$r_paths{$p}->make(imported_res=>1);
	};
      };
    };
    #};
    my $window;
    my $suff = "chi";
    if ($p =~ /data\d+$/) {
      $window = "kmin=$kmin, kmax=$kmax, dk=$dk, kwindow=$kwin";
      $data_kwindow = 1;
    } elsif ($data_kwindow != 1) {
      $window = "kmin=$kmin, kmax=$kmax, dk=$dk, kwindow=$kwin";
    } else {
      #$window = "altwindow=data0.win";
      $window = "kmin=$kmin, kmax=$kmax, dk=$dk, kwindow=$kwin";
    };
    my $this = "$group.$suff, k=$group.k, kweight=$kw, rmax_out=$$r_pf{rmax_out}, $window$pcplot)";
    my $fft_command = wrap('fftf(', '     ', $this);
    $command .= $fft_command . "\n";
    if ($p =~ /data\d+$/) {
      $window = "rmin=$rmin, rmax=$rmax, dr=$dr, rwindow=$rwin";
      $data_rwindow = 1;
    } elsif ($data_rwindow != 1) {
      $window = "rmin=$rmin, rmax=$rmax, dr=$dr, rwindow=$rwin";
    } else {
      #$window = "altwindow=data0.rwin";
      $window = "rmin=$rmin, rmax=$rmax, dr=$dr, rwindow=$rwin";
    };
    $this = "real=$group.chir_re, imag=$group.chir_im, $window)";
    my $bft_command = wrap('fftr(', '     ', $this);
    $command .= $bft_command . "\n";

    $key = $$r_paths{$p}->{lab};
    if ($p =~ /^feff(\d+)\.(\d+)/) {
      my $f = $$r_paths{$p}->{parent};
      $f = $$r_paths{$f}->{lab};
      $f =~ s/FEFF(\d+)/$1/;
      my $pa = $$r_paths{$p}->{lab};
      $pa =~ s/feff0?//;
      $pa =~ s/\.dat//;
      $key = "$f/$pa";
    };

  STYLE: {
      ($style = $$r_pf{datastyle}), last STYLE if ($$r_paths{$p}->{type} eq 'data');
      ($style = $$r_pf{fitstyle}),  last STYLE if ($$r_paths{$p}->{type} eq 'fit');
      ($style = $$r_pf{partsstyle});
    };

    ## foreach my $p (qw(q_env q_mag q_re q_im q_pha)) {
      ## next if ($$r_pf{$p} =~ /^\s+$/);
    my $part = 0;
    my $ylabel = '';
  SWITCH: {
      ($part, $ylabel) =
	('chiq_mag', sprintf("\"Env[\\gx(q)] (\\A\\u-%s\\d)\"", $kw)),
	  last SWITCH if ($$r_pf{q_pl} eq 'e');
      ($part, $ylabel) =
	('chiq_mag', sprintf("\"|\\gx(q)| (\\A\\u-%s\\d)\"", $kw)),
	  last SWITCH if ($$r_pf{q_pl} eq 'm');
      ($part, $ylabel) =
	('chiq_re', sprintf("\"Re[\\gx(q)] (\\A\\u-%s\\d)\"", $kw)),
	  last SWITCH if ($$r_pf{q_pl} eq 'r');
      ($part, $ylabel) =
	('chiq_im', sprintf("\"Im[\\gx(q)] (\\A\\u-%s\\d)\"", $kw)),
	  last SWITCH if ($$r_pf{q_pl} eq 'i');
      ($part, $ylabel) =
	('chiq_pha', sprintf("\"Phase[\\gx(q)] (\\A\\u-%s\\d)\"", $kw)),
	  last SWITCH if ($$r_pf{q_pl} eq 'p');
    };
    next unless $part;
    my $inv = "";
    ($inv = "-1*") if ($invert and ($$r_paths{$p}->type eq 'path'));
    ++$i;
    $i = $i % 10;
    $stack -= $stack_delta if ($$r_paths{$p}->{type} eq 'fit');
    my $stst = $stack + $ds_offset;
    %hash = (plot      => $plot,
	     'x'       => join('.', $group, 'q'),
	     'y'       => "\"$inv" . join('.', $group, $part) . "+$stst\"",
	     xlabel    => "\"k (\\A\\u-1\\d)\"",
	     ylabel    => $ylabel,
	     fg	       => $$r_pf{fg},
	     bg	       => $$r_pf{bg},
	     grid      => $$r_pf{showgrid},
	     gridcolor => $$r_pf{grid},
	     xmin      => $$r_pf{qmin},
	     xmax      => $$r_pf{qmax},
	     style     => $style,
	     color     => "\"" . $$r_pf{'c'.$i} . "\"",
	     key       => $key,
	     title     => "\"\'$set\' in q space\"");
    $this = plotstring(\%hash);
    $this = wrap("", $indent, $this);
    $command .= $this;
    ($plot, $indent) = ('plot', "     ");

    ## determine indicator boundries
    #$indic_command .= "set i___ndic.x = $hash{'x'}\n";
    $indic_command .= "set i___ndic.y = $hash{'y'}\n";
    $indic_command .= "set ind___min = min(ind___min, 1.05*floor(i___ndic.y))\n";
    $indic_command .= "set ind___max = max(ind___max, 1.05* ceil(i___ndic.y))\n";

    $stack += $stack_delta;

    ## A fit has been selected AND bkg and/or res have been requested
    if (($$r_paths{$p}->{type} eq 'fit') and $$r_paths{$p}->{parent}) {
      if (($do_bkg) and (-e $$r_paths{$p}->get('bkgfile'))) {
	(my $gr = $group) =~ s/fit/bkg/;
	++$i;
	$i = $i % 10;
	$inv = "";
	($inv = "-1*") if ($invert and ($$r_paths{$p}->type eq 'path'));
	$stst = $stack + $ds_offset;
	%hash = (plot      => 'plot',
		 'x'       => join('.', $gr, 'r'),
		 'y'       => "\"$inv" . join('.', $gr, $part) . "+$stst\"",
		 xlabel    => "\"R (\\A)\"",
		 ylabel    => $ylabel,
		 fg	   => $$r_pf{fg},
		 bg	   => $$r_pf{bg},
		 grid      => $$r_pf{showgrid},
		 gridcolor => $$r_pf{grid},
		 xmin      => $$r_pf{rmin},
		 xmax      => $$r_pf{rmax},
		 style     => $style,
		 color     => "\"" . $$r_pf{'c'.$i} . "\"",
		 key       => 'Bkg for '.$$r_paths{$p}->short_descriptor,
		 title     => "\"\'$set\' in R space\"");
	my $this = plotstring(\%hash);
	$this = wrap("", $indent, $this);
	(my $this_fft = $fft_command) =~ s/$group/$gr/g;
	$command .= $this_fft . "\n";
	(my $this_bft = $bft_command) =~ s/$group/$gr/g;
	$command .= $this_bft . "\n";
	$command .= $this;
	$stack += $stack_delta;
      };
      if ($do_res) {
	(my $gr = $group) =~ s/fit/res/;
	++$i;
	$i = $i % 10;
	$stst = $stack + $ds_offset;
	%hash = (plot      => 'plot',
		 'x'       => join('.', $gr, 'r'),
		 'y'       => "\"" . join('.', $gr, $part) . "+$stst\"",
		 xlabel    => "\"R (\\A)\"",
		 ylabel    => $ylabel,
		 fg	   => $$r_pf{fg},
		 bg	   => $$r_pf{bg},
		 grid      => $$r_pf{showgrid},
		 gridcolor => $$r_pf{grid},
		 xmin      => $$r_pf{rmin},
		 xmax      => $$r_pf{rmax},
		 style     => $style,
		 color     => "\"" . $$r_pf{'c'.$i} . "\"",
		 key       => 'Resid for '.$$r_paths{$p}->short_descriptor,
		 title     => "\"\'$set\' in R space\"");
	my $this = plotstring(\%hash);
	$this = wrap("", $indent, $this);
	(my $this_fft = $fft_command) =~ s/$group/$gr/g;
	$command .= $this_fft . "\n";
	(my $this_bft = $bft_command) =~ s/$group/$gr/g;
	$command .= $this_bft . "\n";
	$command .= $this;
	$stack += $stack_delta;
      };
    };

    ## envelope plot
    if ($$r_pf{q_pl} eq 'e') {
      $hash{plot} = 'plot';
      $hash{'y'}    = '-1*'.$hash{'y'};
      $hash{key}    = '';
      my $this = plotstring(\%hash);
      $this = wrap("", $indent, $this);
      $command .= $this;
    };

  };
  if ($do_win) {
    ++$i;
    $i = $i % 10;
    my ($group, $kmin, $kmax, $dk, $kwin) = ($self->{group},   $self->{kmin},
					     $self->{kmax},    $self->{dk},
					     $self->{kwindow});
    my $kw = ($$r_pf{kweight} eq 'kw') ? $self->default_k_weight() : $$r_pf{kweight};
##     ($self->{do_r}) and  do {
##       my $this = "$group.chi, kweight=$kw, kmin=$kmin, kmax=$kmax, dk=$dk, kwindow=$kwin)";
##       $command .= wrap('fftf(', '     ', $this) . "\n";
##       $self -> make(do_r=>0);
##     };
    $self -> dispose("___x = ceil($group.chi*$group.k^$kw)", 1); # scale window to plot
    my $scale = $$r_pf{window_multiplier} * Ifeffit::get_scalar("___x");
    my $color = "\"" . $$r_pf{'c'.$i} . "\"";
    my $this = sprintf("plot(%s.k, %s.win*%f, style=lines, color=%s, key=window)",
		    $group, $group, $scale, $color);
    $this = wrap("", "     ", $this) . $/;
    $command .= $this;
  };

  if ($$r_extra[5]) {
    foreach my $i (7 .. $#{$r_extra}) {
      next unless (lc($$r_extra[$i]->[1]) =~ /[kq]/);
      my $val = $$r_extra[$i]->[2];
      next if ($val < 0);
      $indic_command .= $self->plot_vertical_line($val, "", 0, 0, 1)
    };
  };
  $$r_extra[6] = $indic_command;

  $last_plot_command = $command;
  return $command;
};




## args are: x-position, y-range, plotting mode, key, yoffset, and
## newplot flag
sub plot_vertical_line {
  my $self = shift;
  my ($x, $key, $yoffset, $new, $style) = @_;
  ##my $delta = $ymax - $ymin;
  my ($line, $color) = ($default->{indicatorline}, $default->{indicatorcolor});
  #     ($style==1) ?
  #     ($default->{indicatorline}, $default->{indicatorcolor}) :
  #       ($default->{borderline}, $default->{bordercolor});
  my $command = "";
  $command .= "set ind___delta = ind___max-ind___min\n";
  $command .= "set v___ert.x = $x*ones(2)\n";
  $command .= "set v___ert.y = range(ind___min, ind___max, ind___delta)\n";
  if ($new) {
    $command .= "newplot(v___ert.x, \"v___ert.y+$yoffset\", key=\"$key\", style=$line, color=\"$color\")\n";
  } else {
    $command .= "plot(v___ert.x, \"v___ert.y+$yoffset\", key=\"$key\", style=$line, color=\"$color\")\n";
  };
  return $command;
};


sub floor_ceil {
  my ($x, $y, $rpf, $space) = @_;
  my ($ymin, $ymax, $i) = (1e10, -1e10, 0);
  foreach my $xx (@$x) {
    next if ($xx < $$rpf{$space.'min'});
    last if ($xx > $$rpf{$space.'max'});
    ($ymin = $$y[$i]) if ($$y[$i] < $ymin);
    ($ymax = $$y[$i]) if ($$y[$i] > $ymax);
    ++$i;
  };
  return sort ($ymin, $ymax);
};


## sub pathgroup {
##   my $self = shift;
##   ##$$r_paths{$g}->{group} and return $$r_paths{$g}->{group};
##   return 0 if (($g =~ /feff\d+\.\d+/) and not $self->{include});
##   return $g unless ($g =~ /(feff\d+)\.(\d+)/);
##   my $index = $$r_paths{$g}->index;
##   my $g_ = join("_", $1, "$index");
##   $$r_paths{$g}->{group} = $g_;
##   return $g_;
## };

sub pathgroup {
  my ($g, $r_paths) = @_;
  if ($g =~ /(data\d)\.(\d)$/) {
    return $1 . "_" . ("fit", "res", "bkg", "diff")[$2];
  };
  ##$$r_paths{$g}->{group} and return $$r_paths{$g}->{group};
  return 0 unless exists $$r_paths{$g};
  return 0 if (($g =~ /feff\d+\.\d+/) and not $$r_paths{$g}->{include});
  return $$r_paths{$g}->{group} if ($g =~ /data\d+\.\d\.\d+$/);
  return $g unless ($g =~ /(feff\d+)\.(\d+)/);
  my $index = $$r_paths{$g}->index;
  my $g_ = join("_", $1, "$index");
  $$r_paths{$g}->{group} = $g_;
  return $g_;
};


## return a sensible path list lable for this path
sub pathlabel {
  my $self = shift;
  my $pattern = $_[0] || 'Path %i [%p]';
  my $r_paths = $self->{family};
  return $self->{group} unless ($self->{type} eq 'path');

  my %table = (i   => sprintf("%d", substr($self->{feff},4,4)),
	       I   => sprintf("%4.4d", substr($self->{feff},4,4)),
	       p   => "",
	       r   => $self->get('reff'),
	       n   => $self->get('nleg'),
	       a   => $self->get('zcwif'),
	       d   => $self->get('deg'),
	       's' => "",
	       );

  ## find the %p token
  my $pathdesc = substr($self->{intrpline}, CORE::index($self->{intrpline}, ":")+2);
  my $core = substr($pathdesc, 0, CORE::index($self->{intrpline}, " "));
  ## escape metacharacters in the core token, then find all the stuff
  ## between the core tokens
  $core =~ s/([\\\.\^\$\*\+\?\{\}\[\]\(\)\|])/\\$1/g;
  $core =~ s/\s+$//;
  ($pathdesc = $1) if ($pathdesc =~ /$core(.*)$core/);
  $pathdesc =~ s/^\s+//;
  $pathdesc =~ s/\s+$//;
  $table{p} = $pathdesc;

  ## flag special paths
  ($self->{is_ss}  = 1) if ($self->{nleg} == 2);
  ($self->{is_col} = 1) if ($self->{intrpline} =~ /\d :/);

  ## find the %s token
  ($table{'s'} = 'SS')   if $self->{is_ss};
  ($table{'s'} = 'col.') if $self->{is_col};

  $pattern =~ s/\%([adinprsI])/$table{$1}/g;

  ## deal with an ambiguous label (perhaps from a poor pattern,
  ## perhaps from a path clone)
  my $suff = 0;
  foreach my $k (sort (keys %$r_paths)) {
    next unless (exists $$r_paths{$k}->{type});
    next unless ($$r_paths{$k}->{type} eq 'path');
    next unless ($self->{parent} eq $$r_paths{$k}->{parent});
    ## are these in the same feff calc?
    next unless ($$r_paths{$k}->{parent} eq $self->{parent});
    #print "skipping self\n",
    next if ($k eq $self->{id});

    ## escape the pattern
    (my $patt = $pattern) =~ s/([\\\.\^\$\*\+\?\{\}\[\]\(\)\|])/\\$1/g;
    if ($$r_paths{$k}->{lab} =~ /^$patt\s*:\s*(\d+)/) {
      ($suff = $1+1); # if ($1 >= $suff);
    } elsif ($$r_paths{$k}->{lab} eq $pattern) {
      $suff ||= 1;
    };
  };

  ## finally return the label
  $self->{lab} = ($suff) ? $pattern . " : $suff" : $pattern;
};


sub pathstate {
  my $self = shift;
  my $state;
  if ($_[0]) {
    $state = $_[0];
  } else {
    $state = ($self->get('include')) ? "enabled" : "disabled";
  };
  ($state .= "_ss")  if $self->{is_ss};
  ($state .= "_col") if $self->{is_col};
  ##print $state, $/;
  return $state;
};


sub intrpline {
  my $self = shift;
  return "" unless ($self->type eq "path");
  my $parent = $self->get("parent");
  foreach my $l (split(/\n/, $self->{family}->{$parent}->get('intrp'))) {
    my $ss = substr($self->{file},4,4);
    return substr($l, 2) if ($l =~ /^\d\s+$ss/);
  };
  return "";
};

sub plotstring {
  my $rh = $_[0];
  my $string = $$rh{plot} . "(";
  $string .= $$rh{'x'} . ', ' . $$rh{'y'} . ', ';
  if ($$rh{plot} eq 'newplot') {
    foreach (qw(xlabel ylabel fg bg grid gridcolor xmin xmax style color key title)) {
      #next unless $$rh{$_};
      if ($_ eq 'grid') {
	$string .= ($$rh{grid}) ? 'grid, ' : 'nogrid, ';
      } elsif ($_ eq 'gridcolor') {
	$string .= "gridcolor=\"$$rh{gridcolor}\", " if $$rh{grid};
      } elsif ($_ eq 'key') {
	$string .= "key=\"$$rh{key}\", ";
      } else {
	$string .= $_ . "=$$rh{$_}, ";
      };
    };
  } else {
    foreach (qw(style color key)) {
      next unless $$rh{$_};
      if ($_ eq 'key') {
	$string .= "key=\"$$rh{key}\", ";
      } else {
	$string .= $_ . "=$$rh{$_}, ";
      };
    };
  };
  $string =~ s/, $/\)\n/;
  return $string;
};


sub descriptor {
  my $self = shift;
  my $r_paths = $self->{family};
 SWITCH: {
    ($self->{type} eq 'gsd') and do {
      return "Guess, Def, Set";
      last SWITCH;
    };
    ($self->{type} eq 'data') and do {
      return $self->{lab};
      last SWITCH;
    };
    ($self->{type} eq 'fit') and do {
      return join(": ", $$r_paths{$self->{sameas}}->{lab}, $self->{lab});
      last SWITCH;
    };
    ($self->{type} eq 'bkg') and do {
      return join(": ", $$r_paths{$self->{sameas}}->{lab}, $self->{lab});
      last SWITCH;
    };
    ($self->{type} eq 'res') and do {
      return join(": ", $$r_paths{$self->{sameas}}->{lab}, $self->{lab});
      last SWITCH;
    };
    ($self->{type} eq 'diff') and do {
      return join(": ", $$r_paths{$self->{sameas}}->{lab}, $self->{lab});
      last SWITCH;
    };
    ($self->{type} eq 'feff') and do {
      return join(": ", $$r_paths{$self->{data}}->{lab}, $self->{lab});
      last SWITCH;
    };
    ($self->{type} eq 'path') and do {
      return join(": ", $$r_paths{$self->{parent}}->{lab}, $self->{lab});
      last SWITCH;
    };
  };
  return $self->{lab} || "";
};

sub short_descriptor {
  my $self = shift;
  my $r_paths = $self->{family};
 SWITCH: {
    ($self->{type} eq 'gsd') and do {
      return "GDS";
      last SWITCH;
    };
    ($self->{type} eq 'data') and do {
      return 'data';
      last SWITCH;
    };
    (($self->{type} eq 'fit') and $self->{parent}) and do {
      return 'fit';
      last SWITCH;
    };
    ($self->{type} eq 'fit') and do {
      return 'fit';
      last SWITCH;
    };
    ($self->{type} eq 'bkg') and do {
      return 'bkg';
      last SWITCH;
    };
    ($self->{type} eq 'res') and do {
      return 'resid';
      last SWITCH;
    };
    ($self->{type} eq 'diff') and do {
      return 'diff';
      last SWITCH;
    };
    ($self->{type} eq 'feff') and do {
      my $this = $self->{id};
      return (split(/\./, $this))[1];
      last SWITCH;
    };
    ($self->{type} eq 'path') and do {
      ## note that this is similar to the plot key
      my $f = $self->{parent};
      $f = $$r_paths{$f}->{id};
      $f = (split(/\./, $f))[1];
      my $pa = $self->{lab};
      $pa =~ s/feff0?//;
      $pa =~ s/\.dat//;
      my $key = "${f}_$pa";
      $key =~ s/\s+//;
      return $key;
      last SWITCH;
    };
  };
  return $self->{lab} || "";
};


sub param_summary {
  my $self = shift;
  my $pkw  = shift;
  my $rp   = $self->{family};
  my $this = $self;
  $this = $$rp{$this->data};
  ## ($this = $$rp{$self->{sameas}}) if (exists $$rp{$self->{sameas}});
  ## ($this = $$rp{$self->{data}})   if (exists $$rp{$self->{data}});
  my $text = "";
  $text .= "Fitting parameters:\n";
  my @kw = ();
  push @kw, "1" if $this->{k1};
  push @kw, "2" if $this->{k2};
  push @kw, "3" if $this->{k3};
  push @kw, $this->{karb} if $this->{karb_use};
  push @kw, "1" unless @kw;
  $text .= sprintf("-  k-range: [ %.3f : %.3f ]   dk=%.2f
-  R-range: [ %.3f : %.3f ]   dR=%.2f
-  kweight=%s   k-window=%s   R-window=%s
-  fit space=%s     fit background: %s
-  phase correction: %s
-  plotting kweight=%s
-
",
		   $this->{kmin}, $this->{kmax}, $this->{dk},
		   $this->{rmin}, $this->{rmax}, $this->{dr},
		   join(",", @kw), $this->{kwindow}, $this->{rwindow},
		   $this->{fit_space},
		   ((lc($this->{do_bkg}) eq 'yes') ? 'yes' : 'no'),
		   $this->{pcpath}, $pkw,
		   );
};


## look for FEFF.INP, Feff.Inp, and Feff.inp if feff.inp is not found
sub verify_feffinp {
  my $self = shift;
  my $feffinp = $self->{'feff.inp'};
  #print $self->{lab}, "0:  ", $feffinp, $/;
  if (not -e $feffinp) {	# did not find feff.inp,
				# look for FEFF.INP
    my $fi = uc(basename($feffinp));
    $feffinp = File::Spec->catfile(dirname($feffinp), $fi);
    #print $self->{lab}, "1:  ", $feffinp, $/;
  };
  if (not -e $feffinp) {	# did not find FEFF.INP
				# look for Feff.Inp
    my $fi = basename($feffinp);
    my @parts = map { ucfirst $_ } (split(/\./, $fi));
    $fi = join(".", @parts);
    $feffinp = File::Spec->catfile(dirname($feffinp), $fi);
    #print $self->{lab}, "2:  ", $feffinp, $/;
  }
  if (not -e $feffinp) {	# did not find Feff.Inp
				# look for Feff.inp
    my $fi = basename($feffinp);
    my @parts = split(/\./, $fi);
    $fi = join(".", ucfirst($parts[0]), lc($parts[1]));
    $feffinp = File::Spec->catfile(dirname($feffinp), $fi);
    #print $self->{lab}, "3:  ", $feffinp, $/;
  }
  if (not -e $feffinp) {	# did not find Feff.inp
				# give up, reset to feff.inp
    $feffinp = $self->{'feff.inp'};
  };
  #print $self->{lab}, "4:  ", $feffinp, $/;
  $self->make('feff.inp' => $feffinp);
};

## this function reads feff.inp, files.dat, and paths.dat to present
## an easily digestable summary of the feff calculation
sub intrp {
  my $self = shift;
  return 0 unless ($self->{type} eq 'feff');
  $self->{edge} = "K";
  my %label;
  my @title;

  my %intrp_data = (text        => "",
		    ntitle	=> 0,
		    switch	=> 0,
		    rmult	=> 1,
		    rmax	=> 1000,
		    maxr	=> 1000,	      # *
		    cwcrit	=> 2.5,		      # *
		    factor	=> 1000,
		    natom	=> 0,
		    central	=> "",
		    betamax     => $_[0] || 20,	      # *
		    minamp      => 0,		      # *
		    core_token	=> $_[1] || '[+]',);  # *
  my @potentials;

  ## need to read the potentials list so we have the element symbols
  ## as fallbacks for atoms tokens.  close FEFF when the potetial list
  ## if over ...
  open FEFF, $self->{'feff.inp'} or
    die "could not open $self->{'feff.inp'} for reading in intrp\n";
 FL: while (<FEFF>) {
    next if (/^\s*\*/);
    next if (/^\s*$/);
    if ( /^\s*poten/i ) {
      my $pot = "foo";
      while ($pot) {
	my $pot = <FEFF>;
	if ($pot =~ /^\s*\d/) {
	  my @line = split(" ", $pot);
	  $potentials[$line[0]] = get_symbol($line[1]);
	} elsif ($pot =~ /^\s*\w/) {
	  last FL;
	};
      };
    };
  };
  close FEFF;

  ## now we need to find the atomic coordinates of the absorber atom
  open FEFF, $self->{'feff.inp'} or
    die "could not open $self->{'feff.inp'} for reading in intrp\n";
  my $flag = 0;
  my @xyz = (0,0,0);
 FA: while (<FEFF>) {
    chomp;
    $flag = 1, next FA if (/^\s*ato/i);
    next FA unless $flag;
    next if (/^\s*\*/);
    next if (/^\s*$/);
    my @line = split(" ", $_);
    next FA unless ($line[3] == 0);
    @xyz = (@line[0..2]);
    last FA;
  };
  close FEFF;

  $intrp_data{central} = $potentials[0];
  $self->{central} = $intrp_data{central};
  ## and start over again at the top to fetch the hash of atomic positions
  open FEFF, $self->{'feff.inp'} or
    die "could not open $self->{'feff.inp'} for reading in intrp\n";
 FEFFLOOP: while (<FEFF>) {
    chomp;
    last if (/^\s*END/i);
    next FEFFLOOP if (/^\s*\*/);
    next FEFFLOOP if (/^\s*$/);
  SWITCH: {
      # reading atoms list
      ($intrp_data{switch}) and do {
	my ($x, $y, $z, $ipot, $tag) = split;
	#($ipot eq "0") and ($intrp_data{core_token} = $tag || '[+]');

	my $r = sqrt(($x-$xyz[0])**2 + ($y-$xyz[1])**2 + ($z-$xyz[2])**2);
	next FEFFLOOP if ($r > $intrp_data{rmax});
	my $key = round($intrp_data{rmult}*$intrp_data{factor}*($x-$xyz[0])) .
	          round($intrp_data{rmult}*$intrp_data{factor}*($y-$xyz[1])) .
	          round($intrp_data{rmult}*$intrp_data{factor}*($z-$xyz[2]));
	$label{$key} = $tag || $potentials[$ipot]; # use tag if there, else
	++$intrp_data{natom};	                   # use the atomic symbol
	last SWITCH;
      };
      # get crits
      ( /^\s*crit\s*[=,\s]\s*(-?(\d+\.?\d*|\.\d+))/i ) and do {
	$intrp_data{cwcrit} = $1;
	## $intrp_data{cwcrit} = (split( /[=,\s]+/ ))[2];
	last SWITCH;
      };
      # get edge
      (/^\s*(hole|edge)\s*[=,\s]\s*(\d{1,2}|k|l[123]|m[1-5])/i) and do {
	$intrp_data{edge} = $2; #(split( /[=,\s]+/ ))[2];
	($intrp_data{edge} = 'K')  if ($intrp_data{edge} eq 1);
	($intrp_data{edge} = 'L1') if ($intrp_data{edge} eq 2);
	($intrp_data{edge} = 'L2') if ($intrp_data{edge} eq 3);
	($intrp_data{edge} = 'L3') if ($intrp_data{edge} eq 4);
	$self->{edge} = $intrp_data{edge};
	last SWITCH;
      };
      # get title lines
      ( /^\s*title/i ) and do {
	chomp;
	$title[$intrp_data{ntitle}] = substr($_, 0, 69);
	++$intrp_data{ntitle};
	last SWITCH;
      };
      # beginning of atoms list
      ( /^\s*atom/i ) and do {
	$intrp_data{switch} = 1;
	last SWITCH;
      };
      # get rmax
      ( /^\s*r(max|path)\s*[=,\s]\s*(-?(\d+\.?\d*|\.\d+))/i )  and do {
	$intrp_data{rmax} = $2;
	## my @line = split( /[=,\s]+/ );
	## $intrp_data{rmax} = ($line[0] =~ (/r(max|path)/i)) ? $line[1] : $line[2];
	last SWITCH;
      };
      # need to apply rmult to correctly make tags
      # this will fail if RMULTIPLIER comes after the atoms list
      ( /^\s*rmult[a-z]*\s*[=,\s]\s*(-?(\d+\.?\d*|\.\d+))/i ) and do {
	$intrp_data{rmult} = $1;
	## my @line = split( /[=,\s]+/ );
	## $intrp_data{rmult} = ($line[0] =~ (/rmult/i)) ? $line[1] : $line[2];
	last SWITCH;
      };
    };
  };
  close FEFF;

  my (@fname, @sig2, @amp, @degen, @nleg, @reff);
  $intrp_data{switch} = 0;
  open FILES, $self->{'files.dat'} or
    die "could not open $self->{'files.dat'} for reading in intrp\n";
  while (<FILES>) {
    if ( /^\s*--------/ ) {	# find end of header
      ($intrp_data{switch} = 1);
    } elsif ($intrp_data{switch}) {
      next if ( /^\s*file/i );
      next if ( /^\s*$/ );
      chomp;
      #++$npath;			# get path info for each path
      my @line = split;
      unless ($line[0]) { shift(@line); }
      my $ip = sprintf("%d", substr($line[0], 4, 4)); # want index as an integer
      ($fname[$ip], $sig2[$ip], $amp[$ip], $degen[$ip],
       $nleg[$ip],  $reff[$ip] ) = @line;
    };
  };
  close FILES;

  open PATHS, $self->{'paths.dat'} or
    die "could not open $self->{'paths.dat'} for reading in intrp\n";
  $intrp_data{switch} = 0;
  my (@leg, @token);
  my ($nl, $np, $skip) = (-1, 0, 0);
  while (<PATHS>) {
    ($intrp_data{switch} = 1), next if ( /^\s*--------/ );
    if ($intrp_data{switch}) {
      next if ( /label/i );
      next if ( /^\s*$/ );
      chomp;
      if ( /degeneracy/i ) {
	my @line = split;		# path index is $line[0]
	$skip = 1, next unless ($fname[$line[0]]); # skip paths in paths.dat that are
	$skip = 0;
	last if ( $line[$#line] > $intrp_data{maxr} );
	if ( ($np) && ($fname[$np]) ) { # write path tokens for prev. path
	  $intrp_data{text} .= sprintf "%1s : %s", $intrp_data{nshadow}||" ", $intrp_data{core_token};
	  map { $intrp_data{text} .= sprintf " %-6s", $_ } (@token);
	  @token = (); @leg = ();
	}			# write out path information for current path
	$np = $line[0];
	if ( $amp[$np] < $intrp_data{minamp} ) { # skip paths smaller than $opt_a
	  $skip = 1;
	  next;
	}
	($intrp_data{text} .= sprintf "$/%s %4.4u %3u  %5.3f %6.2f ",
	 $nleg[$np], $np, int($degen[$np]+0.1), $reff[$np], $amp[$np])
	  if $fname[$np];
	$intrp_data{nshadow} = 0;
	$nl=-1;
      } else {			# Collect tokens for each leg and count
	next if ($skip);
	++$nl;			# number of forward scatterings.
	my $beta = 180;
	## how does this next bit work???
	if (/\'/) {
	  my $pos = $[;		# Find beta angle.  Good work Steve!
	  $pos = CORE::index($_, "'"); # This is about as annoying as possible.
	  $pos = CORE::index($_, "'", $pos+1);
	  my @findbeta = split( /\s+/, substr( $_, $pos+1) );
	  ($beta = $findbeta[2]) if (exists($findbeta[2]) and length($findbeta[2]));
	}
	@leg = split;
	unless ($nl == $nleg[$np]-1) {
	  ($beta < $intrp_data{betamax}) && ++$intrp_data{nshadow};
	};
	if ( $leg[3] eq "0" ) {
	  $token[$nl] = $intrp_data{core_token};
	} else {
	  ## rmultiplier has already been applied in paths.dat
#	  my $tag = round($intrp_data{rmult}*$intrp_data{factor}*($leg[0]-$xyz[0])) .
#	            round($intrp_data{rmult}*$intrp_data{factor}*($leg[1]-$xyz[1])) .
#	            round($intrp_data{rmult}*$intrp_data{factor}*($leg[2]-$xyz[2]));
	  my $tag = round($intrp_data{factor}*($leg[0]-$xyz[0])) .
	            round($intrp_data{factor}*($leg[1]-$xyz[1])) .
	            round($intrp_data{factor}*($leg[2]-$xyz[2]));
	  $token[$nl] = $label{$tag} || "<?>";
				# paths.dat might contain hand made entries,
				# use <?> as token for a hand made atom
	};
      };
    };
  };
  ## tokens for final path
  $intrp_data{text} .= sprintf "%1s : %s", $intrp_data{nshadow}||" ", $intrp_data{core_token};
  map { $intrp_data{text} .= sprintf " %-6s", $_ } (@token);
  close PATHS;

  my $head = "";
  my $energy = ($absorption_exists) ? sprintf("%s edge energy = %s eV", $intrp_data{edge},
					      Xray::Absorption->get_energy($intrp_data{central},
									   $intrp_data{edge}))
    : "";
  map { $head .= "# $_\n" } (@title);
  $head .= "#$/# Central atom: " . get_name($intrp_data{central}) . " (" .
    get_Z($intrp_data{central}) . ")  $energy\n";
  $head .= "# The central atom is denoted by this token: $intrp_data{core_token}\n";
  $head .= "# Cluster size = $intrp_data{rmax} Angstroms, containing $intrp_data{natom} atoms.\n";
  ($head .= "# rmultiplier = $intrp_data{rmult}\n") if ( $intrp_data{rmult} != 1);
  $head .= "# Curved wave criteria = $intrp_data{cwcrit}.\n";
  $head .= "# Cutoff angle for forward scattering is $intrp_data{betamax} degrees.\n";
  $head .= "# ------------------------------------------------------------\n";
  $head .= "#    degen reff   amp   fs      scattering path";

  return $head . $intrp_data{text};
};
#$head .= "# $npath paths were calculated by feff.\n";
#($head .= "# This list is truncated at $intrp_data{maxr} Angstroms.\n")
#  if ( $intrp_data{maxr} < 999 );
#($head .= "# This list contains paths of amplitude larger than $intrp_data{minamp}\n")
#  if ( $intrp_data{minamp} > 0.0002 );



sub default_k_weight {
  my $self = $_[0];
  my $kw = 1;			# return 1 is none others selected
 SWITCH: {
    $kw = sprintf("%.3f", $self->{karb}), last SWITCH
      if ($self->{karb_use} and ($self->{karb} =~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/));
    $kw = 1, last SWITCH if $self->{k1};
    $kw = 2, last SWITCH if $self->{k2};
    $kw = 3, last SWITCH if $self->{k3};
  };
  return $kw;
};

sub count_data_sets {
  my $self = shift;
  my $r_paths = $self->{family};
  my $nsets = 0;
  foreach my $k (keys %$r_paths) {
    next unless exists($$r_paths{$k}->{type});
    next unless ($$r_paths{$k}->{type} eq 'data');
    next unless $$r_paths{$k}->{include};
    ++$nsets;
      ##       next unless $$r_paths{$k}->{include};
      ##       my $this = $$r_paths{$k}->{k1} + $$r_paths{$k}->{k2} + $$r_paths{$k}->{k3};
      ##       $this += $$r_paths{$k}->{karb_use}
      ## 	if ($$r_paths{$k}->{karb} =~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/);
      ##       $nsets += ($this || 1);
      ##     };
  };
  return $nsets;
};


sub group_weights {
  my $self = shift;
  my @list = ();
  push(@list, 1) if $self->{k1};
  push(@list, 2) if $self->{k2};
  push(@list, 3) if $self->{k3};
  push(@list, $self->{karb}) if $self->{karb_use};
  push(@list, 1) unless @list;
  return @list;
};


sub x_minmax {
  my $self = shift;
  my $group = $self->{group};
  my $suff = "";
 SUFF: {
    $suff = 'energy', last SUFF if (lc($_[0]) eq 'e');
    $suff = 'k',      last SUFF if (lc($_[0]) eq 'k');
    $suff = 'r',      last SUFF if (lc($_[0]) eq 'r');
    $suff = 'q',      last SUFF if (lc($_[0]) eq 'q');
  };
  $self->dispose("set ___min = floor($group.$suff)",1);
  $self->dispose("set ___max = ceil($group.$suff)", 1);
  my @vals = (Ifeffit::get_scalar("___min"),
	      Ifeffit::get_scalar("___max"));
  $self->dispose("erase ___min ___max", 1);
  return @vals;
};


## used in intrp method
## sub _round {
##   my $number = shift;
##   return int($number + .5 * ($number <=> 0));
## };


1;
__END__
