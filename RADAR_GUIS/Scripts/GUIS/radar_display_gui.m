function radar_display_gui(time, mapval, setupfile)
% RADAR_DISPLAY_GUI View and edit HF RADAR radial (and total) vector data.
%
% INPUTS  (all are optional)
%   time: provide in datenum format, default is current day at 00:00 if no time is given
%   mapval: the number of the map file to initally display (numerical order from
%   the list in the setup file), default is 1
%   setupfile: name of the setup file to use, default is "HFR_INFO.mat"

if ~exist('setupfile','var')
    setupfile = 'HFR_INFO.mat';
end

if ~exist('mapval','var')
    mapval = 1;
end

if exist(setupfile,'file') ~= 2
    msgbox(sprintf('Error:  Could not find %s set up file.\n\nRun hfr_setup_gui.m to create this file.',setupfile))
end

AA = load(setupfile);             % load all the set up file information
setupfile = [AA.HFR_PATHS.gui_dir, setupfile];       % make this variable include the complete path
try
    try
      eval(['javaaddpath(''',AA.HFR_PATHS.gui_dir,'Scripts/Support/toolsUI-4.3.jar'')']);
    catch
      eval(['javaaddpath(',AA.HFR_PATHS.gui_dir,'Scripts/Support/toolsUI-4.3.jar)']); 
    end
catch
    fprintf('Could not load Java tools.\n')
end

warning('off','MATLAB:hg:patch:RGBColorDataNotSupported');

% DEFINE AND INITIALIZE VARIABLES

%getel = @mydatatip;
dcm_obj = [];
cursorMode = [];

STN_INFO = AA.HFR_STNS;                % all station information from set up file
radialpath = AA.HFR_PATHS.radial_dir;  % default path for radial files (assumes site folders (XXXX) under this path)
totalpath = AA.HFR_PATHS.total_dir;    % default path for total files
rpcode = AA.HFR_PATHS.radial_pcode;    % default path code for radial files
tpcode = AA.HFR_PATHS.total_pcode;     % default path code for total files
pathspace = 0;                         % does path name contain a space?s
srpre = AA.HFR_PATHS.radial_prefix;    % user defined prefix for radial file
stpre = AA.HFR_PATHS.total_prefix;     % user defined prefix for total file
rpre = 'RDLm';                         % prefix for radial file
tpre = 'TOTm';                         % prefix for total file
sname = char(STN_INFO(1).name);        % station 4 letter name, default is first in the list
nf = 1;                                % number of files in user definied filelist
filelist = cell(nf,1);                 % user defined list for multiple file plots
titlelab = cell(nf,1);
xx = [];                               % loopindex for filelist
tintvl = 1;                            % time interval in hours (used by < > icons to adjust time)
plothandles = [];                      % variable to keep track of plothandles
pcount = 1;                            % variable to keep track of number of plot objects
new = 0;                               % used by program when new figure is created
%oi_cutoff = 0.6;                       % err cutoff for Rutgers thredds OI totals
gdopval = 1.25;                        % GDOP cutoff for display
oival = 0.6;                           % OI threshold cutoff for display
maxcolor = 60;                        % maximum velocity on color scale for m_vec (cm/s)
ns = 0;                                % north/south color scheme
ew = 0;                                % east/west color scheme
gc = 1;                                % method for defining custom map%
fw = 1000; fh = 800;                   % width and height of figure window in pixels
ii = []; cvals = []; aa = [];          % variables for use in function loops, etc
imap = []; temp = [];
newfilepath = 0;
fid = 0;
LONcell = [];
LATcell = [];
cc = [];


% mycolors = [0.043137254901961   0.517647058823529   0.780392156862745;... medium blue
%     0.749019607843137                   0   0.749019607843137;... purple-pink
%     0.870588235294118   0.490196078431373                   0;... gold
%     0.168627450980392   0.505882352941176   0.337254901960784];  %medium green
mycolors = [[27,158,119]./255;  % based on ColorBrewer (http://colorbrewer2.org)
    [117,112,179]./255;
    [231,41,138]./255;
    [102,166,30]./255;
    [230,171,2]./255;
    [166,118,29]./255;
    [102,102,102]./255;];

mycolors = repmat(mycolors,10,1);


%SET THE INITIAL TIME
if exist('time','var')
    dtmp = datestr(time,'yyyy_mm_dd_HHMM');
else
    dtmp = datestr(floor(now),'yyyy_mm_dd_HHMM');
end
yy = str2double(dtmp(1:4));  mm = str2double(dtmp(6:7));  dd = str2double(dtmp(9:10)); hh = str2double(dtmp(12:13)); MM = str2double(dtmp(14:15));
dv = [yy mm dd hh MM 0];
dnum = datenum(dv);

%SET THE INITIAL MAP
cgnum = size(AA.HFR_MAPS,2) + 1;
AA.HFR_MAPS(cgnum).name = {'Custom_Zoom'};  % set up a space for user to create custom temporary map
%mapval = 1;                          % start with first map in the information file
sgrid = char(AA.HFR_MAPS(mapval).name);   % start with first map name in the information file
scq = AA.HFR_MAPS(mapval).scalefactor;
sc = 0.1;     % m_vec arrows

arrow_spd = 20;     % use this speed as reference for scale  (quiver arrows)

[cxmin, cxmax, cymin, cymax] = deal([],[],[],[]);


% Create and hide the GUI figure as it is being constructed.
f = figure('Visible','off','Position',[360,500,fw,fh]);

% Construct the components

% Create custom menus

% Delete standard menu items that are not needed
dm = findall(f,'Tag','figMenuHelp');
dm = [dm findall(f,'Tag','figMenuWindow')];
dm = [dm findall(f,'Tag','figMenuDesktop')];
delete(dm);

mh = uimenu(f,'Label','GUI Menu');
eh(1) = uimenu(mh,'Label','Compute Totals','Callback',{@totalbutton_Callback});
eh(2) = uimenu(mh,'Label','Edit Radials','Callback',{@autoeditbutton_Callback});
eh(3) = uimenu(mh,'Label','Edit Radial (Manual)','Callback',{@editbutton_Callback});
eh(4) = uimenu(mh,'Label','Compare Radials','Callback',{@compareradbutton_Callback});
eh(5) = uimenu(mh,'Label','Check Total','Callback',{@checktotalbutton_Callback});

gdh = uimenu(f,'Label','Map');
ngrid = size(AA.HFR_MAPS,2);
gridhandles = zeros(ngrid,1);
for gg = 1:ngrid
    gridhandles(gg) = uimenu(gdh,'Label',char(AA.HFR_MAPS(gg).name),'Tag','Grid','Callback',{@map_Callback});
end

siteh = uimenu(f,'Label','Site');
nsite = length(STN_INFO);
sitehandles = zeros(nsite,1);
for ss = 1:nsite
    sitehandles(ss) = uimenu(siteh,'Label',char(STN_INFO(ss).name),'Tag','Site','Callback',{@station_Callback});
end


pmh = uimenu(f,'Label','Plot');
eph(1) = uimenu(pmh,'Label','Set Date','Callback',{@date_Callback});
eph(2) = uimenu(pmh,'Label','Set Time Interval','Callback',{@tintvl_Callback});
eph(3) = uimenu(pmh,'Label','Set Path','Callback',{@setpath_Callback});
eph(4) = uimenu(pmh,'Label','Set Path Code','Callback',{@pc_Callback});
eph(5) = uimenu(pmh,'Label','Set File Prefix','Callback',{@radtype_Callback});
eph(6) = uimenu(pmh,'Label','Use Standard File Prefix','Callback',{@radtypestd_Callback});
eph(7) = uimenu(pmh,'Label','Set Maximum Velocity for Colorbar','Callback',{@maxcolorbutton_Callback});
eph(8) = uimenu(pmh,'Label','Set GDOP Threshold for Display','Callback',{@gdopbutton_Callback});
eph(9) = uimenu(pmh,'Label','Set OI Threshold for Display','Callback',{@oibutton_Callback});


xmh = uimenu(f,'Label','Extras');
exh(1) = uimenu(xmh,'Label','Define Custom Zoom','Callback',{@custommap_Callback});
exh(2) = uimenu(xmh,'Label','Select Plot List File','Callback',{@createplotlistbutton_Callback});
exh(3) = uimenu(xmh,'Label','Towards/Away Colors (default)','Callback',{@tabutton_Callback});
exh(4) = uimenu(xmh,'Label','North/South Colors','Callback',{@nsbutton_Callback});
exh(5) = uimenu(xmh,'Label','East/West Colors','Callback',{@ewbutton_Callback});
exh(6) = uimenu(xmh,'Label','Range Ring','Callback',{@rangeringbutton_Callback});
exh(7) = uimenu(xmh,'Label','Save Scale','Callback',{@savescalebutton_Callback});
exh(8) = uimenu(xmh,'Label','Load New Setup File','Callback',{@loadnewsetup_Callback});


% Create custom toolbar

% Start with standard toolbar and remove unwanted tools
set(f,'Toolbar','figure');
tbh = findall(f,'Type','uitoolbar');
sbh = findall(tbh);

dh = findall(sbh,'Tag','Plottools.PlottoolsOn');
dh = [dh findall(sbh,'Tag','Plottools.PlottoolsOff')];
dh = [dh findall(sbh,'Tag','DataManager.Linking')];
dh = [dh findall(sbh,'Tag','Exploration.Brushing')];
dh = [dh findall(sbh,'Tag','Exploration.Rotate')];
dh = [dh findall(sbh,'Tag','Exploration.Pan')];
dh = [dh findall(sbh,'Tag','Standard.FileOpen')];
dh = [dh findall(sbh,'Tag','Standard.NewFigure')];
dh = [dh findall(sbh,'Tag','Annotation.InsertColorbar')];
dh = [dh findall(sbh,'Tag','Annotation.InsertLegend')];

delete(dh)

ICONS = load('myicon.mat');

% Add my tools
displaysettingstool = uitoggletool(tbh,'CData',ICONS.info_icon,...
    'TooltipString','Display Current Settings','ClickedCallback',{@displaysettingsbutton_Callback},...
    'HandleVisibility','off');

imagetool = uipushtool(tbh,'CData',ICONS.exportimage_icon,...
    'TooltipString','Save Image','ClickedCallback',{@exportimagebutton_Callback},...
    'HandleVisibility','off');
qtool = uitoggletool(tbh,'CData',ICONS.arrow_icon,'Separator','on',...
    'TooltipString','Arrow Style',...
    'HandleVisibility','off','ClickedCallback',{@display_settings});
ttool = uitoggletool(tbh,'CData',ICONS.thin_icon,'Separator','on',...
    'TooltipString','Display Fewer Arrows',...
    'HandleVisibility','off','ClickedCallback',{@display_settings});
rbtool = uitoggletool(tbh,'CData',ICONS.rb_icon,'Separator','on',...
    'TooltipString','Red/blue color scheme (for radials only)',...
    'HandleVisibility','off','ClickedCallback',{@display_settings});
ctool = uitoggletool(tbh,'CData',ICONS.color_icon,'Separator','on',...
    'TooltipString','Change Plot Colors (for quiver arrows only)',...
    'HandleVisibility','off','ClickedCallback',{@colorbutton_Callback});
scaleuptool = uipushtool(tbh,'CData',ICONS.scaleup_icon,...
    'TooltipString','Larger Arrows (for quiver arrows only)','ClickedCallback',{@scaleupbutton_Callback},...
    'HandleVisibility','off');
scaledowntool = uipushtool(tbh,'CData',ICONS.scaledown_icon,...
    'TooltipString','Smaller Arrows (for quiver arrows only)','ClickedCallback',{@scaledownbutton_Callback},...
    'HandleVisibility','off');
scalevaluetool = uipushtool(tbh,'CData',ICONS.scale_icon,...
    'TooltipString','Set Arrow Scale','ClickedCallback',{@scalevaluebutton_Callback},...
    'HandleVisibility','off');

tottool = uitoggletool(tbh,'CData',ICONS.total_icon,'Separator','on',...
    'TooltipString','Plot Total Vectors',...
    'HandleVisibility','off','ClickedCallback',{@display_settings});
rtypetool = uitoggletool(tbh,'CData',ICONS.rtype_icon,'Separator','on','Tag','RTypeTool',...
    'TooltipString','Plot Ideal Radials',...
    'HandleVisibility','off','ClickedCallback',{@display_settings});
% flagtool = uitoggletool(tbh,'CData',ICONS.flag_icon,'Separator','on','Tag','FlagTool',...
%     'TooltipString','Display Flagged Vectors',...
%     'HandleVisibility','off','ClickedCallback',{@display_settings});
choosefiletool = uitoggletool(tbh,'CData',ICONS.choosefile_icon,'Separator','on',...
    'TooltipString','Select a File',...
    'HandleVisibility','off','ClickedCallback',{@display_settings});
threddstool = uitoggletool(tbh,'CData',ICONS.thredds_icon,...
    'TooltipString','Thredds Mid-Atlantic OI Totals','ClickedCallback',{@display_settings},...
    'HandleVisibility','off');
listtool = uitoggletool(tbh,'CData',ICONS.list_icon,...
    'TooltipString','Use FileList','ClickedCallback',{@display_settings},...
    'HandleVisibility','off');

bcktool = uipushtool(tbh,'CData',ICONS.bck_icon,...
    'TooltipString','Previous Time','ClickedCallback',{@bckbutton_Callback},...
    'HandleVisibility','off');
fwdtool = uipushtool(tbh,'CData',ICONS.fwd_icon,...
    'TooltipString','Next Time','ClickedCallback',{@fwdbutton_Callback},...
    'HandleVisibility','off');

cleartool = uipushtool(tbh,'CData',ICONS.clear_icon,...
    'TooltipString','Clear Plot','ClickedCallback',{@clearbutton_Callback},...
    'HandleVisibility','off');
plottool = uipushtool(tbh,'CData',ICONS.plot_icon,...
    'TooltipString','Plot','ClickedCallback',{@plotbutton_Callback},...
    'HandleVisibility','off');


ha = axes('FontSize',12);


% Initialize the GUI.
% Change units to normalized so components resize
% automatically.
set([f,ha],...
    'Units','normalized');  % hplotsouth,hplotbay

% Assign the GUI a name to appear in the window title.
set(f,'Name','HFRADAR Viewer GUI')
set(f,'NumberTitle','off')
% Move the GUI to the center of the screen.
movegui(f,'center')
% Make the GUI visible.
set(f,'Color',[0.7 0.9 1])

set(f,'Visible','on');

% figure to display current setting information
f1 = figure('Visible','off','Position',[360,450,500,200]);
display_settings;

clearbutton_Callback;

%  CALLBACK FUNCTIONS


    function setpath_Callback(~,~)
        % Allows user to define default paths for pulling radial and total data.
        rort = inputdlg('Press 1 to set radial path.  Press 2 to set total path. ','Which path?',1,{'1'},'on');
        rort = str2double(char(rort));
        if rort == 1
            radialpath = uigetdir(radialpath,'Select folder containing radial data.');
            radialpath = [radialpath,'/'];
            
        elseif rort == 2
            totalpath = uigetdir(totalpath,'Select folder containing total data.');
            totalpath = [totalpath,'/'];
        else
            disp('Wrong choice. Select "Set Path" again and press 1 to set the radial path or 2 to set the total path.');
        end
        display_settings;
    end

    function pc_Callback(~,~)
        % Allows user to define default path codes for pulling radial and total data.
        rort = inputdlg('Press 1 to set radial path.  Press 2 to set total path. ','Which path?',1,{'1'},'on');
        rort = str2double(char(rort));
        if rort == 1
            rpcode = inputdlg('Enter Path Code For RADIAL Files','RADIAL Path Code',1,{rpcode});
            rpcode = char(rpcode);
        elseif rort == 2
            tpcode = inputdlg('Enter Path Code For RADIAL Files','RADIAL Path Code',1,{tpcode});
            tpcode = char(tpcode);
        else
            disp('Wrong choice');
        end
        display_settings;
    end

% DATA SELECTION CALLBACKS

    function date_Callback(~,~)
        % Allows user to enter the time.
        dtmp = inputdlg('yyyy_mm_dd_hhMM','Enter Time',1,{dtmp});
        dtmp = char(dtmp);
        disp(dtmp)
        yy = str2double(dtmp(1:4));  mm = str2double(dtmp(6:7));  dd = str2double(dtmp(9:10)); hh = str2double(dtmp(12:13)); MM = str2double(dtmp(14:15));
        dv = [yy mm dd hh MM 0];
        dnum = datenum(dv);
        display_settings;
    end

    function tintvl_Callback(~,~)
        tintvl = inputdlg('Enter Time Interval (in hours)','Set Time Interval',1,{num2str(tintvl)});
        tintvl = str2double(char(tintvl));
    end

    function map_Callback(~,~)
        mapval = get(gcbo,'Position');
        sgrid = char(AA.HFR_MAPS(mapval).name);
        
        %scq = (latlondist(AA.HFR_MAPS(mapval).limits(1,3),AA.HFR_MAPS(mapval).limits(1,1), AA.HFR_MAPS(mapval).limits(1,4), AA.HFR_MAPS(mapval).limits(1,2))./376000);
        %scq = 0.003;
        scq = AA.HFR_MAPS(mapval).scalefactor;
        clearbutton_Callback;
        display_settings;
    end

    function station_Callback(~,~)
        % menu callback for site selection.
        stnval = get(gcbo,'Position');
        sname = char(STN_INFO(stnval).name);
        disp(sname);
        display_settings;
    end

    function radtype_Callback(~,~)
        if strcmp(get(tottool,'State'),'on')
            stpre = inputdlg('Enter Prefix For TOTAL Vector File','Prefix Selection',1,{'tuv_oi_MARA'});
            stpre = char(stpre);
        else
            srpre = inputdlg('Enter Prefix For RADIAL Vector File','Prefix Selection',1,{'RDLe'});
            srpre = char(srpre);
        end
        display_settings;
    end

    function radtypestd_Callback(~,~)
        srpre = ''; stpre = '';
        display_settings;
    end


% PLOT CONTROL CALLBACKS

    function plotbutton_Callback(~,~)
        if strcmp(get(listtool,'State'),'on') % CALL PLOT MULTIPLE TIMES, USE USER'S FILELIST WITH CURRENTLY SELECTED DATE
            xx = 1;
            while xx <= nf
                plot_Callback;
                xx = xx+1;
            end
            xx = [];
        else
            plot_Callback;
        end
    end


    function plot_Callback(~,~)
        % Plots radial or total vectors.
        
        set(0,'CurrentFigure',f);
        if strcmp(get(threddstool,'State'),'on') % PLOT RUTGERS OI TOTALS DOWNLOADED FROM THREDDS
            disp('Contacting Thredds server.  Please wait - the data may take up to 60 seconds to load.');
            threddsbutton_Callback;
            
            
            
        else
            
            
            % --------------------------- BEGIN LOAD DATA SECTION ------------------------- %
            
            clear DATA RDATA
            
            
            if ~isempty(xx)
                % GET DATA FILE NAME FROM USER'S FILELIST USING SELECTED DATE
                if ~isempty(filelist{xx})
                    myfilename = char(filelist{xx});
                    pat = '\d\d\d\d_\d\d_\d\d_\d\d\d\d';
                    dst = regexp(myfilename, pat, 'start');
                    myfilename(dst:dst+14) = dtmp;
                    if ~isempty(strfind(myfilename,' '))
                        pathspace = 1;
                    else
                        pathspace = 0;
                    end
                    % LOAD DATA FROM MAT FILE OR .RUV
                    if strcmp(myfilename(end-3:end),'.mat')
                        try
                            DATA = load(myfilename);
                        catch
                            msgbox(sprintf('Error: File not found.\n%s',myfilename));
                        end
                    else
                        DATA = loadRDLFile(myfilename);
                        if isempty(DATA.LonLat)
                            clear DATA
                            msgbox(sprintf('Error: File not found.\n%s',myfilename));
                        end
                    end
                    if exist('DATA','var') == 1
                        % ASSIGN CORRECT VARIABLE TO DATA BASED ON WHETHER IT IS RADIAL OR TOTAL DATA
                        if isfield(DATA,'TUV') || isfield(DATA,'TUVoi')
                            set(tottool,'State','on')
                            DATA = DATA.TUV;
                        elseif isfield(DATA,'RADIAL_struct_version')
                            set(tottool,'State','off')
                            if isfield(DATA,'RADIAL')
                                DATA = DATA.RADIAL;
                            end
                        end
                    end
                end %if not empty place in filelist
                
            else
                % NOT USING A CUSTOM FILE LIST
                
                
                % GET TOTALS FILE NAME
                if strcmp(get(tottool,'State'),'on')
                    % GET TOTALS FILE NAME FROM USER SELECTED FILE
                    if strcmp(get(choosefiletool,'State'),'on') %if 'choose file" box is checked
                        cdir = pwd;
                        if ~isequal(newfilepath,0)
                            try
                              eval(['cd ''',newfilepath,'''']);
                            catch
                              eval(['cd ',newfilepath]);
                            end
                        else
                            try
                            %eval(['cd ''',AA.HFR_PATHS.gui_dir,'TestTotals/',char(AA.HFR_MAPS(mapval).name),'''']);
                                eval(['cd ''',AA.HFR_PATHS.gui_dir,'''']);
                            catch
                                eval(['cd ',AA.HFR_PATHS.gui_dir]);
                            end
                            
                        end
                        [newfile,newfilepath] = uigetfile('*.*','Choose a data file');
                        myfilename = [newfilepath,newfile];
                        disp(['Loading...',myfilename])
                        try
                          eval(['cd ''',cdir,''''])
                        catch
                          eval(['cd ',cdir])
                        end
                        % GET TOTALS FILE NAME FROM DEFAULT SETTINGS
                    else
                        myfilename = getfilename();
                        disp(['Loading...',myfilename])
                    end
                    
                    % LOAD TOTALS DATA
                    try
                        DATA = load(myfilename);
                        if isfield(DATA,'RTUV')
                            RDATA = DATA.RTUV;
                        end
                        DATA = DATA.TUV;
                    catch
                        msgbox(sprintf('Error: File not found.\n%s',myfilename));
                    end
                    
                    
                    % GET RADIAL FILE NAME
                else
                    % GET THE RADIAL FILE NAME FROM USER SELECTED FILE
                    if strcmp(get(choosefiletool,'State'),'on') %if 'choose file" box is checked
                        cdir = pwd;
                        if ~isequal(newfilepath,0)
                            try
                              eval(['cd ''',newfilepath,'''']);
                            catch
                              eval(['cd ',newfilepath]);
                            end
                        else
                            try
                              eval(['cd ''',AA.HFR_PATHS.gui_dir,'RadialEdits/',sname,'''']);
                            catch
                              eval(['cd ',AA.HFR_PATHS.gui_dir,'RadialEdits/',sname]);
                            end
                        end
                        [newfile,newfilepath] = uigetfile('*.*','Choose a data file');
                        myfilename = [newfilepath,newfile];
                        disp(['Loading...',myfilename])
                        try
                          eval(['cd ''',cdir,''''])
                        catch
                          eval(['cd ',cdir])
                        end
                        
                        % LOAD RADIAL FILE NAME FROM DEFAULT SETTINGS
                    else
                        myfilename = getfilename();
                        disp(['Loading...',myfilename])
                    end
                    
                    % LOAD RADIAL DATA
                    if strcmp(myfilename(end-3:end),'.mat')
                        try
                            DATA = load([myfilename(1:length(myfilename)-3),'mat']);
                            DATA = DATA.RADIAL;
                        catch
                            clear DATA
                            msgbox(sprintf('Error: File not found.\n%s',myfilename));
                        end
                    else
                        DATA = loadRDLFile(myfilename);
                        if isempty(DATA.LonLat)
                            clear DATA
                            msgbox(sprintf('Error: File not found.\n%s',myfilename));
                        end
                    end
                    
                    
                end   % if totals else radials
                
            end  % if filelist else no filelist
            
            % --------------------------- END LOAD DATA SECTION ------------------------- %
            
            if exist('DATA','var')==1
                
                
                % IF TOTALS THEN MASK WITH GDOP
                %if strcmp(get(tottool,'State'),'on'); % plot totals
                if isfield(DATA,'ErrorEstimates')
                    try
                        GDOP = DATA.ErrorEstimates(2).TotalErrors;
                        ikeep = find(GDOP <= gdopval);
                        DATA = subsrefTUV( DATA, ikeep, ':', 0, 0 );
                    catch
                        disp('Did not find UWLSQ error estimates.  No GDOP mask applied.')
                    end
                    
                    try
                        Uerr = DATA.ErrorEstimates.Uerr;
                        Verr = DATA.ErrorEstimates.Verr;
                        ikeep = find(Uerr <= oival & Verr <= oival);
                        DATA = subsrefTUV( DATA, ikeep, ':', 0, 0 );
                    catch
                        disp('Did not find OI error estimates.  No OI mask applied.')
                    end
                end
                
                
                % THIN OUT DATA IF REQUESTED
                if strcmp(get(ttool,'State'),'on')
                    clear ZZ ZZZ
                    if strcmp(get(tottool,'State'),'on') % thin out totals
                        if ~isempty(DATA.U)
                            
                            latlist = unique(DATA.LonLat(:,1));
                            latset = latlist(1:2:length(latlist));
                            ZZ = ismember(DATA.LonLat(:,1),latset);
                            lonlist = unique(DATA.LonLat(:,2));
                            lonset = lonlist(1:2:length(lonlist));
                            ZZZ = ismember(DATA.LonLat(:,2),lonset);
                            DATA.U = DATA.U.*ZZ.*ZZZ;
                            DATA.V = DATA.V.*ZZ.*ZZZ;
                            DATA.LonLat = DATA.LonLat.*repmat(ZZ.*ZZZ,1,2);
                            
                        end
                        
                        
                    else  % thin out radials
                        
                        if ~isempty(DATA.U)
                            rangelist = unique(DATA.RangeBearHead(:,1));
                            rset = rangelist(1:2:length(rangelist));
                            %dirlist = unique(DATA.RangeBearHead(:,2));
                            %dirset = dirlist(1:2:length(dirlist));
                            ZZ = ismember(DATA.RangeBearHead(:,1),rset);
                            DATA.U = DATA.U.*ZZ;
                            DATA.V = DATA.V.*ZZ;
                            DATA.LonLat = DATA.LonLat.*repmat(ZZ,1,2);
                        end
                    end
                end
                
                
                % ------------------------------ PLOT DATA --------------------------------- %
                
                hold on % add to current plot (plot may be cleared by user or cleared automatically by use of the time and scale buttons)
                
                % draw markers for radial site locations if radial data is
                % included in the total file
                if exist('RDATA', 'var')
                    for jj = 1:size(RDATA,1)
                        if ~isempty(RDATA(jj).U)
                            if strcmp(RDATA(jj).Type,'RDLMeasured')
                                m_plot(RDATA(jj).SiteOrigin(:,1),RDATA(jj).SiteOrigin(:,2),'Marker','^','MarkerFaceColor','g','MarkerSize',16);
                            elseif strcmp(RDATA(jj).Type,'RDLIdeal')
                                m_plot(RDATA(jj).SiteOrigin(:,1),RDATA(jj).SiteOrigin(:,2),'Marker','s','MarkerFaceColor','r','MarkerSize',16);
                            end
                        end
                    end
                end
                
                
                
                %USE QUIVER ARROWS
                
                % do not display flagged values unless requested
%                 if  strcmp(get(tottool,'State'),'off')
%                     if strcmp(get(flagtool,'State'),'on')
%                     else
%                         DATA.U(DATA.Flag == 128) = NaN;
%                         DATA.V(DATA.Flag == 128) = NaN;
%                     end
%                 end
                if strcmp(get(qtool,'State'),'on')
                    %do not plot vectors outside the map/zoom area
                    imap = find(DATA.LonLat(:,1)>AA.HFR_MAPS(mapval).limits(1,1) & DATA.LonLat(:,1)<AA.HFR_MAPS(mapval).limits(1,2) & DATA.LonLat(:,2)>AA.HFR_MAPS(mapval).limits(1,3) & DATA.LonLat(:,2)<AA.HFR_MAPS(mapval).limits(1,4));
                    plothandles(pcount) = m_quiver(DATA.LonLat(imap,1), DATA.LonLat(imap,2), DATA.U(imap).*scq,DATA.V(imap).*scq,0);
                    
                    if strcmp(get(tottool,'State'),'off') && strcmp(get(rbtool,'State'),'on') % for radials with red/blue settings
                        if ns
                            to = find(DATA.V(imap) > 0);       % current going NORTH
                            [~, dchk] = uv2spdir(DATA.U(imap),DATA.V(imap));
                            rm1 = find(math2true(dchk) > 45 & math2true(dchk) < 135);% find angles that are not close enough to vertical
                            rm2 = find(math2true(dchk) > 225 & math2true(dchk) < 315);
                            rmang = [rm1;rm2];
                        elseif ew
                            to = find(DATA.U(imap) > 0);       % current going EAST
                            [~, dchk] = uv2spdir(DATA.U(imap),DATA.V(imap));
                            rm1 = find(dchk > 45 & dchk < 135);% find angles that are not close enough to horizontal
                            rm2 = find(dchk > 225 & dchk < 315);
                            rmang = [rm1;rm2];
                        else
                            to = find(DATA.RadComp(imap) > 0); % current going away from RADAR
                            rmang = [];
                        end
                        hold on
                        set(plothandles(pcount),'Color','r')
                        pcount = pcount + 1;
                        plothandles(pcount) = m_quiver(DATA.LonLat(imap(to),1), DATA.LonLat(imap(to),2), DATA.U(imap(to)).*scq,DATA.V(imap(to)).*scq,0);
                        set(plothandles(pcount),'Color','b')
                        if ~isempty(rmang)
                            plothandles(pcount) = m_quiver(DATA.LonLat(imap(rmang),1), DATA.LonLat(imap(rmang),2), DATA.U(imap(rmang)).*scq,DATA.V(imap(rmang)).*scq,0);
                            set(plothandles(pcount),'Color','w')
                        end
                        
                    else
                        %if strcmp(get(tottool,'State'),'on')
                        %any special instructions for totals when not using rb color
                        %scheme
                        %else
                        set(plothandles(pcount),'Color',mycolors(pcount,:))  % varying colors for radials
                        pcount = pcount + 1;
                        %end
                    end
                    
                    if exist('fnt','var')
                        delete(fnt);
                    end;
                    
                    if ~isempty(max(strfind(myfilename,'/')))
                        titlelab{pcount} = myfilename(max(strfind(myfilename,'/'))+1:end-4);
                    else
                        titlelab{pcount} = myfilename;
                    end
                    title(titlelab,'interpreter','none','Color','k','FontSize',12);
                    fnt = text(-0.1,-0.1,myfilename,'Color','k','FontSize',8,'Units','normalized','interpreter','none');
                    
                    plotscalearrow(scq,arrow_spd);
                    
                    %dcm_obj = datacursormode(gcf);
                    %set(dcm_obj,'enable','on')
                    %set(dcm_obj,'UpdateFcn',getel);
                    
                    %          rclon = load([AA.HFR_PATHS.gui_dir,'GridFiles/',char(DATA.SiteName),'.mat']);
                    %          rclat = rclon.rclat; rclon = rclon.rclon;
                    %          for cc = 1:length(rclon);
                    %            m_plot([DATA.SiteOrigin(1,1) rclon(cc)], [DATA.SiteOrigin(1,2) rclat(cc)]);
                    %          end
                    %          m_range_ring(DATA.SiteOrigin(1,1), DATA.SiteOrigin(1,2),unique(DATA.RangeBearHead(:,1))-mean(diff(unique(DATA.RangeBearHead(:,1))))/2,72+1, 'Color', 'k');
                    
                    
                    %USE MVEC ARROWS
                else
                    % do not display flagged values unless requested
%                     if strcmp(get(tottool,'State'),'off')
%                         if strcmp(get(flagtool,'State'),'on')
%                         else
%                             DATA.U(DATA.Flag == 128) = NaN;
%                             DATA.V(DATA.Flag == 128) = NaN;
%                         end
%                     end
                    % make all vectors the same size
                    clear tspd tdir Usc Vsc
                    %do not plot vectors outside the map area
                    imap = find(DATA.LonLat(:,1)>AA.HFR_MAPS(mapval).limits(1,1) & DATA.LonLat(:,1)<AA.HFR_MAPS(mapval).limits(1,2) & DATA.LonLat(:,2)>AA.HFR_MAPS(mapval).limits(1,3) & DATA.LonLat(:,2)<AA.HFR_MAPS(mapval).limits(1,4));
                    [spd,direc] = uv2spdir(DATA.U(imap),DATA.V(imap));
                    [~,isort] = sort(spd);
                    scs = zeros(length(spd),1) + sc;
                    [Usc, Vsc] =  spddir2uv(scs, direc(isort));
                    
                    
                    if strcmp(get(tottool,'State'),'on')        % set color categories for totals
                        edges = 1:1:maxcolor;  %cm/s
                        cmap = colormap(jet(length(edges)+1));
                    else                                          % set color categories for radials
                        if strcmp(get(rbtool,'State'),'on')       % purple/blue color scheme
                            if ns
                                to = find(DATA.V(imap) > 0);            % current going NORTH
                            elseif ew
                                to = find(DATA.U(imap) > 0);            % current going EAST
                            else
                                to = find(DATA.RadComp(imap) > 0);      % current going away from RADAR
                            end
                            spd(to) = -(spd(to));                    % when sorted this puts all the "to" arrows in the blue color range
                            edges = -maxcolor:1:maxcolor;
                            cmap = colormap(cool(length(edges)+1));
                            %use interpolated version of Hugh Roarty redblue colormap for mvec arrow dual color scheme 
                            cmap = interp_redblue(length(edges)+1);
                            colormap(cmap);
                        else                                       % standard jet color scheme
                            edges = 1:1:maxcolor;  %cm/s
                            cmap = colormap(jet(length(edges)+1));
                        end
                    end
                    
                    edges = [-inf edges inf];                     % speeds under/over a min/max value will be drawn with same color as the min/max value
                    [~,BIN] = histc(spd(isort),edges);
                    for ii = 1:length(BIN)
                        try
                            cvals(ii,:) = cmap(BIN(ii),:);
                        catch
                            cvals(ii,:) = [1 1 1];  % white for bins with no values
                        end
                    end
                    
                    aa = 1:length(BIN);
                    plothandles(pcount) = m_vec(1,DATA.LonLat(imap(isort(aa)),1), DATA.LonLat(imap(isort(aa)),2), Usc(aa),Vsc(aa),cvals(aa,:),'headlength',4);
                    pcount = pcount+1;
                    
                    if exist('fnt','var')
                        delete(fnt);
                    end;
                    
                    if ~isempty(max(strfind(myfilename,'/')))
                        titlelab{pcount} = myfilename(max(strfind(myfilename,'/'))+1:end-4);
                    else
                        titlelab{pcount} = myfilename;
                    end
                    title(titlelab,'interpreter','none','Color',[0 0 0],'FontSize',12);
                    fnt = text(-0.1,-0.1,myfilename,'Color','k','FontSize',8,'Units','normalized','interpreter','none');
                    
                    hold on
                    plotcolorbar(cmap,edges);
                end %plot data section
                
            end %is DATA loaded section
            
        end  %if thredds
        
    end  %plot_Callback

    function clearbutton_Callback(~,~)
        % Clears the plot.
        
        set(0,'CurrentFigure',f);
        if (~new)
            ap = get(ha,'Position');
            delete(ha);
            ha = axes('Units','normalized','Position',ap);
        else
            ha = axes('Units','Pixels','Position',[50,60,fw-200,fh-100]);
        end
        plothandles = [];
        pcount = 1;
        titlelab = cell(1,1);
        
        try
            xmin = AA.HFR_MAPS(mapval).limits(1); xmax = AA.HFR_MAPS(mapval).limits(2);
            ymin = AA.HFR_MAPS(mapval).limits(3); ymax = AA.HFR_MAPS(mapval).limits(4);
        catch
            msgbox('Warning: Define custom zoom under "Extras" menu.');
        end
        
        try  %added this because quotes handled differently on different systems
            plotBasemap([AA.HFR_MAPS(mapval).limits(1,1) AA.HFR_MAPS(mapval).limits(1,2)],[AA.HFR_MAPS(mapval).limits(1,3) AA.HFR_MAPS(mapval).limits(1,4)],['''',AA.HFR_PATHS.gui_dir,'GridFiles/map_',sgrid,'.mat'''],'lambert','patch',[0.8 0.8 0.8])
        catch
            plotBasemap([AA.HFR_MAPS(mapval).limits(1,1) AA.HFR_MAPS(mapval).limits(1,2)],[AA.HFR_MAPS(mapval).limits(1,3) AA.HFR_MAPS(mapval).limits(1,4)],[AA.HFR_PATHS.gui_dir,'GridFiles/map_',sgrid,'.mat'],'lambert','patch',[0.8 0.8 0.8])
        end
        %plotBasemap([xmin-padx xmax+padx],[ymin-pady ymax+pady],['''',AA.HFR_PATHS.gui_dir,'GridFiles/map_',sgrid,'.mat'''],'lambert','patch',[0.8 0.8 0.8])
        hold on
    end

    function fwdbutton_Callback(source,eventdata)
        % Advances currently selected date by one hour.
        ap = get(ha,'Position');
        delete(ha);
        set(0,'CurrentFigure',f);
        ha = axes('Units','normalized','Position',ap);
        
        adv1 = datenum([yy mm dd hh MM 0])+(tintvl/24);
        dtmp = datestr(adv1,'yyyy_mm_dd_HHMM');
        yy = str2double(dtmp(1:4));  mm = str2double(dtmp(6:7));  dd = str2double(dtmp(9:10)); hh = str2double(dtmp(12:13)); MM = str2double(dtmp(14:15));
        dv = [yy mm dd hh MM 0];
        dnum = datenum(dv);
        clearbutton_Callback(source,eventdata)
        plotbutton_Callback(source,eventdata)
        display_settings;
        
    end

    function bckbutton_Callback(source,eventdata)
        % Subtracts one hour from currently selected date.
        ap = get(ha,'Position');
        delete(ha);
        set(0,'CurrentFigure',f);
        ha = axes('Units','normalized','Position',ap);
        
        adv1 = datenum([yy mm dd hh MM 0])-(tintvl/24);
        dtmp = datestr(adv1,'yyyy_mm_dd_HHMM');
        yy = str2double(dtmp(1:4));  mm = str2double(dtmp(6:7));  dd = str2double(dtmp(9:10)); hh = str2double(dtmp(12:13)); MM = str2double(dtmp(14:15));
        dv = [yy mm dd hh MM 0];
        dnum = datenum(dv);
        clearbutton_Callback(source,eventdata)
        plotbutton_Callback(source,eventdata)
        display_settings;
        
    end

    function scaleupbutton_Callback(source,eventdata)
        % Increases scale for quiver arrows.
        scq = scq + 0.0001;
        display_settings;
        clearbutton_Callback(source,eventdata)
        plotbutton_Callback(source,eventdata)
    end

    function scaledownbutton_Callback(source,eventdata)
        % Decreases scale for quiver arrows.
        scq = scq - 0.0001;
        display_settings;
        clearbutton_Callback(source,eventdata)
        plotbutton_Callback(source,eventdata)
    end

    function scalevaluebutton_Callback(~,~)
        % Allows user to set scale for arrows.
        if strcmp(get(qtool,'State'),'on')
            temp = str2double(char(inputdlg(sprintf('Enter new scaling factor.  Current value is %7.5f',scq),'Name')));
            if ~isempty(temp)
                scq = temp;
            end
        else
            temp = str2double(char(inputdlg(sprintf('Enter new scaling factor.  Current value is %7.5f',sc),'Name')));
            if ~isempty(temp)
                sc = temp;
            end
        end
        display_settings;
    end

    function colorbutton_Callback(~,~)
        myhandle = input(['Enter plot number. 1-',num2str(pcount-1),' ']);
        setcolor = uisetcolor();
        set(plothandles(myhandle),'Color',setcolor);
    end

    function maxcolorbutton_Callback(~,~)
        maxcolor = inputdlg('Enter Colorbar Maximum Velocity (cm/s) ','Set Colorbar');
        maxcolor = str2double(char(maxcolor));
    end

% ACTION CALLBACKS

    function editbutton_Callback(~,~)
        % Hand edit the radial map.
        myfilename = getfilename();
        disp(['Loading...',myfilename])
        try
            Re = loadRDLFile(myfilename);
        catch
            Re = load([myfilename(1:length(myfilename)-3),'mat']);
            Re = Re.RADIAL;
        end
        
        if ~isempty(Re.U)
            if ~isempty(max(strfind(myfilename,'/')))
                try
                    shortname = myfilename(max(strfind(myfilename,'/'))+1:end-4);
                end
            else
                shortname = myfilename;
            end
            
            
            away = find(Re.RadComp(:) < 0); % current going away from RADAR
            to = find(Re.RadComp(:) > 0); % current going toward RADAR
            
            figure(10)
            hold on
            H3 = quiver(Re.LonLat(to,1), Re.LonLat(to,2), Re.U(to).*scq,Re.V(to).*scq,0);
            set(H3,'Color','b')
            H4 = quiver(Re.LonLat(away,1), Re.LonLat(away,2), Re.U(away).*scq,Re.V(away).*scq,0);
            set(H4,'Color','r')
            title([shortname,' '],'interpreter','none')
            xlim_orig = get(gca,'XLim');
            ylim_orig = get(gca,'YLim');
            
            ee = 1;
            ei = [];
            [~] = input('Adjust zoom and press enter when ready.');
            xlim_zoom = get(gca,'XLim');
            ylim_zoom = get(gca,'YLim');
            while isempty(ee) || ee == 1
                
                [gx,gy] = ginput(1);
                close(10);
                DD = latlondist(Re.LonLat(:,2),Re.LonLat(:,1),gy,gx);
                [~, mind] = min(abs(DD));
                Re.U(mind) = NaN;
                Re.V(mind) = NaN;
                ei = [ei; mind];
                
                
                away = find(Re.RadComp(:) < 0); % current going away from RADAR
                to = find(Re.RadComp(:) > 0); % current going toward RADAR
                
                figure(10)
                hold on
                H3 = quiver(Re.LonLat(to,1), Re.LonLat(to,2), Re.U(to).*scq,Re.V(to).*scq,0);
                set(H3,'Color','b')
                H4 = quiver(Re.LonLat(away,1), Re.LonLat(away,2), Re.U(away).*scq,Re.V(away).*scq,0);
                set(H4,'Color','r')
                title([shortname,' '],'interpreter','none')
                set(gca,'XLim',xlim_zoom,'YLim',ylim_zoom)
                uicontrol('Style','pushbutton','String','Zoom Out',...
                    'Position',[0,0,100,20],'Callback',['set(gca,''XLim'',[',num2str(xlim_orig(1)),',',num2str(xlim_orig(2)),'],''YLim'',[',num2str(ylim_orig(1)),',',num2str(ylim_orig(2)),'])']);
                uicontrol('Style','pushbutton','String','Zoom In',...
                    'Position',[125,0,100,20],'Callback','zoom on');
                
                
                ee = input('Press enter when ready or enter 0 to stop editing.');
                xlim_zoom = get(gca,'XLim');
                ylim_zoom = get(gca,'YLim');
                
            end
            close(10);
            
            notnan = find(~isnan(Re.U));
            tmp0 = subsrefRADIAL( Re, notnan, ':', 0);
            
            ss = input('Press 1 to save. ');
            if ss
                RADIAL = tmp0;
                epre = input('What prefix? (Limit to 4 characters, e.g. RDLe) ','s');
                disp(['Saving to ',AA.HFR_PATHS.gui_dir,'RadialEdits/',sname,'/',epre,shortname(5:end)])
                try
                  eval(['save ''',AA.HFR_PATHS.gui_dir,'RadialEdits/',sname,'/',epre,shortname(5:end), ''' RADIAL ei']);
                catch
                  eval(['save ',AA.HFR_PATHS.gui_dir,'RadialEdits/',sname,'/',epre,shortname(5:end), ' RADIAL ei']);                    
                end
            end
        end
    end


    function autoeditbutton_Callback(~,~)
        % calls gui to compute total
        autoedit_gui(dnum);
    end

    function totalbutton_Callback(~,~)
        % calls gui to compute total
        maketotal_gui(dnum);
    end

    function checktotalbutton_Callback(source,eventdata)
        % Allows user to select a total vector to check what radials were used to compute the total.
        % Assumes default processing settings for totals.
        
        cdir = pwd;
        %eval(['cd ''',AA.HFR_PATHS.gui_dir,'TestTotals/',char(AA.HFR_MAPS(mapval).name),'''']);
        try
          eval(['cd ''',AA.HFR_PATHS.total_dir,'''']);
        catch
          eval(['cd ',AA.HFR_PATHS.total_dir]);
        end
        [newtotal,newtotalpath] = uigetfile('*.*','Choose a data file');
        myfilename = [newtotalpath,newtotal];
        newTUV = load(myfilename);
        try
          eval(['cd ''',cdir,''''])
        catch
          eval(['cd ',cdir])
        end
        
        % reset the date in case a file of different date was chosen
        dtmp = datestr(newTUV.TUV.TimeStamp,'yyyy_mm_dd_HHMM');
        yy = str2double(dtmp(1:4));  mm = str2double(dtmp(6:7));  dd = str2double(dtmp(9:10)); hh = str2double(dtmp(12:13)); MM = str2double(dtmp(14:15));
        dv = [yy mm dd hh MM 0];
        dnum = datenum(dv);
        display_settings;
        clearbutton_Callback(source,eventdata)
        
        if isfield(newTUV, 'RTUV')
            for jj = 1:size(newTUV.RTUV,1)  %sort by latitude so neighbors don't have matching colors
                sitelats(jj) = newTUV.RTUV(jj).SiteOrigin(:,2);
            end
            [~,locsort] = sort(sitelats);
            newTUV.RTUV = newTUV.RTUV(locsort);
            for aa = 1:length(newTUV.RTUV)
                plothandles(pcount) = m_quiver(newTUV.RTUV(aa).LonLat(:,1), newTUV.RTUV(aa).LonLat(:,2), newTUV.RTUV(aa).U(:).*scq,newTUV.RTUV(aa).V(:).*scq,0);
                set(plothandles(pcount),'Color',mycolors(aa,:))
                pcount = pcount + 1;
            end
        end
        
        
        if isfield(newTUV.TUV,'ErrorEstimates')
            try
                GDOP = newTUV.TUV.ErrorEstimates(2).TotalErrors;
                ikeep = find(GDOP <= gdopval);
                T = subsrefTUV( newTUV.TUV, ikeep, ':', 0, 0 );
            catch
                disp('Did not find UWLSQ error estimates.  No GDOP mask applied.')
            end
            
            try
                Uerr = newTUV.TUV.ErrorEstimates.Uerr;
                Verr = newTUV.TUV.ErrorEstimates.Verr;
                ikeep = find(Uerr <= oival & Verr <= oival);
                T = subsrefTUV( newTUV.TUV, ikeep, ':', 0, 0 );
            catch
                disp('Did not find OI error estimates.  No OI mask applied.')
            end
        end
        
        
        %         GDOP = newTUV.TUV.ErrorEstimates(2).TotalErrors;
        %         ikeep = find(GDOP <= gdopval); %effectively does the masking
        %         T = subsrefTUV( newTUV.TUV, ikeep, ':', 0, 0 );
        
        %plothandles(pcount) = m_quiver(T.LonLat(:,1), T.LonLat(:,2), T.U(:).*scq,T.V(:).*scq,0);
        %set(plothandles(pcount),'Color','k')
        % use MVEC arrows instead
        % make all vectors the same size
        clear tspd tdir Usc Vsc
        %do not plot vectors outside the map area
        xl = get(gca,'XLim');
        yl = get(gca,'YLim');
        [minlon,minlat] = m_xy2ll(xl(1),yl(1));
        [maxlon,maxlat] = m_xy2ll(xl(2),yl(2));
        %imap = find(T.LonLat(:,1)>minlon & T.LonLat(:,1)<maxlon & T.LonLat(:,2)>minlat & T.LonLat(:,2)<maxlat);
        
        
        
        imap = find(T.LonLat(:,1)>AA.HFR_MAPS(mapval).limits(1,1) & T.LonLat(:,1)<AA.HFR_MAPS(mapval).limits(1,2) & T.LonLat(:,2)>AA.HFR_MAPS(mapval).limits(1,3) & T.LonLat(:,2)<AA.HFR_MAPS(mapval).limits(1,4));
        [spd,direc] = uv2spdir(T.U(imap),T.V(imap));
        [~,isort] = sort(spd);
        scs = zeros(length(spd),1) + sc;
        [Usc, Vsc] =  spddir2uv(scs, direc(isort));
        
        
        edges = 1:1:maxcolor;  %cm/s
        cmap = colormap(jet(length(edges)+1));
        
        
        edges = [-inf edges inf];                     % speeds under/over a min/max value will be drawn with same color as the min/max value
        [~,BIN] = histc(spd(isort),edges);
        for ii = 1:length(BIN)
            try
                cvals(ii,:) = cmap(BIN(ii),:);
            catch
                cvals(ii,:) = [1 1 1];  % white for bins with no values
            end
        end
        
        aa = 1:length(BIN);
        plothandles = m_vec(1,T.LonLat(imap(isort(aa)),1), T.LonLat(imap(isort(aa)),2), Usc(aa),Vsc(aa),cvals(aa,:),'headlength',4);
        hold on
        plotcolorbar(cmap,edges);
        
        
        
        pcount = pcount + 1;
        %plotscalearrow(scq,arrow_spd);
        
        if ~isempty(max(strfind(myfilename,'/')))
            try
                titlelab{pcount} = myfilename(max(strfind(myfilename,'/'))+1:end-4);
            end
        else
            titlelab{pcount} = myfilename;
        end
        title([titlelab{pcount},' '],'interpreter','none','Color','k','FontSize',12);
        
            %spawn a different figure to select total vector of interest
            figure(20)
            HTI = quiver(T.LonLat(:,1), T.LonLat(:,2), T.U(:).*scq,T.V(:).*scq,0);
            set(HTI,'Color','r')
            
            title([titlelab{pcount},' '],'interpreter','none');
            
            
            [~] = input('Zoom in and press enter to select total.');
            [gx,gy] = ginput(1);
            search_radius = inputdlg('Enter Search Radius (km) : ','');
            search_radius = str2double(char(search_radius));
                        
            temp_threshold = 0.5/24; %time window in fraction of day,i.e. how many hourly radial maps are included in total
            MINRadials = 3;
            MINSites = 2;
            disp('')
            disp(['Search Radius:',num2str(search_radius),' km'])
            disp(['MINRadials: ',num2str(MINRadials)])
            disp(['MINSites: ',num2str(MINSites)])
            disp(['Time Window: ',num2str(temp_threshold),' day fraction'])
            
            
            % makeTotals will only run for the gridpoint that was selected
            DD = latlondist(newTUV.TUV.LonLat(:,2),newTUV.TUV.LonLat(:,1),gy,gx);
            [~, mind] = min(abs(DD));
            grid = [newTUV.TUV.LonLat(mind,2),newTUV.TUV.LonLat(mind,1)];
            fprintf('Computing totals\n');
            if isfield(newTUV, 'RTUV')
                makeTotals_checktotal(newTUV.RTUV,'Grid',grid,'TimeStamp',newTUV.RTUV(1).TimeStamp, ...
                    'spatthresh',search_radius,'tempthresh',temp_threshold, ...
                    'CreationInfo','Teresa Updyke - ODU', ...
                    'DomainName','','MinNumSites',MINSites,'MinNumRads',MINRadials,'graphics',1,'gridind',mind);
            end
            if isfield(newTUV, 'RADS')
                makeTotals_checktotal(newTUV.RADS,'Grid',grid,'TimeStamp',newTUV.RADS(1).TimeStamp, ...
                    'spatthresh',search_radius,'tempthresh',temp_threshold, ...
                    'CreationInfo','Teresa Updyke - ODU', ...
                    'DomainName','','MinNumSites',MINSites,'MinNumRads',MINRadials,'graphics',1,'gridind',mind);
            end
        
    end

    function createplotlistbutton_Callback(~,~)
        [newfilelist,newfilelistpath] = uigetfile('*.*','Choose a data file',[AA.HFR_PATHS.gui_dir,'GridFiles/baylist1.txt']);
        filelist = cell(nf);
        fid = fopen([newfilelistpath,newfilelist],'r');
        try
            xx = 1;
            while feof(fid) == 0
                filelist{xx} = fgetl(fid);
                xx= xx+1;
            end
        catch
            disp('Bad format.')
        end
        nf = size(filelist,2);
        xx = [];
    end

    function tabutton_Callback(~,~)
        ns = 0; ew = 0;
    end
    function nsbutton_Callback(~,~)
        ns = 1; ew = 0;
    end
    function ewbutton_Callback(~,~)
        ns = 0; ew = 1;
    end

    function displaysettingsbutton_Callback(~,~)
        if strcmp(get(displaysettingstool,'State'),'on')
            set(f1,'Visible','on')
        else
            set(f1,'Visible','off')
        end
    end


    function exportimagebutton_Callback(~,~)
        myfilename = getfilename();
        if ~isempty(max(strfind(myfilename,'/')))
            try
                titlelab{pcount} = myfilename(max(strfind(myfilename,'/'))+1:end-4);
            end
        else
            titlelab{pcount} = myfilename;
        end
        disp(['Default file name is ',titlelab{pcount}]);
        ifn = input('Press return to use default name or enter a new file name. ','s');
        if ~isempty(ifn)
            eval(['print -dpng ',AA.HFR_PATHS.gui_dir,'Images/',ifn,'.png'])
        else
            eval(['print -dpng ',AA.HFR_PATHS.gui_dir,'Images/',titlelab{pcount},'.png'])
        end
    end

% SUPPORTING SUBFUNCTIONS

    function display_settings(~,~)
        % new window to display current selections
        
        xs = 0.0; ys = 0.95; spc = 0.10;
        if ishandle(f1) && strcmp(get(f1,'Type'),'figure')
            set(0,'CurrentFigure',f1);
        else
            f1 = figure('Visible','off','Position',[360,450,500,200]);
            displaysettingsbutton_Callback;
        end
        
        set(f1,'Toolbar','none');
        set(f1,'MenuBar','none')
        set(f1,'NumberTitle','off')
        set(f1,'Name','CURRENT SETTINGS')
        clf
        ha1 = axes('FontSize',12,'Visible','off');
        
        text(xs,ys-(spc*0), ['Grid: ', sgrid],'Units','normalized')
        text(xs,ys-(spc*1), ['Time: ', datestr(dnum),' UTC'],'Units','normalized');
        if strcmp(get(listtool,'State'),'on')
            currentname = 'File List - Multiple Files';
            currentfullname = currentname;
            isf = length(currentname)+1;
        else
            currentfullname = getfilename();
            if ~isempty(max(strfind(currentfullname,'/')))
                try
                    isf = strfind(currentfullname,'/');
                    currentname = currentfullname(max(strfind(currentfullname,'/'))+1:end-4);
                end
            else
                currentname = currentfullname;
                isf = length(currentname)+1;
            end
        end
        
        if strcmp(get(tottool,'State'),'on')
            text(xs,ys-(spc*2) , 'Plot Totals','Units','normalized');
            text(xs,ys-(spc*9), ['Apply GDOP Cutoff of  ',num2str(gdopval)],'Units','normalized');
            text(xs,ys-(spc*10), ['Apply OI Cutoff of  ',num2str(oival)],'Units','normalized');
            if strcmp(get(qtool,'State'),'on')
                PV = 'Single Color';
            else
                PV = 'Full Colorbar';
            end
        else
            text(xs,ys-(spc*2) , 'Plot Radials','Units','normalized');
            if strcmp(get(rbtool,'State'),'on')
                PV = 'Red/Blue Color Scheme';
            else
                if strcmp(get(qtool,'State'),'on')
                    PV = 'Single Color';
                else
                    PV = 'Full Colorbar';
                end
            end
        end
        text(xs,ys-(spc*8), ['Display ',PV],'Units','normalized');
        
        if strcmp(get(choosefiletool,'State'),'off')
            text(xs,ys-(spc*3), ['FileName: ', currentname],'Units','normalized','interpreter','none');
            text(xs,ys-(spc*4), ['Path: ',currentfullname(1:isf(end)-1) ],'Units','normalized','interpreter','none');
        else
            text(xs,ys-(spc*3),'FileName: User Choice','Units','normalized');
            text(xs,ys-(spc*4),'Path: User Choice','Units','normalized');
        end
        
        if strcmp(get(qtool,'State'),'on')
            PV = sprintf('Quiver    Scale = %7.5f',scq);
        else
            PV = 'MMap Vectors';
        end
        text(xs,ys-(spc*6), ['Arrow Style: ',PV],'Units','normalized');
        if strcmp(get(ttool,'State'),'on')
            PV = 'Fewer Vectors';
        else
            PV = 'All Vectors';
        end
        text(xs,ys-(spc*7), ['Display ',PV],'Units','normalized');
        
        
        set(0,'CurrentFigure',f);
    end


    function [myfilename] = getfilename()
        if strcmp(get(tottool,'State'),'on') % totals
            
            if ~isempty(stpre)
                tpre = stpre;
            else
                if strcmp(get(rtypetool,'State'),'on')
                    tpre = 'TOTi';
                else
                    tpre = 'TOTm';
                end
            end
            [dirname,filename] = datenum_to_directory_filename([totalpath,tpcode], dnum, [tpre,'_'], '.mat',0);
            dirname = char(dirname);
            if strcmp(dirname(end), '/') == 0
                myfilename = [dirname,'/',char(filename)];
            else
                myfilename = [dirname,char(filename)];
            end
            myfilename = pcode_translation(myfilename, dnum);
            if ~isempty(findstr(myfilename,' '))   % looks to see if path contains a space
                pathspace = 1;
            else
                pathspace = 0;
            end
            
        else %  radials
            
            if ~isempty(srpre)
                rpre = srpre;
            else
                if strcmp(get(rtypetool,'State'),'on')
                    rpre = 'RDLi';
                else
                    rpre = 'RDLm';
                end
            end
            [dirname,filename] = datenum_to_directory_filename([radialpath,rpcode], dnum, [rpre,'_',sname,'_'], '.ruv',0);
            dirname = char(dirname);
            if strcmp(dirname(end), '/') == 0
                myfilename = [dirname,'/',char(filename)];
            else
                myfilename = [dirname,char(filename)];
            end
            myfilename = pcode_translation(myfilename, dnum,sname);
            if ~isempty(findstr(myfilename,' '))   % looks to see if path contains a space
                pathspace = 1;
            else
                pathspace = 0;
            end
            
        end  % if (totals or radials?)
    end


    function plotcolorbar(cmap,edges)
        % add the colorbar with appropriate labels
        
        hcb = colorbar('East');
        set(hcb,'Units','normalized')
        A = get(hcb,'Position');  % changed from OuterPosition to Position for later version of Matlab
        set(hcb,'Position',[A(1)+0.07 A(2) A(3) A(4)]);
        maxvind = length(cmap);  % index for max value
        spacing = round((maxvind-1)./5);
        xt = (1:spacing:maxvind)';
        if (maxvind - xt(length(xt)) < spacing)
            xt(length(xt)) = maxvind;
            xtv = xt./maxvind;
        else
            xt = [xt; maxvind];
            xtv = xt./maxvind;
        end
        set(hcb, 'YTick', xtv);
        
        if edges(2) == 1
            xtl = char(num2str([0 edges(xt(2:end-1)) edges(maxvind)]'));
        else
            xtl = char(num2str([edges(2) edges(xt(2:end-1)) edges(maxvind)]'));
        end
        set(hcb, 'YTickLabel',xtl)
        %text(0.32+0.3+0.09, 0.125-0.020,'cm/s','Units','normalized')
        text(1.05,0.0,'cm/s','Units','normalized')
        
    end

    function plotscalearrow(sc,scale_arrow)
        if 0
            [xlims,ylims] = deal(get(gca,'XLim'),get(gca,'YLim'));
            xstart = xlims(1) + (abs(xlims(2)-xlims(1)).*.10);
            ystart = ylims(1) + (abs(ylims(2)-ylims(1)).*.05);
            [Xscalepos,Yscalepos]=m_xy2ll(xstart,ystart);
            %if sc < 0.0005
            %  scale_arrow = 100; %cm/s
            %else
            %  scale_arrow = 50; %cm/s
            %end
            
            hsc = m_quiver(Xscalepos,Yscalepos,sc*scale_arrow,0,0);  %produces slanted line
            set(hsc, 'Color', 'k','LineWidth',2)
            text(xstart,ystart,[num2str(scale_arrow),' cm/s '],'fontsize',12,'HorizontalAlignment','right')
        end %if 0
        
        scale_arrow=50;
        Xscalepos = -75.65;
        Yscalepos = 35.4;
        [xstart,ystart] = m_ll2xy(Xscalepos,Yscalepos);
        hsc = m_quiver(Xscalepos,Yscalepos,sc*scale_arrow,0,0);  %produces slanted line
        set(hsc, 'Color', 'k','LineWidth',2)
        text(xstart,ystart,[num2str(scale_arrow),' cm/s '],'fontsize',12,'HorizontalAlignment','right')
    end

% CALLBACKS FOR OPTIONAL EXTRAS/ CUSTOM SHORTCUTS

    function threddsbutton_Callback(~,~)
        %Retrieve and plot THREDDS totals
        
        %%[LON,LAT,U,V,Uerr,Verr,NRAD]= get_thredds_data(dnum,mapval);
        [TIME,LON,LAT,U,V,Uerr,Verr,NRAD]= get_rutgers_thredds_data_nc([dnum,dnum],[AA.HFR_MAPS(mapval).limits(1,1) AA.HFR_MAPS(mapval).limits(1,2)],[AA.HFR_MAPS(mapval).limits(1,3) AA.HFR_MAPS(mapval).limits(1,4)]);
        %[TIME,LON,LAT,U,V,Uerr,Verr]= get_nn_thredds_data_nc([dnum,dnum],[AA.HFR_MAPS(mapval).limits(1,1) AA.HFR_MAPS(mapval).limits(1,2)],[AA.HFR_MAPS(mapval).limits(1,3) AA.HFR_MAPS(mapval).limits(1,4)]);
        %[TIME,LON,LAT,U,V,Uerr,Verr]= get_ndbc_thredds_data_nc([dnum,dnum],[AA.HFR_MAPS(mapval).limits(1,1) AA.HFR_MAPS(mapval).limits(1,2)],[AA.HFR_MAPS(mapval).limits(1,3) AA.HFR_MAPS(mapval).limits(1,4)]);
        
        notnan = find(~isnan(U+V));c
        LON = LON(notnan);  LAT = LAT(notnan); U = U(notnan); V= V(notnan); Uerr = Uerr(notnan); Verr = Verr(notnan);
        %NRAD = NRAD(notnan);
        if strcmp(get(ttool,'State'),'on')
            clear ZZ ZZZ
            if ~isempty(U)
                
                latlist = unique(LON);
                latset = latlist(1:2:length(latlist));
                ZZ = ismember(LON,latset);
                lonlist = unique(LAT);
                lonset = lonlist(1:2:length(lonlist));
                ZZZ = ismember(LAT,lonset);
                U = U.*ZZ.*ZZZ;
                V = V.*ZZ.*ZZZ;
                Uerr = Uerr.*ZZ.*ZZZ;
                Verr = Verr.*ZZ.*ZZZ;
                LAT = LAT.*ZZ.*ZZZ;
                LON = LON.*ZZ.*ZZZ;
                
            end
        end
        
        %gv = find(Uerr <= oi_cutoff | Verr <= oi_cutoff);
        gv = 1:length(LON);
        
        if strcmp(get(qtool,'State'),'on')
            sct = scq;
            plothandles(pcount) = m_quiver(LON(gv), LAT(gv), U(gv).*sct,V(gv).*sct,0);
            set(plothandles(pcount),'Color','k')
            pcount = pcount + 1;
            plotscalearrow(sct,arrow_spd);
        else  %USE MVEC ARROWS
            sct = sc;
            % make all vectors the same size
            clear tspd tdir Usc Vsc
            LON = LON(gv); LAT = LAT(gv);
            U = U(gv); V = V(gv);
            [spd,direc] = uv2spdir(U,V);
            [~,isort] = sort(spd);
            scs = zeros(length(spd),1) + sct;
            [Usc, Vsc] =  spddir2uv(scs, direc(isort));
            
            
            edges = 1:1:maxcolor;   %cm/s
            cmap = colormap(jet(length(edges)+1));
            
            edges = [-inf edges inf];                     % speeds under/over a min/max value will be drawn with same color as the min/max value
            [~,BIN] = histc(spd(isort),edges);
            for ii = 1:length(BIN)
                try
                    cvals(ii,:) = cmap(BIN(ii),:);
                catch
                    cvals(ii,:) = [1 1 1];  % if no vectors in that category, just assign white
                end
            end
            
            aa = 1:length(BIN);
            plothandles(pcount) = m_vec(1,LON(isort(aa)), LAT(isort(aa)), Usc(aa),Vsc(aa),cvals(aa,:),'headlength',4);
            pcount = pcount+1;
            
            if pcount >2
                title(titlelab)
                %title('Multiple Files ','Color','k','FontSize',12);
                if exist('fnt','var')
                    delete(fnt);
                end;
                
            else
                titlelab{pcount} = ['Rutgers OI Data ',datestr(dnum),'   '];
                %titlelab{pcount} = ['Latest National Network Data ',datestr(TIME),'   '];
                %titlelab{pcount} = ['Latest NDBC Data ',datestr(TIME),'   '];
                title([titlelab{pcount},' '],'Color','k','FontSize',12,'interpreter','none');
                fnt = text(-0.1,-0.1,titlelab{pcount},'Color','k','FontSize',8,'Units','normalized','interpreter','none');
            end
            
            hold on
            plotcolorbar(cmap,edges);
            
        end
        
    end

% function cutoffbutton_Callback(~,~)
%     %Adjusts display settings.
%      oi_cutoff = inputdlg('Enter OI error cutoff value.','OI Cutoff',1,{num2str(oi_cutoff)},'on');
%      oi_cutoff = str2double(char(oi_cutoff));
%      display_settings;
% end

    function gdopbutton_Callback(~,~)
        %Adjusts display settings.
        gdopval = inputdlg('Enter GDOP cutoff value.','GDOP Cutoff',1,{num2str(gdopval)},'on');
        gdopval = str2double(char(gdopval));
        display_settings;
    end

    function oibutton_Callback(~,~)
        %Adjusts display settings.
        oival = inputdlg('Enter OI threshold cutoff value.','OI Threshold Cutoff',1,{num2str(oival)},'on');
        oival = str2double(char(oival));
        display_settings;
    end

    function rangeringbutton_Callback(~,~)
        % Plots range ring on the map.
        rgnum = inputdlg('Enter range value (km).','Plot Range Ring',1,{num2str(AA.HFR_MAPS(mapval).spacing)},'on');
        rgnum = str2double(char(rgnum));
        [lonnum, latnum] = ginput(1);
        [slon,slat]=m_xy2ll(lonnum,latnum);
        m_range_ring(slon,slat,rgnum);
    end

    function savescalebutton_Callback(~,~)
        
        ngrids = size(AA.HFR_MAPS,2);
        AA.HFR_MAPS(mapval).scalefactor = scq;
        HFR_MAPS = AA.HFR_MAPS(1:ngrids-1);
        HFR_STNS = AA.HFR_STNS;
        HFR_PATHS = AA.HFR_PATHS;
        
        eval(['save ', setupfile, ' HFR_PATHS HFR_MAPS HFR_STNS']);
        
    end

    function loadnewsetup_Callback(~,~)
        [setupfilename,setupfilepath] = uigetfile('*.*','Choose a data file',[AA.HFR_PATHS.gui_dir,'GridFiles/baylist1.txt']);
        setupfile = [setupfilepath,setupfilename];
        if exist(setupfile,'file') ~= 2
            msgbox(sprintf('Error:  Could not find %s set up file.\n\nRun hfr_setup_gui.m to create this file.',setupfile))
        end
        
        AA = load(setupfile);             % load all the set up file information
        
        STN_INFO = AA.HFR_STNS;                % all station information from set up file
        radialpath = AA.HFR_PATHS.radial_dir;  % default path for radial files (assumes site folders (XXXX) under this path)
        totalpath = AA.HFR_PATHS.total_dir;    % default path for total files
        rpcode = AA.HFR_PATHS.radial_pcode;    % default path code for radial files
        tpcode = AA.HFR_PATHS.total_pcode;     % default path code for total files
        pathspace = 0;                         % does path name contain a space?
        sname = char(STN_INFO(1).name);        % station 4 letter name, default is first in the list
        
        
        %SET THE INITIAL GRID
        cgnum = size(AA.HFR_MAPS,2) + 1;
        AA.HFR_MAPS(cgnum).name = {'Custom_Zoom'};  % set up a space for user to create custom temporary grid
        mapval = 1;                          % start with first grid in the information file
        sgrid = char(AA.HFR_MAPS(mapval).name);   % start with first grid name in the information file
        scq = AA.HFR_MAPS(mapval).scalefactor;
        sc = 0.1;     % m_vec arrows
        [cxmin, cxmax, cymin, cymax] = deal([],[],[],[]);
        
        ngrid = size(AA.HFR_MAPS,2);
        delete(gridhandles);
        for gg = 1:ngrid
            gridhandles(gg) = uimenu(gdh,'Label',char(AA.HFR_MAPS(gg).name),'Tag','Map','Callback',{@map_Callback});
        end
        
        nsite = length(STN_INFO);
        delete(sitehandles);
        for ss = 1:nsite
            sitehandles(ss) = uimenu(siteh,'Label',char(STN_INFO(ss).name),'Tag','Site','Callback',{@station_Callback});
        end
        
    end

    function custommap_Callback(~,~)
        % Ask how to proceed, either use map or enter manually.
        gc = inputdlg('Enter 1 to define limits by clicking on current map or 2 to type in values. ');
        gc = str2num(cell2mat(gc));
        %clear the old map for custom zoom
        if exist(['',AA.HFR_PATHS.gui_dir,'GridFiles/map_Custom_Zoom.mat'],'file')==2
            try  % because this won't work with PC
                eval(['!rm ','''',AA.HFR_PATHS.gui_dir,'GridFiles/map_Custom_Zoom.mat'''])
            catch
                eval(['!rm ',AA.HFR_PATHS.gui_dir,'GridFiles/map_Custom_Zoom.mat']) 
            end
        end
        
        if gc == 1
            disp('Click on bottom left corner then upper right corner.')
            temp=ginput(2);
            [cxmin, cymin] = m_xy2ll(temp(1,1),temp(1,2));
            [cxmax, cymax] = m_xy2ll(temp(2,1),temp(2,2));
            %AA.HFR_MAPS(cgnum).spacing = 0;% input('Enter grid spacing (km): ');
            AA.HFR_MAPS(cgnum).name = 'Custom_Zoom';
            AA.HFR_MAPS(cgnum).version = 'Custom_Zoom';
            %AA.HFR_MAPS(cgnum).lonlat = [cxmin, cymin; cxmax, cymax];
            AA.HFR_MAPS(cgnum).limits = [cxmin, cxmax, cymin, cymax];
            AA.HFR_MAPS(cgnum).scalefactor = 0.003;
            clearbutton_Callback;
        else
            cxmin=input('Enter minimum longitude. ');
            cxmax=input('Enter maximum longitude. ');
            cymin=input('Enter minimum latitude. ');
            cymax=input('Enter maximum latitude. ');
            AA.HFR_MAPS(cgnum).spacing = 0;%input('Enter grid spacing (km): ');
            AA.HFR_MAPS(cgnum).name = 'Custom_Zoom';
            AA.HFR_MAPS(cgnum).description = 'Custom_Zoom';
            AA.HFR_MAPS(cgnum).limits = [cxmin, cxmax, cymin, cymax];
            AA.HFR_MAPS(cgnum).scalefactor = 0.003;
            clearbutton_Callback;
        end
    end

    function compareradbutton_Callback(~,~)
        
        if strcmp(get(listtool,'State'),'on');radar % CALL PLOT MULTIPLE TIMES, USE USER'S FILELIST WITH CURRENTLY SELECTED DATE
            
            %FIRST FILE
            %use the list for names of files to compare
            myfilename = char(filelist{1});
            pat = '\d\d\d\d_\d\d_\d\d_\d\d\d\d';
            dst = regexp(myfilename, pat, 'start');
            myfilename(dst:dst+14) = dtmp;
            if ~isempty(strfind(myfilename,' '))
                pathspace = 1;
            else
                pathspace = 0;
            end
            
            % LOAD DATA FROM MAT FILE OR .RUV
            if strcmp(myfilename(end-3:end),'.mat')
                disp(['Loading...',myfilename])
                R1 = load(myfilename); R1 = R1.RADIAL;
            else
                R1 = loadRDLFile(myfilename,1);
            end
            
            %SECOND FILE
            clear myfilename
            myfilename = char(filelist{2});
            pat = '\d\d\d\d_\d\d_\d\d_\d\d\d\d';
            dst = regexp(myfilename, pat, 'start');
            myfilename(dst:dst+14) = dtmp;
            if ~isempty(strfind(myfilename,' '))
                pathspace = 1;
            else
                pathspace = 0;
            end
            
            % LOAD DATA FROM MAT FILE OR .RUV
            if strcmp(myfilename(end-3:end),'.mat')
                disp(['Loading...',myfilename])
                R2 = load(myfilename); R2 = R2.RADIAL;
            else
                R2 = loadRDLFile(myfilename,1);
            end
            
            radial_differences(R1,R2,mapval,AA);
            
            
            
            
        else
            
            cdir = pwd;
            try
              eval(['cd ''',AA.HFR_PATHS.gui_dir,'RadialEdits/',sname,'''']);
            catch
              eval(['cd ',AA.HFR_PATHS.gui_dir,'RadialEdits/',sname])
            end
            [R1file,R1filepath] = uigetfile('*.*','Choose a data file');
            R1filename = [R1filepath,R1file];
            
            
            if strcmp(R1filename(end-3:end),'.mat')
                disp(['Loading...',R1filename])
                if strcmp(get(tottool,'State'),'off')
                    R1 = load(R1filename); R1 = R1.RADIAL;
                else
                    R1 = load(R1filename); R1 = R1.TUV;
                    R1.FileName = R1filename;
                end
            else
                R1 = loadRDLFile(R1filename,1);
            end
            try
              eval(['cd ''',cdir,''''])
            catch
              eval(['cd ',cdir])
            end
            
            try
              eval(['cd ''',AA.HFR_PATHS.gui_dir,'RadialEdits/',sname,'''']);
            catch
              eval(['cd ',AA.HFR_PATHS.gui_dir,'RadialEdits/',sname]);
            end
            [R2file,R2filepath] = uigetfile('*.*','Choose a second data file');
            R2filename = [R2filepath,R2file];
            
            
            if strcmp(R2filename(end-3:end),'.mat')
                disp(['Loading...',R2filename])
                if strcmp(get(tottool,'State'),'off')
                    R2 = load(R2filename); R2 = R2.RADIAL;
                else
                    R2 = load(R2filename); R2 = R2.TUV;
                    R2.FileName = R2filename;
                end
            else
                R2 = loadRDLFile(R2filename,1);
            end
            try
              eval(['cd ''',cdir,''''])
            catch
              eval(['cd ',cdir])
            end
            
        end
        
        radial_differences(R1,R2,mapval,AA);
        
    end

    function output_txt = mydatatip(obj,event_obj)
        % Display the position of the data cursor
        % obj          Currently not used (empty)
        % event_obj    Handle to event object
        % output_txt   Data cursor text string (string or cell array of strings).
        
        pos = get(event_obj,'Position');
        output_txt = {['X: ',num2str(pos(1),4)],...
            ['Y: ',num2str(pos(2),4)]};
        
        % If there is a Z-coordinate in the position, display it as well
        if length(pos) > 2
            output_txt{end+1} = ['Z: ',num2str(pos(3),4)];
        end
    end


end