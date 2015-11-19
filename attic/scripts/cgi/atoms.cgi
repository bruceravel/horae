#!/usr/bin/perl
######################################################################
## CGI version of Atoms version 3.0.1
##                                copyright (c) 1998-2005 Bruce Ravel
##                                                     bravel@anl.gov
##                                  http://cars9.uchicago.edu/~ravel/
##
##	  The latest version of Atoms can always be found at
##               http://cars9.uchicago.edu/~ravel/software/
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
######################################################################
my $cvs_info = '$Id: atoms.cgi,v 1.5 2000/10/17 18:30:17 bruce Exp $ ';
## Time-stamp: <06/02/03 13:36:45 bruce>
######################################################################
## Install this some place your web server can find it and then you
## can serve up Atoms over the Web.  Be sure to configure the
## variables in and just after the BEGIN block.
######################################################################
## To Do:
##
##   -- called with file, then press clear button, file argument
##      remains in URL
##   -- under lynx, save as name includes query info
######################################################################
## Code:

## -------------------------------------------------------------------
## These lines need to be fixed by the web administrator installing
## WebAtoms.
BEGIN {
  my $extra_INC =		# Set this if you have Atoms installed
    "/home/bruce/perl";		# outside of Perl's normal search path
  ($extra_INC) and unshift @INC, $extra_INC;
}
my $atoms_help =		# the Web-space location of the help file
  "file://localhost/home/bruce/perl/atoms/cgi/WebAtoms_help.html";
my $ADB_search =		# URL of ADB search form
  "somewhere";
my $ADB_directory =		# the real-disk location of the ADB files
  "/www/apache/htdocs/cgi-data/atoms/ADB/";
## -------------------------------------------------------------------
## On millenia:
##
## BEGIN {
##   my $extra_INC = "";		# Set this if you have Atoms installed
##   ##  "/home/ravel/perl";		# outside of Perl's normal search path
##   ($extra_INC) and unshift @INC, $extra_INC;
## }
## my $atoms_help =
##   "http://cars9.uchicago.edu/cgi-data/atoms/WebAtoms_help.html";
## my $ADB_search =
##   "http://cars9.uchicago.edu/cgi-bin/atoms/Atoms-Search.cgi";
## my $ADB_directory =
##   "/www/htdocs/cgi-data/atoms/ADB/";

## note that this is the actual location of WebAtoms_help.html on
## millenia
##     /millenia/www/apache/htdocs/cgi-data/atoms
## apparently the URL above is mapped to that location.

## the actual location on millenia of the script itself is
##     /millenia/www/apache2/cgi-bin/atoms/

my $version = "1.8 (Atoms $Xray::Atoms::VERSION)"; # (split(' ', $cvs_info))[2] || "pre_release";
my $date    = "3 February, 2005"; # (split(' ', $cvs_info))[3] || "Oct 11 1999";

## =============================== load methods
require 5.004;
use strict;
use Carp;

use Xray::Xtal;
$Xray::Xtal::run_level = 2;
use Xray::Atoms qw(build_cluster rcfile_name number);
use Xray::ATP; # qw(parse_atp);
use Chemistry::Elements qw(get_Z);

use CGI;			# load CGI routines
use CGI::Carp 'fatalsToBrowser';
$CGI::POST_MAX=1024 * 1000;	# max 1M posts
my $q = new CGI;		# create new CGI object
my $inpfile = $q->param('file');
$q->delete('file');
($ADB_directory =~ /\/$/) or $ADB_directory .= '/';

my %values	       = ();	# values hash (a few need to be pre-set)
$values{edge}	       = ' ';
$values{central_index} = 1;
$values{nsites}	       = 10;
$values{rmax}	       = 10;
$values{atp}	       = ($Xray::Atoms::prefer_feff_eight) ? 'feff8' : 'feff';
$values{debug}         = $q->param('debug');
my ($atoms,$feff) = ($q->small('ATOMS'), $q->small('FEFF'));
my $bruce_home	  = "http://cars9.uchicago.edu/~ravel/";
my $atoms_url	  = $bruce_home . "software/";
my $atoms_home	  = $atoms_url;
my @edge_names	  = (" ", qw(K L1 L2 L3 M1 M2 M3 M4 M5));
my @elem_names = (" ","H","He","Li","Be","B","C","N","O","F","Ne",
		     "Na","Mg","Al","Si","P","S","Cl","Ar","K","Ca",
		     "Sc","Ti","V","Cr","Mn","Fe","Co","Ni","Cu","Zn",
		     "Ga","Ge","As","Se","Br","Kr","Rb","Sr","Y","Zr",
		     "Nb","Mo","Tc","Ru","Rh","Pd","Ag","Cd","In",
		     "Sn","Sb","Te","I","Xe","Cs","Ba","La","Ce","Pr",
		     "Nd","Pm","Sm","Eu","Gd","Tb","Dy","Ho","Er","Tm",
		     "Yb","Lu","Hf","Ta","W","Re","Os","Ir","Pt","Au",
		     "Hg","Tl","Pb","Bi","Po","At","Rn","Fr","Ra","Ac",
		     "Th","Pa","U","Np","Pu");
my $table_params  = {qw(border 0 cellspacing 0 cellpadding 2
			align CENTER bgcolor tan)};
my $table_row     = {qw(align CENTER valign CENTER)};
my @atp_files     = qw(feff feff8 atoms absorption xyz alchemy
		       unit p1 p1_cartesian symmetry gnxas_cry gnxas_sym); # geom);
my %atp = (             	# labels for atp file popup
           feff		=> 'feff6.inp',
           feff8	=> 'feff8.inp',
           atoms	=> 'atoms.inp',
	   absorption	=> 'absorption',
           xyz		=> 'xyz',
           alchemy	=> 'alchemy',
           unit		=> 'unit cell',
           p1		=> 'p1.inp',
           p1_cartesian	=> 'cartesian P1 file',
           symmetry	=> 'symmetry',
	   gnxas_cry	=> 'GNXAS cry',
	   gnxas_sym	=> 'GNXAS sym',
	   #geom	=> 'geom.dat',
	   );
my %output = (
	      feff	   => 'feff.inp',
	      feff8	   => 'feff.inp',
	      atoms	   => 'atoms.inp',
	      absorption   => 'absorption.dat',
	      xyz	   => 'xyz.lis',
	      alchemy	   => 'alchemy.lis',
	      unit	   => 'unit.dat',
	      p1	   => 'p1.inp',
	      p1_cartesian => 'cartesian.dat',
	      symmetry	   => 'symmetry.dat',
	      gnxas_cry	   => 'cluster',
	      gnxas_sym	   => 'cluster',
	      #geom	   => 'geom.dat',
	     );

## ----- Installation tool -------------------------------------------
## This next bit is only run by the web administrator at install time.
## It is accessed by running `atoms.cgi -install' at the command line
## in the installation directory.  Normally, this block is ignored by
## the script.
if ($ARGV[0] =~ /-{1,2}install/i) {
  my $pwd = `pwd`;
  print <<EOH

Installation tool for atoms.cgi version $version
  Installing $0 in $pwd
  Creating or varifying hard links:
EOH
  ;
  foreach my $k (keys %output) {
    print "    $output{$k}$/";
    (-f $output{$k}) and unlink $output{$k};
    link($0, $output{$k});
  };
  print <<EOH

  Please edit the variables in and just after the BEGIN block of
  '$0' to complete the installation on your server.
  These variables are:

    \$extra_INC         The installation location of the Atoms package
                         if you have installed it outside of the normal
                         perl search path
    \$atoms_help        The Web-space location of the help file
    \$ADB_search        The URL of the Atoms Database search form
    \$ADB_directory     The real-disk location of the Atoms Database files

EOH
  ;
  exit;
};
## ----- end of installation tool -------------------------------------

my $red_message   = "";		# warnings and errors
my $run_atoms     = 1;		# flag for atoms or feff display
my @sites         = ();		# list of sites
my @cluster       = ();		# spherical cluster
my @neutral       = ();		# charge neutral rhomboidal cluster


## =============================== define a cell and a keyword hash
my $cell = Xray::Xtal::Cell -> new();
my $keywords = Xray::Atoms -> new();
$keywords -> make('identity' => "WebAtoms $version", die=>2,
		  'quiet' => 1, 'www_warn' => "");
($inpfile) and import_data($ADB_directory.$inpfile, $keywords, \%values);

($q->param) or $run_atoms = 0;	# this is the first call!
($q->param('redisplay'))  and $run_atoms = 0;

if ($q->param('text_entry')) {
#  $run_atoms = 0;
  $q->param(text_entry=>0);
};
if ($q->param('list_entry')) {
#  $run_atoms = 0;
  $q->param(list_entry=>0);
};
if ($q->param('Clear')) {
  $inpfile = "";
  $run_atoms = 0;
  $q->delete_all;
  (my $uu = $q->url()) =~ s/\?.*$//;
  $q->redirect($uu);
};
((not $q->param('text_entry')) and (not $q->param('list_entry')))
  and $q->param(list_entry=>1);
#$red_message .= "text = " . $q->param('text_entry') . $/;
#$red_message .= "list = " . $q->param('list_entry') . $/;


## cell parameters
foreach my $key (qw(space_group a b c alpha beta gamma)) {
  last unless $run_atoms;
  my $val =  $q->param($key);
  if (($key eq 'space_group') and ($val =~ /^\s*$/)) {
    $red_message .= "$/You have not specified a space group.$/";
    $run_atoms = 0;
    last;
  };
  next unless ($val);
  if ( ($val) or ($val =~ /^\s*$/) ) {
    $cell -> make($key => $val);
    ## what about non-standard settings...?
    ($values{$key}) = $cell->attributes($key);
    if ($Xray::Xtal::xtal_fatals) {
      $red_message .= $Xray::Xtal::xtal_fatals;
      $run_atoms = 0;
    };
  };
};


## operational keywords
foreach my $key (qw(rmax edge titles)) {
  last unless $run_atoms;
  if (($q->param($key)) and ($q->param($key) !~ /^\s*$/)) {
    if ($key eq 'titles') {
      my $eol = $/ . "+";	# split title text into lines
      my @t = split /$eol/, $q->param('titles');
      $keywords->{'title'} = [];
      map {$keywords->make('title'=>$_)} @t;
    } else {
      $keywords -> make($key => $q->param($key));
    };
  };
};
## fill up the sites array
my $i = 0;
my %map = ();
($q->param('nsites')) and $values{nsites} = $q->param('nsites');
foreach my $s (1 .. ($values{nsites})) {
  last unless $run_atoms;
  my ($e, $x, $y, $z, $t) = ($q->param('elem'.$s),
			     $q->param('x'.$s),
			     $q->param('y'.$s),
			     $q->param('z'.$s),
			     $q->param('tag'.$s));
  next if ($e =~ /^\s*$/);
  unless (($e) and (get_Z($e))) {
    $e =~ s/\s+$//;
    $red_message .= "\"$e\" is not a valid element.$/";
    $run_atoms = 0;
    next;
  };
  $map{$s} = $i;
  $sites[$i] = Xray::Xtal::Site -> new($i);
  $x = number($x, 2, $keywords) + number($q->param("shiftx"), 2, $keywords);
  $y = number($y, 2, $keywords) + number($q->param("shifty"), 2, $keywords);
  $z = number($z, 2, $keywords) + number($q->param("shiftz"), 2, $keywords);
  $sites[$i] -> make(Element=>$e, X=>$x, Y=>$y, Z=>$z, Tag=>$t);
  ($t) = $sites[$i] -> attributes('Tag');
  ## parse_atp in Atoms.pm uses the $keywords->{'sites'} to generate
  ## the <list :style atoms>, so I must load that up as well ...
  $keywords -> make('sites'=> $e, $x, $y, $z, $t, 1);
  ++$i;
};
if ($run_atoms and not $i) {
  $run_atoms = 0;
  $red_message .= "$/You have not defined any sites.$/";
};


if ($run_atoms) {
  if ($q->param('central_index')) {
    $values{central_index} = $q->param('central_index');
    $values{core_tag} = $map{$values{central_index}};
    if ($sites[$values{core_tag}]) {
      $values{core_tag} = $sites[$values{core_tag}] -> {Tag};
      $keywords -> make('core'=>$values{core_tag});
    } else {
      $red_message .=
	"$/You have selected an undefined site as the central atom.$/";
      $run_atoms = 0;
    };
  };

  if ($run_atoms and $cell -> {Space_group}) {
    $cell -> verify_cell();
    ($Xray::Xtal::xtal_fatals) or $cell -> populate(\@sites);
    $keywords -> verify_keywords($cell, \@sites, 2);
    $red_message .= $Xray::Xtal::xtal_warnings;
    if ($Xray::Xtal::xtal_fatals) {
      $red_message .= $Xray::Xtal::xtal_fatals;
      $run_atoms = 0;
    }
    $red_message .= $keywords -> {www_warn};
  };

  $red_message .= $cell -> warn_shift();
  $red_message .= $cell -> cell_check();
};

## foreach my $key (qw(space_group a b c alpha beta gamma)) {
##   $red_message .= $key . "  " . $cell->{ucfirst($key)} . "\n";
## }
##     $run_atoms = 0;

## generate the appropriate page
if ($q->param('actual')) {
  my $atp = $q->param('atp') || 'feff';
  print $q->header('text/plain');
  my $result = messages($q, \%values, 1);
##     foreach my $key (qw(space_group a b c alpha beta gamma)) {
##       print  join(" ", $key, $cell->{ucfirst($key)}, "|", $q->param($key), "\n");
##     }
  run_atoms($q, $atp, $cell, $keywords, \@cluster, \@neutral, \$result);
  print $result;
} elsif ($run_atoms) {
  my $atp = $q->param('atp') || 'feff';
  $q->param(-name=>'actual', -value=>1, text_entry=>0, list_entry=>0);
  my $this = $q->url();
  (my $redir = $q->url(-query=>1)) =~ s/atoms.cgi/$output{$atp}/;
  print $q -> redirect($redir);
} else {
  top($q, \%values);
  messages($q, \%values, 0);
  atoms_keywords($q, \%values);
  site_table($q, \%values);
  bottom($q, \%values);
};


## ----------------------------------------------------------------------
## This is the end!


#########################################################################
## subroutines

## gather and print the output file
sub run_atoms {
  my ($q, $atp, $cell, $keywords, $r_cluster, $r_neutral, $r_result) = @_;
## foreach my $key (qw(space_group a b c alpha beta gamma)) {
##   print  $key . "  " . $$r_cell->{ucfirst($key)} . "\n";
## }
##   exit;
  build_cluster($cell, $keywords, $r_cluster, $r_neutral);
  my $contents = "";
  $q->autoEscape(1);
  my ($default_name, $is_feff) =
    &parse_atp($atp, $cell, $keywords, $r_cluster, $r_neutral, \$contents);
  #my %subs = {'<'=>'&lt;', '>'=>'&gt;'};
  #my $sub_keys = join('', keys(%subs));
  #$contents =~ s/([$sub_keys])/$subs{$1}/eg;
  $$r_result .= $contents;
};

##  Header materials for atoms data entry page
sub top {
  my $q = $_[0];
  my $r_values = $_[1];
  print
    $q->header,			# create the HTTP header
    $q->start_html(-title=>'ATOMS',
		   -bgcolor=>'white',
		   -meta=>{'copyright'=>'copyright 1999-2005 Bruce Ravel'}
		  ),
    $q->h1({align=>'CENTER'}, 'ATOMS on the Web');

  my $paragraph = "$atoms is a program for generating lists of
atomic coordinates from crystallographic data.  The primary use of
$atoms is to create input files suitable for running the " .
  $q->i("ab initio") .
    " XAFS program $feff, however several other interesting output formats
are available.";
  print $q->p($paragraph);
  $paragraph = "This web page demonstrates the main features of $atoms.
It consists of a rather large form which you may fill in with
data describing your crystal. ";
  ($ADB_search) and
    $paragraph .=
      $q->a({href=>$ADB_search},
	    "You may also search a database of input data for $atoms.");
$paragraph .= "  After clicking the \"Run Atoms\"
button, your browser will display an input file suitable for running
$feff (or perhaps some other kind of interesting output file).  You
can get help about any of the parameters by following the link
bound to the parameter name.";
  print $q->p($paragraph);
  $paragraph = "This web page does not offer " .
    $q->a({href=>"$atoms_help#features"}, 'all the features') .
      " available in the version of $atoms which you can run on your
own computer.  Please see the ";
  $paragraph .= $q->a({href=>$atoms_home}, "$atoms homepage");
  $paragraph .= " for complete details.";
  print $q->p($paragraph), $q->hr();
};

## print out error and warning messages
sub messages {
  my $q = $_[0];
  my $r_values = $_[1];
  my $output = $_[2];
  return unless (($red_message) or ($q->param('debug')) );
  if ($q->param('debug')) {
    #foreach my $key ($q->param) {
    #  my $start = ($output) ? " * $key -> " : $q->b("$key -> ") ;
    #  print $start;
    #  my @values = $q->param($key);
    #  print join(", ",@values);
    #  my $end = ($output) ? $/ : $q->br();
    #  print $end;
    #}
    require Data::Dumper;
    $red_message .= $/;
    $red_message .= Data::Dumper ->
      Dump([$cell, $keywords, $values{core_tag}, $run_atoms],
	   [qw(*cell *keywords core_tag, run_atoms)]);
  };
  if ($output) {
    $red_message =~ s|$/|$/ * |g;
    my $ret_str =  " * ", '-' x 70, $/, ' * ';
    $ret_str .= $red_message;
    $ret_str .= $/, " * ", '-' x 70, $/;
    return $ret_str;
  } else {
    print $q->font({color=>'red'}, $q->pre($red_message));
    print $q->hr();
  };
};

## Big table of Atoms keywords, including operational and unit cell parameters
sub atoms_keywords {
  my $q = $_[0];
  my $r_values = $_[1];
  ## Operational parameters and space group
  print
    $q->startform(),
    #$q->hidden('debug', $values{debug});
    $q->table($table_params,
	      $q->Tr($table_row,
		      $q->td({-colspan=>6},
			     $q->submit(-name=>'Run ATOMS',
					-value=>'Run ATOMS'),
			     $q->submit(-name=>'Clear',
					-value=>'Clear'),
			     $q->reset )),
	      $q->Tr($table_row,
		     $q->td($q->a({href=>"$atoms_help#title"},
				  $q->b('Titles'))),
		     $q->td({-colspan=>5},
			     $q->textarea(-name=>'titles',
					  -default=>$$r_values{titles},
					  -rows=>6, -columns=>50))),
	      $q->Tr($table_row,
		     [
		      $q->td({-colspan=>6}, $q->b('Operational Parameters')),
		      $q->td([$q->a({href=>"$atoms_help#space_group"},
				    $q->b('Space', $q->br(), 'Group: ')),
			      $q->textfield(-name=>'space_group',
					    -default=>$$r_values{space_group},
					    -size=>10,  -maxlength=>20),
			      $q->a({href=>"$atoms_help#rmax"},
				    $q->b('Rmax: ')),
			      $q->textfield(-name=>'rmax',
					    -default=>$$r_values{rmax},
					    -size=>10,  -maxlength=>20),
			      $q->a({href=>"$atoms_help#edge"},
				    $q->b('Edge: ')),
			      $q->popup_menu(-name=>'edge',
					     -values=>[@edge_names],
					     -default=>$$r_values{edge},)
			     ]),
		      ]),
	      $q->Tr($table_row,
		     $q->td($q->a({href=>"$atoms_help#output"},
				  $q->b('Output', $q->br(), 'Type: '))),
		     $q->td($q->popup_menu(-name=>'atp',
					   -values=>[@atp_files],
					   -default=>$$r_values{atp},
					   -labels=>\%atp)),
		     $q->td($q->a({href=>"$atoms_help#shift"},
				  $q->b('Shift: '))),
		     $q->td($q->textfield(-name=>'shiftx',
				   -default=>$$r_values{'shiftx'},
				   -size=>10,  -maxlength=>20)),
		     $q->td($q->textfield(-name=>'shifty',
				   -default=>$$r_values{'shifty'},
				   -size=>10,  -maxlength=>20)),
		     $q->td($q->textfield(-name=>'shiftz',
				   -default=>$$r_values{'shiftz'},
				   -size=>10,  -maxlength=>20)),
		     ),
	      $q->Tr($table_row,
		     [
		      $q->td({-colspan=>6,},
			     $q->b('Lattice Constants and Angles')),
		      $q->td([$q->a({href=>"$atoms_help#abc"},
				    $q->b('A: ')),
			      $q->textfield(-name=>'a',
					    -default=>$$r_values{'a'},
					    -size=>10,  -maxlength=>20),
			      $q->a({href=>"$atoms_help#abc"},
				    $q->b('B: ')),
			      $q->textfield(-name=>'b',
					    -default=>$$r_values{'b'},
					    -size=>10,  -maxlength=>20),
			      $q->a({href=>"$atoms_help#abc"},
				    $q->b('C: ')),
			      $q->textfield(-name=>'c',
					    -default=>$$r_values{'c'},
					    -size=>10,  -maxlength=>20)]),
		      $q->td([$q->a({href=>"$atoms_help#alpha"},
				    $q->b('Alpha: ')),
			      $q->textfield(-name=>'alpha',
					    -default=>$$r_values{'alpha'},
					    -size=>10,  -maxlength=>20),
			      $q->a({href=>"$atoms_help#beta"},
				    $q->b('Beta: ')),
			      $q->textfield(-name=>'beta',
					    -default=>$$r_values{'beta'},
					    -size=>10,  -maxlength=>20),
			      $q->a({href=>"$atoms_help#gamma"},
				    $q->b('Gamma: ')),
			      $q->textfield(-name=>'gamma',
					    -default=>$$r_values{'gamma'},
					    -size=>10,  -maxlength=>20)]),
		      $q->td({-colspan=>6},
			     $q->submit(-name=>'Run ATOMS',
					-value=>'Run ATOMS'),
			     $q->submit(-name=>'Clear',
					-value=>'Clear'),
			     $q->reset ),
		     ]));
  print $q -> p();
};

## Big table of site parameters
sub site_table {
  my $q = $_[0];
  my $r_values = $_[1];
  my @sites = &make_n_sites($r_values);
  print $q->table($table_params,
		  $q->Tr($table_row,
			 [
			  $q->td({-colspan=>6},
				 $q->b('Table of Crystallographic Sites')),
			  $q->th([$q->a({href=>"$atoms_help#central"}, 'Cent.'),
				  $q->a({href=>"$atoms_help#element"}, 'Element'),
				  $q->a({href=>"$atoms_help#xyz"},     'X'),
				  $q->a({href=>"$atoms_help#xyz"},     'Y'),
				  $q->a({href=>"$atoms_help#xyz"},     'Z'),
				  $q->a({href=>"$atoms_help#tag"},     'Tag')]),
			  @sites,
			  $q->td({-colspan=>6},
				 $q->submit(-name=>'Run ATOMS',
					    -value=>'Run ATOMS'),
				 $q->submit(-name=>'Clear',
					    -value=>'Clear'),
				 $q->reset ),
			  $q->td({-colspan=>6},
				 $q->b('Redisplay with this many sites:'),
				 $q->textfield(-name=>'nsites',
					       -default=>$$r_values{'nsites'},
					       -size=>3,  -maxlength=>20),
				 $q->submit(-value=> 'Do it!',
					    -name=>'redisplay'),
				 $q->a({href=>"$atoms_help#overview"},
				       $q->b('Explain')) ),
			  ##($q->param('list_entry')) ?
			  ##$q->td({-colspan=>6},
				## $q->b('Press here to redisplay with ' .
				##       'text entry of element symbols:'),
				## $q->submit(-name=>'text_entry',
				##	    -value=>'Do it!'),
				## $q->a({href=>"$atoms_help#overview"},
				##       $q->b('Explain')) ) :
			  ##$q->td({-colspan=>6},
				## $q->b('Press here to redisplay with ' .
				##       'list entry of element symbols:'),
				## $q->submit(-name=>'list_entry',
				##	    -value=>'Do it!'),
				## $q->a({href=>"$atoms_help#overview"},
				##       $q->b('Explain')) ),
			 ]));
  print $q->endform;
};


## trailing materials for atoms data input page
sub bottom {
  my $q = $_[0];
  my $r_values = $_[1];
  print
    $q->hr(),
    "Web$atoms version $version ($date)", $q->br(),
    "$atoms is copyright &copy; 1998-2005 Bruce Ravel", $q->br(),
    $q->a({href=>$atoms_home}, "$atoms homepage"), $q->br(),
    $q->a({href=>$bruce_home}, "Bruce's homepage");

  print $q->end_html, $/; # end the HTML
};


## generate a list of table rows for the sites
sub make_n_sites {
  my $r_values = $_[0];
  my $ns = $$r_values{nsites};
  my $total = $ns + 1;
  my @table = ();
  my %labels = ();
  map {$labels{$_} = '  '.$_} (0..$ns);
  my @radio = $q->radio_group(-name=>'central_index', -values=>[(1..$ns)],
			      -default=>$$r_values{central_index},
			      -labels=>\%labels);
  while ($ns) {
    my $this = $total - $ns--;
    my $elem = ($q->param('text_entry')) ?
      $q->textfield(-name=>'elem'.$this,
		    -default=>$$r_values{'elem'.$this},
		    -size=>3,  -maxlength=>20) :
        $q->popup_menu(-name=>'elem'.$this,
		       -values=>[@elem_names],
		       -default=>$$r_values{'elem'.$this},);

    my @site = (
		$radio[$this-1],
		$elem,
		$q->textfield(-name=>'x'.$this,
			      -default=>$$r_values{'x'.$this},
			      -size=>8,  -maxlength=>20),
		$q->textfield(-name=>'y'.$this,
			      -default=>$$r_values{'y'.$this},
			      -size=>8,  -maxlength=>20),
		$q->textfield(-name=>'z'.$this,
			      -default=>$$r_values{'z'.$this},
			      -size=>8,  -maxlength=>20),
		$q->textfield(-name=>'tag'.$this,
			      -default=>$$r_values{'tag'.$this},
			      -size=>10,  -maxlength=>20)
	       );
    push @table, $q->td([@site]);
  };
  return @table;
};


sub import_data {
  my ($fname, $keys, $r_values) = @_;
  unless (-e $fname) {
    $red_message .= $q->pre("Error reading $fname.\n$!");
    return;
  };
  $keys -> parse_input($fname, 2);
  foreach my $v (qw(a b c alpha beta gamma rmax)) {
    ($keys->{$v}) and $$r_values{$v} = $keys->{$v};
  };
  ($keys->{space}) and $$r_values{space_group} = $keys->{space};
  ($keys->{title}) and $$r_values{titles} = join($/,@{$keys->{title}});
  if ($keys->{shift}) {
    $$r_values{shiftx} = $ {$keys->{shift}}[0];
    $$r_values{shifty} = $ {$keys->{shift}}[1];
    $$r_values{shiftz} = $ {$keys->{shift}}[2];
  };
  if ($keys->{sites}) {
    my $i = 0;
    foreach my $s (@{$keys->{sites}}) {
      ++$i;
      $$r_values{"elem".$i} = $$s[0];
      $$r_values{"x".$i}    = $$s[1];
      $$r_values{"y".$i}    = $$s[2];
      $$r_values{"z".$i}    = $$s[3];
      $$r_values{"tag".$i}  = $$s[4];
      (lc($$s[4]) eq lc($keys->{core})) and $$r_values{central_index} = $i;
    };
    $$r_values{nsites} = $i;
  };
  undef($keys->{core});
};

## Local Variables:
## time-stamp-line-limit: 25
## End:
