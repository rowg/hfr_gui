function autoedit_gui(time)
% AUTOEDIT_GUI Run edit scripts on radial files.

% Initialize Variables

%TIME
   if ~exist('time','var')
    time = floor(now) + (floor( (now - floor(now) ) * 24)/24);  
   end
   endtime = time;
   dtmp0 = 0;
   dtmp1 = datestr(time,'yyyy_mm_dd_HHMM'); 
   tintvl = 60;  % default time interval is 60 minutes, radial input with hourly timestamps

   
  
%INPUT AND OUTPUT INFORMATION
   AA = load('HFR_INFO.mat');
   STN_INFO = AA.HFR_STNS;
   filename = [];
   stn = char(STN_INFO(1).name);
   stnpre = 'RDLm';
   stnsuf = '.ruv';
   sitelist = cell(15,1);
   sitelistdisp = cell(15,1);
   foutpath = [AA.HFR_PATHS.gui_dir,'RadialEdits/'];
   rpath = AA.HFR_PATHS.radial_dir;
   basepath = AA.HFR_PATHS.radial_dir;
   pstruct = AA.HFR_PATHS.radial_pcode;
   pathext = pstruct;
   tpstruct = '';
   tpathext = tpstruct;
   foutp = 'RDLe';
   fout = [foutp,'_[XXXX]_[yyyy]_[mm]_[dd]_[HH][MM].mat'];   
   funcname = 'radial_statedit1';
   
%MISCELLANEOUS
   ii = 1;
   novar = 0;
   viewfig = 0;
   savefig = 0;

   
  
   
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CREATE GUI  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
 
 % Create and hide the GUI figure as it is being constructed.
   fw = 640; fh = 520; yref = 290;
   mgf = figure('Visible','off','Position',[360,500,fw,fh],'MenuBar', 'none');

   startdate_position = [455,140,140,25];
   listbox_position = [150,yref+0,470,160];
   rpathtext_position = [120, yref+195, 500, 20];
   opathtext_position = [120, 250, 500, 20];
   settings_position = [80,147,175,25];
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
   hfunc = uicontrol('Style','pushbutton','String','Function',...
           'Position',settings_position,'Callback',{@funcbutton_Callback});
   hfunctext = uicontrol('Style','text','String',funcname,...
           'Position',settings_position - [ 0 30 0 0]);
       
   hviewfig = uicontrol('Style', 'checkbox', 'String', 'View Figures',...
           'Position', settings_position-[0 70 0 0], 'Callback', {@viewfigcheckbox_Callback}); 
   hsavefig = uicontrol('Style', 'checkbox', 'String', 'Save Images',...
           'Position', settings_position-[0 100 0 0], 'Callback', {@savefigcheckbox_Callback}); 
    
       
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
      
%PROCESS BUTTON
   hedit = uicontrol('Style','pushbutton','String','EDIT RADIALS',...
           'Position',procbutton_position,'BackgroundColor',[0.9 0.2 0.2],'Callback',{@editbutton_Callback});


       
%RADIAL PATH
   hradpath = uicontrol('Style','pushbutton','String','Radial Path',...
           'Position',[30,rpathtext_position(2),80,20],'Callback',{@radpathbutton_Callback});
   hrpath_text = uicontrol('Style','text','String',rpath,...
           'Position',rpathtext_position); 
   hstruct_label = uicontrol('Style','text','String','Path Code',...
           'Position',[30,rpathtext_position(2)-28,78,20],'TooltipString','Enter codes for path directory structure.  All datestr letter codes should be surrounded by & symbols.  XXXX is 4 letter radar site code.');
   hstruct_edit = uicontrol('Style','edit','String',pstruct,...
           'Position',rpathtext_position-[ 0 29 0 -6],'TooltipString','Enter codes for path directory structure.  All datestr letter codes should be surrounded by & symbols.  XXXX is 4 letter radar site code.','Callback',{@pathstruct_Callback}); 

     
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
           'Position',[30,opathtext_position(2)-30,80,20]);
   hoprefix_edit = uicontrol('Style','edit','String',foutp,...
           'Position',opathtext_position-[0 30 420 -5], 'Callback',{@oprefixbutton_Callback});       
   htpcode_label = uicontrol('Style','text','String','Path Code',...
           'Position',opathtext_position-[-90 30 420 -2],'TooltipString','Enter codes for path directory structure for edited data.  All datestr letter codes should be surrounded by square brackets []. [XXXX] is the 4 letter site code.');
   htpcode_edit = uicontrol('Style','edit','String',tpstruct,...
           'Position',opathtext_position-[ -180 30 290 -5],'TooltipString','Enter codes for path directory structure for edited data.  All datestr letter codes should be surrounded by square brackets []. [XXXX] is the 4 letter site code.','Callback',{@tpathstruct_Callback}); 

   
   % Initialize the GUI.
   % Change units to normalized so components resize
   % automatically.
   set([mgf, hedit,hfunc, hfunctext, hdate_label, hdate_edit, henddate_label, henddate_edit, hti_label, hti_edit, ...
   hradpath, hrpath_text, hstruct_edit, hstruct_label, houtprefix_label,hsavefig, hviewfig,...
   hsites, hrprefix_edit, hsuffix, hfilelist, hadd, hclearlist, houtpath, hopath_text,htpcode_label, htpcode_edit, ...
   hoprefix_edit],'Units','normalized');
   
   set(mgf, 'Color',[0.4 0.6 0.9])  % blue
   set([hrpath_text, hopath_text,htpcode_edit],'BackgroundColor',[0.8 0.9 0.9]); % light green
   set([hfunctext,hdate_label,henddate_label,hti_label,hsites, hfilelist, hstruct_label, houtprefix_label,htpcode_label],'BackgroundColor',[1,1,1]); %white
   set([hdate_edit,henddate_edit,hti_edit],'BackgroundColor',[1,1,1],'ForegroundColor',[0 0 1]);
   set([hrprefix_edit, hoprefix_edit,hstruct_edit],'BackgroundColor',[0.8 0.9 0.9],'ForeGroundColor',[0 0 1]);
   % Assign the GUI a name to appear in the window title.
   set(mgf,'Name','Radial Edit GUI')
   % Move the GUI to the center of the screen.
   movegui(mgf,'center')
   % Make the GUI visible.
   set(mgf,'Visible','on'); 
   
   %keyboard
   
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
         basepath(jj,:) = strrep(basepath(jj,:), '[XXXX]', stn(jj,:));
         end
     end
     myfilename = datenum_to_directory_filename(basepath,time,[repmat([stnpre,'_'],size(stn,1),1),stn,repmat(['_'],size(stn,1),1)],stnsuf,0);
     for xx = 1:size(myfilename,2)
       sitelist{ii,1} = myfilename{xx};
       %only display file name not the path
       [novar,filename , novar] = fileparts(char(myfilename{xx}));
       %sitelistdisp{ii,1} = filename;
       sitelistdisp = sitelist;
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

  end

%CLEAR INPUT FILE LIST
  function clearlistbutton_Callback(source,eventdata) 
  % Clears the radial list.  
     clear sitelist sitelistdisp;
     sitelist = cell(15,1);
     sitelistdisp = cell(15,1);
     ii = 1;
     hfilelist = uicontrol('Style','listbox','String',sitelist,...
           'Position',listbox_position, 'Callback',{@filelist_Callback});       
     hclearlist = uicontrol('Style','pushbutton','String','X',...
           'Position',[listbox_position(1)+listbox_position(3)-20,listbox_position(2)+ listbox_position(4)-20,20,20],'Callback',{@clearlistbutton_Callback});
     set(hfilelist,'BackgroundColor',[1 1 1])

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
  function tpathstruct_Callback(hObject, eventdata)
           tpstruct = get(hObject,'String');
           tpathext = tpstruct;
  end


%----------------------- SETTINGS FOR PROCESSING METHOD ----------------------%
function funcbutton_Callback(source,eventdata) 
   cdir = pwd;
   eval(['cd ''',AA.HFR_PATHS.gui_dir,'Scripts/MyEditScripts/''']);
   [funcname] = uigetfile('*.*','Choose a data file');
   funcname = funcname(1:end-2);
   hfunctext = uicontrol('Style','text','String',funcname,...
           'Position',settings_position - [ 0 30 0 0]);
   set(hfunctext,'BackgroundColor',[1 1 1]);
   eval(['cd ''',cdir,''''])      
end

function viewfigcheckbox_Callback(hObject, eventdata, handles)
    if (get(hObject,'Value') == get(hObject,'Max'))
     viewfig = 1; %box checked
    else
     viewfig = 0; %box not checked
    end
  end

 function savefigcheckbox_Callback(hObject, eventdata, handles)
    if (get(hObject,'Value') == get(hObject,'Max'))
     savefig = 1; %box checked
    else
     savefig = 0; %box not checked
    end
  end


%----------------------- BASIC PROCESSING SETTINGS ----------------------%

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


  function editbutton_Callback(source,eventdata) 
  % Calls edit function for radials.   

  times = (datenum(time):(tintvl/60)/24:datenum(endtime)); 
  times = times + 1/24/60/60; % add one second to times
  
  for tt = 1:length(times);

     % insert new times into filenames
     newtimestr = datestr(times(tt),'yyyy_mm_dd_HHMM');
     try
       finallist = strrep(sitelist,dtmp1,newtimestr);
     catch % again why is this section here??
       sitelist = sitelist(1:ii-1);
       finallist = strrep(sitelist,dtmp1,newtimestr);
     end
    
     

     for j2=1:size(sitelist,1)  % loop over list of radial files
 
       fn = finallist{j2};  
       fn = pcode_translation(fn, times(tt));
       d=dir(fn);
       if ~isempty(d)
         if strcmp(fn(end-3:end),'.mat')
            disp(['Loading...',fn])
            eval(['RADIAL = load(''' ,fn,''')']);
            RADIAL = RADIAL.RADIAL;
         else
            RADIAL = loadRDLFile(fn,1);
         end 
         
     
       end
   
     
 
     if ~isempty(RADIAL)
            
       %[dirname,filename] = datenum_to_directory_filename([radialpath,rpcode], dnum, [rpre,'_',sname,'_'], '.ruv',0);
       %dirname = char(dirname);
       %if strcmp(dirname(end), '/') == 0    
       %  myfilename = [dirname,'/',char(filename)];
       %else
       %  myfilename = [dirname,char(filename)];
       %end
       
       fout = strrep(fout,'yyyy_mm_dd_HHMM',newtimestr);
       %outpath = pcode_translation([foutpath,tpathext], times(tt),RADIAL.SiteName);

       outfname = ['''',foutpath,tpathext,fout,''''];
       
       outfname = pcode_translation(outfname, times(tt),RADIAL.SiteName);     
      
        % call the editing routine here
        eval([funcname,'(RADIAL,outfname,viewfig,savefig)']);     
        
       
        fout = strrep(fout,newtimestr,'yyyy_mm_dd_HHMM');  % return to generic filename
        outfname = strrep(outfname,RADIAL.SiteName,'[XXXX]');
        %outfname = ['''',foutpath,fout,''''];
        clear RADIAL
     end %if radial variable is not empty
     end %site loop
  end  %time loop
  
  end  %end of "edit radials" function



end