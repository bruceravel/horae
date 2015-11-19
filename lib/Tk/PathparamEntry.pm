

=head1 NAME

Tk::PathparamEntry - perl/Tk Entry widget with redefined word boundaries

=for pm Tk/PathparamEntry.pm

=for category Derived Widgets

=head1 SYNOPSIS

    use Tk::PathparamEntry;
    ...
    $ppe = $mw->PathparamEntry(?options,...?);

=head1 DESCRIPTION

This "I<IS A>" entry widget with all bindings identical to the normal
entry widget, except that word boundaries have been redefined to be
appropriate to those of an Ifeffit math expression, i.e. whitespace
plus parens, commas, and binary math operators.

=head1 KEYS

widget, entry

=head1 SEE ALSO

L<Tk::Entry>

=cut


package Tk::PathparamEntry;

use Tk::Entry;
use base  qw(Tk::Entry);

Construct Tk::Widget 'PathparamEntry';

sub wordstart
{my ($w,$pos) = @_;
 my $string = $w->get;
 $pos = $w->index('insert')-1 unless(defined $pos);
 $string = substr($string,0,$pos);
 $string =~ s/[^- \t\n\r\f(),^+*\/]*$//;
 length $string;
}

sub wordend
{my ($w,$pos) = @_;
 my $string = $w->get;
 my $anc = length $string;
 $pos = $w->index('insert') unless(defined $pos);
 $string = substr($string,$pos);
 $string =~ s/^(?:((?=[- \t\n\r\f(),^+*\/])[- \t\n\r\f(),+*\/]*|(?=[^- \t\n\r\f(),^+*\/])[^- \t\n\r\f(),^+*\/]*))//x;
 $anc - length($string);
}

1;
