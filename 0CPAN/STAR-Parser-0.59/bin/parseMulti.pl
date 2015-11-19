#! /usr/local/bin/perl

=head1 DESCRIPTION

  This script will attempt to parse all cif files in 
  a given directory and save the parsed binaries.

=head1 USAGE

  parseMulti.pl [-i <input dir> -r -s <size> -o <output dir> -f <filter dict> -l <log file> -c]

  Options:

  -i input directory
  -r recursively search all subdirectories
  -o output directory
  -f filter through dictionary
  -l log file
  -c compress the binaries
  -s size limit: skip files that are greater than <size> MB uncompressed 

  Comments:

  -i defaults to working directory if omitted
  -o defaults to working directory if omitted
  -l defaults to cifParse.log if omitted

=cut

use STAR::Parser;
use STAR::Filter;
use strict;
use Getopt::Std;
use vars qw( $opt_i $opt_r $opt_o $opt_f $opt_l $opt_c $opt_s ); 

getopt('iofls');

$opt_i or $opt_i = ".";
$opt_o or $opt_o = ".";
$opt_l or $opt_l = "cifParse.log";

my $compress = "/bin/compress -f";
my $uncompress = "/bin/uncompress -f";

my @tmp;             # temporary file list (find command output)
my @files;           # file list
my $file;            # one file
my $uncompressed;    # uncompressed file
my $status;          # status of system call
my $id;              # pdbid
my $parse_opt;       # parse options
my $data;            # parsed data object
my $filtered;        # filtered data object
my $dict;            # dictionary
my $date;            # date and time
my $size;            # size limit for files (uncompressed, in MB)
my $pwd;             # working directory

if ( -e "temp.cif.Z" or -e "temp.cif" ) {
    die "Please remove file(s) temp.cif* from working directory";
}

$pwd = `pwd`;

# open log file 
#
open (LOG, ">$opt_l");
print LOG "Working directory: $pwd";
print LOG "Directory of cif files: $opt_i\n";
print LOG "Subdirectories included? ", $opt_r?"yes":"no","\n";
print LOG "Size limit for uncompressed files? ", $opt_s?"$opt_s MB":"none", "\n";
print LOG "Dictionary used for filtering: ", $opt_f?"$opt_f":"none","\n";
print LOG "\n";

# open dictionary
#
if ( $opt_f ) {
    $opt_f =~ /\.cob/ or die "Dictionary must be a binary (.cob file)";
    $dict = STAR::Dictionary->new( $opt_f );
}

# assemble file list
#
if ( $opt_r ) {
    @tmp = `find $opt_i -name "*.cif" -print`;
    @tmp = ( @tmp, `find $opt_i -name "*.cif.Z" -print` );
}
else {
    @tmp = `ls -1 $opt_i/*.cif $opt_i/*.cif.Z`;
}
foreach ( @tmp ) {
    /^(.*\.cif[\.Z]*)/;
    push @files, $1;
}

$date = `date`;
print LOG "Started parsing: $date";

# process all files
#
foreach $file ( sort @files ) {

    $file =~ /(....)\.cif/;
    $id = $1;
    
    if ( $file =~ /^(.*)\.Z/ ) {
        $uncompressed = $1;
        eval{ system( "cp -f $file temp.cif.Z; $uncompress temp.cif.Z" ); };
        if ( ! $@ ) {
            &parse( "temp.cif", $file );
        }
        else {
            print LOG "Could not uncompress $file\n";
        }
    }
    else {
        &parse( $file, $file );
    }
}

eval{ system( "/bin/rm -f temp.cif" ); };
 
$date = `date`;
print LOG "Finished parsing: $date";

close LOG;        
exit(0);

sub parse {

    if ( $opt_s ) {
        $size = -s "$_[0]";
        if ( $size > ( $opt_s * 1048576 ) ) {
            print LOG "File $_[1] ($size bytes uncompressed) exceeds $opt_s MB size limit\n";
            return;
        }
    }

    eval { ( $data ) = STAR::Parser->parse(-file=>$_[0]); };

    if ( $@ ) {
        print LOG "Could not parse $_[1]\n";
        return;
    }
    else {
        print LOG "Parsed $_[1]\n";
        if ( $opt_f ) {
            eval { $filtered = STAR::Filter->filter_through_dict(-data=>$data, -dict=>$dict); };
            if ( $@ ) {
                print LOG "Could not filter $_[0]\n";
                return;
            }
            else {
                $filtered->store( "$opt_o/$id.cob" );
            }
        }
        else {
            $data->store( "$opt_o/$id.cob" );
        }
    }

    if ( $opt_c ) {
        eval{ system( "$compress $opt_o/$id.cob" ); };
        if ( $@ ) {
            print LOG "Could not compress $opt_o/$id.cob\n";
        }
    }
    return;
}
               
    
