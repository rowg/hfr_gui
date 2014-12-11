function maketotal_gui(time)
% MAKETOTAL_GUI Compute total.


% Initialize Variables

%TIME
   if ~exist('time','var')
    time = floor(now) + (floor( (now - floor(now) ) * 24)/24);  
   end
   endtime = time;
   dtmp0 = 0;
   dtmp1 = datestr(time,'yyyy_mm_dd_HHMM'); 
   tintvl = 60;  % default time interval is 60 minutes, radial input with hourly timestamps

%GRID
   AA = load('HFR_INFO.mat');
   STN_INFO = AA.HFR_STNS;
   totgridval = 1;
   totgrid = char(AA.HFR_GRIDS(totgridval).name);
   grid = [AA.HFR_GRIDS(totgridval).lonlat(:,1),AA.HFR_GRIDS(totgridval).lonlat(:,2)];
   
%PROCESSING SETTINGS
   SETTINGS.filelist = '';
   SETTINGS.method = 'UWLS';

   if AA.HFR_GRIDS(totgridval).spacing == 2;
        SETTINGS.UWLS_radius = 2.5;
   elseif AA.HFR_GRIDS(totgridval).spacing == 6;
        SETTINGS.UWLS_radius = 10;
   else
        SETTINGS.UWLS_radius = 0;
   end 
 
   SETTINGS.UWLS_temp_threshold = 0.5; %time window in hours,i.e. how many hourly radial maps are included in total
   SETTINGS.UWLS_maxspeed=200; %cm/s
   SETTINGS.UWLS_MINRadials = 3;
   SETTINGS.UWLS_MINSites = 2;
   SETTINGS.OI_decorrx = 10;
   SETTINGS.OI_decorry = 10;
   SETTINGS.OI_svar = 420;
   SETTINGS.OI_errvar = 66;
   SETTINGS.OI_thresholdx = 0.6;
   SETTINGS.OI_thresholdy = 0.6;
   SETTINGS.current_threshold = 500;  % maximum current allowed for total vector
%INPUT AND OUTPUT INFORMATION
   filename = [];
   stn = char(STN_INFO(1).name);
   stnpre = 'RDLm';
   stnsuf = '.ruv';
   filesel = [];
   sitelist = cell(15,1);
   sitelistdisp = cell(15,1);
   foutpath = [AA.HFR_PATHS.gui_dir,'TestTotals/',totgrid,'/'];
   rpath = AA.HFR_PATHS.radial_dir;
   basepath = AA.HFR_PATHS.radial_dir;
   pstruct = AA.HFR_PATHS.radial_pcode;
   tpstruct = AA.HFR_PATHS.total_pcode;
   pathext = pstruct;
   tpathext = tpstruct;
   foutp = 'TOTm';
   fout = [foutp,'_yyyy_mm_dd_HHMM.mat']; 
   outpath = '';
   saverad = 0;
   
%MISCELLANEOUS
   ii = 1;
   novar = 0;
   

   
  
   
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CREATE GUI  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
 
 % Create and hide the GUI figure as it is being constructed.
   fw = 640; fh = 520; yref = 290;
   mgf = figure('Visible','off','Position',[360,500,fw,fh],'MenuBar', 'none');

   startdate_position = [455,140,140,25];
   listbox_position = [150,yref+0,470,160];
   rpathtext_position = [120, yref+195, 500, 20];
   opathtext_position = [120, 250, 500, 20];
   settings_position = [185,147,75,25];
   procmethod_position = [95,180,120,21];
   procbutton_position = [400,25,170,40];


%BORDER AND LINES
   A = axes;
   set(A,'Visible','off');
   set(A, 'Position', [0, 0, 1, 1]);
   set(A, 'Xlim', [0, 1], 'YLim', [0, 1]);
   hline = line([0, 1], [0.4, 0.4], 'Parent', A,'LineWidth',2);
   hline2 = line([0.5, .5], [0, 0.4], 'Parent', A,'LineWidth',2);
   hborder1 = line([0, 1], [0, 0], 'Parent', A,'LineWidth',2);
   hborder2 = line([0, 1], [1, 1], 'Parent', A,'LineWidth',2);
   hborder3 = line([0, 0], [0, 1], 'Parent', A,'LineWidth',2);
   hborder4 = line([1, 1], [0, 1], 'Parent', A,'LineWidth',2);
   
%PROCESSING METHOD
   hprocmethod = uibuttongroup('visible','on','Parent',mgf,'Units','pixels','Position',procmethod_position,'SelectionChangeFcn',@selectmethod);
   u0 = uicontrol('Style','Radio','String','UWLS',...
    'pos',[0 0 70 15],'parent',hprocmethod,'HandleVisibility','off');
   u1 = uicontrol('Style','Radio','String','OI',...
    'pos',[65 0 70 15],'parent',hprocmethod,'HandleVisibility','off');

   
%START/END TIMES
   hdate_label = uicontrol('Style','text','String','Start',...
           'Position',[startdate_position(1)-85,startdate_position(2)+3,60,20]);
   hdate_edit = uicontrol('Style','edit','String',datestr(time,'dd-mmm-yyyy HH:MM'),...
           'Position',startdate_position,'Callback',{@datebutton_Callback}); 
   henddate_label = uicontrol('Style','text','String','End',...
           'Position',startdate_position - [85 27 80 5]);%[enddate_position(1)-85,enddate_position(2)+3,60,20]);
   henddate_edit = uicontrol('Style','edit','String',datestr(endtime,'dd-mmm-yyyy HH:MM'),...
           'Position',startdate_position-[0 30 0 0],'Callback',{@enddatebutton_Callback});
   hti_label = uicontrol('Style','text','String','Time Interval (min)',...
           'Position',startdate_position - [85 57 0 5]);
   hti_edit = uicontrol('Style','edit','String',tintvl,...
           'Position',startdate_position-[-80 60 80 0],'Callback',{@ti_Callback});
       
   
%GRID
   hgrid_label = uicontrol('Style','text',...
           'String','Grid',...
           'Position',startdate_position - [85 -35 80 5]); 
   hgrid = uicontrol('Style','popupmenu',...
           'String',[AA.HFR_GRIDS.name],...
           'Position',startdate_position - [5 -30 10 0],'Callback',{@grid_Callback});
      
%PROCESS BUTTON
   hproctotal = uicontrol('Style','pushbutton','String','PROCESS TOTALS',...
           'Position',procbutton_position,'BackgroundColor',[0.9 0.2 0.2],'Callback',{@proctotalbutton_Callback});

       
%RADIAL PATH
   hradpath = uicontrol('Style','pushbutton','String','Radial Path',...
           'Position',[30,rpathtext_position(2),80,20],'Callback',{@radpathbutton_Callback});
   hrpath_text = uicontrol('Style','text','String',rpath,...
           'Position',rpathtext_position); 
   hstruct_label = uicontrol('Style','text','String','Path Code',...
           'Position',[30,rpathtext_position(2)-28,78,20],'TooltipString','Enter codes for path directory structure.  All datestr letter codes should be surrounded by square brackets [].  [XXXX] is 4 letter radar site code.');
   hstruct_edit = uicontrol('Style','edit','String',pstruct,...
           'Position',rpathtext_position-[ 0 29 0 -6],'TooltipString','Enter codes for path directory structure.  All datestr letter codes should be surrounded by square brackets [].  [XXXX] is 4 letter radar site code.','Callback',{@pathstruct_Callback}); 

     
%RADIAL FILE LIST      
   hsites = uicontrol('Style','listbox','String',[STN_INFO.name],'Min',1,'Max',3,...
           'Position',[30,yref+30,90,100],'Callback',{@sitebox_Callback});   
   hrprefix_edit = uicontrol('Style','edit','String',stnpre,...
           'Position',[30,yref+134,90,23], 'Callback',{@rprefixbutton_Callback});
   hsuffix = uicontrol('Style','popupmenu',...
           'String',{'.ruv','.mat'},...
           'Position',[25,yref+0,100,25],'Callback',{@hsuffix_menu_Callback});
   hfilelist = uicontrol('Style','listbox','String',sitelist,...
           'Position',listbox_position,'Callback',{@filelist_Callback});   
   hadd = uicontrol('Style','pushbutton','String','-->',...
           'Position',[125,yref+70,20,15],'Callback',{@addbutton_Callback});
   hclearlist = uicontrol('Style','pushbutton','String','X',...
           'Position',[listbox_position(1)+listbox_position(3)-20,listbox_position(2)+ listbox_position(4)-20,20,20],'Callback',{@clearlistbutton_Callback});

%OUTPUT PATH
   houtpath = uicontrol('Style','pushbutton','String','Output Path',...
           'Position',[30,opathtext_position(2),80,20],'Callback',{@outpathbutton_Callback});
   hopath_text = uicontrol('Style','text','String',foutpath,...
           'Position',opathtext_position); 
   houtprefix_label = uicontrol('Style','text','String','Prefix',...
           'Position',[30,opathtext_position(2)-30,80,23]);
   hoprefix_edit = uicontrol('Style','edit','String',foutp,...
           'Position',opathtext_position-[0 30 420 -5], 'Callback',{@oprefixbutton_Callback});
       
   htpcode_label = uicontrol('Style','text','String','Path Code',...
           'Position',opathtext_position-[-90 30 420 -2],'TooltipString','Enter codes for path directory structure for total vector data.  All datestr letter codes should be surrounded by square brackets [].');
   htpcode_edit = uicontrol('Style','edit','String',tpstruct,...
           'Position',opathtext_position-[ -180 30 290 -5],'TooltipString','Enter codes for path directory structure for total vector data.  All datestr letter codes should be surrounded by square brackets [].','Callback',{@tpathstruct_Callback}); 
    
   hsaverad = uicontrol('Style', 'checkbox', 'String', 'Save Radials',...
           'Position', opathtext_position-[-400 30 390 0], 'Callback', {@saveradcheckbox_Callback}); 
 
%DISPLAY UWLS SETTINGS (DEFAULT)          
   hLSradius = uicontrol('Style','edit','String',SETTINGS.UWLS_radius,...
           'Position',settings_position - [0 0 0 0], 'Callback',{@UWLSradius_Callback});    
   hLSmaxspeed = uicontrol('Style','edit','String',SETTINGS.UWLS_maxspeed,...
           'Position',settings_position - [0 30 0 0], 'Callback',{@UWLSmaxspeed_Callback});    
   hLSminrad = uicontrol('Style','edit','String',SETTINGS.UWLS_MINRadials,...
           'Position',settings_position - [0 60 0 0], 'Callback',{@UWLSminrad_Callback});    
   hLSminsites = uicontrol('Style','edit','String',SETTINGS.UWLS_MINSites,...
           'Position',settings_position - [0 90 0 0], 'Callback',{@UWLSminsites_Callback});    
   hLStempthreshold = uicontrol('Style','edit','String',SETTINGS.UWLS_temp_threshold,...
           'Position',settings_position - [0 120 0 0], 'Callback',{@UWLStempthreshold_Callback});
       
   bxh = 2; bxl = -45; bxx = 130; 
   hLSradius_label = uicontrol('Style','text','String','Radius (km)',...
           'Position',settings_position - [bxx 0 bxl bxh]);    
   hLSmaxspeed_label = uicontrol('Style','text','String','Max Velocity (cm/s)',...
           'Position',settings_position - [bxx 30 bxl bxh]);    
   hLSminrad_label = uicontrol('Style','text','String','MIN Radials*',...
           'Position',settings_position - [bxx 60 bxl bxh]);    
   hLSminsites_label = uicontrol('Style','text','String','MIN Sites*',...
           'Position',settings_position - [bxx 90 bxl bxh]);    
   hLStempthreshold_label = uicontrol('Style','text','String','Time Window (hr)*',...
           'Position',settings_position - [bxx 120 bxl bxh]);
   hoverlay_text = [];hOIdecorrx =[]; hOIdecorry=[]; hOIsvar=[]; hOIerrvar=[]; hOIthresholdx=[]; hOIthresholdy=[];
   hOIdecorrx_label = []; hOIsvar_label = []; hOIerrvar_label = []; hOIthresholdx_label = [];
   hnote_text = uicontrol('Style','text','String','*Also used in OI method.','Position', [5,2,310,20],'BackgroundColor',[0.4 0.6 0.9]);
   set([hLSradius_label,hLSmaxspeed_label,hLSminrad_label,hLSminsites_label,hLStempthreshold_label],'BackgroundColor',[1 1 1])
   
%DISPLAY PROCESSING SETTINGS DEPENDING ON USER SELECTION
   function selectmethod(source, eventdata);
   SETTINGS.method = get(get(source,'SelectedObject'),'String');    
    
   if strcmp(SETTINGS.method,'UWLS')
         
   hoverlay_text = uicontrol('Style','text','Position', [5,2,310,175],'BackgroundColor',[0.4 0.6 0.9]);
   hnote_text = uicontrol('Style','text','String','*Also used in OI method.','Position', [5,2,310,20],'BackgroundColor',[0.4 0.6 0.9]);

   hLSradius = uicontrol('Style','edit','String',SETTINGS.UWLS_radius,...
           'Position',settings_position - [0 0 0 0], 'Callback',{@UWLSradius_Callback});    
   hLSmaxspeed = uicontrol('Style','edit','String',SETTINGS.UWLS_maxspeed,...
           'Position',settings_position - [0 30 0 0], 'Callback',{@UWLSmaxspeed_Callback});    
   hLSminrad = uicontrol('Style','edit','String',SETTINGS.UWLS_MINRadials,...
           'Position',settings_position - [0 60 0 0], 'Callback',{@UWLSminrad_Callback});    
   hLSminsites = uicontrol('Style','edit','String',SETTINGS.UWLS_MINSites,...
           'Position',settings_position - [0 90 0 0], 'Callback',{@UWLSminsites_Callback});    
   hLStempthreshold = uicontrol('Style','edit','String',SETTINGS.UWLS_temp_threshold,...
           'Position',settings_position - [0 120 0 0], 'Callback',{@UWLStempthreshold_Callback});
       
   bxh = 2; bxl = -45; bxx = 130; 
   hLSradius_label = uicontrol('Style','text','String','Radius (km)',...
           'Position',settings_position - [bxx 0 bxl bxh]);    
   hLSmaxspeed_label = uicontrol('Style','text','String','Max Velocity (cm/s)',...
           'Position',settings_position - [bxx 30 bxl bxh]);    
   hLSminrad_label = uicontrol('Style','text','String','MIN Radials*',...
           'Position',settings_position - [bxx 60 bxl bxh]);    
   hLSminsites_label = uicontrol('Style','text','String','MIN Sites*',...
           'Position',settings_position - [bxx 90 bxl bxh]);    
   hLStempthreshold_label = uicontrol('Style','text','String','Time Window (hr)*',...
           'Position',settings_position - [bxx 120 bxl bxh]);

   set([hLSradius, hLSmaxspeed, hLSminrad, hLSminsites, hLStempthreshold],'BackgroundColor',[1 1 1],'ForegroundColor',[0 0 1]);  
   set([hLSradius_label,hLSmaxspeed_label,hLSminrad_label,hLSminsites_label,hLStempthreshold_label],'BackgroundColor',[1 1 1])

   else
       
   bxh = -2; bxl = -45; bxx = 130; vs = 10;     
         
   hoverlay_text = uicontrol('Style','text','Position', [5,2,310,175],'BackgroundColor',[0.4 0.6 0.9]);
   
   hOIdecorrx = uicontrol('Style','edit','String',SETTINGS.OI_decorrx,...
           'Position',settings_position - [40 0+vs 0 0], 'Callback',{@OIdecorrx_Callback});    
   hOIdecorry = uicontrol('Style','edit','String',SETTINGS.OI_decorry,...
           'Position',settings_position - [-50 0+vs 0 0], 'Callback',{@OIdecorry_Callback});    
   hOIsvar = uicontrol('Style','edit','String',SETTINGS.OI_svar,...
           'Position',settings_position - [40 30+vs 0 0], 'Callback',{@OIsvar_Callback});    
   hOIerrvar = uicontrol('Style','edit','String',SETTINGS.OI_errvar,...
           'Position',settings_position - [40 60+vs 0 0], 'Callback',{@OIerrvar_Callback});    
   hOIthresholdx = uicontrol('Style','edit','String',SETTINGS.OI_thresholdx,...
           'Position',settings_position - [40 90+vs 0 0], 'Callback',{@OIthresholdx_Callback});    
   hOIthresholdy = uicontrol('Style','edit','String',SETTINGS.OI_thresholdy,...
           'Position',settings_position - [-50 90+vs 0 0], 'Callback',{@OIthresholdy_Callback});    

    
   hOIdecorrx_label = uicontrol('Style','text','String','Decorrelation (km) X,Y',...
           'Position',settings_position - [40+bxx 0+vs bxl bxh]);    
   hOIsvar_label = uicontrol('Style','text','String','Signal Variance (cm2/s2)',...
           'Position',settings_position - [40+bxx 30+vs bxl bxh]);    
   hOIerrvar_label = uicontrol('Style','text','String','Error Variance (cm2/s2)',...
           'Position',settings_position - [40+bxx 60+vs bxl bxh]);    
   hOIthresholdx_label = uicontrol('Style','text','String','Norm. Uncertainty Threshold X,Y',...
           'Position',settings_position - [40+bxx 90+vs bxl bxh]);    
       
   set([hOIdecorrx, hOIdecorry, hOIsvar, hOIerrvar, hOIthresholdx, hOIthresholdy],'BackgroundColor',[1 1 1],'ForegroundColor',[0 0 1]);
   set([hOIdecorrx_label,hOIsvar_label,hOIerrvar_label,hOIthresholdx_label],'BackgroundColor',[1 1 1])    
       
   end
   
   end



   
   % Initialize the GUI.
   % Change units to normalized so components resize
   % automatically.
   set([mgf, hprocmethod, hdate_label, hdate_edit, henddate_label, henddate_edit, hti_label, hti_edit, ...
   hgrid_label, hgrid, hproctotal, hradpath, hrpath_text, hstruct_edit, hstruct_label, houtprefix_label,...
   hsites, hrprefix_edit, hsuffix, hfilelist, hadd, hclearlist, houtpath, hopath_text, ...
   hoprefix_edit, hsaverad, hoverlay_text, hnote_text, htpcode_label, htpcode_edit,...
   hLSradius, hLSmaxspeed, hLSminrad, hLSminsites, hLStempthreshold, ...
   hLSradius_label, hLSmaxspeed_label, hLSminrad_label, hLSminsites_label, hLStempthreshold_label, ...
   hOIdecorrx, hOIdecorry, hOIsvar, hOIerrvar, hOIthresholdx, hOIthresholdy, ...
   hOIdecorrx_label, hOIsvar_label, hOIerrvar_label, hOIthresholdx_label], ...
   'Units','normalized');
   
   set(mgf, 'Color',[0.4 0.6 0.9])  % blue
   set([hrpath_text, hopath_text,htpcode_edit],'BackgroundColor',[0.8 0.9 0.9]); % light green
   set([hdate_label,henddate_label,hti_label,hgrid_label,hsites, hfilelist, hstruct_label, houtprefix_label,htpcode_label,...
        hLSradius_label, hLSmaxspeed_label, hLSminrad_label, hLSminsites_label, hLStempthreshold_label, ...
        hOIdecorrx_label, hOIsvar_label, hOIerrvar_label, hOIthresholdx_label],'BackgroundColor',[1,1,1]); %white
   set([hdate_edit,henddate_edit,hti_edit,...
        hLSradius, hLSmaxspeed, hLSminrad, hLSminsites, hLStempthreshold, ...
        hOIdecorrx, hOIdecorry, hOIsvar, hOIerrvar, hOIthresholdx, hOIthresholdy],'BackgroundColor',[1,1,1],'ForegroundColor',[0 0 1]);
   set([hrprefix_edit, hoprefix_edit,hstruct_edit],'BackgroundColor',[0.8 0.9 0.9],'ForeGroundColor',[0 0 1]);
   % Assign the GUI a name to appear in the window title.
   set(mgf,'Name','makeTotals GUI')
   % Move the GUI to the center of the screen.
   movegui(mgf,'center')
   % Make the GUI visible.
   set(mgf,'Visible','on'); 
   
   %keyboard
   %[UWLS_radius;UWLS_maxspeed;UWLS_MINRadials; UWLS_MINSites; UWLS_temp_threshold]
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALLBACK FUNCTIONS  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%RADIAL PATH
  function radpathbutton_Callback(source,eventdata)
    [newrpath] = uigetdir(rpath,'Choose a data file');
    rpath = [newrpath,'/'];
    hrpathtext = uicontrol('Style','text','String',rpath,...
           'Position',rpathtext_position); 
    set(hrpathtext,'BackgroundColor',[0.8 0.9 0.9]);
  end

%RADIAL PATH STRUCTURE
   function pathstruct_Callback(hObject, eventdata)
           pstruct = get(hObject,'String');
           pathext = pstruct;
   end


%RADIAL PREFIX 
   function rprefixbutton_Callback(hObject, eventdata)
           stnpre = get(hObject,'String');
   end

%RADIAL SUFFIX
   function hsuffix_menu_Callback(source,eventdata) 
      % Determine the selected data set.
      str = get(source, 'String');
      val = get(source,'Value');
      % Set current data to the selected data set.
      stnsuf = str{val};
   end

%SITE SELECTION(S)
  function sitebox_Callback(hObject,eventdata)
   site_selections = get(hObject,{'string','value'});
   stn = char(site_selections{1}(site_selections{2})); 
  end

%ADD FILE TO LIST
  function addbutton_Callback(source,eventdata)  
     basepath = repmat([rpath,pathext],size(stn,1),1);
     for jj = 1:size(stn,1);
         try
         basepath(jj,:) = strrep(basepath(jj,:), 'XXXX', stn(jj,:));
         end
     end
     myfilename = datenum_to_directory_filename(basepath,time,[repmat([stnpre,'_'],size(stn,1),1),stn,repmat(['_'],size(stn,1),1)],stnsuf,0);
     for xx = 1:size(myfilename,2)
       sitelist{ii,1} = myfilename{xx};
       %only display file name not the path
       [novar,filename , novar] = fileparts(char(myfilename{xx}));
       %sitelistdisp{ii,1} = filename;
       ii = ii+1;
     end
       hfilelist = uicontrol('Style','listbox','String',sitelist,...
           'Position',listbox_position,'Callback',{@filelist_Callback});  
       hclearlist = uicontrol('Style','pushbutton','String','X',...
           'Position',[listbox_position(1)+listbox_position(3)-20,listbox_position(2)+ listbox_position(4)-20,20,20],'Callback',{@clearlistbutton_Callback});

       set(hfilelist,'BackgroundColor',[1 1 1])
  end    

%RADIAL FILE LIST
  function filelist_Callback(hObject,eventdata)
    filesel = get(hObject,'value');
  end

%CLEAR INPUT FILE LIST
  function clearlistbutton_Callback(source,eventdata) 
  % Clears the radial list.  
     %clear sitelist sitelistdisp;
     %sitelist = cell(15,1);
     %sitelistdisp = cell(15,1);
     if ~isempty(filesel);
     sitelist(filesel) = '';
     sitelistdisp(filesel) = '';
     
     ii = 1;
     hfilelist = uicontrol('Style','listbox','String',sitelist,...
           'Position',listbox_position, 'Callback',{@filelist_Callback});       
     hclearlist = uicontrol('Style','pushbutton','String','X',...
           'Position',[listbox_position(1)+listbox_position(3)-20,listbox_position(2)+ listbox_position(4)-20,20,20],'Callback',{@clearlistbutton_Callback});
     set(hfilelist,'BackgroundColor',[1 1 1])
     end
     filesel = [];
  end


%OUTPUT PATH AND PREFIX
  function outpathbutton_Callback(source,eventdata)
    [newopath] = uigetdir(foutpath,'Choose a data file');
    foutpath = [newopath,'/'];
    hopathtext = uicontrol('Style','text','String',foutpath,...
           'Position',opathtext_position); 
    set(hopathtext,'BackgroundColor',[0.8 0.9 0.9]);
  end
  function oprefixbutton_Callback(hObject, eventdata)
           foutp = get(hObject,'String');
           fout = [foutp,'_yyyy_mm_dd_HHMM.mat'];
  end

%TOTAL PATH STRUCTURE
   function tpathstruct_Callback(hObject, eventdata)
           tpstruct = get(hObject,'String');
           tpathext = tpstruct;
   end


  function saveradcheckbox_Callback(hObject, eventdata, handles)
    if (get(hObject,'Value') == get(hObject,'Max'))
     saverad = 1; %box checked
    else
     saverad = 0; %box not checked
    end
  end


%----------------------- SETTINGS FOR PROCESSING METHOD ----------------------%

%UWLS PROCESS SETTINGS
  function UWLSradius_Callback(hObject, eventdata)
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',SETTINGS.UWLS_radius);
             uicontrol(hObject)
           return
           end
           SETTINGS.UWLS_radius = dtmp0;       
  end
  function UWLSmaxspeed_Callback(hObject, eventdata)
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',SETTINGS.UWLS_maxspeed);
             uicontrol(hObject)
           return
           end
           SETTINGS.UWLS_maxspeed = dtmp0;
  end
  function UWLSminrad_Callback(hObject, eventdata)
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',SETTINGS.UWLS_MINRadials);
             uicontrol(hObject)
           return
           end    
           SETTINGS.UWLS_MINRadials = dtmp0;
  end
  function UWLSminsites_Callback(hObject, eventdata)
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',SETTINGS.UWLS_MINSites);
             uicontrol(hObject)
           return
           end    
           SETTINGS.UWLS_MINSites = dtmp0;
  end
  function UWLStempthreshold_Callback(hObject, eventdata)
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',SETTINGS.UWLS_temp_threshold);
             uicontrol(hObject)
           return
           end    
           SETTINGS.UWLS_temp_threshold = dtmp0;
  end

%OI PROCESS SETTINGS
  function OIdecorrx_Callback(hObject, eventdata)
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',SETTINGS.OI_decorrx);
             uicontrol(hObject)
           return
           end    
           SETTINGS.OI_decorrx = dtmp0;         
  end
  function OIdecorry_Callback(hObject, eventdata)
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',SETTINGS.OI_decorry);
             uicontrol(hObject)
           return
           end    
           SETTINGS.OI_decorry = dtmp0;         
  end
  function OIsvar_Callback(hObject, eventdata)
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',SETTINGS.OI_svar);
             uicontrol(hObject)
           return
           end    
           SETTINGS.OI_svar = dtmp0;         
  end
  function OIerrvar_Callback(hObject, eventdata)
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',SETTINGS.OI_errvar);
             uicontrol(hObject)
           return
           end    
           SETTINGS.OI_errvar = dtmp0;         
  end
  function OIthresholdx_Callback(hObject, eventdata)
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',SETTINGS.OI_thresholdx);
             uicontrol(hObject)
           return
           end    
           SETTINGS.OI_thresholdx = dtmp0;         
  end
  function OIthresholdy_Callback(hObject, eventdata)
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',SETTINGS.OI_thresholdy);
             uicontrol(hObject)
           return
           end    
           SETTINGS.OI_thresholdy = dtmp0;
  end

%----------------------- BASIC PROCESSING SETTINGS ----------------------%

%GRID
  function grid_Callback(source, eventdata)
   totgridstr = get(source, 'String');
   totgridval = get(source,'Value');
   totgrid = totgridstr{totgridval}; 
   grid = [AA.HFR_GRIDS(totgridval).lonlat(:,1),AA.HFR_GRIDS(totgridval).lonlat(:,2)];
   
   msgbox('Grid changed.  Set appropriate UWLS radius and file output path for this grid.');
     % Changing the grid will change the output file path
       %foutpath = [AA.HFR_PATHS.gui_dir,'TestTotals/',totgrid,'/']; 
       %hopathtext = uicontrol('Style','text','String',foutpath,...
       %    'Position',opathtext_position); 
       %set(hopathtext,'Units','normalized','BackgroundColor',[0.8 0.9 0.9])
       
     % Changing the grid will change the UWLS radius according to grid spacing
       %if AA.HFR_GRIDS(totgridval).spacing == 2;
       % SETTINGS.UWLS_radius = 2.5;
       %elseif AA.HFR_GRIDS(totgridval).spacing == 6;
       % SETTINGS.UWLS_radius = 10;
       %else
       %SETTINGS.UWLS_radius = inputdlg('Enter Search Radius (km) : ','');
       % SETTINGS.UWLS_radius = str2double(char(SETTINGS.UWLS_radius));
       %end    
       %hLSradius = uicontrol('Style','edit','String',SETTINGS.UWLS_radius,...
       %    'Position',settings_position - [0 0 0 0], 'Callback',{@UWLSradius_Callback}); 
       %set(hLSradius,'Units','normalized','BackgroundColor',[1 1 1],'ForegroundColor',[0 0 1]);
  end

%START TIME
  function datebutton_Callback(hObject,eventdata) 
   % Allows user to enter the start time.
     orig_time = datestr(time,'yyyy_mm_dd_HHMM');
     dtmp0 = get(hObject,'String');  %from edit box, in the easy to read format
     try
       %convert to format seen in the filename
       dtmp1 = datestr(dtmp0,'yyyy_mm_dd_HHMM');
       time = datenum(dtmp0);
     catch
       errordlg('Invalid date.','Bad Input','modal')
       set(hObject,'String',datestr(orig_time,'dd-mmm-yyyy HH:MM'));
       uicontrol(hObject)
       return
     end

     try 
       sitelist = strrep(sitelist,orig_time,dtmp1)
       %sitelistdisp = strrep(sitelistdisp,orig_time,dtmp1);
     catch
     end
     try % why did I put this here??
       sitelist = sitelist(1:ii-1);
       sitelistdisp = sitelistdisp(1:ii-1);
       sitelist = strrep(sitelist,orig_time,dtmp1)
       %sitelistdisp = strrep(sitelistdisp,orig_time,dtmp1);
     catch
     end
   hfilelist = uicontrol('Style','listbox','String',sitelist,...
           'Position',listbox_position,'Callback',{@filelist_Callback}); 
   hclearlist = uicontrol('Style','pushbutton','String','X',...
           'Position',[listbox_position(1)+listbox_position(3)-20,listbox_position(2)+ listbox_position(4)-20,20,20],'Callback',{@clearlistbutton_Callback});

   set(hfilelist,'BackgroundColor',[1 1 1])


  end

%END TIME
  function enddatebutton_Callback(hObject,eventdata) 
    % Allows user to enter the end time.
    dtmp0 = get(hObject,'String');  %from edit box, in the easy to read format
    try
      endtime = datenum(dtmp0);
    catch
      errordlg('Invalid date.','Bad Input','modal')
             set(hObject,'String',datestr(endtime,'dd-mmm-yyyy HH:MM'));
             uicontrol(hObject)
    end
  end

%TIME INTERVAL
  function ti_Callback(hObject,eventdata) 
    % Allows user to enter the time interval.
           dtmp0 = str2double(get(hObject,'String'));
           if isnan(dtmp0)
             errordlg('You must enter a numeric value.','Bad Input','modal')
             set(hObject,'String',tintvl);
             uicontrol(hObject)
           return
           end    
           tintvl = dtmp0;         
  end


%%%%%%%%%%%%%%  FINALLY CALL THE FUNCTIONS THAT PROCESS RADIALS TO TOTALS !!!  %%%%%%%%%%%%% 


  function proctotalbutton_Callback(source,eventdata) 
  % Calculates total vectors.   

  times = (datenum(time):(tintvl/60)/24:datenum(endtime)); 
  times = times + 1/24/60/60; % add one second to times
  %sitelist
  
  for tt = 1:length(times);

     % insert new times into filenames
     newtimestr = datestr(times(tt),'yyyy_mm_dd_HHMM');
     try
       finallist = strrep(sitelist,dtmp1,newtimestr);
     catch % again why is this section here??
       sitelist = sitelist(1:ii-1);
       finallist = strrep(sitelist,dtmp1,newtimestr);
     end

     
     lRADS = 0;  % set loaded radial count back to 0
    
     fout = strrep(fout,'yyyy_mm_dd_HHMM',newtimestr);
     outpath = pcode_translation([foutpath,tpathext], times(tt));
     
     for j2=1:size(sitelist,1)  % loop over list of radial files
 
       fn = finallist{j2};  
       fn = pcode_translation(fn, times(tt));
       d=dir(fn);
       if ~isempty(d)
         if strcmp(fn(end-3:end),'.mat')
            disp(['Loading...',fn])
            eval(['load -mat ' ,fn]);
         else
            RADIAL = loadRDLFile(fn);
         end 
         RADS(lRADS+1) = RADIAL; %increment cell structure skipping nonexistent files
         % extract and save radial # info, originally I also recorded site nums
         % here to show which sites contributed which number of radials,
         % could do this again if I assigned specific site numbers to the
         % stations.
         nrads(j2) = length(RADIAL.U);       
         clear RADIAL
         lRADS = lRADS+1; % increment found-station index  
       else
         nrads(j2) = 0;
       end
   
     end
 
     if lRADS>=SETTINGS.UWLS_MINSites   % enough radial sites to generate some totals data
    
       %try  
          fprintf('Computing totals\n'); 
           
          if strcmp(SETTINGS.method,'UWLS')  % UNWEIGHTED LEAST SQUARES METHOD
          
           
            [TUVraw,RTUV]=makeTotals(RADS,'Grid',grid,'TimeStamp',RADS(1).TimeStamp, ...
                   'spatthresh',SETTINGS.UWLS_radius,'tempthresh',SETTINGS.UWLS_temp_threshold./24, ...
                   'MinNumSites',SETTINGS.UWLS_MINSites,'MinNumRads',SETTINGS.UWLS_MINRadials);
            
               
          else    % OPTIMAL INTERPOLATION METHOD
            
            
            [TUVraw,RTUV] = makeTotalsOI(RADS,'Grid',grid,'TimeStamp',RADS(1).TimeStamp,'mdlvar',SETTINGS.OI_svar, 'errvar',SETTINGS.OI_errvar,...
                'sx', SETTINGS.OI_decorrx, 'sy', SETTINGS.OI_decorry, 'tempthresh',SETTINGS.UWLS_temp_threshold, 'normr', SETTINGS.OI_thresholdx,...
                'MinNumSites',SETTINGS.UWLS_MINSites,'MinNumRads',SETTINGS.UWLS_MINRadials);
            
          end
               
               
          
          TUVraw.ProcessingSteps(end+1) = AA.HFR_GRIDS(totgridval).description;
          
          % add names of stations if radial count > 0 and warnings if low count
          for j3 = 1:length(RTUV);
            if(length(RTUV(j3).U)) > 0;
              TUVraw.SiteCodes(j3,:) = RTUV(j3).SiteCode;
              TUVraw.SiteRadialCounts(j3) = length(RTUV(j3).U);
              % check that all radial timestamps match with total timestamp
              if abs(RTUV(j3).TimeStamp - TUVraw.TimeStamp) > 1/24/60
                  disp('time mismatch warning')
                  clear TUVraw
              end
              % check that time associated with file name matches data
              % timestamps
              if abs(times(tt) - RTUV(j3).TimeStamp) > 1/24/60 %difference is greater than 1 minute
                  disp('timestamp/filename mismatch warning')
                  clear TUVraw
              end
            end
          end
          
          SETTINGS.filelist = sitelist;
          TUVraw.Settings = SETTINGS;
          if strcmp(SETTINGS.method,'UWLS')
              TUVraw.Settings.OI_decorrx = NaN;
              TUVraw.Settings.OI_decorry = NaN;
              TUVraw.Settings.OI_svar = NaN;
              TUVraw.Settings.OI_errvar = NaN;
              TUVraw.Settings.OI_thresholdx = NaN;
              TUVraw.Settings.OI_thresholdy = NaN;
          end
          
          [TUV,TI] = cleanTotals(TUVraw,SETTINGS.current_threshold);
          fprintf('%d totals > %3d cm/s removed\n',sum(TI(:)>0),SETTINGS.current_threshold)
          
            
         if saverad
           eval(['save -v7.3 ''',outpath,fout,''' TUV RADS RTUV']);
         else
           eval(['save -v7.3 ''',outpath,fout,''' TUV']);
         end
         disp(['total field created and saved for ',outpath,fout, ' at ' datestr(now)]);
         clear TUV RADS RTUV finallist
         
         
       %catch
        % disp(['total field failed for ',foutpath,fout,' at ' datestr(now)]);
        % clear TUV RADS RTUV finallist
       %end
      
    end %if min sites  
  
    fout = strrep(fout,newtimestr,'yyyy_mm_dd_HHMM');  % return to generic filename
    outpath = '';
  end  %time loop
  
  end  %end of "process totals" function



end