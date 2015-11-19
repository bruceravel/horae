package Ifeffit::Group;                    # -*- cperl -*-
######################################################################
## Ifeffit::Group: Object oriented data group manipulation for Ifeffit
##
##                      Athena is copyright (c) 2001-2009 Bruce Ravel
##                                              bravel AT bnl DOT gov
##                         http://cars9.uchicago.edu/~ravel/software/
##
##                   Ifeffit is copyright (c) 1992-2008 Matt Newville
##                              newville AT cars DOT uchicago DOT edu
##                       http://cars9.uchicago.edu/~newville/ifeffit/
##
##	  The latest version of Athena can always be found at
##	       http://cars9.uchicago.edu/~ravel/software/
##
## -------------------------------------------------------------------
##     All rights reserved. This program is free software; you can
##     redistribute it and/or modify it provided that the above notice
##     of copyright, these terms of use, and the disclaimer of
##     warranty below appear in the source code and documentation, and
##     that none of the names of NIST, Argonne National Laboratory,
##     The Naval Research Laboratory, The University of Chicago,
##     University of Washington, or the authors appear in advertising
##     or endorsement of works derived from this software without
##     specific prior written permission from all parties.
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
use vars qw($VERSION $cvs_info $module_version @ISA @EXPORT @EXPORT_OK);
use constant ETOK=>0.262468292;
use Text::Wrap;
use Ifeffit;
use Ifeffit::Tools;
use Ifeffit::FindFile;
use Chemistry::Elements qw(get_Z);
use File::Basename;
use constant EPSILON => 1e-8;
use constant DELTA => 1e-3;

require Exporter;

@ISA = qw(Exporter AutoLoader Ifeffit::Tools Ifeffit::FindFile);
@EXPORT_OK = qw();

$VERSION = "0.8.059";
$cvs_info = '$Id: $ ';
$module_version = (split(' ', $cvs_info))[2] || 'pre_release';

my $echocmd = \&::Echonow;
my $errorcmd = \&::Error;
my $rpf = \%::plot_features;
use vars qw($rmax_out);
$rmax_out = 10;
my $is_windows = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));
my @done = (" ... done!", 1);
my $screen;
my $default = Ifeffit::Group -> new(not_data=>1);
use vars qw/$last_plot/;


use vars qw/$thisdir $libdir/;
use File::Spec;
$thisdir = $Ifeffit::FindFile::thisdir;
$libdir = File::Spec->catfile($thisdir, "lib", "athena");
#$libdir =~ s/^\//\.\//;
my %clamp = ("Slight" => 3, "Weak" => 6, "Medium" =>12, "Strong" => 24, "Rigid" => 96);


## the use of the $default to set the default values allows the user
## the options of changing these defaults while using Athena.
sub new {
  my $classname = shift;
  my $self = {};

  $self->{line}	        =  0;	# meta data
  $self->{group}	= "";
  $self->{is_xmu}       =  0;
  $self->{is_xmudat}    =  0;
  $self->{is_nor}       =  0;
  $self->{is_xanes}     =  0;
  $self->{is_chi}       =  0;
  $self->{is_rsp}       =  0;
  $self->{is_qsp}       =  0;
  $self->{is_merge}     =  0;
  $self->{is_diff}      =  0;
  $self->{is_bkg}       =  0;
  $self->{not_data}     =  0;
  $self->{is_pixel}     =  0;
  $self->{is_proj}      =  0;
  $self->{reference}    =  0;
  $self->{refsame}      =  0;
  $self->{is_ref}       =  0;

  $self->{is_raw}       =  0;	# raw data files
  $self->{is_rec}       =  0;
  $self->{en_str}       = "";
  $self->{mu_str}       = "";

  $self->{file}	        = "";	# data input parameters
  $self->{ecol}	        =  1;
  $self->{xcol}	        =  2;
  $self->{importance}   =  1;

  $self->{bkg_e0}	=  0;	# background removal parameters
  $self->{bkg_kw}	=  (exists $default->{bkg_kw})   ? $default->{bkg_kw}   : 1;
  $self->{bkg_rbkg}	=  (exists $default->{bkg_rbkg}) ? $default->{bkg_rbkg} : 1;
  $self->{bkg_dk}	=  0;
  $self->{bkg_pre1}	=  (exists $default->{bkg_pre1}) ? $default->{bkg_pre1} : -150;
  $self->{bkg_pre2}	=  (exists $default->{bkg_pre2}) ? $default->{bkg_pre2} : -30;
  $self->{bkg_nor1}	=  (exists $default->{bkg_nor1}) ? $default->{bkg_nor1} : 100;
  $self->{bkg_nor2}	=  (exists $default->{bkg_nor2}) ? $default->{bkg_nor2} : 400;
  $self->{bkg_spl1}	=  (exists $default->{bkg_spl1}) ? $default->{bkg_spl1} : 0.5;
  $self->{bkg_spl2}	=  (exists $default->{bkg_spl2}) ? $default->{bkg_spl2} : 12;
  $self->{bkg_spl1e}	=  0;
  $self->{bkg_spl2e}	=  0;
  $self->{bkg_win}	= $default->{bkg_win} || "kaiser-bessel";
  $self->{bkg_slope}    = 0;	# these six are set whenever
  $self->{bkg_int}      = 0;	# a background is removed
  $self->{bkg_step}     = 0;
  $self->{bkg_fitted_step} = 0;
  $self->{bkg_fixstep}  = 0;
  $self->{bkg_nc0}      = 0;
  $self->{bkg_nc1}      = 0;
  $self->{bkg_nc2}      = 0;
  $self->{bkg_flatten}  = (exists $default->{bkg_flatten}) ? $default->{bkg_flatten} : 0;
  $self->{bkg_fnorm}    = (exists $default->{bkg_fnorm}) ? $default->{bkg_fnorm} : 0;
  $self->{bkg_nnorm}    = (exists $default->{bkg_nnorm}) ? $default->{bkg_nnorm} : 3;
  $self->{bkg_stan}     = 'None';
  $self->{bkg_stan_lab} = '0: None';
  $self->{bkg_clamp1}   = $default->{bkg_clamp1} || 'None';
  $self->{bkg_clamp2}   = $default->{bkg_clamp2} || 'Strong';
  ##$self->{bkg_nclamp}    = 5;
  $self->{bkg_tie_e0}   = 0;
  $self->{bkg_former_e0} = 0;

  $self->{bkg_z}        = 'H';	# Cromer-Liberman parameters
  $self->{bkg_cl}       = 0;

  $self->{fft_arbkw}	=  $default->{fft_arbkw} || 0.5;  # forward FT parameters
  $self->{fft_win}	=  $default->{fft_win} || "kaiser-bessel";
  $self->{fft_dk}	=  (exists $default->{fft_dk}) ? $default->{fft_dk} : 2;
  $self->{fft_kmin}	=  (exists $default->{fft_kmin}) ? $default->{fft_kmin} : 2;
  $self->{fft_kmax}	=  (exists $default->{fft_kmax}) ? $default->{fft_kmax} : 12;
  $self->{fft_pc}	=  $default->{fft_pc} || 'off';
  $self->{fft_edge}	=  'K';

  $self->{bft_win}	=  $default->{bft_win} || "kaiser-bessel";  # back FT parameters
  $self->{bft_rmin}	=  (exists $default->{bft_rmin}) ? $default->{bft_rmin} : 1;
  $self->{bft_rmax}	=  (exists $default->{bft_rmax}) ? $default->{bft_rmax} : 3;
  $self->{bft_dr}	=  (exists $default->{bft_dr}) ? $default->{bft_dr} : 0.5;

  $self->{update_bkg}	= 1;	# these are for flagging chores that need
  $self->{update_fft}	= 1;	# to be done
  $self->{update_bft}	= 1;
  $self->{frozen}	= 0;

  $self->{check}        = 0;	# canvas id's of checkbutton, text,
  $self->{rect}         = 0;    # and rectangle so I can easily
  $self->{text}         = 0;	# manipulate the group list

  $self->{bkg_eshift}   = 0;
  $self->{deg_tol}      = 0;   # deglitching tolerance

  $self->{plot_scale}   = 1;	# plotting parameters
  $self->{plot_yoffset} = 0;

  $self->{detectors}    = [];	# communication with daughter
  $self->{numerator}    = "";	# detector groups
  $self->{denominator}  = "";
  $self->{i0}	        = 0;

  $self->{peak}         = 0;	# peak fit flag

  bless($self, $classname);
  $self -> make(@_);
  return $self;
};



######################################################################
## General group management methods

## return a list of all parameter keys
sub Keys {
  my $self = shift;
  return (qw(line file importance bkg_e0 bkg_kw bkg_rbkg
	     bkg_pre1 bkg_pre2 bkg_nor1 bkg_nor2 bkg_spl1 bkg_spl2
	     bkg_spl1e bkg_spl2e bkg_stan bkg_stan_lab
             bkg_z bkg_cl bkg_nclamp
	     bkg_clamp1 bkg_clamp2 bkg_eshift bkg_step bkg_fixstep
	     bkg_fitted_step bkg_flatten bkg_fnorm
	     fft_arbkw fft_dk fft_win fft_kmin fft_kmax fft_pc fft_edge
	     bft_dr bft_win bft_rmin bft_rmax
	     plot_scale plot_yoffset
	    ));
  ## bkg_dk bkg_win bkg_nclamp
};

sub make {
  my $self = shift;
  unless ($#_ % 2) {
    my $this = (caller(0))[3];
    die "$this error!  Odd number of arguments.\n";
    return;
  };
  while (@_) {
    my $att   = lc(shift);
    next if (($self->{frozen}) and ($att !~ /(update|text)/));
    my $value = shift;
    $self->{$att} = $value;
    ($self->{original_label} = $value) if (($att eq 'label') and (not $self->{original_label}));
  SWITCH: {			# deal with related parameters
      ($self->{update_fft} = 1), ($self->{update_bft} = 1), last SWITCH
	if (($att eq 'update_bkg') and ($value == 1));
      ($self->{update_bft} = 1), last SWITCH if (($att eq 'update_fft') and ($value == 1));

      ($self->{is_raw} = 0),     last SWITCH if (($att eq 'is_rec') and ($value == 1));
      ($self->{is_rec} = 0),     last SWITCH if (($att eq 'is_raw') and ($value == 1));

      ($self->{is_chi} = 0), ($self->{is_chi} = 0), ($self->{is_rsp} = 0),
      ($self->{is_qsp} = 0),   last SWITCH
	if (($att eq 'not_data') and ($value == 1));

      ($self->{is_chi} = 0), ($self->{is_rsp} = 0), ($self->{is_qsp} = 0),
      ($self->{not_data} = 0), last SWITCH
	if (($att eq 'is_xmu')   and ($value == 1));

      $self->{bkg_fixstep} = 1, $self->{bkg_step} = 1, last SWITCH
	if (($att eq 'is_nor')   and ($value == 1));

      ($self->{is_xmu} = 0), ($self->{is_rsp} = 0), ($self->{is_qsp} = 0),
      ($self->{not_data} = 0), last SWITCH
	if (($att eq 'is_chi')   and ($value == 1));

      ($self->{is_xmu} = 0), ($self->{is_chi} = 0), ($self->{is_qsp} = 0),
      ($self->{not_data} = 0), last SWITCH
	if (($att eq 'is_rsp')   and ($value == 1));

      ($self->{is_xmu} = 0), ($self->{is_chi} = 0), ($self->{is_rsp} = 0),
      ($self->{not_data} = 0), last SWITCH
	if (($att eq 'is_qsp')   and ($value == 1));

      $self->{label} =~ s{[\"\']}{}g, last SWITCH if ($att eq 'label');


      #($self->{bkg_slope} = 0), last SWITCH
      #if (($att eq 'bkg_slope')   and ($value < EPSILON));

      #($self->{bkg_int} = 0), last SWITCH
      #if (($att eq 'bkg_int')   and ($value < EPSILON));
    };
    ## deal with e0 shift in reference channel
    #if ($att eq 'bkg_eshift') {
    #  if ($self->{reference}) {
    #	if (
    #  };
    #};
  };
};

## this is a "private" method that overrides the frozen restriction on
## make-ing a parameter value
sub _MAKE {
  my $self = shift;
  my $is_frozen = $self->{frozen};
  $self->unfreeze;
  $self->make(@_);
  $self->freeze if $is_frozen;
};

## this is just like make, except that it overrides frozen-ness in a safe way
sub MAKE {
  my $self = shift;
  $self->_MAKE(@_);
};

sub freeze {
  my $self = shift;
  return if ($self->{is_pixel}); ## it makes no sense at all to freeze a pixel group
  $self->{frozen} = 1;
};
sub unfreeze {
  my $self = shift;
  $self->{frozen} = 0;
};

## set parameters from one group to those of another group, taking
## care to ignore energy parameters for k-, R-, q- records
sub set_to_another {
  my $self = shift;
  my $other = shift;
  my $is_energy = (($other->{is_xmu}) or ($other->{is_nor}));
  my $is_rq     = (($other->{is_rsp}) or ($other->{is_qsp}));
  foreach my $x ($self->Keys, 'bkg_nnorm') {
    next unless ($x =~ m{^(?:bft|bkg|fft|impor|plot)});
    $self->{$x} = $other->{$x};
    my $item = $self->{group};
  SWITCH: {
      ($is_energy) and ($x eq 'bkg_e0') and do {
	if ($self->{bkg_e0} <= 0) {
	  ifeffit("pre_edge($item.energy, $item.xmu)\n");
	  $self->{bkg_e0} = Ifeffit::get_scalar("e0");
	};
	last SWITCH;
      };
      ($is_energy) and ($x eq 'bkg_spl2e') and do {
	if ($self->{bkg_spl2e} <= 1) {
	  ifeffit("set ___x = ceil($item.energy)");
	  my $maxE = Ifeffit::get_scalar("___x");
	  $self->{bkg_spl2e} = sprintf("%.2f", $maxE);
	  $self->{bkg_spl2} = $self -> e2k($self->{bkg_spl2e});
	};
	last SWITCH;
      };
      (not $is_rq) and ($x eq 'fft_kmax') and do {
	if ($self->{fft_kmax} <= 0.1) {
	  ifeffit("set ___x = ceil($item.k)");
	  my $maxk = Ifeffit::get_scalar("___x") || 15;
	  $self->{fft_kmax} = ($is_energy) ? $self->{bkg_spl2} : $maxk;
	};
	last SWITCH;
      };
      1;
    };
  };
  $self -> _MAKE(update_bkg=>1, update_fft=>1, update_bft=>1);
};


## interpolate $other onto $self
sub interpolate {
  my $self = shift;
  my ($other, $space, $mode) = @_;
  my ($stan, $this) = ($self->{group}, $other->{group});

  ## get $self up to date for interpolation
  if ($self->{update_bkg}) {
    $self->dispatch_bkg($mode);
    $self->_MAKE(update_bkg=>0);
  };
  if ((lc($space) =~ /[rq]/) and ($self->{update_fft})) {
    $self->do_fft($mode);
    $self->_MAKE(update_fft=>0);
  };
  if ((lc($space) eq 'q') and ($self->{update_bft})) {
    $self->do_bft($mode);
    $self->_MAKE(update_bft=>0);
  };
  ## get $other up to date for interpolation
  if ($other->{update_bkg}) {
    $other->dispatch_bkg($mode);
    $other->_MAKE(update_bkg=>0);
  };
  if ((lc($space) =~ /[rq]/) and ($other->{update_fft})) {
    $other->do_fft($mode);
    $other->_MAKE(update_fft=>0);
  };
  if ((lc($space) eq 'q') and ($other->{update_bft})) {
    $other->do_bft($mode);
    $other->_MAKE(update_bft=>0);
  };

  my ($x, $y1, $y2, $y3, $y4);
 SWITCH: {			# get columns
    ($x, $y1, $y2) = ("energy", "xmu", ""),       last SWITCH if (lc($space) eq 'e');
    ($x, $y1, $y2) = ("energy", "norm", ""),      last SWITCH if (lc($space) eq 'n');
    ($x, $y1, $y2) = ("k", "chi", ""),            last SWITCH if (lc($space) eq 'k');
    ($x, $y1, $y2) = ("r", "chir_re", "chir_im"), last SWITCH if (lc($space) eq 'r');
    ($x, $y1, $y2) = ("q", "chiq_re", "chiq_im"), last SWITCH if (lc($space) eq 'q');
  };
 MP: {				# handle complex data (rsp and qsp)
    ($y3, $y4) = ("chir_mag", "chir_pha"), last MP if (lc($space) eq 'r');
    ($y3, $y4) = ("chiq_mag", "chiq_pha"), last MP if (lc($space) eq 'q');
  };
  ## need to snarf the portion of $stan.$x that is covered by $this.$x
  my @xstan = Ifeffit::get_array("$stan.$x");
  $self -> dispose("set ___x = max($this.$x)", 1);
  my $xmax = Ifeffit::get_scalar("___x");
  my @xxx = grep { $_ <= $xmax } @xstan;
  Ifeffit::put_array("$this.xxx", \@xxx);
  my $sets = "set($this.interp = qinterp($this.$x, $this.$y1, $this.xxx),\n";
  $sets   .= "    $this.$x = $this.xxx,\n";
  $sets   .= "    $this.$y1 = $this.interp)";
  $self -> dispose($sets, $mode);
  if (lc($space) =~ /[rq]/) {
    $sets  = "set($this.interp = qinterp($this.$x, $this.$y2, $this.xxx),\n";
    $sets .= "    $this.$y2 = $this.interp)";
    $self -> dispose($sets, $mode);
    ## fill mag and phase arrays
  };
  $self -> dispose("erase $this.xxx $this.interp", $mode);    # garbage collection
};


## compute the difference spectrum in some space between $self and
## $other.  store the difference in group diff___diff.  this does NOT
## create a group out of diff___diff.
sub plot_difference {
  my $self = shift;
  my ($other, $hash_ref, $mode, $rpf) = @_;
  my ($space, $xnot, $xn, $xx, $list, $groups) = ($$hash_ref{space}, $$hash_ref{xnot}, $$hash_ref{xmin},
						  $$hash_ref{xmax}, $$hash_ref{list}, $$hash_ref{groups});
  my $invert = ($$hash_ref{invert}) ? "-1*" : "";
  ## make sure the background is up to date
  unless ($$hash_ref{space} eq 'e') {
    ($self->{update_bkg})  and $self->dispatch_bkg($mode);
    $self->_MAKE(update_bkg=>0);
    ($other->{update_bkg}) and $other->dispatch_bkg($mode);
    $other->_MAKE(update_bkg=>0);
  };
  my ($stan, $this) = ($self->{group}, $other->{group});
  ## various parameters for the plot
  my ($sp, $suff, $suff2, $color, $xmin, $xmax, $xlabel, $ylabel);
  $color = ($$hash_ref{components}) ? $default->{color2} : $default->{color0};
  my ($command, $plot, $marker);
 SWITCH: {
    ($space =~ /[en]/) and do {
      unless ($self->{is_xmu} or $self->{not_data}) {
	&$errorcmd("> Difference plot aborted: \"$self->{label}\" cannot be plotted in energy");
	return 0;
      };
      unless ($other->{is_xmu} or $other->{not_data}) {
	&$errorcmd("> Difference plot aborted: \"$other->{label}\" cannot be plotted in energy");
	return 0;
      };
      ($sp, $suff, $xmin, $xmax) = ('energy', 'xmu',
				    $self->{bkg_e0}+$$rpf{emin},
				    $self->{bkg_e0}+$$rpf{emax});
      if ($space eq 'n') {
	$suff = ($self->{bkg_flatten}) ? "flat" : "norm";
      };
      my $esh_s = $self->{bkg_eshift}; # = =
      my $esh_o = $other->{bkg_eshift};
      ## build the difference spetrum
      $command = "set diff___diff.$suff = $invert($stan.$suff - " .
	"interp($this.$sp+$esh_o, $this.$suff, $stan.$sp+$esh_s))\n";
      ## figure out the labels
      $xlabel = "\"E (eV)\"";
      $ylabel = ($space eq 'n') ? "\"difference in normalized x\\gm(E)\"" :
	"\"difference in x\\gm(E)\"";
      ## build the plot command
      $plot .= "($stan.$sp+$esh_s, diff___diff.$suff, ";
      $plot .= "style=lines, color=\"$color\", key=difference, ";
      $plot .= "xmin=$xmin, xmax=$xmax, ";
      $plot .= ($invert) ? "title=\"$other->{label} - $self->{label}\", " : "title=\"$self->{label} - $other->{label}\", ";
      $plot .= "xlabel=$xlabel, ylabel=$ylabel)";
      $marker  = "pmarker \"$stan.$sp+$esh_s\", diff___diff.$suff, $xnot+$xn, $default->{marker}, $default->{markercolor}\n";
      $marker .= "pmarker \"$stan.$sp+$esh_s\", diff___diff.$suff, $xnot+$xx, $default->{marker}, $default->{markercolor}\n";
      last SWITCH;
    };
    ($space eq 'k') and do {
      ($sp, $suff, $xmin, $xmax) = ('k', 'chi', $$rpf{kmin}, $$rpf{kmax});
      unless ($self->{is_xmu} or $self->{is_chi}) {
	&$errorcmd("> Difference plot aborted: \"$self->{label}\" cannot be plotted in k-space");
	return 0;
      };
      unless ($other->{is_xmu} or $other->{is_chi}) {
	&$errorcmd("> Difference plot aborted: \"$other->{label}\" cannot be plotted in k-space");
	return 0;
      };
      ## build the difference spetrum
      $command = "set diff___diff.$suff = $invert($stan.$suff-$this.$suff)\n";
      ## figure out the labels correctly for this k-weight
      my ($k, $w);
      my $ww = $self->{fft_arbkw};
      if    ($$rpf{k_w} eq 'w') { (($k, $w) = ("k\\u$ww\\d * ", "^$ww")) }
      elsif ($$rpf{k_w} == 0)   { (($k, $w) = ("", "")) }
      elsif ($$rpf{k_w} == 1)   { (($k, $w) = ("k * ", "^k")) }
      elsif ($$rpf{k_w} >= 2)   { (($k, $w) = ("k\\u$$rpf{k_w}\\d * ", "^$$rpf{k_w}")) };
      $xlabel = "\"k (\\A\\u-1\\d)\"";
      $ylabel = sprintf("\"%s difference in \\gx(k)\"", $k);
      ## build the plot command
      $plot .= "($stan.$sp, diff___diff.$suff*$stan.$sp$w, ";
      $plot .= "style=lines, color=\"$color\", key=difference, ";
      $plot .= "xmin=$xmin, xmax=$xmax, title=\"$self->{label} - $other->{label}\", ";
      $plot .= "xlabel=$xlabel, ylabel=$ylabel)";
      $marker  = "pmarker $stan.$sp, diff___diff.$suff $xn $default->{marker}, $default->{markercolor}\n";
      $marker .= "pmarker $stan.$sp, diff___diff.$suff $xx $default->{marker}, $default->{markercolor}\n";
      last SWITCH;
    };
    ($space eq 'r') and do {
      unless ($self->{is_xmu} or $self->{is_chi} or $self->{is_rsp}) {
	&$errorcmd("> Difference plot aborted: \"$self->{label}\" cannot be plotted in R-space");
	return 0;
      };
      unless ($other->{is_xmu} or $other->{is_chi} or $other->{is_rsp}) {
	&$errorcmd("> Difference plot aborted: \"$other->{label}\" cannot be plotted in R-space");
	return 0;
      };
      ## is the FT up to date??
      ($self->{update_fft}) and $self->do_fft($mode, $rpf);
      $self->_MAKE(update_fft=>0);
      ($other->{update_fft}) and $other->do_fft($mode, $rpf);
      $other->_MAKE(update_fft=>0);
      ($sp, $suff, $suff2, $xmin, $xmax) = ('r', 'chir_re', 'chir_im', $$rpf{rmin}, $$rpf{rmax});
      ## build all four parts of the difference spetrum
      my $sets = "set(diff___diff.$suff = $invert($stan.$suff-$this.$suff),\n";
      $sets   .= "    diff___diff.$suff2 = $invert($stan.$suff2-$this.$suff2),\n";
      $sets   .= "    diff___diff.chir_mag = sqrt(diff___diff.$suff^2 + diff___diff.$suff2^2),\n";
      $sets   .= "    diff___diff.chir_pha = atan(diff___diff.$suff2 / diff___diff.$suff))\n";
      $command .= $sets;
      ## figure out the labels for this part of the complex function
      my ($part, $lab, $tit);
      if    ($$rpf{r_mag}) {($part,$lab,$tit) = ("chir_mag", "|\\gx(R)|", "magnitude of ")}
      elsif ($$rpf{r_re})  {($part,$lab,$tit) = ("chir_re",  "Re[\\gx(R)]", "real part of ")}
      elsif ($$rpf{r_im})  {($part,$lab,$tit) = ("chir_im",  "Im[\\gx(R)]", "imaginary part of ")}
      elsif ($$rpf{r_pha}) {($part,$lab,$tit) = ("chir_pha", "Pha[\\gx(R)]", "phase of ")};
      $xlabel = "\"k (\\A\\u-1\\d)\"";
      $ylabel = sprintf("\"difference in %s\"", $lab);
      ## build the plot command
      $plot .= "($stan.$sp, diff___diff.$part, ";
      $plot .= "style=lines, color=\"$color\", key=difference, ";
      $plot .= "xmin=$xmin, xmax=$xmax, title=\"$self->{label} - $other->{label}\", ";
      $plot .= "xlabel=$xlabel, ylabel=$ylabel)";
      $marker  = "pmarker $stan.$sp, diff___diff.$suff $xn $default->{marker}, $default->{markercolor}\"\n";
      $marker .= "pmarker $stan.$sp, diff___diff.$suff $xx $default->{marker}, $default->{markercolor}\"\n";
      last SWITCH;
    };
    ($space eq 'q') and do {
      if ($self->{not_data}) {
	&$errorcmd("> Difference plot aborted: \"$self->{label}\" cannot be plotted in q-space");
	return 0;
      };
      if ($other->{not_data}) {
	&$errorcmd("> Difference plot aborted: \"$other->{label}\" cannot be plotted in q-space");
	return 0;
      };
      ## are the FTs up to date??
      ($self->{update_fft}) and $self->do_fft($mode, $rpf);
      $self->_MAKE(update_fft=>0);
      ($other->{update_fft}) and $other->do_fft($mode, $rpf);
      $other->_MAKE(update_fft=>0);
      ($self->{update_bft}) and $self->do_bft($mode);
      $self->_MAKE(update_bft=>0);
      ($other->{update_bft}) and $other->do_bft($mode);
      $other->_MAKE(update_bft=>0);
      ($sp, $suff, $suff2, $xmin, $xmax) = ('q', 'chiq_re', 'chiq_im', $$rpf{qmin}, $$rpf{qmax});
      ## build all four parts of the difference spetrum
      my $sets  = "set(diff___diff.$suff = $invert($stan.$suff-$this.$suff),\n";
      $sets    .= "    diff___diff.$suff2 = $invert($stan.$suff2-$this.$suff2),\n";
      $sets    .= "    diff___diff.chiq_mag = sqrt(diff___diff.$suff^2 + diff___diff.$suff2^2),\n";
      $sets    .= "    diff___diff.chiq_pha = atan(diff___diff.$suff2 / diff___diff.$suff))\n";
      $command .= $sets;
      ## figure out the labels for this part of the complex function
      my ($part, $lab, $tit);
      if    ($$rpf{'q_mag'}) {($part,$lab,$tit) = ("chiq_mag", "|\\gx(q)|", "magnitude of ")}
      elsif ($$rpf{'q_re'})  {($part,$lab,$tit) = ("chiq_re",  "Re[\\gx(q)]", "real part of ")}
      elsif ($$rpf{'q_im'})  {($part,$lab,$tit) = ("chiq_im",  "Im[\\gx(q)]", "imaginary part of ")}
      elsif ($$rpf{'q_pha'}) {($part,$lab,$tit) = ("chiq_pha", "Pha[\\gx(q)]", "phase of ")};
      $xlabel = "\"k (\\A\\u-1\\d)\"";
      $ylabel = sprintf("\"difference in %s\"", $lab);
      ## build the plot command
      $plot .= "($stan.$sp, diff___diff.$part, ";
      $plot .= "style=lines, color=\"$color\", key=difference, ";
      $plot .= "xmin=$xmin, xmax=$xmax, title=\"$self->{label} - $other->{label}\", ";
      $plot .= "xlabel=$xlabel, ylabel=$ylabel)";
      $marker  = "pmarker $stan.$sp, diff___diff.$suff $xn $default->{marker}, $default->{markercolor}\"\n";
      $marker .= "pmarker $stan.$sp, diff___diff.$suff $xx $default->{marker}, $default->{markercolor}\"\n";
      last SWITCH;
    };
  };
  my $pp = ($$hash_ref{components}) ? "plot" : "newplot";
  if ($$hash_ref{components}) {
    my $str = $space;
    ($str = $$rpf{k_w}) if ($space eq 'k');
    ($str = $$rpf{$space."_marked"}) if ($space =~ /[rq]/);
    $self->plot_marked($str, $mode, $groups, {$other->{group}=>1, $self->{group}=>1}, $rpf, $list)
  };
  $plot = wrap($pp, "       ", $plot);
  ##$command .= $plot . "\n";
  $self->dispose($command, $mode);
  unless ($$hash_ref{noplot}) {
    $self->dispose($plot, $mode);
    $self->dispose($marker, $mode);
  };
  return 1;
};


## erase a group from memory, preserving the initial state of the
## record
## what about title lines?
sub erase {
  my $self = shift;
  my $group = $self->{group};
  &$errorcmd("> Cannot erase defaults."), return if ($group eq "Default Parameters");
  my (@x, @y1, @y2, @z1, @z2);
  ## save initial data
 SWITCH: {
    ($self->{is_xmu}) and do {
      @x  = Ifeffit::get_array($group.".energy");
      @y1 = Ifeffit::get_array($group.".xmu");
      last SWITCH;
    };
    ($self->{is_chi}) and do {
      @x  = Ifeffit::get_array($group.".k");
      @y1 = Ifeffit::get_array($group.".chi");
      last SWITCH;
    };
    ($self->{is_rsp}) and do {
      @x  = Ifeffit::get_array($group.".r");
      @y1 = Ifeffit::get_array($group.".chir_re");
      @y2 = Ifeffit::get_array($group.".chir_im");
      @z1 = Ifeffit::get_array($group.".chir_mag");
      @z2 = Ifeffit::get_array($group.".chir_pha");
      last SWITCH;
    };
    ($self->{is_qsp}) and do {
      @x  = Ifeffit::get_array($group.".q");
      @y1 = Ifeffit::get_array($group.".chiq_re");
      @y2 = Ifeffit::get_array($group.".chiq_im");
      @z1 = Ifeffit::get_array($group.".chiq_mag");
      @z2 = Ifeffit::get_array($group.".chiq_pha");
      last SWITCH;
    };
  };
  ## erase group
  $self -> dispose("erase \@group $group\n");
  ## restore intial data
 SWITCH: {
    ($self->{is_xmu}) and do {
      Ifeffit::put_array($group.".energy",   \@x);
      Ifeffit::put_array($group.".xmu",      \@y1);
      $self -> _MAKE(update_bkg=>1, update_fft=>1, update_bft=>1);
      last SWITCH;
    };
    ($self->{is_chi}) and do {
      Ifeffit::put_array($group.".k",        \@x);
      Ifeffit::put_array($group.".chi",      \@y1);
      $self -> _MAKE(update_bkg=>0, update_fft=>1, update_bft=>1);
      last SWITCH;
    };
    ($self->{is_rsp}) and do {
      Ifeffit::put_array($group.".r",        \@x);
      Ifeffit::put_array($group.".chir_re",  \@y1);
      Ifeffit::put_array($group.".chir_im",  \@y2);
      Ifeffit::put_array($group.".chir_mag", \@z1);
      Ifeffit::put_array($group.".chir_pha", \@z2);
      $self -> _MAKE(update_bkg=>0, update_fft=>0, update_bft=>1);
      last SWITCH;
    };
    ($self->{is_qsp}) and do {
      Ifeffit::put_array($group.".q",        \@x);
      Ifeffit::put_array($group.".chiq_re",  \@y1);
      Ifeffit::put_array($group.".chiq_im",  \@y2);
      Ifeffit::put_array($group.".chiq_mag", \@z1);
      Ifeffit::put_array($group.".chiq_pha", \@z2);
      $self -> _MAKE(update_bkg=>0, update_fft=>0, update_bft=>0);
      last SWITCH;
    };
  };
};



## reset bkg_e0 to the value found by pre_edge and update the spline
## energy range values
sub reset_e0 {
  my $self = shift;
  my $group = $self->{group};
  my $esh =  $self->{bkg_eshift};
  my $dmode = $_[0] || 5;
  $self -> dispose("## resetting e0 to its default value\n", $dmode);
  $self -> dispose("pre_edge(\"$group.energy+$esh\", $group.xmu)\n", $dmode);
  my $e0 = Ifeffit::get_scalar("e0");
  unless ($e0) {		# deal with situation where pre_edge
    $self ->			# fails to return an e0 value
      dispose("## failed to find e0 with the pre_edge command, take max of derivative",
	      $dmode);
    my $sets = "set($group.deriv = deriv($group.xmu),";
    $sets   .= "    i___i = ceil($group.deriv),";
    $sets   .= "    i___i = nofx($group.deriv, i___i))";
    $self -> dispose($sets, $dmode);
    $e0 = Ifeffit::get_scalar("i___i");
    if ($e0 < 5) {
      $e0 = 15;
      $self -> dispose("## max of derivative was very close to the beginning of the data, e0 set to 15th data point", $dmode);
    };
    my @array = Ifeffit::get_array("$group.energy");
    $e0 = $array[$e0-1];
    $self -> dispose("erase i___i $group.deriv", $dmode);
  };
  $self -> _MAKE(bkg_e0=>$e0);
  my $k = $self->{bkg_spl1};
  $self -> _MAKE(bkg_spl1e=>$self->k2e($k));
  $k = $self->{bkg_spl2};
  $self -> _MAKE(bkg_spl2e=>$self->k2e($k));
  $self -> _MAKE(update_bkg=>1);
};

## reset bkg_e0 to half the edge step and update the spline
## energy range values
sub e0_half_step {
  my $self = shift;
  my $fraction = $_[1];
  $fraction ||= 0.5;
  ($fraction = 0.5) if ($fraction <= 0);
  ($fraction = 1.0) if ($fraction >  1);
  my $group = $self->{group};
  my $esh =  $self->{bkg_eshift};
  my $dmode = $_[0] || 5;
  my $prior = 0;
  my $count = 1;
  while (abs($self->{bkg_e0}-$prior) > DELTA) {
    &$echocmd("> Resetting E0 to half edge step, iteration $count");
    $prior = $self->{bkg_e0};
    $self->dispatch_bkg($dmode) if $self->{update_bkg};
    my $halfstep = $fraction * $self->{bkg_step};
    my @x = Ifeffit::get_array("$group.energy");
    my @y = Ifeffit::get_array("$group.pre");
    my $ehalf = 0;
    foreach my $i (0 .. $#x) {
      next if ($y[$i] < $halfstep);
      my $frac = ($halfstep - $y[$i-1]) / ($y[$i] - $y[$i-1]);
      $ehalf = $x[$i-1] + $frac*($x[$i] - $x[$i-1]);
      last;
    };
    $self -> _MAKE(bkg_e0=>$ehalf+$esh);
    my $k = $self->{bkg_spl1};
    $self -> _MAKE(bkg_spl1e=>$self->k2e($k));
    $k = $self->{bkg_spl2};
    $self -> _MAKE(bkg_spl2e=>$self->k2e($k));
    $self -> _MAKE(update_bkg=>1);
    ++$count;
    return if ($count > 5);	# it shouldn't take more than three
                                # unless something is very wrong with
                                # these data
  };
};



######################################################################
## Plotting methods

sub SetDefault {
  my $self = shift;
  $default -> _MAKE(@_);
  #$default = Ifeffit::Group -> new(@_);
};


sub Default {
  my $self = shift;
  return $default->{$_[0]} || 0;
};


## the argument is a character string that is decoded to indicate

## plotting of mu, mu0, pre and whether data should be normalized or
## differentiated
sub plotE {
  my $self = shift;
  my ($group, $lab) = ($self->{group}, $self->{label});
  my $not_data = $self->{not_data};
  unless (($self->{is_xmu}) or ($not_data)) {
    if ($group eq "Default Parameters") {
      &$errorcmd("> No data!");
      return 0;
    };
    &$errorcmd("> The group \"$lab\" cannot be plotted in energy.");
    return 0;
  };
  my ($str, $mode, $rpf, $indicators) = (lc($_[0]), $_[1], $_[2], $_[3]);
  ($str eq 'e') and ($str = 'em');
  my ($mu, $not, $pre, $post, $norm, $clnorm, $der, $second, $smooth, $deg) = (0,0,0,0,0,0,0,0,0,0);
  my $plot_scale = $self->{plot_scale};
  my $yoffset    = $self->{plot_yoffset};
  my $cnt = 0;
  my $color;
  my (@markers_e, @markers_x);
  ## determine parameters for legend
  ($str =~ /m/) and ($mu   = 1); # parse the inicator argument
  ($str =~ /z/) and ($not  = 1);
  ($str =~ /p/) and ($pre  = 1);
  ($str =~ /t/) and ($post = 1);
  ($str =~ /n/) and ($norm = 1);
  ($str =~ /d/) and (($der, $second)  = (1, 0));
  ($str =~ /2/) and (($der, $second)  = (0, 1));
  ($str =~ /s/) and ($smooth = 1);
  ($str =~ /g/) and ($deg  = 1);
  ($self->{bkg_cl}) and ($clnorm = 1);
  ($clnorm == 1) and (($pre, $post) = (0,0));
  my $markers = $default->{showmarkers};
  my ($plot, $this, $command, $scr, $title) =
    ("newplot", "", "", $default->{screen}, ", title=\"$lab\"");
  my $esh = $self->{bkg_eshift};
  if ($norm)   { ($pre, $post) = (0,0); }; # no pre or post in norm or deriv
  if ($der)    { ($not, $pre, $post) = (0,0,0); };
  if ($second) { ($not, $pre, $post) = (0,0,0); };
  if ($deg)    { $not = 0; };
  if ($deg and ($self->{deg_emax} < $self->{bkg_e0})) { ($pre, $post) = (1,0); };
  if ($deg and ($self->{deg_emin} > $self->{bkg_e0})) { ($pre, $post) = (0,1); };
  if ($self->{not_data}) { ($not, $pre, $post) = (0,0,0); };
  if ($self->{is_xanes}) { $not = 0;};

  my $xrange = "";

  if ($rpf) {
    my @xrange = ($self->{bkg_e0}+$$rpf{emin}, $self->{bkg_e0}+$$rpf{emax});
    $xrange = ", xmin=$xrange[0], xmax=$xrange[1]";
  };
  my $func = "";
  ## y-axis label
  if ($norm and $der) {
    $func = "deriv of norm ";
  } elsif ($norm) {
    $func = "norm ";
  } elsif ($der) {
    $func = "deriv ";
  } elsif ($second) {
    $func = "second deriv ";
  };
  ($func = "smoothed $func") if $smooth;
  my $labels = ", xlabel=\"E (eV)\", ylabel=\"${func}x\\gm(E)\"";
  ($self->{update_bkg}) and $self->dispatch_bkg($mode);
  ## this next bit must be done after the call to dispatch_bkg
  if ($not_data) {
    my @e = Ifeffit::get_array("$group.energy");
    $self->_MAKE(bkg_e0=>$e[0]-$$rpf{emin}) unless $self->{bkg_e0};
  } elsif ($self->{is_nor}) {
    my $cmd = sprintf("set(___x = npts(%s.energy), %s.preline = zeros(___x))", $group, $group);
    $self->dispose("$cmd", $mode);
  #} else {
    ##print "in plotE: ", Ifeffit::get_scalar("pre_slope"), " ",
    ##Ifeffit::get_scalar("pre_offset"), $/;
    ##     $self->_MAKE(bkg_slope => Ifeffit::get_scalar("pre_slope"),
    ##     		bkg_int	  => Ifeffit::get_scalar("pre_offset"),);
    ##     my $cmd = sprintf("set %s.preline = %g+%g*(%s.energy + %g)",
    ## 		      $group, $self->{bkg_int}, $self->{bkg_slope}, $group, $self->{bkg_eshift});
    ##     $self->dispose("$cmd", $mode);
  };
  $self->_MAKE(update_bkg=>0);

  if ($str =~ /(s+)/) {
    my $iterations = length($1);
    my $suff = 'xmu';
    if ($self->{not_data}) {
      $suff = 'det';
    } elsif ($norm) {
      $suff = 'norm';
    };
    $self->dispose("set $group.smooth = $group.$suff", $mode);
    foreach (1 .. $iterations) {
      $self->dispose("set $group.smooth = smooth($group.smooth)", $mode);
    };
  };

  if ($not) {			# plot the background as raw or normalized
    $color = $default->{'color1'};
    ##my $plot_scale_this = ($self->{is_diff}) ? "$plot_scale" : "1";
    my $plot_scale_this = "$plot_scale";
    if ($norm) {
      if ($clnorm) {
	$this= sprintf("%s(%s.energy+%s, \"%s*%s.f2norm+%s\"%s%s %s, style=lines, color=\"%s\", key=bkg%s)",
		       $plot, $group, $esh, $plot_scale_this, $group, $yoffset,
		       $labels, $scr, $xrange, $color, $title);
      } elsif ($self->{is_nor}) {
	$this= sprintf("%s(%s.energy+%s, \"%s*%s.fbkg+%s\"%s%s%s, style=lines, color=\"%s\", key=bkg%s)",
		       $plot, $group, $esh, $plot_scale_this, $group, $yoffset,
		       $labels, $scr, $xrange, $color, $title);
      } elsif ($self->{bkg_flatten}) {
	$this= sprintf("%s(%s.energy+%s, \"%s*%s.fbkg+%s\"%s%s%s, style=lines, color=\"%s\", key=bkg%s)",
		       $plot, $group, $esh, $plot_scale_this, $group, $yoffset,
		       $labels, $scr, $xrange, $color, $title);
      } else {
	$this= sprintf("%s(%s.energy+%s, \"%s*(%s.bkg-%s.preline)/%f+%s\"%s%s %s, style=lines, color=\"%s\", key=bkg%s)",
		       $plot, $group, $esh, $plot_scale_this, $group,
		       $group, $self->{bkg_step}, $yoffset,
		       $labels, $scr, $xrange, $color, $title);
      };
      $this = wrap("", " " x (length($plot)+1), $this) . $/;
      $command .= $this;
      $markers and
	push @markers_e, $self->{bkg_e0}; #+$self->{bkg_eshift};
    } else {
      if ($clnorm) {
	$this = sprintf("%s(%s.energy+%s, \"%s*%s.f2+%s\"%s%s %s, style=lines, color=\"%s\", key=bkg%s)",
			$plot, $group, $esh, $plot_scale_this, $group, $yoffset, $labels, $scr, $xrange, $color, $title);
      } else {
	$this = sprintf("%s(%s.energy+%s, \"%s*%s.bkg+%s\"%s%s %s, style=lines, color=\"%s\", key=bkg%s)",
			$plot, $group, $esh, $plot_scale_this, $group, $yoffset, $labels, $scr, $xrange, $color, $title);
      };
      $this = wrap("", " " x (length($plot)+1), $this) . $/;
      $command .= $this;
      $markers and
	push @markers_e, $self->{bkg_e0}; #+$self->{bkg_eshift};
    };
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($mu) {			# plot the data as raw, normalized, or derivative
    $color = $default->{'color0'};
    my $style = $$rpf{linestyle};
    if ($der and $norm) {
      my $suff = ($not_data) ? 'det' : 'norm';
      my $task = "deriv";
      if ($smooth) {
	#$command .= "set $group.der = deriv($group.smooth)\n";
	($task, $suff) = ("deriv", "smooth");
      };
      $this = sprintf("%s(%s.energy+%s, \"%s*(%s(%s.%s)/deriv(%s.energy))+%s\"%s%s %s, style=%s, color=\"%s\", key=\"\\gm\"%s)",
		      $plot, $group, $esh, $plot_scale, $task, $group, $suff, $group,
		      $yoffset, $labels, $scr,
		      $xrange, $style, $color, $title);
      $this = wrap("", " " x (length($plot)+1), $this) . $/;
      $command .= $this;
      $markers and push @markers_e, $self->{bkg_e0}; #+$self->{bkg_eshift};
    } elsif ($norm) {
      my $suff;
      if ($smooth) {
	$suff = 'smooth';
      } elsif ($not_data) {
	$suff = 'det';
      } elsif ($self->{bkg_flatten}) {
	$suff = 'flat';
      } else {
	$suff = 'norm';
      };
      #($self->{is_nor}) and ($suff = 'xmu');
      #my $plot_scale_this = ($self->{is_diff}) ? "$plot_scale" : "1";
      my $plot_scale_this = "$plot_scale";
      $this = sprintf("%s(%s.energy+%s, \"%s*%s.%s+%s\"%s%s %s, style=%s, color=\"%s\", key=\"\\gm\"%s)",
		      $plot, $group, $esh,
		      $plot_scale_this, $group, $suff, $yoffset,
		      $labels, $scr, $xrange, $style, $color, $title);
      $this = wrap("", " " x (length($plot)+1), $this) . $/;
      $command .= $this;
    } elsif ($der) {
      my $suff = ($not_data) ? 'det' : 'xmu';
      my $task = "deriv";
      if ($smooth) {
	#$command .= "set $group.der = deriv($group.smooth)\n";
	($task, $suff) = ("deriv", "smooth");
      };
      $this = sprintf("%s(%s.energy+%s, \"%s*(%s(%s.%s)/deriv(%s.energy))+%s\"%s%s %s, style=%s, color=\"%s\", key=\"\\gm\"%s)",
		      $plot, $group, $esh, $plot_scale, $task, $group, $suff, $group,
		      $yoffset, $labels, $scr,
		      $xrange, $style, $color, $title);
      $this = wrap("", " " x (length($plot)+1), $this) . $/;
      $command .= $this;
      $markers and push @markers_e, $self->{bkg_e0}; #+$self->{bkg_eshift};
    } elsif ($second) {
      my $suff = ($not_data) ? 'det' : 'xmu';
      $suff = 'smooth' if $smooth;
      my $task = "deriv";
      $command .= "## plotting second derivative\n";
      $command .= "set $group.der = deriv($group.$suff)/deriv($group.energy)\n";
      $suff = 'der';
      $this = sprintf("%s(%s.energy+%s, \"%s*(%s(%s.%s)/deriv(%s.energy))+%s\"%s%s %s, style=%s, color=\"%s\", key=\"\\gm\"%s)",
		      $plot, $group, $esh, $plot_scale, $task, $group, $suff, $group,
		      $yoffset, $labels, $scr,
		      $xrange, $style, $color, $title);
      $this = wrap("", " " x (length($plot)+1), $this) . $/;
      $command .= $this;
      $markers and push @markers_e, $self->{bkg_e0}; #+$self->{bkg_eshift};
    } else {
      my $suff = ($not_data) ? 'det' : 'xmu';
      ($suff = "smooth") if $smooth;
      #my $plot_scale_this = ($self->{is_diff}) ? "$plot_scale" : "1";
      my $plot_scale_this = "$plot_scale";
      $this = sprintf("%s(%s.energy+%s, \"%s*%s.%s+%s\"%s%s %s, style=%s, color=\"%s\", key=\"\\gm\"%s)",
		      $plot, $group, $esh, $plot_scale_this, $group, $suff, $yoffset, $labels, $scr,
		      $xrange, $style, $color, $title);
      $this = wrap("", " " x (length($plot)+1), $this) . $/;
      $command .= $this;
    };
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($pre) { # plot the pre-edge lines and pre? markers
    $color = $default->{'color2'};
    $this = sprintf("%s(%s.energy+%s, \"%s.preline+%s\"%s%s %s, style=lines, color=\"%s\", key=pre%s)",
		    $plot, $group, $esh, $group, $yoffset, $labels, $scr, $xrange, $color, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "", "");
    ++$cnt;
    $markers and (not $deg) and
      push @markers_e, $self->{bkg_pre1}+$self->{bkg_e0}, #+$self->{bkg_eshift},
                       $self->{bkg_pre2}+$self->{bkg_e0}; #+$self->{bkg_eshift};
    ## plot deglitching line in pre-edge
    if ($deg) {
      $color = $default->{'color4'};
      my @x = Ifeffit::get_array("$group.energy");
      my @y = Ifeffit::get_array("$group.preline");
      my ($i, $j) = (0,0);
      foreach (@x) {
	last if ($_ > $self->{deg_emin});
	++$i;
      };
      foreach (@x) {
	last if ($_ > $self->{deg_emax});
	++$j;
      };
      @x=splice(@x, $i, $j-$i);
      @y=splice(@y, $i, $j-$i);
      Ifeffit::put_array("$group.edeg", \@x);
      Ifeffit::put_array("$group.xdeg", \@y);
      $command .= "## deglitching margin lines are not available for plotting in a macro.\n";
      $command .= sprintf("plot(%s.edeg+%s, \"%s.xdeg+%g+%s\", style=lines, color=\"%s\", key=toler)\n",
			  $group, $esh, $group, $self->{deg_tol}, $yoffset, $color);
      $command .= sprintf("plot(%s.edeg+%s, \"%s.xdeg-%g+%s\", style=lines, color=\"%s\")\n",
			  $group, $esh, $group, $self->{deg_tol}, $yoffset, $color);
      push @markers_e, $self->{deg_emin}, #+$self->{bkg_eshift},
                       $self->{deg_emax}; #+$self->{bkg_eshift};
      ++$cnt;
    };
  };
  if ($post and (not $self->{bkg_fixstep})) { # plot the post-edge line and nor? markers
    $color = $default->{'color3'};
    my $cmd;
    if ($self->{is_merge} eq 'n') {

      my ($flat1, $flat2) = ($self->{bkg_e0}+$self->{bkg_nor1}-$self->{bkg_eshift},
			     $self->{bkg_e0}+$self->{bkg_nor2}-$self->{bkg_eshift});
      my $shift = $self->{bkg_eshift};
      my $suff = 'xmu';
      $cmd = "# postline for normalized records\n";
      $cmd = "guess(flat_c0=0)\n";
      if (($flat2-$flat1) < 300) {
	if ($self->{bkg_nnorm} == 1) {
	  $cmd .= "set(flat_c1=0)\n";
	} else {
	  $cmd .= "guess(flat_c1=0)\n";
	};
	$cmd .= "set  (flat_c2=0)\n";
      } elsif ($self->{bkg_nnorm} == 2) {
	$cmd .= "guess(flat_c1=0)\n";
	$cmd .= "set  (flat_c2=0)\n";
      } elsif ($self->{bkg_nnorm} == 1) {
	$cmd .= "set(flat_c1=0, flat_c2=0)\n";
      } else {
	$cmd .= "guess(flat_c1=0, flat_c2=0)\n";
      };
      $cmd .= "def($group.postline = (flat_c0 + flat_c1*($group.energy+$shift) + flat_c2*($group.energy+$shift)**2)),\n";
      $cmd .= "    $group.resid = $group.$suff - $group.postline)\n";
      $cmd .= "minimize($group.resid, x=$group.energy, xmin=$flat1, xmax=$flat2)\n";
      $cmd .= "unguess\n";
    } else {
      $cmd = sprintf("# postline for non-normalized records\nset %s.postline = %g+%g*(%s.energy+%g)+%g*(%s.energy+%g)**2\n",
		     $group, $self->{bkg_nc0},
		     $self->{bkg_nc1}, $group, $self->{bkg_eshift},
		     $self->{bkg_nc2}, $group, $self->{bkg_eshift});
    };
    $self->dispose($cmd, $mode);
    $this = sprintf("%s(%s.energy+%s, \"%s.postline+%s\"%s%s %s, style=lines, color=\"%s\", key=post%s)",
		    $plot, $group, $esh, $group, $yoffset, $labels, $scr, $xrange, $color, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title, $xrange) = ("plot", "", "", "");
    ++$cnt;
    $markers and (not $deg) and
      push @markers_e, $self->{bkg_nor1}+$self->{bkg_e0}, #+$self->{bkg_eshift},
                       $self->{bkg_nor2}+$self->{bkg_e0}; #+$self->{bkg_eshift};
    ## plot deglitching line in post-edge
    if ($deg) {
      $color = $default->{'color4'};
      my @x = Ifeffit::get_array("$group.energy");
      my @y = Ifeffit::get_array("$group.postline");
      my ($i, $j) = (0,0);
      foreach (@x) {
	last if ($_ > $self->{deg_emin});
	++$i;
      };
      foreach (@x) {
	last if ($_ > $self->{deg_emax});
	++$j;
      };
      @x=splice(@x, $i, $j-$i);
      @y=splice(@y, $i, $j-$i);
      Ifeffit::put_array("$group.edeg", \@x);
      Ifeffit::put_array("$group.xdeg", \@y);
      $command .= "## deglitching margin lines are not available for plotting in a macro.\n";
      $command .= sprintf("plot(%s.edeg+%s, \"%s.xdeg+%g+%s\", style=lines, color=\"%s\", key=toler)\n",
			  $group, $esh, $group, $self->{deg_tol}, $yoffset, $color);
      $command .= sprintf("plot(%s.edeg+%s, \"%s.xdeg-%g+%s\", style=lines, color=\"%s\")\n",
			  $group, $esh, $group, $self->{deg_tol}, $yoffset, $color);
      push @markers_e, $self->{deg_emin}, #+$self->{bkg_eshift},
                       $self->{deg_emax}; #+$self->{bkg_eshift};
      ++$cnt;
    };
  };
  if (not $deg and @markers_e and not $$rpf{suppress_markers}) {
    @markers_e = sort {$a <=> $b} @markers_e;
    my $suff = ($norm) ? "norm" : "xmu";
    ($suff = 'flat') if ($norm and $self->{bkg_flatten});
    #($self->{is_nor}) and ($suff = "xmu");
    if ($der) {
      foreach my $e (@markers_e) {
	if ($smooth) {
	  $command .= "pmarker \"$group.energy+$self->{bkg_eshift}\", \"deriv($group.smooth)/deriv($group.energy)\", $e, $default->{marker}, $default->{markercolor}, $yoffset\n";
	} else {
	  $command .= "pmarker \"$group.energy+$self->{bkg_eshift}\", \"deriv($group.$suff)/deriv($group.energy)\", $e, $default->{marker}, $default->{markercolor}, $yoffset\n";
	};
      };
    } elsif ($second) {
      foreach my $e (@markers_e) {
	if ($smooth) {
	  $command .= "set $group.der = deriv($group.smooth)/deriv($group.energy)\n";
	} else {
	  $command .= "set $group.der = deriv($group.$suff)/deriv($group.energy)\n";
	};
	$command .= "pmarker \"$group.energy+$self->{bkg_eshift}\", \"deriv($group.der)/deriv($group.energy)\", $e, $default->{marker}, $default->{markercolor}, $yoffset\n";
      };
    } else {
      foreach my $e (@markers_e) {
	$command .= "pmarker \"$group.energy+$self->{bkg_eshift}\", $group.$suff, $e, $default->{marker}, $default->{markercolor}, $yoffset\n";
      };
    };
  };

  &$echocmd("> plotting in energy from group \`$lab\'");
  ##$command = wrap("", "", $command);
  $self->dispose("$command", $mode);
  $last_plot = $command;

  if ($$indicators[0]) {
    my $suff = ($norm) ? "norm" : "xmu";
    ($suff = "det") if $not_data;
    my $sets = q{};
    if ($der) {
      $sets = "set(i___ndic.y = deriv($group.$suff)/deriv($group.energy)+$yoffset,\n";
    } else {
      $sets = "set(i___ndic.y = $group.$suff+$yoffset,\n";
    };
    my $eshift = $self->{bkg_eshift};
    $sets .= "    i___ndic.x = $group.energy+$eshift)";
    $self->dispose($sets, $mode);
    my @x = Ifeffit::get_array("i___ndic.x");
    my @y = Ifeffit::get_array("i___ndic.y");
    my ($ymin, $ymax) = $self->floor_ceil(\@x, \@y, $rpf, 'e', $self->{bkg_e0});
    #print join("|", $not_data, $ymin, $ymax), $/;
    #(($ymin, $ymax) = ($plot_scale*$ymin, $plot_scale*$ymax)) if ($not_data);
    my $diff = $ymax-$ymin;
    $ymin -= $diff/20;
    $ymax += $diff/20;
    foreach my $i (@$indicators) {
      next if ($i =~ /^[01]$/);
      next if (lc($i->[1]) =~ /[r\s]/);
      next if (lc($i->[2]) =~ /\A\s*\z/);
      my $val = $i->[2];
      ($val = $self->k2e($val)+$self->{bkg_e0}) if (lc($i->[1]) =~ /[kq]/);
      next if ($val < 0);
      $self->plot_vertical_line($val, $ymin, $ymax, $mode, "", 0, 0, 1)
    };
  };


  &$echocmd("> plotting in energy from group \`$lab\' ... done!");
  if ($post and ($self->{bkg_fixstep})) {
    &$echocmd("> Post edge line not plotted because the edge step was fixed.")
  };
  &$errorcmd("> \`$lab\' has a plot multiplier of zero.  Is that what you want?")
    unless ($self->{plot_scale});
};

sub floor_ceil {
  my $self = shift;
  my ($x, $y, $rpf, $space, $e0) = @_;
  my ($ymin, $ymax, $i) = (1e10, -1e10, -1);
  foreach my $xx (@$x) {
    ++$i;
    next if ($xx < $$rpf{$space.'min'}+$e0);
    last if ($xx > $$rpf{$space.'max'}+$e0);
    ($ymin = $$y[$i]) if ($$y[$i] < $ymin);
    ($ymax = $$y[$i]) if ($$y[$i] > $ymax);
  };
  return ($ymin, $ymax);
};

## the argument is a character string which is decoded to indicate the
## k-weighting and whether the k-window should be plotted
sub plotk {
  my $self = shift;
  my ($group, $lab) = ($self->{group}, $self->{label});
  my $e0    = $self->{bkg_e0};
  unless (($self->{is_xmu}) or ($self->{is_chi})) {
    if ($group eq "Default Parameters") {
      &$errorcmd("> No data!");
      return 0;
    };
    &$errorcmd("> The group \"$lab\" cannot be plotted in k-space.");
    return 0;
  };
  my ($str, $mode, $rpf, $indicators) = (lc($_[0]), $_[1], $_[2], $_[3]);
  ##($str eq 'k') and ($str = 'kw');
  my $win = $$rpf{k_win};  #((length($str) > 2) and ($str =~ /w$/)) ? 1 : 0;
  my ($this, $command, $scale, $weight, $scr, $plot_scale, $yoffset) =
    ("", "", 1, 1, $default->{screen}, $self->{plot_scale}, $self->{plot_yoffset});
  my $color = $default->{color0};
  ($self->{is_xmu}) and ($self->{update_bkg}) and $self->dispatch_bkg($mode);
  $self->_MAKE(update_bkg=>0);

  ##($str =~ /^kw/) and ($weight = $self->{fft_arbkw}); # parse indicator string
  ##($str =~ /^k([\d])/) and ($weight=$1);
  ##---
  ## getting the new k-weighting scheme working....
  $weight = ($$rpf{kw} eq 'kw') ? $self->{fft_arbkw} : $$rpf{kw};
  $str .= $$rpf{chie};
  ##---
  my $xrange = "";
  if ($rpf) {
    $xrange = "xmin=$$rpf{kmin}, xmax=$$rpf{kmax}, ";
  };

  ## determine parameters for legend

  my $k;
  $k = "k\\u$weight\\d ";
  ($weight == 0) and ($k = "");
  ($weight == 1) and ($k = "k ");
  ($weight >= 2) and ($k = "k\\u$weight\\d ");
  my $suff = "k";
  $this = sprintf("newplot(%s.%s, \"(%s*%s.chi*%s.k^%.3g)+%s\",%s xlabel=\"k (\\A\\u-1\\d)\",ylabel=\"%s\\gx(k)\"%s, style=lines, color=\"%s\", key=\\gx(k), title=\"%s\")",
		  $group, $suff, $plot_scale, $group, $group, $weight, $yoffset,
		  $xrange, $k, $scr, $color, $lab);
  if ($str =~ /e/) {
    $suff = 'eee';
    $command .= "$group.eee = $group.k^2/etok+$e0$/";
    $xrange = "";
    if ($rpf) {
      my @xrange = ($self->{bkg_e0}+$$rpf{emin}, $self->{bkg_e0}+$$rpf{emax});
      $xrange = " xmin=$xrange[0], xmax=$xrange[1], ";
    };
    ## labels are different for a chi(E) plot
    $this = sprintf("newplot(%s.%s, \"(%s*%s.chi*%s.k^%.3g)+%s\",%s xlabel=\"E (eV)\",ylabel=\"%s\\gx(E)\"%s, style=lines, color=\"%s\", key=\\gx(E), title=\"%s\")",
		    $group, $suff, $plot_scale, $group, $group, $weight, $yoffset,
		    $xrange, $k, $scr, $color, $lab);
  };
  ## test if background removal is up to date
  $this = wrap("", "        ", $this) . $/;
  $command .= $this;
  if ($win) {
    ($self->{update_fft}) and $self->do_fft($mode, $rpf);
    $self->_MAKE(update_fft=>0);
    ifeffit("set ___x = ceil($group.chi*$plot_scale*$group.k^$weight)"); # scale window to plot
    $scale = 1.05 * Ifeffit::get_scalar("___x");
    $color = $default->{color1};
    my $suff = ($str =~ /e/) ? "eee" : "k";
    $this = sprintf("plot(%s.$suff, \"%s.win*%f+%s\", style=lines, color=\"%s\", key=window)",
		    $group, $group, $scale, $yoffset, $color);
    $this = wrap("", "     ", $this) . $/;
    $command .= $this;
  };
  #$command .= ("plot(title=$group)\n");
  ##print $command;
  &$echocmd("> plotting in k-space from group \`$lab\'");
  ##$command = wrap("", "", $command);
  $self->dispose($command, $mode);

  if ($$indicators[0]) {
    ifeffit("set i___ndic.x = $plot_scale*$group.chi*$group.k^$weight+$yoffset");
    my @x = Ifeffit::get_array("$group.$suff");
    my @y = Ifeffit::get_array("i___ndic.x");
    my $this = ($suff eq 'k') ? 0 : $e0;
    my ($ymin, $ymax) = $self->floor_ceil(\@x, \@y, $rpf, 'e', $this);
    $ymin *= 1.05;
    $ymax *= 1.05;
    foreach my $i (@$indicators) {
      next if ($i =~ /^[01]$/);
      next if (lc($i->[1]) =~ /[r\s]/);
      next if (lc($i->[2]) =~ /\A\s*\z/);
      my $val = $i->[2];
      ($val = $self->e2k($val)) if ((lc($i->[1]) eq "e") and ($suff eq 'k'));
      ($val = $self->k2e($val)) if ((lc($i->[1]) ne "e") and ($suff ne 'k'));
      next if ($val < 0);
      $self->plot_vertical_line($val, $ymin, $ymax, $mode, "", 0, 0, 1)
    };

##     foreach my $i (@$indicators) {
##       next if ($i =~ /^[01]$/);
##       next if (lc($i->[1]) =~ /[r\s]/);
##       my $val = $i->[2];
##       ($val = $self->e2k($val)) if (lc($i->[1]) eq "e");
##       next if ($val < 0);
##       ifeffit("set ___x = ceil($plot_scale*$group.chi*$group.k^$weight+$yoffset)");
##       my $ymax = Ifeffit::get_scalar("___x") * 1.05;
##       ifeffit("set ___x = floor($plot_scale*$group.chi*$group.k^$weight+$yoffset)");
##       my $ymin = Ifeffit::get_scalar("___x") * 1.05;
##       $self->plot_vertical_line($val, $ymin, $ymax, $mode, "", 0, 0, 1)
##     };
  };

  $last_plot = $command;
  ($self->{plot_scale}) ? &$echocmd("> plotting in k-space from group \`$lab\' ... done!") :
    &$errorcmd("> \`$lab\' has a plot multiplier of zero.  Is that what you want?");
};

## the argument is a character string which is decoded to indicate
## which of magnitude, phase, real, and imaginary should be plotted
## and whether the R-window should be plotted.  There is also the
## option of plotting the envelope, which is the magnitude plotted
## with the negated magnitude
sub plotR {
  my $self = shift;
  my ($group, $lab) = ($self->{group}, $self->{label});
  if (($self->{is_qsp}) or ($group eq 'Default Parameters') or ($self->{not_data})) {
    if ($group eq "Default Parameters") {
      &$errorcmd("> No data!");
      return 0;
    };
    &$errorcmd("> The group \"$lab\" cannot be plotted in R space.");
    return 0;
  };
  #my $w =  $self->{fft_kw} + 1;
  my ($str, $mode, $rpf, $indicators) = (lc(substr($_[0], 1)), $_[1], $_[2], $_[3]);
  my $w = $$rpf{kw} + 1;
  #($str eq 'r') and ($str = 'rm');
  my $win = 0;
  ($str =~ /w$/) and ($win = 1);
  my ($this, $command, $plot, $scale, $scr, $title, $plot_scale, $yoffset) =
    ("", "", "newplot", 1, $default->{screen}, ", title=\"$lab\"", $self->{plot_scale}, $self->{plot_yoffset});
  my $labels = sprintf(", xlabel=\"R (\\A)\", ylabel=\"|\\gx(R)| (\\A\\u-%d\\d)\"", $w);
  my $cnt = 0;
  my $color;
  my $xrange = "";
  if ($rpf) {
    $xrange = ", xmin=$$rpf{rmin}, xmax=$$rpf{rmax}";
  };
  ($self->{update_bkg}) and $self->dispatch_bkg($mode);
  $self->_MAKE(update_bkg=>0);
  ($self->{update_fft}) and $self->do_fft($mode, $rpf);
  $self->_MAKE(update_fft=>0);

  if ($str =~ /e/) {
    $color = $default->{'color'.$cnt};
    $this = sprintf("%s(%s.r, \"%s*%s.chir_mag+%s\"%s%s %s, style=lines, color=\"%s\", key=\"Env[\\gx(R)]\"%s)",
		    $plot, $group, $plot_scale, $group, $yoffset,
		    $labels, $scr, $xrange, $color, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    $this = sprintf("plot(%s.r, \"-%s*%s.chir_mag+%s\", style=lines, color=\"%s\", key=\"\")",
		    $group, $plot_scale, $group, $yoffset, $color);
    $this = wrap("", "     ", $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($str =~ /m/) {
    $color = $default->{'color'.$cnt};
    $this = sprintf("%s(%s.r, \"%s*%s.chir_mag+%s\"%s%s %s, style=lines, color=\"%s\", key=\"|\\gx(R)|\"%s)",
		    $plot, $group, $plot_scale, $group, $yoffset,
		    $labels, $scr, $xrange, $color, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($str =~ /r/) {
    $color = $default->{'color'.$cnt};
    $this = sprintf("%s(%s.r, \"%s*%s.chir_re+%s\"%s%s %s, style=lines, color=\"%s\", key=\"Re[\\gx(R)]\"%s)",
		    $plot, $group, $plot_scale, $group, $yoffset,
		    $labels, $scr, $xrange, $color, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($str =~ /i/) {
    $color = $default->{'color'.$cnt};
    $this = sprintf("%s(%s.r, \"%s*%s.chir_im+%s\"%s%s %s, style=lines, color=\"%s\", key=\"Im[\\gx(R)]\"%s)",
		    $plot, $group, $plot_scale, $group, $yoffset,
		    $labels, $scr, $xrange, $color);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($str =~ /p/) {
    $color = $default->{'color'.$cnt};
    $this = sprintf("%s(%s.r, \"%s.chir_pha+%s\"%s%s %s, style=lines, color=\"%s\", key=\"Phase[\\gx(R)]\"%s)",
		    $plot, $group, $group,, $yoffset,
		    $labels, $scr, $xrange, $color, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($win) {			# need to scale it
    ($self->{update_bft}) and $self->do_bft($mode);
    $self->_MAKE(update_bft=>0);
    ifeffit("set ___x = ceil($group.chir_mag)"); # scale window to plot
    $scale = 1.05 * $plot_scale * Ifeffit::get_scalar("___x");
    $color = $default->{'color'.$cnt};
    $this = sprintf("%s(%s.r, \"%s.rwin*%.2f+%s\"%s%s %s, style=lines, color=\"%s\", key=window%s)",
		    $plot, $group, $group, $scale, $yoffset,
		    $labels, $scr, $xrange, $color, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr) = ("plot", "", "", "");
    ++$cnt;
  };
  ##print $command;
  &$echocmd("> plotting in R-space from group \`$lab\'");
  ## $command = wrap("", "", $command);
  $self->dispose($command, $mode);
  if ($$indicators[0]) {
    my $suff = "chir_re";
    ($suff = "chir_mag") if ($str !~ /[eir]/);
    ($suff = "chir_pha") if ($str =~ /p/);
    ifeffit("set i___ndic.x = $plot_scale*$group.$suff+$yoffset");
    my @x = Ifeffit::get_array("$group.r");
    my @y = Ifeffit::get_array("i___ndic.x");
    my ($ymin, $ymax) = $self->floor_ceil(\@x, \@y, $rpf, 'r', 0);
    $ymin *= 1.05;
    $ymax *= 1.05;
    foreach my $i (@$indicators) {
      next if ($i =~ /^[01]$/);
      next unless (lc($i->[1]) eq 'r');
      next if (lc($i->[2]) =~ /\A\s*\z/);
      my $val = $i->[2];
      next if ($val < 0);
      $self->plot_vertical_line($val, $ymin, $ymax, $mode, "", 0, 0, 1)
    };

  };


  $last_plot = $command;
  ($self->{plot_scale}) ? &$echocmd("> plotting in R-space from group \`$lab\' ... done!") :
    &$errorcmd("> \`$lab\' has a plot multiplier of zero.  Is that what you want?");
};

## the argument is a character string which is decoded to indicate
## which of magnitude, phase, real, and imaginary should be plotted
## and whether the k-window should be plotted.  There is also the
## option of plotting the envelope, which is the magnitude plotted
## with the negated magnitude
sub plotq {
  my $self = shift;
  my ($group, $lab) = ($self->{group}, $self->{label});
  if (($group eq 'Default Parameters') or ($self->{not_data})) {
    if ($group eq "Default Parameters") {
      &$errorcmd("> No data!");
      return 0;
    };
    &$errorcmd("> The group \"$lab\" cannot be plotted in q space.");
    return 0;
  };
  my ($str, $mode, $rpf, $indicators) = (lc($_[0]), $_[1], $_[2], $_[3]);
  ($str eq 'q') and ($str = 'qi');
  my $win = 0;
  ($str =~ /w$/) and ($win = 1);
  my ($this, $command, $plot, $scale, $scr, $title, $plot_scale, $yoffset) =
    ("", "", "newplot", 1, $default->{screen}, ", title=\"$lab\"", $self->{plot_scale}, $self->{plot_yoffset});
  #my $w =  $self->{fft_kw};
  my $w = $$rpf{kw};
  my $labels = sprintf(", xlabel=\"k (\\A\\u-1\\d)\",ylabel=\"|\\gx(q)| (\\A\\u-%d\\d)\"", $w);
  my $cnt = 0;
  my $color;
  my $xrange = "";
  if ($rpf) {
    $xrange = "xmin=$$rpf{qmin}, xmax=$$rpf{qmax}, ";
  };
  ($self->{update_bkg}) and $self->dispatch_bkg($mode);
  $self->_MAKE(update_bkg=>0);
  ($self->{update_fft}) and $self->do_fft($mode, $rpf);
  $self->_MAKE(update_fft=>0);
  ($self->{update_bft}) and $self->do_bft($mode);
  $self->_MAKE(update_bft=>0);

  if ($str =~ /e/) {
    $color = $default->{'color'.$cnt};
    $this = sprintf("%s(%s.q, \"%s*%s.chiq_mag+%s\"%s%s, style=lines, color=\"%s\",%s key=\"Env[\\gx(q)]\"%s)",
		    $plot, $group, $plot_scale, $group, $yoffset,
		    $labels, $scr, $color, $xrange, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    $this = sprintf("plot(%s.q, \"-%s*%s.chiq_mag+%s\", style=lines, color=\"%s\", key=\"\")",
		    $group, $plot_scale, $group, $yoffset, $color);
    $this = wrap("", "     ", $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($str =~ /m/) {
    $color = $default->{'color'.$cnt};
    $this = sprintf("%s(%s.q, \"%s*%s.chiq_mag+%s\"%s%s, style=lines, color=\"%s\",%s key=\"|\\gx(q)|\"%s)",
		    $plot, $group, $plot_scale, $group, $yoffset,
		    $labels, $scr, $color, $xrange, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($str =~ /r/) {
    $color = $default->{'color'.$cnt};
    $this = sprintf("%s(%s.q, \"%s*%s.chiq_re+%s\"%s%s, style=lines, color=\"%s\",%s key=\"Re[\\gx(q)]\"%s)",
		    $plot, $group, $plot_scale, $group, $yoffset,
		    $labels, $scr, $color, $xrange, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($str =~ /i/) {
    $color = $default->{'color'.$cnt};
    $this = sprintf("%s(%s.q, \"%s*%s.chiq_im+%s\"%s%s, style=lines, color=\"%s\",%s key=\"Im[\\gx(q)]\"%s)",
		    $plot, $group, $plot_scale, $group, $yoffset,
		    $labels, $scr, $color, $xrange, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($str =~ /p/) {
    $color = $default->{'color'.$cnt};
    $this = sprintf("%s(%s.q, \"%s.chiq_pha+%s\"%s%s, style=lines, color=\"%s\",%s key=\"Phase[\\gx(q)]\"%s)",
		    $plot, $group, $group, $yoffset,
		    $labels, $scr, $color, $xrange, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  if ($win) {			# need to scale it correctly
    $color = $default->{'color'.$cnt};
    ifeffit("set ___x = ceil($group.chiq_mag)"); # scale window to plot
    $scale = 1.05 * $plot_scale * Ifeffit::get_scalar("___x");
    $this = sprintf("%s(%s.q, \"%s.win*%.2f+%s\", style=lines, color=\"%s\",%s key=window%s)",
		    $plot, $group, $group, $scale, $yoffset, $color, $title);
    $this = wrap("", " " x (length($plot)+1), $this) . $/;
    $command .= $this;
    ($plot, $labels, $scr, $title) = ("plot", "", "", "");
    ++$cnt;
  };
  ##print $command;
  &$echocmd("> plotting in q-space from group \`$lab\'");
  ##$command = wrap("", "", $command);
  $self->dispose($command, $mode);
  if ($$indicators[0]) {
    my $suff = "chiq_re";
    ($suff = "chiq_mag") if ($str !~ /[eir]/);
    ($suff = "chiq_pha") if ($str =~ /p/);
    ifeffit("set i___ndic.x = $plot_scale*$group.$suff+$yoffset");
    my @x = Ifeffit::get_array("$group.q");
    my @y = Ifeffit::get_array("i___ndic.x");
    my ($ymin, $ymax) = $self->floor_ceil(\@x, \@y, $rpf, 'q', 0);
    $ymin *= 1.05;
    $ymax *= 1.05;
    foreach my $i (@$indicators) {
      next if ($i =~ /^[01]$/);
      next if (lc($i->[1]) =~ /[r\s]/);
      next if (lc($i->[2]) =~ /\A\s*\z/);
      my $val = $i->[2];
      ($val = $self->e2k($val)) if (lc($i->[1]) eq "e");
      next if ($val < 0);
      $self->plot_vertical_line($val, $ymin, $ymax, $mode, "", 0, 0, 1)
    };
  };
  $last_plot = $command;
  ($self->{plot_scale}) ? &$echocmd("> plotting in q-space from group \`$lab\' ... done!") :
    &$errorcmd("> \`$lab\' has a plot multiplier of zero.  Is that what you want?");
};


## the argument is a character string which is decoded to indicate the
## k-weighting and whether the k-window should be plotted
sub plotkq {
  my $self = shift;
  my ($group, $lab) = ($self->{group}, $self->{label});
  unless (($self->{is_xmu}) or ($self->{is_chi})) {
    if ($group eq "Default Parameters") {
      &$errorcmd("> No data!");
      return 0;
    };
    &$errorcmd("> The group \"$lab\" cannot be plotted in k-space.");
    return 0;
  };
  my ($str, $mode, $rpf, $indicators) = (lc($_[0]), $_[1], $_[2], $_[3]);
  my $win = ($str =~ /w/) ? 1 : 0;
  my ($this, $command, $scale, $weight, $scr, $plot_scale, $yoffset) =
    ("", "", 1, 1, $default->{screen}, $self->{plot_scale}, $self->{plot_yoffset});
  my $color = $default->{color0};
  #$weight = $self->{fft_kw};
  $weight = $$rpf{kw};
  my $xrange = "";
  if ($rpf) {
    $xrange = "xmin=$$rpf{kmin}, xmax=$$rpf{kmax}, ";
  };

  ($self->{is_xmu}) and ($self->{update_bkg}) and $self->dispatch_bkg($mode);
  ($self->{update_bkg}) and $self->dispatch_bkg($mode);
  $self->_MAKE(update_bkg=>0);
  ($self->{update_fft}) and $self->do_fft($mode, $rpf);
  $self->_MAKE(update_fft=>0);
  ($self->{update_bft}) and $self->do_bft($mode);
  $self->_MAKE(update_bft=>0);

  ## determine parameters for legend

  my $k;
  ($weight == 0) and ($k = "");
  ($weight == 1) and ($k = "k ");
  ($weight >= 2) and ($k = "k\\u$weight\\d ");
  ## test if background removal is up to date
  $this = sprintf("newplot(%s.k, \"%s.chi*%s.k^%d+%s\",%s xlabel=\"k (\\A\\u-1\\d)\",ylabel=\"%s\\gx(k)\"%s, style=lines, color=\"%s\", key=\\gx(k), title=\"%s\")",
		  $group, $group, $group, $weight, $yoffset,
		  $xrange, $k, $scr, $color, $lab);
  $this = wrap("", "        ", $this) . $/;
  $command .= $this;

  $color = $default->{color1};
  $this = sprintf("plot(%s.q, \"%s.chiq_re+%s\", style=lines, color=\"%s\", key=\"Re[\\gx(q)]\")",
		  $group, $group, $yoffset, $color);
  $this = wrap("", "     ", $this) . $/;
  $command .= $this;

  if ($win) {
    ($self->{update_fft}) and $self->do_fft($mode, $rpf);
    $self->_MAKE(update_fft=>0);
    ifeffit("set ___x = ceil($group.chi*$plot_scale*$group.k^$weight)"); # scale window to plot
    $scale = 1.05 * Ifeffit::get_scalar("___x");
    $color = $default->{color2};
    $this = sprintf("plot(%s.k, \"%s.win*%f+%s\", style=lines, color=\"%s\", key=window)",
		    $group, $group, $scale, $yoffset, $color);
    $this = wrap("", "     ", $this) . $/;
    $command .= $this;
  };


  &$echocmd("> plotting in k/q from group \`$lab\'");
  ##$command = wrap("", "", $command);
  $self->dispose($command, $mode);
  if ($$indicators[0]) {
    foreach my $i (@$indicators) {
      next if ($i =~ /^[01]$/);
      next if (lc($i->[1]) =~ /[r\s]/);
      next if (lc($i->[2]) =~ /\A\s*\z/);
      my $val = $i->[2];
      ($val = $self->e2k($val)) if (lc($i->[1]) eq "e");
      next if ($val < 0);
      ifeffit("set ___x = ceil($plot_scale*$group.chi*$group.k^$weight+$yoffset)");
      my $ymax = Ifeffit::get_scalar("___x") * 1.05;
      ifeffit("set ___x = floor($plot_scale*$group.chi*$group.k^$weight+$yoffset)");
      my $ymin = Ifeffit::get_scalar("___x") * 1.05;
      $self->plot_vertical_line($val, $ymin, $ymax, $mode, "", 0, 0, 1)
    };
  };
  $last_plot = $command;
  &$echocmd("> plotting in k/q from group \`$lab\' ... done!");

  ##&$echocmd(@done);
};




## the first argument indicates the type of multi-data set plot, the
## second and third are references to the groups and marked hashes.
## The options are
##    e, n, d            mu, normalized mu, or deriv of mu
##    kw, 0, 1, 2, 3, e  chi(k) with k-weight or chi(E) with k-weight
##    rm, rp, rr, ri     chi(R), magnitude, phase, real, imaginary
##    qm, qp, qr, qi     chi(q), magnitude, phase, real, imaginary
sub plot_marked {
  my $self = shift;
  my $group = $self->{group};
  my ($space, $mode, $r_groups, $r_marked, $rpf, $canvas, $indicators) = @_;
  my $m = 0;			# check that something is marked
  map {$m ||= $_} values %$r_marked;
  unless ($m) {
    &$errorcmd("> Multiple group plot aborted.  There are no marked groups.");
    return 1;
  };
  $space = lc($space);
  $space .= $$rpf{chie} if ($space !~ /^[enqr]/);
  my ($x, $y, $this, $command, $plot, $w, $defw) =
    ("", "", "", "", "newplot", -1, $$r_groups{'Default Parameters'}->{fft_arbkw});
  my $scr = $default->{screen};
  my $title_string = ($$rpf{project}) ? basename($$rpf{project}) : "all marked groups";
  $title_string =~ s{\.prj$}{};
  my $title = ", title='$title_string'";
  my ($xo, $xf, $yf, $yi);
  ## need to get kw from default parameters
  ## get the list in the order placed on the skinny canvas
  my @keys = sort {($canvas->bbox($$r_groups{$a}->{text}))[1] <=>
		     ($canvas->bbox($$r_groups{$b}->{text}))[1]} (keys (%$r_marked));
  my $first;
  foreach (@keys) {		# find the first marked group name
    $first = $_, last if $$r_marked{$_};
  };

 SWITCH: {			# set column names
    ($x, $y)     = ("energy", "xmu"),   last SWITCH if ($space eq 'e');
    #($x, $y)     = ("energy", "flat"),  last SWITCH if (($space eq 'n') and $default->{flatten});
    ($x, $y)     = ("energy", "norm"),  last SWITCH if ($space eq 'n');
    #($x, $y)     = ("energy", "der"),   last SWITCH if ($space eq 'd');
    ($x, $y, $w) = ("k", "chi", 'w'),   last SWITCH if ($space eq 'kw');
    ($x, $y, $w) = ("k", "chi", 0),     last SWITCH if ($space eq '0');
    ($x, $y, $w) = ("k", "chi", 1),     last SWITCH if ($space eq '1');
    ($x, $y, $w) = ("k", "chi", 2),     last SWITCH if ($space eq '2');
    ($x, $y, $w) = ("k", "chi", 3),     last SWITCH if ($space eq '3');
    ($x, $y, $w) = ("eee", "chi", 'w'), last SWITCH if ($space eq 'kwe');
    ($x, $y, $w) = ("eee", "chi", 0),   last SWITCH if ($space eq '0e');
    ($x, $y, $w) = ("eee", "chi", 1),   last SWITCH if ($space eq '1e');
    ($x, $y, $w) = ("eee", "chi", 2),   last SWITCH if ($space eq '2e');
    ($x, $y, $w) = ("eee", "chi", 3),   last SWITCH if ($space eq '3e');
    ($x, $y)     = ("r", "chir_mag"),   last SWITCH if ($space eq 'rm');
    ($x, $y)     = ("r", "chir_re"),    last SWITCH if ($space eq 'rr');
    ($x, $y)     = ("r", "chir_im"),    last SWITCH if ($space eq 'ri');
    ($x, $y)     = ("r", "chir_pha"),   last SWITCH if ($space eq 'rp');
    ($x, $y)     = ("q", "chiq_mag"),   last SWITCH if ($space eq 'qm');
    ($x, $y)     = ("q", "chiq_re"),    last SWITCH if ($space eq 'qr');
    ($x, $y)     = ("q", "chiq_im"),    last SWITCH if ($space eq 'qi');
    ($x, $y)     = ("q", "chiq_pha"),   last SWITCH if ($space eq 'qp');
  };
  ##print join(" ", $space, $x, $y, $w), $/;
  return unless &::verify_ranges($first, $x, 1);
  my $cnt = 0;
  my $color;
  my $labels;
  my $xrange = "";
 SWITCH: {
    ($x eq 'energy') and do {
      my ($xn, $xx) = ($$r_groups{$first}->{bkg_e0}+$$rpf{emin},
		       $$r_groups{$first}->{bkg_e0}+$$rpf{emax});
      $xrange = ", xmin=$xn, xmax=$xx";
      last SWITCH;
    };
    ($x eq 'k') and do {
      $xrange = ", xmin=$$rpf{kmin}, xmax=$$rpf{kmax}";
      last SWITCH;
    };
    ($x eq 'eee') and do {
      my ($xn, $xx) = ($$r_groups{$first}->{bkg_e0}+$$rpf{emin},
		       $$r_groups{$first}->{bkg_e0}+$$rpf{emax});
      $xrange = ", xmin=$xn, xmax=$xx";
      #$self->dispose("$first.eee = $first.k^2 / etok + $$r_groups{$first}->{bkg_e0}\n", $mode);
      last SWITCH;
    };
    ($x eq 'r') and do {
      $xrange = ", xmin=$$rpf{rmin}, xmax=$$rpf{rmax}";
      last SWITCH;
    };
    ($x eq 'q') and do {
      $xrange = ", xmin=$$rpf{qmin}, xmax=$$rpf{qmax}";
      last SWITCH;
    };
  };

  ##my $first = (keys (%$r_marked))[0];
  if ($x eq "energy") {
    ## handle norm and deriv
    my $type = "";
    my $smoothed = ($$rpf{smoothderiv}) ? "smoothed " : q{};
  SWITCH: {
      ($type = $smoothed."derivative of normalized"), last SWITCH if ($$rpf{e_mderiv} and ($y eq 'norm'));
      ($type = $smoothed."derivative of"),            last SWITCH if  $$rpf{e_mderiv};
      ($type = "normalized"),                         last SWITCH if ($y eq 'norm');
      ($type = "flattened, normalized"),              last SWITCH if ($y eq 'flat');
      ($type = $smoothed."derivative of"),            last SWITCH if ($y eq 'der');
    };
    $labels = ", xlabel=\"E (eV)\", ylabel=\"$type x\\gm(E)\"";
    my $sp = ($y eq 'norm') ? 'n' : 'e';
  } elsif ($x eq "k") {
    my $k;
  SWITCH: {
      ($k = "k\\ukw\\d "), last SWITCH if ($w eq 'w');
      ($k = ""),           last SWITCH if ($w == 0);
      ($k = "k "),         last SWITCH if ($w == 1);
      ($k = "k\\u$w\\d "), last SWITCH if ($w >= 2);
    };
    $labels = sprintf(", xlabel=\"k (\\A\\u-1\\d)\",ylabel=\"%s\\gx(k) (\\A\\u-%s\\d)\"",
		      $k, $w);
  } elsif ($x eq "eee") {
    my $k;
  SWITCH: {
      ($k = "k\\ukw\\d "), last SWITCH if ($w eq 'w');
      ($k = ""),           last SWITCH if ($w == 0);
      ($k = "k "),         last SWITCH if ($w == 1);
      ($k = "k\\u$w\\d "), last SWITCH if ($w >= 2);
    };
    $labels = sprintf(", xlabel=\"E (eV)\",ylabel=\"%s\\gx(E) (\\A\\u-%s\\d)\"",
		      $k, $w);
  } elsif ($x eq "r") {
    #my $w = $self->{fft_kw}+1;
    my $w = ($$rpf{kw} eq 'kw') ? $self->{fft_arbkw}+1 : $$rpf{kw}+1;
    my $y = "|\\gx(R)|";
    ($y = "Re[\\gx(R)]") if ($space eq 'rr');
    ($y = "Im[\\gx(R)]") if ($space eq 'ri');
    ($y = "Phase[\\gx(R)]") if ($space eq 'rp');
    $labels = sprintf(", xlabel=\"R (\\A)\",ylabel=\"%s (\\A\\u-%.3g\\d)\"", $y,$w);
  } elsif ($x eq "q") {
    my $w = ($$rpf{kw} eq 'kw') ? $self->{fft_arbkw} : $$rpf{kw};
    $labels = sprintf(", xlabel=\"k (\\A\\u-1\\d)\",ylabel=\"\\gx(q) (\\A\\u-%.3g\\d)\"", $w);
  };
  my $xx = ($x eq 'r') ? 'R' : $x;
  &$echocmd("> plotting in $xx for all marked groups");
  ##foreach (keys (%$r_marked)) {
  my $some_zero = 0;
  my ($indic_min, $indic_max) = (1000000, -1000000);
  my $counter = 0;
  foreach (@keys) {
    ## need to check what needs updating
    my $plot_scale = $$r_groups{$_}->{plot_scale};
    my $lab = $$r_groups{$_}->{label};
    ++$some_zero if not $plot_scale;
    my $yoffset    = $$r_groups{$_}->{plot_yoffset};
    if ($$r_marked{$_}) {
      ## determine the line type for this 'un
      $counter++;
      my $style = 'lines';
      if ($default->{linetypes}) {
       	use integer;
       	if ($counter < 40) {
       	  $style = (qw[lines dashed dotted dot-dash])[$counter / 10];
       	} else {
       	  $style = "linespoints" . ($counter/10 - 3);
       	};
      };

      next if (($x ne 'energy') and ($$r_groups{$_}->{not_data}));
      next if (($x ne 'energy') and ($$r_groups{$_}->{is_xanes}));
      next if (($x eq 'energy') and (not ($$r_groups{$_}->{is_xmu} or $$r_groups{$_}->{is_nor} or $$r_groups{$_}->{not_data})));
      next if (($x eq 'eee') and (not ($$r_groups{$_}->{is_xmu} or $$r_groups{$_}->{is_nor} or $$r_groups{$_}->{is_chi})));
      next if (($x eq 'eee') and ($$r_groups{$_}->{not_data}));
      ## verify ranges are in correct order
      next if ($$r_groups{$_}->{is_xmu} and
	       ($$r_groups{$_}->{bkg_pre1} > $$r_groups{$_}->{bkg_pre2}));
      next if ($$r_groups{$_}->{is_xmu} and
	       ($$r_groups{$_}->{bkg_nor1} > $$r_groups{$_}->{bkg_nor2}));
      next if ($$r_groups{$_}->{is_xmu} and
	       ($$r_groups{$_}->{bkg_spl1} > $$r_groups{$_}->{bkg_spl2}));
      next if (($space =~ /^[qr]/) and ($$r_groups{$_}->{fft_kmin} > $$r_groups{$_}->{fft_kmax}));
      next if (($space =~ /^q/)    and ($$r_groups{$_}->{bft_rmin} > $$r_groups{$_}->{bft_rmax}));
      unless (($y eq 'xmu') or ($x eq 'eee')) { # don't need to update bkg if plotting mu(E)
	$$r_groups{$_}->dispatch_bkg($mode) if ($$r_groups{$_}->{update_bkg});
	$$r_groups{$_}->_MAKE(update_bkg=>0);
      };
      if ($space =~ /^[qr]/) {
	($$r_groups{$_}->{update_fft}) and $$r_groups{$_}->do_fft($mode, $rpf);
	$$r_groups{$_}->_MAKE(update_fft=>0);
      };
      if ($space =~ /^q/) {
	($$r_groups{$_}->{update_bft}) and $$r_groups{$_}->do_bft($mode);
	$$r_groups{$_}->_MAKE(update_bft=>0);
      };

      $color = $default->{'color'.$cnt%10};
      my $indent = " " x (length($plot) + 1);
      ## kw-weighted chi(k) data
      if (($x eq 'k') and ($w eq 'w')) {
	my $w = ($$rpf{kw} eq 'kw') ? $$r_groups{$_}->{fft_arbkw} : $$rpf{kw};
	$this = sprintf("%s(%s.k, \"%s*%s.chi*%s.k^%s+%s\"%s%s%s, style=%s, color=\"%s\", key=\"%s\"%s)",
			$plot, $_, $plot_scale, $_, $_, $w, $yoffset,
			$labels, $scr, $xrange, $style, $color, $lab, $title);
	$this = wrap("", $indent, $this) . $/;
	$command .= $this;
	## determine indicator boundries
	ifeffit("set i___ndic.x = $plot_scale*$_.chi*$_.k^$w+$yoffset");
	my @x = Ifeffit::get_array("$_.k");
	my @y = Ifeffit::get_array("i___ndic.x");
	my ($ymin, $ymax) = $self->floor_ceil(\@x, \@y, $rpf, 'k', 0);
	$ymin *= 1.05;
	$ymax *= 1.05;
	($indic_max = $ymax) if ($ymax > $indic_max);
	($indic_min = $ymin) if ($ymin < $indic_min);
	## integer weighted chi(k) data
      } elsif (($x eq 'k') and ($w != 0)) {
	$this= sprintf("%s(%s.k, \"%s*%s.chi*%s.k^%s+%s\"%s%s%s, style=%s, color=\"%s\", key=\"%s\"%s)",
		       $plot, $_, $plot_scale, $_, $_, $w, $yoffset,
		       $labels, $scr, $xrange, $style, $color, $lab, $title);
	$this = wrap("", $indent, $this) . $/;
	$command .= $this;
	## determine indicator boundries
	ifeffit("set i___ndic.x = $plot_scale*$_.chi*$_.k^$w+$yoffset");
	my @x = Ifeffit::get_array("$_.k");
	my @y = Ifeffit::get_array("i___ndic.x");
	my ($ymin, $ymax) = $self->floor_ceil(\@x, \@y, $rpf, 'k', 0);
	$ymin *= 1.05;
	$ymax *= 1.05;
	($indic_max = $ymax) if ($ymax > $indic_max);
	($indic_min = $ymin) if ($ymin < $indic_min);
	## kw weighted chi(E) data
      } elsif (($x eq 'eee') and ($w eq 'w')) {
	$self->dispose("set $_.eee = $_.k^2 / etok + $$r_groups{$_}->{bkg_e0}\n", $mode);
	my $ww = ($$rpf{kw} eq 'kw') ? $$r_groups{$_}->{fft_arbkw} : $$rpf{kw};
	$this = sprintf("%s(%s.eee, \"%s*%s.chi*%s.k^%s+%s\"%s%s%s, style=%s, color=\"%s\", key=\"%s\"%s)",
			$plot, $_, $plot_scale, $_, $_, $ww, $yoffset,
			$labels, $scr, $xrange, $style, $color, $lab, $title);
	$this = wrap("", $indent, $this) . $/;
	$command .= $this;
	## determine indicator boundries
	ifeffit("set i___ndic.x = $plot_scale*$_.chi*$_.k^$ww+$yoffset");
	my @x = Ifeffit::get_array("$first.eee");
	my @y = Ifeffit::get_array("i___ndic.x");
	my ($ymin, $ymax) = $self->floor_ceil(\@x, \@y, $rpf, 'e', $$r_groups{$first}->{bkg_e0});
	$ymin *= 1.05;
	$ymax *= 1.05;
	($indic_max = $ymax) if ($ymax > $indic_max);
	($indic_min = $ymin) if ($ymin < $indic_min);
	## integer weighted chi(E) data
      } elsif (($x eq 'eee') and ($w =~ /[123]/)) {
	$self->dispose("set $_.eee = $_.k^2 / etok + $$r_groups{$_}->{bkg_e0}\n", $mode);
	$this= sprintf("%s(%s.eee, \"%s*%s.chi*%s.k^%s+%s\"%s%s%s, style=%s, color=\"%s\", key=\"%s\"%s)",
		       $plot, $_, $plot_scale, $_, $_, $w, $yoffset,
		       $labels, $scr, $xrange, $style, $color, $lab, $title);
	$this = wrap("", $indent, $this) . $/;
	$command .= $this;
	## determine indicator boundries
	ifeffit("set i___ndic.x = $plot_scale*$_.chi*$_.k^$w+$yoffset");
	my @x = Ifeffit::get_array("$first.eee");
	my @y = Ifeffit::get_array("i___ndic.x");
	my ($ymin, $ymax) = $self->floor_ceil(\@x, \@y, $rpf, 'e', $$r_groups{$first}->{bkg_e0});
	$ymin *= 1.05;
	$ymax *= 1.05;
	($indic_max = $ymax) if ($ymax > $indic_max);
	($indic_min = $ymin) if ($ymin < $indic_min);
	## deriv(mu(E)) data
      } elsif (($$rpf{e_mderiv} eq 'd') and ($x eq 'energy') and (not $$r_groups{$_}->{not_data})) {
	my $eshift = $$r_groups{$_}->{bkg_eshift};

	$self->dispose("set $_.smooth = deriv($_.$y)/deriv($group.energy)", $mode);
	if ($$rpf{smoothderiv}) {
	  foreach my $it (1 .. $$rpf{smoothderiv}) {
	    $self->dispose("set $_.smooth = smooth($_.smooth)", $mode);
	  };
	};

	$this = sprintf("%s(%s.%s+%s, \"%s*%s.smooth+%s\"%s%s%s, style=%s, color=\"%s\", key=\"%s\"%s)",
			$plot, $_, $x, $eshift, $plot_scale, $_, $yoffset,
			$labels, $scr, $xrange, $style, $color, $lab, $title);
	$this = wrap("", $indent, $this) . $/;
	$command .= $this;
	## determine indicator boundries
	ifeffit("set i___ndic.x = $plot_scale*(deriv($_.$y)/deriv($group.energy))+$yoffset");
	my @x = Ifeffit::get_array("$_.energy");
	my @y = Ifeffit::get_array("i___ndic.x");
	my ($ymin, $ymax) = $self->floor_ceil(\@x, \@y, $rpf, 'e', $$r_groups{$first}->{bkg_e0});
	$ymin *= 1.05;
	$ymax *= 1.05;
	($indic_max = $ymax) if ($ymax > $indic_max);
	($indic_min = $ymin) if ($ymin < $indic_min);
	## all other data in energy
      } elsif ($x eq 'energy') {
	my $eshift = $$r_groups{$_}->{bkg_eshift};
	my $yy = $y;
	(($$r_groups{$_}->{is_nor}) and ($y eq 'norm')) and ($yy = 'xmu');
	(($y eq 'norm') and ($$r_groups{$_}->{bkg_flatten})) and ($yy = 'flat');
	($$r_groups{$_}->{not_data}) and ($yy = 'det');
	my $mult = ($$r_groups{$_}->{not_data} or $$r_groups{$_}->{is_xanes} or $$r_groups{$_}->{is_nor}) ?
	  "$plot_scale*" : '';
	$this = sprintf("%s(%s.%s+%s, \"%s%s.%s+%s\"%s%s%s, style=%s, color=\"%s\", key=\"%s\"%s)",
			$plot, $_, $x, $eshift, $mult, $_, $yy, $yoffset,
			$labels, $scr, $xrange, $style, $color, $lab, $title);
	$this = wrap("", $indent, $this) . $/;
	$command .= $this;
	## determine indicator boundries
	ifeffit("set i___ndic.x = $mult$_.$yy+$yoffset");
	my @x = Ifeffit::get_array("$_.energy");
	my @y = Ifeffit::get_array("i___ndic.x");
	my ($ymin, $ymax) = $self->floor_ceil(\@x, \@y, $rpf, 'e', $$r_groups{$first}->{bkg_e0});
	my $diff = $ymax-$ymin;
	$ymin -= $diff/20;
	$ymax += $diff/20;
	($indic_max = $ymax) if ($ymax > $indic_max);
	($indic_min = $ymin) if ($ymin < $indic_min);
	## all other data
      } else {
	$this = sprintf("%s(%s.%s, \"%s*%s.%s+%s\"%s%s%s, style=%s, color=\"%s\", key=\"%s\"%s)",
			$plot, $_, $x, $plot_scale, $_, $y, $yoffset,
			$labels, $scr, $xrange, $style, $color, $lab, $title);
	$this = wrap("", $indent, $this) . $/;
	$command .= $this;
	## determine indicator boundries
	ifeffit("set i___ndic.x = $plot_scale*$_.$y+$yoffset");
	my @x = Ifeffit::get_array("$_.$x");
	my @y = Ifeffit::get_array("i___ndic.x");
	my ($ymin, $ymax) = $self->floor_ceil(\@x, \@y, $rpf, lc($x), 0);
	$ymin *= 1.05;
	$ymax *= 1.05;
	($indic_max = $ymax) if ($ymax > $indic_max);
	($indic_min = $ymin) if ($ymin < $indic_min);
      };
      ($plot, $labels, $scr, $title) = ("plot", "", "", "");
      ++$cnt;
      #$title .= "$_ ";
    };
  };
  #$command .= ("plot(title=$title)\n");
  ##print $command;
  ##$command = wrap("", "", $command);
  $self->dispose($command, $mode);
  if ($$indicators[0]) {
    foreach my $i (@$indicators) {
      next if ($i =~ /^[01]$/);
      next if (lc($i->[1]) =~ /^\s*$/);
      next if (($x ne "r") and (lc($i->[1]) eq "r"));
      next if (($x eq "r") and (lc($i->[1]) ne "r"));
      my $val = $i->[2];
      ($val = $self->e2k($val)) if (($x =~ /[kq]/) and (lc($i->[1]) eq "e"));
      ($val = $self->k2e($val) + $$r_groups{$first}->{bkg_e0})
	if (($x =~ /^e/) and (lc($i->[1]) =~ /[kq]/));
      next if ($val < 0);
      $self->plot_vertical_line($val, $indic_min, $indic_max, $mode, "", 0, 0, 1)
    };
  };
  $last_plot = $command;
  ($xx = "chi(E)") if ($xx eq 'eee');
  ($some_zero) ?
    &$errorcmd("> WARNING: One or more of the groups plotted had plot multipliers set to zero.") :
      &$echocmd("> plotting in $xx for all marked groups ... done!");
};


## args are: x-position, y-range, plotting mode, key, yoffset, and
## newplot flag
sub plot_vertical_line {
  my $self = shift;
  my ($x, $ymin, $ymax, $mode, $key, $yoffset, $new, $style) = @_;
  my $delta = $ymax - $ymin;
  my ($line, $color) = ($style==1) ?
    ($default->{indicatorline}, $default->{indicatorcolor}) :
      ($default->{borderline}, $default->{bordercolor});
  $self->dispose("set(v___ert.x = $x*ones(2), v___ert.y = range($ymin, $ymax, $delta))", $mode);
  if ($new) {
    $self->dispose("newplot(v___ert.x, \"v___ert.y+$yoffset\", key=\"$key\", style=$line, color=\"$color\")", $mode);
  } else {
    $self->dispose("plot(v___ert.x, \"v___ert.y+$yoffset\", key=\"$key\", style=$line, color=\"$color\")", $mode);
  };
};


sub plot_window {
  my $self = shift;
  my ($new, $space, $mode, $color, $rpf) = @_;
  my $group = $self->{group};
  my $yoffset = $self->{plot_yoffset};
  my $plot_scale = $self->{plot_scale};
  my $plot = ($new) ? "newplot" : "plot";
  my $this;
 SWITCH: {
    (lc($space) =~ /^[kq]$/) and do {
      ($self->{update_fft}) and $self->do_fft($mode, $rpf);
      $self->_MAKE(update_fft=>0);
      my $weight = $$rpf{kw};
      ifeffit("set ___x = ceil($group.chi*$plot_scale*$group.k^$weight)"); # scale window to plot
      my $scale = 1.05 * Ifeffit::get_scalar("___x");
      $color ||= $default->{color9};
      $this = sprintf("%s(%s.k, \"%s.win*%f+%s\", style=lines, color=\"%s\", key=window)",
		      $plot, $group, $group, $scale, $yoffset, $color);
      $this = wrap("", "     ", $this) . $/;
      last SWITCH;
    };
    (lc($space) eq 'r') and do {
      ($self->{update_bft}) and $self->do_bft($mode);
      $self->_MAKE(update_bft=>0);
      ifeffit("set ___x = ceil($group.chir_mag)"); # scale window to plot
      my $scale = 1.05 * $plot_scale * Ifeffit::get_scalar("___x");
      $color ||= $default->{color9};
      $this = sprintf("%s(%s.r, \"%s.rwin*%.2f+%s\", style=lines, color=\"%s\", key=window)",
		      $plot, $group, $group, $scale, $yoffset, $color);
      last SWITCH;
    };
  };
  $self->dispose($this, $mode);
};


######################################################################
## Analysis methods

## These methods do not rely on ifeffit program variables.  Instead
## they construct the full command from the hash values for the
## group. This obviates the need to keep track of the current state of
## the program variables at the cost of longer commands and keeping
## clear which is the current group.

sub dispatch_bkg {
  my $self = shift;
  return if $self->{not_data};
  my $mode = $_[0];
  if ($self->{bkg_cl}) {
    $self -> do_bkg_cl($mode);
  } else {
    $self -> do_background($mode);
  };
};

sub set_clamp {
  my $self = shift;
  my $key = ucfirst(lc($_[0]));
  my $val = int($_[1]);
  $clamp{$key} = $val;
  return 1;
};

sub do_background {
  my $self = shift;
  my $mode = $_[0];
  my $group = $self->{group};
  my $label = $self->{label};
  ## why is this necessary???
  my $precmd  = "(\"$group.energy+$self->{bkg_eshift}\", $group.xmu, ";
  $precmd    .= "e0=$self->{bkg_e0}, ";
  $precmd    .= "pre1=$self->{bkg_pre1}, ";
  $precmd    .= "pre2=$self->{bkg_pre2}, ";
  $precmd    .= "norm_order=$self->{bkg_nnorm}, ";
  $precmd    .= "norm1=$self->{bkg_nor1}, ";
  $precmd    .= "norm2=$self->{bkg_nor2})\n";
  $precmd     = wrap("pre_edge", "        ", $precmd);
  ##                              vvvvvvvvvvvvv Is this the right thing to do??
  my $command = "(\"$group.energy+$self->{bkg_eshift}\", $group.xmu, ";
  unless ($self->{bkg_stan} =~ /None/) {
    ## selecting the standard back on the main window checks to see
    ## that it is up to date
    $command .= "k_std=$self->{bkg_stan}.k, chi_std=$self->{bkg_stan}.chi, ";
  };
  $command   .= "e0=$self->{bkg_e0}, ";
  my $fixed = 0;
  if ($self->{bkg_fixstep}) { $command .= "edge_step=$self->{bkg_step}, do_pre=F, ";
			      $fixed    = $self->{bkg_step}; };
  #elsif ($self->{is_nor})   { $command .= "edge_step=1, "; }
  $command   .= "rbkg=$self->{bkg_rbkg}, ";
  $command   .= "kmin=$self->{bkg_spl1}, ";
  $command   .= "kmax=$self->{bkg_spl2}, ";
  $command   .= "kweight=$self->{bkg_kw}, ";
  $command   .= "dk=$self->{bkg_dk}, ";
  $command   .= "kwindow=$self->{bkg_win}";
  #$command   .= "do_pre=false";
  #unless ($self->{is_nor}) {
    $command   .= ", pre1=$self->{bkg_pre1}";
    $command   .= ", pre2=$self->{bkg_pre2}";
    $command   .= ", fnorm=yes" if ($self->{bkg_fnorm});
    $command   .= ", norm_order=$self->{bkg_nnorm}";
    $command   .= ", norm1=$self->{bkg_nor1}";
    $command   .= ", norm2=$self->{bkg_nor2}";
  #};
  ($self->{bkg_clamp1} ne 'None') and $command .= ", clamp1=$clamp{$self->{bkg_clamp1}}";
  ($self->{bkg_clamp2} ne 'None') and $command .= ", clamp2=$clamp{$self->{bkg_clamp2}}";
  if (($self->{bkg_clamp1} ne 'None') or ($self->{bkg_clamp2} ne 'None')) {
    my $n = int($self->{bkg_nclamp});
    $command .= ", nclamp=$n";
  };
  $command   .= ", interp=$default->{interp}";
  $command   .= ")\n";
  $command    = wrap("spline", "       ", $command);
  if ($self->{is_xanes}) {
    &$echocmd("> normalizing \`$label\' ...");
  } else {
    &$echocmd("> removing background from \`$label\' ...");
  };
  ## print $command;
  #$self->{is_nor} or
    $self->dispose($precmd, $mode);
  $self->_MAKE(bkg_nc0	 => Ifeffit::get_scalar("norm_c0"),
	       bkg_nc1	 => Ifeffit::get_scalar("norm_c1"),
	       bkg_nc2	 => Ifeffit::get_scalar("norm_c2"));
  my $before = Ifeffit::get_scalar("edge_step");
  $self->_MAKE(bkg_slope => ($self->{is_xmudat}) ? 0 : Ifeffit::get_scalar("pre_slope"));
  $self->_MAKE(bkg_int	 => ($self->{is_xmudat}) ? 0 : Ifeffit::get_scalar("pre_offset"));
  $self->_MAKE(bkg_step  => $fixed || sprintf "%.7f", Ifeffit::get_scalar("edge_step"));
  $self->_MAKE(bkg_fitted_step => $self->{bkg_step}) unless $fixed;
  $self->_MAKE(bkg_fitted_step => 1) if ($self->{is_nor});
  $self->dispose("$command", $mode) unless $self->{is_xanes};
  my $after = Ifeffit::get_scalar("edge_step");
  my $correction = $after/$before;
  my $cmd = ($self->{is_nor}) ?
    sprintf("set ___x = npts(%s.energy)\nset %s.preline = zeros(___x)\n", $group, $group) :
      sprintf("set %s.preline = %g+%g*(%s.energy + %g)\n",
	      $group, $self->{bkg_int}, $self->{bkg_slope}, $group, $self->{bkg_eshift});
  $self->dispose($cmd, $mode);
  $self->_MAKE(update_bkg => 0,
	       update_fft => 1,
	       bkg_cl	 => 0);
  my $xcmd = q{};
  if ($self->{is_xanes}) {
    $xcmd  = sprintf("set(%s.prex = (%s.xmu-%s.preline),\n",
		     $group, $group, $group);
    $xcmd .= sprintf("    %s.norm = (%s.xmu-%s.preline)/%g,\n",
		     $group, $group, $group, $self->{bkg_step});
    $xcmd .= sprintf("    %s.postline = %g+%g*(%s.energy+%f)+%g*(%s.energy+%f)**2)\n",
		     $group, $self->{bkg_nc0},
		     $self->{bkg_nc1}, $group, $self->{bkg_eshift},
		     $self->{bkg_nc2}, $group, $self->{bkg_eshift});
  } elsif ($self->{is_xmudat}) {
    $xcmd  = sprintf("set(%s.prex = %s.xmu,\n", $group, $group);
    $xcmd .= sprintf("    %s.norm = %s.xmu)\n", $group, $group);
  } else {
    $xcmd = sprintf("set %s.prex = %s.pre\n", $group, $group);
    if (abs($correction - 1) > DELTA) {
      $xcmd .= "## the next line corrects a bug in Ifeffit 1.2.11 in which the spline command does not respect the supplied value of norm_order \n";
      $xcmd .= sprintf("set %s.norm = %f*%s.norm\n", $group, $correction, $group)
    };
  };
  $self->dispose($xcmd, $mode);

  ## why am I having trouble with these two???????  this should not be necessary!!!!
  $self->{bkg_slope} = ($self->{is_xmudat}) ? 0 : Ifeffit::get_scalar("pre_slope");
  $self->{bkg_int}   = ($self->{is_xmudat}) ? 0 : Ifeffit::get_scalar("pre_offset");

  ## make flattened normalized data
  $command  = "## make the flattened, normalized spectrum\n";
  $command .= "##   flat_cN are the difference in slope and curvature between\n";
  $command .= "##   the pre- and post-edge polynomials\n";
  $command .= sprintf("set %s.postline = %g+%g*(%s.energy+%f)+%g*(%s.energy+%f)**2\n",
		      $group, $self->{bkg_nc0},
		      $self->{bkg_nc1}, $group, $self->{bkg_eshift},
		      $self->{bkg_nc2}, $group, $self->{bkg_eshift});
  $command .= "step $group.energy $self->{bkg_eshift} $self->{bkg_e0} $group.theta\n";

  if ($self->{bkg_fixstep} or $self->{is_nor} or $self->{is_xanes}) {
    ## the edge step is fixed, so we have to regress the flat_c? values
    my ($flat1, $flat2) = ($self->{bkg_e0}+$self->{bkg_nor1}-$self->{bkg_eshift},
			   $self->{bkg_e0}+$self->{bkg_nor2}-$self->{bkg_eshift});
    my $shift = $self->{bkg_eshift};
    $command .= "guess(flat_c0=0, flat_c1=0)\n";
    if (($flat2-$flat1) < 300) {
      $command .= "set(flat_c2=0)\n";
    } elsif ($self->{bkg_nnorm} == 2) {
      $command .= "set(flat_c2=0)\n";
    } else {
      $command .= "guess(flat_c2=0)\n";
    };
    $command .= "def($group.line = (flat_c0 + flat_c1*($group.energy+$shift) + flat_c2*($group.energy+$shift)**2),\n";
    $command .= "    $group.resid = $group.prex - $group.line)\n";
    $command .= "minimize($group.resid, x=$group.energy, xmin=$flat1, xmax=$flat2)\n";
    #$command .= "show flat_c0 flat_c1 flat_c2\n";
    $command .= "unguess\n";
    #$command .= "set $group.line = $group.line * $self->{bkg_step} / $self->{bkg_fitted_step}\n";
    #$command .= "set $group.line = (flat_c0 * $self->{bkg_step} / $self->{bkg_fitted_step}) + flat_c1*($group.energy+$shift) + flat_c2*($group.energy+$shift)**2\n"
    #  if $fixed;
  } else {
    my $shift = $self->{bkg_eshift};
    $command .= "set(flat_c0=$self->{bkg_nc0} - $self->{bkg_int},\n";
    $command .= "    flat_c1=$self->{bkg_nc1} - $self->{bkg_slope},\n";
    if ($self->{bkg_nnorm} == 2) {
      $command .= "    flat_c2=0,\n";
    } else {
      $command .= "    flat_c2=$self->{bkg_nc2},\n";
    };
    $command .= "    $group.line = (flat_c0 + flat_c1*($group.energy+$shift) + flat_c2*($group.energy+$shift)**2))\n";
  };

  ## make sure that a fitted edge step actually exists...
  $self->_MAKE(bkg_fitted_step => $self->{bkg_step}) unless $self->{bkg_fitted_step};
  $command .= "set($group.flat = (($self->{bkg_fitted_step} - $group.line)*$group.theta + $group.prex) / $self->{bkg_step})\n";
  $command .= "set($group.fbkg = ($group.bkg-$group.preline+($self->{bkg_fitted_step}-$group.line)*$group.theta)/$self->{bkg_step})\n"
    unless $self->{is_xanes};
  $self->dispose($command, $mode);
  ##&$echocmd("---> flattened");

  if ($self->{is_xanes}) {
    &$echocmd("> normalizing \`$label\' ... done!");
  } else {
    &$echocmd("> removing background from \`$label\' ... done!");
  };
};

##   $command .= "guess(flat_c0=0, flat_c1=0, flat_c2=0)\n";
##   $command .= "def $group.line = (flat_c0 + flat_c1*$group.energy + flat_c2*$group.energy**2)\n";
##   $command .= "def $group.resid = $group.pre - $group.line\n";
##   $command .= "minimize($group.resid, x=$group.energy, xmin=$flat1, xmax=$flat2)\n";
##   $command .= "unguess\n";



sub do_bkg_cl {
  my $self = shift;
  my $mode = $_[0];
  my $group = $self->{group};
  my $label = $self->{label};
  my $iz = get_Z($self->{bkg_z});
  my $command = "(z=$iz, group=$group, ";
  ##                                  vvvvvvvv Is this the right thing to do??
  $command   .= "energy=$group.energy+$self->{bkg_eshift}, xmu=$group.xmu, ";
  $command   .= "e0=$self->{bkg_e0}, ";
  my $fixed = 0;
  if ($self->{bkg_fixstep}) { $command .= "edge_step=$self->{bkg_step}, ";
			      $fixed    = $self->{bkg_step}; }
  elsif ($self->{is_nor})   { $command .= "edge_step=1, "; }
  $command   .= "pre1=$self->{bkg_pre1}, ";
  $command   .= "pre2=$self->{bkg_pre2}, ";
  $command   .= "norm1=$self->{bkg_nor1}, ";
  $command   .= "norm2=$self->{bkg_nor2}, ";
  $command   .= "interp=$default->{interp})\n";
  $command    = wrap("bkg_cl", "       ", $command);
  &$echocmd("> removing background from \`$label\'");
  ## print $command;
  $self->dispose($command, $mode);
  $self->_MAKE(bkg_slope  => Ifeffit::get_scalar("pre_slope"),
	       bkg_int	  => Ifeffit::get_scalar("pre_offset"),
	       bkg_nc0	  => Ifeffit::get_scalar("norm_c0"),
	       bkg_nc1	  => Ifeffit::get_scalar("norm_c1"),
	       bkg_nc2	  => Ifeffit::get_scalar("norm_c2"),
	       update_bkg => 0,
	       update_fft => 1,
	       bkg_cl	  => 1);
  $self->_MAKE(bkg_step   => $fixed || sprintf "%.7f", Ifeffit::get_scalar("edge_step"));
  $self->_MAKE(bkg_fitted_step => $self->{bkg_step}) unless $fixed;
  &$echocmd("> removing background from \`$label\' ... done!");
};


sub do_fft {
  my $self = shift;
  return if $self->{not_data};
  my ($mode, $rpf) = @_;
  my $group = $self->{group};
  my $label = $self->{label};
  my $kw = ($$rpf{kw} eq 'kw') ? $self->{fft_arbkw} : $$rpf{kw};
  ## verify values
  my $command = "($group.chi, ";
  $command   .= "k=$group.k, ",
  $command   .= "kweight=$kw, ";
  $command   .= "kmin=$self->{fft_kmin}, ";
  $command   .= "kmax=$self->{fft_kmax}, ";
  $command   .= "dk=$self->{fft_dk}, ";
  $command   .= "kwindow=$self->{fft_win}, ";
  $command   .= "rmax_out=$Ifeffit::Group::rmax_out";
  if (lc($self->{fft_pc}) eq 'on') {
    my $str = join(" ", lc($self->{bkg_z}), lc($self->{fft_edge}));
    ($command .= ", pc_edge=\"$str\", pc_caps=1");
  };
  $command   .= ")\n";
  $command    = wrap("fftf", "     ", $command);
  &$echocmd("> forward transforming \`$label\'");
  $self->dispose($command, $mode);
  $self->_MAKE(update_fft=>0);
  &$echocmd("> forward transforming \`$label\' ... done!");
  ##print $command;
};


sub do_bft {
  my $self = shift;
  return if $self->{not_data};
  my $mode = $_[0];
  my $group = $self->{group};
  my $label = $self->{label};
  ## verify values
  my $command = "(real=$group.chir_re, imag=$group.chir_im, ";
  $command   .= "rmin=$self->{bft_rmin}, ";
  $command   .= "rmax=$self->{bft_rmax}, ";
  $command   .= "dr=$self->{bft_dr}, ";
  $command   .= "rwindow=$self->{bft_win})\n";
  $command    = wrap("fftr", "     ", $command);
  ##print $command;
  &$echocmd("> back transforming \`$label\'");
  $self->_MAKE(update_bft=>0);
  $self->dispose($command, $mode);
  &$echocmd("> back transforming \`$label\' ... done!");
};



######################################################################
## Merging methods

sub merge {
  my $self = shift;
  my ($space, $weight, $mode, $r_groups, $r_marked, $rpf, $canvas) = @_;
  &$echocmd("> Merging ... ");
  push @{$self->{titles}}, "Merge in $space space of:";
  my $group = $self->{group};
  $self -> _MAKE(is_merge=>lc($space));
  my $is_xanes = 0;
  my ($x, $y1, $y2, $y3, $y4);
 SWITCH: {			# get columns
    ($x, $y1, $y2) = ("energy", "xmu", ""),       last SWITCH if (lc($space) eq 'e');
    ($x, $y1, $y2) = ("energy", "norm", ""),      last SWITCH if (lc($space) eq 'n');
    ($x, $y1, $y2) = ("k", "chi", ""),            last SWITCH if (lc($space) eq 'k');
    ($x, $y1, $y2) = ("r", "chir_re", "chir_im"), last SWITCH if (lc($space) eq 'r');
    ($x, $y1, $y2) = ("q", "chiq_re", "chiq_im"), last SWITCH if (lc($space) eq 'q');
  };
 MP: {				# handle complex data (rsp and qsp)
    ($y3, $y4) = ("chir_mag", "chir_pha"), last MP if (lc($space) eq 'r');
    ($y3, $y4) = ("chiq_mag", "chiq_pha"), last MP if (lc($space) eq 'q');
  };
  ## get the list of marked groups in the order placed on the group list
  my @ll = sort {($canvas->bbox($$r_groups{$a}->{text}))[1] <=>
		   ($canvas->bbox($$r_groups{$b}->{text}))[1]} (keys (%$r_marked));
  my (@list, @list2);			# get the list of marked groups
  map {if ($$r_marked{$_}) {push @list, $_; push @list2, $_}} @ll;
  my $first = $list[0];
 SWITCH: {			# deal with the first element in the
    ($y1 eq 'norm') and do {	# list to get the command strings started
      ($$r_groups{$first} -> {update_bkg}) and $$r_groups{$first} -> dispatch_bkg($mode);
      last SWITCH;
    };
    ($x eq 'k') and do {
      ($$r_groups{$first} -> {update_bkg}) and $$r_groups{$first} -> dispatch_bkg($mode);
      last SWITCH;
    };
    ($x eq 'r') and do {
      ($$r_groups{$first} -> {update_bkg}) and $$r_groups{$first} -> dispatch_bkg($mode);
      ($$r_groups{$first} -> {update_fft}) and $$r_groups{$first} -> do_fft($mode);
      last SWITCH;
    };
    ($x eq 'q') and do {
      ($$r_groups{$first} -> {update_bkg}) and $$r_groups{$first} -> dispatch_bkg($mode);
      ($$r_groups{$first} -> {update_fft}) and $$r_groups{$first} -> do_fft($mode);
      ($$r_groups{$first} -> {update_bft}) and $$r_groups{$first} -> do_bft($mode);
      last SWITCH;
    };
  };
  ## find longest common abscissa range in the marked groups.
  ## interpolate over this range.  intrpolating just over the range of
  ## the first group might lead to extrapolation in other groups.
  my @first_absc = Ifeffit::get_array("$first.$x");
  my ($xmin, $xmax) = ($first_absc[0], $first_absc[$#first_absc]);
  foreach (@list) {		# make sure they are all up-to-date
  SWITCH: {
      &$echocmd(">   bringing \"" . $$r_groups{$_} -> {label} . "\" up to date for merge in $y1...");
      ($y1 eq 'xmu') and do{
	$is_xanes ||= $$r_groups{$_} -> {is_xanes};
	last SWITCH;
      };
      ($y1 eq 'norm') and do{
	($$r_groups{$_} -> {update_bkg}) and $$r_groups{$_} -> dispatch_bkg($mode);
	$is_xanes ||= $$r_groups{$_} -> {is_xanes};
	last SWITCH;
      };
      ($x eq 'k') and do{
	($$r_groups{$_} -> {update_bkg}) and $$r_groups{$_} -> dispatch_bkg($mode);
	last SWITCH;
      };
      ($x eq 'r') and do{
	($$r_groups{$_} -> {update_bkg}) and $$r_groups{$_} -> dispatch_bkg($mode);
	($$r_groups{$_} -> {update_fft}) and $$r_groups{$_} -> do_fft($mode);
	last SWITCH;
      };
      ($x eq 'q') and do{
	($$r_groups{$_} -> {update_bkg}) and $$r_groups{$_} -> dispatch_bkg($mode);
	($$r_groups{$_} -> {update_fft}) and $$r_groups{$_} -> do_fft($mode);
	($$r_groups{$_} -> {update_bft}) and $$r_groups{$_} -> do_bft($mode);
	last SWITCH;
      };
    };
    my @this = Ifeffit::get_array("$_.$x");
    my ($x1, $x2) = ($this[0], $this[$#this]);
    ($xmin = $x1) if ($x1 > $xmin);
    ($xmax = $x2) if ($x2 < $xmax);
  };
  $self->dispose("set(i___n = nofx($first.$x, $xmin), i___x = nofx($first.$x, $xmax))", 1);
  my $imin = int Ifeffit::get_scalar("i___n") - 1;
  my $imax = int Ifeffit::get_scalar("i___x") - 1;
  $self->dispose("erase i___n i___x", 1);
  my @abscissa = @first_absc[$imin .. $imax];
  Ifeffit::put_array("$group.$x", \@abscissa);

  ## start command strings
  if ($x eq 'energy') {
    $self -> dispose("set $group.$x = $group.$x+$$r_groups{$first}->{bkg_eshift}", $mode);
  };
  my ($cmd, $cmd2, $file, $n) = ("set $group.$x = $first.$x\n", "", "merge of ", 0);

  my $sets = "set(___x = npts($group.$x),\n";
  $sets   .= "    $group.$y1 = zeros(___x),\n";
  $sets   .= "    $group.stddev = zeros(___x))";
  $self -> dispose($sets, $mode);

  (($x eq 'r') or ($x eq 'q')) and ($self -> dispose("set $group.$y2 = zeros(___x)", $mode));
  my $is_detector = 0;
  my $sum = 0;
  foreach (@list) {
    &$echocmd(">   interpolating \"" . $$r_groups{$_} -> {label} . "\" to merge grid ...");
    my $noise = $$r_groups{$_}->{importance};
    if ($weight ne 'u') {
      my @noise = $$r_groups{$_}->chi_noise($rpf);
      $noise = ($x eq 'r') ? $noise[1] : $noise[0];
    };
    $sum += $noise;
    $file .= $$r_groups{$_}->{label} . ", ";
    my $esh = ($x eq 'energy') ? $$r_groups{$_}->{bkg_eshift} : 0;
    ## keep a running tally for mean and std. dev.
    if ($x eq 'energy') {	# worry about e0 shifts
      my $yy = $y1;		# worry about summing detector data
      (($yy, $is_detector) = ("det", 1)) if $$r_groups{$_}->{not_data};
      ($yy = 'flat') if ((lc($space) eq 'n') and $$r_groups{$_}->{bkg_flatten});
      $self -> dispose("set($_.merge = qinterp($_.$x+$esh, $_.$yy, $group.$x), $group.$y1 = $group.$y1 + $noise*$_.merge)", $mode);
    } else {
      $self -> dispose("set($_.merge = qinterp($_.$x, $_.$y1, $group.$x),$group.$y1 = $group.$y1 + $noise*$_.merge)", $mode);
    };
    ++$n;
    if (($x eq 'r') or ($x eq 'q')) {
      $self -> dispose("set($_.merge2 = qinterp($_.$x, $_.$y2, $group.$x), $group.$y2 = $group.$y2 + $noise*$_.merge2)", $mode);
      ## need a standard deviation of this part as well
      $self -> dispose("erase $_.merge2", $mode);
    };
  };
  my $yy = $y1;		# worry about summing detector data
  ($yy = "det") if $is_detector;
  $self -> dispose("set $group.$yy = $group.$y1 / $sum", $mode);
  foreach (@list2) {		# compute the variance, title lines
    &$echocmd(">   computing contribution of \"" . $$r_groups{$_} -> {label} . "\" to varience ...");
    my $noise =  $$r_groups{$_}->{importance};
    if ($weight ne 'u') {
      my @noise = $$r_groups{$_}->chi_noise($rpf);
      $noise = ($x eq 'r') ? $noise[1] : $noise[0];
    };
    my $esh = 0;
    my $string = "** " . $$r_groups{$_} -> {file};
    ##$$r_groups{$_}->{is_rec} && ($string .= ", $_");
    push @{$self->{titles}}, $string;
    if ($x eq 'energy') {	# worry about e0 shifts
      my $yy = $y1;		# worry about summing detector data
      ($yy = "det") if $$r_groups{$_}->{not_data};
      my $yyy = $y1;		# worry about summing detector data
      ($yyy = "det") if $$r_groups{$_}->{not_data};
      ($yyy = 'flat') if ((lc($space) eq 'n') and $$r_groups{$_}->{bkg_flatten});
      $esh = $$r_groups{$_}->{bkg_eshift};
      $self -> dispose("set($_.merge = qinterp($_.$x+$esh, $_.$yyy, $group.$x), $group.stddev = $group.stddev + $noise*($_.merge-$group.$yy)**2)", $mode);
    } else {
      $self -> dispose("set($_.merge = qinterp($_.$x, $_.$y1, $group.$x), $group.stddev = $group.stddev + $noise*($_.merge-$group.$y1)**2)", $mode);
    };
    $self -> dispose("erase $_.merge", $mode);
    ## need second column standard deviation also
  };
  $self -> dispose("set $group.stddev = sqrt(($group.stddev * $n) / ($sum*($n-1)))", $mode);
  $self -> put_titles();
  if ($y1 eq 'norm') {
    $self -> dispose("set $group.xmu = $group.norm\n", $mode);
  };
  if (($x eq 'r') or ($x eq 'q')) {
    $self -> dispose("set $group.$y2 = $group.$y2 / $n", $mode);
    $self -> dispose($cmd2, $mode);
    my $str = sprintf("set(%s.%s = sqrt(%s.%s**2 + %s.%s**2),\n",
		      $group, $y3, $group, $y1, $group, $y2);
    $str   .= sprintf("    %s.%s = atan(%s.%s / %s.%s))\n",
		      $group, $y4, $group, $y2, $group, $y1);
    $self -> dispose($str, $mode);
    ##   } elsif ($x eq 'energy') {
    ##     $self -> dispose("set $group.xmu = $group.norm\n", $mode);
  };
  $file =~ s/, $//;
  &$echocmd("> Merging ... done!");
  return ($file, $first, $is_detector, $is_xanes);
};


sub chi_noise {
  my $self = shift;
  my ($rpf) = @_;
  $self ->dispatch_bkg if $self->{update_bkg};
  my $group = $self->{group};
  my $string = "($group.chi, k=$group.k, ";
  foreach (qw(kmin kmax dk kwindow)) {
    my $this = "fft_".$_;
    ($this = "fft_win") if ($_ eq 'kwindow');
    my $val = $self->{$this};
    if (($_ eq 'kmax') and ($val == 999)) {
      $self -> dispose("___x = ceil($self->{group}.k)\n", 1);
      $val = Ifeffit::get_scalar("___x");
    };
    $string   .= "$_=$val, ";
  };
  $string   .= "kweight=$$rpf{kw}, ";
  $string =~ s/, $/\)\n/;
  $string = wrap("\nchi_noise", "         ", $string);
  $self->dispose($string, 5);
  $string = sprintf("## epsk=%.6g  epsR=%.6g  kmax_suggest=%.3f\n\n",
		    Ifeffit::get_scalar("epsilon_k"),
		    Ifeffit::get_scalar("epsilon_r"),
		    Ifeffit::get_scalar("kmax_suggest"));
  $self->dispose($string, 5);
  return (Ifeffit::get_scalar("epsilon_k"),
	  Ifeffit::get_scalar("epsilon_r"),
	  Ifeffit::get_scalar("kmax_suggest"));
};


sub kmax_suggest {
  my $self = shift;
  my ($rpf) = @_;
  my @noise = $self->chi_noise($rpf);
  $self -> _MAKE(fft_kmax => $noise[2], update_fft=>1);
  return $noise[2];
};


sub param_summary {
  my $self = shift;
  my $text = "";
  $text .= sprintf(".  Element=%s   Edge=%s\n",
		   $self->{bkg_z}, $self->{fft_edge});

  $text .= "Background parameters\n";
  $text .= sprintf(".  E0=%.3f  Eshift=%.3f  Rbkg=%.3f
.  Standard=%s
.  Kweight=%.1f  Edge step=%.3f
.  Fixed step=%s    Flatten=%s
.  Pre-edge range: [ %.3f : %.3f ]
.  Pre-edge line: %.5g + %.5g * E
.  Normalization range: [ %.3f : %.3f ]
.  Post-edge polynomial: %.5g + %.5g * E + %.5g * E^2
.  Spline range: [ %.3f : %.3f ]   Clamps: %s/%s
",
		   $self->{bkg_e0}, $self->{bkg_eshift}, $self->{bkg_rbkg},
		   $self->{bkg_stan_lab},
		   $self->{bkg_kw}, $self->{bkg_step},
		   ($self->{bkg_fixstep}?'yes':'no'), ($self->{bkg_flatten}?'yes':'no'),
		   $self->{bkg_pre1}, $self->{bkg_pre2},
		   $self->{bkg_int}, $self->{bkg_slope},
		   $self->{bkg_nor1}, $self->{bkg_nor2},
		   $self->{bkg_nc0}, $self->{bkg_nc1}, $self->{bkg_nc2},
		   $self->{bkg_spl1e}, $self->{bkg_spl2e}, $self->{bkg_clamp1}, $self->{bkg_clamp2},
		  );

  $text .= "Foreward FT parameters\n";
  $text .= sprintf(".  Kweight=%s   Window=%s   Phase correction=%s
.  k-range: [ %.3f : %.3f ]   dk=%.2f
",
		   $self->{fft_arbkw}, $self->{fft_win}, $self->{fft_pc},
		   $self->{fft_kmin}, $self->{fft_kmax}, $self->{fft_dk},
		   );

  $text .= "Backward FT parameters\n";
  $text .= sprintf(".  R-range: [ %.3f : %.3f ]
.  dR=%.2f   Window=%s
",
		   $self->{bft_rmin}, $self->{bft_rmax},
		   $self->{fft_dr}, $self->{bft_win},
		  );

  $text .= "Plotting parameters\n";
  $text .= sprintf(".  Multiplier=%.5g   Y-offset=%.3f\n",
		   $self->{plot_scale}, $self->{plot_yoffset});

  $text .= ".  \n";
  return $text;
};


sub sanity {
  my $self = shift;
  my $message = q{};

  ## background removal values
  $message .= "The edge energy is unset\n"      if ($self->{bkg_e0} =~ m{\A\s*\z});
  $message .= "The lower bound for the pre-edge range is very large ($self->{bkg_pre1})\n"      if (abs($self->{bkg_pre1})   > 1000);
  $message .= "The upper bound for the pre-edge range is very large ($self->{bkg_pre2})\n"      if (abs($self->{bkg_pre2})   > 1000);
  $message .= "The lower bound for the normalization range is very large ($self->{bkg_nor1})\n" if (abs($self->{bkg_nor1})   > 5000);
  $message .= "The upper bound for the normalization range is very large ($self->{bkg_nor2})\n" if (abs($self->{bkg_nor2})   > 5000);
  $message .= "The lower bound for the spline range is very large ($self->{bkg_spl1e})\n"       if (abs($self->{bkg_spl1e})  > 5000);
  $message .= "The upper bound for the spline range is very large ($self->{bkg_spl2e})\n"       if (abs($self->{bkg_spl2e})  > 5000);
  $message .= "The normalization order is not an allowed value ($self->{bkg_nnorm})\n"          if (abs($self->{bkg_nnorm}) !~ m{[123]});

  ## Fourier transform values
  $message .= "The kmin for the forward transfer is negative ($self->{fft_kmin})\n"                  if ($self->{fft_kmin}  < 0);
  $message .= "The kmax for the forward transfer is negative ($self->{fft_kmax})\n"                  if ($self->{fft_kmax}  < 0);
  $message .= "The kmin for the forward transfer is very large ($self->{fft_kmin})\n"                if ($self->{fft_kmin}  > 25);
  $message .= "The kmax for the forward transfer is very large ($self->{fft_kmax})\n"                if ($self->{fft_kmax}  > 25);
  $message .= "The dk for the forward transfer is negative ($self->{fft_dk})\n"                      if ($self->{fft_dk}    < 0);
  $message .= "The dk for the forward transfer is very large ($self->{fft_dk})\n"                    if ($self->{fft_dk}    > 10);
  $message .= "The arbitrary k-weight for the forward transfer is negative ($self->{fft_arbkw})\n"   if ($self->{fft_arbkw} < 0);
  $message .= "The arbitrary k-weight for the forward transfer is very large ($self->{fft_arbkw})\n" if ($self->{fft_arbkw} > 5);

  ## backward Fourier transform values
  $message .= "The Rmin for the backward transfer is negative ($self->{fft_rmin})\n"                 if ($self->{fft_rmin} < 0);
  $message .= "The Rmax for the backward transfer is negative ($self->{fft_rmax})\n"                 if ($self->{fft_rmax} < 0);
  $message .= "The Rmin for the backward transfer is very large ($self->{fft_rmin})\n"               if ($self->{fft_rmin} > 31);
  $message .= "The Rmax for the backward transfer is very large ($self->{fft_rmax})\n"               if ($self->{fft_rmax} > 31);
  $message .= "The dR for the backward transfer is negative ($self->{fft_dr})\n"                     if ($self->{fft_dr}   < 0);
  $message .= "The dR for the backward transfer is very large ($self->{fft_dr})\n"                   if ($self->{fft_dr}   > 10);

  return 0 if ($message =~ m{\A\s*\z});

  my $i = 0;
  my $processed = q{};
  foreach my $line (split(/\n/, $message)) {
    $processed .= sprintf(" %-3d: %s\n", ++$i, $line);
  };
  return $processed;
};



1;
__END__
