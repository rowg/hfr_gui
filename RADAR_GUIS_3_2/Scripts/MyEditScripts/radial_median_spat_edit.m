
% radial_median_spat_edit.m
% T. Updyke Nov 14 2016


function [RADIAL,EDIT_INDEX] = radial_median_spat_edit(R,outfname,vf,sf)


RADIAL_ORIG = R;


%-------------------------  add your code here ------------------------%


% output variable must include:
% RADIAL      the new edited radial with flagged data REMOVED from the radial,
%               not simply assigned to NaN or a flag value!! 
% EDIT_INDEX  containing indices for the deleted data in original radial structure 

% Using CODAR's radial median filter as a guide:
% For each radial source vector, the RadialFiller program computes the median of all velocities within 
% radius of <RCLim> * Range Step (km) whose vector bearing (angle of arrival at site) is also within <AngLim>
% degrees from the source vector's bearing. If the difference between the vector's velocity and the median
% velocity is greater than <CurLim> cm/s, then the vector is discarded <in my
% case, set to NaN and then removed>
% default values are: RCLim = 2.1 steps, AngLim = 10 degrees, CurLim  = 30 centimeters per second (cm/s)

RCLim = 2.1; %steps
AngLim = 10;
CurLim = 30;

Rstep = min(diff(unique(R.RangeBearHead(:,1)))); 
Bstep =  min(diff(unique(R.RangeBearHead(:,2))));

RLim = round(RCLim);
BLim = AngLim./Bstep;  % steps, if not an integer will cause an error

% convert range into range cell numbers
RCell = floor((R.RangeBearHead(:,1)./Rstep)+0.1); 
% convert bearing into bearing cell numbers
adj = 5-min(R.RangeBearHead(:,2));
BCell = (R.RangeBearHead(:,2) + adj)./Bstep;

%place velocities into a matrix with rows defined as bearing cell # and columns as range cell #
BRvel = zeros(360./Bstep,max(RCell))*NaN; % velocity matrix organized as (bearing cell , range cell)
BRind = zeros(360./Bstep,max(RCell))*NaN; % index matrix organized as (bearing cell , range cell)
for xx = 1:length(R.RadComp) 
    BRvel(BCell(xx),RCell(xx)) = R.RadComp(xx);
    BRind(BCell(xx),RCell(xx)) = xx;  % keep track of indices so easy to return to original single column format
end 

% deal with 359 to 0 transition in bearing by
% repeating first BLim rows at the bottom and last BLim rows at the top
% don't need to do this on both ends but more straightforward for indexing later
% also pad ranges with NaNs by adding extra columns

BRtemp = [BRvel(end-(BLim-1):end,:); BRvel; BRvel(1:BLim,:)];
rangepad = zeros(size(BRtemp,1),RLim).*NaN;
BRpad = [rangepad BRtemp rangepad];

% construct a version of the matrix with the median of neighboring velocities 
BRmed = BRpad.*NaN;

for bb = BLim+1:BLim+size(BRvel,1)   % all the bearings but not assigning median values to the padded area
  for rr = RLim+1:RLim+size(BRvel,2)   % all the ranges but not assigning median values to the padded area
    BRmed(bb,rr) = nanmedian(reshape((BRpad(bb-BLim:bb+BLim,rr-RLim:rr+RLim)),(BLim*2+1)*(RLim*2+1),1));
  end
end

% now compare median values with original values and remove those with
% absolute difference greater than the current limit
BRdiff = abs(BRvel - BRmed(BLim+1:BLim+size(BRvel,1),RLim+1:RLim+size(BRvel,2))); 
BRedit = BRvel;
BRedit(BRdiff>CurLim) = NaN;

% now insert values back into the original one column structure
for bb = 1:size(BRedit,1)
    for rr = 1:size(BRedit,2)
        if ~isnan(BRind(bb,rr))
        RADIAL.RadComp(BRind(bb,rr)) = BRedit(bb,rr);
        end
    end
end

EDIT_INDEX = find(isnan(RADIAL.RadComp));
sI  = find(isfinite(RADIAL.RadComp));

RADIAL = subsrefRADIAL( R, sI, ':', 1 );


eval(['save ',outfname, ' RADIAL RADIAL_ORIG EDIT_INDEX']);
disp(['Saved to ',outfname]);


% not used, only for checking code
%uR = unique(RCell);
%uB = unique(BCell);
%ubear = unique(R.RangeBearHead(:,2));

%keyboard
%figure; imagesc(BRvel); colorbar('vert'); title('Radial Velocity');xlabel('Range Cell#'); ylabel('Bearing Cell#')
% figure; imagesc(BRpad); colorbar('vert'); title('Padded Radial Velocity for Spatial Neighbor Calculation');xlabel('Range Cell'); ylabel('Bearing Cell')
% figure; imagesc(BRmed); colorbar('vert'); title('Median of Neighboring Radial Velocities');xlabel('Range Cell'); ylabel('Bearing Cell')
% figure; imagesc(BRdiff); colorbar('vert'); title('Absolute Value of Radial Velocities - Median Velocities');xlabel('Range Cell'); ylabel('Bearing Cell')
% figure; imagesc(BRedit); colorbar('vert'); title('Edited Radial Velocities');xlabel('Range Cell'); ylabel('Bearing Cell')


%------------------------- end user custom code -------------------------%


% PLOT 
if vf || sf
    
DI = diff(RADIAL.RangeBearHead(:,1));
rdif = DI(find(DI>0));
if rdif(1) < 2
    sc = 0.00025;
else
    sc = 0.0030;
end

f = figure('Visible', 'off');
H0 = quiver(R.LonLat(:,1), R.LonLat(:,2), R.U(:).*sc,R.V(:).*sc,0);
set(H0,'Color','r')
hold on
H1 = quiver(RADIAL.LonLat(:,1), RADIAL.LonLat(:,2), RADIAL.U(:).*sc,RADIAL.V(:).*sc,0);
set(H1,'Color',[0 0.5 0])
title(sprintf('%s %s\nOutliers: |Velocity - Median of Neighboring Velocities)| > %d cm/s\nNeighbors are within %5.1f km and %d degrees.',RADIAL.SiteName, datestr(RADIAL.TimeStamp),CurLim,RLim*Rstep,AngLim));
perc_reduction = round((length(EDIT_INDEX)./length(R.U)).*100);
xlabel(['Points Removed: ',num2str(length(EDIT_INDEX)),' of ', num2str(length(R.U)), '  (',num2str(perc_reduction),'%)'])

%view figure
if vf
   set(f,'Visible','on')
end

%save figure
if sf
   pstr = sprintf('print(f,''-dpng'',%s.png'')',outfname(1:end-5));
   try
     eval(pstr)
   catch
     disp('Could not save figure to file.')
   end
    
end

end


