%% AFMPD Data Export Tool
% *Description* - Analysis of Intervals  and saving their means
% It takes the Ergebnis.mat and the raw data file from the same folder and
% saves the means of the intervals in a text file
%
% *Inputs required* : Raw data .dat file and the intervals as files not
% arguments.
% Other m-files required: none
% Subfunctions: none
% MAT-files required: Intervals.mat % Generated from Interval_selection.m file
%
% *Author* : Akash Mankar
% * _IRS University of Stuttgrt / BarcelonaTech_ *
% 10 May 2018
%------------- BEGIN CODE --------------
function Data_Export
clc; close all; clearvars;
%% Preamble/Loading data and Declaration Stuff
% Loading interval data from Intervals.mat file, this is generated using the other m file
if exist([pwd, filesep, 'Intervals.mat'],'file')
    load('Intervals.mat');
else
    disp('Intervals selection doesnt exist, please use Interval_Selection.m')
    errordlg('No intervals data found, first select intervals using Interval_selection.m','No Intervals');
    return
end


% Variable used for selecting the row from the Intervals.mat that needs
% analysis, for testing now it has more than one rows, if files will be
% copied to each folder separately for easier analysis then it should be
% changed to 1 as Intervals.mat will only have one row.
vnum=1;

%% Excel Output Filename
% 
%  Change the output filename
%  Use commented filename code to choose any name
%  Keep the current code for rawdata filename and _outdata.xlsx at end

%filename = 'outdata4.xlsx';
[pathstr, name, ext] = fileparts(Versuch.Dateiname);
filename = strcat(name,'_outdata.xlsx');

%% UX
% *UI to browse the raw data file as input*
[FileName,PathName,FilterIndex] = uigetfile('.dat');

% loading the raw data from the expirement
M=importdata(Versuch(vnum).Dateiname);
%M=importdata([PathName,FileName]);

%% Gathering all the channel names from the rawdata
head=cell(5,1);
for i=1:5
    head(i)=textscan(M.textdata{i+4,1},'%s','delimiter',':');
end
head=vertcat(head{:});
headxls=head(2:end)';

%% Channel Definations
% *Define here thrust and calibration channel* , both are same
% _1. Schubmessung/thrust measurement_
IndexSch = find(contains(head,'Kraftsensor [uE]'));           % Replace here the channel name without the colon(:)
% _2.Kalibration/Calibration_
IndexKalib = find(contains(head,'Kraftsensor [uE]'));         % Replace here the channel name without the colon(:)
% _5. Diverses/Misc_
%IndexMisc = find(contains(head,'Gas A [mg/s]'));        % Replace here the channel name without the colon(:)

% If the file doesn't have regular channel names, setting averaging loop to
% time channel(Zeit) to throw garbage average value, so that user can
% understand he needs to set the channel definiations.
if(IndexSch==0)
    errordlg('No channel data found for thrust, make sure you define the channel you want to average in the Channel Defination section','No channel in raw data!');
    IndexSch=1;
end
if(IndexKalib==0)
    errordlg('No channel data found for calibration, make sure you define the channel you want to average in the Channel Defination section','No channel in raw data!');
    IndexSch=1;
end


%% Extracting Means from Raw Data file out to outdata struct
% Setting flag defaults to run the averaging loops
noSchubFlag=0;noKalibFlag=0;noMessDataFlag=0;noMiscFlag=0;
% checking if user was lazy enough to set experiment condition's interval,
% setting it to length of raw data, so whole raw data file can be
% processed.
if(isempty(Versuch.Versuchsdatengrenzen))
    Versuch.Versuchsdatengrenzen=[1 length(M.data(:,1))];
end
if(isempty(Versuch.Kalibration))
    noKalibFlag=1;  % no calibration intervals selected
end
if(isempty(Versuch.Schubmessung))
    noSchubFlag=1;  % no thrust measurement intervals selected
end
if(isempty(Versuch.Messdaten))
    noMessDataFlag=1; % no measurement data intervals selected
end
if(isempty(Versuch.Diverses))
    noMiscFlag=1;    % no Misc intervals selected %this interval is obsolete
end

if(~noSchubFlag)
    % looping withing number of intervals selected for Messdaten from
    % Intervals.mat
    % looping withing number of intervals selected for Schubmessung from
    % Intervals
    for i=1:size(Versuch(vnum).Schubmessung,1)
        % Creating a vertical array with the mean data for each of the selected
        % intervals
        % i loops through intervals
        for jj=1:size(Versuch(vnum).Versuchsdatengrenzen,1)
            if(Versuch(vnum).Schubmessung(i,1)>Versuch(vnum).Versuchsdatengrenzen(jj,1) && Versuch(vnum).Schubmessung(i,2)<Versuch(vnum).Versuchsdatengrenzen(jj,2))
                outnum=jj;
            end
        end
        outdata(outnum).schub(i,1)=M.data(Versuch(vnum).Schubmessung(i,1));
        outdata(outnum).schub(i,2)=M.data(Versuch(vnum).Schubmessung(i,2));
        outdata(outnum).schub(i,3)=(mean(M.data(Versuch(vnum).Schubmessung(i,1):Versuch(vnum).Schubmessung(i,2),IndexSch)));
    end
end

if(~noKalibFlag)
    % looping withing number of intervals selected for Kalibration from
    % Intervals.mat
    for i=1:size(Versuch(vnum).Kalibration,1)
        % Creating a vertical array with the mean data for each of the selected
        % intervals
        % Force sensor channel is searched automatically, if channel name
        % changes, change it in *Channel Defination* section above.
        %

        % this loop checks the expirement conditions and save the data in
        % different array of the outdata depending on the interval
        for jj=1:size(Versuch(vnum).Versuchsdatengrenzen,1)
            if(Versuch(vnum).Kalibration(i,1)>Versuch(vnum).Versuchsdatengrenzen(jj,1) && Versuch(vnum).Kalibration(i,2)<Versuch(vnum).Versuchsdatengrenzen(jj,2))
                outnum=jj;
            end
        end

        outdata(outnum).kalib(i,1)=M.data(Versuch(vnum).Kalibration(i,1));
        outdata(outnum).kalib(i,2)=M.data(Versuch(vnum).Kalibration(i,2));
        outdata(outnum).kalib(i,3)=mean(M.data(Versuch(vnum).Kalibration(i,1):Versuch(vnum).Kalibration(i,2),IndexKalib));

    end
end
    
if(~noMessDataFlag)
    for i=1:size(Versuch(vnum).Messdaten,1)
        % Creating a vertical array with the mean data for each of the selected
        % intervals
        % i loops through intervals
        % this loop checks the expirement conditions and save the data in
        % different array of the outdata depending on the interval
        for jj=1:size(Versuch(vnum).Versuchsdatengrenzen,1)
            if(Versuch(vnum).Messdaten(i,1)>Versuch(vnum).Versuchsdatengrenzen(jj,1) && Versuch(vnum).Messdaten(i,2)<Versuch(vnum).Versuchsdatengrenzen(jj,2))
                outnum1=jj;
            end
        end

        outdata(outnum).messdaten(i,1)=M.data(Versuch(vnum).Messdaten(i,1),1);
        outdata(outnum).messdaten(i,2)=M.data(Versuch(vnum).Messdaten(i,2),1);
        for j=2:size(head,1)
            outdata(outnum).messdaten(i,j+1)=(mean(M.data(Versuch(vnum).Messdaten(i,1):Versuch(vnum).Messdaten(i,2),j)));
        end

    end
end

if(~noMiscFlag)
    % looping withing number of intervals selected for Misc from
    % Intervals.mat
    for i=1:size(Versuch(vnum).Diverses,1)
        % Creating a vertical array with the mean data for each of the selected
        % intervals
        % i loops through intervals
        % 21 is hardcoded (for now) column from the raw data for Schub channel
        % diversesMean(i) = mean(M.data(Versuch(vnum).Diverses(i,1):Versuch(vnum).Diverses(i,2),21)) ;
        % different array of the outdata depending on the interval
        for jj=1:size(Versuch(vnum).Versuchsdatengrenzen,1)
            if(Versuch(vnum).Diverses(i,1)>Versuch(vnum).Versuchsdatengrenzen(jj,1) && Versuch(vnum).Diverses(i,2)<Versuch(vnum).Versuchsdatengrenzen(jj,2))
                outnum=jj;
            end
        end
        outdata(outnum).diverse(i,1)=Versuch(vnum).Diverses(i,1);
        outdata(outnum).diverse(i,2)=Versuch(vnum).Diverses(i,2);
        outdata(outnum).diverse(i,3)=mean(M.data(Versuch(vnum).Diverses(i,1):Versuch(vnum).Diverses(i,2),IndexMisc)) ;
end
end

%% Saving the average data in a Matlab file
save('outdata.mat', 'outdata')

%% Saving Measurement Data in Excel File
sheet = 1;
% writing time header manually
timeheadxlrange='A4';
timehead=["Time from","Time to"]';
xlswrite(filename,timehead,sheet,timeheadxlrange);
% writing channel headers
xlheadrange='A6';
xlswrite(filename,headxls',sheet,xlheadrange);
% writing mean data
xlRange = 'B4';
if(~noMessDataFlag)
xlswrite(filename,outdata.messdaten',sheet,xlRange);
else
    prompt="No data to average, select intervals.";
    xlswrite(filename,cellstr(prompt),sheet,xlRange);
end
intervalrnage='B3';
intervalhead="Interval #";
xlswrite(filename,cellstr(intervalhead),1,'A3');
d=num2cell(1:length(Versuch.Messdaten));
xlswrite(filename,d,1,'B3');


%% Saving Calibration and Thrust Data in Excel File 
sheet = 2;
%writing headers for excel file
calibtit="Calibration";
masstxt="Total Calibration Mass (in N)";
massval="2.896117029";
calibxlRange='B3';
calibdatRange='C4';
calibhead=["Interval No","Time From","Time To","Mean"];
if(~noKalibFlag)
    intervalno=1:length(Versuch.Kalibration);
    xlswrite(filename,intervalno',sheet,'B4');
    xlswrite(filename,calibhead,sheet,calibxlRange);
    %writing data from outdata matrix
    xlswrite(filename,outdata.kalib,sheet,calibdatRange);
else
    prompt="No data to average for Calibration, Select intervals.";
    xlswrite(filename,cellstr(prompt),sheet,calibdatRange);
end
%Thrust Data
thrustit="Thrust Measurement";
xlswrite(filename,calibhead,sheet,'J3');
if(~noSchubFlag)
    thr_intervalno=1:length(Versuch.Schubmessung);
    xlswrite(filename,thr_intervalno',sheet,'J4');
    xlswrite(filename,outdata.schub,sheet,'K4');
else
    prompt="No data to average for Thrust, select intervals.";
    xlswrite(filename,cellstr(prompt),sheet,'K4');
end
%% Some unnecessary excel magic 
%  *Auto resize the column widths* , takes a bit to process but its worth 
%  the wait. You can provide the range also to shave off some time, but it 
%  happens pretty fast(comparitavely to doing it manually)
hExcel = actxserver('Excel.Application');
hWorkbook = hExcel.Workbooks.Open([pwd, filesep,filename]);
hExcel.Cells.EntireColumn.AutoFit;
hExcel.Range('B3..M100').Select;
% Center align the cell contents.
hExcel.Selection.HorizontalAlignment = 3;
hExcel.Selection.VerticalAlignment = 2;

hWorkbook.Worksheets.Item(1).Name ='Measurement_Data';
hWorkbook.Worksheets.Item(2).Name ='Calib_n_Thrust';
% % Put "cursor" or active cell at A1, the upper left cell.
% hExcel.Range('A1').Select;
hWorkbook.Save;
hWorkbook.Close;
hExcel.Quit;
clear hExcel;clear hWorkbook;clear hExcel; % removing from memory

% writing expirement description and calibration mass values after
% centering and autofit commands are executed, to avoid very wide columns
% due to long text descriptions

xlswrite(filename,cellstr(calibtit),2,'B2');
xlswrite(filename,cellstr(thrustit),2,'J2');
xlswrite(filename,cellstr(masstxt),2,'D2');
xlswrite(filename,cellstr(massval),2,'G2');

if isempty(getfield(Versuch(vnum),'Beschreibung'))
else
    descrange='N1';
    xlswrite(filename,cellstr(Versuch(vnum).Beschreibung),1,descrange);
    xlswrite(filename,cellstr(Versuch(vnum).Beschreibung),2,descrange);
end


%% Cleaning up
% Cleaning up unnecessary variables
clearvars -except outdata Versuch

