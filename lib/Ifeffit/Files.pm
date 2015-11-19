package Ifeffit::Files;		# -*- cperl -*-
######################################################################
## Ifeffit::Files: Object oriented tools for performing file checks
##
##                      Athena is copyright (c) 2001-2006 Bruce Ravel
##                                                     bravel@anl.gov
##                            http://feff.phys.washington.edu/~ravel/
##
##                   Ifeffit is copyright (c) 1992-2006 Matt Newville
##                                         newville@cars.uchicago.edu
##                       http://cars9.uchicago.edu/~newville/ifeffit/
##
##	  The latest version of Athena can always be found at
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

##  This file contains all the various checks of imported data files
##  that Athena and Artemis need to do in order to properly read data
##  from a wide variety of sources.  These things are segregated to
##  the file for organizational purposes.


use strict;
use vars qw($VERSION $cvs_info $module_version @ISA @EXPORT @EXPORT_OK @buffer);
use constant EPSI => 0.00001;
use File::Basename;
use File::Copy;
use Ifeffit;
use Xray::Xtal;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Compress::Zlib;

require Exporter;

@ISA = qw(Exporter AutoLoader Ifeffit);
@EXPORT_OK = qw();


use vars qw($elem_regex);
$elem_regex = '([bcfhiknopsuvwy]|a[cglmrstu]|b[aehikr]|c[adeflmorsu]|dy|e[rsu]|f[emr]|g[ade]|h[aefgos]|i[nr]|kr|l[airu]|m[dgnot]|n[abdeiop]|os|p[abdmortu]|r[abefhnu]|s[bcegimnr]|t[abcehilm]|xe|yb|z[nr])';
my $num_regex  = '-?(\d+\.?\d*|\.\d+)';


## this should be called immediately after a disposal of
## "read_data". It checks the $column_label ifeffit global variable,
## which ifeffit sets to "--undefined--" when it is thinks that it was
## given a file that was not actually data.
sub is_datafile {
  shift;
  my $col_string = Ifeffit::get_string('$column_label');
  return (not ($col_string =~ /^(--undefined--|\s*)$/));
};



## =================================================================
## Recognize a record file
## check the first line of a file to verify that it is a record
sub is_record {
  shift;
  my $file = $_[0];
  my $verbose = $_[1];
  my $gz = gzopen($file, "rb") or die "could not open $file as a record\n";
  my $first;
  $gz->gzreadline($first);
  $gz->gzclose();
  my $is_proj = ($first =~ /Athena (record|project) file/) ? $1 : 0;
  if ($verbose) {
    my $passfail = ($is_proj) ? 'athena    ' : 'not athena';
    printf "%s\n\t%s  is_project=%s\n", $a, $passfail, $is_proj;
  };
  return $is_proj;
};
sub is_athena { is_record(@_) };

## an artemis project file is a valid zip file with a file called
## HORAE in it.
sub is_artemis {
  shift;
  my $file = $_[0];
  my $verbose = $_[1];
  Archive::Zip::setErrorHandler( \&is_zip_error_handler );
  my $zip = Archive::Zip->new();
  my $is_zipstyle = ($zip->read($file) == AZ_OK);
  my $horae = ($is_zipstyle) ? $zip->membersMatching( '^HORAE$' ) : 0;
  undef $zip;
  Archive::Zip::setErrorHandler( undef );
  if ($verbose) {
    my $passfail = ($is_zipstyle and $horae) ? 'artemis    ': 'not artemis';
    printf "\t%s is_zipfile=%s  horae=%s\n", $passfail, $is_zipstyle, $horae;
  };
  return ($is_zipstyle, $horae);
};
sub is_zip_error_handler { 1; };

## an atoms.inp file is identified by having a valid space group
## symbol and by having an atoms list with at least one valid line of
## atoms
sub is_atoms {
  shift;
  my $a = $_[0];
  my $verbose = $_[1];
  open A, $a or die "could not open $a: $!";
  my ($space_test, $atoms_test, $toss) = (0,0,0);
  my $switch = 0;
 A: while (<A>) {
    next if /^\s*$/;		# skip blanks
    next if /^\s*[!\#%*]/;	# skip comment lines
    $switch = 1, next if  (/^\s*ato/);
    if ($switch) {
      my @line = split(" ", $_);
      ($atoms_test=1), last A if ( (lc($line[0]) =~ /^$elem_regex$/) and
				   ($line[1] =~ /^$num_regex$/)  and
				   ($line[2] =~ /^$num_regex$/)  and
				   ($line[3] =~ /^$num_regex$/));
    } else {

      my @line = split(" ", $_);
    LINE: foreach my $word (@line) {
	last LINE if (lc($word) eq 'title');
	if (lc($word) =~ /space/) {
	  my $lline = lc($_);
	  my $space = substr($_, index($lline,"space")+6);
	  $space =~ s/^[\s=,]+//;
	  $space =  substr($space, 0, 10); # next 10 characters
	  $space =~ s/[!\#%*].*$//;   # trim off comments
	  ($space_test, $toss) = Xray::Xtal::Cell::canonicalize_symbol($space);
	};
      };
    };
  };
  close A;
  if ($verbose) {
    my $passfail = ($atoms_test && $space_test) ? 'atoms    ': 'not atoms';
    printf "\t%s   atoms_test=%d  space_test=%s\n", $passfail, $atoms_test, $space_test;
  };
  return ($space_test && $atoms_test) ? 1 : 0;
};

## an atoms.inp file is identified by having a valid space group
## symbol and by having an atoms list with at least one valid line of
## atoms
sub is_cif {
  shift;
  my $a = $_[0];
  return 1 if (basename($a) =~ /cif$/i);
  return 0;
};

## a feff.inp file is identified by having a potentials list and at
## least two valid potentials line, the absorber and one other.
sub is_feff {
  shift;
  my $a = $_[0];
  my $verbose = $_[1];
  open A, $a or die "could not open $a: $!";
  my $switch = 0;
  my ($abs_test, $scat_test) = (0,0);
 A: while (<A>) {
    chomp;
    next if /^\s*$/;		# skip blanks
    next if /^\s*[!\#%*]/;	  # skip comment lines
    $switch = 1, next if  (/^\s*pot/i);
    if ($switch) {
      last A if (/^\s*[a-zA-Z]/);
      my @line = split(" ", $_);
      ($abs_test=$_),  next A if (($line[0] =~ /^0$/) and
				  ($line[1] =~ /^\d+$/) and
				  (lc($line[2]) =~ /^$elem_regex$/));
      ($scat_test=$_), next A if (($line[0] =~ /^\d+$/) and
				  ($line[1] =~ /^\d+$/) and
				  (lc($line[2]) =~ /^$elem_regex$/));
    };
  }
  close A;
  if ($verbose) {
    my $passfail = ($abs_test && $scat_test) ? 'feff    ': 'not feff';
    printf "\t%s    abs_test =%s\n\t            scat_test=%s\n",
      $passfail, $abs_test, $scat_test;
  };
  return ($abs_test && $scat_test) ? 1 : 0;
};

## a data file is data if ifeffit recognizes it as such and returns a
## column_label string
sub is_data {
  shift;
  my $a = $_[0];
  my $verbose = $_[1];
  ifeffit("read_data(file=$a, group=a)\n");
  my $col_string = Ifeffit::get_string('$column_label');
  if ($verbose) {
    my $passfail = ($col_string =~ /^(\s*|--undefined--)$/) ?
      'not data' : 'data    ' ;
    printf "\t%s    col_string=%s\n", $passfail, $col_string;
  };
  return ($col_string =~ /^(\s*|--undefined--)$/) ? 1 : 0;
};


sub is_feffnnnn {
  return 1;
};

## this returns 0 is it is a two column file, -1 if it is tagged by
## athena as a multicolumn file, or the number of columns that ifeffit
## reports
sub is_multicolumn {
  shift;
  my $file = $_[0];
  open F, $file or die "could not open $file as a record\n";
  my $first = <F>;
  close F;
  ## look for the tag from Athena 0.8.025 and later
  return -1 if ($first =~ /Athena multicolumn data file/);
  return  0 if ($first =~ /Athena data file/);
  ## else rely on Ifeffit to recognize the situation
  ifeffit("read_data(file=\"$file\", group=t___oss)\n");
  my $ncol = Ifeffit::get_scalar('&n_arrays_read');
  ifeffit("erase \@group t___oss\n");
  return ($ncol==2) ? 0 : $ncol;
};


## =================================================================
## Recognize xanes data (i.e. data of limited energy extent)
sub is_xanes {
  shift;
  my ($data, $cutoff) = @_;
  ## open the data with ifeffit
  ifeffit("read_data(file=\"$data\", group=t___oss)\n");
  my $suff = (split(" ", Ifeffit::get_string('$column_label')))[0];
  ifeffit("em___in = floor(t___oss.$suff)\n");
  ifeffit("em___ax = ceil(t___oss.$suff)\n");
  my ($emin, $emax) = (Ifeffit::get_scalar('em___in'),
		       Ifeffit::get_scalar('em___ax'));
  ifeffit("erase \@group t___oss\n");
  my $span = ($emax-$emin);
  ($span *= 1000) if ($span < 2); # keV, presumably
  return 1 if ( $span < $cutoff );
  return 0;
};

## =================================================================
## Recognize feff's xmu.dat file

sub is_xmudat {
  shift;
  my ($file, $top) = @_;
  open F, $file or die "could not open $file as data (is_xmudat)\n";
  my $first = <F>;
  close F, return 0 unless ($first =~ /Feff/);
  my $mu = 0;
  while (<F>) {
    #(/Mu=([- ]?\d*\.\d+E\+\d+)/) and ($mu = sprintf("%.4f",$1));
    ($mu = (split(/[ =]+/, $_))[2]) if $_ =~ /Mu=/;
    last if not (/^\s*\#/);
  };
  my @line = split(" ", $_);
  close F;
  return 0 unless ($#line == 5); # xmu.dat is a 6-column file
  return $mu if $mu;
  my $dialog = $top->Dialog(-text => "$file appears to be an xmu.dat file from Feff.  Is that correct?",
			    -bitmap => 'question',
			    -title => 'Is this an xmu.dat file?',
			    -default_button=> 'Yes', -buttons => [qw/Yes No Cancel/]);
  my $answer = $dialog->Show();
  ## need to do the right thing for cancel
  return ($answer eq 'Yes') ? 0.01 : 0 ;
};



## =================================================================
## Recognize data that is a function of pixel position

sub is_pixel {
  shift;
  my $data = shift;
  open DATA, $data or die "could not open $data as data (is_pixel)\n";
  my $i = 0;
  my $first;
  my $is_pixel = 1;
  DATA: while (<DATA>) {
      chomp;
      next if (/^\s*$/);
      #next if (/^\s*[^0-9\-]/);
      my @line = split(" ", $_);
      foreach my $c (@line) {
	next DATA unless ($c =~ /-?(\d+\.?\d*|\.\d+)/);
      };
      my $pixel = $line[0];
      close DATA, return 0 unless ($pixel =~ /^\d+$/);
      ($first = $pixel) unless defined $first;
      $is_pixel &&= ($pixel == $i+$first);
      ##print join(" ", '$i $first $pixel $is_pixel',
      ##		 $i, $first, $pixel, $is_pixel), $/;
      ++$i;
      close DATA, return 0 unless $is_pixel;
      close DATA, return 1 if ($i == 100);
    };
  close DATA;
  return 1;
};


## =================================================================
## Recognize and handle files from NSLS beamline X10C

## sub is_x10c {
##   shift;
##   my $data = shift;
##   open D, $data or die "could not open $data as data (is_x10c)\n";
##   my $first = <D>;
##   close D, return 0 unless (uc($first) =~ /^EXAFS/);
##   my $lines = 0;
##   while (<D>) {
##     close D, return 1 if (uc($first) =~ /^\s+DATA START/);
##     ++$lines;
##     #close D, return 0 if ($lines > 40);
##   };
##   close D;
## };
##
##
## ## deal with files from X10C by streaming the file, fixing the
## ## problems, and putting the fixed up file in the stash directory.
## sub fix_x10c {
##   shift;
##   my ($data, $stash_dir) = @_;
##   my ($nme, $pth, $suffix) = fileparse($data);
##   my $new = File::Spec->catfile($stash_dir, $nme);
##   ($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);
##   open D, $data or die "could not open $data as data (fix_x10c)\n";
##   open N, ">".$new or die "could not write to $new (fix_x10c)\n";
##   my $header = 1;
##   my $null = chr(0).'+';
##   while (<D>) {
##     $_ =~ s/$null//g;		# clean up nulls
##     print N "# " . $_ if $header; # comment headers
##     ($header = 0), next if (uc($_) =~ /^\s+DATA START/);
##     next if ($header);
##     $_ =~ s/([eE][-+]\d{1,2})-/$1 -/g; # clean up 5th column
##     print N $_;
##   };
##   close N;
##   close D;
##   return $new;
## }



## =================================================================
## Check for monotonically increasing data in energy

## return 0 if these data are monotonically increasing in energy and
## return the number of points found out of order if not (yeah, yeah,
## the logic is backwards -- deal!).  also return the list of points
## that aren't monotonic.  $evkev says what kind of data these are --
## encoder and lambda data need to be monotonic *decreasing* in those
## values so that they will be increasing in energy when converted
sub monotonic_data {
  shift;
  my ($group, $xaxis, $evkev) = @_;
  my @x = Ifeffit::get_array($xaxis);
  my @points;
  my $ok = 0;
  my $prev = $x[0];
  if ($evkev =~ /enc|lambda/) {
    foreach (1 .. $#x) {
      if ($x[$_] >= $prev) {++$ok; push @points, $_+1}
      $prev = $x[$_];
    };
  } else {
    foreach (1 .. $#x) {
      if ($x[$_] <= $prev) {++$ok; push @points, $_+1}
      $prev = $x[$_];
    };
  };
  return $ok, @points;
};

## =================================================================
## Check to see if k-grid of input chi(k) data is uniform

## check to see that input chi(k) data is on a rigorously uniform
## k-grid. also check that the first point is either 0 or 0.05.
## return 0 if this data fails either test.
sub uniform_k_grid {
  shift;
  my $group = $_[0];
  my @x = Ifeffit::get_array("$group.k");
  return 0 unless ((abs($x[0]) < EPSI) or ($x[0]-0.05 < EPSI));
  my $ok = 1;
  my $prev = sprintf "%.3f", $x[1] - $x[0];
  foreach (2 .. $#x) {
    my $this = sprintf "%.3f", $x[$_] - $x[$_-1];
    $ok = ($this eq $prev) ? 1 : 0;
    $prev = $this;
  };
  return $ok;
};




## =================================================================
## Recognize and handle backwards data

## check to see if the x-axis array is in descending order.  If it is,
## then reverse all of this groups arrays before actually doing
## anything with them.  Ifeffit needs its data in strictly ascending
## order.  This should be called after a disposal of "read_data" and
## before anything is done with the columns
sub backwards_data {
  shift;
  my ($group, $xaxis) = @_;
  my $col_string = Ifeffit::get_string('$column_label');
  my @cols = split(" ", $col_string);
  my @x = Ifeffit::get_array($xaxis);
  #print join(" ", @x[0..5]), $/;
  my $is_backwards = (($x[0] > $x[1]) and ($x[1] > $x[2]) and ($x[2] > $x[3]) and
		      ($x[3] > $x[4]) and ($x[4] > $x[5]));
  return 0 unless $is_backwards;
  #print "it's backwards!\n";
  foreach (@cols) {
    @x = Ifeffit::get_array("$group.$_");
    @x = reverse @x;
    Ifeffit::put_array("$group.$_", \@x);
  };
  return 1;
}




1;
__END__
