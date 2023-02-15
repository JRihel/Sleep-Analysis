% Created May, 2011
% This is a brand new program that simplifies and expands the sleep
% analysis, to 1) be streamlined in one function 2) expand the stats 3)
% batch everything together in one step.

% UPDATE-- May 23rd, 2011;  It appears that the function works to produce
% the activity and sleep traces along with an extensive table

% NOTES:  To use this program: 

% 1) the Perl Batch Folder2\output folder
% requires the data in the format YYMMDD_BB_DATA.txt, which is the file
% output created by the perl_batch_combo.m file

% 2) For each file, there must be a genotype file in the Perl Batch
% Folder2\Genotype_lists in the format YYMMDD_BBgenotype.txt  The name must
% match the file in the output folder file.


function geno=sleep_analysis2020()

%First, there is no reason to force the user to import the listname, the
%filename, and the cam type.  These could all be easily determined by the
%program.  

%Lookup all the filenames
files = dir('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output');

%Create an overarching loop that will systematically scan through each
%file in the output directory
a=0;
for zzz = 1:length(files); 
    if files(zzz).isdir == 0;

%determining the names of files for each run
%determining the names of genotype file for each run-- ASSUMES FORMAT:
%YYMMDD_BBgenotype.txt

filename = files(zzz).name;
listname = strcat(filename(1:9),'genotype.txt');

%importing the genotype list data from the genotype_lists folder
%importing the data from the PERL script manipulated file
dataset = importdata(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\', filename), '\t',2); %090102_15_DATA.txt','\t',2);
gridmap = importdata(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Genotype_lists\', listname),'\t',2); %090102_15_genotype.txt','\t',2);
    
%___ This next part is unchanged from the original analysis, as it splits the data into timed and genotyped structures

% This loop 1) looks up how many columns there are (i.e. how many
% genotypes/conditions 2) imports the name into a file called geno.name 3)
% imports the data based on which well #s are located in the genotype list

for i=1:length(gridmap.data(1,1:end));
    geno.name{i} = gridmap.textdata(2,i);    
    geno.data{i} = dataset.data(:,gridmap.data(find(~isnan(gridmap.data(:,i))),i)+ 2);
end

% I need to save the information from the gridmap for fish ID #
for i =1:length(gridmap.data(1,1:end));
    geno.fishID{i} = gridmap.data(find(~isnan(gridmap.data(:,i))),i);
end
% No matter how many wells there are, if you used the PERL script, the clock
% will always be the last column, and is corrected so that 0 is normal lights
% ON = 9AM

geno.zeitgeber = dataset.data(:,end);

% These are additional useful timestamps == the day number from the start of
% experiment and the day-night timestamp of 0 for day 1 for night (based on
% lights on = 0, lights off = 14 in the zeitgeber stamp

%2020 Update: I notice that the timing of this appears to be off the L:D
%transition by one minute in this case. That is because of the one
%minute binning, which can 'bridge' the actual L:D transition. How to
%adjust this depends on when the timestamp is relative to the actual one minute mark. In this case, it is 33 seconds in
% Probably the best way to handle this is simply to bin everything tighter,
% say in 5 or 10 second bins. That should still be manageable data size.
% For now, I readjust to 13.9833 which is equal to 59 minutes,
% so, the transition is in that minute

geno.lightschedule = geno.zeitgeber;
geno.lightschedule(find(geno.zeitgeber < 24)) = 1;
geno.lightschedule(find(or(geno.zeitgeber < 13.9833,geno.zeitgeber >23.9833))) = 0;

% This method gets the first dark transition correct, but is misses the
% first light transition by one minute becuase of rounding. e.g. 23.992
% will capture the transition state but will still be greater than 13.992
% What if I sweep over both boundries:


% For calculating the daynight data, I first make a counter of minutes from
% start of experiment, convert that to hours, and divide and floor by 24
% 2020 Update: This method of calculating the daynumber is off by one
% minute. That is because when I calculate geno.time, I add it to the
% geno.zeitgeber of the first value, but that will shift it by 1.


for j = 0:length(geno.lightschedule)-1
    geno.time(j+1) = j + 1;
end

    geno.time = geno.time/60;
% Now I calculate the day number by dividing the geno.time by 24 flooring it

%geno.daynumber = floor((geno.zeitgeber(1)+geno.time)/24)+1;

% There is a simpler way to calculate what I want: simply make the loop for
% geno.time start at geno.zeitgeber(1), then add 1/60 each round:

%Update: the geno.counter is useful for aligning the graphs

geno.counter(1)=geno.zeitgeber(1);
for j= 2:length(geno.lightschedule)
geno.counter(j)=geno.counter(j-1)+(1/60);
end

% Because of little timestamp glitches, this is off by a tiny amount 0.0003
% hour. That is much better than my older code. Now: (23.991 is a way to put the 23.992 data into the next day, since the lights go on for about 30 seconds) 

%geno.daynumber = floor((geno.counter)/24)+1;

% This is also not great, because it drifts relative to the transitions of
% the light dark cycle. I think better is to build the daynumber from the
% lightschedule data directly, so they will never be in conflict. To do
% that, I will use the diff function to find the transition points and use
% this: 
clear DIFF
DIFF=diff(geno.lightschedule)';
DIFF=[DIFF(1) DIFF];
daycount=1;
nightcount=0;
for i=1:length(geno.lightschedule)
   if DIFF(i)==-1
       daycount=daycount+1;
   end
   if DIFF(i)==1
       nightcount=nightcount+1;
   end
   geno.daynumber(i)=daycount;
   geno.nightnumber(i)=nightcount;
end
% May 7, 2020-- The code is now aligned perfectly up to here



% Step 2-- Now I am ready, for each genotype, to calculate the various day/night
%graphs, this will be substantially updated to include more graphs, to plot
%them in the same chart for ease of reading, and will include stats
%analysis to compare genotypes with ANOVAs. 

% I used to calculate the important measures, then generate the graphs;
% now, to ease the rewrite, I am moving the graph making to the end of the
% initial calculations

%graphic 1- 10 minute data trace
% it loops through A) all genotypes B) all
% columns C) all rows and sums by groups of 10
for i = 1:length(gridmap.data(1,1:end));
    for j = 1:length(geno.data{i}(1,1:end))
        for q = 10:10:length(geno.data{i})
            geno.tenminute{i}(q/10,j) = sum(geno.data{i}(q-9:q,j));
        
        end
    end
    
end
% geno.tenminute data needs a timestamp. Simply take every 10 minutes from
% the geno.time and adjust by adding the startvalue
geno.tenminutetime = geno.time(10:10:end)+ geno.zeitgeber(1);

% Now, the data is ready to be plotted on a 10 minute graph


% Making the 10 minute sleep chart
% First, the data needs to be converted into a string of 1s and 0s/ for
% when they are sleeping or not.
for i = 1:length(gridmap.data(1,1:end));
    geno.sleep{i} = geno.data{i};
    geno.sleep{i}(find(geno.data{i} > 0.1)) = 0;
    geno.sleep{i}(find(geno.data{i} <= 0.1)) = 1;    
% And converts it into a 10 minute chart    
    for j = 1:length(geno.sleep{i}(1,1:end))
        for q = 10:10:length(geno.sleep{i})
            geno.sleepchart{i}(q/10,j) = sum(geno.sleep{i}(q-9:q,j));
        end
    end
end
% I also need to work out the bout breakpoints, allowing me to count the
% number of bouts and the length of the bouts. The following loop creates
% the sleep contunuity chart, which can be used to derive the # bouts and
% the average sleep lengths
% continuity is an increase of 1 for each sleep bout, such that long bouts
% are long strings of increasing numbers
% sleep bout start is a 1 marking the start of each sleep bout
% sleep latency is a string of 1s from the start of each time period to the first sleep bout
for i = 1:length(gridmap.data(1,1:end));
    geno.sleepcontinuity{i} = geno.sleep{i};
       for j = 1:length(geno.sleep{i}(1,1:end));                                                     
            for k = 2: length(geno.sleep{i}(:,1));
                if geno.sleep{i}(k,j) == 1;
                    if geno.sleep{i}(k-1,j) == 0
                       geno.sleepcontinuity{i}(k,j) = 1;
                    end
                    if geno.sleep{i}(k-1,j) == 1
                        z = 1 + geno.sleepcontinuity{i}(k-1,j);
                        geno.sleepcontinuity{i}(k,j) = z;
                    end
                end
            end
       end
    geno.sleepboutstart{i} = geno.sleepcontinuity{i};
    geno.sleepboutstart{i}(find(geno.sleepcontinuity{i} > 1)) = 0;
end
% I now cut everything except the sleepbout end values:

for i = 1:length(gridmap.data(1,1:end));
    geno.sleepends{i} = geno.sleepcontinuity{i};
       for j = 1:length(geno.sleepcontinuity{i}(1,1:end));                                                     
            for k = 1: length(geno.sleepcontinuity{i}(:,1))-1;
                if geno.sleepcontinuity{i}(k,j) > 0;
                    if geno.sleepcontinuity{i}(k+1,j) > 0
                       geno.sleepends{i}(k,j) = NaN;
                    end                     
                end
                if geno.sleepcontinuity{i}(k,j) == 0;
                    geno.sleepends{i}(k,j) = NaN;
                end
            end
             if geno.sleepcontinuity{i}(length(geno.sleepcontinuity{i}(:,1)),j) == 0;
                    geno.sleepends{i}(length(geno.sleepcontinuity{i}(:,1)),j) = NaN;
             end
       end

end


% Now I work out sleeplatency, first by marking the light:dark boundries
    geno.lightboundries = geno.lightschedule;
    for q = 2:length(geno.lightboundries)
        if geno.lightschedule(q) == geno.lightschedule(q-1)
            geno.lightboundries(q) = 0;
        end
        if geno.lightschedule(q) ~= geno.lightschedule(q-1)
            geno.lightboundries(q) = 1;
        end
    end
    geno.lightboundries(1) = 1;
% and then by filling in 1s as long as the fish is moving
 
            for i = 1:length(gridmap.data(1,1:end));
    for j = 1:length(geno.sleep{i}(1,1:end));                                                     
            geno.sleeplatency{i}(:,j) = geno.lightboundries;  
            for k = 1: length(geno.sleep{i})-1;   
                if geno.sleeplatency{i}(k,j) == 1;
                    if geno.sleep{i}(k+1,j) == 0;
                        geno.sleeplatency{i}(k+1,j) = 1;
                    end    
                end    
            end
       end
            end
            
% Now I make the 10 minute average waking activity chart
% It first looks for the 0s and converts it to NaNs
for i = 1:length(gridmap.data(1,1:end));
    geno.avewaking{i} = geno.data{i};
    geno.avewaking{i}(find(geno.data{i} == 0)) = NaN;
       
% And converts it into a 10 minute chart    
    for j = 1:length(geno.avewaking{i}(1,1:end))
        for q = 10:10:length(geno.avewaking{i})
            geno.avewakechart{i}(q/10,j) = nanmean(geno.avewaking{i}(q-9:q,j));
        end
    end
end
% All the above sections remain unchanged, as these pull out critical
% features of the dataset.
% However, I wish to carve the data in two ways-- measure the waking
% continuity, and to carve up the sleep bout and wake bout lengths as
% distrubitions per fish, e.g. 

for i = 1:length(gridmap.data(1,1:end));
geno.wake{i}=geno.sleep{i}
geno.wake{i}(find(geno.sleep{i}==1))=0;
geno.wake{i}(find(geno.sleep{i}==0))=1;
end

for i = 1:length(gridmap.data(1,1:end));
    geno.wakecontinuity{i} = geno.wake{i};
       for j = 1:length(geno.wake{i}(1,1:end));                                                     
            for k = 2: length(geno.wake{i}(:,1));
                if geno.wake{i}(k,j) == 1;
                    if geno.wake{i}(k-1,j) == 0
                       geno.wakecontinuity{i}(k,j) = 1;
                    end
                    if geno.wake{i}(k-1,j) == 1
                        z = 1 + geno.wakecontinuity{i}(k-1,j);
                        geno.wakecontinuity{i}(k,j) = z;
                    end
                end
            end
       end
    geno.wakeboutstart{i} = geno.wakecontinuity{i};
    geno.wakeboutstart{i}(find(geno.wakecontinuity{i} > 1)) = 0;
end

for i = 1:length(gridmap.data(1,1:end));
    geno.wakeends{i} = geno.wakecontinuity{i};
       for j = 1:length(geno.wakecontinuity{i}(1,1:end));                                                     
            for k = 1: length(geno.wakecontinuity{i}(:,1))-1;
                if geno.wakecontinuity{i}(k,j) > 0;
                    if geno.wakecontinuity{i}(k+1,j) > 0
                       geno.wakeends{i}(k,j) = NaN;
                    end
                    
                end
                if geno.wakecontinuity{i}(k,j) == 0;
                   geno.wakeends{i}(k,j) = NaN;
                end
            end
            if geno.wakecontinuity{i}(length(geno.wakecontinuity{i}(:,1)),j) == 0;
                    geno.wakeends{i}(length(geno.wakecontinuity{i}(:,1)),j) = NaN;
             end
       end

end

%2020 Note: the code appears to perform correctly to here.


%Now I make the graphs into near publishable and also detailed formats from the start:
% I will call on shadedErrorBar.m, which will be required for this part.

mkdir(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\'));
% First, Making the Average Activity Plot, Smoothed
figure
hold on
legendData=[];
colorspectra= [57/255 106/255 177/255;218/255 124/255 48/255;62/255 150/255 81/255;204/255 37/255 41/255;83/255 81/255 84/255;107/255 76/255 154/255;146/255 36/255 40/255;148/255 139/255 61/255;148/255 139/255 61/255;148/255 139/255 61/255];
%Note-- I got the optimized colorwheel from the Internet for good color separation.

for i = 1:length(gridmap.data(1,1:end));
    if i<=8
    Act{i}=shadedErrorBar(geno.counter,smooth(nanmean(geno.data{i}'),60),smooth(nanstd(geno.data{i}')./sqrt(length(geno.data{i}(1,:))),60),{'LineWidth',1,'Color',colorspectra(i,:)});
    end
    if i>8
    Act{i}=shadedErrorBar(geno.counter,smooth(nanmean(geno.data{i}'),60),smooth(nanstd(geno.data{i}')./sqrt(length(geno.data{i}(1,:))),60),{'LineWidth',1,'Color',colorspectra(8,:)});  
    end
    
    legendData=[legendData,Act{i}.mainLine]
    legendname(i) = cellstr(cell2mat(geno.name{i}));
end

ax = gca;
ax.FontSize = 16; 
xlabel('Zeitgeber Time (Hours)','FontSize',16)
ylabel('Average Activity (s/min)','FontSize',16)
xlim([geno.zeitgeber(1) max(geno.counter)])
pbaspect([max(geno.daynumber) max(geno.daynumber)./2 1])
title(strcat('Average Activity--file:',filename(1:6),'-',filename(8:9)),'FontSize',12) 
legend(legendData,legendname)

% Add black-white boundries to the borders
L=[];
L=find(geno.lightboundries==1);
L=[L; length(geno.counter)];
y=ylim;
for l=2:2:(length(L)-1)
R=rectangle('Position',[geno.counter(L(l)) (y(2)-0.5) (geno.counter(L(l+1))-geno.counter(L(l))) 0.5],'Facecolor',[0 0 0],'Edgecolor',[0 0 0]);
uistack(R,'bottom')
end

for l=1:2:(length(L)-1)
R=rectangle('Position',[geno.counter(L(l)) (y(2)-0.5) (geno.counter(L(l+1))-geno.counter(L(l))) 0.5],'Facecolor',[1 1 1],'Edgecolor',[0 0 0]);
uistack(R,'bottom')
end

%2020 Update-- Graph looks great. Legend is fixed. Bars are not obtrusive.   
hgsave(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),' activity ribbon.fig'))
close
% Same graph for Waking Activity: 
figure
hold on
legendData=[];

for i = 1:length(gridmap.data(1,1:end));
    if i<=8
    Wak{i}=shadedErrorBar(geno.counter,smooth(nanmean(geno.avewaking{i}'),60),smooth(nanstd(geno.avewaking{i}')./sqrt(length(geno.avewaking{i}(1,:))),60),{'LineWidth',1,'Color',colorspectra(i,:)});
    end
    if i>8
    Wak{i}=shadedErrorBar(geno.counter,smooth(nanmean(geno.avewaking{i}'),60),smooth(nanstd(geno.avewaking{i}')./sqrt(length(geno.avewaking{i}(1,:))),60),{'LineWidth',1,'Color',colorspectra(8,:)});  
    end
    
    legendData=[legendData,Wak{i}.mainLine];
    legendname(i) = cellstr(cell2mat(geno.name{i}));
end

ax = gca;
ax.FontSize = 16; 
xlabel('Zeitgeber Time (Hours)','FontSize',16)
ylabel('Waking Activity (s/min)','FontSize',16)
xlim([geno.zeitgeber(1) max(geno.counter)])
pbaspect([max(geno.daynumber) max(geno.daynumber)./2 1])
title(strcat('Waking Activity--file:',filename(1:6),'-',filename(8:9)),'FontSize',12) 
legend(legendData,legendname)

% Add black-white boundries to the borders
L=[];
L=find(geno.lightboundries==1);
L=[L; length(geno.counter)];
y=ylim;
for l=2:2:(length(L)-1)
R=rectangle('Position',[geno.counter(L(l)) (y(2)-0.5) (geno.counter(L(l+1))-geno.counter(L(l))) 0.5],'Facecolor',[0 0 0],'Edgecolor',[0 0 0]);
uistack(R,'bottom')
end

for l=1:2:(length(L)-1)
R=rectangle('Position',[geno.counter(L(l)) (y(2)-0.5) (geno.counter(L(l+1))-geno.counter(L(l))) 0.5],'Facecolor',[1 1 1],'Edgecolor',[0 0 0]);
uistack(R,'bottom')
end

%2020 Update-- Graph looks great. Legend is fixed. Bars are not obtrusive.   
hgsave(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),' waking ribbon.fig'))
close
% And Sleep

figure
hold on
legendData=[];

for i = 1:length(gridmap.data(1,1:end));
    if i<=8
    Sle{i}=shadedErrorBar(geno.tenminutetime,smooth(nanmean(geno.sleepchart{i}'),6),smooth(nanstd(geno.sleepchart{i}')./sqrt(length(geno.sleepchart{i}(1,:))),6),{'LineWidth',1,'Color',colorspectra(i,:)});
    end
    if i>8
    Sle{i}=shadedErrorBar(geno.tenminutetime,smooth(nanmean(geno.sleepchart{i}'),6),smooth(nanstd(geno.sleepchart{i}')./sqrt(length(geno.sleepchart{i}(1,:))),6),{'LineWidth',1,'Color',colorspectra(8,:)}) ;   
    end
    
    legendData=[legendData,Sle{i}.mainLine];
    legendname(i) = cellstr(cell2mat(geno.name{i}));
end

ax = gca;
ax.FontSize = 16; 
xlabel('Zeitgeber Time (Hours)','FontSize',16)
ylabel('Sleep (minutes/10min)','FontSize',16)
xlim([geno.zeitgeber(1) max(geno.counter)])
pbaspect([max(geno.daynumber) max(geno.daynumber)./2 1])
title(strcat('Sleep--file:',filename(1:6),'-',filename(8:9)),'FontSize',12) 
legend(legendData,legendname)

% Add black-white boundries to the borders. I need to define new boundries
% for the ten minute plot
L=[];
L=find(geno.lightboundries==1);
L(2:end)=floor(L(2:end)/10);
L=[L; length(geno.tenminutetime)];
y=ylim;
for l=2:2:(length(L)-1)
R=rectangle('Position',[geno.tenminutetime(L(l)) (y(2)-0.5) (geno.tenminutetime(L(l+1))-geno.tenminutetime(L(l))) 0.5],'Facecolor',[0 0 0],'Edgecolor',[0 0 0]);
uistack(R,'bottom')
end

for l=1:2:(length(L)-1)
R=rectangle('Position',[geno.tenminutetime(L(l)) (y(2)-0.5) (geno.tenminutetime(L(l+1))-geno.tenminutetime(L(l))) 0.5],'Facecolor',[1 1 1],'Edgecolor',[0 0 0]);
uistack(R,'bottom')
end

%2020 Update-- Graph looks great. Legend is fixed. Bars are not obtrusive.   
hgsave(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),' sleep ribbon.fig'))
close
%2020 Update-- Also plot the mean traces for sleep and activity for each
%fish, each genotype. This will allow for a rapid spotting of any animals
%that are immobile and should have been excluded from the analysis and will
%give more information about the variety of behaviors. 

for i=1:length(gridmap.data(1,1:end));
    figure;
    hold on
    for j=1:length(geno.data{i}(1,:))
    if i<=8
    plot(geno.counter,smooth(geno.data{i}(:,j)',60),'Color',colorspectra(i,:),'LineWidth',0.1)
    end
    if i>8
    plot(geno.counter,smooth(geno.data{i}(:,j)',60),'Color',colorspectra(8,:),'LineWidth',0.1)
    end
    
    
    end
    if i<8
    plot(geno.counter,smooth(nanmean(geno.data{i}'),60),'Color',colorspectra(i+1,:),'LineWidth',5)
    end
    if i>=8
    plot(geno.counter,smooth(nanmean(geno.data{i}'),60),'Color',colorspectra(8,:),'LineWidth',5)
    end
ax = gca;
ax.FontSize = 16; 
xlabel('Zeitgeber Time (Hours)','FontSize',16)
ylabel('Average Activity (s/min)','FontSize',16)
xlim([geno.zeitgeber(1) max(geno.counter)])
pbaspect([max(geno.daynumber) max(geno.daynumber)./2 1])
title(strcat('Average Activity-',geno.name{i},' (file:',filename(1:6),'-',filename(8:9),')'),'FontSize',10)
% Add black-white boundries to the borders
L=[];
L=find(geno.lightboundries==1);
L=[L; length(geno.counter)];
y=ylim;
for l=2:2:(length(L)-1)
R=rectangle('Position',[geno.counter(L(l)) (y(2)-0.5) (geno.counter(L(l+1))-geno.counter(L(l))) 0.5],'Facecolor',[0 0 0],'Edgecolor',[0 0 0]);
uistack(R,'bottom')
end

for l=1:2:(length(L)-1)
R=rectangle('Position',[geno.counter(L(l)) (y(2)-0.5) (geno.counter(L(l+1))-geno.counter(L(l))) 0.5],'Facecolor',[1 1 1],'Edgecolor',[0 0 0]);
uistack(R,'bottom')
end
label=num2str(i);
hgsave(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),' all_act_ribbon-',label,'.fig'))
close
end

%And all the Sleep traces
for i=1:length(gridmap.data(1,1:end));
    figure;
    hold on
    for j=1:length(geno.sleepchart{i}(1,:))
    
    if i<=8    
    plot(geno.tenminutetime,smooth(geno.sleepchart{i}(:,j)',6),'Color',colorspectra(i,:),'LineWidth',0.1)
    end
    if i>8    
    plot(geno.tenminutetime,smooth(geno.sleepchart{i}(:,j)',6),'Color',colorspectra(8,:),'LineWidth',0.1)
    end
    
    
    end
    if i<8
    plot(geno.tenminutetime,smooth(nanmean(geno.sleepchart{i}'),6),'Color',colorspectra(i+1,:),'LineWidth',5)
    end
    if i>=8
    plot(geno.tenminutetime,smooth(nanmean(geno.sleepchart{i}'),6),'Color',colorspectra(8,:),'LineWidth',5)
    end
ax = gca;
ax.FontSize = 16; 
xlabel('Zeitgeber Time (Hours)','FontSize',16)
ylabel('Sleep (minutes/10min)','FontSize',16)
xlim([geno.zeitgeber(1) max(geno.counter)])
pbaspect([max(geno.daynumber) max(geno.daynumber)./2 1])
title(strcat('Sleep-',geno.name{i},' (file:',filename(1:6),'-',filename(8:9),')'),'FontSize',10)
L=[];
L=find(geno.lightboundries==1);
L(2:end)=floor(L(2:end)/10);
L=[L; length(geno.tenminutetime)];
y=ylim;
for l=2:2:(length(L)-1)
R=rectangle('Position',[geno.tenminutetime(L(l)) (y(2)-0.5) (geno.tenminutetime(L(l+1))-geno.tenminutetime(L(l))) 0.5],'Facecolor',[0 0 0],'Edgecolor',[0 0 0]);
uistack(R,'bottom')
end

for l=1:2:(length(L)-1)
R=rectangle('Position',[geno.tenminutetime(L(l)) (y(2)-0.5) (geno.tenminutetime(L(l+1))-geno.tenminutetime(L(l))) 0.5],'Facecolor',[1 1 1],'Edgecolor',[0 0 0]);
uistack(R,'bottom')
end
label=num2str(i);
hgsave(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),' all_sleep_ribbon-',label,'.fig'))
close  
end 

% This bit adds data to the database, for easy lookup. I've put the code
% here to allow for the graphs to be produced before saving to the
% database (if errors, wont prematurely add to the list).
database = importdata('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\RawDatabase3.xls');
%
for l = 1:(10-length(geno.name));
    newline{length(geno.name)+1+l} = '';
end
clear l
%
newline{1} = filename(1:9);
for l = 1:(length(geno.name));
newline{1+l} = char(geno.name{l});
end
clear l
database = [database; newline];
xlswrite('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\RawDatabase3.xls',database)
clear database
clear newline

% 2020 Update. I want to take the summary data for the day and night and
% calculate this more carefully as well. For one thing, the table format I
% used previously is not bad, although it adds an extra night line because
% it goes in a loop for the max of the day number-- but the total number of
% day and night periods can never be the same, unless you stop the tracking
% exactly at the transition point. That glitch has always led to some
% annoyances. 

%Solution-- Calculate the night number the same way you calculate the
%daynumber: See above. Now use two loops, one for the day, one for the
%night;

%Problem-- Sleep lengths were calculated as an average, and very lazy. But
%this data is not normally distributed, so should be handled differently.
%Certainly the median value is more important, as will be distributions. 
%Same for wakebout lengths. 

%Solution-- Mark the sleepboutends like the sleepboutstarts. Then find the
%values at those sleepboutends

for i=1:length(gridmap.data(1,1:end));
    for j = 1:max(geno.daynumber)
        for k = 1:length(geno.fishID{i})
        geno.summarytable.sleep.day{i}(j,k) = nansum(geno.sleep{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 0)),k));
        geno.summarytable.sleepBout.day{i}(j,k) = nansum(geno.sleepboutstart{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 0)),k));
        geno.summarytable.sleepLengthmedian.day{i}(j,k) = nanmedian(geno.sleepends{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 0)),k));
        geno.summarytable.sleepLengthmean.day{i}(j,k) = nanmedian(geno.sleepends{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 0)),k));
        geno.summarytable.sleepLatency.day{i}(j,k)=nansum(geno.sleeplatency{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 0)),k));
        geno.summarytable.wakeBout.day{i}(j,k)=nansum(geno.wakeboutstart{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 0)),k));   
        geno.summarytable.wakeLengthmedian.day{i}(j,k) = nanmedian(geno.wakeends{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 0)),k));
        geno.summarytable.wakeLengthmean.day{i}(j,k) = nanmean(geno.wakeends{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 0)),k));
        geno.summarytable.averageActivity.day{i}(j,k)=nanmean(geno.data{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 0)),k));
        geno.summarytable.averageWaking.day{i}(j,k)=nanmean(geno.avewaking{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 0)),k));
        
        end 
    end
end

for i=1:length(gridmap.data(1,1:end));
    for j = 1:max(geno.nightnumber)
        for k = 1:length(geno.fishID{i})
        geno.summarytable.sleep.night{i}(j,k) = nansum(geno.sleep{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 1)),k));
        geno.summarytable.sleepBout.night{i}(j,k)=nansum(geno.sleepboutstart{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 1)),k));   
        geno.summarytable.sleepLengthmedian.night{i}(j,k) = nanmedian(geno.sleepends{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 1)),k));
        geno.summarytable.sleepLengthmean.night{i}(j,k) = nanmean(geno.sleepends{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 1)),k));
        geno.summarytable.sleepLatency.night{i}(j,k)=nansum(geno.sleeplatency{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 1)),k));
        geno.summarytable.wakeBout.night{i}(j,k)=nansum(geno.wakeboutstart{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 1)),k));   
        geno.summarytable.wakeLengthmedian.night{i}(j,k) = nanmedian(geno.wakeends{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 1)),k));
        geno.summarytable.wakeLengthmean.night{i}(j,k) = nanmean(geno.wakeends{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 1)),k));
        geno.summarytable.averageActivity.night{i}(j,k)=nanmean(geno.data{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 1)),k));
        geno.summarytable.averageWaking.night{i}(j,k)=nanmean(geno.avewaking{i}(intersect(find(geno.daynumber == j),find(geno.lightschedule == 1)),k));
           
        end 
    end
end

% 2020 Update-- Seems more accurate than my older methods up to here. The

% I will index this within geno.sleepStructure and geno.wakeStructure as
% follows: geno.sleepStructure{genotype}.day{number}.fish{each fish}, etc.

    for i=1:length(gridmap.data(1,1:end));
        for j = 1:max(geno.nightnumber)
            for k = 1:length(geno.fishID{i})
            geno.sleepStructure{i}.night{j}.fish{k}=geno.sleepends{i}(intersect(intersect(find(geno.daynumber == j),(find(geno.lightschedule == 1))),find(~isnan(geno.sleepends{i}(:,k)))),k)
            end
        end
    end
    
    for i=1:length(gridmap.data(1,1:end));
        for j = 1:max(geno.daynumber)
            for k = 1:length(geno.fishID{i})
            geno.sleepStructure{i}.day{j}.fish{k}=geno.sleepends{i}(intersect(intersect(find(geno.daynumber == j),(find(geno.lightschedule == 0))),find(~isnan(geno.sleepends{i}(:,k)))),k)
            end
        end
    end
% Now I have an indexed SleepBout Structure. Do the same for the wakebouts.
for i=1:length(gridmap.data(1,1:end));
        for j = 1:max(geno.nightnumber)
            for k = 1:length(geno.fishID{i})
            geno.wakeStructure{i}.night{j}.fish{k}=geno.wakeends{i}(intersect(intersect(find(geno.daynumber == j),(find(geno.lightschedule == 1))),find(~isnan(geno.wakeends{i}(:,k)))),k)
            end
        end
    end
    
    for i=1:length(gridmap.data(1,1:end));
        for j = 1:max(geno.daynumber)
            for k = 1:length(geno.fishID{i})
            geno.wakeStructure{i}.day{j}.fish{k}=geno.wakeends{i}(intersect(intersect(find(geno.daynumber == j),(find(geno.lightschedule == 0))),find(~isnan(geno.wakeends{i}(:,k)))),k)
            end
        end
    end
save(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),'.mat'),'geno')

%2020 Update to here-- Looks fine, although the order of geno could be
%improved for ease of reading it


% 2020-- Make graphs of day and night sleep distrubtions for each:    
    for i=1:length(gridmap.data(1,1:end))
        geno.SleepSortNight{i}=[];
        for j=1:length(geno.sleepStructure{i}.night)
            for k=1:length(geno.sleepStructure{i}.night{j}.fish)
            C= geno.sleepStructure{i}.night{j}.fish{k};
            geno.SleepSortNight{i}=[geno.SleepSortNight{i}; C];
            clear C
            end
        end
    end
    
    for i=1:length(gridmap.data(1,1:end))
        geno.SleepSortDay{i}=[];
        for j=1:length(geno.sleepStructure{i}.day)
            for k=1:length(geno.sleepStructure{i}.day{j}.fish)
            C= geno.sleepStructure{i}.day{j}.fish{k};
            geno.SleepSortDay{i}=[geno.SleepSortDay{i}; C];
            clear C
            end
        end
    end
    
    
    for i=1:length(gridmap.data(1,1:end))
        geno.WakeSortNight{i}=[];
        for j=1:length(geno.wakeStructure{i}.night)
            for k=1:length(geno.wakeStructure{i}.night{j}.fish)
            C= geno.wakeStructure{i}.night{j}.fish{k};
            geno.WakeSortNight{i}=[geno.WakeSortNight{i}; C];
            clear C
            end
        end
    end

  for i=1:length(gridmap.data(1,1:end))
        geno.WakeSortDay{i}=[];
        for j=1:length(geno.wakeStructure{i}.day)
            for k=1:length(geno.wakeStructure{i}.day{j}.fish)
            C= geno.wakeStructure{i}.day{j}.fish{k};
            geno.WakeSortDay{i}=[geno.WakeSortDay{i}; C];
            clear C
            end
        end
  end
%Note-- Because some wake bouts (but almost never sleep bouts) bridge
%across the light:dark divide, the WakeBouts at day and night do not
%perfectly total the SleepBout at day and night; however, the sum across
%all these appears correct-- as in, every minute is accounted for as a
%bout.
    for i=1:length(gridmap.data(1,1:end))
    sleephistD{i}=histcounts(geno.SleepSortDay{i},max(geno.SleepSortDay{i}))
    wakehistD{i}=histcounts(geno.WakeSortDay{i},max(geno.WakeSortDay{i}))
    sleephistN{i}=histcounts(geno.SleepSortNight{i},max(geno.SleepSortNight{i}))
    wakehistN{i}=histcounts(geno.WakeSortNight{i},max(geno.WakeSortNight{i}))
    end
    
    figure;hold on
    for i=1:length(gridmap.data(1,1:end))
        if i<=8
        plot(sleephistD{i}/sum(sleephistD{i}),'LineWidth',2,'Color',colorspectra(i,:))
        end
        if i>8
        plot(sleephistD{i}/sum(sleephistD{i}),'LineWidth',2,'Color',colorspectra(8,:))
        end
    end
    [~,p,~]=kstest2(sleephistD{1},sleephistD{end});
    geno.KSdist(1)=p;
    ax = gca;
    ax.FontSize = 16; 
    xlabel('Sleep Length(minutes)','FontSize',16)
    ylabel('Frequency','FontSize',16)
    title(strcat('histSleepDay-file:',filename(1:6),'-',filename(8:9),'; KSp=',num2str(round(p,2))),'FontSize',10) 
    legend(legendname)
    hgsave(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),' SleepDistDay.fig'))
    close
    
    figure;hold on
    for i=1:length(gridmap.data(1,1:end))
    
        if i<=8
        plot(sleephistN{i}/sum(sleephistN{i}),'LineWidth',2,'Color',colorspectra(i,:))
        end
        if i>8
        plot(sleephistN{i}/sum(sleephistN{i}),'LineWidth',2,'Color',colorspectra(8,:))
        end
            
    end
    
    
    [~,p,~]=kstest2(sleephistN{1},sleephistN{end});
    geno.KSdist(2)=p;
    ax = gca;
    ax.FontSize = 16; 
    xlabel('Sleep Length(minutes)','FontSize',16)
    ylabel('Frequency','FontSize',16)
    title(strcat('histSleepNight-file:',filename(1:6),'-',filename(8:9),'; KSp=',num2str(round(p,2))),'FontSize',10) 
    legend(legendname)
    hgsave(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),' SleepDistNight.fig'))
    close
    
    figure;hold on
    for i=1:length(gridmap.data(1,1:end))
    
        if i<=8
        plot(wakehistD{i}/sum(wakehistD{i}),'LineWidth',2,'Color',colorspectra(i,:))
        end
        if i>8
        plot(wakehistD{i}/sum(wakehistD{i}),'LineWidth',2,'Color',colorspectra(8,:))
        end
        
    end
    [~,p,~]=kstest2(wakehistD{1},wakehistD{end});
    geno.KSdist(3)=p;
    ax = gca;
    ax.FontSize = 16; 
    xlabel('Wake Length(minutes)','FontSize',16)
    ylabel('Frequency','FontSize',16)
    title(strcat('histWakeDay-file:',filename(1:6),'-',filename(8:9),'; KSp=',num2str(round(p,2))),'FontSize',10) 
    legend(legendname)
    hgsave(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),' WakeDistDay.fig'))
    close
    
    figure;hold on
    for i=1:length(gridmap.data(1,1:end))
        if i<=8
        plot(wakehistN{i}/sum(wakehistN{i}),'LineWidth',2,'Color',colorspectra(i,:))
        end
        if i>8
        plot(wakehistN{i}/sum(wakehistN{i}),'LineWidth',2,'Color',colorspectra(8,:))
        end
        
        
    end
    [~,p,~]=kstest2(wakehistN{1},wakehistN{end});
    geno.KSdist(4)=p;
    ax = gca;
    ax.FontSize = 16; 
    xlabel('Wake Length(minutes)','FontSize',16)
    ylabel('Frequency','FontSize',16)
    title(strcat('histWakeNight-file:',filename(1:6),'-',filename(8:9),'; KSp=',num2str(round(p,2))),'FontSize',10) 
    legend(legendname)
    hgsave(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),' WakeDistNight.fig'))
    close
    %The KS stat actually does a good job finding the difference in sleep bout
%structure between the genotypes. 
    
%2020update-- Now, to make all the comparison graphs. Maybe best is to make
%all the comparison graphs, no matter what, and for the
%significant/interesting datasets, move those graphs into a different
%folder. 

%I also still want to make some summary table, with data for each fish
%across all the parameters, as well

% And for later, make fingerprints and mesh with previous data.


% OK, Now I want to loop over all the day/night data and construct a table
% for these in a variable manner as needed:

for j=1:max(geno.daynumber)
geno.stats.sleepday{j}=[];
geno.stats.sleepBoutday{j}=[];
geno.stats.sleepLengthday{j}=[];
geno.stats.sleepLatencyday{j}=[];
geno.stats.wakeBoutday{j}=[];
geno.stats.wakeLengthday{j}=[];
geno.stats.averageActivityday{j}=[];
geno.stats.averageWakingday{j}=[];
end
Genomask=[];
for i=1:length(gridmap.data(1,1:end))
Genomask=[Genomask i*ones(1,length(geno.data{i}(1,:)))];
    for j=1:(max(geno.daynumber))

        geno.stats.sleepday{j}=[geno.stats.sleepday{j} geno.summarytable.sleep.day{i}(j,:)];
        geno.stats.sleepBoutday{j}=[geno.stats.sleepBoutday{j} geno.summarytable.sleepBout.day{i}(j,:)];
        geno.stats.sleepLengthday{j}=[geno.stats.sleepLengthday{j} geno.summarytable.sleepLengthmedian.day{i}(j,:)];
        geno.stats.sleepLatencyday{j}=[geno.stats.sleepLatencyday{j} geno.summarytable.sleepLatency.day{i}(j,:)];
        geno.stats.wakeBoutday{j}=[geno.stats.wakeBoutday{j} geno.summarytable.wakeBout.day{i}(j,:)];
        geno.stats.wakeLengthday{j}=[geno.stats.wakeLengthday{j} geno.summarytable.wakeLengthmedian.day{i}(j,:)];
        geno.stats.averageActivityday{j}=[geno.stats.averageActivityday{j} geno.summarytable.averageActivity.day{i}(j,:)];
        geno.stats.averageWakingday{j}=[geno.stats.averageWakingday{j} geno.summarytable.averageWaking.day{i}(j,:)];
    end
end
        
for j=1:max(geno.nightnumber)
geno.stats.sleepnight{j}=[];
geno.stats.sleepBoutnight{j}=[];
geno.stats.sleepLengthnight{j}=[];
geno.stats.sleepLatencynight{j}=[];
geno.stats.wakeBoutnight{j}=[];
geno.stats.wakeLengthnight{j}=[];
geno.stats.averageActivitynight{j}=[];
geno.stats.averageWakingnight{j}=[];
end

for i=1:length(gridmap.data(1,1:end))

    for j=1:(max(geno.nightnumber))

        geno.stats.sleepnight{j}=[geno.stats.sleepnight{j} geno.summarytable.sleep.night{i}(j,:)];
        geno.stats.sleepBoutnight{j}=[geno.stats.sleepBoutnight{j} geno.summarytable.sleepBout.night{i}(j,:)];
        geno.stats.sleepLengthnight{j}=[geno.stats.sleepLengthnight{j} geno.summarytable.sleepLengthmedian.night{i}(j,:)];
        geno.stats.sleepLatencynight{j}=[geno.stats.sleepLatencynight{j} geno.summarytable.sleepLatency.night{i}(j,:)];
        geno.stats.wakeBoutnight{j}=[geno.stats.wakeBoutnight{j} geno.summarytable.wakeBout.night{i}(j,:)];
        geno.stats.wakeLengthnight{j}=[geno.stats.wakeLengthnight{j} geno.summarytable.wakeLengthmedian.night{i}(j,:)];
        geno.stats.averageActivitynight{j}=[geno.stats.averageActivitynight{j} geno.summarytable.averageActivity.night{i}(j,:)];
        geno.stats.averageWakingnight{j}=[geno.stats.averageWakingnight{j} geno.summarytable.averageWaking.night{i}(j,:)];
    end
end  
% Now I merge this into a huge array, sort the variable names as strings
% in an array, and then array2table to make 

for j=1:max(geno.daynumber)
geno.daytable(:,j)=geno.stats.sleepday{j}';
geno.daytable(:,j+max(geno.daynumber))=geno.stats.sleepBoutday{j}';
geno.daytable(:,j+2*max(geno.daynumber))=geno.stats.sleepLengthday{j}';
geno.daytable(:,j+3*max(geno.daynumber))=geno.stats.sleepLatencyday{j}';
geno.daytable(:,j+4*max(geno.daynumber))=geno.stats.wakeBoutday{j}';
geno.daytable(:,j+5*max(geno.daynumber))=geno.stats.wakeLengthday{j}';
geno.daytable(:,j+6*max(geno.daynumber))=geno.stats.averageActivityday{j}';
geno.daytable(:,j+7*max(geno.daynumber))=geno.stats.averageWakingday{j}';
end

for j=1:max(geno.nightnumber)
geno.nighttable(:,j)=geno.stats.sleepnight{j}';
geno.nighttable(:,j+max(geno.nightnumber))=geno.stats.sleepBoutnight{j}';
geno.nighttable(:,j+2*max(geno.nightnumber))=geno.stats.sleepLengthnight{j}';
geno.nighttable(:,j+3*max(geno.nightnumber))=geno.stats.sleepLatencynight{j}';
geno.nighttable(:,j+4*max(geno.nightnumber))=geno.stats.wakeBoutnight{j}';
geno.nighttable(:,j+5*max(geno.nightnumber))=geno.stats.wakeLengthnight{j}';
geno.nighttable(:,j+6*max(geno.nightnumber))=geno.stats.averageActivitynight{j}';
geno.nighttable(:,j+7*max(geno.nightnumber))=geno.stats.averageWakingnight{j}';
end
geno.fulltable=[geno.daytable geno.nighttable];

%Loop to create the variable names: 
for j=1:max(geno.daynumber)
Variablenamesday(j)=string(strcat('sleepTotalday',num2str(j)));
Variablenamesday(j+max(geno.daynumber))=string(strcat('sleepBoutday',num2str(j)));
Variablenamesday(j+2*max(geno.daynumber))=string(strcat('sleepLengthday',num2str(j)));
Variablenamesday(j+3*max(geno.daynumber))=string(strcat('sleepLatencyday',num2str(j)));
Variablenamesday(j+4*max(geno.daynumber))=string(strcat('wakeBoutday',num2str(j)));
Variablenamesday(j+5*max(geno.daynumber))=string(strcat('wakeLengthday',num2str(j)));
Variablenamesday(j+6*max(geno.daynumber))=string(strcat('aveActday',num2str(j)));
Variablenamesday(j+7*max(geno.daynumber))=string(strcat('aveWakeday',num2str(j)));

end

for j=1:max(geno.nightnumber)
Variablenamesnight(j)=string(strcat('sleepTotalnight',num2str(j)));
Variablenamesnight(j+max(geno.nightnumber))=string(strcat('sleepBoutnight',num2str(j)));
Variablenamesnight(j+2*max(geno.nightnumber))=string(strcat('sleepLengthnight',num2str(j)));
Variablenamesnight(j+3*max(geno.nightnumber))=string(strcat('sleepLatencynight',num2str(j)));
Variablenamesnight(j+4*max(geno.nightnumber))=string(strcat('wakeBoutnight',num2str(j)));
Variablenamesnight(j+5*max(geno.nightnumber))=string(strcat('wakeLengthnight',num2str(j)));
Variablenamesnight(j+6*max(geno.nightnumber))=string(strcat('aveActnight',num2str(j)));
Variablenamesnight(j+7*max(geno.nightnumber))=string(strcat('aveWakenight',num2str(j)));

end

GenotypeT=table(string(Genomask'),'VariableNames',string('Genotype'))
geno.fullvariabletable=[Variablenamesday Variablenamesnight];
geno.analysistable=array2table(geno.fulltable,'VariableNames',geno.fullvariabletable)
geno.analysistable=[GenotypeT geno.analysistable]
%factors=table([(1:width(geno.analysistable)-1)]','VariableNames',{'Measures'});
factors=table(geno.fullvariabletable','VariableNames',{'Measures'});
%lme = fitlme(geno.analysistable,strcat('Genotype + sleepTotalday1-aveWakenight',num2str(max(geno.nightnumber))))
rm = fitrm(geno.analysistable,strcat('sleepTotalday1-aveWakenight',num2str(max(geno.nightnumber)),'~Genotype'),'WithinDesign',factors)
%[test1,stats,stats2]=ranova(rm)
geno.ranova = multcompare(rm,'Genotype','By','Measures')
save(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),'.mat'),'geno')
%This gave me the output I wanted.

% One issue is the Measures are given twice, in alphabetical order of the
% measures, so I need to be careful about indexing the pvalues from
% geno.ranova to make the graphs: I create an index of each measure and the
% pvalues. I will then use the measureindex to find the data to graph.
%Update-- No, it is only given twice IF there are only two genotypes; but
%if there are more, the table is more complex, showing pairwise
%data. 

%I need to group by n*(n-1) values, determine if any of those are p<0.06,
%then plot the graph, with the p value of the lowest measure for the top of
%the graph. 
% This is correct:
geno.measureindex=table2array(geno.ranova(1:length(geno.data)*(length(geno.data)-1):end,{'Measures'}))
% Now I will grab all the p values
geno.pvalue=table2array(geno.ranova(1:end,{'pValue'}))
% Loop in chunks of the data
p=0;
q=0;

for i = 1:(length(geno.data)*(length(geno.data)-1)):length(geno.pvalue)
    q=q+1;
    if min(geno.pvalue(i:i+(length(geno.data)*(length(geno.data)-1))-1))<0.05
        p=p+1;
        geno.significant(p,1)=geno.measureindex(q);
        geno.significant(p,2)=min(geno.pvalue(i:i+(length(geno.data)*(length(geno.data)-1))-1));      
    end
end
if min(geno.pvalue>0.05)
    geno.significant=[];
end

% Now, Genomask gives me the map of the genotypes, and geno.analysistable
% has all the lookups I need, headed by the data in measureindex.
% I need to loop over chunks of the data for each measurement 

%geno.significant(:,1)=geno.measureindex(find(geno.pvalue <0.06))
%geno.significant(:,2)=geno.pvalue(find(geno.pvalue <0.06))
% Now I look through the significant Measures and grab the data from that
% table column:
if isempty(geno.significant)==0;
    for i=1:length(geno.significant(:,1))

    geno.sigData(:,i)=table2array(geno.analysistable(:,geno.significant(i,1)));

    end

% This builds a Table of values that are significant, with each column
% representing a measure. So, now I just need to use the GenoMask and each
% column of data to generate dabest plots one at a time.
% Using PlotSpread, I can use this format to plot:

for i=1:length(geno.significant(:,1))
    figure;plotSpread(geno.sigData(:,i),'categoryIdx',Genomask,'showMM',4,'distributionIdx',Genomask,'categoryColors',colorspectra(1:length(geno.data),:))
    ax = gca;
    ax.XTickLabel=legendname;
    title(strcat(geno.significant(i,1),'-',filename(1:6),'-',filename(8:9),'; p=',num2str(round(str2num(geno.significant(i,2)),2))),'FontSize',10) 
    ylabel(geno.significant(i,1),'FontSize',14)
    A=axis;
    ylim([0,A(4)]);
    fg = gcf;
    for j=1:2+length(geno.data)
        fg.Children.Children(j).MarkerSize=20;
        fg.Children.Children(j).LineWidth=2
    end
    hgsave(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),'sig-', geno.significant(i,1),'.fig'))
close
end
end



save(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\Analysis_output\',filename(1:end-9),'\',filename(1:end-9),'.mat'),'geno')
movefile(strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\',files(zzz).name),strcat('C:\Users\Jason Rihel\Documents\Perl Batch Folder2\output\output ran\',files(zzz).name)) 

    
end % The end of the isdir loop
    clear a A Act ax dataset daycount DIFF factors fg filename geno Genomask GenotypeT gridmap h i j k l L label legendData legendname listname nightcount p q R rm sigData Sle sleephistD sleephistN stats Variablenamesday Variablenamesnight Wak wakehistD wakehistN y  

end  % The end of the files loop

% Don't forget to check if the analysis will handle properly more than two
% genotypes.

 
% I also want to put the data into a database that will grow with each
% iteration.  I think the data from the sleep table is sufficient for a
% database.  One problem-- the data could be mismatched if there are
% different numbers of days and nights.  One solution-- just preallocate the
% database size to allow up to maybe 5 days, fill in with NaNs when there is no data


