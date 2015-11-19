package Ifeffit::Tools;		# -*- cperl -*-
######################################################################
## Ifeffit::Tools: Object oriented tools for the Ifeffit interface
##
##                      Athena is copyright (c) 2001-2009 Bruce Ravel
##                                              bravel AT bnl DOT gov
##                         http://cars9.uchicago.edu/~ravel/software/
##
##                   Ifeffit is copyright (c) 1992-2007 Matt Newville
##                              newville AT cars DOT uchicago DOT edu
##                       http://cars9.uchicago.edu/~newville/ifeffit/
##
##	  The latest version of Athena can always be found at
##	       http://cars9.uchicago.edu/~ravel/software/
##
## -------------------------------------------------------------------
##     All rights reserved. This program is free software; you can
##     redistribute it and/or modify it provided that the above notice
##     of copyright, these terms of use, and the disclaimer of
##     warranty below appear in the source code and documentation, and
##     that none of the names of NIST, Argonne National Laboratory,
##     The Naval Research Laboratory, The University of Chicago,
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
use Text::Wrap;
use Ifeffit;
use Ifeffit::FindFile;

require Exporter;

@ISA = qw(Exporter AutoLoader Ifeffit);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw();

###########################################################################
# ------------------------------------------------------------------------
## Why is the package containing Athena and Artemis called horae?
##
## "The HORAE, who are worshipped as Hours as well as Seasons, are the
##  wardens of the sky and of Olympus. Their task is to open and close
##  the Gates of Heaven, whether to open the thick cloud in the entrance,
##  or shut it. They also yoke and unyoke the horses of the chariots of
##  the gods, and they feed the horses with ambrosia."
##
## Text copyright © Carlos Parada
## http://homepage.mac.com/cparada/GML/HORAE.html

$VERSION = "070";

# ------------------------------------------------------------------------
###########################################################################

$cvs_info = '$Id: $ ';
$module_version = (split(' ', $cvs_info))[2] || 'pre_release';
my $is_windows = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));


use vars qw/$libdir/;
use File::Spec;
$libdir = File::Spec->catfile(identify_self(), "lib");

sub identify_self {
  my @caller = caller;
  use File::Basename qw(dirname);
  return dirname($caller[1]);
};

use vars qw($horae_dir $horae_atp_dir $horae_dl_dir $horae_stash_dir);
sub initialize_horae_space {
  ## .horae/
  $horae_dir = Ifeffit::FindFile->find("other", "horae");
  (-d $horae_dir) or mkpath($horae_dir);

  ## .horae/atp/
  $horae_atp_dir = Ifeffit::FindFile->find("other", "atp_personal");
  (-d $horae_atp_dir) or mkpath($horae_atp_dir);

  ## .horae/downloads/
  $horae_dl_dir = Ifeffit::FindFile->find("other", "downloads");
  (-d $horae_dl_dir) or mkpath($horae_dl_dir);

  ## .horae/stash/
  $horae_stash_dir = Ifeffit::FindFile->find("other", "stash");
  (-d $horae_stash_dir) or mkpath($horae_stash_dir);
};


my $command_regex = join("|", qw{ f1f2 bkg_cl chi_noise color comment correl cursor
				  def echo erase exit feffit ff2chi fftf fftr
				  get_path guess history linestyle load
				  log macro minimize newplot path pause plot
				  plot_arrow plot_marker plot_text pre_edge print
				  quit random read_data rename reset restore
				  save set show spline sync unguess window
				  write_data zoom });


## return a list of all possible window types (hanning fraction?)
sub Windows {
  my $self = shift;
  return (qw/hanning kaiser-bessel welch parzen sine/);
};


## this converts the Ifeffit version string to a number, e.g. 1.2.5 -> 1.02005
sub vstr {
  my $self = shift;
  my @l = split(" ", Ifeffit::get_string("\$&build"));
  my @v = split(/\./, $l[0]);
  ($v[2] =~ s/[^0-9]//g);
  return ($#v == 2) ? sprintf("%d.%2.2d%3.3d", @v) : $l[0];
};

######################################################################
## Methods for handling energy and k values

## convert an absolute energy value to a k value
## NEED BETTER ABSTRACTION OF ENERGY REFERENCE
sub e2k {
  my $self = shift;
  my $e = shift;
  my $e0 = $self->{bkg_e0} || $self->{e0} || $_[0];
  ($e < $e0) and ($e0 = 0);
  #return 0 if ($e<$e0);
  return sprintf("%.3f", sqrt(($e-$e0)*ETOK));
};

## convert a k value to an absolute energy value
sub k2e {
  my $self = shift;
  my $k = shift;
  my $e0 = 0;# $self->{bkg_e0};
  return $e0 if ($k<0);
  return sprintf("%.3f", ($k**2 / ETOK) + $e0);
};


######################################################################
## crystal d-spacing utility
sub dspacing {
  my ($self, $cut, $temp) = (shift, shift, shift);
  my $ds;
 SHIFT: {
    ## Silicon 111
    (lc($cut) eq 'si(111)') and do {
      my $lattice = 5.43102089;
      ## my $lattice = a0 + alpha * $temp;
      $ds = $lattice/sqrt(3);
      last SHIFT;
    };
    ## Silicon 220
    ((lc($cut) eq 'si(220)') or (lc($cut) eq 'si(202)') or (lc($cut) eq 'si(022)')) and do {
      my $lattice = 5.43102089;
      $ds = $lattice/sqrt(8);
      last SHIFT;
    };
    ## Silicon 311
    ((lc($cut) eq 'si(311)') or (lc($cut) eq 'si(131)') or (lc($cut) eq 'si(113)')) and do {
      my $lattice = 5.43102089;
      $ds = $lattice/sqrt(11);
      last SHIFT;
    };
    ## Silicon 511
    ((lc($cut) eq 'si(511)') or (lc($cut) eq 'si(151)') or (lc($cut) eq 'si(115)')) and do {
      my $lattice = 5.43102089;
      $ds = $lattice/sqrt(27);
      last SHIFT;
    };

    ## Indium Antimonide 111
    (lc($cut) eq 'insb(111)') and do {
      my $lattice = 7.4806;
      $ds = $lattice/sqrt(3);
      last SHIFT;
    };

    ## Germanium 111
    (lc($cut) eq 'ge(111)') and do {
      my $lattice = 5.43102089;
      $ds = $lattice/sqrt(3);
      last SHIFT;
    };

    ## Diamond 111
    (lc($cut) eq 'diamond(111)') and do {
      my $lattice = 3.567;
      $ds = $lattice/sqrt(3);
      last SHIFT;
    };

    ## YB66

    $ds = 1;
  };
  return sprintf("%.7f", $ds);
};

######################################################################
## String interactions

sub get_titles {
  my $self = shift;
  my $group = $self->{group};
  $self->{titles} = [];
  my $i = 1;
  my $str = Ifeffit::get_string(join("", "\$", $group, "_title_", sprintf("%2.2d",$i)));
  while ($str !~ /^\s*$/) {
    push @{$self->{titles}}, $str;
    ++$i;
    $str = Ifeffit::get_string(join("", "\$", $group, "_title_", sprintf("%2.2d",$i)));
  };
};

sub put_titles {
  my $self = shift;
  my $group = $self->{group};
  my $i = 1;
  $i = 1;
  foreach (@{$self->{titles}}) {
    my $name = join("", "\$", $group, "_title_", sprintf("%2.2d",$i));
    my $string = $_;
    if (length($string) > 1000) { $string = substr($string, 0, 1000) };
    Ifeffit::put_string($name, $string);
    ++$i;
  };
  my $str = Ifeffit::get_string(join("", "\$", $group, "_title_", sprintf("%2.2d",$i)));
  while ($str !~ /^\s*$/) {	# clean up remaining strings from memory
    my $name = join("", "\$", $group, "_title_", sprintf("%2.2d",$i));
    $self -> dispose("erase $name", 1);
    ## Ifeffit::put_string(join("", "\$", $group, "_title_", sprintf("%2.2d",$i)), '');
    ++$i;
    ## $str  = Ifeffit::get_string(join("", "\$", $group, "_title_", sprintf("%2.2d",$i)));
    $str  = Ifeffit::get_string($name);
  };
};

sub project_header {
  my $self = shift;
  my $workspace = $_[0] || "";
  my $string = "# This file created at " . $self -> date_of_file . "\n";
  my $iff_vers = (split(" ", Ifeffit::get_string("\$&build")))[0];
  if ($is_windows) {

## http://aspn.activestate.com/ASPN/docs/ActivePerl/5.8/lib/Win32.html
##     OS                    ID    MAJOR   MINOR
##     Win32s                 0      -       -
##     Windows 95             1      4       0
##     Windows 98             1      4      10
##     Windows Me             1      4      90
##     Windows NT 3.51        2      3      51
##     Windows NT 4           2      4       0
##     Windows 2000           2      5       0
##     Windows XP             2      5       1
##     Windows Server 2003    2      5       2
##     Windows Vista          2      6       0

    my @os = eval "Win32::GetOSVersion()";
    my $os = "Some Windows OS";
  SWITCH: {
      $os = "Win32s",              last SWITCH if  ($os[4] == 0);
      $os = "Windows 95",          last SWITCH if (($os[4] == 1) and ($os[1] == 4) and ($os[2] == 0));
      $os = "Windows 98",          last SWITCH if (($os[4] == 1) and ($os[1] == 4) and ($os[2] == 10));
      $os = "Windows ME",          last SWITCH if (($os[4] == 1) and ($os[1] == 4) and ($os[2] == 90));
      $os = "Windows NT 3.51",     last SWITCH if (($os[4] == 2) and ($os[1] == 3) and ($os[2] == 51));
      $os = "Windows NT 4",        last SWITCH if (($os[4] == 2) and ($os[1] == 4) and ($os[2] == 0));
      $os = "Windows 2000",        last SWITCH if (($os[4] == 2) and ($os[1] == 5) and ($os[2] == 0));
      $os = "Windows XP",          last SWITCH if (($os[4] == 2) and ($os[1] == 5) and ($os[2] == 1));
      $os = "Windows Server 2003", last SWITCH if (($os[4] == 2) and ($os[1] == 5) and ($os[2] == 2));
      $os = "Windows Vista",       last SWITCH if (($os[4] == 2) and ($os[1] == 6) and ($os[2] == 0));
    };
    $string .= "# using $os, perl $], Tk $Tk::VERSION, and Ifeffit $iff_vers\n";
    $string .= "# IFEFFIT_DIR is $ENV{IFEFFIT_DIR}\n";
  } else {
    $string .= "# using $^O, perl $], Tk $Tk::VERSION, and Ifeffit $iff_vers\n";
  };
  $string .= "# Workspace: $workspace\n\n" if $workspace;
  return $string;
};


sub date_of_file {
  my $self = shift;
  my $month = (qw/January February March April May June July
	          August September October November December/)[(localtime)[4]];
  my $year = 1900 + (localtime)[5];
  return sprintf "%2.2u:%2.2u:%2.2u on %s %s, %s",
    reverse((localtime)[0..2]), (localtime)[3], $month, $year;
  # ^^^ this gives hour:min:sec
};


######################################################################
## Tk-related commands

## first arg is 1 when this is called from the Help menu, 0 otherwise
## second arg is 1 if called after reading a file, 0 otherwise
sub memory_check {
  my $self = shift;
  my ($top, $echocmd, $hash, $max_heap, $just_checking, $reading_file) = @_;
  &$echocmd("Cannot check memory with this version of Ifeffit"), return 0 if ($max_heap == -1);
  my $free = Ifeffit::get_scalar("\&heap_free");
  my $frac_used = sprintf("%.2f%%", Ifeffit::get_scalar("\&heap_used"));
  my $used = $max_heap - $free;
  foreach my $k (keys %$hash) {
    delete $$hash{$k} unless (ref($$hash{$k}) =~ /Ifeffit/);
  };
  my $ngr  = keys %$hash;
  --$ngr;
  &$echocmd("You have not used any memory yet."), return 0 unless ($ngr>0);
  my $per  = ($ngr) ? $used / $ngr : 0;
  my $more = ($ngr) ? int($free / $per) : 0;
  $per =  int($per/1024);
  $free = int($free/1024);
  $used = int($used/1024);
  my $net = int($max_heap / 1024);
  my $report = "\n\nNumber of groups: $ngr
Memory used per group: about $per kB
Amount of memory space used: $frac_used
Memory space free: $free kB
Total memory space: $net kB
Approximate number of groups available: $more
";
  if ($just_checking) {
    my $message = "Ifeffit's current memory usage:$report";
    my $dialog =
      $top -> Dialog(-bitmap         => 'info',
		     -text           => $message,
		     -title          => 'Athena: memory check',
		     -buttons        => ['OK'],
		     -default_button => 'OK');
    my $response = $dialog->Show();
    return 0;
  } elsif ($more < 2) {
    my $message = "Ifeffit is nearly out of memory space!!!
Athena will not read more data until you
delete some groups.\n\n$report";
    my $dialog =
      $top -> Dialog(-bitmap         => 'error',
		     -text           => $message,
		     -title          => 'Athena: Out of memory space',
		     -buttons        => ['OK'],
		     -default_button => 'OK');
    my $response = $dialog->Show();
    return -1;
  } elsif (($more < 5) and $reading_file) {
    my $message = "You are running out of Ifeffit memory space!!!
Reading this data group is probably ok, but you
need to delete some groups before reading
more data.\n\n$report";
    my $dialog =
      $top -> Dialog(-bitmap         => 'warning',
		     -text           => $message,
		     -title          => 'Athena: memory space running low',
		     -buttons        => ['OK'],
		     -default_button => 'OK');
    my $response = $dialog->Show();
    return 1;
  } elsif (($more < 10) and (not $reading_file)) {
    my $message = "You are running out of Ifeffit memory space!!!
You should probably delete some groups to
free up space before continuing with any
operation.\n\n$report";
    my $dialog =
      $top -> Dialog(-bitmap         => 'warning',
		     -text           => $message,
		     -title          => 'Athena: memory space running low',
		     -buttons        => ['OK'],
		     -default_button => 'OK');
    my $response = $dialog->Show();
    return 1;
  };
  return 1;
};


######################################################################
## Deal with Macintosh EOL characters

## return values: 0: not mac  1: mac and fixed  -1: mac and skipped
sub fix_mac {
  my $self = shift;
  my ($file, $stash_dir, $skip, $top) = @_;
  open F, $file or die "could not open $file as data\n";
  my @snarf = <F>;
  my $is_mac = (grep {/\r/} @snarf);
  close F;
  return 0 unless $is_mac;
  if ($skip eq 'skip') {
    my $message = "The file \"$file\" has Mac end-of-line characters and will be skipped.";
    my $dialog =
      $top -> Dialog(-bitmap         => 'warning',
		     -text           => $message,
		     -title          => 'Athena: Mac file',
		     -buttons        => [qw/OK/],
		     -default_button => 'OK');
    my $response = $dialog->Show();
    return -1;
  } elsif ($skip eq 'ask') {
    my $message = "The file \"$file\" has Mac end-of-line characters.  Would you like to fix the end-of-line characters or skip this file?";
    my $dialog =
      $top -> Dialog(-bitmap         => 'warning',
		     -text           => $message,
		     -title          => 'Athena: Mac file',
		     -buttons        => [qw/Fix Skip/],
		     -default_button => 'Fix');
    my $response = $dialog->Show();
    return -1 if ($response eq 'Skip');
  };
  ## copy file to stash directory and fixy it up using the read
  ## technique found on perlmonks
  my ($nme, $pth, $suffix) = fileparse($file);
  my $stash = File::Spec->catfile($stash_dir, $nme);
  copy($file, $stash);
  my $temp =  File::Spec->catfile($stash_dir, "unmacify");

  my $CHUNK_SIZE = 4096;
  open F, $stash or die "could not open $file as data\n";
  my $chunk;
  my @lines_and_endings;
  my $partial;
  while (read F, $chunk, $CHUNK_SIZE) {
    ## split the chunk into a list of parts, keping the line endings
    ## in an array
    my @parts = split /(\r\n?|\n)/, $chunk;
    if (defined $partial) {
      $parts[0] = $partial . $parts[0];
      undef $partial;
    };
    ## if the last part is not a line ending, then the line could
    ## potentially be continued in the following chunk
    if ($parts[-1] !~ /^\r\n?|\n$/) {
      $partial = pop @parts;
    };
    push @lines_and_endings, @parts;
  };
  push @lines_and_endings, $partial if defined $partial;
  close F;
  open T, ">".$temp or die "could not open $temp for writing\n";
  foreach (grep {! /^\r\n?|\n$/} @lines_and_endings) {
    print T $_, $/;
  };
  close T;
  unlink $stash;
  move($temp, $stash);
  return $stash;
};

######################################################################
## Trapping and processing errors

sub trap {
  my $self = shift;
  my ($program, $version, $type, $trapfile, $error, $workspace) = @_;
  my $file = $trapfile;
  my $i = 2;
  while (-e $trapfile) {
    $file = join("", $file, '~', $i, '~');
    ++$i;
  };

  my $header = $self->project_header($workspace) . "\n\n";
  my $msg    = &Carp::longmess . "\n\n";

  print STDERR "\nThe following message was trapped by $program:\n\n";
  print STDERR $msg;
  print STDERR "Please include this information along with your explanation when\nyou make a bug report.\n";

  ##open FILE, ">>".$file;
##   open FILE, ">".$file;
##   print FILE "# $program $version\n";
##   print FILE $header;
##   print FILE "The following message was trapped by $program on a ";
##   print FILE ($type eq 'warn') ? "SIGWARN:\n\n" : "SIGDIE:\n\n";
##   print FILE $msg;
##   print FILE "End of trap file.\n";
##   close FILE;

  my $message = ($type eq 'warn') ?
    "$program trapped a warning!  Warning message dumped to screen." :
      "$program trapped an error!  Error message dumped to screen.";
  &$error($message);

};



######################################################################
## Dispatching commands

## This uses a binary mode to indicate what chores should be done.  So
## $mode=1 sends the command to ifeffit.  $mode=3 send the command to
## ifeffit AND stores it in the ifeffit buffer.  Etc...

## THIS NEEDS BETTER ABSTRACTION!!!

sub dispose {
  my $self = shift;
  my ($command, $mode) = @_;
  ##(substr($command, -1) eq "\n") or ($command .= "\n");
  $mode ||= 1;

  if ($mode & 1) {
    my ($reprocessed, $eol) = (q{}, $/);
    foreach my $thisline (split(/\n/, $command)) {
      ## this next bit of insanity is an ifeffit optimization.  it is
      ## considerably faster to have perl process multi-line commands
      ## into long (up to 2048 characters) individual commands than to
      ## use ifeffit and the swig wrapper. the point here is to
      ## recognize parens-bound commands and concatinate them onto a
      ## single line

      ## want to not waste time on this if the output mode is for feffit!!
      next if ($thisline =~ m{^\s*\#});
      next if ($thisline =~ m{^\s*$});

      $thisline =~ s{^\s+}{};
      $thisline =~ s{\s+$}{};
      $thisline =~ s{\s+=}{ =};
      my $re = $command_regex;
      $eol = ($thisline =~ m{^(?:$re)\s*\(}) ? " " : $eol;
      $eol = $/ if ($thisline =~ m{\)$});
      $reprocessed .= $thisline . $eol;
    };
    foreach my $thisline (split(/\n/, $reprocessed)) {
      ifeffit($thisline);
      print $thisline,$/,$/ if ($mode & 32);
    };
  };

  foreach my $thisline (split(/\n/, $command)) {
    $thisline =~ s/\+ *-/-/g; # suppress "+-" in command strings math expressions
    $thisline .= "\n";
    ((not defined $mode) or ($mode < 1)) and ($mode = 5);
    #($mode & 1) and do {		# bit 1 is set, send to ifeffit
    #  ifeffit($thisline);
    #};
    ($mode & 2) and do {		# bit 2 is set, store in ifeffit buffer
      push @::ifeffit_buffer, $thisline; # useful for bug reports
    };
    ($mode & 4) and do {		# bit 4 is set, write to ifeffit display
      my $tag = ($thisline =~ /^\s*\#/) ? 'comment' : 'command';
      my $buffer = (ref($::notes{ifeffit}) =~ m{Frame}) ? $::notes{ifeffit}->Subwidget("rotext") : $::notes{ifeffit};
      $buffer -> insert('end', $thisline, $tag);
      my ($lines, $response) = (Ifeffit::get_scalar('&echo_lines')||0, "");
      if ($lines) {
	map {$response .= Ifeffit::get_echo()."\n"} (1 .. $lines);
	if ($response =~ /check these variables:(.*)/is) {
	  @buffer = split(" ", $1);
	};
	($response) and $buffer -> insert('end', $response, 'response');
      };
      $buffer -> yviewMoveto(1);
      my $length = (split(/\./, $buffer -> index('end')))[0];
      if ($length > 100000) {
	my $trim = $length-100000;
	$buffer -> delete('1.0', $trim.'.0');
      };
    };
    ($mode & 8) and do {		# bit 8 is set, store in macro buffer
      push @::macro_buffer, $thisline;
    };
    ($mode & 16) and do {		# bit 16 is set, print to STDOUT
      local $| = 1;
      print STDOUT $thisline;
    };
  };
};


## see http://perlmonks.org/?node_id=316086
sub reload {
  my ($PM) = @_ or return;
  $PM =~ s!::!/!g;
  $PM .= ".pm";
  delete $INC{$PM};
  no strict 'refs';
  no warnings 'redefine';
  my $warnings = \&warnings::import;
  local *warnings::import = sub {
    &{$warnings};
    unimport warnings "redefine";
  };
  eval { require $PM };
};



1;
__END__
