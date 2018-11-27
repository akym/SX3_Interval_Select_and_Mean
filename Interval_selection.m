function Interval_selection
% Interval_selection v2
% 
% INPUT:
% OUTPUT: Intervals in Ergebnis.mat
% Other m-files required: From subfunctions folder
% Subfunctions: infobox.m, movingaverage.m, leporidae.m, panzoom.m
% MAT-files required: Ergebnis.mat % Generated from Interval_selection.m file
%
% Version: 2.0
% Datum: 24/04/2018
% Autor: Akash Mankar
% Built on top of version 1
%
% Credits for version 1
% Version: 1.0
% Datum: 2017-040
% Autor: Peter Justel
% Lizenz: CC-BY-SA 4.0 (Feel free, but attribute the author, and share remixes under similar terms)
% https://creativecommons.org/licenses/by-sa/4.0/
% https://creativecommons.org/licenses/by-sa/4.0/legalcode

%%%% README
%
%
%
%
%%%% Preamble

%clc
%clear all
close all
clear Versuch
CWD = pwd;	% current working directory.


%%%% Konfiguration

%% For new data vnum = 0, to revisit last interval selection vnum=1%%

vnum = 0;			
%%
beschreibung_switch = 0;							% Flag; Gespeicherte Versuchsbeschreibungen und Zuordnungen anzeigen, und danach Ausführung stoppen.
selectedothersplotswitch = 0;						% Flag; Weitere Zeitreihen im extrafenster plotten?
	auswahl = [9 3 15:17];							% [9 3 15:17]Wenn Selectedothersplotswitch = true: Welche Datenreihen dargestellt werden sollen. Siehe auch die "head" Struktur, welche dynamisch ausgelesen wird, oder die Notizen am Ende dieser Funktion. [3 22 7 8 19]
xachseneinheiten = false;								% Nur für die Darstellung verwenden! Für die Bearbeitung der Intervalle ist eine x-achse in Zeiteinheiten ungeeignet. Flag; Ob auf der X-Achse der Datenindex oder die Zeit aufgetragen werden soll.
mittelungsbreite = 100;									% Filter: Radius der Mittelung um den aktuellen Punkt (Mittelungsradius; nur 1 und 2; Standard=100)
Ergebnisdatei = 'Intervals.mat';							% Name der Datei, in der die Ergebnisse gespeichert sind. Diese muss im selben Ordner liegen. Wenn noch nicht vorhanden, gewünschten Dateinamen hier angeben.
Versuchsdatenpfad = CWD;	% Systemabhängig formatierter Pfad zum Ordner mit den Versuchsdaten. Standard: ./Versuchsdaten
Subfunktionspfad = [CWD, filesep, 'Subfunctions'];		% Systemabhängig formatierter Pfad zu den Subfunktionen,
Backuppfad = [CWD, filesep, 'Backups'];			% Systemabhängig formatierter Pfad zu den Backups



%%%% Load data, create new experiment numbers, generate new result files

addpath(Subfunktionspfad)	% where it finds the subfunctions.

% Load information about experiments.
if exist([CWD, filesep, Ergebnisdatei],'file')	% test if result file is in the same folder as this function
	load([CWD, filesep, Ergebnisdatei]);
	if exist('Versuch','var') == 0 || isstruct(Versuch) == 0 || isfield(Versuch, 'Dateiname') == 0
		error([Ergebnisdatei, ' must contain a Structure Array named "try", and the corresponding fields.'])
	end
	
	% Alle Versuchsbeschreibungen anzeigen
	if beschreibung_switch == 1
		disp('Trial descriptions are displayed. description_switch = true')
		disp('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -')
		for ii = 1:size(Versuch, 2)		 %#ok<*NODEF>
			disp(['Versuch (', num2str(ii), ') - ',Versuch(ii).Dateiname,' : ', Versuch(ii).Beschreibung])	% Durch alle Versuche laufen, und Beschreibungen anzeigen. Dann Skript beenden.
			if mod(ii,5) == 0
				% alle 5 Versuche einen optischen trenner.
				disp('- - - - -')
			end
		end
		assignin('base','Versuch',Versuch)	% Die Daten aus der Ergebnisdatei in den Basisworkspace laden, zum anschauen.
		return
	end
else											% andernfalls eine neue Ergebnisdatei anlegen.
	antwort = questdlg(['Matlab can not find ', [CWD, filesep, Ergebnisdatei], ' . Should a new data structure be created? ', Ergebnisdatei, ' .'], 'New Data Matrix', 'Yes', 'Cancel', 'Yes'); % questdlg(Dialogtext, Titeltext, Button 1, Button 2, Button 3, Default Button)
	if strcmp(antwort, 'Yes')
		Versuch = struct([]);
		Versuch(1).Dateiname = '';		% Name der Datei mit den Versuchsdaten
		Versuch(1).Beschreibung = '';	% Beschreibung des Versuchs
		Versuch(1).Versuchsdatengrenzen = [];	% Wenn in einer Datei mehrere Versuche sind, können Grenzen definiert werden, die einen Versuch darstellen.
		Versuch(1).Kalibration = [];	% Die Intervalle in der Zeitreihe, welche zur Kalibration gehören.
		Versuch(1).Schubmessung = [];	% Zwei Intervalle, welche "An" und "Aus" repräsentieren.
		Versuch(1).Messdaten = [];		% Die Intervalle innerhalb der Zeitreihe, welche zu den Messpunkten gehören.
		Versuch(1).Diverses = [];
        
        % for everything else you do as an experiment by the way.
		vnum = 0;						% The file name can then be specified in the next step.
	else
		disp(['Matlab can not find ', [CWD, filesep, Ergebnisdatei], ' . Operation Canceled.'])	% evtl. durch uiopen dialog, oder neu erschaffen, ersetzen. % possibly by ui open dialog, or create new, replace.
		return
	end
end



% Daten zu Versuch Nummer "vnum" laden
if vnum == 0
	
	% neuen Versuch einlesen
	NeueDatei = inputdlg({'Please enter the file name of the raw data file :'}, 'Input Data File', 1, {'tank8_0'});	% inputdlg(Fenstertext, Fenstertitel, Inputzeilenanzahl, Default Antwort)
	if isempty(NeueDatei)	% wenn "Abbrechen" gedrückt wurde
		return
	else
		NeueDatei = NeueDatei{1};
	end
	
	% Sanity checks
	if size(NeueDatei, 2) == 0
		error('No file specified.')
	elseif exist([Versuchsdatenpfad, filesep, NeueDatei],'file') == 0
		error(['file not found: ', Versuchsdatenpfad, filesep, NeueDatei])
	end
	
	% Check if the file is already used on any attempt.
	a = {Versuch.Dateiname};		% cell array mit allen Dateinamen.
	neuerversuchflag = 0;
	for ii = 1:size(a,2)
		if strcmp(a{ii}, NeueDatei) == 1
			disp(['Interval selection already exist for attempt number ', num2str(ii), ' . Condition description: ', Versuch(ii).Beschreibung])
			neuerversuchflag = 1;
		end
	end
	
	% Dialogbox, wenn die Datei bereits bei einem anderen Versuch benutzt wird.
	if neuerversuchflag == 1
		antwort2 = questdlg(['Intervals data for ', NeueDatei, ' file already exists, if you want to re-analyse and define new intervals, please choose new analysis below or manually change the vnum in the code at line 40 to access previous intervals.'], 'Analysis already exist', 'New analysis', 'Cancel', 'Abbrechen'); % questdlg(Dialogtext, Titeltext, Button 1, Button 2, Button 3, Default Button)
		if strcmp(antwort2, 'Neue Versuchsnummer') == 1
			Versuch(end+1).Dateiname = NeueDatei;	% Neue Versuchsnummer mit bestehendem Dateinamen erzeugen.
			Versuch(end).Beschreibung = '';			% Zu dieser Versuchsnummer (ja, da muss "end" nicht "end+1" stehen), die Beschreibung initialisieren.
			vnum = size(Versuch, 2);
		else
			disp('Canceled. If you need to access the previous selection of intervals, enter the experiment number manually in the code at line 40.')
			% Es wurde Abbrechen oder das Kreuz gedrückt.
			return
		end
	else

		if exist('antwort', 'var')
			vnum = 1;			% Der erste Versuch muss hier ein bisschen speziell behandelt werden. Er braucht schon Feldzuweisungen, damit alles reibungsfrei läuft (s.o.). Allerdings kann dann nicht "hinten angehängt" werden, weil sonst die erste Zeile leer bleibt.
			Versuch(1).Dateiname = NeueDatei;
		else
			% Alles lief glatt. Neuen Versuch erzeugen.
			Versuch(end+1).Dateiname = NeueDatei;	% Neue Versuchsnummer mit bestehendem Dateinamen erzeugen.
			Versuch(end).Beschreibung = '';		% Zu dieser Versuchsnummer (ja, da muss "end" nicht "end+1" stehen), die Beschreibung initialisieren.
			vnum = size(Versuch, 2);
		end
	 
	end
elseif vnum < 0 || round(vnum) ~= vnum		% Sanity check
	error('vnum must be zero or a positive integer.')
elseif vnum <= size(Versuch, 2)
	% Ein existierender Versuch wurde gewählt. Gehe weiter zum import der Daten.
else
	error(['No data under the experiment number ', num2str(vnum)])
end
assignin('base','Versuch',Versuch)	% Die Daten aus der Ergebnisdatei in den Basisworkspace laden, zum anschauen.

% Versuchsdaten einlesen % Read test data

%% Here the header are extracted from the rawdata file

if isempty(Versuch(vnum).Dateiname) % Sanity Checks
	error(['No file name to try(', num2str(vnum), ') definiert.'])
elseif exist([Versuchsdatenpfad, filesep, Versuch(vnum).Dateiname], 'file')	% wenn es zu der Versuchsnummer tatsächlich einen Versuch gibt: Daten laden.
	
	% Load test dat
	M = importdata([Versuchsdatenpfad, filesep, Versuch(vnum).Dateiname]);		
	assignin('base','Rohdaten',M)
	
	% Parsing the Headers
	head = cell(5, 1);   % change the cell number to number of row from the input file
      
	for ii = 1:5       % change to number of rows of the headers from the input file
		head{ii} = strread(M.textdata{ii+4,1},'%s','delimiter',':'); %#<DSTRRD>% Separate the column names from the text data
	end
	head = vertcat(head{:});		% ein einzelnes langes Cellarray draus machen.
	assignin('base','Header',head)
else
	error(['Can not find data for trial number ', num2str(vnum), ' in ' [Versuchsdatenpfad, filesep, Versuch(vnum).Dateiname], ' .'])
end
%%


%%%% GUI for Data Representation and Interval Selection

%%%% Building up the graphical environment

selectwindow = figure('units','normalized',... % normalized heißt: unabhängig von der Bildschirm/Fenstergröße geht es immer von 0 bis 1
					'Position',[0.05 0.128 0.95 0.8],... % Position: [left bottom width heights]
					'Color','w',...
					'NumberTitle', 'off',...			% Schaltet "Figure n" im Fenstertitel ab.
					'Name', 'AFMPD Tank 8 Data Representation and Interval Selection ',...
					'WindowButtonMotionFcn',@routing,... % WindowButtonMotionFcn: verknüpft die Funktion, welche beim "Motion" callback ausgelöst werden soll.
					'WindowButtonUpFcn',@routing,...
					'WindowScrollWheelFcn',@panzoom, ...
					'WindowKeyPressFcn', @panzoom,...
					'WindowKeyReleaseFcn', @panzoom);


uicontrol('Style', 'pushbutton',...
        'String','Info',...
        'units','normalized',...
        'BackgroundColor','w',...
        'FontSize',14,...
        'Position', [0.87 0.95 0.08 0.044],...
        'Callback',@infobox);


			
% Kontrollgruppen Radiobuttons
dataradiogroup = uibuttongroup('units', 'normalized',...	% enthält die Radiobuttons, mit denen die dargestellten Daten geändert werden können.
								'Position', [0.87 0.36 0.1 0.58],...
								'Title', 'Select Channel:',...
								'FontSize', 12,...
								'SelectionChangeFcn', @selectdata);

clustersradiogroup = uibuttongroup('units', 'normalized',...	% enthält die radiobuttons, mit denen der Clustertyp (Messdaten, Kalibration, Diverses) ausgewählt werden kann.
								'Position', [0.87 0.22 0.1 0.126],...
								'Title', 'Interval for:',...
								'FontSize', 12,...
								'SelectionChangedFcn', @selectclustertype);
							
filterradiogroup = uibuttongroup('units', 'normalized',...	% enthält die radiobuttons, mit denen der Filter für die geglätteten Daten gewählt werden kann.
								'Position', [0.96 0.07 0.03 0.13],...
								'Title', 'Filter',...
								'FontSize', 10,...
								'SelectionChangeFcn', @selectfilter);



% Radio buttons for data dialing
radio1 = gobjects(size(M.data,2)-1);	% Initialize the radio button Graphic object arrays.
topslot = (1-0.02);						% Used to arrange the buttons from top to bottom, not the other way round. See also the definition of 'Position'.
                                        

%%%%%% 
% here the channels are getting populated
%%%%%%

% here the channels are getting populated
for ii = 1:length(radio1)
	buttonhoehe = topslot/length(radio1);		% Automatic scaling depending on the number of time series.
	buttonypos = topslot - (ii*buttonhoehe);	% Automatic arrangement in height, depending on the number of time series. The seats are occupied top to bottom.
	radio1(ii) = uicontrol(dataradiogroup,...
					'Style', 'radiobutton',...
					'String', head{ii+1}, ...	% Because of the time on position head {1}, ii + 1 -> i. the names of the time series start at head {2}.
					'Fontsize', 10,...
					'Units', 'normalized',...
					'Position', [0.05 buttonypos 0.95 buttonhoehe],...
					'UserData', ii+1);			% This number assigns the radio button the time series.
end

% Radio Buttons for Cluster Selection: Measurement Data, Calibration, Data Limits, Miscellaneous
buttonhoehe = topslot/5;	% For the arrangement of radio buttons important size

radio2.messdaten = uicontrol(clustersradiogroup,...
					'Style', 'radiobutton',...
					'string', 'Measurement Data', ...
					'Fontsize', 10,...
					'Units', 'normalized',...
					'Position', [0.05 topslot-buttonhoehe 0.95 buttonhoehe],...
					'userdata', 'Messdaten');

radio2.Schubmessung = uicontrol(clustersradiogroup,...
					'Style', 'radiobutton',...
					'string', 'Thrust Measurement', ...
					'Fontsize', 10,...
					'Units', 'normalized',...
					'Position', [0.05 topslot-2*buttonhoehe 0.95 buttonhoehe],...
					'userdata', 'Schubmessung'); %
				
radio2.kalibration = uicontrol(clustersradiogroup,...
					'Style', 'radiobutton',...
					'string', 'Calibration', ...
					'Fontsize', 10,...
					'Units', 'normalized',...
					'Position', [0.05 topslot-3*buttonhoehe 0.95 buttonhoehe],...
					'userdata', 'Kalibration');


radio2.datengrenzen = uicontrol(clustersradiogroup,...
					'Style', 'radiobutton',...
					'string', 'Exp. Conditions', ...                       %'Exp Conditions(', num2str(vnum),')'
					'Fontsize', 10,...
					'Units', 'normalized',...
					'Position', [0.05 topslot-4*buttonhoehe 0.95 buttonhoehe],...
					'userdata', 'Versuchsdatengrenzen');
				
radio2.diverses = uicontrol(clustersradiogroup,...
					'Style', 'radiobutton',...
					'string', 'Misc', ...
					'Fontsize', 10,...
					'Units', 'normalized',...
					'Position', [0.05 topslot-5*buttonhoehe 0.95 buttonhoehe],...
					'userdata', 'Diverses');



% Radiogroup for filter selection

radio3.zero = uicontrol(filterradiogroup,...
					'Style', 'radiobutton',...
					'string', '0', ...
					'Fontsize', 10,...
					'Units', 'normalized',...
					'Position', [0.187 0.7 0.67 0.20],...
					'userdata', 0);

radio3.one = uicontrol(filterradiogroup,...
					'Style', 'radiobutton',...
					'string', '1', ...
					'Fontsize', 10,...
					'Units', 'normalized',...
					'Position', [0.187 0.5 0.67 0.20],...
					'userdata', 1);

radio3.two = uicontrol(filterradiogroup,...
					'Style', 'radiobutton',...
					'string', '2', ...
					'Fontsize', 10,...
					'Units', 'normalized',...
					'Position', [0.187 0.3 0.67 0.20],...
					'userdata', 2);

radio3.three = uicontrol(filterradiogroup,...
					'Style', 'radiobutton',...
					'string', '3', ...
					'Fontsize', 10,...
					'Units', 'normalized',...
					'Position', [0.187 0.1 0.67 0.20],...
					'userdata', 3);



				
% Pushbuttons

uicontrol('Style', 'pushbutton',...
        'String','Reset',...
        'units','normalized',...
        'BackgroundColor','w',...
        'FontSize',14,...
        'Position', [0.87 0.113 0.08 0.044],...
        'Callback',@clearclusters);

uicontrol('Style', 'pushbutton',...
        'String','Description',...
        'units','normalized',...
        'BackgroundColor','w',...
        'FontSize',12,...
        'Position', [0.87 0.061 0.08 0.044],...
        'Callback',@beschreibung_add);

savebutton = uicontrol('Style', 'pushbutton',...
        'String','Save Data',...
        'units','normalized',...
        'BackgroundColor','w',...
        'FontSize',14,...
        'Position', [0.87 0.009 0.08 0.044],...
        'Callback',@savebuttonpress);


					
%%%% Daten aufbauen 
%%%% Data develop

if xachseneinheiten == 1 % x axis units
	t = M.data(:,1);	% Zeit in Sekunden auf der X-Achse aufgetragen. %Time in seconds plotted on the x-axis.
% 	t_ind = 1: length(M.data(:,1));		% WIP! Indices der Zeitdaten %WIP! Indices of time data
else
	t = 1: length(M.data(:,1));		% Index auf der X-Achse aufgetragen. % Index plotted on the x-axis.
end
tr = M.data(:,dataradiogroup.SelectedObject.UserData);		% Geplottete Daten. % Plotted data.

% Moving Average Algorithmus, der Anfang und Ende vernachlässigt (startet erst ab b+1 Punkten und endet b Punkte vor Ende).
b = mittelungsbreite;					% Radius der Mittelung um den aktuellen Punkt (Mittelungsradius)
                                        % Radius of the averaging around the current point (averaging radius)
Tr = movingaverage(tr, 'mittelungsbreite', b, 'methode', 1);

if isempty(Versuch(vnum).Versuchsdatengrenzen) == 1
	mintr = min(tr);			% braucht es auch in @paintcluster
	maxtr = max(tr);			% braucht es auch in @paintcluster
	scalefactor = std(Tr-tr);	% Hier wird die Größe des Grenzbalkens skaliert, je nach dem wie verrauscht das Signal ist (skaliert mit der Standardabweichung).
elseif size(Versuch(vnum).Versuchsdatengrenzen, 2) == 2
	mintr = min( tr( Versuch(vnum).Versuchsdatengrenzen(1,1):Versuch(vnum).Versuchsdatengrenzen(1,2) ) );
	maxtr = max( tr( Versuch(vnum).Versuchsdatengrenzen(1,1):Versuch(vnum).Versuchsdatengrenzen(1,2) ) );
	scalefactor = std( Tr( Versuch(vnum).Versuchsdatengrenzen(1,1):Versuch(vnum).Versuchsdatengrenzen(1,2) ) - tr( Versuch(vnum).Versuchsdatengrenzen(1,1):Versuch(vnum).Versuchsdatengrenzen(1,2) ) );
else
	error('The contents or formatting of the experimental data limits are not covered by the code.')
end
	
if mintr == maxtr && mintr ~= 0		% für den Fall, dass die Funktion konstant ist.
	scalefactor = 0.1*mintr;
elseif mintr == maxtr && mintr == 0	% wenn die Funktion konstant null ist.
	scalefactor = 0.5;
end



%%%% Plot aufbauen
% Build plot

Achse1 = axes('units','normalized',...
			'Position',[0.05 0.08 0.8 0.9],...
			'XLim',[0 max(t)],...
			'YLim',[mintr maxtr+scalefactor],...
			'Tag', 'Achse1', ...
			'ButtonDownFcn', @panzoom);
		
if isempty(Versuch(vnum).Versuchsdatengrenzen) == 0
	Achse1.XLim = [t(Versuch(vnum).Versuchsdatengrenzen(1)), t(Versuch(vnum).Versuchsdatengrenzen(2))];		% Falls Versuchsgrenzen definiert wurden, wird die Ansicht entsprechend skaliert.
end

if xachseneinheiten == 1
	xlabel(head(1))
else
	xlabel('Data Points')
end
ylabel(head(dataradiogroup.SelectedObject.UserData)) % y label axis 

hold on
cmap = colormap(lines);		% Read matrix with color value data
cmap = cmap(1:7, :);		% pick up meaningful part. the colormap repeats from 8 easy.
 
%%%%% 
% Main plot here
%%%%%

datenplot = plot(Achse1, t, tr, 'color', [0.8 0.8 0.8], 'ButtonDownFcn', @clustergenesis);
mittelplot = plot(Achse1, t, Tr, 'color',[0.2 0.2 0.2], 'ButtonDownFcn', @clustergenesis);
mittelplot.Visible = 'off';	% We need the thing defined, but it should not be displayed at first.

if isempty(Versuch(vnum).(clustersradiogroup.SelectedObject.UserData)) == 0		% Falls im Versuch(vnum) schon Cluster für die Messdaten definiet wurden. % If clusters for the measurement data have already been defined in the experiment (vnum).
	clusters = Versuch(vnum).(clustersradiogroup.SelectedObject.UserData);	% Cluster laden % Load cluster
	clgrenzen_objects = gobjects(size(clusters,1),size(clusters,2)+1);		% Array der Graphikobjekte initialisieren. Spalten: Clusteranfang, Clusterende, Clusternummer % Initialize array of graphics objects. Columns: cluster start, cluster end, cluster number...
	% Cluster einzeichnen % Draw a cluster
	for ii = 1:size(clusters,1)
		paintcluster(clusters(ii,:), ii)
	end
else
	clusters = [];
	clgrenzen_objects = gobjects(0);

end
	


%%%% Weitere Plots  
%more plots

if selectedothersplotswitch == 1
	figure('units','normalized','Position',[0 0 0.9875 0.8000], 'NumberTitle', 'off', 'Name', 'Selected Others')
	Auswahl = M.data(:,auswahl);	% ausgewählte Daten separieren
	for ii = 1:length(auswahl)
		subplot(length(auswahl), 1, ii)
		plot(M.data(:,1),Auswahl(:,ii))
		xlabel(head{1})
		ylabel(head{auswahl(ii)})
		grid on
		set(gca, 'XLim', [0 M.data(end,1)])
	end
end



%%%% Variablen initialisieren % Variable init

actionflag = 0;		% Determines whether an interval boundary should be moved.
actioncluster = 0;	% Here is stored, which interval is connected to the action.
a_e = 1;			% here it is saved, whether the border should be moved left or border right.

newclusterflag = 0; % Determines if a new cluster is being created.
temp_object = gobjects(1,3);	% Cache for the newly created interval.

counter = 1;

%%%% Callback Funktionen

	function routing(src, evt)
		% This function commits the WindowButtonUpFcn and WindowButtonMotionFcn callback to several functions.
		panzoom(src,evt)
		clusteraction(src,evt)
	end



	function selectclustertype(~,evt)
		% hier muss ich reinschreiben, was passiert, wenn ein radiobutton ausgewählt, oder verändet wird.
		% clustersradiogroup.SelectedObject -> gibt mir den radiobutton, der ausgewählt ist.
		% evt.OldValue ist das Handle des zuletzt ausgewählten Buttons
		
		% cluster in "Arbeits"-Versuch speichern
		Versuch(vnum).(evt.OldValue.UserData) = clusters;
		
		% clear graphix
		delete(clgrenzen_objects)       % Intervallgrenzen Graphikobjekte aus dem Plot entfernen
		clgrenzen_objects = gobjects(0);
		
		% neue cluster laden
		clusters = Versuch(vnum).(clustersradiogroup.SelectedObject.UserData);
		
		% plot clusters
		for jj = 1:size(clusters,1)
			paintcluster(clusters(jj,:),jj)
		end
	end


%%
	function selectdata(~,~)
		% Here the data assigned to the plots are changed.
		
		if newclusterflag == 1                  % when a new cluster is about to be created
			delete(temp_object)                 % delete temporary graphic object
			temp_object = gobjects(1,3);        % Place placeholder again
			newclusterflag = 0;					% Reset flag.
		end
		
		tr = M.data(:,(dataradiogroup.SelectedObject.UserData-0));
        % Average filter
		if filterradiogroup.SelectedObject.UserData == 0
			Tr = movingaverage(tr, 'mittelungsbreite', b, 'methode', 1);
		elseif filterradiogroup.SelectedObject.UserData < 4
			Tr = movingaverage(tr, 'mittelungsbreite', b, 'methode', filterradiogroup.SelectedObject.UserData);
		end
		%%
		if isempty(Versuch(vnum).Versuchsdatengrenzen) == 1 % Versuchsdatengrenzen = Expirement conditions intervals
                mintr = min(tr);			% it also needed in @paintcluster
                maxtr = max(tr);			% it also needed in @paintcluster
                scalefactor = std(Tr-tr);	% Here the height of the border bar is scaled, depending on how noisy the signal is (scaled by the standard deviation). 
            elseif size(Versuch(vnum).Versuchsdatengrenzen, 2) == 2
                mintr = min( tr( Versuch(vnum).Versuchsdatengrenzen(1,1):Versuch(vnum).Versuchsdatengrenzen(1,2) ) );
                maxtr = max( tr( Versuch(vnum).Versuchsdatengrenzen(1,1):Versuch(vnum).Versuchsdatengrenzen(1,2) ) );
                scalefactor = std( Tr( Versuch(vnum).Versuchsdatengrenzen(1,1):Versuch(vnum).Versuchsdatengrenzen(1,2) ) - tr( Versuch(vnum).Versuchsdatengrenzen(1,1):Versuch(vnum).Versuchsdatengrenzen(1,2) ) );
            else
                error('The contents or formatting of the experimental data limits are not covered by the code.')
        end
        %%
		datenplot.YData = tr;		 % assign the new data to the plot
		mittelplot.YData = Tr;
        
		if mintr == maxtr && mintr ~= 0
             % in case the function is constant.
            scalefactor = 0.1*mintr;
            Achse1.YLim = [0 maxtr+scalefactor];
        elseif mintr == maxtr && mintr == 0
           % if the function is constantly zero.
            scalefactor = 0.5;
            Achse1.YLim = [-1 1];
		elseif mintr <= 0 && maxtr > 0
            % e.g. with fluctuations around the zero value.
			Achse1.YLim = [mintr maxtr];
		elseif mintr < 0 && maxtr <= 0
            % when everything is in the negative
			Achse1.YLim = [mintr 0];
		else
            % when everything is normal
            Achse1.YLim = [0 maxtr+scalefactor];
		end
		
		if isempty(Versuch(vnum).Versuchsdatengrenzen) == 0
			Achse1.XLim = [t(Versuch(vnum).Versuchsdatengrenzen(1)), t(Versuch(vnum).Versuchsdatengrenzen(2))];
		else
			Achse1.XLim = [0 t(end)];
		end
		ylabel(head{dataradiogroup.SelectedObject.UserData})

        % Adjust the graphical representation of the cluster boundaries.
        for jj = 1:size(clgrenzen_objects,1)
            y1 = tr(clusters(jj,1)) - scalefactor;		% Here the size of the bar is scaled, depending on how noisy the signal is (scaled by the standard deviation).
            y2 = tr(clusters(jj,1)) + scalefactor/2;
            clgrenzen_objects(jj,1).YData = [y1 y2];
            clgrenzen_objects(jj,2).YData = [y1 y2];
            clgrenzen_objects(jj,3).Position(2) = y1-scalefactor*0.2;
        end
		
	end

%%

	function selectfilter(~,~)
		% Stellt anders gefilterte Daten dar
		if filterradiogroup.SelectedObject.UserData == 0
			mittelplot.Visible = 'off';
		elseif filterradiogroup.SelectedObject.UserData < 4
			mittelplot.Visible = 'on';
			mittelplot.YData = movingaverage(tr, 'mittelungsbreite', b, 'methode', filterradiogroup.SelectedObject.UserData);
		else
			error('diocane!! wtf did just happen? filterradiogroup.SelectedObject.UserData is 4 or bigger?') % original author: Peter
		end
	end



	function clusteraction(src,evt)
		% cluster bewegen
        % move cluster with mouse actions
		
		%%% ursprünglicher Plan (nicht unbedingt komplett wahrheitsgetreu):
		% Cluster erschaffen (input: clustertyp, Versuch.cluster, currentPosition, anfangEndeFlag, output: anfangEndeFlag, Graphikobjekt, Versuch.cluster(+1))
		% cluster aus konserve zeichnen (input: clustertyp, Versuch, Achsenhandle?, output: Graphikobjekt)
		%D grenze verschieben (input: clnummer, clustertyp, Versuch, actionflag, WindoButtonMotionFcn trigger, CurrentPosition, output: actionflag, clustergrenze, Graphikobjekt.Position)
		%D cluster löschen (input: clnummer)
		% Datengrenzen einzeichnen/ Plot skalieren.
		% Radiobutton Clustersorte änderung -> speichern, clear, neu laden, neu zeichnen.
		% funktion für die action, funktion fürs einzeichnen, funktion fürs sortieren.
		%%%

		if strcmp(evt.EventName, 'WindowMouseMotion') && actionflag == 1
			% Bewegung der Grenze
			X = round(Achse1.CurrentPoint(1,1));				% hole die aktuelle x-Position
			clgrenzen_objects(actioncluster, a_e).XData = [X X];	% verschiebe die Linie
			x1 = clgrenzen_objects(actioncluster, 1).XData(1,1);	% für die Berechnung der Schriftposition.
			x2 = clgrenzen_objects(actioncluster, 2).XData(1,1);
			if a_e == 1				% Wenn der Anfangsstrich gewählt wird, wird auch der Y-Wert verändert.
				y1 = tr(X) - scalefactor;
				y2 = tr(X) + scalefactor/2;
				clgrenzen_objects(actioncluster, 1).YData = [y1 y2];
				clgrenzen_objects(actioncluster, 2).YData = [y1 y2];
				clgrenzen_objects(actioncluster, 3).Position = [x1+round((x2-x1)/2) y1-scalefactor*0.2];
			elseif a_e == 2
				clgrenzen_objects(actioncluster, 3).Position(1,1) = x1+round((x2-x1)/2);	% Beim verschieben der hinteren Grenze soll er nur die x-position der Schrift verändern.
			end
		
		elseif strcmp(evt.EventName, 'Hit') && strcmp(src.Tag, 'GrenzeLinks') || strcmp(src.Tag, 'GrenzeRechts')
			% bewegung ermöglichen: flag und zu bewegende Grenze setzen.
			actionflag = 1;
			actioncluster = src.UserData;
			if strcmp(src.Tag, 'GrenzeLinks')
				a_e = 1;
			else
				a_e = 2;
			end

		elseif strcmp(evt.EventName, 'WindowMouseRelease')
			% bewegung aufhören
			if actionflag == 1
				clusters(actioncluster, a_e) = round(Achse1.CurrentPoint(1,1));		% Position der Grenze Speichern.
				actionflag = 0;
			end
		end
	end



	function paintcluster(cluster, clusternummer)
		% Clustergrenzen einzeichnen, und Handles in clgrenzen_objects ablegen.
		% INPUT: 2er Vektor mit Anfang und Ende des Clusters, globale Nummer des Clusters.
		% OUTPUT: Graphikobjekte in Achse1 für den Cluster
		
		clcolor = mod(clusternummer-1, 7) +1;	% cmap hat 7 Einträge. Danach muss wieder von vorn begonnen werden. Dafür sorgt die Modulo operation (Rest der Übrig bleibt, wenn man von der ersten Zahl möglichst viele ganze Vielfache der ersten Zahl abzieht)
		% Sanity checks
% 		if cluster(1) < 0	% this shit has problems mit xachseneinheiten == 1. cluster(1) kann 19500 sein, wenn die zeit in sekunden nur bis 2100 geht.
% 			cluster(1) = 0;
% 		elseif cluster(1) > t(end)
% 			cluster(1) = t(end);
% 		end
% 		if cluster(2) < 0
% 			cluster(2) = 0;
% 		elseif cluster(2) > t(end)
% 			cluster(2) = t(end);
% 		end
		
		% Intervall einzeichnen
		x1 = t(cluster(1));						% Intervallgrenze Anfang x-wert
		x2 = t(cluster(2));						% Intervallgrenze Ende x-wert				
		y1 = tr(cluster(1)) - scalefactor;		% Intervallgrenzen unterer y-wert
		y2 = tr(cluster(1)) + scalefactor/2;	% Intervallgrenzen oberer y-wert
		clgrenzen_objects(clusternummer,1) = plot(Achse1, [x1 x1], [y1 y2], 'LineWidth', 4, 'Color', cmap(clcolor,:), 'Tag', 'GrenzeLinks', 'UserData', clusternummer, 'ButtonDownFcn', @clusteraction);	% Anfangsgrenze zeichnen
		clgrenzen_objects(clusternummer,2) = plot(Achse1, [x2 x2], [y1 y2], 'LineWidth', 4, 'Color', cmap(clcolor,:), 'Tag', 'GrenzeRechts', 'UserData', clusternummer, 'ButtonDownFcn', @clusteraction);	% Endgrenze zeichnen
		clgrenzen_objects(clusternummer,3) = text(Achse1, x1+round((x2-x1)/2), y1-scalefactor*0.2, int2str(clusternummer), 'Color', cmap(clcolor,:), 'Tag', 'ClusterNummerierung', 'UserData', clusternummer, 'HorizontalAlignment','Center', 'ButtonDownFcn',@textButtonDown);	% Clusternummer einzeichnen.
	end



	function clustergenesis(~,evt)
		switch evt.Button
				case 1 % Left mouse button
					
					if ~newclusterflag % if it is a new clustr
						start = round(Achse1.CurrentPoint(1,1));	% First interval limit
						y1 = tr(start) - scalefactor; 
						y2 = tr(start) + scalefactor/2; 
						temp_object(1,1) = plot([start start], [y1 y2], 'LineWidth', 4, 'Color', [0.5 0.5 0.5], 'Tag', 'Temporäre Intervallgrenze', 'ButtonDownFcn', @clusteraction);	% Draw first interval limit.
						
					else % finalisiere Cluster
						start = temp_object(1).XData(1,1);				%read out the cluster since this value is deleted after the first run (~ newclusterflag) (see workspaces of functions).
						ende = round(Achse1.CurrentPoint(1,1));
						
						if start < ende			% Sort the boundaries in the correct direction.
							tempcluster = [start ende];
						else
							tempcluster = [ende start];
						end
						if isempty(clusters) == 1
							splitnumber = 0;
						else
							splitnumber = length(find(clusters(:,1) < tempcluster(1,1)));	% find the number of the next cluster to the left of the new one.
						end
						clusternum = splitnumber +1;
						
						
						% sort cluster, and prepare / prepare clgrenzen_objects for @paintcluster
						if isempty(clusters) == 1
							clusters = tempcluster;
							clgrenzen_objects = temp_object;
						elseif splitnumber == 0							% cluster ist vor dem ersten
							clusters = [tempcluster; ...
										clusters];
							clgrenzen_objects = [temp_object; ...
												clgrenzen_objects];
											
						elseif splitnumber == length(clusters)	% cluster ist nach dem letzten
							clusters = [clusters; ...
										tempcluster];
							clgrenzen_objects = [clgrenzen_objects; ...
												temp_object];
											
						else										% cluster ist mittendrin
							clusters = [clusters(1:splitnumber,:); ...
											tempcluster; ...
											clusters(splitnumber+1:end,:)];
							clgrenzen_objects = [clgrenzen_objects(1:splitnumber,:); ...
												temp_object; ...
												clgrenzen_objects(splitnumber+1:end,:)];
						end
						
						% cluster richtig einzeichnen
                        % draw cluster correctly
						delete(temp_object)						% temporäres Graphikobjekt löschen
						temp_object = gobjects(1,3);			% Platzhalter wieder anlegen.
						paintcluster(tempcluster, clusternum)	% Jetzt den ordentlichen cluster zeichnen.
						

						% korrigieren der Intervallbeschriftungen, Farben, und Identifizierungsnummern
                        % Correct the interval labels, colors, and identification numbers
						for kk = 1:size(clgrenzen_objects,1)
							clcolor = mod(kk-1, 7) +1;										% s. @paintcluster für Erklärung
							set(clgrenzen_objects(kk,1), 'Color', cmap(clcolor,:), 'UserData', kk);			
							set(clgrenzen_objects(kk,2), 'Color', cmap(clcolor,:), 'UserData', kk);
							set(clgrenzen_objects(kk,3), 'Color', cmap(clcolor,:), 'UserData', kk, 'string',int2str(kk));	% und noch die Zahlenbeschriftung anpassen.
						end
						
					end
					newclusterflag = ~newclusterflag;
					
				case 3	% Rechte maustaste Right mousekey
					if exist('leporidae','file') && counter < 11
						leporidae(counter)
						counter = counter +1;
					else
						counter = 1;
					end
			end
	end



	function textButtonDown(src,~)  % To delete a cluster by clicking on an interval label.
		clusternummer = src.UserData;	
		if ~newclusterflag % falls die Erstellung eines neuen Clusters noch nicht abgeschlossen ist, lassen wir das besser.
            choice = questdlg(['Do you want to delete interval number ' int2str(clusternummer) ' ?'],'Delete Interval?','Yes','No','No');		% Frage ob Cluster wirklich geloescht werden soll
			switch choice
				case 'Yes' % Wenn mit "Ja" beantwortet
					clusters(clusternummer,:) = [];			% lösche den Cluster in den Daten
					delete(clgrenzen_objects(clusternummer,:))	% Loesche alle zugehörigen Grafik-Elemente auf einmal
                    clgrenzen_objects(clusternummer,:)=[];		% Loesche auch die Object Handles in der clgrenzen Matix.
					
					% korrigieren der clgrenzen handles, der Intervallbeschriftungen und der Farben
					for kk = 1:size(clgrenzen_objects,1)
						clcolor = mod(kk-1, 7) +1;	% cmap hat 7 Einträge. Danach muss wieder von vorn begonnen werden. Dafür sorgt die Modulo operation (Rest der Übrig bleibt, wenn man von der ersten Zahl möglichst viele ganze Vielfache der ersten Zahl abzieht)
						set(clgrenzen_objects(kk,1), 'Color', cmap(clcolor,:), 'UserData', kk)
						set(clgrenzen_objects(kk,2), 'Color', cmap(clcolor,:), 'UserData', kk)
						set(clgrenzen_objects(kk,3), 'Color', cmap(clcolor,:), 'UserData', kk, 'string',int2str(kk))
					end
				otherwise % else, do nothing.
			end
		end
	end




	function clearclusters(~,~)
		% Deletes all clusters of the currently selected variety.
		antwoort = questdlg(['Are you sure you want to delete all intervals for ', clustersradiogroup.SelectedObject.UserData,' ?'],'Delete interval?','Yes','No','Yes');
		if strcmp(antwoort, 'Yes')
			clusters = [];			% lösche die Cluster in den Daten
			delete(clgrenzen_objects)	% Loesche alle zugehörigen Grafik-Elemente auf einmal
			clgrenzen_objects = gobjects(0);		% Loesche auch die Object Handles in der clgrenzen Matix.
		else
			return
		end
	end



	function beschreibung_add(~,~)
	
        % allows you to edit the description of the current experiment.
		beschreibtemp = inputdlg(['Description of trial (', num2str(vnum),')                                   .'], 'Edit experiment conditions description', 1, {Versuch(vnum).Beschreibung});	% inputdlg(Fenstertext, Fenstertitel, Inputzeilenanzahl, Default Antwort)
		if size(beschreibtemp,1) == 0
			% es wurde Abbrechen gedrückt
			return
		else
			% Beschreibung speichern.
			Versuch(vnum).Beschreibung = beschreibtemp{1};
		end
	end



	function savebuttonpress(~,~)
		if xachseneinheiten == true
			error('Representation in time units. Data is not stored for security.')
		end
		%%%% Save result
		daten = datestr(date,'yyyy-mm-dd');
		if exist([CWD, filesep, Ergebnisdatei], 'file')
			movefile([CWD, filesep, Ergebnisdatei],[Backuppfad , filesep, daten,'_', Ergebnisdatei])		% Backup der Ergebnisdatei. Die aktuelle Ergebnisdatei wird in den Unterordner Ergebnisbackups verschoben, und das aktuelle Datum vorangestellt. 
            % Backup of the result file. The current result file is moved to the Result Backup subfolder and preceded by the current date.
		end
		Versuch(vnum).(clustersradiogroup.SelectedObject.UserData) = clusters; % synchronize current clusters and attempt.
		assignin('base','Versuch',Versuch)					 % Save the content of the experiment in the basis Workspace under "Versuch".
		save([CWD, filesep, Ergebnisdatei],'Versuch')		% Save data to result file.
		
		savebutton.BackgroundColor = [0.45 0.95 0.63];	% Visueller cue, dass gespeichert wurde.
		pause(0.5)
		savebutton.BackgroundColor = 'w';
	end

figure(selectwindow) % um das Hauptfenster auf jeden Fall als oberstes angezeigt zu bekommen.
% assignin('base','selectwindow',selectwindow)	% um sich u.a. die gobject Daten anschauen zu können

if xachseneinheiten == true
	warndlg('A representation of the X-axis units in seconds also causes the interval limits to be stored in seconds. At the moment, this is still interfering with operations on the interval boundaries, since indices are needed there. In this mode, therefore, the memory function is deactivated.');
end

end

%%%% Notes

% filesep -> platform independent path separator. see fullfile and helper object: specify file names

% @errors: see also assert(condition, errormessage)

% whos [Varname] -> Info about variables

% [pathstr,name,ext] = fileparts(filename) -> Separates path, filename and extension.

% Hilfeobjekt: Access Elements of a Nonscalar Struct Array

% Hilfeobjekt: Share data among callbacks

% 'ButtonDownFcn', {@clusteraction,ii,1} -> so you can pass the callback function dynamically two more parameters (here "ii" and "1").

% format long -> high precision, more number after decimals.


% Ergebnis.m enthält struct Versuch(ii), mit Feldern .Beschreibung, .Dateiname, .Datengrenzen, .Kalibration, .Messpunkte

% Metadata: File number, B field, Cathode gas, Anodic gas, Amperage, Remainder

% Sort trial conditions: Versuch2 = Versuch([1 2 3 4 5 6 9 7 8]);


% load('Dateiname', optional 'variablenname')
% save('Dateiname.bak', 'Variablenname')
% save('Dateiname', 'Variablenname')

% Count lines with blank characters: grep -cve '^ \ s * $' <file>
% This searches for lines in <file> the do not match (-v) lines that match 
% the pattern (-e) '^\s*$', which is the beginning of a line, followed by 0
% or more whitespace characters, followed by the end of a line (ie. no 
% content other then whitespace), and display a count of matching lines (-c) 
% instead of the matching lines themselves.

% Matlab colors:
% Blue: [0 0.447, 0.741]
% Red [0.85  0.325 0.098]
% Yellow: [0.929 0.694 0.125]
% Green: [0.446 0.674 0.188]
% Dark Red: [0.635 0.078 0.184];