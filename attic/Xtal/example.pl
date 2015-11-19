#!/usr/bin/perl -w

## This is a simple example of the use of the Xtal.pm module.
##
## Given this information about a crystal, rhombohedral AgNO3
##
##   title = silver nitrate
##   space = r 3 c
##   a     = 6.342
##   alpha = 47.8167
##   atoms
##     Ag     0.25000   0.25000   0.25000  Ag1 (2b)
##     N      0.00000   0.00000   0.00000  N1 (2a)
##     O      0.25000  -0.25000   0.00000  O1 (6e)
##
## this example will write the contents of the unit cell in cartesian
## coordinates to standard output.  I chose a rhombohedral cell for
## this example because the volume and metric tensor are non-trivial
## but still easy to calculate by hand.

use Xray::Xtal;

## create a new cell and set its attributes
$cell = Xray::Xtal::Cell -> new()
  -> make(Space_group => "r 3 c", A => 6.342, Alpha => 47.8167);
## (you could also say Space_group => 161 or Space_group => "c_3v^6")
## (you could also use the hexagonal setting, although the cartesian
##  coordinates would come out differently)

## some work space
@sites = ();
$n = 0;

## create the sites and define their attributes
$sites[$n++] = Xray::Xtal::Site -> new()
  -> make(Element=>"Ag", X=>0.25, Y=>0.25,  Z=>0.25);

$sites[$n++] = Xray::Xtal::Site -> new()
  -> make(Element=>"N",  X=>0,    Y=>0,     Z=>0   );

$sites[$n++] = Xray::Xtal::Site -> new()
  -> make(Element=>"O",  X=>0.25, Y=>-0.25, Z=>0   );

## now fill out the contents of the unit cell.  this line demonstartes
## the relationship between the Cell and Site objects
$cell -> populate(\@sites);

## the populate method fills up the contents attribute of the cell
## with the complete description of the unit cell (assuming, of
## course, that all the sites were defined)
($contents) = $cell -> attributes("Contents");
@list = @$contents;		# the notation gets hairy, this helps

## $contents is an anonymous array which we want to access in list
## context.  Each element of that array is itself an anonymous array
## describing a position in the unit cell.  The first three elements
## of the position description are the fractional x, y, and z
## coordinates of that position.  The last element is a *reference* to
## the site that generated that position.  This leads to a lot of
## notation...

## note that all of the positions in the unit cell have been
## canonicalized to the first octant (well, actually to the first
## octant in fractional coordinates.  this example just happens to
## also be in the first octant in Cartesian coordinates.)

print <<EOH
From this description of a unit cell in crystallographic notation:

  title = silver nitrate
  space = r 3 c
  a     = 6.342
  alpha = 47.8167
  atoms
    Ag     0.25000   0.25000   0.25000  Ag1 (2b)
    N      0.00000   0.00000   0.00000  N1 (2a)
    O      0.25000  -0.25000   0.00000  O1 (6e)

We get this description in Cartesian coordinates:

EOH
;
while (@list) {
  $this = shift(@list);
  ($x, $y, $z) = $cell -> metric($$this[0], $$this[1], $$this[2]);
  ($elem) = $ {$$this[3]} -> attributes("Element");
  printf "  %-2s\t%8.5f\t%8.5f\t%8.5f$/", $elem, $x, $y, $z;
};

## all done!
