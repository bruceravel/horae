package Ifeffit::FindFile;		# -*- cperl -*-
######################################################################
## Ifeffit::FindFile: Crude, object oriented file location database
##
##    Athena, Artemis, Hephaestus copyright (c) 2001-2006, 2008 Bruce Ravel
##                                                     bravel@anl.gov
##                                  http://cars9.uchicago.edu/~ravel/
##
##                   Ifeffit is copyright (c) 1992-2006 Matt Newville
##                                         newville@cars.uchicago.edu
##                                 http://cars9.uchicago.edu/ifeffit/
##
##	  The latest version of horae can always be found at
##	       http://cars9.uchicago.edu/~ravel/software/exafs
##
## -------------------------------------------------------------------
##     All rights reserved. This program is free software; you can
##     redistribute it and/or modify it provided that the above notice
##     of copyright, these terms of use, and the disclaimer of
##     warranty below appear in the source code and documentation, and
##     that none of the names of Argonne National Laboratory, The
##     Naval Research Laboratory, The University of Chicago,
##     University of Washington, or the authors appear in advertising
##     or endorsement of works derived from this software without
##     specific prior written permission from all parties.
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

use strict;
use vars qw($VERSION $cvs_info $module_version @ISA @EXPORT @EXPORT_OK @buffer);
use constant ETOK=>0.262468292;
use Carp qw(confess cluck);
use File::Basename;
use File::Copy;
use File::Path;

use constant ENV_HOME => $ENV{HOME} || "";
use constant ENV_IFEFFIT_DIR => $ENV{IFEFFIT_DIR} || "";
use constant PLOP => "plop";

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw();

sub identify_self {
  my @caller = caller;
  use File::Basename qw(dirname);
  return dirname($caller[1]);
};
use vars qw($thisdir $is_windows $is_darwin $xray);
$thisdir = identify_self();
$is_windows = ((lc($^O) eq 'mswin32') or (lc($^O) eq 'cygwin'));
$is_darwin  =  (lc($^O) eq 'darwin');
($xray = $thisdir) =~ s{Ifeffit$}{Xray};

## attempt to find some adequate userspace on WINDOWS
my $WIN_HOME = ENV_IFEFFIT_DIR;
if ($is_windows) {
  if (-e $ENV{USERPROFILE}) {
    $WIN_HOME = File::Spec->catfile($ENV{USERPROFILE}, "Application Data");
    mkpath($WIN_HOME) if not -e $WIN_HOME;
  } elsif (-e $ENV{HOMEPATH}) {
    $WIN_HOME = $ENV{HOMEPATH};
  } elsif (-e $ENV{HOME}) {
    $WIN_HOME = $ENV{HOME};
  };
};


my %_unix =
  (
   hephaestus =>
   {
    horae       => File::Spec->catfile(ENV_HOME, ".horae"),
    hephaestus  => File::Spec->catfile($thisdir, "lib", "hephaestus"),
    par         => PLOP,
    rc_personal => File::Spec->catfile(ENV_HOME, ".horae", "hephaestus.ini"),
    rc_system   => File::Spec->catfile($thisdir, "lib", "hephaestus", "hephaestus.ini"),
    data        => File::Spec->catfile(ENV_HOME, ".horae", "hephaestus.data"),
   },

   athena =>
   {
    horae           => File::Spec->catfile(ENV_HOME, ".horae"),
    rc_dummy	    => File::Spec->catfile(ENV_HOME, ".horae", "athenarc.dummy"),
    rc_personal	    => File::Spec->catfile(ENV_HOME, ".horae", "athenarc"),
    version_marker  => File::Spec->catfile(ENV_HOME, ".horae", "athena.0.8.022"),
    mru             => File::Spec->catfile(ENV_HOME, ".horae", "athena.mru"),
    system_mee      => File::Spec->catfile($thisdir, "lib", "athena", "athena.mee"),
    mee             => File::Spec->catfile(ENV_HOME, ".horae", "athena.mee"),
    plotstyles      => File::Spec->catfile(ENV_HOME, ".horae", "athena.plst"),
    plugins         => File::Spec->catfile(ENV_HOME, ".horae", "athena.plugins"),
    demos	    => File::Spec->catfile($thisdir, "lib", "demos"),
    poddir	    => File::Spec->catfile($thisdir, "lib", "athena.doc"),
    aug 	    => File::Spec->catfile($thisdir, "lib", "aug"),
    augpod	    => File::Spec->catfile($thisdir, "lib", "aug", "pod"),
    aughtml	    => File::Spec->catfile($thisdir, "lib", "aug", "html"),
    logo	    => File::Spec->catfile($thisdir, "lib", "athena", "athena-logo.gif"),
    rc_sys	    => File::Spec->catfile($thisdir, "lib", "athena", "athenarc"),
    hints           => File::Spec->catfile($thisdir, "lib", "athena", "athena.hints"),
    xbm             => File::Spec->catfile($thisdir, "lib", "athena", "athena_icon.xbm"),
    xpm             => File::Spec->catfile($thisdir, "lib", "athena", "athena_icon.gif"),
    config          => File::Spec->catfile($thisdir, "lib", "athena", "athena.config"),
    plugininc       => $thisdir,
    pluginiff       => $thisdir,
    userplugininc   => File::Spec->catfile(ENV_HOME, ".horae"),
    userfiletypedir => File::Spec->catfile(ENV_HOME, ".horae", "Ifeffit", "Plugins", "Filetype", "Athena"),
    par             => PLOP,
    oldrc           => File::Spec->catfile(ENV_HOME, ".athenarc"),
    oldmru          => File::Spec->catfile(ENV_HOME, ".athena.mru"),
    temp_lcf        => File::Spec->catfile(ENV_HOME, ".horae", "stash", "...marked.lcf.csv"),
   },

   artemis =>
   {
    horae          => File::Spec->catfile(ENV_HOME, ".horae"),
    tmp		   => File::Spec->catfile(ENV_HOME, ".horae", "stash", "tmp"),
    rc_dummy	   => File::Spec->catfile(ENV_HOME, ".horae", "artemisrc.dummy"),
    rc_personal	   => File::Spec->catfile(ENV_HOME, ".horae", "artemisrc"),
    version_marker => File::Spec->catfile(ENV_HOME, ".horae", "artemis.0.6.007"),
    mru            => File::Spec->catfile(ENV_HOME, ".horae", "artemis.mru"),
    doc		   => File::Spec->catfile($thisdir, "lib", "artemis.doc"),
    logo	   => File::Spec->catfile($thisdir, "lib", "artemis", "artemis-logo.gif"),
    rc_sys	   => File::Spec->catfile($thisdir, "lib", "artemis", "artemisrc"),
    hints          => File::Spec->catfile($thisdir, "lib", "artemis", "artemis.hints"),
    xbm            => File::Spec->catfile($thisdir, "lib", "artemis", "artemis_icon.xbm"),
    xpm            => File::Spec->catfile($thisdir, "lib", "artemis", "artemis_icon.gif"),
    config         => File::Spec->catfile($thisdir, "lib", "artemis", "artemis.config"),
    readme         => File::Spec->catfile($thisdir, "lib", "artemis", "artemis_project.readme"),
    par            => PLOP,
    oldrc          => File::Spec->catfile(ENV_HOME, ".artemisrc"),
    oldmru         => File::Spec->catfile(ENV_HOME, ".artemis.mru"),
   },

   atoms =>
   {
    atp_personal   => File::Spec->catfile(ENV_HOME, ".horae", "atp"),
    atp_sys        => File::Spec->catfile($xray, "atp"),
    xray_lib       => File::Spec->catfile($xray, "lib"),
    space_group_db => File::Spec->catfile($xray, "space_groups.db"),
   },

   other =>
   {
    horae        => File::Spec->catfile(ENV_HOME, ".horae"),
    atp_personal => File::Spec->catfile(ENV_HOME, ".horae", "atp"),
    downloads    => File::Spec->catfile(ENV_HOME, ".horae", "downloads"),
    stash        => File::Spec->catfile(ENV_HOME, ".horae", "stash"),
    formula_dat  => PLOP,
    absorption   => PLOP,
    scattering   => PLOP,
    cromann_db   => PLOP,
    waaskirf_db  => PLOP,
   },
  );

my %_windows =
  (
   hephaestus =>
   {
    horae       => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "hephaestus"),
    hephaestus  => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "hephaestus"),
    par         => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "par", "hephaestus"),
    rc_personal => File::Spec->catfile($WIN_HOME,       "horae", "hephaestus.ini"),
    rc_system   => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "hephaestus", "hephaestus.ini"),
    data        => File::Spec->catfile($WIN_HOME,       "horae", "hephaestus.data"),
   },

   athena =>
   {
    horae	    => File::Spec->catfile($WIN_HOME,       "horae"),
    demos	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "examples", "Athena", "demos"),
    poddir	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "doc", "athena"),
    aug 	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "aug"),
    augpod	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "aug", "pod"),
    aughtml	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "aug", "html"),
    rc_sys	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "athena", "athenarcw"),
    logo	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "athena", "athena-logo.gif"),
    config	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "athena", "athena.config"),
    hints	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "athena", "athena.hints"),
    xbm		    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "athena", "athena_icon.xbm"),
    xpm		    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "athena", "athena_icon.gif"),
    plugininc	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "perl"),
    pluginiff	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "perl", "Ifeffit"),
    par		    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "par", "athena"),
    rc_dummy	    => File::Spec->catfile($WIN_HOME,       "horae", "athenarc.dummy"),
    rc_personal	    => File::Spec->catfile($WIN_HOME,       "horae", "athena.ini"),
    version_marker  => File::Spec->catfile($WIN_HOME,       "horae", "athena.0.8.022"),
    mru		    => File::Spec->catfile($WIN_HOME,       "horae", "athena.mru"),
    system_mee	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "athena", "athena.mee"),
    mee		    => File::Spec->catfile($WIN_HOME,       "horae", "athena.mee"),
    plotstyles      => File::Spec->catfile($WIN_HOME,       "horae", "athena.plst"),
    plugins         => File::Spec->catfile($WIN_HOME,       "horae", "athena.plugins"),
    userplugininc   => File::Spec->catfile($WIN_HOME,       "horae"),
    userfiletypedir => File::Spec->catfile($WIN_HOME,       "horae", "Ifeffit", "Plugins", "Filetype", "Athena"),
    oldrc	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "athena.ini"),
    oldmru	    => File::Spec->catfile(ENV_IFEFFIT_DIR, "athena.mru"),
    temp_lcf        => File::Spec->catfile($WIN_HOME,       "horae", "stash", "...marked.lcf.csv"),
   },

   artemis =>
   {
    horae          => File::Spec->catfile($WIN_HOME,       "horae"),
    doc		   => File::Spec->catfile(ENV_IFEFFIT_DIR, "doc", "artemis"),
    rc_sys	   => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "artemis", "artemisrcw"),
    logo	   => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "artemis", "artemis-logo.gif"),
    hints          => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "artemis", "artemis.hints"),
    xbm            => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "artemis", "artemis_icon.xbm"),
    xpm            => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "artemis", "artemis_icon.gif"),
    config         => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "artemis", "artemis.config"),
    readme         => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "artemis", "artemis_project.readme"),
    par            => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "par", "artemis"),
    tmp            => File::Spec->catfile($WIN_HOME,       "horae", "stash", "tmp"),
    rc_dummy	   => File::Spec->catfile($WIN_HOME,       "horae", "artemisrc.dummy"),
    rc_personal	   => File::Spec->catfile($WIN_HOME,       "horae", "artemis.ini"),
    version_marker => File::Spec->catfile($WIN_HOME,       "horae", "artemis.0.6.007"),
    mru            => File::Spec->catfile($WIN_HOME,       "horae", "artemis.mru"),
    oldrc          => File::Spec->catfile(ENV_IFEFFIT_DIR, "artemis.ini"),
    oldmru         => File::Spec->catfile(ENV_IFEFFIT_DIR, "artemis.mru"),
   },

   atoms =>
   {
    atp_personal   => File::Spec->catfile($WIN_HOME,       "horae", "atp"),
    atp_sys        => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "atp"),
    xray_lib       => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "perl", "Xray", "lib"),
    space_group_db => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "perl", "Xray", "space_groups.db")
   },

   other =>
   {
    horae        => File::Spec->catfile($WIN_HOME,       "horae"),
    atp_personal => File::Spec->catfile($WIN_HOME,       "horae", "atp"),
    downloads    => File::Spec->catfile($WIN_HOME,       "horae", "downloads"),
    stash        => File::Spec->catfile($WIN_HOME,       "horae", "stash"),
    formula_dat  => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "chemistry", "formula.dat"),
    absorption   => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "perl", "Xray", "Absorption"),
    scattering   => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "perl", "Xray", "Scattering"),
    cromann_db   => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "perl", "Xray", "cromamm.db"),
    waaskirf_db  => File::Spec->catfile(ENV_IFEFFIT_DIR, "share", "perl", "Xray", "waaskirf.db"),
   },
  );



sub find {
  my ($self, $program, $which) = (shift, shift, shift);
  my $location;
  if ($is_windows) {
    $location = $_windows{$program}{$which};
  ## } elsif ($is_darwin) {
  ##   $location = $_unix{$program}{$which};
  } else {
    $location = $_unix{$program}{$which};
  };
  return ($location eq PLOP) ? q{} : $location;
};



1;
__END__
