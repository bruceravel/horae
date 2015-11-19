#! /usr/local/bin/perl -w

##########################
#                        #
# create.pl              #
#                        #
# simple script to test  #
# new methods for data   #
# inserting              #
#                        #
# Wolfgang Bluhm, SDSC   #
#                        #
##########################

use strict;
use STAR::DataBlock;

my $i;
my ( @items, @item_data );

my $data = STAR::DataBlock->new;

$data->title('newly_created');
$data->type('data');

$data->file_name('none');
$data->starting_line(0);
$data->ending_line(0);     #how would one handle these?

@items = ('_citation.title', 
          '_citation.id',
          '_citation_author.citation_id',
          '_citation_author.name'
         );

@item_data = ( ['This is just a dummy title', 'Another one'],
               [1,2],
               [1,1,2],
               ['Doe J.','Bear G.B.','Ghost W.'] 
             );

foreach $i ( 0..$#items ) {

    $data->set_item_data( -item=> $items[$i],
                          -dataref=>$item_data[$i]);
}

$data->store($ARGV[0]);

=head1 DESCRIPTION

 A very primitive example using method calls for creating a new data structure.
 (Data to be inserted is hard-coded into the script :-) , 
 and saved as the specified file.)

=head1 USAGE

 perl create.pl <out.cob>

=cut


