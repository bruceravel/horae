package Ifeffit::Plugins::Filetype::Athena::X10C;  # -*- cperl -*-


=head1 NAME

Ifeffit::Plugin::Filetype::Athena::X10C - NSLS X10C filetype plugin

=head1 SYNOPSIS

This provides two functions which will be called by B<Athena> as

   Ifeffit::Plugin::Filetype::Athena::X10C -> is("/path/to/file");
   $corrected_file = Ifeffit::Plugin::Filetype::Athena::X10C ->
       fix("/path/to/file", "path/to/stash/", $top, $hash_ref);

This documentation describes B<Athena>'s filetype plugin architecture
as well as specifically describing the NSLS X10C plugin.

=head1

This is a plugin which provides two functions to B<Athena> to use to
recognize "non-standard" data, where non-standard means any data file
that cannot be directly interpretted by B<Ifeffit>.  In this case,
data from beamline X10C can be recognized and preprocessed before
importing into B<Athena>.

The file type plugin provides two methods, C<is> and C<fix>.  C<is>
will be used by B<Athena> to test every data file that is imported.
C<fix> will be used to preprocess any data file that C<is> recognizes
so that it can be imported by B<Ifeffit>.

Plugins that are not distributed with B<Athena> can be placed in

   ~/.horae/Ifeffit/Plugin/Filetype/Athena/

on unix and in

   C:\Program Files\Ifeffit\horae\Ifeffit\Plugin\Filetype\Athena\

on windows.  Note that the Windows installation location C<C:\Program
Files\Ifeffit> might be different on your machine.  Programs found in
the plugin location will be loaded and used by B<Athena> to interpret
data files.

=head1 Writing a plugin

The plugin starts with a namespace declaration.  Filetype plugins
B<must> be in the C<Ifeffit::Plugin::Filetype::Athena> namespace.
Choosing a namespace which is indicative of the the file type is
recommended since a message will be sent to the echo area when the
plugin's C<is> method recognizes a file.  This message is of the form

   /path/to/file seems to be a ABCD data file.

where ABCD is the chosen namespace.  In the case of this file, the
namespace is C<X10C> since this plugin corrects files from beamline
NSLS X10C, making them readable by B<Athena>.

The namespace declaration is

   package Ifeffit::Plugin::Filetype::Athena::X10C

(replace C<X10C> with your namespace).  This is followed by some
boilerplate required for the plugin to operate:

   use vars qw(@ISA @EXPORT @EXPORT_OK);
   use Exporter;
   use File::Basename;
   @ISA = qw(Exporter AutoLoader);
   @EXPORT_OK = qw();

You may need to import other modules.  File::Copy is particularly
useful.

The C<is> and C<fix> methods must be defined, as described below.  You
may need to define other subroutines, but those should be treated as
private methods (in the sense that Athena will never call them
directly).

Note that B<Athena> tries to recognize files defined by plugins in
alfabetical order of their namespaces.  Thus the BESSRC test is made
before the X10C test.  Once a filetype test succeeds, the remaining
tests are skiped.  If you wish to assure that your test is made early,
give it a name that sorts to an early position.  This is a good way to
over-ride a test from the standard distribution.

=cut


use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
use File::Basename;
use File::Copy;
@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw();

=head1 Variables

=over 4

=item $is_binary

This variable should be 0 if the data file that this plugin is written
for is a text file.  It should be 1 if this is a binary format.  In
the case of a binary format, the C<fix> method must parse the binary
and write a text file to the stash directory.

=item $description

This variable contains a one-line description of this plugin for use
in the plugin registry.

=cut

use vars qw($is_binary $description);
$is_binary = 0;
$description = "Read files from NSLS beamline X10C.";

=back

=head1 Methods

=over 4

=item C<is>

The is method is used to identify the file type, typically by some
information contained within the file.  In the case of an NSLS X10C
data, the file is recognized by the string "EXAFS" on the first line
and by the string "DATA START" several lines later.

Note that the C<is> method needs to be quick.  There may be many file
type plugins in the queue.  A file that does not meet any of the
plugin criteria will still be subjected to each plugin's C<is>
method. If C<is> is slow, Athena will be slow.

=cut

sub is {
  shift;
  my $data = shift;
  open D, $data or die "could not open $data as data (X10C)\n";
  my $first = <D>;
  close D, return 0 unless (uc($first) =~ /^EXAFS/);
  my $lines = 0;
  while (<D>) {
    close D, return 1 if (uc($first) =~ /^\s+DATA START/);
    ++$lines;
    #close D, return 0 if ($lines > 40);
  };
  close D;
};


=item C<fix>

Stream the input data file into B<Athena>'s stash directory,
performing whatever modifications are needed to bring the data file
into compliance with B<Ifeffit>.

This method takes four arguments all of which will be sent by
B<Athena>.  The first is the fully resolved path to the data file.
The second is the location of the stash directory used by B<Athena>.
The data converted into an B<Athena>-readable format must end up in
the stash directory.  The third argument is B<Athena>'s main window
object.  This is needed for plugins that consist of GUI elements.  For
example, extracting one record from a multi-record data format (Spec
is an example) will require some interaction with the user.  The GUI
element involved in this interaction can be built as a daughter of
main window supplied as the third argument.

The fourth argument is a reference to a hash whose keys and values
will be written to plugin registry file.  This allows parameters set
in the plugin to persist across B<Athena> sessions.  This is most
likely used in conjustion with a GUI element built off the third
argument.  In that scenario, the GUI prompts the user for parameters
required to properly convert the data.  If you need persistence use
this hash to save those values.

This mehtod returns the fully resolved filename of the fixed file in
the stash directory.  To abort file import, return an empty string.

For an NSLS X10C file, the null characters are stripped from the
header, the header lines are commented out with hash characters, and
the situation of the fifth data column not being preceeded by white
space is corrected.

=cut

sub fix {
  shift;
  my ($data, $stash_dir, $top, $hash) = @_;
  my ($nme, $pth, $suffix) = fileparse($data);
  my $new = File::Spec->catfile($stash_dir, $nme);
  ($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);
  open D, $data or die "could not open $data as data (fix in X10C)\n";
  open N, ">".$new or die "could not write to $new (fix in X10C)\n";
  my $header = 1;
  my $null = chr(0).'+';
  while (<D>) {
    $_ =~ s/$null//g;		# clean up nulls
    print N "# " . $_ if $header; # comment headers
    ($header = 0), next if (uc($_) =~ /^\s+DATA START/);
    next if ($header);
    $_ =~ s/([eE][-+]\d{1,2})-/$1 -/g; # clean up 5th column
    print N $_;
  };
  close N;
  close D;
  return $new;
}

=back


=head1 AUTHOR

  Bruce Ravel <bravel@anl.gov>
  http://feff.phys.washington.edu/~ravel/software/exafs/
  Athena copyright (c) 2001-2006


=cut



1;
__END__
