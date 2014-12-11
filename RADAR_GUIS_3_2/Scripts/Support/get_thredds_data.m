
function [LON,LAT,U,V,Uerr,Verr,NRAD] = get_thredds_data(time,gridnum)
% get_thredds_data.m
% import data directly from the Thredds server 
% this could be adapted but for now
% only works if lat/lon index limits go in increments of 1 and there is
% only one time
%%
%% Note: Due to missing times in the Rutgers Thredds server the time
%% indexing is not regular!

tic
url='http://tashtego.marine.rutgers.edu:8080/thredds/dodsC/cool/codar/totals/macoora6km';


AA = load('HFR_INFO.mat');

% If the rutgers oi thredds grid changes, will have to update these values
all_lon = [-75.9895  -75.93143  -75.87335  -75.81528  -75.757195  -75.69912  -75.641045...
    -75.58297  -75.524895  -75.46682  -75.408745  -75.35067  -75.292595  -75.23452  -75.176445...
    -75.11837  -75.060295  -75.00222  -74.944145  -74.88607  -74.827995  -74.76992  -74.711845...
    -74.65377  -74.595695  -74.53762  -74.479546  -74.42147  -74.363396  -74.30532  -74.247246...
    -74.18917  -74.131096  -74.07302  -74.01494  -73.95686  -73.89879  -73.84071  -73.78264...
    -73.72456  -73.66649  -73.60841  -73.55034  -73.49226  -73.43419  -73.376114  -73.31804...
    -73.259964  -73.20189  -73.143814  -73.08574  -73.027664  -72.96959  -72.911514  -72.85344...
    -72.795364  -72.73729  -72.679214  -72.62114  -72.563065  -72.50499  -72.446915  -72.38884...
    -72.330765  -72.27268  -72.21461  -72.15653  -72.09846  -72.04038  -71.98231  -71.92423...
    -71.86616  -71.80808  -71.75001  -71.69193  -71.63386  -71.57578  -71.51771  -71.45963...
    -71.40156  -71.34348  -71.28541  -71.22733  -71.16926  -71.11118  -71.05311  -70.99503...
    -70.93696  -70.87888  -70.82081  -70.76273  -70.70466  -70.64658  -70.58851  -70.53043...
    -70.47236  -70.41428  -70.35621  -70.29813  -70.24005  -70.18198  -70.1239  -70.06583...
    -70.00775  -69.94968  -69.8916  -69.83353  -69.77545  -69.71738  -69.6593  -69.60123...
    -69.54315  -69.48508  -69.427  -69.36893  -69.31085  -69.25278  -69.1947  -69.13663  -69.07855...
    -69.02048  -68.9624  -68.90433  -68.84625  -68.78818  -68.7301  -68.67203  -68.61395  -68.55588...
    -68.497795  -68.43972  -68.381645  -68.32357  -68.265495  -68.20742  -68.149345  -68.09127  -68.033195];

all_lat =    [35.0052  35.05914  35.11308  35.16702  35.22096  35.2749  35.32884  35.38278  35.43672...
    35.49066  35.5446  35.59854  35.65248  35.70642  35.76036  35.8143  35.86824  35.92218  35.97612...
    36.03006  36.084  36.13794  36.19188  36.24582  36.29976  36.3537  36.40764  36.46158  36.51552...
    36.56946  36.6234  36.67734  36.73128  36.78522  36.83916  36.8931  36.94704  37.00098  37.05492...
    37.10886  37.1628  37.21674  37.27068  37.32462  37.37856  37.4325  37.48644  37.54038  37.59432...
    37.64826  37.7022  37.75614  37.81008  37.86402  37.91796  37.9719  38.02584  38.07978  38.13372...
    38.18766  38.2416  38.29554  38.34948  38.40342  38.45736  38.5113  38.56524  38.61918  38.67312...
    38.72706  38.781  38.83494  38.88888  38.94282  38.99676  39.0507  39.10464  39.15858  39.21252...
    39.26646  39.3204  39.37434  39.42828  39.48222  39.53616  39.5901  39.64404  39.69798  39.75192...
    39.80586  39.8598  39.91374  39.96768  40.02162  40.07556  40.1295  40.18344  40.23738  40.29132...
    40.34526  40.3992  40.45314  40.50708  40.56102  40.61496  40.6689  40.72284  40.77678  40.83072...
    40.88466  40.9386  40.99254  41.04648  41.10042  41.15436  41.2083  41.26224  41.31618  41.37012...
    41.42406  41.478  41.53194  41.58588  41.63982  41.69376  41.7477  41.80164  41.85558  41.90952  41.96346];



% USE GRID INFO TO SET THE LOCATION LIMITS
xmin = min(AA.HFR_GRIDS(gridnum).lonlat(:,1)); xmax = max(AA.HFR_GRIDS(gridnum).lonlat(:,1));
ymin = min(AA.HFR_GRIDS(gridnum).lonlat(:,2)); ymax = max(AA.HFR_GRIDS(gridnum).lonlat(:,2));



ilon = find(all_lon >= xmin & all_lon <= xmax); 
ilat = find(all_lat >= ymin & all_lat <= ymax);  

latIs = min(ilat)-1; %subtract 1 because thredds index starts at 0
lonIs = min(ilon)-1;
latI = max(ilat)-1; %57
lonI = max(ilon); %51
latinc = 1;
loninc = 1;
nlat = (latI - latIs) + 1; % would have to change if increments were not 1
nlon = (lonI - lonIs) + 1;


%% FIND TIME INDEX VALUE
%% Note: Due to missing times in the Rutgers Thredds server the time
%% indexing is not regular so have to query for all times using nc_varget which is slow!

 d0 = datenum(2001,1,1,0,0,0);
 ts = nc_varget(url, 'time');
 all_times = ts + d0;
 timeI = find(all_times == time);


%% RETRIEVE DATA FROM SERVER

skipnum = 11; % remove this many places at front of each row to get rid of indices i.e. [0][100]
latind = [num2str(latIs),':',num2str(latinc),':',num2str(latI)];
lonind = [num2str(lonIs),':',num2str(loninc),':',num2str(lonI)];
ivals = ['[',num2str(timeI),'][',latind,'][',lonind,']'];
disp(['http://tashtego.marine.rutgers.edu:8080/thredds/dodsC/cool/codar/totals/macoora6km.ascii?u',ivals,',v',ivals,',u_err',ivals,',v_err',ivals,',num_radials',ivals]);

A = urlread(['http://tashtego.marine.rutgers.edu:8080/thredds/dodsC/cool/codar/totals/macoora6km.ascii?u',ivals,',v',ivals,',u_err',ivals,',v_err',ivals,',num_radials',ivals]);
 
%% EXTRACT TIME
latheader = ['num_radials.lat[',num2str(nlat),']'];
latstart = strfind(A,latheader);
tloc = strfind(A,'num_radials.time[1]');
tval = A(tloc+19:latstart-1);
disp(['Retrieving data from ',datestr(datenum([2001 1 1 0 0 0]) + str2num(tval))])

if time - (datenum([2001 1 1 0 0 0]) + str2num(tval)) < 0.04

%% EXTRACT U COMPONENT DATA
uheader = ['u.u[1][',num2str(nlat),'][',num2str(nlon),']'];

 ustart = strfind(A,uheader);
 uend = strfind(A,'u.time[1]');
 B = A(ustart+length(uheader):uend-1);
 Be = strrep(B,'],',']       '); % allows for greater space between indices and data so taking out more spaces for indices will not cut out data
 Be = strrep(Be,',',' ');
 
  c=[0 find(Be==10)]; % find end of line characters for each row of text 
  for j2=2:length(c)-1 
      F{j2}=Be(c(j2)+skipnum:c(j2+1)-1);
  end
  
  F = F(2:end-1);
  
  UU = zeros(nlat,nlon).*NaN;
  for xx = 1:nlat;
      UU(xx,1:nlon) = str2num(F{xx});
  end;
  
  
  
 %% EXTRACT V COMPONENT DATA
 clear F B Be c
 vheader = ['v.v[1][',num2str(nlat),'][',num2str(nlon),']'];
 vstart = strfind(A,vheader);
 vend = strfind(A,'v.time[1]');
 B = A(vstart+length(vheader):vend-1);
 Be = strrep(B,'],',']       '); % allows for greater space between indices and data so taking out 9 or more spaces for indices will not cut out data
 Be = strrep(Be,',',' ');
 
  c=[0 find(Be==10)]; % find end of line characters for each row of text 
  for j2=2:length(c)-1 
      F{j2}=Be(c(j2)+skipnum:c(j2+1)-1);
  end
  
  F = F(2:end-1);
  
  VV = zeros(nlat,nlon).*NaN;
  for xx = 1:nlat;
      VV(xx,1:nlon) = str2num(F{xx});
  end;
  
   %% EXTRACT U ERR DATA
 clear F B Be c vstart vend vheader
 vheader = ['u_err.u_err[1][',num2str(nlat),'][',num2str(nlon),']'];
 vstart = strfind(A,vheader);
 vend = strfind(A,'u_err.time[1]');
 B = A(vstart+length(vheader):vend-1);
 Be = strrep(B,'],',']       '); % allows for greater space between indices and data so taking out 9 or more spaces for indices will not cut out data
 Be = strrep(Be,',',' ');
 
  c=[0 find(Be==10)]; % find end of line characters for each row of text 
  for j2=2:length(c)-1 
      F{j2}=Be(c(j2)+skipnum:c(j2+1)-1);
  end
  
  F = F(2:end-1);
  
  UUERR = zeros(nlat,nlon).*NaN;
  for xx = 1:nlat;
      UUERR(xx,1:nlon) = str2num(F{xx});
  end;

 %% EXTRACT V ERR DATA
 clear F B Be c vstart vend vheader
 vheader = ['v_err.v_err[1][',num2str(nlat),'][',num2str(nlon),']'];
 vstart = strfind(A,vheader);
 vend = strfind(A,'v_err.time[1]');
 B = A(vstart+length(vheader):vend-1);
 Be = strrep(B,'],',']       '); % allows for greater space between indices and data so taking out 9 or more spaces for indices will not cut out data
 Be = strrep(Be,',',' ');
 
  c=[0 find(Be==10)]; % find end of line characters for each row of text 
  for j2=2:length(c)-1 
      F{j2}=Be(c(j2)+skipnum:c(j2+1)-1);
  end
  
  F = F(2:end-1);
  
  VVERR = zeros(nlat,nlon).*NaN;
  for xx = 1:nlat;
      VVERR(xx,1:nlon) = str2num(F{xx});
  end;
  
  
 %% EXTRACT V ERR DATA
 clear F B Be c vstart vend vheader
 vheader = ['num_radials.num_radials[1][',num2str(nlat),'][',num2str(nlon),']'];
 vstart = strfind(A,vheader);
 vend = strfind(A,'num_radials.time[1]');
 B = A(vstart+length(vheader):vend-1);
 Be = strrep(B,'],',']       '); % allows for greater space between indices and data so taking out 9 or more spaces for indices will not cut out data
 Be = strrep(Be,',',' ');
 
  c=[0 find(Be==10)]; % find end of line characters for each row of text 
  for j2=2:length(c)-1 
      F{j2}=Be(c(j2)+skipnum:c(j2+1)-1);
  end
  
  F = F(2:end-1);
  
  NNRAD = zeros(nlat,nlon).*NaN;
  for xx = 1:nlat;
      NNRAD(xx,1:nlon) = str2num(F{xx});
  end;

  
  %% EXTRACT GRID DATA
  lonheader = ['num_radials.lon[',num2str(nlon),']'];
  lonstart = strfind(A,lonheader);
  LT = A(latstart+length(latheader):lonstart-1);
  LT = strrep(LT,',',' ');
  LATITUDE = str2num(LT);
 
  LN =  A(lonstart+length(lonheader):end);
  LN = strrep(LN,',',' ');
  LONGITUDE = str2num(LN);
 
 
  [mX,mY] = meshgrid(LONGITUDE,LATITUDE);
  LON = reshape(mX,nlat*nlon,1);
  LAT = reshape(mY,nlat*nlon,1);
  U = reshape(UU,nlat*nlon,1);
  V = reshape(VV,nlat*nlon,1);
  Uerr = reshape(UUERR,nlat*nlon,1);
  Verr = reshape(VVERR,nlat*nlon,1);
  NRAD = reshape(NNRAD,nlat*nlon,1);
  
  iflag = find(U == -999);
  U(iflag) = NaN;
  V(iflag) = NaN;
  %Uerr(iflag) = NaN;
  %Verr(iflag) = NaN;
  %NRAD(iflag) = NaN;

  toc
else
    disp('Aborting - times do not match!')
end  
  
  