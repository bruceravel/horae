

=head1 NAME

Tk::KeyEntry - perl/Tk Entry widget for entering single characters

=for pm Tk/KeyEntry.pm

=for category Derived Widgets

=head1 SYNOPSIS

    use Tk::KeyEntry;
    ...
    $ppe = $mw->KeyEntry(?options,...?);

=head1 DESCRIPTION

This "I<IS A>" entry widget with all bindings identical to the normal
entry widget.  However, it only allows the entered string to be one
character long.  Each keystroke replaces the contents of the widget
with the new key stroke.  Only the first character of a clipboard
selection is inserted.

=head1 KEYS

widget, entry

=head1 SEE ALSO

L<Tk::Entry>

=cut

package Tk::KeyEntry;

use Tk::Entry;
use base  qw(Tk::Entry);

Construct Tk::Widget 'KeyEntry';

sub Insert
{
 my $w = shift;
 my $s = shift;
 return unless (defined $s && $s ne '');
 $w -> delete(0, 'end');
 $w->insert('insert',$s);
 $w->SeeInsert
};


sub InsertSelection
{
 my $w = shift;
 eval {local $SIG{__DIE__};
       $w -> delete(0, 'end');
       $w->Insert(substr($w->SelectionGet,0,1))
     }
};

sub ButtonRelease_2
{
 my $w = shift;
 my $Ev = $w->XEvent;
 if (!$Tk::mouseMoved) {
   eval
     {local $SIG{__DIE__};
      $w -> delete(0, 'end');
      $w->insert('insert',substr($w->SelectionGet,0,1));
      $w->SeeInsert;
    }
   }
}



1;
