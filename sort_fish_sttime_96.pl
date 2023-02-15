#!/usr/local/bin/perl

# Get data for sleeping fish
# Output each kind of duration (burst, mid, freeze) to a separate file

# Call this file like
#    sort_fish input_file.txt
# where the only argument needed is the file from the robot
# The input file must end in '.txt'

# $Revision: 1.6 $, checked in $Date: 2005/11/01 16:41:29 $

use warnings;
use strict;

use IO::File;

my $Num_Fish = 96;

my ($infile) = @ARGV;
my $Usage = "sort_fish.pl input_file.txt\n";
die "Must get an input file\n$Usage\n" unless defined $infile;

my $rows_printed = "";
my %Fish_Info = ();

# Make six output files. e.g., sample1.txt -> sample1_burct.txt
# Open up filehandles for each file so we can print to them.
my %filehandles = ();
my $out_head = $infile;
$out_head =~ s/\.txt$// or die "Input file must have '.txt' at the end\n";
foreach my $data_type (qw(burdur burct fredur frect middur midct)) {
    my $filename = $out_head . "_" . $data_type . ".txt";
    my $fh = new IO::File ("> $filename");
    if (!defined $fh) {
	die "Couldn't open file $filename for writing: $!\n";
    }
    $filehandles{$data_type} = $fh;
}

# Get the headers in the first line
my $first_line = <>; $first_line =~ s/\r?\n//;
my @headers = split "\t", $first_line;

# Now read every line and pull in the data
# We print data to six different files for the different data types.
# Things like tabs and column headers go to every file.
# The duration/count values go to only one file.
my $line_count = 0;
my $did_header = "";
while(<>) {
    my $line = $_;
    $line =~ s/\r?\n//;
    my @cols = split "\t", $line;
    my %values;
    @values{@headers} = @cols;
    my ($location, $start, $end) = @values{qw(location start end)};

    # Two versions of output files have slightly different column header names
    my $sttime;
    if (exists $values{time}) {
	$sttime = $values{time};
    }
    elsif (exists $values{sttime}) {
	$sttime = $values{sttime};
    }
    else {
	die "Didn't find a 'time' OR a 'sttime' column in the first line\n";
    }

#    print "$location $start $end $burdur $sttime\n";
#   $location =~ s/^w0*// or die "Unexpected location name '$location'\n";

    # Store the 6 kinds of data for this fish
    foreach my $data_type (keys %filehandles) {
#	my $fh = $filehandles{$data_type};
#	print $fh $values{$data_type};
	$Fish_Info{$location}{$data_type} = $values{$data_type};
    }


    $line_count++;

    # Last line for this start/end pair? 
    if ($line_count % $Num_Fish == 0) {

	# If we've just read the first 96 fish, then we need to
	# print out the header, whose column names are the fish numbers
	if (! $did_header) {
	    # First header line of output
	    &print_to_all_filehandles("TIME(SECONDS)\t");
	    foreach my $fish (sort {$a <=> $b} keys %Fish_Info) {
		&print_to_all_filehandles("\tFISH$fish");
	    }
	    &print_to_all_filehandles("\t\t\tCLOCK\n");

	    # Second header line for output
	    &print_to_all_filehandles("start\tend");
	    foreach my $data_type(keys %filehandles) {
		my $fh = $filehandles{$data_type};
		foreach my $fish (1 .. scalar(keys %Fish_Info)) {
		    print $fh "\t$data_type";
		}
	    }
	    &print_to_all_filehandles("\t\t\t\n");

	    # Make sure we don't print the header twice
	    $did_header = 1;

	}

	# Print start and end time for this pair
	&print_to_all_filehandles("$start\t$end\t");

	# Print the list of all 96 fish values for a certain time
	# into each of the 6 files
	foreach my $data_type (keys %filehandles) {
	    my $fh = $filehandles{$data_type};
	    foreach my $fish (sort {$a <=> $b} keys %Fish_Info) {
		print $fh "$Fish_Info{$fish}{$data_type}\t";
	    }
	}

	# Now calculate and print the time for the set of measurements
	my ($h, $m, $s) = split ":", $sttime;
	my $decimal = $h + $m/60 + $s/3600;
	# Can't use '%' modulus operator, since it returns an integer
	my $mdecimal = $decimal - 9;
	if ($mdecimal < 0) {$mdecimal += 24}
	my $sdecimal = sprintf("%16.3f", $mdecimal);
#	print "H M S decimal mdec are $h $m $s $decimal $sdecimal\n";
	&print_to_all_filehandles("\t\t$sdecimal\n");
	$rows_printed++;
    }

}

print "Printed out $line_count lines to six files with $rows_printed rows each\n";
die"ERROR: Number of rows printed x Number of fish isn't Number of lines read\n"
    unless $rows_printed * scalar(keys %Fish_Info) == $line_count;

foreach my $d (keys %filehandles) {
    my $fh = $filehandles{$d};
    close $fh;
}

########################
sub print_to_all_filehandles {
    my ($to_print) = @_;
    foreach my $data_type (keys %filehandles) {
	my $fh = $filehandles{$data_type};
	print $fh $to_print;
    }
}

