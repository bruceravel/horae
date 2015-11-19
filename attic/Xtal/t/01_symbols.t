#! /usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..27$/"; }
END {print "not ok 1$/" unless $loaded;}
use Xray::Xtal;
$Xray::Xtal::run_level = 3;
$loaded = 1;
print "ok 1$/";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


## the purpose of this test is to probe the various ways of specifying
## a space group

@pm3m = ("p m -3 M",		     # 2.  test the symbol itself
	 "p m 3 m",		     # 3.  test the 1935 symbol
	 221,			     # 4.  the number
	 "o_h^1",		     # 5.  schoenflies
	 "o^1_h",		     # 6.  schoenflies, the other way
	 "p 4/m -3 2/m",	     # 7.  the full symbol
	 "P M -3 M",		     # 8.  case
	 "p  m  -3  m",		     # 9.  extra spaces
	 "  p m -3 m",		     # 10. leading spaces
	 "p m -3 m  ",		     # 11. trailing spaces
	 "p	m	  -3	m",  # 12. tabs & spaces
	 "pm-3m",		     # 13. no spaces
	 "pm3m",		     # 14. no spaces
	 "perovskite"		     # 15. shorthand
	);

$n = 1;
while (@pm3m) {
  $this = shift @pm3m;
  ++$n;
  $cell = Xray::Xtal::Cell -> new() -> make(Space_group => $this);
  ($group) = $cell -> attributes("Space_group");
  if ($group eq "p m -3 m") {
    print "ok $n$/";
  } else {
    print "not ok $n$/";
  };
  undef $cell;
};

@cm = ("c m",			# 16. the symbol
       "a m",			# 17. a short monoclinic symbol
       "a 1 1 m",);		# 18. a full monoclinic setting
while (@cm) {
  $this = shift @cm;
  ++$n;
  $cell = Xray::Xtal::Cell -> new() -> make(Space_group => $this);
  ($group) = $cell -> attributes("Space_group");
  if ($group eq "c m") {
    print "ok $n$/";
  } else {
    print "not ok $n$/";
  };
  undef $cell;
};

@abm2 = ("a b m 2",		# 19. the symbol
	 "a e m 2",);		# 20. double glide plane symbol
while (@abm2) {
  $this = shift @abm2;
  ++$n;
  $cell = Xray::Xtal::Cell -> new() -> make(Space_group => $this);
  ($group) = $cell -> attributes("Space_group");
  if ($group eq "a b m 2") {
    print "ok $n$/";
  } else {
    print "not ok $n$/";
  };
  undef $cell;
};

%schoen = ("V_3^3" => "p 31 1 2",   # 21. V groups
	   "D_ 3^ 3" => "p 31 1 2", # 22. spaces in the schoenflies symbol
	  );
while (($key, $val) = each %schoen) {
  ++$n;
  $cell = Xray::Xtal::Cell -> new() -> make(Space_group => $key);
  ($group) = $cell -> attributes("Space_group");
  if ($group eq $val) {
    print "ok $n$/";
  } else {
    print "not ok $n$/";
  };
  undef $cell;
};

				# 23. Miscellany
%misc = ("p 63 / m c m" => "p 63/m c m", # 23: slashes with spaces
	);
while (($key, $val) = each %misc) {
  ++$n;
  $cell = Xray::Xtal::Cell -> new() -> make(Space_group => $key);
  ($group) = $cell -> attributes("Space_group");
  if ($group eq $val) {
    print "ok $n$/";
  } else {
    print "not ok $n$/";
  };
  undef $cell;
};

				# 24-27. Various things that aren't symbols
@not = ("p m -3 q", 0, "o_h^127", "hi mom!");
while (@not) {
  $this = shift @not;
  ++$n;
  $cell = Xray::Xtal::Cell -> new() -> make(Space_group => $this);
  ($group) = $cell -> attributes("Space_group");
  if ($group eq "0") {
    print "ok $n$/";
  } else {
    print "not ok $n$/";
  };
  undef $cell;
};
