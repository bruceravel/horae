#! /usr/local/bin/perl -w 

##############################
#                            #
# query.pl                   #
#                            #
# Queries a data structure   # 
# using the STAR::DataBlock  #
# module                     # 
#                            # 
# Wolfgang Bluhm, SDSC       #
#                            #
##############################

use strict;
use STAR::DataBlock;
use STAR::Dictionary;

my ($s, $i);    
my ($string, $dict);
my (@item_data);
my @selected;

my $data = STAR::DataBlock->new($ARGV[0]);     # 1-arg constructor
#
#this just retrieves an already blessed
#object, so ok even if it's a Dictionary
#which inherits from DataBlock

# could also replace the above one-liner 
# with the following two lines:
#
# my $data = STAR::DataBlock->new;              # no-arg constructor
# $data = STAR::DataBlock::retrieve($ARGV[0]);
 
$dict = 0;
$dict = 1 if $data->type eq "dictionary";

if ( $dict ) {
    print "-"x62,"\n";
    print "Query dictionary by save block and item name.\n";
    print "save can be: - (not in a save block),\n";
    print "             A_CATEGORY (e.g. ENTITY),\n";
    print "             _an_item   (e.g. _entity.id)\n";
    print "Capitalization may vary with dictionary.\n";
    print "Item examples: _dictionary.version      ",
          "_dictionary_history.revision\n";
    print "               _category.description    ",
          "_category_examples.case\n";
    print "               _item_linked.child_name  ",
          "_item_description.description\n";
    print "For items with multiple values: ",
          "choose index (e.g.: 1, 4-6)\n";
    print "-"x62,"\n";
}
else {
    print "-"x62,"\n";
    print "Query ",$data->title," by item name.\n";
    print "For items with multiple values: ",
          "choose index (e.g.: 1, 4-6)\n";
    print "-"x62,"\n";
}

do {
    if ( $dict ) {
        print "save: ";
        chomp ($s = <STDIN>);
    }
    else {
        $s = "-";
    }

    print "item: ";
    chomp ($i = <STDIN>);
    
    @item_data = $data->get_item_data( -save=>$s, -item=>$i );
    @selected = ();
    if ( $#item_data < 0 ) {     # returned null, item doesn't exist
        print "item $i doesn't exist\n";
    }
    else {
        if ( $#item_data > 0 ) {
            print "index (range: 0..", $#item_data, "): ";
            chomp ( $string = <STDIN> );
            @selected = selection();
        }
        else {
            push @selected, 0;
        }
        foreach (@selected) {
            print "[$_] " unless ( $#item_data == 0 );
            print $item_data[$_];
            print "\n";
        }
    }
} while (print("Continue with query? ") && <STDIN> =~ /\by/i);


sub selection {

    while ( $string =~ /\d+/ ) {
        if ( $string =~ /^\D*(\d+)\-(\d+)(.*)/ ) {    #range (e.g. 1-3)
            push @selected, ($1..$2);
            $string = $3;
        }
        elsif ( $string =~ /^\D*(\d+)(.*)/ ) {        #one number
            push @selected, $1;
            $string = $2;
        }
    }
    return @selected;
}

=head1 DESCRIPTION

 This script provides a simple interactive query interface to the data structure
 of a file of dictionary (.cob files). Query is by item only (for a data file), 
 or by save block and item (for a dictionary file).

=head1 USAGE

 perl query.pl <data.cob or dict.cob>

=cut


