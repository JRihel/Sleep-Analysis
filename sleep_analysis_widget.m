%Sleep Analysis Widget

% THe purpose of this script is to input a specific window of data to be
% analyzed from the sleep_analysis_2020 code. This will ask for the window,
% which you must manually provide then spit out summary data for that
% window



% Requirement: Place a .mat file to analyze into Perl Batch
% Folder2\Analysis_Window

function window=sleep_analysis_widget()

files = dir('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_window');

for zzz = 1:length(files); 
    if files(zzz).isdir == 0;

%determining the names of files for each run
%determining the names of genotype file for each run-- ASSUMES FORMAT:
%YYMMDD_BBgenotype.txt

filename = files(zzz).name;
load(filename)
    end
end
clear zzz files 

%for i=1:length(geno.data)
%plot(nanmean(geno.data{i}'))
%hold on
%end
%ylabel('Activity per minute')
%xlabel('Minutes')

%Creating the prompt and assessing the starting and ending points to pull

startP = string('Start');
endP=string('End');
mess = [startP; endP];

dlgtitle = 'Inspect the Graph and Input the start time and end time to analyze';
dims = [1 80];
answer = inputdlg(mess,dlgtitle,dims);
startend = answer;
startW=str2num(startend{1});
endW=str2num(startend{2});

%Now use those to grab the data from all the slots:

for i=1:length(geno.data)

window.name{i}=geno.name{i};
window.fishID{i}=geno.fishID{i};
window.zeitgeber=geno.zeitgeber(startW:endW);
window.time=geno.time(startW:endW);
window.counter=geno.counter(startW:endW);
window.lightschedule=geno.lightschedule(startW:endW);
window.lightboundries=geno.lightboundries(startW:endW);
window.daynumber=geno.daynumber(startW:endW);
window.nightnumber=geno.nightnumber(startW:endW);
window.data{i}=geno.data{i}(startW:endW,:);
window.sleep{i}=geno.sleep{i}(startW:endW,:);
window.sleepconinuity{i}=geno.sleepcontinuity{i}(startW:endW,:);
window.sleepboutstart{i}=geno.sleepboutstart{i}(startW:endW,:);
window.sleepends{i}=geno.sleepends{i}(startW:endW,:);
window.sleeplatencyO{i}=geno.sleeplatency{i}(startW:endW,:);
window.avewaking{i}=geno.avewaking{i}(startW:endW,:);
window.wake{i}=geno.wake{i}(startW:endW,:);
window.wakeconinuity{i}=geno.wakecontinuity{i}(startW:endW,:);
window.wakeboutstart{i}=geno.wakeboutstart{i}(startW:endW,:);
window.wakeends{i}=geno.wakeends{i}(startW:endW,:);
end

% I also want to calculate the sleepLatency from the start of the window:
for i=1:length(geno.data)
    for j=1:length(window.sleep{i}(1,1:end));
        window.sleeplatencyS{i}(:,j)= [1; zeros(length(window.zeitgeber)-1,1)];
       for k = 1: length(window.sleep{i})-1; 
            if window.sleeplatencyS{i}(k,j)==1;
                if window.sleep{i}(k+1,j) ==0;
                   window.sleeplatencyS{i}(k+1,j) = 1;
                end
            end
        end
    end
end

%Now, I collect summary stats within this window:

for i=1:length(geno.data);
        window.summarytable.sleep{i} = nansum(geno.sleep{i}(startW:endW,:));
        window.summarytable.sleepBout{i} = nansum(geno.sleepboutstart{i}(startW:endW,:));
        window.summarytable.sleepLengthmedian{i} = nanmedian(geno.sleepends{i}(startW:endW,:));
        window.summarytable.sleepLengthmean{i} = nanmean(geno.sleepends{i}(startW:endW,:));
        window.summarytable.sleepLatencyO{i} = nansum(geno.sleeplatency{i}(startW:endW,:));
        window.summarytable.sleepLatencyS{i} = nansum(window.sleeplatencyS{i});
        window.summarytable.wakeBout{i}= nansum(geno.wakeboutstart{i}(startW:endW,:));   
        window.summarytable.wakeLengthmedian{i} = nanmedian(geno.wakeends{i}(startW:endW,:));
        window.summarytable.wakeLengthmean{i} = nanmean(geno.wakeends{i}(startW:endW,:));
        window.summarytable.averageActivity{i} = nanmean(geno.data{i}(startW:endW,:));
        window.summarytable.averageWaking{i}= nanmean(geno.avewaking{i}(startW:endW,:));
end 
mkdir(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_window\',filename(1:9),'\'));
save(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_window\',filename(1:9),'\',filename(1:9),'_window.mat'),'window')

% Now to make all the plots and stats

% First, I will plot all the summary stats, To do that, I need to create
% strings that put all the data into one vector:
window.stats.sleep=[];
window.stats.sleepBout=[];
window.stats.sleepLength=[];
window.stats.sleepLatencyO=[];
window.stats.sleepLatencyS=[];
window.stats.wakeBout=[];
window.stats.wakeLength=[];
window.stats.averageActivity=[];
window.stats.averageWaking=[];

window.Genomask=[];
for i=1:length(window.data)
window.Genomask=[window.Genomask i*ones(1,length(window.data{i}(1,:)))];    
        window.stats.sleep=[window.stats.sleep window.summarytable.sleep{i}];
        window.stats.sleepBout=[window.stats.sleepBout window.summarytable.sleepBout{i}];
        window.stats.sleepLength=[window.stats.sleepLength window.summarytable.sleepLengthmedian{i}];
        window.stats.sleepLatencyO=[window.stats.sleepLatencyO window.summarytable.sleepLatencyO{i}];
        window.stats.sleepLatencyS=[window.stats.sleepLatencyS window.summarytable.sleepLatencyS{i}];
        window.stats.wakeBout=[window.stats.wakeBout window.summarytable.wakeBout{i}];
        window.stats.wakeLength=[window.stats.wakeLength window.summarytable.wakeLengthmedian{i}];
        window.stats.averageActivity=[window.stats.averageActivity window.summarytable.averageActivity{i}];
        window.stats.averageWaking=[window.stats.averageWaking window.summarytable.averageWaking{i}];    
end



%To make plotting easier, I put this all into one matrix: 

window.AllData=[window.stats.sleep' window.stats.sleepBout' window.stats.sleepLength' window.stats.sleepLatencyO' window.stats.sleepLatencyS' window.stats.wakeBout' window.stats.wakeLength' window.stats.averageActivity' window.stats.averageWaking']; 

for i=1:9
window.pvalue(i)=anovan(window.AllData(:,i),{window.Genomask})
end

Variablenames(1)=string('sleep Total-min');
Variablenames(2)=string('sleep Bout number');
Variablenames(3)=string('sleepLength-min');
Variablenames(4)=string('sleepLatencyO-min');
Variablenames(5)=string('sleepLatencyS-min');
Variablenames(6)=string('wakeBout number');
Variablenames(7)=string('wakeLength-min');
Variablenames(8)=string('ave Activity-sec');
Variablenames(9)=string('ave Wake Activity-sec');

colorspectra= [57/255 106/255 177/255;218/255 124/255 48/255;62/255 150/255 81/255;204/255 37/255 41/255;83/255 81/255 84/255;107/255 76/255 154/255;146/255 36/255 40/255;148/255 139/255 61/255;148/255 139/255 61/255;148/255 139/255 61/255];

for i=1:length(window.data)
legendname(i) = cellstr(cell2mat(window.name{i}));
end

for i=1:9
    figure;plotSpread(window.AllData(:,i),'categoryIdx',window.Genomask,'showMM',4,'distributionIdx',window.Genomask,'categoryColors',colorspectra(1:length(window.data),:))
    ax = gca;
    ax.XTickLabel=legendname;
    title(strcat(Variablenames(i),'-',filename(1:6),'-',filename(8:9),'window'),'FontSize',10) 
    ylabel(Variablenames(i),'FontSize',14)
    A=axis;
    ylim([0,A(4)]);
    fg = gcf;
    for j=1:2+length(window.data)
        fg.Children.Children(j).MarkerSize=20;
        fg.Children.Children(j).LineWidth=2
    end
    hgsave(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_window\',filename(1:9),'\',filename(1:9), Variablenames(i),'_window.fig'))
close
end

save(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_window\',filename(1:9),'\',filename(1:9),'_window.mat'),'window')
clear ans
end