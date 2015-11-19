#! /usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10$/"; }
END {print "not ok 1$/" unless $loaded;}
use Xray::Xtal;
$loaded = 1;
print "ok 1$/";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$epsilon = 0.00001;

## instantiate a cell and set it dimensions
$cell = Xray::Xtal::Cell -> new() -> make("A" => 6.342, "Alpha" => 47.8167);
print "ok 2$/";

## start building cell for AgNO3

## title silver nitrate
## space  r 3 c
## a    = 6.342
## alpha= 47.8167
## rmax = 6.00
## core = Ag1
## atom
## Ag     0.25000   0.25000   0.25000  Ag1 (2b)
## N      0.00000   0.00000   0.00000  N1 (2a)
## O      0.25000  -0.25000   0.00000  O1 (6e)

## test Cell attributes
($a, $alpha) = $cell -> attributes("A", "Alpha");
if ( (abs($a-6.342)<$epsilon) and (abs($alpha-47.8167)<$epsilon) ) {
  print "ok 3$/";
} else {
  print "not ok 3$/";
};

## now set the space group (this could have been done when
## instantiated)
$cell -> make("Space_group" => "r 3 c");

## does it know that this is the rhombohedral setting?
($setting) = $cell -> attributes("Setting");
if ($setting eq "rhombohedral") {
  print "ok 4$/";
} else {
  print "not ok 4$/";
};

## did the other axes/angles get set?
($b, $c, $beta, $gamma) = $cell -> attributes("B", "C", "Beta", "Gamma");
if ( (abs($b-6.342) < $epsilon)        and
     (abs($c-6.342) < $epsilon)        and
     (abs($beta-47.8167)  < $epsilon)  and
     (abs($gamma-47.8167) < $epsilon) ) {
  print "ok 5$/";
} else {
  print "not ok 5$/";
};

## cell volume
## $pi = 3.14159265358979323844;
## $ang_rad = $pi * 47.8167 / 180;
## $vol = 6.342**3 * sqrt(1 - 3*cos($ang_rad)**2 + 2*cos($ang_rad)**3);
$vol = 128.261102611632;
($volume) = $cell -> attributes("Volume");
if (abs($vol-$volume) < $epsilon) {
  print "ok 6$/";
} else {
  print "not ok 6$/";
};

## metric tensor
## $cosxx = ( cos($ang_rad)**2 - cos($ang_rad) ) / ( sin($ang_rad)**2 );
## $sinxx = sqrt(1-$cosxx**2);
## $txx = $sinxx*sin($ang_rad);
## $tyx = -( ($cosxx/($sinxx*sin($ang_rad)) ) +
##           (cos($ang_rad)*$cosxx)/($sinxx*sin($ang_rad)))
##          * ($sinxx*sin($ang_rad));
## $tyz = cos($ang_rad);
## $tzx = -( $cosxx*$sinxx*sin($ang_rad) ) / $sinxx;
## $tzz = sin($ang_rad);
($txx, $tyx, $tyz, $tzx, $tzz) =
  (0.678575, 0.671505, 0.671505, 0.297687, 0.741000);
($xx, $yx, $yz, $zx, $zz) =
  $cell -> attributes("Txx", "Tyx", "Tyz", "Tzx", "Tzz");
if ( (abs($txx-$xx) < $epsilon) and
     (abs($tyx-$yx) < $epsilon) and
     (abs($tyz-$yz) < $epsilon) and
     (abs($tzx-$zx) < $epsilon) and
     (abs($tzz-$zz) < $epsilon) ) {
  print "ok 7$/";
} else {
  print "not ok 7$/";
};

## ($bravais) = $cell -> attributes("Bravais");
## print join(", ", @{$bravais}), $/;

## now lets start checking the site class

@sites = ();
$n = 0;

## Ag     0.25000   0.25000   0.25000  Ag1 (2b)
## N      0.00000   0.00000   0.00000  N1 (2a)
## O      0.25000  -0.25000   0.00000  O1 (6e)

## instantiate and set attributes of the three sites
$sites[$n++] = Xray::Xtal::Site -> new()
  -> make(Element=>"Ag", X=>0.25, Y=>0.25, Z=>0.25);

$sites[$n++] = Xray::Xtal::Site -> new()
  -> make(Element=>"N",  X=>0,    Y=>0,    Z=>0   );

$sites[$n++] = Xray::Xtal::Site -> new()
  -> make(Element=>"O",  X=>0.25, Y=>0.75, Z=>0   );

## and populate the cell with those sites.  This line is key and
## demonstrates the interplay between the two classes
$cell -> populate(\@sites);

##   Ag    0.25000    0.25000    0.25000  Ag1       	   0
##   Ag    0.75000    0.75000    0.75000  Ag1       	   1
##   N     0.00000    0.00000    0.00000  N1        	   2
##   N     0.50000    0.50000    0.50000  N1        	   3
##   O     0.25000    0.75000    0.00000  O1        	   4
##   O     0.00000    0.25000    0.75000  O1        	   5
##   O     0.75000    0.00000    0.25000  O1        	   6
##   O     0.25000    0.75000    0.50000  O1        	   7
##   O     0.75000    0.50000    0.25000  O1        	   8
##   O     0.50000    0.25000    0.75000  O1        	   9

@test = ("Ag 0.25000 0.25000 0.25000",
	 "Ag 0.75000 0.75000 0.75000",
	 "N  0.00000 0.00000 0.00000",
	 "N  0.50000 0.50000 0.50000",
	 "O  0.25000 0.75000 0.00000",
	 "O  0.00000 0.25000 0.75000",
	 "O  0.75000 0.00000 0.25000",
	 "O  0.25000 0.75000 0.50000",
	 "O  0.75000 0.50000 0.25000",
	 "O  0.50000 0.25000 0.75000");



($contents) = $cell -> attributes("Contents");

## test number of items in the unit cell
if ($#{$contents} == 9) {
  print "ok 8$/";
} else {
  print "not ok 8$/";
};

## make strings from the fractional positions in the unit cell and
## compare them to stored strings
$cell_test = 1;
@list = @{$contents};
while (@list) {
  $this = shift(@list);

  ($elem) = $ {$$this[3]} -> attributes("Element");
  $this_site = sprintf "%-2s %7.5f %7.5f %7.5f",
  $elem, $$this[0], $$this[1], $$this[2];

  $test = shift(@test);

  #print "$test  $this_site $/";
  $cell_test &&= ($test eq $this_site);
};

if ($cell_test) {
  print "ok 9$/";
} else {
  print "not ok 9$/";
};


## now test the conversion to cartesian coordinates

@coords = (" 1.07588,  3.71484,  1.64684",
	   " 3.22764, 11.14452,  4.94052",
	   " 0.00000,  0.00000,  0.00000",
	   " 2.15176,  7.42968,  3.29368",
	   " 1.07588,  5.82117,  0.47198",
	   " 0.00000,  4.77951,  3.52457",
	   " 3.22764,  4.25868,  2.59080",
	   " 1.07588,  7.95051,  2.82170",
	   " 3.22764,  7.42968,  2.59080",
	   " 2.15176,  6.90885,  4.46853",);

$metric_test = 1;
@list = @{$contents};
while (@list) {
  $this = shift(@list);
  ($x, $y, $z) = $cell -> metric($$this[0], $$this[1], $$this[2]);
  $this_coord =  sprintf "%8.5f, %8.5f, %8.5f",  $x, $y, $z;
  $test = shift(@coords);
  #($test eq $this_coord) || ( print ">", $test, "<  >", $this_coord, "<", $/);
  $metric_test &&= ($test eq $this_coord);
};

if ($metric_test) {
  print "ok 10$/";
} else {
  print "not ok 10$/";
};

## Local Variables:
## mode: cperl
## End:
