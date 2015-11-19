#! /usr/bin/perl -w
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


## If this is being installed with Atoms of with Ifeffit, then
## $ENV{INSTALLING_WITH} will be set by Atoms' topmost Makefile.PL.
my $blib;
SWITCH : {
  $blib = "blib",       last SWITCH if (not $ENV{INSTALLING_WITH});
  $blib = "../blib",    last SWITCH if ($ENV{INSTALLING_WITH} eq 'atoms');
  $blib = "../blib",    last SWITCH if ($ENV{INSTALLING_WITH} eq 'horae');
  $blib = "../../blib", last SWITCH if ($ENV{INSTALLING_WITH} eq 'ifeffit');
};

#print "In Xtal:  blib=$blib\n";

WriteMakefile
  (
   'NAME'	     => 'Xray::Xtal',
   'DISTNAME'     => 'Xtal',
   'VERSION_FROM' => 'Xtal.pm', # finds $VERSION
   dist           => { COMPRESS => 'gzip -f', SUFFIX => 'gz' },
   clean          =>	{ FILES    => "*.db" },
   ($] >= 5.005 ?
    ('ABSTRACT' =>
     'Xtal.pm: Object Oriented Crystallography with a condensed matter slant',
     'AUTHOR'   => 'Bruce Ravel (ravel@phys.washington.edu)') : ()),
   'PL_FILES'     => {'space_groups.db.PL' => 'space_groups.db',},
   'PM' =>
   {'Xtal.pm'             => "$blib/lib/Xray/Xtal.pm",
    'space_groups.db.PL'  => "$blib/lib/Xray/space_groups.db.PL",
    'space_groups.db'     => "$blib/lib/Xray/space_groups.db",
    'xtalrc.en'           => "$blib/lib/Xray/lib/xtalrc.en",
    #'xtalrc.sp'           => "$blib/lib/Xray/lib/xtalrc.sp",
    #'xtalrc.fr'           => "$blib/lib/Xray/lib/xtalrc.fr",
    #'xtalrc.ge'           => "$blib/lib/Xray/lib/xtalrc.ge",
   },
  );

## Local Variables:
## mode: cperl
## End:
