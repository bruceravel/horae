## -*- cperl -*-

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


## fixup shbang lines in the scripts
@ARGV = qw(apt.pl dafs.pl findatp powder.pl template.pl tkatoms.pl horae_update);
do 'fixin';

WriteMakefile(
	      'NAME'    => 'AtomsOtherScripts',
	      'VERSION' => '2004.01.15',
	      EXE_FILES => ['findatp']
	      #'PM' =>
	      #{				# module and data
	      # 'findatp.pl' => "$blib/bin/findatp"
	       #'apt.pl'	 	   => "$blib/bin/apt",
	       #'apt.pod'       	   => "$blib/bin/apt.pod",
	       #'tkatoms.pl'        => "$blib/bin/tkatoms",
	       #'tkatoms.gif'       => "$blib/lib/Xray/lib/tkatoms.gif",
	       #'tkatoms3.xbm'      => "$blib/lib/Xray/lib/tkatoms3.xbm",
	       #'elephant.xbm'      => "$blib/lib/Xray/lib/elephant.xbm",
	       #'Tk/Absorption.pm'  => "$blib/lib/Xray/Tk/Absorption.pm",
	       #'Tk/Atoms.pm'       => "$blib/lib/Xray/Tk/Atoms.pm",
	       #'Tk/Config.pm'	   => "$blib/lib/Xray/Tk/Config.pm",
	       #'Tk/Dafs.pm'	   => "$blib/lib/Xray/Tk/Dafs.pm",
	       ##'Tk/Molecule.pm'  => "$blib/lib/Xray/Tk/Molecule.pm",
	       #'Tk/Plotter.pm'	   => "$blib/lib/Xray/Tk/Plotter.pm",
	       #'Tk/Powder.pm'	   => "$blib/lib/Xray/Tk/Powder.pm",
	       #'Tk/Utils.pm'	   => "$blib/lib/Xray/Tk/Utils.pm",
	      #},
	     );
