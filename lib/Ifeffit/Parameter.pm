package Ifeffit::Parameter;                  # -*- cperl -*-
######################################################################
## Ifeffit::Path: Object oriented GDS parameter manipulation
##
##                     Artemis is copyright (c) 2001-2008 Bruce Ravel
##                                                     bravel@anl.gov
##                            http://feff.phys.washington.edu/~ravel/
##
##                   Ifeffit is copyright (c) 1992-2006 Matt Newville
##                                         newville@cars.uchicago.edu
##                        http://cars.uchicago.edu/~newville/ifeffit/
##
##	  The latest version of Artemis can always be found at
##	 http://feff.phys.washington.edu/~ravel/software/exafs
##
## -------------------------------------------------------------------
##     All rights reserved. This program is free software; you can
##     redistribute it and/or modify it provided that the above notice
##     of copyright, these terms of use, and the disclaimer of
##     warranty below appear in the source code and documentation, and
##     that none of the names of The Naval Research Laboratory, The
##     University of Chicago, University of Washington, or the authors
##     appear in advertising or endorsement of works derived from this
##     software without specific prior written permission from all
##     parties.
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
use vars qw($VERSION $cvs_info $module_version @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader Ifeffit::Tools);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw();

$VERSION = "0.8.013";

sub new {
  my $classname = shift;
  my $self = {};
  $self->{index}     = "";
  $self->{type}      = "";
  $self->{name}      = "";
  $self->{mathexp}   = "";
  $self->{note}      = "";
  $self->{autonote}  = 1;
  $self->{bestfit}   = "";
  $self->{error}     = "";
  $self->{modified}  = 0;
  $self->{highlight} = 0;
  bless($self, $classname);
  $self -> make(@_);
  return $self;
};

sub make {
  my $self = shift;
  unless ($#_ % 2) {
    my $this = (caller(0))[3];
    die "$this error!\n";
    return;
  };
  while (@_) {
    my $att   = lc(shift);
    my $value = shift;
    $self->{$att} = $value unless (($self->{type} eq 'sep') and not ($att =~ /(mathexp|note)/));
    if (($att eq 'type') and ($value eq 'sep')) {
      $self->{name}     = "";
      $self->{mathexp}  = "-" x 25;;
      $self->{bestfit}  = "";
      $self->{modified} = 0;
      $self->{note}	= "separator";
      $self->{autonote} = 0;
    };
  };
};

## generic methods for returning attributes of the parameter object
sub Index     { return shift->{index}     };
sub type      { return shift->{type}      };
sub name      {
  my $self = shift;
  return ($self->type eq 'sep') ? "-" x 7  : $self->{name};
};
sub mathexp   { return shift->{mathexp}   };
sub note      { return shift->{note}      };
sub autonote  { return shift->{autonote}  };
sub bestfit   { return shift->{bestfit}   };
sub error     { return shift->{error}     };
sub modified  { return shift->{modified}  };

## return (and optionally set) the current highlighting code
sub highlight {
  my $self = shift;
  $self->{highlight}+= $_[0] if $_[0];
  return $self->{highlight};
};



sub write_gsd {
  my $self = shift;
  my $use_bestfit = shift;
  my $name   = $self -> name;
  my $choice = $self -> type;
  my $value  = ($use_bestfit and ($choice eq 'guess') and (not $self->modified)) ?
    $self -> bestfit :
      $self -> mathexp;
  my $string;
  return "" if ($choice eq 'skip');
  return "" if ($choice eq 'eval');
  $value =~ s/^\s+//;		# strip leading blanks
  $value =~ s/\s+$//;		# strip trailing blanks
  ($value = "0") if ($value =~ /^\s*$/);
  ($choice = "def") if ($choice eq "restrain");
  ($value = $1) if ($value =~ /([-+]?[\d\.]+)\s*\(.*\)/);
  $string = sprintf("%-5s %s = %s\n", $choice, $name, $value);
  return $string;
};



1;
__END__
