#! /usr/local/bin/perl -w

#########################
#                       # 
# Script parentChild.pl # 
# Wolfgang Bluhm, SDSC  #
#                       #
#########################

# writes a list of all dependent item definitions in dictionary

use STAR::DataBlock;
use STAR::Dictionary;

my $dict = STAR::Dictionary->new($ARGV[0]);
my @saves = $dict->get_save_blocks;   # these describe both items and cats

my ($save, $i );
my (@parent_items, @child_items);

open (OUT, ">$ARGV[1]");

foreach $save ( @saves ) {
    if ( 1 ) {    #all
        @parent_items  = $dict->get_item_data(-save=>$save,
                                              -item=>"_item_linked.parent_name");
        @child_items   = $dict->get_item_data(-save=>$save,
                                              -item=>"_item_linked.child_name");
        if ( $#parent_items >=0 ) {
            print OUT "save block: $save\n";
            print OUT "parent\t\t\t  child\n";
            foreach $i ( 0..$#parent_items ) {
                print OUT $parent_items[$i],"\t  ",$child_items[$i],"\n";
            }
            print OUT "\n";
        }
    }
}

close OUT;

=head1 DESCRIPTION

 Reads the data structure of a dictionary (.cob file) and outputs a file 
 listing all parent-child relationships in the dictionary.

=head1 USAGE

 perl parentChild.pl <dict.cob> <outfile>

=cut

