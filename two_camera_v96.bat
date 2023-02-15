@echo off
rem Don't print rem lines!

rem This script will take data for 192 fish, where each set of 96 fish
rem was viewed with the camera for 60 seconds at a time.
rem It will split it into 12 files.
rem For each set of 96 fish, there will be files for the
rem count and duration of burst, freeze, and mid-range motion.
rem $Revision: 1.2 $, checked in $Date: 2012/09/01 16:31:04 $

rem Input file is start_data_sample.txt (but could be changed - it's at
rem the end of the first "perl" line below)

rem Get rid of all lines where empty duration > 5 (scriptome tool)
rem (Lines where the camera wasn't really watching those fish)
rem [change input filename on next line if desired]
perl -ne "BEGIN {$col=3; $limit=17;}" -e "BEGIN {$count=0} s/\r?\n//; @F=split /\t/, $_; if ($F[$col] < $limit) {$count++; print qq~$_\n~} END {warn qq~Chose $count lines out of $.\n~}" %1 > %1.limit17

rem this is an attempted fix to make the problem with first 1 second data go away
rem Get rid of the first lines when there is a problem with the 1 second script (if the data is a 1 second expt, throws out first 5 seconds-ah, but it loses the header!)
perl -ne "BEGIN {$col=7; $limit=5;}" -e "BEGIN {$count=0} s/\r?\n//; @F=split /\t/, $_; if ($F[$col] > $limit) {$count++; print qq~$_\n~} END {warn qq~Chose $count lines out of $.\n~}" %1.limit17 > %1.limit5

rem But I need to get back the header!

rem Remove 'w0' or 'c' from c158 etc. on every line

perl -ne "s/^w|c//; print $_" %1.limit5 > %1.no_c
REM perl -ne "s/-//; print $_" %1.no_a > %1.no_c
rem perl -ne "s/^w00//; print $_" %1.limit5 > %1.no_c
rem perl -ne "s/^w0//; print $_" %1.limit5 > %1.no_c
rem perl -ne "s/^c//; print $_" %1.limit5 > %1.no_c

rem Take the lines with the first 96 fish (new location line has < 96.1)
rem This gets the header line also; 2013 Update-- No, now header is lost!
perl -ne "BEGIN {$col=0; $limit=96.1;}" -e "BEGIN {$count=0} s/\r?\n//; @F=split /\t/, $_; if ($F[$col] < $limit) {$count++; print qq~$_\n~} END {warn qq~Chose $count lines out of $.\n~}" %1.no_c > %1.first_96.txt

rem Take the lines with the LAST 96 fish (new location line has < 96.1)
rem No header line here
perl -ne "BEGIN {$col=0; $limit=96.1;}" -e "BEGIN {$count=0} s/\r?\n//; @F=split /\t/, $_; if ($F[$col] > $limit) {$count++; print qq~$_\n~} END {warn qq~Chose $count lines out of $.\n~}" %1.no_c > %1.last_96.txt


rem Get the header line back for last 96 fish
perl -ne "if ($. ==1) {print $_; exit}" %1 > %1.header
perl -ne "print $_" %1.header %1.last_96.txt > %1.last_96h.txt
perl -ne "print $_" %1.header %1.first_96.txt > %1.first_96h.txt

rem Run the perl script to break each file into 6 sub-files
rem of the various counts and durations
perl sort_fish_sttime_96.pl %1.first_96h.txt 
perl sort_fish_sttime_96.pl %1.last_96h.txt