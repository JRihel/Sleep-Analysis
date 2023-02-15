% Sept 2012 Update:  Program is to handle new Zebrabox tracking 192 fish at
% once.  I will pull apart the data into two boxes.

% This is a brand new program that simplifies the sleep
% analysis, to 1) be streamlined in one function 2) expand the stats 3)
% batch everything together in one step.

function perl_batch_192()

% Step 1: getting the files from the "files to run" folder and converting them
% This is similar to the perl_batch_files, except that now it will
% determine the camera type to use and will move the files out of the file to run folder into a dated folder

% NAMING CONVENTION IS CHANGED-- 
% two boxes:  YYMMDD_BB_BB.XLS
%           or YYMMDD_BBp_BBp.XLS
% one box:  YYMMDD_BB.XLS
%           or YYMMDD_BBp.XLS

files = dir('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Files to Run');
tic
for i = 1:length(files); 

    if files(i).isdir == 0;
        
% This loop looks for two-camera files
if length(files(i).name) > 15;
copyfile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Files to Run\',files(i).name),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:end-3),'txt'))
status = dos(strcat('two_camera_v96.bat "',files(i).name(1:end-3),'txt"'))

   if strcat(files(i).name(10)) == '_'
    movefile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:end-3),'txt.first_96h_middur.txt'),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(i).name(1:10),'DATA.txt'))
    movefile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:end-3),'txt.last_96h_middur.txt'),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(i).name(1:7),files(i).name(11:12),'_DATA.txt'))
    end

    if strcat(files(i).name(10)) == 'p'
    movefile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:end-3),'txt.first_96h_middur.txt'),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(i).name(1:11),'DATA.txt'))
    movefile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:end-3),'txt.last_96h_middur.txt'),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(i).name(1:7),files(i).name(12:14),'_DATA.txt'))
    end

delete(strcat(files(i).name(1:end-3),'txt.limit5'))
delete(strcat(files(i).name(1:end-3),'txt.limit17'))
delete(strcat(files(i).name(1:end-3),'txt.first_96.txt'))
delete(strcat(files(i).name(1:end-3),'txt.first_96h.txt'))
delete(strcat(files(i).name(1:end-3),'txt.first_96h_burct.txt'))
delete(strcat(files(i).name(1:end-3),'txt.first_96h_burdur.txt'))
delete(strcat(files(i).name(1:end-3),'txt.first_96h_frect.txt'))
delete(strcat(files(i).name(1:end-3),'txt.first_96h_fredur.txt'))
delete(strcat(files(i).name(1:end-3),'txt.first_96h_midct.txt'))
delete(strcat(files(i).name(1:end-3),'txt.header'))
delete(strcat(files(i).name(1:end-3),'txt.last_96.txt'))
delete(strcat(files(i).name(1:end-3),'txt.last_96h.txt'))
delete(strcat(files(i).name(1:end-3),'txt.last_96h_burct.txt'))
delete(strcat(files(i).name(1:end-3),'txt.last_96h_burdur.txt'))
delete(strcat(files(i).name(1:end-3),'txt.last_96h_frect.txt'))
delete(strcat(files(i).name(1:end-3),'txt.last_96h_fredur.txt'))
delete(strcat(files(i).name(1:end-3),'txt.last_96h_midct.txt'))
delete(strcat(files(i).name(1:end-3),'txt.no_c'))
delete(strcat(files(i).name(1:end-3),'txt'))
end

% This loop looks for 1 camera files WARNING-- NAMING CONVENTION IS NOW CHANGED
% This is CODE FOR THE CURRENT BOX 3.
if length(files(i).name) < 15;
  copyfile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Files to Run\',files(i).name),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:end-3),'txt'))
status = dos(strcat('perl sort_fish_sttime_96.pl "',files(i).name(1:end-3),'txt"'))

if strcat(files(i).name(10)) == '.'
movefile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:end-4),'_middur.txt'),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(i).name(1:9),'_DATA.txt'))
end

if strcat(files(i).name(10)) == 'p'
movefile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:end-4),'_middur.txt'),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(i).name(1:10),'_DATA.txt'))
end

delete(strcat(files(i).name(1:end-4),'_burct.txt'))
delete(strcat(files(i).name(1:end-4),'_burdur.txt'))
delete(strcat(files(i).name(1:end-4),'_frect.txt'))
delete(strcat(files(i).name(1:end-4),'_fredur.txt'))
delete(strcat(files(i).name(1:end-4),'_midct.txt'))
delete(strcat(files(i).name(1:end-3),'txt'))
    end
end    
%
end
toc

% And a short loop to clear all Files to Run to Files Ran folder
for i = 1:length(files); 

   if files(i).isdir == 0;
    movefile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Files to Run\',files(i).name),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Files Ran\',files(i).name))
    end
end
% Now run the merge program to clean up the output files; (No longer cals 
merge
% At the end, the files should have been moved into the Files Ran folder,
% and there should be several _DATA files in the output folder ready to be
% analyzed with the sleep analysis tool
end
 


















