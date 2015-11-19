

=head1 NAME

Tk::RetEntry - Entry widget with a binding to return and enter

=for pm Tk/RetEntry.pm

=for category Derived Widgets

=head1 SYNOPSIS

    use Tk::RetEntry;
    ...
    $ppe = $mw->KeyEntry(?options,...?);

=head1 DESCRIPTION

This "I<IS A>" entry widget with all bindings identical to the normal
entry widget.  This takes one additional argument, C<-command>, which
is a reference to a callback to be bound to the return and enter keys.

=head1 KEYS

widget, entry

=head1 SEE ALSO

L<Tk::Entry>

=cut


package Tk::RetEntry;

use Tk ();
use Tk::Entry;
use Tk::Derived;
@ISA = qw(Tk::Derived Tk::Entry);
use strict;

Construct Tk::Widget 'RetEntry';

sub Populate {
  my ($self, $args) = @_;
  $self->ConfigSpecs('-command' => ['CALLBACK' => undef, undef, 1],
		     # -foreground is special. Has to be specified otherwise Tk sets it to PASSIVE
		     ## see http://groups-beta.google.com/group/comp.lang.perl.tk/browse_thread/thread/64abac3d77c581a/e236ed8d1584bb5f?q=perl+tk+entry+foreground&rnum=6#e236ed8d1584bb5f
		     '-foreground'  => ['SELF' => "foreground",  "Foreground", Tk::BLACK ],
		     '-selectforeground'  => ['SELF' => "foreground",  "Foreground", Tk::BLACK ],
		    );
  my $command = $args->{-command};
  $self->bind("<KeyPress-Return>"   => $command);
  $self->bind("<KeyPress-KP_Enter>" => $command);
  $self;
};

1;
