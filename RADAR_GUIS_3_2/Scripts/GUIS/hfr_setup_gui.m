function hfr_setup_gui(setupfile)
% T Garner May 28 2010 
% T Updyke expanded program and put into GUI form Nov 5 2011
%
% DESCRIPTION  Saves a MAT file containing path, station and grid information for
% use with RADAR_GUIS display and processing scripts. Run this script to
% get started with GUI programs and rerun to update configuration as
% needed.
%
% INPUTS 
%   Grid files need to be created before they can be loaded into the hfr_setup_gui. 
%   The grid file must be a MAT or text file containing the positions of the grid points. 
%
%      In the MAT file case, the file must contain a variable named "LONLAT" 
%      in which the first column is longitude and the second column latitude.  
%
%      In the text file case, the file must contain only numeric values and have two columns, 
%      the first being longitude and the second latitude.  
%
% OUTPUTS
%
%  The outputs listed below are required for the gui programs. Add
%  other information/fields to these structures or create your own variables for
%  your custom programs.
%
%  Note: The output is saved as a Matlab version 7.3 MAT file.
% 
%  HFR_INFO.mat containing the structure variables:
%
%    1) HFR_PATHS
%         gui_dir        path for the RADAR_GUIS directory
%         radial_dir     path to radial files
%                        (Note: RDL's must be directly below station folders named with 4
%                        letter station codes in this main directory)
%         radial_pcode   Defines radial data folder structure (press
%                        the "Radial Path Code" button for more information)
%         total_dir      path to totals data for your routine hourly processing
%         total_pcode    Defines data folder structure for totals (press
%                        the "Total Path Code" button for more information)
%
%    2) HFR_STNS         structure with station information  
%         name           4 letter site code
%         lat            (optional) station latitude
%         lon            (optional) station longitude
%         
%    3) HFR_GRIDS        structure with grid information   
%         name           short names for grids (8 characters or less)
%         description    descriptive name for grid
%         lonlat         2 column matrix with locations of grid points for total processing
%         spacing        the nominal spacing of a grid given in kilometers
%         limits         limits for map display [lonmin lonmax latmin latmax]
%         

% --------------------- INITIAL VARIABLE ASSIGNMENTS ------------------------ %
% load existing set up file or initialize variables if no file exists

format long

if ~exist('setupfile','var')
    setupfile = 'HFR_INFO.mat';
end

if (exist(setupfile,'file') == 2)
    load(setupfile);
    if ~isempty(HFR_GRIDS)
        ngrids = size(HFR_GRIDS,2);
    else 
        ngrids = 0;
    end
    if ~isempty(HFR_STNS)
        nsites = size(HFR_STNS,1);
    else
        nsites = 0;
    end    

else
    HFR_PATHS = struct();
    HFR_PATHS.gui_dir = '/Users/codar/RADAR_GUIS/';
    HFR_PATHS.radial_dir = '/Users/codar/Data/Radials/';
    HFR_PATHS.total_dir = '/Users/codar/Data/Totals/';
    HFR_PATHS.radial_pcode = '[XXXX]/';
    HFR_PATHS.total_pcode = '';
    HFR_STNS = struct('name','','lon',0,'lat',0);
    HFR_GRIDS = struct('name','','description','','spacing',0,'lonlat',[0 0],'limits',[0 0 0 0],'scalefactor',0);
    ngrids = 0;
    nsites = 0;    
end

sv = '';
siteinfo = cell(3,1);
gridinfo = cell(3,1);
gridfilepath='';
gridfile = '';
newgrid = [];
gridlimits = cell(4,1);
ilimits = [];
LONLAT = [];
ow = 0;
[xmin, xmax, ymin, ymax, padx, pady] = deal([]);
options = struct('Resize','on','WindowStyle','normal','Interpreter','tex');
createsitefolder = 0;
creategridfolder = 0;
createmap = 1;
sitesel = 1;
gridsel = 1;
keep = [];

% ----------------------- CREATE THE GUI FIGURE ------------------------ %


mgf = figure('Visible','off','Position',[727 409 785 452],'MenuBar', 'none');


hgpath = uicontrol('Style','pushbutton','String','RADAR_GUIS Path',...
           'Position',[45 402 150 30],'Callback',{@gpathbutton_Callback});
hgpath_edit = uicontrol('Style','edit','String',HFR_PATHS.gui_dir,...
           'Position',[210 402 535 30],'Callback',{@gpathedit_Callback});

hrpath = uicontrol('Style','pushbutton','String','Radial Path',...
           'Position',[45 367 150 30],'Callback',{@rpathbutton_Callback});
hrpath_edit = uicontrol('Style','edit','String',HFR_PATHS.radial_dir,...
           'Position',[210 367 535 30],'Callback',{@rpathedit_Callback});

hrpathcode_text = uicontrol('Style','pushbutton','String','Radial Path Code',...
           'Position',[45 337 150 25],'Callback',{@rpathcode_Callback});
       
hrpathcode_edit = uicontrol('Style','edit','String',HFR_PATHS.radial_pcode,...
           'Position',[210 333 535 30],'Callback',{@rpathcodeedit_Callback});
       
       
htpath = uicontrol('Style','pushbutton','String','Total Path',...
           'Position',[45 300 150 30],'Callback',{@tpathbutton_Callback});
htpath_edit = uicontrol('Style','edit','String',HFR_PATHS.total_dir,...
           'Position',[210 300 535 30],'Callback',{@tpathedit_Callback});       
       
htpathcode_text = uicontrol('Style','pushbutton','String','Total Path Code',...
           'Position',[45 270 150 25],'Callback',{@tpathcode_Callback});
       
htpathcode_edit = uicontrol('Style','edit','String',HFR_PATHS.total_pcode,...
           'Position',[210 266 535 30],'Callback',{@tpathcodeedit_Callback});
       
       
hsite_text = uicontrol('Style','text','String','Radar Sites',...
           'Position',[45 225 165 22]);       
hgrid_text = uicontrol('Style','text','String','Grids',...
           'Position',[247 225 165 22]);   
hdelsite = uicontrol('Style','pushbutton','String','X','ToolTip','Delete Selected Site',...
           'Position',[193 225 22 22],'Callback',{@delsitebutton_Callback});
hdelgrid = uicontrol('Style','pushbutton','String','X','ToolTip','Delete Selected Grid',...
           'Position',[393 225 22 22],'Callback',{@delgridbutton_Callback});
hupsite = uicontrol('Style','pushbutton','String','^','ToolTip','Move Selected Site Up In The List',...
           'Position',[45 225 22 22],'Callback',{@upsitebutton_Callback});
hupgrid = uicontrol('Style','pushbutton','String','^','ToolTip','Move Selected Grid Up In The List',...
           'Position',[247 225 22 22],'Callback',{@upgridbutton_Callback});
       
hsite_box = uicontrol('Style','listbox','String',[HFR_STNS.name],...
           'Position',[45 75 170 140],'Callback',{@sitebox_Callback});  
hgrid_box = uicontrol('Style','listbox','String',[HFR_GRIDS.name],...
           'Position',[245 75 170 140],'Callback',{@gridbox_Callback}); 
       
haddsite = uicontrol('Style','pushbutton','String','Add Site',...
           'Position',[45 35 80 30],'Callback',{@addsitebutton_Callback});
haddgrid = uicontrol('Style','pushbutton','String','Add Grid',...
           'Position',[245 35 80 30],'Callback',{@addgridbutton_Callback});

heditsite = uicontrol('Style','pushbutton','String','Edit Site',...
           'Position',[135 35 80 30],'Callback',{@editsitebutton_Callback});
heditgrid = uicontrol('Style','pushbutton','String','Edit Grid',...
           'Position',[335 35 80 30],'Callback',{@editgridbutton_Callback});
       
       
hsitefolder_check = uicontrol('Style', 'checkbox', 'String', 'Create Site Folders',...
           'Position',[485 225 190 23], 'Callback', {@sitefolder_checkbox_Callback}); 
hgridfolder_check = uicontrol('Style', 'checkbox', 'String', 'Create Grid Folders',...
           'Position',[485 200 190 23], 'Callback', {@gridfolder_checkbox_Callback});     
hmap_check = uicontrol('Style', 'checkbox', 'String', 'Create Maps','Value',1,...
           'Position',[485 175 190 23], 'Callback', {@map_checkbox_Callback}); 

hinstall = uicontrol('Style','pushbutton','String','Install Setup File',...
           'Position',[465 60 250 75],'Callback',{@installbutton_Callback});
       
   set([mgf, hgpath, hgpath_edit, hrpath, hrpath_edit, hrpathcode_text, hrpathcode_edit, ...
     htpath, htpath_edit, htpathcode_text, htpathcode_edit, ...      
     hsite_text, hgrid_text, hsite_box, hgrid_box, haddsite, haddgrid, heditsite, heditgrid,...
     hupsite, hdelsite, hupgrid, hdelgrid, hsitefolder_check, hgridfolder_check, hmap_check, hinstall ], ...
     'Units','normalized');
   
   set(mgf, 'Color',[0.4 0.6 0.9])  % blue
   set([hsite_text, hgrid_text, hsite_box, hgrid_box],'BackgroundColor',[1,1,1]); %white
   set([hgpath_edit, hrpath_edit, hrpathcode_edit, htpath_edit, htpathcode_edit],'BackgroundColor',[0.8 0.8 0.8]); %light grey
   set([hinstall],'BackgroundColor',[0 0.5 0]);
   
   % Assign the GUI a name to appear in the window title.
   set(mgf,'Name','HFR Setup GUI')
   % Move the GUI to the center of the screen.
   movegui(mgf,'center')
   % Make the GUI visible.
   set(mgf,'Visible','on'); 
       
% ------------------------------ CALLBACK FUNCTIONS  --------------------------- %

%RADIAL PATH
 function gpathbutton_Callback(source,eventdata)
    HFR_PATHS.gui_dir = uigetdir(HFR_PATHS.gui_dir,'Choose default radial data folder.');
    HFR_PATHS.gui_dir = [HFR_PATHS.gui_dir,'/'];
    hgpath_edit = uicontrol('Style','edit','String',HFR_PATHS.gui_dir,...
           'Position',[210 402 535 30],'Callback',{@gpathedit_Callback});
    set(hgpath_edit,'Units','normalized','BackgroundColor',[0.8 0.8 0.8])
  end

 function gpathedit_Callback(hObject, eventdata)
           HFR_PATHS.gui_dir = get(hObject,'String');
 end


%RADIAL PATH
  function rpathbutton_Callback(source,eventdata)
    HFR_PATHS.radial_dir = uigetdir(HFR_PATHS.radial_dir,'Choose default radial data folder.');
    HFR_PATHS.radial_dir = [HFR_PATHS.radial_dir,'/'];
    hrpath_edit = uicontrol('Style','edit','String',HFR_PATHS.radial_dir,...
           'Position',[210 367 535 30],'Callback',{@rpathedit_Callback});
    set(hrpath_edit,'Units','normalized','BackgroundColor',[0.8 0.8 0.8])
  end

 function rpathedit_Callback(hObject, eventdata)
           HFR_PATHS.radial_dir = get(hObject,'String');
 end



%TOTAL PATH
  function tpathbutton_Callback(source,eventdata)
    HFR_PATHS.total_dir = uigetdir(HFR_PATHS.total_dir,'Choose default radial data folder.');
    HFR_PATHS.total_dir = [HFR_PATHS.total_dir,'/'];
    htpath_edit = uicontrol('Style','edit','String',HFR_PATHS.total_dir,...
           'Position',[210 300 535 30],'Callback',{@tpathedit_Callback});  
    set(htpath_edit,'Units','normalized','BackgroundColor',[0.8 0.8 0.8])
  end

 function tpathedit_Callback(hObject, eventdata)
           HFR_PATHS.total_dir = get(hObject,'String');
 end

%PATH CODE EXPLANATION
 function rpathcode_Callback(source,eventdata)
   msgbox(sprintf('Enter codes in the adjacent box to define paths to radials. Use MATLAB datestr codes surrounded by brackets [] and use [XXXX] in place of the site code.\n\nNOTES\nPath codes only work if your data is organized in a consistent way for all sites under a single base path.  Also if you use the name of the site in your organization scheme, you must use the four letter site name (case sensitive). \n\nLet''s say you keep all your data in /Users/codar/path/Radials/.  Under this base folder you have a folder for each site and then under each site folder, there is a folder for every year and month. It looks like this:\n\n\n /Users/codar/path/Radials/\n\n           CBBT/\n                   2012_Jan\n                   2012_Feb\n           VIEW/\n                   2012_Jan\n                   2012_Feb\n\n\n  For this example the path code would be [XXXX]/[yyyy]_[mmm]/ \n\n'));
 end

function rpathcodeedit_Callback(hObject, eventdata)
           HFR_PATHS.radial_pcode = get(hObject,'String');
end

 function tpathcode_Callback(source,eventdata)
   msgbox(sprintf('Enter codes in the adjacent box to define paths to totals. Use MATLAB datestr codes surrounded by brackets [].\n\nNOTES\nPath codes only work if your data is organized in a consistent way under a single base path.\n\nLet''s say you keep all your data in /Users/codar/path/Totals/GRID1/.  Under this base folder, there is a folder for every year and month. It looks like this:\n\n\n /Users/codar/path/Totals/GRID1/\n\n                   2012_01/\n                   2012_02/\n                   2012_03/\n                   2012_04/\n\n\n  For this example the path code would be [yyyy]_[mm]/ \n\n'));
 end

function tpathcodeedit_Callback(hObject, eventdata)
           HFR_PATHS.total_pcode = get(hObject,'String');
end


function sitebox_Callback(hObject,eventdata)
   sitesel = get(hObject,'value');
end

function gridbox_Callback(hObject,eventdata)
   gridsel = get(hObject,'value');
end

function delsitebutton_Callback(source,eventdata)
    if sitesel~=0
      HFR_STNS = HFR_STNS([1:sitesel-1 sitesel+1:end]);  
      hsite_box = uicontrol('Style','listbox','String',[HFR_STNS.name],...
           'Position',[45 75 170 140],'Callback',{@sitebox_Callback});  
      set(hsite_box,'BackgroundColor',[1 1 1],'Units','normalized');
      nsites = nsites-1;
      sitesel=0;
    end
end

function delgridbutton_Callback(source,eventdata)
    if gridsel~=0
      HFR_GRIDS = HFR_GRIDS([1:gridsel-1 gridsel+1:end]);
      hgrid_box = uicontrol('Style','listbox','String',[HFR_GRIDS.name],...
           'Position',[245 75 170 140],'Callback',{@gridbox_Callback});
      set(hgrid_box,'BackgroundColor',[1 1 1],'Units','normalized');
      ngrids = ngrids-1;  
      gridsel = 0;
    end
end

function upsitebutton_Callback(source,eventdata)
    % moves selected file to top of the list    
    if sitesel > 1
      HFR_STNS(nsites+1) = HFR_STNS(sitesel-1);  % move a copy of first site to end of structure
      HFR_STNS(sitesel-1) = HFR_STNS(sitesel);   % move selected to first spot
      HFR_STNS(sitesel) = HFR_STNS(nsites+1);  % move first site copy to space originally occupied by selected file so swap is complete
      HFR_STNS = HFR_STNS(1:nsites);  % remove copy at end
      hsite_box = uicontrol('Style','listbox','String',[HFR_STNS.name],...
           'Position',[45 75 170 140],'Callback',{@sitebox_Callback});
      sitesel = 0; % so the selection must be reset, avoids confusion and unintended deletes
      set(hsite_box,'BackgroundColor',[1 1 1],'Units','normalized'); 
    end
end



function upgridbutton_Callback(source,eventdata)
    % moves selected file to top of the list
    if gridsel >1
      HFR_GRIDS(ngrids+1) = HFR_GRIDS(gridsel-1);  % move a copy of first grid to end of structure
      HFR_GRIDS(gridsel-1) = HFR_GRIDS(gridsel);   % move selected to grid spot
      HFR_GRIDS(gridsel) = HFR_GRIDS(ngrids+1);  % move first grid copy to space originally occupied by selected file so swap is complete
      HFR_GRIDS = HFR_GRIDS(1:ngrids);  % remove copy at end    
      hgrid_box = uicontrol('Style','listbox','String',[HFR_GRIDS.name],...
           'Position',[245 75 170 140],'Callback',{@gridbox_Callback});
      gridsel = 0; % so the selection is reset, avoids confusion and unintended deletes
      set(hgrid_box,'BackgroundColor',[1 1 1],'Units','normalized');    
    end
end


function addsitebutton_Callback(source,eventdata)
    if sitesel ~=0
      siteinfo = inputdlg({sprintf('Only required information is 4 letter code! \n\nFour letter code.'),'Latitude (decimal form, negative for degrees south)','Longitude (decimal form, negative for degrees west)'},'Enter Site Information',[2 30]);    
      if size(siteinfo{1},2) == 4 
        HFR_STNS(nsites+1,:).name = {siteinfo{1}}; 
        HFR_STNS(nsites+1).lat = str2double(siteinfo{2});
        HFR_STNS(nsites+1).lon = str2double(siteinfo{3});
        hsite_box = uicontrol('Style','listbox','String',[HFR_STNS.name],...
           'Position',[45 75 170 140],'Callback',{@sitebox_Callback});  
        set(hsite_box,'BackgroundColor',[1 1 1],'Units','normalized');
        nsites = nsites+1;
      else
        msgbox('Site name must be four letter code.')
      end
    else
        msgbox('Selection didn''t register. Please click on site again to select.')
    end
end

function editsitebutton_Callback(source, eventdata)
    if sitesel ~=0
      siteinfo = inputdlg({sprintf('Only required information is 4 letter code! \n\nFour letter code.'),'Latitude (decimal form, negative for degrees south)','Longitude (decimal form, negative for degrees west)'},'Enter Site Information',[2 30],{char(HFR_STNS(sitesel,:).name),sprintf('%10.5f',(HFR_STNS(sitesel,:).lat)),sprintf('%10.5f',(HFR_STNS(sitesel,:).lon))});
      if ~isempty(siteinfo)
        if size(siteinfo{1},2) == 4 
          HFR_STNS(sitesel,:).name = {siteinfo{1}};  
        else
          msgbox('Site name must be four letter code.')
        end
        if ~isnan(str2double(siteinfo{2}))
          HFR_STNS(sitesel).lat = str2double(siteinfo{2});
        else
          %msgbox('Latitude must be a number.')
        end   
        if ~isnan(str2double(siteinfo{3}))
          HFR_STNS(sitesel).lon = str2double(siteinfo{3});
        else
          %msgbox('Latitude must be a number.')
        end          
        hsite_box = uicontrol('Style','listbox','String',[HFR_STNS.name],...
           'Position',[45 75 170 140],'Callback',{@sitebox_Callback});  
        set(hsite_box,'BackgroundColor',[1 1 1],'Units','normalized');
      end
    else
      msgbox('Selection didn''t register. Please click on site again to select.')
    end
end

function editgridbutton_Callback(source, eventdata)
  if exist('gridsel','var') && gridsel ~=0
    
    gridinfo = inputdlg({'Enter nickname for grid (no spaces, 8 characters or less).','Enter grid description.','Nominal Grid Spacing','Scale Factor'},'Edit Grid',[1 60; 4 60; 1 60; 1 60],{sprintf('%s',char(HFR_GRIDS(gridsel).name)),sprintf('%s',char(HFR_GRIDS(gridsel).description)), sprintf('%6.2f',HFR_GRIDS(gridsel).spacing), sprintf('%10.6f',HFR_GRIDS(gridsel).scalefactor) });    
    if ~isempty(gridinfo)
      HFR_GRIDS(gridsel).name = {gridinfo{1}};
      HFR_GRIDS(gridsel).description = {gridinfo{2}};
      HFR_GRIDS(gridsel).spacing = str2double({gridinfo{3}});
      HFR_GRIDS(gridsel).scalefactor = str2double({gridinfo{4}});
    end
    
    gridlimits = inputdlg({sprintf('Define new limits (FOR MAP DISPLAY ONLY) or skip this option and click "ok" or "cancel" to continue.\n\nMinimum Longitude'),'Maximum Longitude','Minimum Latitude', 'Maximum Latitude'},'Grid Limits',[2 80],{sprintf('%10.5f',HFR_GRIDS(gridsel).limits(1,1)),sprintf('%10.5f',HFR_GRIDS(gridsel).limits(1,2)),sprintf('%10.5f', HFR_GRIDS(gridsel).limits(1,3)),sprintf('%10.5f',HFR_GRIDS(gridsel).limits(1,4))  });
    
    if ~isempty(gridlimits)
      HFR_GRIDS(gridsel).limits = [str2double(gridlimits{1})  str2double(gridlimits{2})  str2double(gridlimits{3})  str2double(gridlimits{4})];  % used for drawing the map slightly larger than grid
    end
    
    hgrid_box = uicontrol('Style','listbox','String',[HFR_GRIDS.name],...
           'Position',[245 75 170 140],'Callback',{@gridbox_Callback});
    set(hgrid_box,'BackgroundColor',[1 1 1],'Units','normalized');
    
  
  else
    msgbox('Selection didn''t register. Please click on site again to select.')
  end
end

function addgridbutton_Callback(source,eventdata)
    
    gridinfo = inputdlg({'Enter nickname for grid (no spaces, 8 characters or less).','Enter grid description.'},'Title',[1 60; 4 60]);    
    uiwait(msgbox('In the following step, you must import a MAT or text file containing the positions of the grid points. In the MAT file case, your file must contain a variable named "LONLAT" in which the first column is longitude and the second column latitude.  In the text file case, the file must contain only numeric values and have two columns, the first being longitude and the second latitude.', 'Import Grid Information','modal'));
    
    [gridfile, gridfilepath] = uigetfile('*','Import Grid File',[HFR_PATHS.gui_dir,'/GridFiles/OriginalDataFiles/MidAtlantic_6km.txt']);
    
    if strcmp(gridfile(end-3:end), '.mat') == 0;
      eval(['newgrid = load(''',gridfilepath, gridfile,''');']);
      LONLAT = [newgrid(:,1) newgrid(:,2)];
    else 
      eval(['newgrid = load(''',gridfilepath, gridfile,''');']);
      LONLAT = newgrid.LONLAT;
    end
    
    % Option to use a subset of the grid.
      gridlimits = inputdlg({sprintf('Define a smaller coverage area by reseting limits below or skip this option and click "ok" or "cancel" to continue.\n\nMinimum Longitude'),'Maximum Longitude','Minimum Latitude', 'Maximum Latitude'},'Grid Limits',[2 80],{sprintf('%10.5f',min(LONLAT(:,1))),sprintf('%10.5f',max(LONLAT(:,1))),sprintf('%10.5f', min(LONLAT(:,2))),sprintf('%10.5f',max(LONLAT(:,2)))  });
    
      if isempty(gridlimits)
          HFR_GRIDS(ngrids+1).lonlat = LONLAT;
      else
        try
         ilimits = find(LONLAT(:,1)>= str2double(gridlimits{1}) & LONLAT(:,1) <= str2double(gridlimits{2}) & LONLAT(:,2) >= str2double(gridlimits{3}) & LONLAT(:,2) <= str2double(gridlimits{4}));
         if ~isempty(ilimits)
             HFR_GRIDS(ngrids+1).lonlat = [LONLAT(ilimits,1) LONLAT(ilimits,2)];
         else
             HFR_GRIDS(ngrids+1).lonlat = LONLAT;
         end
        catch
         disp('New grid limits failed. Using full grid.')
         HFR_GRIDS(ngrids+1).lonlat = LONLAT;
        end
      end
    
    HFR_GRIDS(ngrids+1).name = {gridinfo{1}};
    HFR_GRIDS(ngrids+1).description = {gridinfo{2}};
    SL = unique(LONLAT(:,2));
    if length(SL) > 1
      HFR_GRIDS(ngrids+1).spacing = round(latlondist(SL(2),LONLAT(1,1),SL(1),LONLAT(2,1)));
    else
      HFR_GRIDS(ngrids+1).spacing = 1;
    end
    
    % limits for the map 
    xmin = min(HFR_GRIDS(ngrids+1).lonlat(:,1)); xmax = max(HFR_GRIDS(ngrids+1).lonlat(:,1));
    ymin = min(HFR_GRIDS(ngrids+1).lonlat(:,2)); ymax = max(HFR_GRIDS(ngrids+1).lonlat(:,2));
    % pad so map display is slightly larger than the grid
    pady = (ymax - ymin).*0.02;     padx = (xmax - xmin).*0.02;
    if padx == 0 %so display doesn't fail when trying to create map for a grid with single point at a buoy
       padx = 10; %degrees lon
    end
    if pady == 0
       pady = 10; %degrees lat 
    end
    HFR_GRIDS(ngrids+1).limits = [xmin-padx xmax+padx ymin-pady ymax+pady];  % used for drawing the map slightly larger than grid
    
    if HFR_GRIDS(ngrids+1).spacing > 5
      HFR_GRIDS(ngrids+1).scalefactor = 0.003;
    else
      HFR_GRIDS(ngrids+1).scalefactor = 0.0003; 
    end
    
    hgrid_box = uicontrol('Style','listbox','String',[HFR_GRIDS.name],...
           'Position',[245 75 170 140],'Callback',{@gridbox_Callback});
    set(hgrid_box,'BackgroundColor',[1 1 1],'Units','normalized');
    ngrids = ngrids+1;
end

function sitefolder_checkbox_Callback(hObject, eventdata, handles)
    if (get(hObject,'Value') == get(hObject,'Max'))
     createsitefolder = 1; %box checked
     msgbox('Creates new folders for your stations in the RadialEdits folder.  If your computer is DOS based (Windows PC) and can''t handle the mkdir command then uncheck this box, go to the RadialEdits folder and create a folder for each station using the four letter station names.');
    else
     createsitefolder = 0; %box not checked
    end
end

function gridfolder_checkbox_Callback(hObject, eventdata, handles)
    if (get(hObject,'Value') == get(hObject,'Max'))
     creategridfolder = 1; %box checked
     msgbox('Creates new folders for your grids in the TestTotals folder.  If your computer is DOS based (Windows PC) and can''t handle the mkdir command then uncheck this box, go to the RadialEdits folder and create a folder for each grid using the short grid name.');
    else
     creategridfolder = 0; %box not checked
    end
end

function map_checkbox_Callback(hObject, eventdata, handles)
    if (get(hObject,'Value') == get(hObject,'Max'))
     createmap = 1; %box checked
    else
     createmap = 0; %box not checked
     msgbox('Creates coast files for plotting with m_map and the HFR Progs toolbox. These files are saved in the GridFiles folder. If you have changed any grid information during the setup process, leave this box checked.');
    end
end

function installbutton_Callback(source,eventdata)
    
    % add final / to pathnames if forgotten
    if strcmp(HFR_PATHS.gui_dir(end), '/') == 0
        HFR_PATHS.gui_dir = [HFR_PATHS.gui_dir, '/'];
    end
    if strcmp(HFR_PATHS.radial_dir(end), '/') == 0
        HFR_PATHS.radial_dir = [HFR_PATHS.radial_dir, '/'];
    end
    if strcmp(HFR_PATHS.total_dir(end), '/') == 0
        HFR_PATHS.total_dir = [HFR_PATHS.total_dir, '/'];
    end
    if ~isempty(HFR_PATHS.radial_pcode)
        if strcmp(HFR_PATHS.radial_pcode(end), '/') == 0
          HFR_PATHS.radial_pcode = [HFR_PATHS.radial_pcode, '/'];
        end
    else 
        HFR_PATHS.radial_pcode = '';
    end
    if ~isempty(HFR_PATHS.total_pcode)
        if strcmp(HFR_PATHS.total_pcode(end), '/') == 0
          HFR_PATHS.total_pcode = [HFR_PATHS.total_pcode, '/'];
        end
    else 
        HFR_PATHS.radial_pcode = '';
    end
    
    
    % remove any empty slots in HFR_STNS and HFR_GRIDS
    keep = [];
    for xx = 1:size(HFR_STNS,1);
        if ~isempty(HFR_STNS(xx).name)
        keep = [keep; xx];
        end
    end
    if ~isempty(keep)
        HFR_STNS = HFR_STNS(keep);
    end
    
    
    keep = [];
    for xx = 1:size(HFR_GRIDS,2);
        if ~isempty(HFR_GRIDS(xx).name)
        keep = [keep; xx];
        end
    end
    if ~isempty(keep)
        HFR_GRIDS = HFR_GRIDS(keep);
    end
    
    
    if (createsitefolder)
    
    for xx = 1:length(HFR_STNS);
       ow=0;
       if exist([HFR_PATHS.gui_dir,'RadialEdits/',char(HFR_STNS(xx).name)],'dir')
          ow = input([char(HFR_STNS(xx).name),' Directory already exists.  Press 1 to overwrite.']);
       else
          eval(['!mkdir ''', HFR_PATHS.gui_dir,'RadialEdits/',char(HFR_STNS(xx).name),'''']) 
       end
       if ow == 1
         eval(['!rm -Ri ''', HFR_PATHS.gui_dir,'RadialEdits/',char(HFR_STNS(xx).name),''''])
         eval(['!mkdir ''', HFR_PATHS.gui_dir,'RadialEdits/',char(HFR_STNS(xx).name),'''']) 
       end
    end
    end
    
    
    if (creategridfolder)

    for xx = 1:size(HFR_GRIDS,2);
       ow=0;
       if exist([HFR_PATHS.gui_dir,'TestTotals/',char(HFR_GRIDS(xx).name(:))],'dir')
        ow = input([char(HFR_GRIDS(xx).name(:)),' Directory already exists.  Press 1 to overwrite.']);
       else
        eval(['!mkdir ''', HFR_PATHS.gui_dir,'TestTotals/',char(HFR_GRIDS(xx).name),'''']) 
       end
       if ow == 1
        eval(['!rm -Ri ''', HFR_PATHS.gui_dir,'TestTotals/',char(HFR_GRIDS(xx).name),'''']) 
        eval(['!mkdir ''', HFR_PATHS.gui_dir,'TestTotals/',char(HFR_GRIDS(xx).name),'''']) 
       end
    end
    
    end
    
    
    
    if createmap
    
    % make a copy of the previous GridFiles folder
    try 
       eval(['!cp -Ri ',HFR_PATHS.gui_dir,'GridFiles ',HFR_PATHS.gui_dir, 'GridFiles_saved',datestr(now,'yyyymmddHHMM')]);
    end

    msgbox('Please click ok to continue and then wait for the next dialog box to appear. This may take a couple of minutes because maps are being generated for each grid.')

    for xx = 1:size(HFR_GRIDS,2);
      disp(sprintf('Constructing map for grid %s ...', char(HFR_GRIDS(xx).name)))
      xmin = min(HFR_GRIDS(xx).lonlat(:,1)); xmax = max(HFR_GRIDS(xx).lonlat(:,1));
      ymin = min(HFR_GRIDS(xx).lonlat(:,2)); ymax = max(HFR_GRIDS(xx).lonlat(:,2));
      % pad so map is slightly larger than the grid
      pady = (ymax - ymin).*0.02;
      padx = (xmax - xmin).*0.02;
      makeCoast([xmin-padx xmax+padx],[ymin-pady ymax+pady],'lambert',['''',HFR_PATHS.gui_dir,'GridFiles/map_',char(HFR_GRIDS(xx).name),'.mat'''],4);
      
    end
    end
    

    sv = inputdlg(['Writing to ',HFR_PATHS.gui_dir, 'GridFiles/HFR_INFO.mat. OK? (y/n) ']);
    if ~isempty(sv) && (strcmp(sv,'y') || strcmp(sv,'Y'))
        % make a copy of the previous setup file
        try 
            eval(['!cp ',HFR_PATHS.gui_dir,'GridFiles/HFR_INFO.mat ',HFR_PATHS.gui_dir, 'GridFiles/HFR_INFO.saved',datestr(now,'yyyymmddHHMM'),'.mat']);
        end
        % save the new setup  file
      eval(['save -v7.3 ''',HFR_PATHS.gui_dir, 'GridFiles/HFR_INFO'' HFR_GRIDS HFR_STNS HFR_PATHS']);
      disp('Setup file HFR_INFO.mat was successfully saved to RADAR_GUIS/GridFiles/ folder.');
      disp('Rerun hfr_setup_gui.m to update information as needed.')
      close
    else
        setupfilename = char(inputdlg('Use this name (do not include path, e.g. HFR_INFO_bay.mat): ','s'));
        
        sv = inputdlg(sprintf('Writing to %sGridFiles/%s. OK? (y/n) ',HFR_PATHS.gui_dir,setupfilename),'s');
        if ~isempty(sv) && (strcmp(sv,'y') || strcmp(sv,'Y'))
          % save the new setup  file
          eval(['save -v7.3 ''',HFR_PATHS.gui_dir, 'GridFiles/',setupfilename,''' HFR_GRIDS HFR_STNS HFR_PATHS']);
          disp(sprintf('Setup file %s was successfully saved to RADAR_GUIS/GridFiles/ folder.',setupfilename));
          disp('Rerun hfr_setup_gui.m to update information as needed.')
          %close
        end
    end
    
    
end

    


end % function
