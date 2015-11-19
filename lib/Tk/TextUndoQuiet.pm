

=head1 NAME

Tk::TextUndoQuiet - TextUndo widget sans progress popup in the Save method

=for pm Tk/TextUndoQuiet.pm

=for category Derived Widgets

=head1 SYNOPSIS

    use Tk::TextUndoQuiet;
    ...
    $tuq = $mw->TextUndoQuiet(?options,...?);

=head1 DESCRIPTION

This "I<IS A>" widget with everything identical to the normal TextUndo
widget, except that the progress popup is disabled when saving a file.

=head1 KEYS

widget, text, undo

=head1 SEE ALSO

L<Tk::TextUndo>

=cut


package Tk::TextUndoQuiet;

use Tk::TextUndo;
use base  qw(Tk::TextUndo);

Construct Tk::Widget 'TextUndoQuiet';

sub Save
{
 my ($w,$filename) = @_;
 $filename = $w->FileName unless defined $filename;
 return $w->FileSaveAsPopup unless defined $filename;
 local *FILE;
 if (open(FILE,">$filename"))
  {
   my $status;
   my $count=0;
   my $index = '1.0';
   my $progress;
   my ($lines) = $w->index('end') =~ /^(\d+)\./;
   while ($w->compare($index,'<','end'))
    {
#    my $end = $w->index("$index + 1024 chars");
     my $end = $w->index("$index  lineend +1c");
     print FILE $w->get($index,$end);
     $index = $end;
##      if (($count++%1000) == 0)
##       {
##        $progress = $w->TextUndoFileProgress (Saving => $filename,$count,$count,$
## lines);
##       }
    }
##   $progress->withdraw if defined $progress;
   if (close(FILE))
    {
     $w->ResetUndo;
     $w->FileName($filename);
     return 1;
    }
  }
 else
  {
   $w->BackTrace("Cannot open $filename:$!");
  }
 return 0;
}

1;
