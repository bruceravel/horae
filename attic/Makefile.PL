## -*- cperl -*-

BEGIN {
  print "\n === The Ifeffit wrapper, Athena, Artemis, and Hephaestus ===\n\n";
  ## make sure the pgplot environment is sane...  these defaults
  ## assume that pgplot was installed by Matt's PGPLOT_install
  $ENV{PGPLOT_DIR} ||= '/usr/local/share/pgplot';
  $ENV{PGPLOT_DEV} ||= '/XSERVE';
}


## load some necessary modules ...
use ExtUtils::MakeMaker;
use Config;
use File::Copy;
use File::Spec;
use Getopt::Long;

## process the command line switches ....
my ($nocpan, $debian, $platform) = (0, 0, q{});
## is this windows?  is this Mac?

my $prefix = q{};
&GetOptions('nocpan'     => \$nocpan,   # flag for building CPAN modules in the bundle
	    'platform=s' => \$platform, # flag for specifying platform
	    'prefix=s'   => \$prefix,   # specify an installation prefix
	    'help'       => \&help,
	    'h'          => \&help,
	    'debian'     => \$debian,   # save Carlo some grief
	   );
$platform = lc($platform);
($platform = 'debian') if $debian;
if (not $platform) {
 SWITCH: {
    ($platform = 'windows'), last SWITCH if (($^O eq 'MSWin32') or ($^O eq 'cygwin'));
    ($platform = 'darwin'),  last SWITCH if (lc($^O) eq 'darwin');
    $platform = 'unix';
  };
};


## Set some environment variables to influence how makefiles further
## down in the hierarchy will behave
$ENV{INSTALLING_WITH} = 'horae';
$ENV{SKIP_ALL_CPAN_MODULES} = $nocpan;
print "You are suppressing the installation of the CPAN bundle.\n" if $ENV{SKIP_ALL_CPAN_MODULES};
## this is a leftover from the days when this package was part of the
## ifeffit distro
$blib = "blib";


## refuse to run if the --prefix flag is set AND this is Windows or OSX
if ($prefix and ($platform =~ /(?:darwin|windows)/)) {
  print <<"EOH"

Yikes!

Use of the --prefix flag is only allowed on unix machines.  If you
wish to install this software to a non-standard location on Windows
or Mac OSX, you are on your own.  You will need to understand how
modules are used by perl *and* you will need to modify the Makefile.PL
file.

EOH
    ;
  exit;
};




###====================================================
###
###   step 0
###
## clean up any stray pm_to_blib files so that everything gets
## properly rebuilt
#my @pm_to_blib = `find ./ -name pm_to_blib`;
foreach my $subdir (qw(atp Xtal scripts Chemistry language Absorption)) {
  my $pm_to_blib = File::Spec->catfile($subdir, "pm_to_blib");
  unlink($pm_to_blib) if (-e $pm_to_blib);
};


## need to inport ExtUtils::F77 stuff except on a Windows box which
## lacks compilers (such as my own)
#unless ($^O eq 'MSWin32') { eval "require ExtUtils::F77; ExtUtils::F77->import" };

## ready to start the build process ....
##############################################################################


###====================================================
###
###   step 1
###
## write a comment to the screen to assure the user that this script
## understands what kind of computer it is running on
if ($platform eq 'windows') {
  print "This is Windows.\n";
} elsif ($platform eq 'darwin') {
  print "This is Mac OSX.\n";
} else {
  print "This is $^O.\n";
};


###====================================================
###
###   step 2
###
## check that some minimum standards are met: (1) at least perl 5.004,
## (2) Tk is installed and is at least 800.022
print "Checking dependencies ...\n";
my $stop = 0;
if ($] < 5) {
  warn "  Your version of perl ($]) is way too ancient!  Athena and Artemis\n".
    "     require Perl5.  You can get perl from http://www.perl.com\n";
  ++$stop;
} elsif ($] < 5.005) {
  warn "  Perl version $] is quite old.  You may consider updating.\n".
    "  The latest version of Perl can be found at http://www.perl.com\n";
};
$there = eval 'require Tk;';
if (not $there) {
  warn "  Tk is not installed.  Download the latest from\n".
    "     http://search.cpan.org/search?module=Tk\n";
  ++$stop;
} elsif ($Tk::VERSION < 800.022) {
  warn "  Athena and Artemis require Tk version 800.022 or later.  Download\n".
    "     the latest from http://search.cpan.org/search?module=Tk\n";
  ++$stop;
};

die "Failed dependencies.  Not installing athena and artemis.\n" if $stop;
print "Dependencies ok.  Cool!\n";

$|=1;


###====================================================
###
###   step 3
###
## run two small perl scripts that build configuration files in
## various formats from the master config files.  these config files
## govern the behavior of the preferences in Athena and Artemis
do 'mkathenarc';
do 'mkartemisrc';



###====================================================
###
###   step 4
###
## assemble programs from their parts.  these are simple concatinations

my $mode = 0755;

## ----- build ATHENA
(-e "athena") and unlink "athena";
open TO, ">athena" or die 'could not open athena for writing\n';
foreach my $p (qw(top head main_window draw_properties set_properties file
		  group_ops align pixel calibrate deglitch truncate sa_fluo
		  mee diff lograt peakfit lcf rebin smooth convolve demo
		  macro palettes plot plotstyles project report rc
		  setup mru prefs registry keys teach_ft misc)) {
  open FROM, "athena_parts/$p.pl" or die "could not open athena_parts/$p.pl for reading\n";
  foreach my $l (<FROM>) { print TO $l };
  close FROM
};
close TO;
print "Assembled athena from its parts (athena_parts/).\n";
chmod $mode, 'athena';

## ----- build ARTEMIS
(-e "artemis") and unlink "artemis";
open TO, ">artemis" or die 'could not open artemis for writing\n';
foreach my $p (qw(top head main_window gds2 feff atoms2 path file athena firstshell
		  data palettes fit plot zip project record macro mru
		  prefs log logview feffit rc misc)) {
  open FROM, "artemis_parts/$p.pl" or die "could not open artemis_parts/$p.pl for reading\n";
  foreach my $line (<FROM>) { print TO $line };
  close FROM
};
close TO;
print "Assembled artemis from its parts (artemis_parts/).\n";
chmod $mode, 'artemis';

## ----- build HEPHAESTUS
(-e "hephaestus") and unlink "hephaestus";
open TO, ">hephaestus" or die 'could not open hephaestus.pl for writing\n';
foreach my $p (qw(head absorption formula data f1f2 ion transition find line misc)) {
  open FROM, "hephaestus_parts/$p.pl" or die "could not open parts/$p.pl for reading\n";
  foreach my $line (<FROM>) { print TO $line };
  close FROM
};
close TO;
print "Assembled hephaestus from its parts (hephaestus_parts/).\n";
chmod $mode, 'hephaestus';



###====================================================
###
###   step 5
###
### use the fixin script to fix the #! lines in each of the programs
if ($platform ne 'windows') {
  print "Fixing execution path in the Athena, Artemis, and Hephaestus executables...\n";
  @ARGV = qw(athena artemis hephaestus ifeffit_shell.pl rdaj lsprj atoms);
  do 'fixin';
};



###====================================================
###
###   step 6
###
### a few more small chores

## certain situations require information about compilation and
## installation to be fed to WriteMakefile.  that info will be put
## into this array, but this array needs to be scoped outside of the
## block beginning "unless ($platform eq 'debian') ... "
my @compile = ();

## For Debian, the ifeffit wrapper is a separate package and is a
## dependency so we need not do any of the compilation here.
if (($platform eq 'debian') and (-e "ifeffit_wrap.c")) {
  unlink "ifeffit_wrap.c";
};

if (($Tk::VERSION < 804) and ($platform ne 'debian')) {
  copy "Tk/FBox.pm.save", "Tk/FBox.pm";
};

## For OSX we want to rely upon the installer package to provide a compiled
## ifeffit_wrap, thus we skip the compilation by unlinking the source
if (($platform eq 'darwin') and (-e "ifeffit_wrap.c")) {
  unlink "ifeffit_wrap.c";
};



###====================================================
###
###   step 7
###
### figure out how to compile the ifeffit wrapper and set various
### variables that influence the building of the makefiles
unless ($platform =~ /(?:debian)/) {

  ## this is done so that MakeMaker does not try to generate Makefile
  ## lines to compile the wrapper on a Windows box which lacks compilers
  ## (such as my own).
  if ($platform eq 'windows') {

    copy "MANIFEST", "MANIFEST.unix";
    copy "MANIFEST.windows", "MANIFEST";
    copy "Ifeffit.pm", "Ifeffit.pm.4unix";
    copy "Ifeffit.pm.4windows", "Ifeffit.pm";
  } elsif ($platform ne 'darwin') {
    copy "ifeffit_wrap.c.source", "ifeffit_wrap.c";
  };


  ## figure out where ifeffit thinks pgplot is installed

  my ($compile_flags, $pgplot_location, $iffdir);
  unless ($platform eq 'windows') {
    if ($platform eq 'darwin') {
      $pgplot_location = q{};
    } else {
      ($compile_flags, $pgplot_location, $iffdir) = ("", "", `ifeffit -i`);
      $iffdir =~ s/\s*$//;
      print STDOUT
	"Ifeffit's installations directory is $iffdir\n\t(found by capturing \`ifeffit -i\`)\n";
      open C, "$iffdir/config/Config.mak" or
	die "Could not open $iffdir/config/Config.mak file for reading\n";
      while (<C>) {
	next if (/^\s*\#/);
	chomp;
	($compile_flags   .= (split(/=/, $_))[1]) if (/^LIB/);
	$compile_flags    .= " ";
	($pgplot_location .= (split(" ", $_))[2]) if (/^LIB_PLT/);
      };
      print STDOUT "Compilation flags (from $iffdir/config/Config.mak):\n\t$compile_flags\n";
    };
    $pgplot_location =~ s/-L//;
    if ($pgplot_location) {
      print STDOUT "PGPLOT directory: $pgplot_location\n";
      print STDOUT "Fixing fallback for environment variable PGPLOT_DIR in the programs\n";
      foreach my $name (qw(athena artemis hephaestus)) {
	open OLD, "< $name.pl";
	open NEW, "> $name.fixed";
	while (<OLD>) {
	  s!/usr/local/share/pgplot!$pgplot_location!;
	  print NEW $_;
	};
	close OLD; close NEW;
	rename "$name.fixed", "$name.pl";
	chmod 0755, "$name.pl";
      };
    };
  };


  ## Unix, Windows and OSX+fink have different compilation needs.  this
  ## array attempts to handle them all
  if ($platform eq 'windows') {		# Matt will compile the wrapper for windows
    @compile = ();
  } elsif ($platform eq 'darwin') {
    ## 30-Apr-04 Matt changed to use /Applications/Ifeffit and PGPLOT with
    ##           X11,Aquaterm,and Png devices.
    ##           Using this requires Fink's g77 / libg2c.
    @compile = ('NAME'	       => 'Ifeffit',
		'SKIP'	       => ['test_dynamic'],
		'OBJECT'	       => 'ifeffit_wrap.o',
		'INSTALLBIN'     => '/Applications/Ifeffit/bin',
		'INSTALLSITEBIN' => '/Applications/Ifeffit/bin',
		'INSTALLSCRIPT'  => '/Applications/Ifeffit/bin',
		'INC'	       => '-I/Applications/Ifeffit/share/ifeffit/config',
		'LDDLFLAGS'      => join(" ", $Config{lddlflags},
					 '-framework Foundation',
					 '-framework AppKit'),
		'LIBS'	       => join(" ", $Config{ldflags},
				       qw(-L/Applications/Ifeffit/lib
					  -lifeffit
					  -lpgplot_iff
					  -lpng_iff
					  -lz_iff
					  -laquaterm
					  -L/sw/lib
					  -lg2c
					  -L/usr/lib
					  -lgcc
					  -L/usr/X11R6/lib
					  -lX11
					  -lSystem)),
	       );
  } else {			# this should work for all Unixes (other than darwin)
    if ($prefix) {
      print STDOUT "Installing to prefix=$prefix\n";
      @compile = ('OBJECT'	   => 'ifeffit_wrap.o',
		  'LIBS'	   => [$compile_flags],
		  'PREFIX'     => $prefix,
		  #'INSTALLPRIVLIB' => File::Spec->catfile($prefix, "lib"),
		  #'INSTALLSCRIPT'  => File::Spec->catfile($prefix, "bin"),
		  #'INSTALLBIN'	    => File::Spec->catfile($prefix, "bin"),
		  #'INSTALLMAN1DIR' => File::Spec->catfile($prefix, "man", "man1"),
		  #'INSTALLMAN3DIR' => File::Spec->catfile($prefix, "man", "man3"),
		  #'INSTALLARCHLIB' => File::Spec->catfile($prefix, "lib"),
		 );
    } else {
      @compile = ('OBJECT'     => 'ifeffit_wrap.o',
		  'LIBS'       => [$compile_flags],
		  'INSTALLBIN' => '/usr/local/bin',
		  'INSTALLSCRIPT' => '/usr/local/bin',
		 );
    };
  };
}; ## end of "unless ($platform =~ /(?:darwin|debian)/)"



###====================================================
###
###   step 8
###
### set up the screen message presented after the "make install" stage
sub MY::postamble {
  return "" if ($platform eq 'windows');
  q(
install ::
	@echo ' '
	@echo '*****************************************************************************'
	@echo 'Installation is finished.'
	@echo 'The following programs have been installed:'
	@echo '   athena:      XAS data processing and manipulation'
	@echo '   artemis:     EXAFS data analysis and error analysis'
	@echo '   hephaestus:  Souped-up periodic table for absorption spectroscopists'
	@echo '   atoms:       CLI tool for making feff.inp files'
	@echo ' '
	@echo '     -- This software is copyright (c) 2001-2006, Bruce Ravel --'
	@echo '     -- Ifeffit is copyright (c) 1992-2006, Matthew Newville  --'
	@echo 'Ifeffit, Athena, and Artemis may be freely redistributed according to'
	@echo 'the terms of their licenses.'
	@echo ' '
	@echo 'Join the Ifeffit Mailing List at'
	@echo '    http://millenia.cars.aps.anl.gov/mailman/listinfo/ifeffit/'
	@echo ' '
	@echo 'Send bug reports and suggestions to bravel@anl.gov.  See '
	@echo '    http://cars9.uchicago.edu/~ravel/software/bugs.html'
	@echo '*****************************************************************************'
)
};



###====================================================
###
###   step 9
###
### WriteMakefile actually generates the main makefiles
if ($^O eq 'linux') {
  print STDOUT " * Linux users may see one warning about \"No library found for -lg2c\".\n" .
    " * This can be safely ignored if it only appears once.\n";
};
WriteMakefile(
	      'DISTNAME'     => 'horae',
	      'NAME'	     => 'Ifeffit',
	      'VERSION_FROM' => 'Ifeffit/Tools.pm', # finds $VERSION
	      @compile,
              'dist'         => { COMPRESS => 'gzip -fv', SUFFIX => 'gz' },
	      EXE_FILES      => [qw(athena artemis hephaestus atoms rdaj lsprj)],

	      PREREQ_PM => {Tk			    => 804.027,
			    Archive::Zip	    => 0,
			    Chemistry::Elements	    => 0,
			    Compress::Zlib	    => 0,
			    Config::IniFiles	    => 0,
			    Math::Combinatorics	    => 0,
			    Math::Derivative	    => 0,
			    Math::Round		    => 0,
			    Math::Spline	    => 0,
			    Parse::RecDescent	    => 0,
			    Pod::Escapes	    => 0,
			    Pod::Simple		    => 0,
			    STAR::Parser	    => 0, # am I CPANable?
			    Spreadsheet::WriteExcel => 0,
			    Statistics::Descriptive => 0,
			    Text::Glob		    => 0,
			    Tie::IxHash		    => 0,
			    Tie::Watch		    => 0,
			    Time::Stopwatch	    => 0,
			    Tk::FileDialog	    => 0,
			    Tk::GBARR		    => 0,
			    Tk::HistEntry	    => 0,
			    Tk::Pod		    => 0,
			    Tk::Splashscreen	    => 0,
			    WWWBrowser		    => 0,
			    ##XML::Simple	    => 0, # horae_update
			    perlindex		    => 0,

			    Chemistry::Formula      => 0,
			    Xray::Absorption        => 0,
			   },

	      'PM' =>
	      {
	       ## programs, modules, init files, and data
# 	       'athena.pl'		      => "$blib/bin/athena",
# 	       'artemis.pl'		      => "$blib/bin/artemis",
# 	       'hephaestus.pl'		      => "$blib/bin/hephaestus",
# 	       'atoms.pl'		      => "$blib/bin/atoms",
# 	       'rdaj.pl'	              => "$blib/bin/rdaj",

	       (($platform eq 'debian') ? () :
		('ifeffit_shell.pl'	      => "$blib/bin/ifeffit_shell.pl",
		 'Ifeffit.pm'		      => "$blib/lib/Ifeffit.pm",)),
	       'Ifeffit/Tools.pm'	      => "$blib/lib/Ifeffit/Tools.pm",
	       'Ifeffit/FindFile.pm'	      => "$blib/lib/Ifeffit/FindFile.pm",
	       'Ifeffit/Files.pm'	      => "$blib/lib/Ifeffit/Files.pm",
	       'Ifeffit/Group.pm'	      => "$blib/lib/Ifeffit/Group.pm",
	       'Ifeffit/Path.pm'	      => "$blib/lib/Ifeffit/Path.pm",
	       'Ifeffit/ParseFeff.pm'	      => "$blib/lib/Ifeffit/ParseFeff.pm",
	       'Ifeffit/Parameter.pm'	      => "$blib/lib/Ifeffit/Parameter.pm",
	       'Ifeffit/Elements.pm'	      => "$blib/lib/Ifeffit/Elements.pm",
	       'Ifeffit/ArtemisLog.pm'	      => "$blib/lib/Ifeffit/ArtemisLog.pm",

	       'Ifeffit/Plugins/Filetype/Athena/BESSRC.pm'  => "$blib/lib/Ifeffit/Plugins/Filetype/Athena/BESSRC.pm",
	       'Ifeffit/Plugins/Filetype/Athena/CMC.pm'     => "$blib/lib/Ifeffit/Plugins/Filetype/Athena/CMC.pm",
	       'Ifeffit/Plugins/Filetype/Athena/Encoder.pm' => "$blib/lib/Ifeffit/Plugins/Filetype/Athena/Encoder.pm",
	       'Ifeffit/Plugins/Filetype/Athena/Lambda.pm'  => "$blib/lib/Ifeffit/Plugins/Filetype/Athena/Lambda.pm",
	       'Ifeffit/Plugins/Filetype/Athena/SSRL.pm'    => "$blib/lib/Ifeffit/Plugins/Filetype/Athena/SSRL.pm",
	       'Ifeffit/Plugins/Filetype/Athena/X10C.pm'    => "$blib/lib/Ifeffit/Plugins/Filetype/Athena/X10C.pm",
	       'Ifeffit/Plugins/Filetype/Athena/X15B.pm'    => "$blib/lib/Ifeffit/Plugins/Filetype/Athena/X15B.pm",

	       'Ifeffit/lib/athena/athena.config'    => "$blib/lib/Ifeffit/lib/athena/athena.config",
	       'Ifeffit/lib/athena/athenarc'	     => "$blib/lib/Ifeffit/lib/athena/athenarc",
	       'Ifeffit/lib/athena/athena.hints'     => "$blib/lib/Ifeffit/lib/athena/athena.hints",
	       'Ifeffit/lib/athena/athena.mee'       => "$blib/lib/Ifeffit/lib/athena/athena.mee",
	       'Ifeffit/lib/athena/athena-logo.gif'  => "$blib/lib/Ifeffit/lib/athena/athena-logo.gif",
	       'Ifeffit/lib/athena/athena_icon.xbm'  => "$blib/lib/Ifeffit/lib/athena/athena_icon.xbm",
	       'Ifeffit/lib/athena/athena_icon.gif'  => "$blib/lib/Ifeffit/lib/athena/athena_icon.gif",
	       'Ifeffit/lib/athena/athena_icon.png'  => "$blib/lib/Ifeffit/lib/athena/athena_icon.png",
	       'Ifeffit/lib/athena/athena_icon.xpm'  => "$blib/lib/Ifeffit/lib/athena/athena_icon.xpm",
	       'Ifeffit/lib/athena/athena_icon.ico'  => "$blib/lib/Ifeffit/lib/athena/athena_icon.ico",

	       'Ifeffit/lib/artemis/artemis.config'         => "$blib/lib/Ifeffit/lib/artemis/artemis.config",
	       'Ifeffit/lib/artemis/artemisrc'	            => "$blib/lib/Ifeffit/lib/artemis/artemisrc",
	       'Ifeffit/lib/artemis/artemis.hints'          => "$blib/lib/Ifeffit/lib/artemis/artemis.hints",
	       'Ifeffit/lib/artemis/artemis-logo.gif'       => "$blib/lib/Ifeffit/lib/artemis/artemis-logo.gif",
	       'Ifeffit/lib/artemis/artemis_icon.xbm'       => "$blib/lib/Ifeffit/lib/artemis/artemis_icon.xbm",
	       'Ifeffit/lib/artemis/artemis_icon.gif'       => "$blib/lib/Ifeffit/lib/artemis/artemis_icon.gif",
	       'Ifeffit/lib/artemis/Artemis.png'            => "$blib/lib/Ifeffit/lib/artemis/artemis_icon.png",
	       'Ifeffit/lib/artemis/artemis_icon.xpm'       => "$blib/lib/Ifeffit/lib/artemis/artemis_icon.xpm",
	       'Ifeffit/lib/artemis/artemis_icon.ico'       => "$blib/lib/Ifeffit/lib/artemis/artemis_icon.ico",
	       'Ifeffit/lib/artemis/artemis_project.readme' => "$blib/lib/Ifeffit/lib/artemis/artemis_project.readme",

	       'Ifeffit/lib/hephaestus/absorption.gif' => "$blib/lib/Ifeffit/lib/hephaestus/absorption.gif",
	       'Ifeffit/lib/hephaestus/data.gif'       => "$blib/lib/Ifeffit/lib/hephaestus/data.gif",
	       'Ifeffit/lib/hephaestus/f1f2.gif'       => "$blib/lib/Ifeffit/lib/hephaestus/f1f2.gif",
	       'Ifeffit/lib/hephaestus/find.gif'       => "$blib/lib/Ifeffit/lib/hephaestus/find.gif",
	       'Ifeffit/lib/hephaestus/line.gif'       => "$blib/lib/Ifeffit/lib/hephaestus/line.gif",
	       'Ifeffit/lib/hephaestus/formulas.gif'   => "$blib/lib/Ifeffit/lib/hephaestus/formulas.gif",
	       'Ifeffit/lib/hephaestus/ion.gif'        => "$blib/lib/Ifeffit/lib/hephaestus/ion.gif",
	       'Ifeffit/lib/hephaestus/trans.gif'      => "$blib/lib/Ifeffit/lib/hephaestus/trans.gif",
	       'Ifeffit/lib/hephaestus/help.gif'       => "$blib/lib/Ifeffit/lib/hephaestus/help.gif",
	       'Ifeffit/lib/hephaestus/transition.gif' => "$blib/lib/Ifeffit/lib/hephaestus/transition.gif",
	       'Ifeffit/lib/hephaestus/vulcan.gif'     => "$blib/lib/Ifeffit/lib/hephaestus/vulcan.gif",
	       'Ifeffit/lib/hephaestus/vulcan.ico'     => "$blib/lib/Ifeffit/lib/hephaestus/vulcan.ico",
	       'Ifeffit/lib/hephaestus/vulcan.png'     => "$blib/lib/Ifeffit/lib/hephaestus/vulcan.png",
	       'Ifeffit/lib/hephaestus/vulcan.xpm'     => "$blib/lib/Ifeffit/lib/hephaestus/vulcan.xpm",
	       'Ifeffit/lib/hephaestus/kalziumrc'      => "$blib/lib/Ifeffit/lib/hephaestus/kalziumrc",
	       'Ifeffit/lib/hephaestus/hephaestus_icon.xbm' => "$blib/lib/Ifeffit/lib/hephaestus/hephaestus_icon.xbm",
	       'Ifeffit/lib/hephaestus/hephaestus.ini' => "$blib/lib/Ifeffit/lib/hephaestus/hephaestus.ini",

	       'Xray/Atoms.pm'               => "$blib/lib/Xray/Atoms.pm",
	       'Xray/ATP.pm'                 => "$blib/lib/Xray/ATP.pm",
	       'Xray/Fluo.pm'                => "$blib/lib/Xray/Fluo.pm",


	       'Ifeffit/lib/artemis.doc/artemis.pod'           =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis.pod",
	       'Ifeffit/lib/artemis.doc/artemis_afs.pod'       =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_afs.pod",
	       'Ifeffit/lib/artemis.doc/artemis_athena.pod'    =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_athena.pod",
	       'Ifeffit/lib/artemis.doc/artemis_atoms.pod'     =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_atoms.pod",
	       'Ifeffit/lib/artemis.doc/artemis_editme.pod'    =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_editme.pod",
	       'Ifeffit/lib/artemis.doc/artemis_feffinp.pod'   =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_feffinp.pod",
	       'Ifeffit/lib/artemis.doc/artemis_fitinfo.pod'   =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_fitinfo.pod",
	       'Ifeffit/lib/artemis.doc/artemis_gds.pod'       =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_gds.pod",
	       'Ifeffit/lib/artemis.doc/artemis_intrp.pod'     =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_intrp.pod",
	       'Ifeffit/lib/artemis.doc/artemis_logview.pod'   =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_logview.pod",
	       'Ifeffit/lib/artemis.doc/artemis_opparams.pod'  =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_opparams.pod",
	       'Ifeffit/lib/artemis.doc/artemis_path.pod'      =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_path.pod",
	       'Ifeffit/lib/artemis.doc/artemis_plot.pod'      =>"$blib/lib/Ifeffit/lib/artemis.doc/artemis_plot.pod",

	       ## demo projects
	       'examples/athena/demos/align_merge.prj'	=> "$blib/lib/Ifeffit/lib/demos/align_merge.prj",
	       'examples/athena/demos/calibrate.prj'	=> "$blib/lib/Ifeffit/lib/demos/calibrate.prj",
	       'examples/athena/demos/clamp.prj'	=> "$blib/lib/Ifeffit/lib/demos/clamp.prj",
	       'examples/athena/demos/clnorm.prj'	=> "$blib/lib/Ifeffit/lib/demos/clnorm.prj",
	       'examples/athena/demos/diff.prj'	        => "$blib/lib/Ifeffit/lib/demos/diff.prj",
	       'examples/athena/demos/dispersive.prj'	=> "$blib/lib/Ifeffit/lib/demos/dispersive.prj",
	       'examples/athena/demos/deglitch.prj'	=> "$blib/lib/Ifeffit/lib/demos/deglitch.prj",
	       'examples/athena/demos/linearcombo.prj'  => "$blib/lib/Ifeffit/lib/demos/linearcombo.prj",
	       'examples/athena/demos/peakfit.prj'	=> "$blib/lib/Ifeffit/lib/demos/peakfit.prj",
	       'examples/athena/demos/rbkg.prj'		=> "$blib/lib/Ifeffit/lib/demos/rbkg.prj",
	       'examples/athena/demos/selfabs.prj'      => "$blib/lib/Ifeffit/lib/demos/selfabs.prj",
	       'examples/athena/demos/reports.prj'	=> "$blib/lib/Ifeffit/lib/demos/reports.prj",
	       'examples/athena/demos/smoothing.prj'	=> "$blib/lib/Ifeffit/lib/demos/smoothing.prj",
	       'examples/athena/demos/stacked_plot.prj'	=> "$blib/lib/Ifeffit/lib/demos/stacked_plot.prj",
	       'examples/athena/demos/truncate.prj'	=> "$blib/lib/Ifeffit/lib/demos/truncate.prj",

	       ## non-standard Tk goodies
	       'Tk/PathparamEntry.pm'	      => "$blib/lib/Tk/PathparamEntry.pm",
	       'Tk/KeyEntry.pm'	              => "$blib/lib/Tk/KeyEntry.pm",
	       'Tk/RetEntry.pm'	              => "$blib/lib/Tk/RetEntry.pm",
	       'Tk/SGB.pm'	              => "$blib/lib/Xray/Tk/SGB.pm",
	       'Tk/TextUndoQuiet.pm'          => "$blib/lib/Tk/TextUndoQuiet.pm",

	       ## deal with different versions of perl/Tk
	       #((($Tk::VERSION > 804) or ($platform eq 'debian')) ?
	       # () : ('Tk/FBox.pm' => "$blib/lib/Tk/FBox.pm",)),

	      },
	     );


###====================================================
###
###   step 10
###
### if an installation prefix was specified at the command line, write
### out files for use in bash and tcsh login scripts directing those
### shells where to find all this stuff
if ($prefix) {
  ## munge the names of the libsdirs to reflect the new prefix
  (my $sitearch = $Config{installsitearch}) =~ s(^$Config{prefix})($prefix);
  (my $archlib  = $Config{installarchlib})  =~ s(^$Config{prefix})($prefix);
  prefix_touch_bash($sitearch, $archlib);
  prefix_touch_tcsh($sitearch, $archlib);
  print STDOUT "Wrote files horae.bash and horae.tcsh\n";
};



###====================================================
###
###   step 11
###
### closing message written to the screen
my $make = ($^O eq 'MSWin32') ? 'nmake' :'make';
print STDOUT $/, "+", "--*--" x 14, "+";
print STDOUT "\n| Yay! Now type \"$make\" then \"$make install\" to finish the installation  |\n".
  "| of the Ifeffit wrapper, Athena, Artemis, and Hephaestus.             |\n";
print STDOUT "+", "--*--" x 14, "+", $/, $/;





###====================================================
###
###   extra stuff
###
### two subroutines used in step 10

sub prefix_touch_bash {
  my ($sitearch, $archlib) = @_;
  open B, ">horae.bash" or die "could not touch horae.bash file\n";
  print B "#!/bin/sh

####  Add the contents of this file to the users \$HOME/.profile or to
####  the system level profile (/etc/profile, /etc/bashrc, or perhaps
####  /etc/profile.local)

#### one good way of doing this is to put the following line in the
#### profile.  using a line like this makes it easier to maintain your
#### login scripts should the contents of this file change in a
#### future horae release:
####     test -s /opt/horae/etc/horae.bash \&\& . /opt/horae/etc/horae.bash

# set the path to include the location of the horae binaries
export PATH=\$PATH:\"$prefix/bin/\"
# you might also need to put the location of the ifeffit binary in the PATH

# set manual path and the perl library path
export MANPATH=\$MANPATH:\"$prefix/man/\"
export PERL5LIB=\$PERL5LIB:\"$sitearch\"
export PERL5LIB=\$PERL5LIB:\"$archlib\"

# uncomment the next two lines and modify them to point to the
# location of pgplot on your system
#export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\"/usr/local/pgplot/\"
#export PGPLOT_DIR=\"/usr/local/pgplot\"
export PGPLOT_DEV=\"/xwin\"

";
  close B;
};

sub prefix_touch_tcsh {
  my ($sitearch, $archlib) = @_;
  open B, ">horae.tcsh" or die "could not touch horae.tcsh file\n";
  print B "#!/bin/tcsh

####  Add the contents of this file to the users \$HOME/.cshrc or to
####  the system level profile (/etc/csh.cshrc, /etc/csh.login, or
####  perhaps /etc/csh.login.local)

#### one good way of doing this is to put the following 3 lines in the
#### login script.  using lines like this makes it easier to maintain
#### your login scripts should the contents of this file change in a
#### future horae release:
####    if ( -r /opt/horae/etc/horae.tcsh ) then
####        source /opt/horae/etc/horae.tcsh
####    endif


# set the path to include the location of the horae binaries
setenv PATH \$PATH\":\"$prefix/bin/
# you might also need to put the location of the ifeffit binary in the PATH

# set manual path and the perl library path
setenv MANPATH \$MANPATH\":\"$prefix/man/
setenv PERL5LIB \$PERL5LIB\":\"$sitearch
setenv PERL5LIB \$PERL5LIB\":\"$archlib

# uncomment the next two lines and modify them to point to the
# location of pgplot on your system
#setenv LD_LIBRARY_PATH \$LD_LIBRARY_PATH\":\"/usr/local/pgplot/
#setenv PGPLOT_DIR /usr/local/pgplot
setenv PGPLOT_DEV /xwin

";
  close B;
};


### help message for --help command line argument
sub help {
  print << 'EOH'
This is the build script for the Horae package, which consists of
Athena, Artemis, Hephaestus, and the command line version of Atoms.
Typically, you can run this script without arguments, however in
some situations arguments can be useful.

      flag        type        purpose
   -----------------------------------------------------------
     nocpan      boolean    do not build CPAN bundle
     platform    string     specify the target platform
     prefix      string     specify the installation prefix
     help, h     boolean    write this message and exit

The prefix is usually figured out automatically.  --prefix=debian is
useful for specifying that the build is happening on a debian system or
in the context of building a debian package.  --prefix=windows or
--prefix=darwin may be necessary if the script does not recognize that
you are on one of those platforms for some reason.

EOH
;
  exit;
};
