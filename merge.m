% This m-file takes the data that has been split into two parts (usually
% becuase of alignment issues) and puts them together into one file for
% analysis

% UPDATE: Oct 15, 2012--merge was in wrong order slightly, putting finished
% product into the trash.
% Jason Jason Rihel on 12/1/08
function merge()
files = dir('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output');
tic
for i = 1:length(files);
    
    if files(i).isdir ==0;
        if strcat(files(i).name(10)) == 'p' 
            copyfile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(i).name),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name));
            copyfile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(i).name(1:9),files(i).name(11:end)),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:9),files(i).name(11:end)));
            N  = importdata(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name),'\t', 2);
            dlmwrite(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:9),files(i).name(11:end)),N.data,'-append','delimiter','\t')
            clear N
            
            movefile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(i).name),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\merged parts\',files(i).name))
            movefile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(i).name(1:9),files(i).name(11:end)),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\merged parts\',files(i).name(1:9),files(i).name(11:end)))     
            
            movefile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:9),files(i).name(11:end)),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(i).name(1:9),'_DATA.txt'))
            
            delete(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name));
            %delete(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\',files(i).name(1:9),files(i).name(11:end)));
        end
    end
end
toc
end
