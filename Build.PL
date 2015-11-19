use strict;
use warnings;
use Module::Build;

(-e 'bin/athena')     and unlink 'bin/athena';
(-e 'bin/artemis')    and unlink 'bin/artemis';
(-e 'bin/hephaestus') and unlink 'bin/hephaestus';


my $build = Module::Build
  -> new(
	 create_readme      => 0,
	 ##create_makefile_pl => 'traditional',
	 license            => 'perl',
	 module_name        => 'horae',
	 dist_author        => 'Bruce Ravel <bravel AT bnl DOT gov>',
	 dist_abstract      => 'XAS data processing and analysis using Ifeffit',
	 dist_version_from  => 'lib/Ifeffit/Tools.pm',
	 requires           => {
				"Tk"                      => '804.027',
				"Compress::Zlib"	  => '0',
				"Archive::Zip"		  => '0',
				"Chemistry::Elements"	  => '0',
				"Config::IniFiles"	  => '0',
				"Math::Combinatorics"	  => '0',
				"Math::Derivative"	  => '0',
				"Math::Round"		  => '0',
				"Math::Spline"		  => '0',
				"Parse::RecDescent"	  => '0',
				"Pod::Escapes"		  => '0',
				"Pod::Simple"		  => '0',
				"Spreadsheet::WriteExcel" => '0',
				"Statistics::Descriptive" => '0',
				"Text::Glob"		  => '0',
				"Tie::IxHash"		  => '0',
				"Tie::Watch"		  => '0',
				"Time::Stopwatch"	  => '0',
				"Tk::FileDialog"	  => '0',
				"Tk::NumEntry"		  => '0',
				"Tk::HistEntry"		  => '0',
				"Tk::Pod"		  => '0',
				"Tk::Splashscreen"	  => '0',
			       },
	 PL_files           => {
				'lib/Xray/space_groups.db.PL' => 'lib/Xray/space_groups.db',
				'mkathena.PL'                 => 'bin/athena',
				'mkartemis.PL'                => 'bin/artemis',
				'mkhephaestus.PL'             => 'bin/hephaestus',
				'mkathenarc.PL'               => 'lib/Ifeffit/lib/athena/athena.ini',
				'mkartemisrc.PL'              => 'lib/Ifeffit/lib/artemis/artemis.ini',
			       },
	 rc_files           => {
				"lib/Ifeffit/lib/athena/athenarc"      => "lib/Ifeffit/lib/athena/athenarc",
				"lib/Ifeffit/lib/athena/athenarcw"     => "lib/Ifeffit/lib/athena/athenarcw",
				"lib/Ifeffit/lib/artemis/artemisrc"    => "lib/Ifeffit/lib/artemis/artemisrc",
				"lib/Ifeffit/lib/artemis/artemisrcw"   => "lib/Ifeffit/lib/artemis/artemisrcw",
				"lib/Ifeffit/lib/hephaestus/kalziumrc" => "lib/Ifeffit/lib/hephaestus/kalziumrc",
			       },
	 recommends         => { },
	 sign               => 0,
	);

foreach my $el (qw(gif png ico xpm config ini rc hints mee readme pod prj db atp en)) {
  $build->add_build_element($el);
};


$build->create_build_script;

