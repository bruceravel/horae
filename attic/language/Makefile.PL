use ExtUtils::MakeMaker;

## If this is being installed with Atoms of with Ifeffit, then
## $ENV{INSTALLING_WITH} will be set by Atoms' topmost Makefile.PL.
my $blib;
SWITCH : {
  $blib = "blib",       last SWITCH if (not $ENV{INSTALLING_WITH});
  $blib = "../blib",    last SWITCH if ($ENV{INSTALLING_WITH} eq 'atoms');
  $blib = "../blib",    last SWITCH if ($ENV{INSTALLING_WITH} eq 'horae');
  $blib = "../../blib", last SWITCH if ($ENV{INSTALLING_WITH} eq 'ifeffit');
};

WriteMakefile(
	      'NAME'    => 'AtomsLanguage',
	      'VERSION' => '2004.01.14',
	      'PM' =>
	      {
	       'atomsrc.en'   => "$blib/lib/Xray/lib/atomsrc.en",
	       'tkatomsrc.en' => "$blib/lib/Xray/lib/tkatomsrc.en",
	      },
	     );
