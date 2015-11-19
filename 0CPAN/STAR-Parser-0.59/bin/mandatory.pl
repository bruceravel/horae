#! /usr/local/bin/perl -w

#########################
#                       # 
# Sript mandatory.pl    #
# Wolfgang Bluhm, SDSC  #
#                       #
#########################

# writes a list with all categories and items in the dictionary
# grouped by whether they are listed as mandatory or not

use STAR::DataBlock;
use STAR::Dictionary;

my $dict = STAR::Dictionary->new($ARGV[0]);
my @saves = $dict->get_save_blocks;   # these describe both items and cats

my ($save, $mand);
my @mand_items; 
my @opt_items;
my @mand_cats;
my @opt_cats;

open (OUT, ">$ARGV[1]");

foreach $save ( @saves ) {
    if ( $save eq "-" ) {
        next;
    }
    elsif ( $save !~ /\./ ) {    #this is a category
        $mand = ($dict->get_item_data(-save=>$save,
                                      -item=>"_category.mandatory_code"))[0];
        if ( $mand eq "yes" ) {
            push @mand_cats, $save;
        }
        else {
            push @opt_cats, $save;
        }
    }
    else {                    #this is an item
        $mand = ($dict->get_item_data(-save=>$save,
                                      -item=>"_item.mandatory_code"))[0];
        if ( $mand eq "yes" ) {
            push @mand_items, $save;
        }
        else {
            push @opt_items, $save;
        }
    }
}

print OUT "Summary:\n";
print OUT "--------\n";
print OUT $#mand_cats+1, " mandatory categories\n";
print OUT $#opt_cats+1, " optional categories\n";
print OUT $#mand_items+1, " mandatory items\n";
print OUT $#opt_items+1, " optional items\n";

print OUT "\n\nMandatory Categories:\n";
print OUT     "---------------------\n";
foreach ( @mand_cats ) { print OUT "$_\n"}

print OUT "\n\nOptional Categories:\n";
print OUT     "--------------------\n";
foreach ( @opt_cats ) { print OUT "$_\n"}

print OUT "\n\nMandatory Items:\n";
print OUT     "----------------\n";
foreach ( @mand_items ) { print OUT "$_\n"}

print OUT "\n\nOptional Items:\n";
print OUT     "---------------\n";
foreach ( @opt_items ) { print OUT "$_\n"}

close OUT;

=head1 DESCRIPTION

 Reads in the data structure of a dictionary (.cob file), and outputs a file
 which lists the mandatory status for each category and item described.

=head1 USAGE

 perl mandatory.pl <dict.cob> <outfile>

=cut


