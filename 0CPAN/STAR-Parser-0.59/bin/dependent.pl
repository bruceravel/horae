#! /usr/local/bin/perl -w

#########################
#                       # 
# Script dependent.pl   # 
# Wolfgang Bluhm, SDSC  #
#                       #
#########################

# writes a list of all dependent item definitions in dictionary

use STAR::DataBlock;
use STAR::Dictionary;

my $dict = STAR::Dictionary->new($ARGV[0]);
my @saves = $dict->get_save_blocks;   # these describe both items and cats

my ($save, $mand);
my (@depend_items, $depend_item); 

open (OUT, ">$ARGV[1]");

print OUT "Item\n";
print OUT "\tDependent items\n";
print OUT "---------------------------\n\n";

foreach $save ( @saves ) {
    if ( $save =~ /\./ ) {    #this is an item
        @depend_items = $dict->get_item_data(-save=>$save,
                             -item=>"_item_dependent.dependent_name");
        if ( $#depend_items >=0 ) {
            print OUT "$save\n";
            foreach $depend_item ( @depend_items ) {
                print OUT "\t$depend_item\n";
            }
        }
    }
}

close OUT;

=head1 DESCRIPTION

 Reads the saved data structure of a dictionary (.cob file), and outputs 
 a file with a list of dependent item definitions contained in the dictionary.

=head1 USAGE

 perl dependent.pl <dict.cob> <outfile>

=cut

