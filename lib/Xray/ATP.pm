package Xray::ATP;
######################################################################
## This is the Xray::ATP.pm module.  It exports a single function,
## parse_atp, which is the output engine for Atoms.
##
##  This program is copyright (c) 1998-2006 Bruce Ravel
##  <bravel@anl.gov>
##  http://cars9.uchicago.edu/~ravel/software/
##
## -------------------------------------------------------------------
##     All rights reserved. This program is free software; you can
##     redistribute it and/or modify it under the same terms as Perl
##     itself.
##
##     This program is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     Artistic License for more details.
## -------------------------------------------------------------------
##
######################################################################
## Time-stamp: <1999/12/03 09:05:33 bruce>
######################################################################
## Code:

=head1 NAME

Xray::ATP - Output engine for Atoms

=head1 SYNOPSIS

  use Xray::ATP;
  ($output, $is_feff) =
     parse_atp($atp, $cell, $keywords, \@cluster,
	       \@neutral, \$contents);

See L<Xray::Atoms> for a discussion of the arguments to C<parse_atp>.

=head1 DESCRIPTION

This module exports the C<parse_atp> function, which is the output
engine used by Atoms.  It takes an atp file type a
cell object, a keywords object, references to two lists, and a
reference to a scalar as its input.  On return, it fills the scalar
with the text string output and returns a two element array.  The two
elements are the default filename taken from the atp file and a flag
indicating whether the output is intended for Feff.

This module must be used in conjunction with <Xray::Atoms>.  It exists
as a separate module because about half the length of the Atoms module
was the C<parse_atp> function and its utilities.  It seemed more
efficient from a maintenance viewpoint to make two modules.

=cut



use strict;
use vars qw($VERSION $cvs_info $module_version @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(parse_atp);
#@EXPORT_OK = ;

$cvs_info = '$Id: ATP.pm,v 1.4 2000/11/21 01:09:32 bruce Exp $ ';
$module_version = 1.41; #(split(' ', $cvs_info))[2] || "pre_release";
$VERSION = $module_version;

use Carp;
use Xray::Atoms qw(rcdirectory absorption mcmaster i_zero self);
use Xray::Xtal;
use Xray::Absorption;
use Chemistry::Elements qw(get_Z);
use Text::ParseWords;
use constant EV2RYD => 13.605698;
use constant PI => 3.14159265358979323844;
use constant EPSILON => 0.00001;


## -------------------------------------------------------------------
## This beast handles the atoms template (atp) files

## the arguments are
##   1. atp type
##   2. reference to a cell
##   3. reference to the keyword data
##   4. reference to a cluster (or the calculation for dafs)
##   5. reference to an array, (not used -- a placeholder)
##   6. reference to a scalar (filled with the output data on return)
sub parse_atp {
  my ($atptype, $cell, $keywords, $r_cluster, $r_neutral, $r_contents) = @_;
  my %ipots	 = ();
  my $ipot_style = "species";
  my @overfull	 = ();
  my ($central, $xcenter, $ycenter, $zcenter, $is_host) =
    $cell -> central($keywords->{"core"});
  ($is_host) or $keywords->{"dopant_core"} = $central;

  ## meta variables
  my %meta_data = ("precision"	  => "%9.5f",
		   "filetype"	  => "file",
		   "inc_begin"	  => 0,
		   "list_type"	  => "",
		   "is_feff"	  => 0,
		   "is_gnxas"	  => 0,
		   "occupancy"	  => 1,
		   "small_sphere" => 2.2,
		   "output_file"  => "");

  ## find and fetch the chosen atp file
  ## search in the user's .atoms directory, then in the system atp directory
  $meta_data{output_file} = $atptype . ".out";
  ($atptype eq "test") and $meta_data{output_file} = $^O . ".dat";
  my ($atpbase, $rcdir) = ($atptype.".atp", &rcdirectory);
  my $atpfile = File::Spec->catfile($rcdir, "atp", $atpbase);
  (-e $atpfile) or
    $atpfile = File::Spec->catfile($Xray::Atoms::atp_dir, $atpbase);
  (-e $atpfile) or do {
    warn "No such atp file \"$atptype\"\n";
    return 0;
  };
  open (ATP, $atpfile) || die "Could not open atp file \"$atptype\"\n";
  my @atp = <ATP>;		# slurp in the atp file
  close ATP;

  ## set up piles of useful variables
  my %edges = (
	       "no" => 0,  "k"  => 1,  "l1" => 2,  "l2" => 3,  "l3" => 4,
	       "m1" => 5,  "m2" => 6,  "m3" => 7,  "m4" => 8,  "m5" => 9,
	       "n1" => 10, "n2" => 11, "n3" => 12, "n4" => 13, "n5" => 14,
	       "n6" => 15, "n7" => 16, "o1" => 17, "o2" => 18, "o3" => 19,
	       "o4" => 20, "o5" => 21, "o6" => 22, "o7" => 23, "p1" => 24,
	       "p2" => 25, "p3" => 26
	      );
  my %gnxas_class  = ( "triclinic"    => "T",
		       "cubic"	      => "C",
		       "hexagonal"    => "H",
		       "monoclinic"   => "M",
		       "orthorhombic" => "O",
		       "trigonal"     => "R",
		       "tetragonal"   => "E");

  ## simple substitutions
  my ($aa, $bb, $cc, $aalpha, $bbeta, $ggamma, $space, $given,
      $setting, $bravais) =
    $cell -> attributes("A", "B", "C", "Alpha", "Beta", "Gamma",
			"Space_group", "Given_group", "Setting", "Bravais");
  ##@bravais ||= ("none");
  ##my @bravais = defined($bravais) ? @$bravais : ("none");
  my $r1	  = $$r_cluster[1][4]    || 0;
  ($atptype =~ /powder/) and $r1 = 0;
  my $qvec	  = $keywords->{"qvec"}  || [0, 0, 0];
  my $shift_vec	  = $keywords->{"shift"} || [0, 0, 0];
  my $edge_energy =
    Xray::Absorption -> get_energy($central, $keywords->{"edge"});
  my $abslist	  =
    join(",", &get_abs_list($cell, $keywords, $central, \%meta_data));
  my $gnid = (@{$keywords->{"title"}}) ?
    (split(" ", $ {$keywords->{"title"}}[0]))[0] : "abc";
  $gnid ||= "abc";		# the bizarre case of "title = "
  my %match_words =
    (
				# central atom tokens
     "central"	  => ucfirst($central),
     "ctag"	  => $keywords->{"core"},
     "fxc"        => $keywords->{"cformulas"}->[0],
     "fyc"        => $keywords->{"cformulas"}->[1],
     "fzc"        => $keywords->{"cformulas"}->[2],
				# edge tokens
     "edge"	  => ucfirst($keywords->{"edge"}),
     "iedge"	  => $edges{lc($keywords->{"edge"})},
     "eedge"	  => sprintf($meta_data{precision}, $edge_energy),
     "redge"      => sprintf($meta_data{precision}, $edge_energy/EV2RYD),
				# distance tokens
     "nclus"	  => $#{$r_cluster}+1,
     "rmax"	  => sprintf($meta_data{precision}, $keywords->{"rmax"}),
     "rnn"	  => sprintf($meta_data{precision}, sqrt($r1)),
     "rss"	  => sprintf($meta_data{precision},
			     $meta_data{small_sphere}*sqrt($r1)+0.00001),
				# unit cell tokens
     "a"	  => sprintf($meta_data{precision}, $aa),
     "b"	  => sprintf($meta_data{precision}, $bb),
     "c"	  => sprintf($meta_data{precision}, $cc),
     "alpha"	  => sprintf($meta_data{precision}, $aalpha),
     "beta"	  => sprintf($meta_data{precision}, $bbeta),
     "gamma"	  => sprintf($meta_data{precision}, $ggamma),
     "space"	  => ucfirst($space),
     "given"	  => $given,
     "group"	  => $$Xray::Xtal::r_space_groups{$space}->{number},
     "class"	  => $cell -> crystal_class(),
     "bravais"	  => Xray::Atoms::bravais_string($bravais,$meta_data{is_gnxas}),
     "setting"	  => $setting,
				# non-data tokens
     "os"	  => $^O,
     "n"          => $/,
				# gnxas tokens
     "gnclass"	  => $gnxas_class{$cell -> crystal_class()},
     "gnid"       => $gnid,
     "nabs"       => &get_nabs($cell, $central),
     "abslist"    => $abslist,
				# dafs tokens
     "emin"	  => sprintf($meta_data{precision}, $keywords->{"emin"}  || 0),
     "emax"	  => sprintf($meta_data{precision}, $keywords->{"emax"}  || 0),
     "estep"	  => sprintf($meta_data{precision}, $keywords->{"estep"} || 0),
     "reflection" => "(" . join(" ", map {sprintf "%d", $_} @$qvec) . ")",
     "dspacing"	  => sprintf($meta_data{precision}, $cell -> d_spacing(@$qvec)),
     "thickness"  => sprintf($meta_data{precision}, $keywords->{"thickness"} || 0),
				# powder tokens
     "energy"     => sprintf($meta_data{precision}, $keywords->{"energy"} || 0),
     "lambda"     => sprintf($meta_data{precision}, $keywords->{"lambda"} || 0),
    );
  my @numeric =
    qw(eedge redge rmax rnn rss a b c alpha beta gamma emin emax estep dspacing);
  map { $match_words{$_} =~ s/0{2,}$/0/ } @numeric;
  $match_words{'redge'}  =~ s/ //g;
  $match_words{'gnid'}   =~ s/\W//g;

  while (@atp) {
    ## the game is to interpret $line and modify it as appropriate then,
    ## outside the switch, print out the modified $line
    my $line  = shift @atp;
    (my $trimmed_line = $line) =~ s/^\s+//; # trim leading blanks
  ATP_SWITCH: {

      ## ========================== this is an atp <com>ment
      ($trimmed_line =~ /^\<com/) && do {
	$line = "";
	last ATP_SWITCH;
      };

      ## ========================== this is file(1) magic
      ($trimmed_line =~ /^\<atp/) && do {
	$line = "";
	last ATP_SWITCH;
      };

      ## ========================== meta data line
      ($trimmed_line =~ /^\<meta/) && do {
	chomp $line;
	$line =~ tr/\<>/  /;	# this precludes having < or > in the meta data
	my @words = &quotewords('\s+', 0, $line);
	shift @words;		# shift off <meta
	while (@words) {
	  my $word = shift @words;
	  next unless $word;
	META: {
	    ($word eq ":precision") && do {
	      $meta_data{precision} = shift @words;
	      $meta_data{precision} = "%" . $meta_data{precision} . "f";
	      map { ($match_words{$_} =
		     sprintf($meta_data{precision}, $match_words{$_}))
		      =~ s/0{2,}$/0/
		    } @numeric;
	      last META;
	    };
	    ($word eq ":file") && do {
	      $meta_data{filetype} = shift @words;
	      last META;
	    };
	    ($word eq ":output") && do {
	      $meta_data{output_file} = shift @words;
	      last META;
	    };
	    ($word eq ":incbegin") && do {
	      $meta_data{inc_begin} = shift @words;
	      last META;
	    };
	    ($word eq ":list") && do {
	      $meta_data{list_type} = shift @words;
	      last META;
	    };
	    ($word eq ":feff") && do {
	      $meta_data{is_feff} = shift @words;
	      ($meta_data{is_feff}) and $meta_data{occupancy} = 0;
	      last META;
	    };
	    ($word eq ":gnxas") && do {
	      $meta_data{is_gnxas} = shift @words;
	      $match_words{"bravais"} =
		Xray::Atoms::bravais_string($bravais,$meta_data{is_gnxas}),
	      ($meta_data{is_gnxas}) and $meta_data{occupancy} = 0;
	      ($meta_data{is_gnxas}) and
		map { $match_words{$_} =~ s/^ +// } qw(rmax rnn rss);
	      last META;
	    };
	    ($word eq ":occupancy") && do {
	      $meta_data{occupancy} = shift @words;
	      last META;
	    };
	    ($word eq ":margin") && do {
	      $meta_data{margin} = shift @words;
	      $keywords->make(overfull_margin=>$meta_data{margin});
	      last META;
	    };
	    ($word eq ":sphere") && do {
	      $meta_data{small_sphere} = shift @words;
	      if (@$r_cluster) {
		($match_words{"rss"} =
		 sprintf($meta_data{precision},
			 $meta_data{small_sphere}*
			 sqrt($$r_cluster[1][4])+0.00001))
		  =~ s/0{2,}$/0/;
	      };
	      last META;
	    };
	  };
	};
	## fix up the value for nclus
	#($list_type eq "feff8")    &&
	#  ($match_words{"nclus"} = $#{$r_neutral}+1);
      LIST: {
	  ($meta_data{list_type} eq "symmetry") && do {
	    my $p = $cell -> get_symmetry_table();
	    $match_words{"nclus"} =  $#{$p} + 1;
	    last LIST;
	  };
	  ($meta_data{list_type} eq "atoms") && do {
	    my $p = $keywords->{'sites'};
	    $match_words{"nclus"} =  $#{$p} + 1;
	    $match_words{abslist} =
	      join(",", &get_abs_list($cell, $keywords,
				      $central, \%meta_data));
	    last LIST;
	  };
	  ($meta_data{list_type} eq "unit") && do {
	    my ($contents) = $cell -> attributes("Contents");
	    $match_words{"nclus"} =  $#{$contents} + 1;
	    last LIST;
	  };
	  ($meta_data{list_type} eq "overfull") && do {
	    @overfull = $cell->overfull($meta_data{margin});
	    $match_words{"nclus"} =  $#overfull + 1;
	    last LIST;
	  };
	  ($meta_data{list_type} eq "cluster") && do {
	    my $nc = 0;
	    map { my ($h) = $ {$$_[3]} -> attributes("Host");
		  ($h eq 1) and ++$nc } @$r_cluster;
	    $match_words{"nclus"} = $nc;
	    last LIST;
	  };
	};
	$line = "";
	last ATP_SWITCH;
      };


      ## ========================== id line
      ($trimmed_line =~ /^\<id/) && do {
	&ATP_id(\$line, $r_contents, $keywords, \%meta_data);
	last ATP_SWITCH;
      };

      ## ========================== ease line
      (($trimmed_line =~ /^\<ease/) or ($trimmed_line =~ /^\<fuse/)) && do {
	&ATP_ease(\$line, $r_contents);
	last ATP_SWITCH;
      };

      ## ========================== absorption data resource
      ($trimmed_line =~ /^\<resource/) && do {
	&ATP_resource(\$line, $r_contents);
	last ATP_SWITCH;
      };

      ## ========================== shift vector
      ($trimmed_line =~ /^\<shift/) && do {
	&ATP_shift(\$line, $r_contents, $shift_vec, \%meta_data);
	last ATP_SWITCH;
      };

      ## ========================== GNXAS cell lines
      ($trimmed_line =~ /^\<gncell/) && do {
	&ATP_gncell(\$line, $r_contents, $cell, \%match_words, \%meta_data);
	last ATP_SWITCH;
      };

      ## ========================== corrections
      ($trimmed_line =~ /^\<corrections/) && do {
	unless (Xray::Absorption ->
		data_available($central,$keywords->{"edge"})) {
	  $line = "";
	  last ATP_SWITCH;
	};
	if ($keywords->{"edge"} =~ /^[mnop]/i) {
	  $line = "";
	  last ATP_SWITCH;
	};
	&ATP_corrections(\$line, $r_contents, $cell, $keywords, \$central);
	last ATP_SWITCH;
      };

      ## ========================== print title lines
      ($trimmed_line =~ /^\<title/) && do {
	&ATP_title(\$line, $r_contents, $keywords);
	last ATP_SWITCH;
      };

      ## ========================== potentials list
      ($trimmed_line =~ /^\<potentials/) && do {
	if ($meta_data{list_type} eq "dafs") {
	  $line = shift @atp;
	  $line = "";
	  last ATP_SWITCH;
	};
	my $ref = &ATP_potentials(\$line, $r_contents, $cell, $keywords, $r_cluster,
				  \@atp, \$ipot_style, \%ipots, $central);
	%ipots = %$ref;
	##print "after ATP_potentials: ", join("|",%ipots), $/;
	last ATP_SWITCH;
      };

      ## ========================== atoms list
      ($trimmed_line =~ /^\<list/) && do {
	##print "before ATP_atoms: ", join("|",%ipots), $/;
	&ATP_atoms(\$line, $r_contents, $cell, $keywords, $r_cluster,
		   $r_neutral, \%match_words, \@atp, \@overfull,
		   \$ipot_style, \%ipots, \%meta_data);
	last ATP_SWITCH;
      };

      ## ========================== dafs list
      ($trimmed_line =~ /^\<dafs/) && do {
	unless ($meta_data{list_type} eq "dafs") {
	  $line = shift @atp;
	  $line = "";
	  last ATP_SWITCH;
	};
	&ATP_dafs(\$line, $r_contents, $r_cluster, \@atp, \%meta_data);
	last ATP_SWITCH;
      };

      ## ========================== powder list
      ($trimmed_line =~ /^\<powder/) && do {
	unless ($meta_data{list_type} eq "powder") {
	  $line = shift @atp;
	  $line = "";
	  last ATP_SWITCH;
	};
	&ATP_powder(\$line, $cell, $r_contents, $r_cluster, \@atp, \%meta_data);
	last ATP_SWITCH;
      };

      ## ========================== any other line
      do {
	my $matchstring = join("|", keys %match_words);
	$line =~ s/\<($matchstring)>/$match_words{$1}/go;
	last ATP_SWITCH;
      };

    };

    $$r_contents .=  $line;
  };
  return ($meta_data{output_file}, $meta_data{is_feff});
};




## subroutines for type 4 tokens (block structures) -----------

sub ATP_id {
  my ($line, $r_contents, $keywords, $meta) = @_;
  chomp $$line;
  $$line =~ tr/\<>/  /;		# this precludes having < or > in the prefix
  my @words = &quotewords('\s+', 0, $$line);
  my $prefix = "";
  shift @words;			# shift off <id
  while (@words) {
    my $word = shift @words;
    next unless $word;
  ID: {
      ($word eq ":prefix") && do {
	$prefix = shift @words;
	last ID;
      };
    };
  };
  my $identity = $keywords->{'identity'} || $VERSION;
  $$r_contents .= $prefix .
    "This $$meta{filetype} was generated by $identity$/";
  $$r_contents .= $prefix .
    "Atoms written by and copyright (c) Bruce Ravel, 1998-2001$/";
  $$line ="";
};

sub ATP_ease {
  my ($line, $r_contents) = @_;
  chomp $$line;
  $$line =~ tr/\<>/  /;		# this precludes having < or > in the prefix
  my @words = &quotewords('\s+', 0, $$line);
  my ($filetype, $prefix) = ("feff", "");
  shift @words;			# shift off <ease or <fuse
  while (@words) {
    my $word = shift @words;
    next unless $word;
  ID: {
      ($word eq ":file") && do {
	$filetype = shift @words;
	last ID;
      };
      ($word eq ":prefix") && do {
	$filetype = shift @words;
	last ID;
      };
    };
  };
  $prefix ||= ($filetype eq "feff") ? " *!!&& " : "!!&& ";
  $$line    = "$/${prefix}Local Variables:$/";
  $$line   .=   "${prefix}input-program-name: \"$filetype\"$/";
  $$line   .=   "${prefix}End:$/";
};

sub ATP_resource {
  my ($line, $r_contents) = @_;
  chomp $$line;
  $$line =~ tr/\<>/  /;		# this precludes having < or > in the prefix
  my $prefix = "";
  my @words = &quotewords('\s+', 0, $$line);
  shift @words;			# shift off <reflection
  while (@words) {
    my $word = shift @words;
    next unless $word;
  ID: {
      ($word eq ":prefix") && do {
	$prefix = shift @words;
	last ID;
      };
    };
  };
  $$r_contents .= $prefix . Xray::Absorption -> current_resource . $/;
  $$line = "";
}


sub ATP_shift {
  my ($line, $r_contents, $shift_vec, $meta) = @_;
  chomp $$line;
  $$line =~ tr/\<>/  /;		# this precludes having < or > in the prefix
  my $prefix = "";
  my @words = &quotewords('\s+', 0, $$line);
  shift @words;			# shift off <shift
  while (@words) {
    my $word = shift @words;
    next unless $word;
  ID: {
      ($word eq ":prefix") && do {
	$prefix = shift @words;
	last ID;
      };
    };
  };
  if ($$shift_vec[0] or $$shift_vec[1] or $$shift_vec[2]) {
    $$r_contents .= $prefix . 'shift ' .
      join(" ", map {sprintf $$meta{precision}, $_} @$shift_vec) . $/;
  };
  $$line = "";
};

sub ATP_gncell {
  my ($line, $r_contents, $cell, $match_words, $meta) = @_;
  my $comma = ',';
  my $this_line .= sprintf($$meta{precision}, $$match_words{'a'});
  my $this_class = $cell -> crystal_class();
 CLASS_SWITCH: {
    ($this_class eq "triclinic") && do {
      $this_line .= join("",  $comma, $$match_words{'b'}, $comma,
			 $$match_words{'c'}, $/,
			 $$match_words{'alpha'}, $comma,
			 $$match_words{'beta'},  $comma,
			 $$match_words{'gamma'});

      last CLASS_SWITCH;
    };
    ($this_class eq "monoclinic") && do {
      $this_line .= join("",  $comma, $$match_words{'b'},  $comma,
			 $$match_words{'c'}, $/,
			 $$match_words{'beta'});

      last CLASS_SWITCH;
    };
    ($this_class eq "orthorhombic") && do {
      $this_line .= join("", $comma, $$match_words{'b'},  $comma,
			 $$match_words{'c'});
      last CLASS_SWITCH;
    };
    (($this_class eq "tetragonal") or ($this_class eq "hexagonal")) && do {
      $this_line .= join("",  $comma, $$match_words{'c'});
      last CLASS_SWITCH;
    };
    ($this_class eq "trigonal") && do {
      $this_line .= join("",  $comma,, $$match_words{'c'}, $/,
			 $$match_words{'beta'});
      last CLASS_SWITCH;
    };
  };
  $this_line .= $/;
  $this_line =~ s/ //g;
  $$r_contents .= $this_line;
  $$line = "";
}

sub ATP_corrections {
  my ($line, $r_contents, $cell, $keywords, $central) = @_;
  chomp $$line;
  $$line =~ tr/\<>/  /;		# this precludes having < or > in the prefix
  my @words = &quotewords('\s+', 0, $$line);
  my $prefix = "";
  my $write_line = 1;
  my $units = "cm-1";
  shift @words;			# shift off <corrections
  while (@words) {
    my $word = shift @words;
    next unless $word;
  CORR: {
      ($word eq ":prefix") && do {
	$prefix = shift @words;
	last CORR;
      };
      ($word eq ":prettyline") && do {
	$write_line = shift @words;
	last CORR;
      };
      ($word eq ":units") && do {
	$units = shift @words;
	last CORR;
      };
    };
  };
  my ($fluorescence) =
    ($keywords->{"nitrogen"} > 0.001) ||
      ($keywords->{"argon"}    > 0.001) ||
	($keywords->{"krypton"}  > 0.001);
  my $prettyline = sprintf "%s%s$/", $prefix, "-- * " x 13;
  my ($xsec, $delta, $density) =
    absorption($cell, $$central, $keywords->{"edge"});
  ($write_line) && ($$r_contents .= $prettyline);
  if ($units eq 'microns') {
    ## need to deal gracefully with the situation that $xsec or $delta
    ## are 0, this will cause 0's to be written out
    my $xx = $xsec  || 10e10;
    my $dd = $delta || 10e10;
    $$r_contents .=
      sprintf "%s  total mu*x=1: %8.2f microns,  unit edge step: %8.2f microns$/",
	$prefix, 10000/$xx, 10000/$dd;
  } else {
    $$r_contents .=
      sprintf "%s  total mu = %8.2f cm^-1,  delta_mu = %8.2f cm^-1$/",
	$prefix, $xsec, $delta;
  };
  $$r_contents .=
    sprintf "%s  specific gravity = %6.3f$/", $prefix, $density;
  my $sigmm = mcmaster($$central, $keywords->{"edge"});
  ($write_line) && ($$r_contents .= $prettyline);
  $units = "ang^2";
  $$r_contents .=
    sprintf "%s  Normalization correction:   %8.5f %s$/",
    $prefix, $sigmm, $units;
  if ($fluorescence) {
    my $sigi0 = i_zero($$central, $keywords->{"edge"},
		       $keywords->{"nitrogen"},
		       $keywords->{"argon"},
		       $keywords->{"krypton"});
    $$r_contents .=
      sprintf "%s  I0 correction:              %8.5f %s$/",
      $prefix, $sigi0, $units;
    my ($ampsa, $sigsa) = self($$central, $keywords->{"edge"}, $cell);
    $$r_contents .=
      sprintf "%s  self absorption correction: %8.5f %s$/",
      $prefix, $sigsa, $units;
    $$r_contents .=
      sprintf "%s            amplitude factor: %6.3f$/",
      $prefix, $ampsa;
    ($write_line) && ($$r_contents .= $prettyline);
    $$r_contents .=
      sprintf "%s  net correction:             %8.5f %s$/",
      $prefix, $sigmm + $sigi0 + $sigsa, $units;
  };
  ($write_line) && ($$r_contents .= $prettyline);
  $$line = "";
}

sub ATP_title {
  my ($line, $r_contents, $keywords) = @_;
  chomp $$line;
  $$line =~ tr/\<>/  /;		# this precludes having < or > in the prefix
  my @words = &quotewords('\s+', 0, $$line);
  my ($prefix, $lines) = ("",0);
  shift @words;			# shift off <titles
  while (@words) {
    my $word = shift @words;
    next unless $word;
  TITLES: {
      ($word eq ":prefix") && do {
	$prefix = shift @words;
	last TITLES;
      };
      ($word eq ":lines") && do {
	$lines = shift @words;
	($lines < 1) and $lines = 1;
	last TITLES;
      };
    };
  };
  my $count = 0;
  foreach my $title (@{$keywords->{"title"}}) {
    ++$count;
    ($lines) and ($count > $lines) and last;
    $$r_contents .=  $prefix . $title . $/;
  };
  if ($count == 0) {
    $$r_contents .=  $prefix . "..." . $/;
    $count = 1;
  };
  if ($count < $lines) {
    my $n = $lines - $count;
    $$r_contents .= ($prefix.$/) x $n;
  };
  $$line = "";
};

## subroutines for type 2 tokens (list structures) ------------

sub ATP_potentials {
  my ($line, $r_contents, $cell, $keywords, $r_cluster, $atp, $ipot_style, $ipots, $central) = @_;
  chomp $$line;
  $$line =~ tr/\<>/  /;
  my @words = &quotewords('\s+', 0, $$line);
  $$ipot_style = "species";	# species, tags, sites
  my ($gcd, $is_mol, $display) = (0, 0, 1);
  shift @words;			# shift off <potentials
  while (@words) {
    my $word = shift @words;
    next unless $word;
  POTS: {
      ($word eq ":ipots") && do {
	$$ipot_style = shift @words;
	last POTS;
      };
      ($word eq ":gcd") && do {
	$gcd = shift @words;
	last POTS;
      };
      ($word eq ":mol") && do {
	$is_mol = shift @words;
	last POTS;
      };
      ($word eq ":display") && do {
	$display = shift @words;
	last POTS;
      };
    };
  };
  unless (($$ipot_style eq "tags") or ($$ipot_style eq "sites")) {
    $$ipot_style = "species";
  };
  ##print "Potentials style is $$ipot_style\n";
  ($display) and $$line = shift @$atp;
  ## central atom information
  my $thisline = $$line;
  my %matches = ("ipot" => 0,
		 "stoi" => 0.001,
		 "znum" => sprintf("%2d",&get_Z($central)),
		 "elem" => sprintf("%-10s",ucfirst($central)),
		 "l"    => Xray::Absorption -> get_l($central)  );
  my $matchstring = join("|", keys %matches);
  $thisline =~ s/(\<($matchstring)>)/$matches{$2}/go;
  ($display) and $$r_contents .=  $thisline;
  ## and now all the rest ...
  %$ipots =
    $cell -> set_ipots($$ipot_style, $is_mol, $keywords->{"core"});
  unless ($display) {
    $$line = "";
    last ATP_SWITCH;
  };

  #print join("|",%$ipots), $/;
  $ipots = fix_ipots($ipots, $r_cluster, $$ipot_style);
  #print join("|",%$ipots), $/;

  my @keys = sort {$$ipots{$a} <=> $$ipots{$b}} (keys %$ipots);
  my %stoi = &get_stoi($cell, \@keys, $$ipot_style, $gcd);
  foreach my $key (@keys) {
    my $thisline = $$line;
    my $elem;
    my $pot_label;		# get the element symbol and the potential
    if ($$ipot_style eq "species") { # label for the current
      $elem = $key;		# ipot scheme
      $pot_label = sprintf("%-2s", ucfirst($elem));
    } elsif ($$ipot_style eq "tags") {
    TAG: foreach my $site (@{$cell->{Contents}}) {
	if ($ {$$site[3]}->{Tag} eq $key) {
	  $elem = $ {$$site[3]}->{Element};
	  $pot_label = sprintf("%-10s", $key);
	  last TAG;
	};
      };
    } elsif ($$ipot_style eq "sites") {
    ID: foreach my $site (@{$cell->{Contents}}) {
	if ($ {$$site[3]}->{Id} eq $key) {
	  $elem = $ {$$site[3]}->{Element};
	  my $tag = $ {$$site[3]}->{Tag};
	  $pot_label = sprintf("%-10s", $tag);
	  last ID;
	};
      };
    };
    my ($ip, $zn, $l, $stoi) =
      ($$ipots{$key},
       sprintf("%2d",&get_Z($elem)||0),
       Xray::Absorption -> get_l($elem),
       $stoi{$key});
    $elem = sprintf("%-2s",ucfirst($elem));
    my %matches = ("ipot" => $ip,
		   "znum" => $zn,
		   "elem" => sprintf("%-10s", $pot_label),
		   "l"    => $l,
		   "stoi" => $stoi,);
    my $matchstring = join("|", keys %matches);
    $thisline =~ s/(\<($matchstring)>)/$matches{$2}/go;
    $$r_contents .=  $thisline;
  };
  $$line = "";
  return $ipots;
};

## this ain't pretty...
sub ATP_atoms {
  my ($line, $r_contents, $cell, $keywords, $r_cluster,
      $r_neutral, $match_words, $atp, $overfull,
      $ipot_style, $ipots, $meta) = @_;
  chomp $$line;
  $$line =~ tr/\<>/  /;
  my @words = &quotewords('\s+', 0, $$line);
  my $style = "cluster";	# unit, overfull
  shift @words;			# shift off <list
  while (@words) {
    my $word = shift @words;
    next unless $word;
  ATOMS: {
      ($word eq ":style") && do {
	$style = shift @words;
	last ATOMS;
      };
      ($word eq ":margin") && do {
	$keywords->{"overfull_margin"} = shift @words;
	last ATOMS;
      };
    };
  };

  $$line = shift @$atp;

  my $inc = $$meta{inc_begin};
  my $r_atom_list;
  my $bigger  = ($#{$r_cluster} > $#{$r_neutral}) ?
    $#{$r_cluster} : $#{$r_neutral};
  my @indeces = map {""} (0..$bigger+1);
  my @bounce  = map {1}  (0..$bigger+1);
 LISTTYPE: {
    ($style eq "cluster") && do {
      $r_atom_list = $r_cluster;
      ($$line =~ /\<itag>/) && (@indeces = fetch_indeces($r_cluster));
      ($$line =~ /\<1bou>/) && (@bounce  = one_bounce($r_cluster));
      last LISTTYPE;
    };
    ($style eq "neutral") && do {
      $r_atom_list = $r_neutral;
      ($$line =~ /\<itag>/) && (@indeces = fetch_indeces($r_neutral));
      $$match_words{"nclus"} = $#{$r_neutral}+1;
      last LISTTYPE;
    };
    ($style eq "unit")    && do {
      my ($contents) = $cell -> attributes("Contents");
      $r_atom_list = \@{$contents};
      ($$line =~ /\<itag>/) && (@indeces = count_sites($r_atom_list));
      last LISTTYPE;
    };
    ($style eq "atoms")   && do {
      $r_atom_list = $keywords->{'sites'};
      last LISTTYPE;
    };
    ($style eq "overfull") && do {
     # (@$overfull) or
	@$overfull = $cell->overfull($keywords->{"overfull_margin"});
      $r_atom_list = $overfull;
      last LISTTYPE;
    };
    ## this one's a bit different...
    ($style eq "symmetry") && do {
      &symmetry_table($cell, $$line, $r_contents, $$meta{is_gnxas});
      $$line = "";
      return;
      #last ATP_SWITCH;
    };
  };
  if (($$meta{list_type} eq "dafs") and ($style !~ /atoms|unit|overfull/)) {
    $$line = shift @$atp;
    $$line = "";
    ## an error message would be good ...
    #last ATP_SWITCH;
    return;
  };

  my $atoms_cnt = 0;
  my %atoms_seen;
 ATOMS: foreach my $atom (@$r_atom_list) {
    my $thisline = $$line;
    my ($el, $tag, $thisipot, $x, $y, $z, $occ, $host);
    my ($file, $b, $bx, $by, $bz, $color, $valence) = ("", "", "", "", "", "");
    my ($fx, $fy, $fz, $utag) = ("", "", "", "");
    if ($style eq 'atoms') {
      ($el, $x, $y, $z, $tag, $occ) = @$atom;
      # next unless $occ;
      ++$atoms_cnt;
      $utag = $tag||ucfirst($el); #) =~ s/\s*$//;
      if ( $atoms_seen{$utag}++ )  {
	$utag .= '_' . $atoms_cnt;
      };
      $tag  = sprintf("%-10s", $tag);
      $occ  = sprintf($$meta{precision}, $occ);
      $thisipot = "";
    } else {
      ($el) = $ {$$atom[3]} -> attributes("Element");
      $el = lc($el);
      my $label;		# get the correct hash key for the
      if ($$ipot_style eq "species") { # current ipot scheme
	$label = $el;
      } elsif ($$ipot_style eq "tags") {
	($label) = $ {$$atom[3]} -> attributes("Tag");
      } elsif ($$ipot_style eq "sites") {
	($label) = $ {$$atom[3]} -> attributes("Id");
      };
      ($tag) = $ {$$atom[3]} -> attributes("Tag");
      $tag = sprintf("%-10s", $tag);
      ($utag) = $ {$$atom[3]} -> attributes("Utag");
      $utag = sprintf("%-13s", $utag);
      $thisipot = $inc ? $$ipots{$label} : 0;
      defined ($thisipot) or $thisipot = '?';
      ($thisipot =~ /\d/) or $thisipot = '?';
      ($host, $occ)  = $ {$$atom[3]} -> attributes("Host", "Occupancy");
      unless ($inc) {		# check for dopant central atom
	if ($keywords->{dopant_core} and (not $$meta{occupancy})) {
	  $el = $keywords->{dopant_core};
	  $tag = sprintf("%-10s", ucfirst($el));
	  $indeces[0] = sprintf("%-10s", $tag);
	};
      };
      ## next unless $ {$$atom[3]} -> attributes("Occupancy");
      if ((not $host) and (not $$meta{occupancy})) {
	## remove dopants from these lists
	splice @indeces, $inc, 1;
	splice @bounce, $inc, 1;
	next ATOMS;
      };
      ($x, $y, $z) =		# make sure coords are never -0.00000
	map { $_ = (abs($_) > EPSILON) ? $_ : 0; }
	  ($$atom[0], $$atom[1], $$atom[2]);
      ($fx, $fy, $fz) = @$atom[8..10];
    };
    my $znum = &get_Z($el);
    ## $die = 4 because I presume this warning has already been
    ## flagged at an earlier point in the execution of the program
    $x = Xray::Atoms::number($x, 4); #$keywords->{die});
    $y = Xray::Atoms::number($y, 4); #$keywords->{die});
    $z = Xray::Atoms::number($z, 4); #$keywords->{die});
    my $r = sprintf($$meta{precision}, sqrt($x**2 + $y**2 + $z**2));
    ($x, $y, $z) = map { sprintf($$meta{precision}, $_); } ($x, $y, $z);

    ## grab and format the remaining site attributes
    unless ($style eq 'atoms') {
      ($style eq 'cluster') and
	($fx, $fy, $fz) = map {sprintf "%s", $_} ($fx, $fy, $fz);
      ($file, $b, $bx, $by, $bz, $color, $valence) =
	$ {$$atom[3]} ->
	  attributes("File", "B", "Bx", "By", "Bz", "Color", "Valence");
      ($b, $bx, $by, $bz) =
	map { sprintf($$meta{precision}, $_); } ($b, $bx, $by, $bz);
    };


    ## it is possible for an overfilled list to be longer than a
    ## cluster, so...
    defined $indeces[$inc] or $indeces[$inc] = "";
    defined $bounce[$inc]  or $bounce[$inc]  = 1;
    my %matches = ("x"	      => $x,
		   "y"	      => $y,
		   "z"	      => $z,
		   "r"	      => $r,
		   "fx"	      => $fx,
		   "fy"	      => $fy,
		   "fz"	      => $fz,
		   "occ"      => $occ,
		   "ipot"     => $thisipot,
		   "znum"     => $znum,
		   "tag"      => $tag,
		   "utag"     => $utag,
		   "elem"     => sprintf("%-2s", ucfirst($el)),
		   "itag"     => sprintf("%-13s", $indeces[$inc]),
		   "1bou"     => $bounce[$inc],
		   "inc"      => sprintf("%4d", $inc),
		   "file"     => $file,
		   "b"	      => $b,
		   "bx"	      => $bx,
		   "by"	      => $by,
		   "bz"	      => $bz,
		   "color"    => $color,
		   "valence"  => $valence,
		   "n"	      => $/);
    ($$meta{is_gnxas}) and $matches{elem} = sprintf("%2s",ucfirst($el));
    my $matchstring = join("|", keys %matches);
    $thisline =~ s/\<($matchstring)>/$matches{$1}/g;
    $$r_contents .=  $thisline;
    ++$inc;
  };
  $$line = "";
};

sub ATP_dafs {
  my ($line, $r_contents, $r_cluster, $atp, $meta) = @_;
  chomp $$line;
  my $inc = $$meta{inc_begin};

  $$line = shift @$atp;
  foreach my $point (@$r_cluster) { # data stored in $r_cluster
    my $thisline = $$line;
    my ($e, $r, $i, $la) =		# make sure coords are never -0.00000
      ($$point[0], $$point[1], $$point[2], $$point[3]);
    my $asqr = $r**2 + $i**2;
    my $a = sqrt($asqr);
    my $p = atan2($i, $r);
    $e = sprintf("%10.3f", $e);
    ($r, $i, $a, $asqr, $p, $la) =
      map { sprintf($$meta{precision}, $_) } ($r, $i, $a, $asqr, $p, $la);
    my %matches = ("e"     => $e,
		   "a"     => $a,
		   "asqr"  => $asqr,
		   "r"     => $r,
		   "i"     => $i,
		   "la"    => $la,
		   "p"     => $p,
		   "n"     => $/,
		   "inc"   => sprintf("%5d", $inc++) );
    my $matchstring = join("|", keys %matches);
    $thisline =~ s/\<($matchstring)>/$matches{$1}/go;
    $$r_contents .=  $thisline;
  };
  $$line = "";
};


sub ATP_powder {
  my ($line, $cell, $r_contents, $r_cluster, $atp, $meta) = @_;
  chomp $$line;
  my $inc = $$meta{inc_begin};

  my $biggest = 0;
  $$line = shift @$atp;
  ## fetch the normalization constant
  foreach my $point (@$r_cluster) { # data stored in $r_cluster
    my ($tth, $h, $k, $l, $r, $i, $m) = @$point;
    my $p   = $cell -> multiplicity($h, $k, $l);
    my $amp = ($r**2 + $i**2) * $p;
    my $th  = PI*$tth/360;
    $amp   *= (1 + cos(2*$th)**2) / (sin($th)**2 * cos($th));
    $amp   *= exp(-2*$m);
    ($amp > $biggest) and $biggest = $amp;
  };
  foreach my $point (@$r_cluster) { # data stored in $r_cluster
    my $thisline = $$line;
    my ($tth, $h, $k, $l, $r, $i, $m) = @$point;

    my $p   = $cell -> multiplicity($h, $k, $l);
    my $a   = ($r**2 + $i**2);
    my $amp = $a * $p;
    my $th  = PI*$tth/360;
    my $lp  = (1 + cos(2*$th)**2) / (sin($th)**2 * cos($th));
    $amp   *= $lp*exp(-2*$m);
    $amp   *= 100/$biggest;
    my $ph  = atan2($i, $r);
    $th = $tth/2;

    ($r, $i, $a, $amp, $ph, $tth, $th, $lp) =
      map { sprintf($$meta{precision}, $_) } ($r, $i, $a, $amp, $ph, $tth, $th, $lp);
    my %matches = ("tth"   => $tth,
		   "th"    => $th,,
		   "a"     => $a,
		   "asqr"  => $amp,
		   "amp"   => $amp,
		   "r"     => $r,
		   "i"     => $i,
		   "p"     => $ph,
		   "lp"    => $lp,
		   "m"     => $m,
		   "h"     => sprintf("%2d", $h),
		   "k"     => sprintf("%2d", $k),
		   "l"     => sprintf("%2d", $l),
		   "n"     => $/,
		   "mult"  => sprintf("%2d", $p),
		   "inc"   => sprintf("%5d", $inc++) );
    my $matchstring = join("|", keys %matches);
    $thisline =~ s/\<($matchstring)>/$matches{$1}/go;
    $$r_contents .=  $thisline;
  };
  $$line = "";
};

## utility subroutines ----------------------------------------------

## return a count of the number of unique sites populated
sub get_nabs {
  my ($cell, $central) = @_;
  my ($sites) = $cell -> attributes("Contents");
  return 0 unless ($sites);
  my $count = 0;
  my %seen;
  foreach my $site (@{$sites}) {
    my ($elem) = $ {$$site[3]} -> attributes("Element");
    my ($id) = $ {$$site[3]} -> attributes("Id");
    unless ( $seen{$id}++ ) {
      (lc($central) eq lc($elem)) and ++$count;
    };
  };
  return $count;
};

## return a list of the indeces of the atoms in the cell contents list
## which are of the same species as the central atom but which are
## different unique sites (as needed for GNXAS CRYMOL file)
sub get_abs_list {
  my ($cell, $keywords, $central, $meta) = @_;
  my ($sites) = $cell -> attributes("Contents");
  my $is_atoms = ($$meta{list_type} eq "atoms");
  ($is_atoms) and $sites = $keywords->{'sites'};
  my $count = 0;
  my @list = ();
  return @list unless ($sites);
  my %seen;
  foreach my $site (@{$sites}) {
    ++$count;
    if ($is_atoms) {		# must be a gnxas SYM file
      my $elem = $site -> [0];
      (lc($central) eq lc($elem)) and push @list, $count;
    } else {			# must be a gnxas CRY file
      my ($elem) = $ {$$site[3]} -> attributes("Element");
      my ($id) = $ {$$site[3]} -> attributes("Id");
      unless ( $seen{$id}++ ) {
	(lc($central) eq lc($elem)) and push @list, $count;
      };
    };
  };
  return @list;
};

## this is a bit repetitive, but I might want to change it later
sub get_stoi {
  my ($cell, $keys, $type, $gcd) = @_;
  my @count = ();
  my ($sites) = $cell -> attributes("Contents");
  my $smallest = 1000000;
  foreach my $key (@$keys) {
    my $count = 0;
  STYLES: {
      ($type eq "species") && do {
	foreach my $site (@{$sites}) {
	  my ($tag) = $ {$$site[3]} -> attributes("Element");
	  (lc($key) eq lc($tag)) and ++$count;
	};
	last STYLES;
      };
      ($type eq "tags") && do {
	foreach my $site (@{$sites}) {
	  my ($tag) = $ {$$site[3]} -> attributes("Tag");
	  ($key eq $tag) and ++$count;
	};
	last STYLES;
      };
      ($type eq "sites") && do {
	foreach my $site (@{$sites}) {
	  my ($tag) = $ {$$site[3]} -> attributes("Id");
	  ($key == $tag) and ++$count;
	};
	last STYLES;
      };
    };
    push @count, $key, $count;
    $smallest = ($count < $smallest) ? $count : $smallest;
  };
  if ($gcd) {			                  # gcd flag is set so...
  GCD: foreach my $i (reverse (1 .. $smallest)) { # step backwards from
      my $not_ok = 0;		                  #   smallest stoi value
      foreach my $s (0 .. $#{$keys}) {            # a denom. has mod 0 for
	$not_ok ||= ($count[2*$s+1] % $i);        #   each value of stoi.
      };
      unless ($not_ok) {
	foreach my $s (0 .. $#{$keys}) {
	  $count[2*$s+1] /= $i;
	};
	last GCD;
      };
    };
  };
  return @count;		# return stoi hash
};


sub fix_ipots {
  my ($ipots, $r_cluster, $ipot_style) = @_;
  my @keys = sort {$$ipots{$a} <=> $$ipots{$b}} (keys %$ipots);
  my @found = ();
  my $index = -1;
  foreach my $k (@keys) {
    ++$index;
    $found[$index] = 0;
    ## search through the cluster of atoms looking for at least one
    ## example of each unique potential.
  ATOMS: foreach my $atom (@$r_cluster) {
      my ($el, $tag, $id) = ($ {$$atom[3]} -> attributes("Element"),
			     $ {$$atom[3]} -> attributes("Tag"),
			     $ {$$atom[3]} -> attributes("Id"));
      #print join("~", $el, $tag, $id), $/;
      if ($ipot_style eq "species") {
	++$found[$index], last ATOMS if (lc($k) eq lc($el));
      } elsif ($ipot_style eq "tags") {
	++$found[$index], last ATOMS if (lc($k) eq lc($tag));
      } elsif ($ipot_style eq "sites") {
	++$found[$index], last ATOMS if (lc($k) eq lc($id));
      };
    };
  };
  ## weed out each ipot that is not represented in the cluster
  foreach my $i (reverse(0..$#found)) {
    splice(@keys, $i, 1) unless $found[$i];
  };
  ## renumber the ipots with the missing one weeded out
  my %fixed = ();
  foreach my $i (0..$#keys) {
    $fixed{$keys[$i]} = $i+1;
  };
  return \%fixed;
};


sub symmetry_table {
  my ($cell, $line, $r_contents, $is_gnxas) = @_;
  my ($group, $given, $setting) =
    $cell->attributes("Space_group", "Given_group", "Setting");
  #-------------------------- handle different settings as needed
  my $positions = "positions";
  my $do_ortho =
    ($cell -> crystal_class() eq "orthorhombic" ) &&
      ($setting);
  my $do_tetr  =
    ($cell -> crystal_class() eq "tetragonal" )   &&
      ($setting);
  ($cell -> crystal_class() eq "monoclinic") && do {
    $positions = $setting;
				# bravais vector for the //given// symbol
    ##@bravais =  Xray::Xtal::Cell::bravais($given, 0);
  };
  (($group =~ /^r/i) && ($setting eq "rhombohedral"))
    && ($positions = "rhombohedral");
  ($positions) || do {
    my $this = (caller(0))[3];
    die "Invalid positions specifier in " . $this . "(Bruce's error)";
    return;
  };
  my $list = $cell -> get_symmetry_table();
  my ($xx, $yy, $zz, $rx, $ry, $rz);
  my $inc = 1;
  foreach my $position (@{$list}) {
    my $thisline = $line;
    ($xx = $$position[0]) =~ s/\$//g;
    ($xx =~ /^-/) || ($xx = " ".$xx);
    ($yy = $$position[1]) =~ s/\$//g;
    ($yy =~ /^-/) || ($yy = " ".$yy);
    ($zz = $$position[2]) =~ s/\$//g;
    ($zz =~ /^-/) || ($zz = " ".$zz);
    ($rx, $ry, $rz) = (0, 0, 0);
    if ($is_gnxas) {		# could this be more annoying?
      my ($gx, $gy, $gz);
      $gx  = ($xx =~ /([- ]x)/ ) ? $1 : "  ";
      $gx .= ($xx =~ /([-+ ]y)/) ? $1 : "  ";
      $gx .= ($xx =~ /([-+ ]z)/) ? $1 : "  ";
      $gy  = ($yy =~ /([- ]x)/ ) ? $1 : "  ";
      $gy .= ($yy =~ /([-+ ]y)/) ? $1 : "  ";
      $gy .= ($yy =~ /([-+ ]z)/) ? $1 : "  ";
      $gz  = ($zz =~ /([- ]x)/ ) ? $1 : "  ";
      $gz .= ($zz =~ /([-+ ]y)/) ? $1 : "  ";
      $gz .= ($zz =~ /([-+ ]z)/) ? $1 : "  ";
      map { $_ =~ s/\+/ /g } ($gx, $gy, $gz);
      ($xx, $yy, $zz) = ($gx, $gy, $gz);
      $rx = ($xx =~ /x([-+]\d\/\d)/) ? eval($1) : 0;
      $ry = ($yy =~ /y([-+]\d\/\d)/) ? eval($1) : 0;
      $rz = ($zz =~ /z([-+]\d\/\d)/) ? eval($1) : 0;
    };
    my %matches = ("x"     => $xx,
		   "y"     => $yy,
		   "z"     => $zz,
		   "rx"    => $rx,
		   "ry"    => $ry,
		   "rz"    => $rz,
		   "inc"   => sprintf("%4d", $inc++));
    my $matchstring = join("|", keys %matches);
    $thisline =~ s/\<($matchstring)>/$matches{$1}/go;
    $$r_contents .=  $thisline;
  };
};

## this is a scheme for numbering shells and subshells to provide a
## visual cue for which atoms in a cluster are symmetry related about
## the central atom
sub fetch_indeces {
  my $r_cluster	= $_[0];
  my @list	= $ {$$r_cluster[0][3]} -> attributes("Tag");
  my %seen	= ();
  my %count	= ();
  my %shell	= ();
  my $this	= "";
  ## should this be user configurable?  atp configurable?
  my ($open, $close) = ("_", ""); # ("/", "/"); # ("<", ">"); ("_", "");
  foreach my $i (1..$#{$r_cluster}) {
    my ($x, $y, $z) =
      ($$r_cluster[$i][0], $$r_cluster[$i][1], $$r_cluster[$i][2]);
    my $r = ($x**2 + $y**2 + $z**2);
    #next if ($r < EPSILON);
    $r = sprintf("%8.4f", $r);
    my ($tag) = $ {$$r_cluster[$i][3]} -> attributes("Tag");
    $tag  =~ s/\s+$//;
    $this =  $tag.$r;
    exists($seen{$this}) or ++$count{$tag};
    ++$seen{$this};
    push @list, join("", $tag, $open, $count{$tag}, $close );
  };
  return @list;
};

## this provides a list of itags suitable for distinguishing sites in
## a P1 file
sub count_sites {
  my $r_cluster = $_[0];
  my @list;
  my %seen = ();
  foreach my $i (0..$#{$r_cluster}) {
    my ($tag) = $ {$$r_cluster[$i][3]} -> attributes("Tag");
    ++$seen{$tag};
    push @list, $tag."_".$seen{$tag};
  };
  return @list;
};

#### THIS IS BROKEN IN ALPHA21 (and earlier)
## this computes the one bounce flags needed for a feff6 geom.dat file
## this has to be a two pass filter
## this does not work in some situations ... for example perfect hcp.
sub one_bounce {
  my $r_cluster = $_[0];
  my @list = (1);
  my @descri = ("");
  my %seen = ();
  foreach my $i (1..$#{$r_cluster}) {
    my ($x, $y, $z) = map { int(1000*$_) }
      (abs($$r_cluster[$i][0]),
       abs($$r_cluster[$i][1]),
       abs($$r_cluster[$i][2]));
    ($x, $y, $z) = sort($x, $y, $z);
    my ($tag) = $ {$$r_cluster[$i][3]} -> attributes("Tag");
    push @descri, sprintf("%s%s%s%-10s", $x, $y, $z, $tag);
  };
  foreach my $i (1..$#{$r_cluster}) {
    unless ($seen{$descri[$i]}++) {
      my @count = grep /$descri[$i]/, @descri;
      push @list, $#count+1;
    } else {
      push @list, 0;
    };
  };
  return @list;
};

1;
__END__


=head1 MORE INFORMATION

There is more information available in the Atoms document.  There you
will find complete descriptions of atp files, calculations using the
Xray::Absorption package, keywords in atoms input files and lots of
other topics.


=head1 AUTHOR

  Bruce Ravel <ravel@phys.washington.edu>
  Atoms URL: http://feff.phys.washington.edu/~ravel/software/atoms/


=cut
