#!/usr/bin/perl -w

use strict;
use Text::Wrap;
use File::Copy;
#use Data::Dumper;
my %hash = ();
my $libdir      = "lib/Ifeffit/lib/athena/";
my $config_file = $libdir."athena.config";
my $rc_file     = $libdir."athenarc";
my $rcw_file    = $libdir."athenarcw";
my $ini_file    = $libdir."athena.ini";
my $pl_file     = "athena_parts/rc.pl";

print "Reading configuration file: $config_file\n";
my $ret = &read_config(\%hash, $config_file);
die "config file could not be found\n" if ($ret == -1);

#print Data::Dumper->Dump([\%hash], [qw(hash)]);


open R, ">$rc_file"  or die "could not open $rc_file file for writing\n";
open I, ">$ini_file" or die "could not open $ini_file file for writing\n";
open P, ">$pl_file"  or die "could not open $pl_file file for writing\n";

## write the line identifying the file
print R <<EOH
##
## This is the runtime configuration file for Athena on Unix.
##
EOH
  ;
print I <<EOH
##
## This is the initialization file for Athena on Windows.
##
EOH
  ;

print P <<EOH
## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2005 Bruce Ravel
##
##  This section of the code initializes all configuration values.
##  This file was generated from the athena.config file.


sub default_rc {
EOH
  ;

## write the header
foreach (<DATA>) {
  print R;
  print I;
};

print R "\n\n";
print I "\n\n";


## step through all the values
foreach my $s (@{$hash{order}}) {
  print R wrap("# ", "# ", $hash{$s}{description});
  print R "\n[$s]\n";
  print I wrap("# ", "# ", $hash{$s}{description});
  print I "\n[$s]\n";
  foreach my $v (@{$hash{$s}{order}}) {
    my $val = $hash{$s}{$v}{default};
    my $win = (exists $hash{$s}{$v}{windows}) ? $hash{$s}{$v}{windows} : $val;
    ($val = "") if ($val eq '""');
    ($win = "") if ($win eq '""');
    if ($hash{$s}{$v}{type} eq 'boolean') {
      $val = ($val eq 'true') ? $hash{$s}{$v}{onvalue} : ($hash{$s}{$v}{offvalue}||0);
      $win = ($win eq 'true') ? $hash{$s}{$v}{onvalue} : ($hash{$s}{$v}{offvalue}||0);
    };
    print R "  $v = $val\n";
    print I "  $v = $win\n";
    unless ($hash{$s}{$v}{type} =~ /(boolean|positive integer|real|regex)/) {
      $val = '"'.$val.'"';
      $win = '"'.$win.'"';
    };
    if ($hash{$s}{$v}{type} =~ 'regex') {
      $val = "'".$val."'";
      $win = "'".$win."'";
    };
    if ($hash{$s}{$v}{type} =~ 'boolean') {
      ($val = '"'.$val.'"') unless ($val =~ /[01]/);
      ($win = '"'.$win.'"') unless ($win =~ /[01]/);
    };
    if (exists $hash{$s}{$v}{windows}) {
      print P "  \$_[0]{$s}{$v} = (\$is_windows) ? $win : $val;\n";
    } else {
      print P "  \$_[0]{$s}{$v} = $val;\n";
    };
  };
  print R "\n\n";
  print I "\n\n";
  print P "\n\n";
};

print P <<EOH
  return 1;
};


## END OF RC FILE SUBSECTION
##########################################################################################
EOH
;

## close 'em and finish up
close R;
close I;
close P;
copy($ini_file, $rcw_file);
print "Wrote $rc_file\n      $rcw_file\n      $ini_file\n      $pl_file\n";

sub read_config {
  my $rhash = $_[0];
  ## my $config_file = ($is_windows) ? "$ENV{IFEFFIT_DIR}\\athena.config" :
  ##   File::Spec->catfile($Ifeffit::Group::libdir, "athena.config");
  my $config_file = $_[1];
  return -1 unless (-e $config_file);

  $$rhash{order} = [];
  my ($current_section, $current_variable) = ("", "");
  open C, $config_file or die "could not open $config_file for reading\n";
  while (<C>) {
    next if (/^\s*$/);		# blank line
    next if (/^\s*\#/);		# comment line
    chomp;
  SWITCH: {
      ## recognize a new section of variables
      (/^section=/) and do {
	my @line = split(/=/, $_);
	push @{$$rhash{order}}, $line[1];
	$$rhash{$line[1]} = {};
	$current_section = $line[1];
	last SWITCH;
      };
      ## read the description of the current section of variables
      (/^section_description/) and do {
	$$rhash{$current_section}{description} = "";
	my $next = <C>;
	while ($next !~ /^\s*$/) {
	  chomp $next;
	  $$rhash{$current_section}{description} .= substr($next, 1);
	  $next = <C>;
	};
	$$rhash{$current_section}{description} =
	  substr($$rhash{$current_section}{description}, 1);
	last SWITCH;
      };
      ## recognize a new variable
      (/^variable=/) and do {
	my @line = split(/=/, $_);
	push @{$$rhash{$current_section}{order}}, $line[1];
	$$rhash{$current_section}{$line[1]} = {};
	$current_variable = $line[1];
	last SWITCH;
      };
      ## read the description of the current variable
      (/^description/) and do {
	$$rhash{$current_section}{$current_variable}{description} = "";
	my $next = <C>;
	while ($next !~ /^\s*$/) {
	  chomp $next;
	  $next =~ s/^ *\./\n\n   /;
	  $$rhash{$current_section}{$current_variable}{description} .= substr($next, 1);
	  $next = <C>;
	};
	$$rhash{$current_section}{$current_variable}{description} =
	  substr($$rhash{$current_section}{$current_variable}{description}, 1);
	last SWITCH;
      };
      ## the type (i.e. string, boolean, etc) of the current variable
      (/^type=/) and do {
	my @line = split(/=/, $_);
	$$rhash{$current_section}{$current_variable}{type} = $line[1];
	last SWITCH;
      };
      ## default value
      (/^default=/) and do {
	my @line = split(/=/, $_);
	$$rhash{$current_section}{$current_variable}{default} = $line[1];
	last SWITCH;
      };
      ## list values
      (/^values=/) and do {
	my @line = split(/=/, $_);
	$$rhash{$current_section}{$current_variable}{values} = $line[1];
	last SWITCH;
      };
      ## special treatment for windows
      (/^windows=/) and do {
	my @line = split(/=/, $_);
	$$rhash{$current_section}{$current_variable}{windows} = $line[1];
	last SWITCH;
      };
      ## max value for a positive integer
      (/^maxint=/) and do {
	my @line = split(/=/, $_);
	$$rhash{$current_section}{$current_variable}{maxint} = $line[1];
	last SWITCH;
      };
      ## boolean for whether a font may be variable width
      (/^variable_width=/) and do {
	my @line = split(/=/, $_);
	$$rhash{$current_section}{$current_variable}{variable_width} = $line[1];
	last SWITCH;
      };
      ## value for boolean true
      (/^onvalue=/) and do {
	my @line = split(/=/, $_);
	$$rhash{$current_section}{$current_variable}{onvalue} = $line[1];
	last SWITCH;
      };
      ## value for boolean true
      (/^offvalue=/) and do {
	my @line = split(/=/, $_);
	$$rhash{$current_section}{$current_variable}{offvalue} = $line[1];
	last SWITCH;
      };
    };
  };

  close C;

};


__DATA__
###########################################################################
##                      Athena is copyright (c) 2001-2005 Bruce Ravel
##                                                     bravel@anl.gov
##                            http://feff.phys.washington.edu/~ravel/
##
##                   Ifeffit is copyright (c) 1992-2005 Matt Newville
##                                         newville@cars.uchicago.edu
##                       http://cars9.uchicago.edu/~newville/ifeffit/
##
##	  The latest version of Athena can always be found at
##          http://feff.phys.washington.edu/~ravel/software/
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
###########################################################################

### ***************************************************
###  This file is not normally edited by hand.
###  Use Athena's preferences dialog instead.
### ***************************************************

### ***************************************************
###  BE VERY CAREFUL TO AVOID END OF LINE WHITESPACE
### ***************************************************
