#!/usr/bin/perl -w

use strict;
use Xray::Xtal;
use Ifeffit;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my $elem_regex = '([bcfhiknopsuvwy]|a[cglmrstu]|b[aehikr]|c[adeflmorsu]|dy|e[rsu]|f[emr]|g[ade]|h[aefgos]|i[nr]|kr|l[airu]|m[dgnot]|n[abdeiop]|os|p[abdmortu]|r[abefhnu]|s[bcegimnr]|t[abcehilm]|xe|yb|z[nr])';
my $num_regex  = '-?(\d+\.?\d*|\.\d+)';

## if the display is messed up, comment the next line and uncomment
## the following line
my ($red, $green, $reset) = ("[31;1m", "[32;1m", "[33m[0m");
## my ($red, $green, $reset) = ("", "", "");

print "usage: testinp <file(s)>\n" unless @ARGV;


foreach my $a (@ARGV) {

  ## now test if this is an athena project file
  my $is_proj = test_athena($a);
  my $passfail = ($is_proj) ?
    $green.'athena    '.$reset :
      $red.'not athena'.$reset;
  printf "%s\n\t%s  is_project=%s\n",
    $a, $passfail, $is_proj;

  ## now test if this is an athena project file
  my ($is_zipfile, $horae) = test_artemis($a);
  $passfail = ($is_zipfile and $horae) ?
    $green.'artemis    '.$reset :
      $red.'not artemis'.$reset;
  printf "\t%s is_zipfile=%s  horae=%s\n",
    $passfail, $is_zipfile, $horae;

  ## test if this is a atoms.inp file
  my ($space_test, $atoms_test) = test_atoms($a);
  $passfail = ($atoms_test && $space_test) ?
    $green.'atoms    '.$reset : $red.'not atoms'.$reset;
  printf "\t%s   atoms_test=%d  space_test=%s\n",
    $passfail, $atoms_test, $space_test;

  ## now test if this is a feff.inp file
  my ($abs_test, $scat_test) = test_feff($a);
  $passfail = ($abs_test && $scat_test) ?
    $green.'feff    '.$reset : $red.'not feff'.$reset;
  printf "\t%s    abs_test =%s\n\t            scat_test=%s\n",
    $passfail, $abs_test, $scat_test;

  ## now test if this is a data file
  my $col_string = ($is_zipfile) ? " " : test_data($a);
  $passfail = ($col_string =~ /^(\s*|--undefined--)$/) ?
    $red.'not data'.$reset :
      $green.'data    '.$reset ;
  printf "\t%s    col_string=%s\n",
    $passfail, $col_string;


}


## an atoms.inp file is identified by having a valid space group
## symbol and by having an atoms list with at least one valid line of
## atoms
sub test_atoms {
  my $a = $_[0];
  open A, $a or die "could not open $a: $!";
  my ($space_test, $atoms_test, $toss) = (0,0,0);
  my $switch = 0;
 A: while (<A>) {
    next if /^\s*$/;		# skip blanks
    next if /^\s*[!\#%*]/;	  # skip comment lines
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
  return ($space_test, $atoms_test);
};


## a feff.inp file is identified by having a potentials list and at
## least two valid potentials line, the absorber and one other.
sub test_feff {
  my $a = $_[0];
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
  return ($abs_test, $scat_test);
};


## a data file is data if ifeffit recognizes it as such and returns a
## column_label string
sub test_data {
  my $a = $_[0];
  ifeffit("read_data(file=$a, group=a)\n");
  return Ifeffit::get_string('$column_label');
};


## an athena project file is so marked in the first line
sub test_athena {
  my $file = $_[0];
  open F, $file or die "could not open $file as a record\n";
  my $first = <F>;
  close F;
  return ($first =~ /Athena (record|project) file/) ? $1 : 0;
};


## an artemis project file is a valid zip file with a file called
## HORAE in it.
sub test_artemis {
  my $file = $_[0];
  Archive::Zip::setErrorHandler( \&is_zip_error_handler );
  my $zip = Archive::Zip->new();
  my $is_zipstyle = ($zip->read($file) == AZ_OK);
  my $horae = ($is_zipstyle) ? $zip->membersMatching( '^HORAE$' ) : 0;
  undef $zip;
  Archive::Zip::setErrorHandler( undef );
  return ($is_zipstyle, $horae);
};

sub is_zip_error_handler { 1; };
