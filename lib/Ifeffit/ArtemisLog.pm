#! /usr/bin/perl -w
package Ifeffit::ArtemisLog;
######################################################################
## Ifeffit::ArtemisLog: Object oriented Artemis log file parsing
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
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

#@ISA = qw(Exporter AutoLoader);
@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw();

$VERSION = "0.8.013";

use Carp;
use File::Basename;
use File::Spec;

sub new {
  my $classname = shift;
  my $self = {};

  $self->{"info"}	    = {};  # version, creation_date, os
  $self->{"stats"}	    = {};  # chisqr, chinu, cormin, rfactor, nidp, nvar
  $self->{"bestfit"}	    = {};  # best fits of guess params
  $self->{"error"}	    = {};  # errors in guess params
  $self->{"initial"}	    = {};  # initial values of guess params
  $self->{"bkg"}	    = {};  # backgroun parameters
  $self->{"bkgerr"}	    = {};  # errors in background parameters
  $self->{"correlation"}    = {};  # correlations between guess params
  $self->{"def"}	    = {};  # final values for def params
  $self->{"restraint"}	    = {};  # final values for restraints
  $self->{"restraint_expr"} = {};  # math expression for restraints
  $self->{"set"}	    = {};  # values for set params
  $self->{"after"}	    = {};  # values for after-fit params
  $self->{"after_expr"}	    = {};  # math expressions for after-fit params
  #$self->{"delset"}	    = {};  # propagated errors in set params
  $self->{"chifiles"}	    = [];  # input chi file names
  $self->{"warnings"}	    = [];  # warnings found in the log file
  #$self->{"datasets"}	    = {};  # attribute values for data sets
  #$self->{"pathparam"}	    = {};  # final path param values
  #$self->{"delpath"}	    = {};  # path param propagated errors
  $self->{"order"}	    = {};

  $self->{order}->{guess}       = [];
  $self->{order}->{set}         = [];
  $self->{order}->{def}         = [];
  $self->{order}->{restraint}   = [];
  $self->{order}->{after}       = [];
  $self->{order}->{correlation} = [];
  $self->{order}->{bkg}         = [];

  bless($self, $classname);
  ($_[0]) and $self -> read(@_);
  return $self;
};

sub read {
  my $self = shift;
  my $logfile = $_[0];
  croak "Artemis logfile $logfile is not a readable file" unless (-e $logfile);

  ## ----------------------------------------------------------------
  ## match operational params and data set specific statistics in the
  ## data set section
  my %opparams = (file			       => 'file',
		  'k-range'		       => 'krange',
		  dk			       => 'dk',
		  'k-window'		       => 'kwin',
		  'k-weight'		       => 'kw',
		  'R-range'		       => 'rrange',
		  dR			       => 'dr',
		  'R-window'		       => 'rwin',
		  'fitting space'	       => 'fitspace',
		  'background function'	       => 'bkg',
		  'spline parameters'	       => 'nbkg',
		  'phase correction'	       => 'pcpath',
		  'Chi-square'		       => 'chisqr',
		  'R-factor for this data set' => 'rfact');
  my $opregex = "(" . join("|", (sort (keys %opparams))) . ")";
  ## ----------------------------------------------------------------
  ## match path parameters
  my @pathparams = (qw(feff id label s02 reff dr r 3rd ei degen e0
		       ss2 4th dphase));
  my $ppregexp = '(3rd|4th|d(egen|phase|r)|e[0i]|feff|id|label|s02|r(|eff)|ss2)';
  ## ----------------------------------------------------------------

  #-#-#--------------------------------------------------------------
  # begin reading log file

  my $section = 'header';
  my $data_set = 0;
  my $current_set = "";
  my $path = "";
  my $number_of_data_sets = 0;
  open(LOG, $logfile) or croak "could not open $logfile as a logfile";

  while (<LOG>) {
    $_ =~ s{\r}{};
    chomp;
    next if (/^\s*$/);
  WHERE: {

      ## --- a warning section ------------------------
      (/^\s*!!/) and do {
	## ill-defined guesses are marked by >>
	push @{$self->{warnings}},
	  "The guess parameter $1 did not affect the fit"
	    if (/>>\s*(\w+)/);
	push @{$self->{warnings}}, "Fitting was not performed."
	  if (/FITTING/);
	last WHERE;
      };

      ## --- project information section --------------
      ($section eq 'header') and do {
	if (/^\s*=+$/) {
	  $section = 'general';
	  last WHERE;
	};
	my @line = split(/\s+:\s+/, $_);
	$self->{info}{$line[0]} = $line[1] || " ";
	last WHERE;
      };

      ## --- fit statistics section --------------
      ($section eq 'general') and do {
	($section = 'guess'), last WHERE if (/^Guess/);
      GEN: {
	  ($self->{stats}{nidp}   = $1),                next GEN if (/^Independent points\s+=\s+(\d*\.\d+)/);
	  ($self->{stats}{nvar}   = sprintf("%d", $1)), next GEN if (/^Number of variables\s+=\s+(\d*\.\d+)/);
	  ($self->{stats}{chisqr} = $1),                next GEN if (/^Chi-square\s+=\s+(\d*\.\d+)/);
	  ($self->{stats}{chinu}  = $1),                next GEN if (/^Reduced Chi-square\s+=\s+(\d*\.\d+)/);
	  ($self->{stats}{rfact}  = $1),                next GEN if (/^R-factor\s+=\s+(\d*\.\d+)/);
	  ($self->{stats}{epsk}   = $1),                next GEN if (/^Measurement uncertainty \(k\)\s+=\s+(\d*\.\d+)/);
	  ($self->{stats}{epsr}   = $1),                next GEN if (/^Measurement uncertainty \(R\)\s+=\s+(\d*\.\d+)/);
	  ($self->{stats}{ndata}  = sprintf("%d", $1)), next GEN if (/^Number of data sets\s+=\s+(\d*\.\d+)/);
	}
	last WHERE;
      };

      ## --- guess parameters section --------------
      ($section eq 'guess') and do {
	if (/^Def/) {		# recognize next section
	  $self->{stats}{pathindex} = "";
	  if (/\(using \"(.*)\"/) { # snarf ifeffit's current path
	    $self->{stats}{pathindex} = $1;
	  };
	  ($section = 'def');
          last WHERE;
	};
	($section = 'restraint'),  last WHERE if (/^Restraints/);
	($section = 'bkg'),        last WHERE if (/^Background/);
	($section = 'set'),        last WHERE if (/^Set/);
	($section = 'after'),      last WHERE if (/^After/);
	($section = 'corr'),       last WHERE if (/^Correlations/);
	if (/^=+ Data set >>(.+)<</) {
	  ($section = 'dataset');
	  ++$data_set;
	  $current_set = $1;
	  push @{$self->{"chifiles"}}, $current_set;
	  $self->{$current_set}->{titles} = [];
	  $self->{$current_set}->{paths} = [];
	  last WHERE;
	};
	if (/^\s+(\w+)\s+=\s+(-?\d*\.\d+)\s+\+\/\-\s+(\d*\.\d+)\s+\(guessed as ([\-\*\+\/a-zA-Z_0-9. ()]+)\)/) {
	  $self->{bestfit}{$1} = $2;
	  $self->{error}{$1}   = $3;
	  $self->{initial}{$1} = $4;
	  push @{ $self->{order}->{guess} }, $1;
	} elsif (/^\s+(\w+)\s+=\s+(-?\d*\.\d+)\s+\+\/\-\s+(\d*\.\d+)\s+\((-?\d*(\.\d+|))\)/) {
	  $self->{bestfit}{$1} = $2;
	  $self->{error}{$1}   = $3;
	  $self->{initial}{$1} = $4;
	  push @{ $self->{order}->{guess} }, $1;
	};
	last WHERE;
      };

      ## --- the background parameters section --------------
      ($section eq 'bkg') and do {
	if (/^Def/) {		# recognize next section
	  $self->{stats}{pathindex} = "";
	  if (/\(using \"(.*)\"/) { # snarf ifeffit's current path
	    $self->{stats}{pathindex} = $1;
	  };
	  ## fill up correlations hash with zeros, that way all
	  ## possible correlations are defined.
	  foreach my $x (sort (keys %{$self->{bestfit}})) {
	    foreach my $y (sort (keys %{$self->{bestfit}})) {
	      last if ($x eq $y);
	      my $key = join(":", $x, $y);
	      $self->{corr}->{$key} = 0;
	    };
	  };
	  ($section = 'def');
          last WHERE;
	};
	($section = 'restraint'), last WHERE if (/^Restraints/);
	($section = 'set'),       last WHERE if (/^Set/);
	($section = 'after'),     last WHERE if (/^After/);
	($section = 'corr'),      last WHERE if (/^Correlations/);
	if (/^\s+(\w+)\s+=\s+(-?\d*\.\d+)\s+\+\/\-\s+(\d*\.\d+)/) {
	  $self->{bkg}{$1}    = $2;
	  $self->{bkgerr}{$1} = $3;
	  push @{ $self->{order}->{bkg} }, $1;
	};
	last WHERE;
      };

      ## --- the def parameters section --------------
      ($section eq 'def') and do {
	($section = 'restraint'),  last WHERE if (/^Restraints/);
	($section = 'set'),        last WHERE if (/^Set/);
	($section = 'after'),      last WHERE if (/^After/);
	($section = 'bkg'),        last WHERE if (/^Background/);
	($section = 'corr'),       last WHERE if (/^Correlations/);
	if (/^=+ Data set >>(.+)<</) {
	  ($section = 'dataset');
	  ++$data_set;
	  $current_set = $1;
	  push @{$self->{"chifiles"}}, $current_set;
	  $self->{$current_set}->{titles} = [];
	  $self->{$current_set}->{paths} = [];
	  last WHERE;
	};
	($self->{def}{$1} = $2) if (/^\s+(\w+)\s+=\s+(-?\d*(\.\d+|))/);
	push @{ $self->{order}->{def} }, $1;
	last WHERE;
      };

      ## --- the restraint section -------------------
      ($section eq 'restraint') and do {
	($section = 'set'),   last WHERE if (/^Set/);
	($section = 'after'), last WHERE if (/^After/);
	($section = 'bkg'),   last WHERE if (/^Background/);
	($section = 'corr'),  last WHERE if (/^Correlations/);
	if (/^=+ Data set >>(.+)<</) {
	  ($section = 'dataset');
	  ++$data_set;
	  $current_set = $1;
	  push @{$self->{"chifiles"}}, $current_set;
	  $self->{$current_set}->{titles} = [];
	  $self->{$current_set}->{paths} = [];
	  last WHERE;
	};
	if (/^\s+(\w+)\s+=\s+(-?\d*\.\d+)\s+(?:\:=)?\s+(.+)/) {
	  $self->{restraint}{$1} = $2;
	  $self->{restraint_expr}{$1} = $3;
	};
	push @{ $self->{order}->{restraint} }, $1;
	last WHERE;
      };

      ## --- set parameters section --------------
      ($section eq 'set') and do {
	($section = 'after'),   last WHERE if (/^After/);
	($section = 'bkg'),     last WHERE if (/^Background/);
	($section = 'corr'),    last WHERE if (/^Correlations/);
	if (/^=+ Data set >>(.+)<</) {
	  ($section = 'dataset');
	  ++$data_set;
	  $current_set = $1;
	  push @{$self->{"chifiles"}}, $current_set;
	  $self->{$current_set}->{titles} = [];
	  $self->{$current_set}->{paths} = [];
	  last WHERE;
	};
	if (/^\s+(\w+)\s+=\s+(-?\d*(\.\d+|))/) {
	  ($self->{set}{$1} = $2);
	  push @{ $self->{order}->{set} }, $1;
	  ##print "?????>", $1, " ", $self->{order}->{set}, " ",  @{ $self->{order}->{set} }, $/;
	};
	last WHERE;
      };

      ## --- after-fit parameters section --------------
      ($section eq 'after') and do {
	($section = 'bkg'),     last WHERE if (/^Background/);
	($section = 'corr'),    last WHERE if (/^Correlations/);
	if (/^=+ Data set >>(.+)<</) {
	  ($section = 'dataset');
	  ++$data_set;
	  $current_set = $1;
	  push @{$self->{"chifiles"}}, $current_set;
	  $self->{$current_set}->{titles} = [];
	  $self->{$current_set}->{paths} = [];
	  last WHERE;
	};
	(($self->{after}{$1}, $self->{after_expr}{$1}) = ($2, $3)) if (/^\s+(\w+)\s*:\s*(-?\d*\.\d+)\s*=\s*(.+)/);
	push @{ $self->{order}->{after} }, $1;
	last WHERE;
      };

      ## --- correlations section + cormin --------------
      ($section eq 'corr') and do {
	if (/^All other[^0-9]*(\d\.\d+)/) { # recognize next section
	  $self->{stats}{cormin} = $1;
	  $section = 'dataset';
	  last WHERE;
	};
	if (/^\s+(\w+) and (\w+)\s+-->\s+(-?\d*\.\d+)/) {
	  my $key = join(":", $1, $2);
	  ($key = join(":", $2, $1)) unless exists $self->{corr}->{$key};
	  my $val = $3;
	  $self->{corr}{$key} = $val;
	  push @{ $self->{order}->{correlation} }, $key;
	};
	last WHERE;
      };

      ## --- data set info section --------------
      ($section eq 'dataset') and do {
	## grab the label for the current data set, use this as a hash
	## key in the data structure
	if (/^=+ Data set >>(.+)<</) {
	  ++$data_set;
	  $current_set = $1;
	  push @{$self->{"chifiles"}}, $current_set;
	  $self->{$current_set}->{titles} = [];
	  $self->{$current_set}->{paths} = [];
	  last WHERE;
	};
	if (/^\s+=+/) {		# recognize next section
	  $section = 'paths';
	  last WHERE;
	};
      DATASET: {
	  ## grab operational params and data set specific statistics
	  ($_ =~ /^\s+$opregex/) and do {
	    my $key = $opparams{$1};
	    if ($key eq 'pcpath') {
	      $self->{$current_set}->{$key} = (split(/\s+=\s+/, $_))[1];
	    } else {
	      $self->{$current_set}->{$key} = (split(/(:|\s+=)\s+/, $_))[2];
	    };
	    last DATASET;
	  };
	  ## grab title lines associated with this data set
	  ($_ =~ /^\s+title lines/) and do {
	    $self->{$current_set}->{titles} = [];
	    my $line = <LOG>;
	    while ($line !~ /^\s*$/) {
	      chomp $line;
	      $line =~ s/^\s+//;
	      push @{$self->{$current_set}->{titles}}, $line;
	      $line = <LOG>;
	    };
	  };
	};
	last WHERE;
      };

      ## --- paths section for "current" data set --------------
      ($section eq 'paths') and do {
	if (/=+ Data set >>(.+)<</) { # recognize and intialize the next data set
	  ++$data_set;
	  $current_set = $1;
	  push @{$self->{"chifiles"}}, $current_set;
	  $self->{$current_set}->{titles} = [];
	  $self->{$current_set}->{paths} = [];
	  $section = 'dataset';
	  last WHERE;
	};
	if ($_ !~ /^\s+$ppregexp/) { # the line identifying this path
	  ($path = $_) =~ s/^\s+//;
	  $path =~ s/\s*\.\.$//;
	  push @{$self->{$current_set}->{paths}}, $path;
	  $path = $current_set . ": " . $path;
	  $self->{$path} = {};
	};
	last WHERE if ($! =~ /^\s+reff\+dr/); # skip the reff+dr line
	if ($_ =~ /^\s+feff/) {	# treat feff and id as strings
	   $self->{$path}{feff} = (split(/\s+=\s+/, $_))[1];
	  last WHERE;
	} elsif ($_ =~ /^\s+(id|label)/) {
	   $self->{$path}{id} = (split(/\s+=\s+/, $_))[1] || "";
	  last WHERE;
	};
	## snarf the rest of the path params as numbers
	while (/$ppregexp\s+=\s+(-?\d*\.\d+)/g) {
	  ##print join(" ", $path, $1, $5), $/;
	  my $key = $1;
	  #($key = 'ns02') if ($key =~ /s02/);
	  $self->{$path}{$key} = $4;
	};
	last WHERE;
      };
    };

  };
  close LOG;

  ## fill up correlations hash with zeros, that way all
  ## possible correlations are defined.
  foreach my $x (sort (keys %{$self->{bestfit}})) {
    foreach my $y (sort (keys %{$self->{bestfit}})) {
      last if ($x eq $y);
      my $key = join(":", $x, $y);
      $self->{corr}->{$key} ||= 0;
    };
    foreach my $y (sort (keys %{$self->{bkg}})) {
      my $key = join(":", $x, $y);
      $self->{corr}->{$key} ||= 0;
    };
  };
};


sub list {
  my $self = shift;
  return (@{$self->{chifiles}})         if (lc($_[0]) eq 'data');

  return @{ $self->{order}->{guess}       }  if (lc($_[0]) eq 'guess');
  return @{ $self->{order}->{bkg}         }  if (lc($_[0]) eq 'bkg');
  return @{ $self->{order}->{def}         }  if (lc($_[0]) eq 'def');
  return @{ $self->{order}->{restraint}   }  if (lc($_[0]) =~ /restrain/);
  return @{ $self->{order}->{set}         }  if (lc($_[0]) eq 'set');
  return @{ $self->{order}->{after}       }  if (lc($_[0]) eq 'after');
  return @{ $self->{order}->{correlation} }  if (lc($_[0]) eq 'corr');

##   return (keys %{$self->{bestfit}})     if (lc($_[0]) eq 'guess');
##   return (keys %{$self->{bkg}})         if (lc($_[0]) eq 'bkg');
##   return (keys %{$self->{def}})         if (lc($_[0]) eq 'def');
##   return (keys %{$self->{restraint}})   if (lc($_[0]) eq 'restraint');
##   return (keys %{$self->{set}})         if (lc($_[0]) eq 'set');
##   return (keys %{$self->{after}})       if (lc($_[0]) eq 'after');
##   return (keys %{$self->{corr}})        if (lc($_[0]) eq 'corr');

  return ('Project title', 'Comment', 'Prepared by', 'Contact', 'Started',
	  'This fit at', 'Environment', 'Fit label', 'Data sets',
	  'Figure of merit') if (lc($_[0]) eq 'info');
  return (qw(nidp nvar chisqr chinu rfact epsk epsr cormin ndata
	     pathindex cormin))         if (lc($_[0]) eq 'stats');
  return (qw(file titles paths krange dk kwin kw rrange dr rwin fitspace
	     bkg nbkg pcpath chisqr rfact))  if (lc($_[0]) eq 'dataparams');
  return (qw(feff id label r reff dr degen s02 e0 ss2 3rd 4th ei dphase))
                                        if (lc($_[0]) eq 'pathparams');
};

sub get {
  my $self = shift;
  my $item = $_[0];
  my $escaped = _escape_meta($item);

  my @info  = ('Project title', 'Comment', 'Prepared by', 'Contact', 'Started',
	       'This fit at', 'Environment', 'Fit label', 'Data sets', 'Figure of merit');
  my @stats = (qw(nidp nvar chisqr chinu rfact epsk epsr cormin ndata
		  pathindex cormin));

 QUERY: {

    ## warnings
    return @{$self->{warnings}} if ($item eq 'warnings');

    ## project information
    return $self->{info}->{$item} if (grep {/^$escaped$/} @info);

    ## fit statistics
    return $self->{stats}->{$item}||0 if (grep {/^$escaped$/} @stats);

    ## guess variables
    return ($self->{bestfit}->{$item},
	    $self->{error}  ->{$item},
	    $self->{initial}->{$item}) if (grep {/^$escaped$/} $self->list('guess'));

    ## background variables
    return ($self->{bkg}->{$item},
	    $self->{bkgerr}  ->{$item}) if (grep {/^$escaped$/} $self->list('bkg'));

    ## def variables
    return $self->{def}->{$item} if (grep {/^$escaped$/} $self->list('def'));

    ## restraints
    return $self->{restraint}->{$item} if (grep {/^$escaped$/} $self->list('restraint'));

    ## set variables
    return $self->{set}->{$item} if (grep {/^$escaped$/} $self->list('set'));

    ## after-fit variables
    return $self->{after}->{$item} if (grep {/^$escaped$/} $self->list('after'));

    ## correlations
    if (lc($item) =~ /^corr/) {
      my $key = join(":", $_[1], $_[2]);
      ($key = join(":", $_[2], $_[1])) unless (exists $self->{corr}->{$key});
      return 0 unless (exists $self->{corr}->{$key});
      return $self->{corr}->{$key};
    };

    ## opparams and pathparams for a data set
    if (grep {/^$escaped$/} $self->list('data')) {
      my $tmp = _escape_meta($_[1]);
      ##print ">>$_[1]<<  >>$tmp<<\n";
      if (grep {/^$tmp$/} @{$self->{$item}->{paths}}) {
	my $key = join(": ", $item, $_[1]);
	return 0 unless exists($self->{$key}->{$_[2]});
	return $self->{$key}->{$_[2]} if (grep {/^$_[2]$/} $self->list('pathparams'));
      };
      return @{$self->{$item}->{titles}} if ($_[1] eq 'titles');
      return @{$self->{$item}->{paths}}  if ($_[1] eq 'paths');
      return $self->{$item}->{$_[1]} if (grep {/^$_[1]$/} $self->list('dataparams'));
      return -998;
    };



    return -999;
  };
};


sub _escape_meta {
  my $tmp = $_[0];
  $tmp =~ s/([\[\]^\$\\\(\)\+\*\-\?])/\\$1/g;
  #$tmp =~ s/\(/\\\(/g;
  return $tmp;
};

sub get_parameter {
  my $self = shift;
  my $item = $_[0];

  ## guess variables
  return ($self->{bestfit}->{$item},
	  $self->{error}  ->{$item},
	  $self->{initial}->{$item}) if (grep {/^$item$/} $self->list('guess'));

  ## def variables
  return $self->{def}->{$item} if (grep {/^$item$/} $self->list('def'));

  ## set variables
  return $self->{set}->{$item} if (grep {/^$item$/} $self->list('set'));

  ## after variables
  return ($self->{after}->{$item}, $self->{after_expr}->{$item}) if (grep {/^$item$/} $self->list('after'));

  # restraint
  return ($self->{restraint}->{$item}, $self->{restraint_expr}->{$item})
    if (grep {/^$item$/} $self->list('restraint'));

  $self -> get(@_);
};



##  display methods

sub header {
  my $self = $_[0];
  my $string = "";
  foreach my $i ($self -> list('info')) {
    my $this = $i;
    ($this = "This fit at") if ($this eq 'Last fit');
    my $val = $self->get($i);
    $string .= sprintf("%-15s :  ", $this);
    $string .= "\n", next if (not defined($val));
    $string .= "\n", next if ($val =~ /^\<.*\>$/);
    $string .= "\n", next if ($val =~ /^\s*$/);
    $string .= "$val\n";
  };
  $string .= "\n" . "=" x 60 . "\n\n";
  return $string;
};

sub stats {
  my $self = $_[0];
  my $string = "";
  $string .= "\nFitting statistics\n";
  my %names = (nidp   => "Number of independent points",
	       nvar   => "Number of variables",
	       chisqr => "Chi-square",
	       chinu  => "Reduced chi-square",
	       rfact  => "R-factor",
	       epsk   => "Measurement uncertainty (k)",
	       epsr   => "Measurement uncertainty (R)");
  foreach my $i ($self -> list('stats')) {
    next if (($i eq 'cormin') or ($i eq 'ndata') or ($i eq 'pathindex'));
    $string .= sprintf("  %-28s : %s\n", $names{$i}, $self -> get($i));
  };
  return $string;
};

sub guess {
  my $self = $_[0];
  my $string = "";
  $string .=  "\nGuess parameters\n";
  foreach my $i ($self -> list('guess')) {
    my @ret = $self->get_parameter($i);
    ##$notes{results} -> insert('end', join(" ", $i, @ret, $/));
    if (grep {/$i/} @Ifeffit::Tools::buffer) {
				## ... and was guessed as a math expr.
      if ($ret[2] !~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) {
	$string .= sprintf("  %-15s =  %12.7f : no effect on the fit  (guessed as %s)\n",
			   $i, @ret[0,2]);
				## ... and was guessed as a number
      } else {
	$string .= sprintf("  %-15s =  %12.7f : no effect on the fit  (%.4g)\n",
			   $i, @ret[0,2]);
      };
				## this variable was guessed as a math expr.
    } elsif ($ret[2] !~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) {
      $string .= sprintf("  %-15s =  %12.7f   +/-   %12.7f    (guessed as %s)\n",
			 $i, @ret);
    } else {		## this variable was guessed as a number
      $string .= sprintf("  %-15s =  %12.7f   +/-   %12.7f    (%.4f)\n",
			 $i, @ret);
    };
  };
  return $string;
};

sub def {
  my $self = $_[0];
  my $which = $_[1];
  my $string = "";
  $string .=  "\nDef parameters";
  $string .= " (using \"$which\")" if ($which);
  $string .= "\n";
  foreach my $i ($self -> list('def')) {
    $string .= sprintf("  %-15s =  %12.7f\n", $i, $self->get_parameter($i));
  };
  return $string;
};

sub restraint {
  my $self = $_[0];
  my $which = $_[1];
  my $string = "";
  foreach my $i ($self -> list('restraint')) {
    $string .= sprintf("  %-15s =  %12.7f  := %s \n", $i, $self->get_parameter($i));
  };
  return ($string) ? "\nRestraints\n" . $string : "";
};

sub set {
  my $self = $_[0];
  my $string = "";
  $string .=  "\nSet parameters\n";
  foreach my $i ($self -> list('set')) {
    $string .= sprintf("  %-15s =  %s\n", $i, $self->get_parameter($i));
  };
  return $string;
};

sub after {
  my $self = $_[0];
  my $string = "";
  foreach my $i ($self -> list('after')) {
    $string .= sprintf("  %-15s : %12.7f = %s\n", $i, $self->get_parameter($i));
  };
  return ($string) ? "\nAfter-fit parameters\n" . $string : "";
};

sub correlations {
  my $self = $_[0];
  my $cormin = $self->get('cormin');
  my $string = "\nCorrelations between variables:\n";
  foreach my $c ($self->list("corr")) {
    my @vars = split(/:/, $c);
    my $corr = $self->get('correlation', @vars);
    next if (abs($corr) < $cormin);
    $string .= sprintf("  %10s and %-10s --> %7.4f\n", @vars, $corr);
  };
  $string .= "All other correlations are below $cormin\n\n";
  return $string;
};

sub dataparams {
  my $self = $_[0];
  my $data = $_[1];
  my $write_titles = $_[2];
  my $string = "\n ===== Data set >>" . $data . "<< " . "=" x 40 . "\n\n";
  my %opparams = reverse (file			       => 'file',
			  'k-range'		       => 'krange',
			  dk			       => 'dk',
			  'k-window'		       => 'kwin',
			  'k-weight'		       => 'kw',
			  'R-range'		       => 'rrange',
			  dR			       => 'dr',
			  'R-window'		       => 'rwin',
			  'fitting space'	       => 'fitspace',
			  'background function'	       => 'bkg',
			  'spline parameters'	       => 'nbkg',
			  'phase correction'	       => 'pcpath',
			  'Chi-square'		       => 'chisqr',
			  'R-factor for this data set' => 'rfact');
  if (defined($self->{$data}->{rfact})) {
    $string .= sprintf("  %-19s = %s\n", 'file', $self->get($data, 'file'));
  } else {
    $string .= sprintf("  %-19s = %s\n", 'file', "");
  };
  if ($write_titles) {
    $string .= "  titles:\n";
    $string .= join("\n", @{$self->get($data, 'titles')});
    $string .= "\n";
  };
  foreach my $k (qw(krange dk kwin kw rrange dr rwin fitspace bkg pcpath)) {
    $string .= sprintf("  %-19s = %s\n", $opparams{$k}, $self->get($data, $k));
    $string .= sprintf("  %-19s = %s\n", $opparams{nbkg}, $self->get($data, 'nbkg'))
      if (($k eq 'bkg') and $self->get($data, 'nbkg'));
  };
  $string .= sprintf("\n  R-factor for this data set = %s\n", $self->get($data, 'rfact'))
    if defined($self->{$data}->{rfact});
  $string .= "\n";
  return $string;
};



1;


__END__

=head1 NAME

B<Ifeffit::ArtemisLog> - read Artemis log files

=head1 SYNOPSIS

    use Ifeffit::ArtemisLog;
    my $data = Ifeffit::ArtemisLog -> new();
    $data -> read("myfit.log");
    print "Reduced chi-square = ", $data -> get("chinu");

=head1 DESCRIPTION


B<Ifeffit::ArtemisLog> is an object oriented representation of log
files written by Artemis, which contain the results of a fit to EXAFS
data.  Using B<Ifeffit::ArtemisLog> you can easily extract information
from these log files and easily write specially tailored reports on
your fitting results.  See L<EXAMPLES> below for a simple script to
show the temperature dependence of a variable in a set of fits.


=head1 METHODS

=over 4

=item new()

The C<new> method is used to create the ArtemisLog object.  Optionally
you can give the name of the log file as an argument to the C<new> method.

  my $data = Ifeffit::ArtemisLog -> new('myfit.log');

=item read()

The C<read> method reads the log file, parses its contents, and saves
its information in a data structure.  This method is called when
C<new> is given a log file as its argument.

  $data -> read('myfit.log');

=item list()

The list method returns lists of general information about the data
structure and about the contents of the log file.  C<list> can be
called in a number of ways.

Return a list of the labels of all the data sets used in the fit:
    $data -> list('data');

Return a list of all guess variables used in the fit:
    $data -> list('guess');

Return a list of all def variables used in the fit:
    $data -> list('def');

Return a list of all set variables used in the fit:
    $data -> list('set');

Return a list of all after-fit variables:
    $data -> list('after');

Return a list of identifiers for the project information:
    $data -> list('info');

Return a list of identifiers for the fitting statistical:
    $data -> list('stats');

Return a list of identifiers for the fitting parameters for each data
set:
    $data -> list('dataparams');

Return a list of identifiers for the path parameters:
    $data -> list('pathparams');

=item get()

This method returns values of the various parameters read from the log
file.  The C<get> method takes one, two, or three arguments depending
on what information you are looking for.  If you ask to C<get>
something that Ifeffit::ArtemisLog cannot interpret, an error code
will be returned.  -999 is the code for a string that could not be
interpreted.  -998 is the code for an operational or path parameter
that could not be interpreted.

=over 4

=item def or set parameters

To get the value of a def or set parameter, use the one-argument form:
    my $value = $data -> get('def_or_set_param');

=item after-fit parameters

To get the evaluation of an after-fit parameter, use the one-argument form:
    my $value = $data -> get('after_param');

=item guess parameters

To get the best-fit value, error bar, and initial guess on a guess
parameter, use the one-argument form:
    my ($best_fit, $error, $initial) = $data -> get('guess_param');

=item correlations

To get the correlation between two guess parameters, use the
three-argument form:
    my $corr = $data -> get('correlation', 'var1', 'var2');

Any correlations below the cutoff set by the cormin parameter will be
reported as 0.

=item project information

To get project information, use the one-argument form:
    my $title = $data -> get('Project title');

The available project information parameters are identified by
'Project title', 'Comment', 'Prepared by', 'Contact', 'Started', 'This fit
at', and 'Environment'.  This list of identifiers is returned using
the C<list('info')> method.

=item fitting statistics

To get fitting statistics, use the one-argument form:
    my $chi_square = $data -> get('chisqr')

The identifiers for the various fitting statistic parameters are
returned using the C<list('stats')> method.  These identifiers are

    nidp nvar chisqr chinu rfact epsk epsr cormin ndata
    pathindex cormin

If the log file is from a summation (i.e. no fit was performed) 0 will
be returned for parameters such as rfact that were not computed.

=item data set parameters

To get the values of the fitting parameters for a data set as well as
data set specific statistics, use the two-argument form:
    my $k_weight = $data -> get($data_set, 'kw');

The titles or the list of paths associated with a data set are
returned by the C<get> method as lists:
    my @titles = $data -> get($data_set, 'titles');
    my @paths  = $data -> get($data_set, 'paths');

The identifiers for the the various data set parameters are returned
by the C<list('dataparams')> method.  They are:

    file titles paths krange dk kwin kw rrange dr rwin fitspace
    bkg pcpath chisqr rfact

=item path parameters

To get the values of path parameters for individual paths, use the
three-argument form:
    my $delta_R = $data -> get($data_set, $path, 'dr');

The identifiers for the path parameters are returned by the
C<list('pathparams')> method.  They are:

    feff id reff degen s02 e0 dr ss2 3rd 4th ei dphase

The first two arguments to C<get> in this case identify the data set
and the path.  The identifiers for the data sets and for the
individual paths depend on information obtained from the log file.
The identifiers for the data sets can be obtained by

    my @data_sets = $data -> list('data');

The identifiers for the paths can be obtained by

    my @paths  = $data -> get($data_set, 'paths');

These identifiers are related to the strings used as entries in the
Data and Paths list in Artemis.  The identifiers obtained as described
above will be presented in the same order as they appear in the Data
and Paths list.

=back

=item get_parameter()

It is possible for the C<get> method to return the wrong kind of
parameter in certain situations.  One such situation would be if you
have a guess, def, set, or after parameter called by the name of
fitting statistic parameter, for example, a guess parameter called
"chisqr".  That is not prohibited in Ifeffit, but it will lead to
confusion in Ifeffit::ArtemisLog.  To resolve this confusion, there is
the C<get_parameter> method, which operates by the same syntax as the
C<get> method, but which only serves to return guess, def, set, or
after parameters.  Doing C<$data -> get_parameter('chisqr')> would, in
the case of the example, return the value of the "chisqr" parameter,
while C<get('chisqr')> woould return the value of chi-square for the
fit.

=back



=head1 EXAMPLES

Here is a simple script illustrating the use of
B<Ifeffit::ArtemisLog>.  Suppose you have a set of temperature
dependent data on porridge at three temperatures: too cold, just
right, and too hot.  This script will read the log files from the fits
to these three data sets and print a report on the temperature
dependence of a sigma^2 parameter called "sig2".

     #!/usr/bin/perl -w

     use Ifeffit::ArtemisLog;
     $toocold   = Ifeffit::ArtemisLog -> new("toocold.log");
     $justright = Ifeffit::ArtemisLog -> new("justright.log");
     $toohot    = Ifeffit::ArtemisLog -> new("toohot.log");

     print  "#  temperature dependence of sig2 in porridge data", $\ ;
     print  "# --------------------------------------------", $\ ;
     print  "#   data_set    sig2    error   (initial)\n";
     printf " too_cold    %8.5f   %8.5f   %8.5f\n", $toocold   -> get("sig2");
     printf " justright   %8.5f   %8.5f   %8.5f\n", $justright -> get("sig2");
     printf " too_hot     %8.5f   %8.5f   %8.5f\n", $toohot    -> get("sig2");


=head1 AUTHOR

  Bruce Ravel, bravel@anl.gov
  http://feff.phys.washington.edu/~ravel/software/exafs/


=cut
