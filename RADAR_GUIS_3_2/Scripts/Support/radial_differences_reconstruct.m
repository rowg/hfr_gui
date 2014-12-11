%radial_differences.m
%T. Garner  6/23/2008
%INPUT: 2 radial structures
%OUTPUT: plots

function [] = radial_differences(R1,R2,gridval,AA)

AA = load('HFR_INFO.mat');

%gridval = 1; % start with first grid in the information file
%if gridval <= size(AA.HFR_GRIDS.name,1)
  sgrid = AA.HFR_GRIDS.name{gridval};
%else
%  disp('Attempting to use custom grid') 
%end

if AA.HFR_GRIDS.spacing{gridval} == 2
    sc=0.0005;      % scaling for quiver arrow
else
    sc = 0.005;
end
xmin = min(AA.HFR_GRIDS.lonlat{gridval}(:,1)); xmax = max(AA.HFR_GRIDS.lonlat{gridval}(:,1));
ymin = min(AA.HFR_GRIDS.lonlat{gridval}(:,2)); ymax = max(AA.HFR_GRIDS.lonlat{gridval}(:,2));
% pad so map is slightly larger than the grid
pady = (ymax - ymin).*0.02;
padx = (xmax - xmin).*0.02;

%computations
% in one file but not the other

%raw data for checking computation
try
  LL1 = R1.OtherMetadata.RawData(:,1:2);
  LL2 = R2.OtherMetadata.RawData(:,1:2);
  [LLC,LL1only,LL2only] = setxor(LL1, LL2,'rows'); % verified same as using R1.LonLat, R2.LonLat so order of rawdata is same
catch
 disp('No raw data included in MAT file')
end


[C,IR1only,IR2only] = setxor(R1.LonLat, R2.LonLat,'rows');
if ~( isempty(IR1only) && isempty(IR2only))
R1o_U = R1.U(IR1only);
R1o_V = R1.V(IR1only);
R2o_U = R2.U(IR2only);
R2o_V = R2.V(IR2only);
end

% in both files
try
[Craw,IR1raw,IR2raw] = intersect(LL1, LL2,'rows');
catch
 disp('No raw data included in MAT file')
end


[C,IR1,IR2] = intersect(R1.LonLat, R2.LonLat,'rows');
if ~isempty(IR1);
R1_U = R1.U(IR1);
R1_V = R1.V(IR1);
R2_U = R2.U(IR2);
R2_V = R2.V(IR2);
R1_R = R1.RadComp(IR1);
R2_R = R2.RadComp(IR2);
R1B = R1.RangeBearHead(IR1,2);
R2B = R2.RangeBearHead(IR2,2);
% check that locations are the same
%disp('Locations equal? ')
%isequalwithequalnans(R1.LonLat(IR1),R2.LonLat(IR2))

% find the intersection of unique ranges from both files
%R1RNG = unique(R1.RangeBearHead(IR1,1));
%R2RNG = unique(R2.RangeBearHead(IR2,1));
%commonranges = intersect(R1RNG,R2RNG);
%for xx = 1:size(commonranges,1)
%end


% radial differences for locations found in both files
nn = find(~isnan(R1_R+R2_R));
[ccr] = corrcoef(R1_R(nn),R2_R(nn));
rsq = ccr(1,2);
% least squares fit line
ccp = polyfit(R1_R(nn),R2_R(nn),1);



Udif = R1_U - R2_U;
Vdif = R1_V - R2_V;
[spd1,dir1] = uv2spdir(R1_U,R1_V);
[spd2,dir2] = uv2spdir(R2_U,R2_V);
spd_signed = (spd1-spd2);
[spdif, ddif] = uv2spdir(Udif,Vdif);

ipos = find(spd_signed>0);
iposbig = find(spd_signed > 0 & spdif>30);
inegbig = find(spd_signed < 0 & spdif>30);
% changed direction?
flipaway  = find(R1.U(IR1) < 0 & R2.U(IR2) > 0);
flipto = find(R1.U(IR1) > 0 & R2.U(IR2) < 0);
end

%text printout

disp(sprintf('%s: %4d radials',char(R1.FileName),size(R1.U,1)));
disp(sprintf('%s: %4d radials',char(R2.FileName),size(R2.U,1)));


%plots
crf = figure('Position',[360,500,1000,800]);

subplot(2,2,1)
fsize = 10;
plot(R1_R,R2_R,'k.')
mval = max(max(abs(R1_R),abs(R2_R)));
axis([-mval mval -mval mval])
fline = polyval(ccp,R1_R);
hold on
plot(R1_R,fline,'r-','LineWidth',2)
xlabel('R1 Velocity (cm/s)')
ylabel('R2 Velocity (cm/s)')
[r1p,r1name,r1sf] = fileparts(char(R1.FileName)); [r2p,r2name,r2sf] = fileparts(char(R2.FileName));

tstr = sprintf('R1= %s    (%3d count)\nR2= %s   (%3d count)',r1name,size(R1.U,1),r2name,size(R2.U,1));
title(tstr,'Interpreter','none');
thandle0 = text(0.1,0.90,sprintf('R^2 = %5.2f\n%4d values\ny = %5.2fx + %5.2f',rsq, length(nn),ccp(1),ccp(2)),'Units','normalized','HorizontalAlignment','left','FontSize',fsize,'Interpreter','none');
grid

if 0 %not needed because locations are the same for reconstructed file
plotBasemap([xmin-padx xmax+padx],[ymin-pady ymax+pady],['''',AA.HFR_PATHS.gui_dir,'GridFiles/map_',sgrid,'.mat'''],'lambert')
hold on   
if exist('R1o_U', 'var')
P1 = m_quiver(R1.LonLat(IR1only,1),R1.LonLat(IR1only,2),sc*R1o_U,sc*R1o_V,0);  
set(P1,'Color','r')
end
if exist('R1o_U', 'var')
P2 = m_quiver(R2.LonLat(IR2only,1),R2.LonLat(IR2only,2),sc*R2o_U,sc*R2o_V,0);  
set(P2,'Color','b')
end
if ~( isempty(IR1only) && isempty(IR2only))
T1 = title(sprintf('R1 Only: %3d count (red)  R2 Only: %3d count (blue)',length(IR1only),length(IR2only)));
set(T1,'FontSize',fsize);
end
set(gca,'FontSize',fsize);
end %if 0 

%figure
subplot(2,2,2)
set(gca,'FontSize',fsize);
plotBasemap([xmin-padx xmax+padx],[ymin-pady ymax+pady],['''',AA.HFR_PATHS.gui_dir,'GridFiles/map_',sgrid,'.mat'''],'lambert')
hold on 
if 0
P12 = m_quiver(R2.LonLat(IR2,1),R2.LonLat(IR2,2),sc*Udif,sc*Vdif,0);  
set(P12,'Color','m')
P12c = m_quiver(R2.LonLat(IR2(ipos),1),R2.LonLat(IR2(ipos),2),sc*Udif(ipos),sc*Vdif(ipos),0);  
set(P12c,'Color','c')
P12blarge = m_quiver(R2.LonLat(IR2(iposbig),1),R2.LonLat(IR2(iposbig),2),sc*Udif(iposbig),sc*Vdif(iposbig),0);  
set(P12blarge,'Color','b');
P12rlarge = m_quiver(R2.LonLat(IR2(inegbig),1),R2.LonLat(IR2(inegbig),2),sc*Udif(inegbig),sc*Vdif(inegbig),0);  
set(P12rlarge,'Color','r');
end
%T2 = title(sprintf('Velocity Differences (R1-R2) for All Shared Radials %3d count\nR1 slower (pink/red)  R2 slower (cyan/blue), Darker shades >30cm/s\nAverage Speed Difference = %4.1f cm/s',length(IR2),mean(spdif)));
T2 = title(sprintf('Velocity Differences (R1-R2) for All Shared Radials %3d count\nAverage Speed Difference = %4.1f cm/s',length(IR2),mean(spdif(~isnan(spdif)))));

set(T2,'FontSize',fsize);

% use mvec arrows

 % make all vectors the same size
      
         %simplify the indices first
         LONC = R2.LonLat(IR2,1); LATC = R2.LonLat(IR2,2);  %latitude and longitude for positions common to both files
         
         %do not plot vectors outside the map area
         imap = find(LONC > (xmin-padx) & LONC < (xmax+padx) & LATC > (ymin-pady) & LATC < (ymax+pady));
         LONmap = LONC(imap);  LATmap = LATC(imap);
         Umap = Udif(imap);  Vmap = Vdif(imap);
         [spd,direc] = uv2spdir(Umap,Vmap);
         [novar,isort] = sort(spd);
         scs = zeros(length(spd),1) + 0.05;%sc;
         [Usc, Vsc] =  spddir2uv(scs, direc(isort));

         maxcolor = 40;
         edges = 1:1:maxcolor;  %cm/s
         cmap = colormap(jet(length(edges)+1));         
         edges = [-inf edges inf];                     % speeds under/over a min/max value will be drawn with same color as the min/max value
         [novar,BIN] = histc(spd(isort),edges);
         for ii = 1:length(BIN);
            try
              cvals(ii,:) = cmap(BIN(ii),:);
            catch
              cvals(ii,:) = [1 1 1];  % white for bins with no values
            end
         end
         
         aa = 1:length(BIN);
         m_vec(1,LONmap(isort(aa)), LATmap(isort(aa)), Usc(aa),Vsc(aa),cvals(aa,:),'headlength',2);
         plotcolorbar(cmap,edges);

%figure
subplot(2,2,3)
set(gca,'FontSize',fsize);
plotBasemap([xmin-padx xmax+padx],[ymin-pady ymax+pady],['''',AA.HFR_PATHS.gui_dir,'GridFiles/map_',sgrid,'.mat'''],'lambert')
hold on
PAWAY = m_quiver(R2.LonLat(IR2(flipaway),1),R2.LonLat(IR2(flipaway),2),sc*Udif(flipaway),sc*Vdif(flipaway),0); 
PTO = m_quiver(R2.LonLat(IR2(flipto),1),R2.LonLat(IR2(flipto),2),sc*Udif(flipto),sc*Vdif(flipto),0);
set(PTO,'Color','r')
set(PAWAY,'Color','b')    
T3 = title(sprintf('Direction Changes (Subset of Shared Radials %3d count)\n Average Speed Difference = %4.1f cm/s',length(flipaway)+length(flipto),(mean(spdif([flipaway;flipto])))));
set(T3,'FontSize',fsize);
thandle = text(-0.15,-0.2,tstr,'Units','normalized','HorizontalAlignment','left','FontSize',fsize,'Interpreter','none');

%figure
subplot(2,2,4)
set(gca,'FontSize',fsize);
plot(math2true(R1.RangeBearHead(IR1,2)),spdif,'k.')
xlabel('Bearing (deg True)')
ylabel('Speed Difference (cm/s)')
T4 = title(sprintf('Bearing vs. Speed Differences \nfor All Shared Radials'));
set(T4,'FontSize',fsize);
set(gca,'XLim',[0 360]);

%print -dpng /Users/garner/Desktop/test.png

function plotcolorbar(cmap,edges)
   % add the colorbar with appropriate labels
   
   hcb = colorbar('East');
       set(hcb,'Units','normalized')
       A = get(hcb,'OuterPosition');
       set(hcb,'OuterPosition',[A(1)+0.07 A(2) A(3) A(4)]);
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


end