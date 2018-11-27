function infobox(~,~)
% Infobox fur Bedienung der Aufbereitung2.m GUI
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


figure('units','normalized',...
		'Position',[0.75 0.18 0.25 0.72],... % Position: [left bottom width heights]
		'NumberTitle', 'off',...			% Schaltet "Figure n" im Fenstertitel ab.
		'Name', 'Info',...
		'Color','w');


Text = {'Operation:','','Move: Drag axis surface','Zoom: Mouse wheel','X / Y zoom only: Shift / Ctrl', 'New interval: click on the plot in two places','Delete interval: click on the number of the interval', 'Move interval border: drag & drop','"Expirement conditions" Interval specifies the X-axis limits for the experiment','','','', ...
					'Saving the changes:', '', 'All changes are cached in the figure, and are preserved when you change the interval type. The changes are only saved in the result file when the "Save button is pressed, which makes it possible to discard changes by closing the window.','Backups are automatically generated from the result file. For each day, a backup is created, which is always overwritten.','','','', ...
					'Filter:','','0: Hide filter curve','1: Central average', '2: Central median', '3: With vertical distance weighted average'};


uicontrol('Style', 'text',...
        'String',Text,...
        'units','normalized',...
        'BackgroundColor',[0.96 0.96 0.96],...
        'FontSize',11,...
		'HorizontalAlignment', 'left',...
        'Position', [0.03 0.02 0.94 0.96]);

% assignin('base', 'infofigure', infofigure)