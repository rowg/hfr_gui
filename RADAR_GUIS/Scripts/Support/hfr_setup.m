function hfr_gui_setup()
% T Garner May 28 2010 
%
% Before running any of the gui programs in this package, 
% edit this file as described in the instructions throughout the code.
% and run the program. This will save a MAT file to provide information for
% the gui's.  This set up only needs to be done once.
% 
%
% DESCRIPTION  Saves a MAT file containing path, station and grid information for
% use with display and processing scripts.
%
% INPUTS 
%    grid data files supplied by user and placed in the GridFiles folder 
%       (i.e. hfrnet_EGCequidistCyl_2kmGrid.mat, MidAtlantic_6km.txt)  
%    See the code below for steps on how to enter your information to make
%    a custom MAT file for use with the RADAR GUI scripts.
%
% OUTPUTS
%
%  The outputs listed below are required for the gui programs but feel free to add
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
%         total_dir      path to totals data for your routine hourly processing
%
%    2) HFR_STNS         structure with station information  
%         name           4 letter site code
%         lat            (optional) station latitude
%         lon            (optional) station longitude
%         code           (optional) if you want to assign a number to this site
%         ip             (optional) for example, you could use this info to set up an automated
%                        data pull for a specific radial in radar_display_gui from a site that you 
%                        don't normally pull hourly data from 
%         
%    3) HFR_GRIDS        grid information, all fields listed below are cell arrays    
%         gridversion    descriptive name for grids with creation date
%         gridname       short names for grids
%         lonlat         2 column matrix with locations of grid points for total processing
%         spacing        the nominal spacing of a grid given in kilometers
%                     
%
%------------------------ BEGIN INPUTS --------------------------------%

%  1) Change path for the RADAR_GUIS folder. Path must end with the / symbol.

HFR_PATHS = struct();

HFR_PATHS.gui_dir = '/Users/garner/RADAR_GUIS/';


% 2)  All radials must be located in a single folder containing station subfolders that
%     are named with the four letter station code.  Enter the path to that single folder. 
%     Path must end with the / symbol.
%     The programs assume that all radials are found directly underneath the
%     station folder.

HFR_PATHS.radial_dir = '/Users/garner/Documents/MATLAB/Data/Radials/';

%     This directory will be the default path when you look to plot totals from your routine hourly processing.
%     Path must end with the / symbol.

HFR_PATHS.total_dir = '/Users/garner/Documents/MATLAB/Data/Totals/';

% 3)  Enter your station information in the following structure.  The only
%     field that is used by the programs is HFR_STNS.name although you
%     could fill in the other information if you would like to have it
%     available for your own use or other programs.  

HFR_STNS(1).name = {'VIEW'};
HFR_STNS(1).lat = 36.949926;
HFR_STNS(1).lon = -76.243181;
HFR_STNS(1).code = 1;
HFR_STNS(1).ip = '0.0.0.0';

HFR_STNS(2).name={'CPHN'};
HFR_STNS(2).lat=36+55.851/60;
HFR_STNS(2).lon=-76-1.005/60;
HFR_STNS(2).code = 2;
HFR_STNS(2).ip = '0.0.0.0';

HFR_STNS(3).name={'SUNS'}; 
HFR_STNS(3).lat= 37+(08.271/60);
HFR_STNS(3).lon= -(75+(58.334/60));
HFR_STNS(3).code = 3;

HFR_STNS(4).name = {'CBBT'};
HFR_STNS(4).lat = 37+(2.773/60);
HFR_STNS(4).lon = -(76+(3.764/60));
HFR_STNS(4).code = 0;
HFR_STNS(4).ip = '0.0.0.0';

HFR_STNS(5).name={'ASSA'};
HFR_STNS(5).lat=38+12.301/60;
HFR_STNS(5).lon=-(75+(9.174/60));
HFR_STNS(5).code = 4;
HFR_STNS(5).ip = '0.0.0.0';

HFR_STNS(6).name = {'CEDR'};
HFR_STNS(6).lat = 37+(40.369/60);
HFR_STNS(6).lon = -(75+(35.634/60));
HFR_STNS(6).code = 5;
HFR_STNS(6).ip = '0.0.0.0';

HFR_STNS(7).name = {'LISL'};
HFR_STNS(7).lat = 36+(41.503/60);
HFR_STNS(7).lon = -(75+(55.358/60));
HFR_STNS(7).code = 6;
HFR_STNS(7).ip = '0.0.0.0';

HFR_STNS(8).name={'DUCK'};
HFR_STNS(8).lat= 36.1803;
HFR_STNS(8).lon=-75.7501;
HFR_STNS(8).code = 7;
HFR_STNS(8).ip = '0.0.0.0';

HFR_STNS(9).name={'HATY'}; 
HFR_STNS(9).lat= 35.2572;
HFR_STNS(9).lon=-75.5199;
HFR_STNS(9).code = 8;
HFR_STNS(9).ip = '0.0.0.0';

HFR_STNS(10).name={'BRIG'}; 
HFR_STNS(10).lat= 0;
HFR_STNS(10).lon= 0;
HFR_STNS(10).code = 9;

HFR_STNS(11).name={'LOVE'}; 
HFR_STNS(11).lat= 0;
HFR_STNS(11).lon= 0;
HFR_STNS(11).code = 10;

HFR_STNS(12).name={'HOOK'}; 
HFR_STNS(12).lat= 0;
HFR_STNS(12).lon= 0;
HFR_STNS(12).code = 11;


% This section creates new folders for your stations in the RadialEdits
% folder.  If you're computer is DOS based (Windows) and can't handle the mkdir command then comment 
% these lines out, go to the RadialEdits folder and create a folder for each station 
% using the four letter station names.

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

% 4) You can have as many grids for total processing as you like.  Enter
% the number of grids you want.  Enter a descriptive title for each, a short name and the nominal spacing in km.
% For the short names please do not include spaces because this will cause
% path problems.  

ngrids = 3; 

HFR_GRIDS.version = cell(ngrids,1);
HFR_GRIDS.version{1} = ['National Network 2km Chesapeake Bay Grid, created ',datestr(now)];
HFR_GRIDS.version{2} = ['Southern Subset of National Network 6km Mid-Atlantic Grid, created ',datestr(now)];
HFR_GRIDS.version{3} = ['National Network 6km Mid-Atlantic Grid, created ',datestr(now)];

HFR_GRIDS.name = cell(ngrids,1);

HFR_GRIDS.name{1} = 'CHES2km';
HFR_GRIDS.name{2} = 'ATLSOUTH';
HFR_GRIDS.name{3} = 'MATL6km';  %limit to 8 characters for readability in GUI programs

HFR_GRIDS.spacing = cell(ngrids,1); %nominal spacing  % kilometers
HFR_GRIDS.spacing{1} = 2; 
HFR_GRIDS.spacing{2} = 6; 
HFR_GRIDS.spacing{3} = 6; 

% This section creates new folders for your grid in the TestTotals
% folder.  If you're computer is DOS based and can't handle the mkdir command then comment 
% these lines out, go to the TestTotals folder and create a folder for each
% grid using the short names you entered above.

 for xx = 1:ngrids;
     ow=0;
     if exist([HFR_PATHS.gui_dir,'TestTotals/',char(HFR_GRIDS.name{xx})],'dir')
      ow = input([char(HFR_GRIDS.name{xx}),' Directory already exists.  Press 1 to overwrite.']);
     else
      eval(['!mkdir ''', HFR_PATHS.gui_dir,'TestTotals/',char(HFR_GRIDS.name{xx}),'''']) 
     end
     if ow == 1
      eval(['!rm -Ri ''', HFR_PATHS.gui_dir,'TestTotals/',char(HFR_GRIDS.name{xx}),'''']) 
      eval(['!mkdir ''', HFR_PATHS.gui_dir,'TestTotals/',char(HFR_GRIDS.name{xx}),'''']) 
     end
end

% 5) Place your latitude/longitude grid information in a data file in
%    RADAR_GUIS/GridFiles/OriginalDataFiles and then 
%    write your custom code here that will load the location info. Put [lon lat] in the
%    grid cell structure. See examples below.

HFR_GRIDS.lonlat = cell(ngrids,1);  

% Load the East Coast National Network 2 km grid, pull out the
% Chesapeake Bay and put in correct format
filenamestr = [HFR_PATHS.gui_dir,'GridFiles/OriginalDataFiles/hfrnet_EGCequidistCyl_2kmGrid.mat'];
eval(['load ''',filenamestr,'''']);
wx = Lons(512:540,1111:1152); %water only, includes NaN
wy = Lats(512:540,1111:1152); %water only, includes NaN
[meshX_large,meshY_large] = meshgrid(wx,wy); % huge mesh grid!
UX = unique(meshX_large(~isnan(meshX_large)));
UY = unique(meshY_large(~isnan(meshY_large)));
[x, y] = meshgrid(UX,UY);  %create smaller mesh, includes land points
X = reshape(x,size(x,1)*size(x,2),1); %single column form
Y = reshape(y,size(y,1)*size(y,2),1);
HFR_GRIDS.lonlat{1} = [X Y];
 

% Load the full Mid Atlantic grid.
filenamestr2 = [HFR_PATHS.gui_dir,'GridFiles/OriginalDataFiles/MidAtlantic_6km.txt'];
eval(['load ''',filenamestr2,'''']);
MAG = MidAtlantic_6km;

% Note: I am saving a southern subset of the full Mid-Atlantic grid for my
% second grid.
ILOC = find(MAG(:,1)>= -76 & MAG(:,1) <= -72 & MAG(:,2) >= 35 & MAG(:,2) <= 39.5);
HFR_GRIDS.lonlat{2} = [MAG(ILOC,1) MAG(ILOC,2)];  

% and the full grid as my third.
HFR_GRIDS.lonlat{3} = [MAG(:,1) MAG(:,2)];  


% This section creates coast files for plotting with m_map and the
% HFR_Progs toolbox. It places these files under the GridFiles folder.
for xx = 1:ngrids;
    xmin = min(HFR_GRIDS.lonlat{xx}(:,1)); xmax = max(HFR_GRIDS.lonlat{xx}(:,1));
    ymin = min(HFR_GRIDS.lonlat{xx}(:,2)); ymax = max(HFR_GRIDS.lonlat{xx}(:,2));
    % pad so map is slightly larger than the grid
    pady = (ymax - ymin).*0.02;
    padx = (xmax - xmin).*0.02;
    makeCoast([xmin-padx xmax+padx],[ymin-pady ymax+pady],'lambert',['''',HFR_PATHS.gui_dir,'GridFiles/map_',char(HFR_GRIDS.name{xx}),'.mat'''],4);
end


%------------------------------ END INPUTS ----------------------------------%

% SAVE THE OUTPUT FILE
sv = input(['Writing to ',HFR_PATHS.gui_dir, 'GridFiles/HFR_INFO.mat. OK? (y/n) '],'s');
if strcmp(sv,'y') || strcmp(sv,'Y')
 eval(['save -v7.3 ''',HFR_PATHS.gui_dir, 'GridFiles/HFR_INFO'' HFR_GRIDS HFR_STNS HFR_PATHS']);
end

