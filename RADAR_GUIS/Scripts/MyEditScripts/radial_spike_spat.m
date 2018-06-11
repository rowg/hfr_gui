
% radial_spike_spat.m
% T. Updyke Nov 28 2012


function [RADIAL,EDIT_INDEX] = radial_spike_spat(R,outfname,vf,sf)


RADIAL_ORIG = R;


%-------------------------  add your code here ------------------------%


% output variable must include:
% RADIAL      the new edited radial with flagged data REMOVED from the radial,
%               not simply assigned to NaN or a flag value!! 
% EDIT_INDEX  containing indices for the deleted data in original radial structure 

% Based on OOI spike test (1341-10006_Data_Product_SPEC_SPKETST_OOI.pdf) 
% Uses a modified version of Matlab code dataqc_spiketest.m containing the
% following description:
% DATAQC_SPIKETEST   Data quality control algorithm testing a time
%                    series for spikes. Returns 1 for presumably
%                    good data and 0 for data presumed bad.
%
% Time-stamp: <2010-07-28 14:25:42 mlankhorst>
%
% METHODOLOGY: The time series is divided into windows of length L
%   (an odd integer number). Then, window by window, each value is
%   compared to its (L-1) neighboring values: a range R of these
%   (L-1) values is computed (max. minus min.), and replaced with
%   the measurement accuracy ACC if ACC>R. A value is presumed to
%   be good, i.e. no spike, if it deviates from the mean of the
%   (L-1) peers by less than a multiple of the range, N*max(R,ACC).
%
%   Further than (L-1)/2 values from the start or end points, the
%   peer values are symmetrically before and after the test
%   value. Within that range of the start and end, the peers are
%   the first/last L values (without the test value itself).
%
%   The purpose of ACC is to restrict spike detection to deviations
%   exceeding a minimum threshold value (N*ACC) even if the data
%   have little variability. Use ACC=0 to disable this behavior.


acc = 5;
N = 5;
L = 5;
nanmax = 1;


Rstep = min(diff(unique(R.RangeBearHead(:,1)))); 
Bstep =  min(diff(unique(R.RangeBearHead(:,2))));
AngLim = 10;
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

BRpad = [BRvel(end-(BLim-1):end,:); BRvel; BRvel(1:BLim,:)];

% construct 2 matrices with spike test results along range and along
% bearing separately
BR_btest = BRpad.*NaN;
BR_rtest = BRpad.*NaN;

% loop through range cells and look for spikes in bearing with modified OOI code
for rr = 1:size(BRpad,2)
  BR_btest(:,rr)=dataqc_spiketest_tgu(BRpad(:,rr),acc,N,L,nanmax);
end

% loop through bearing cell and look for spikes in range with modified OOI code
for bb = 1:size(BRpad,1)
BR_rtest(bb,:)=dataqc_spiketest_tgu(BRpad(bb,:),acc,N,L,nanmax);
end



% combine the two results (a zero in one or the other flags the data
% point)
BRedit = min(BR_rtest,BR_btest);
%only range for testing
%BRedit = BR_rtest;
%only bearing for testing
%BRedit = BR_btest;

BRedit = BRedit(BLim+1:BLim+size(BRvel,1),:);
BRedit(BRedit==0) = NaN;
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

%fprintf('%s\n',num2str(length(EDIT_INDEX)));

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
title(sprintf('%s %s\nOOI Spike Test (L = %1d, N = %1d, ACC = %2d, nanmx=%d)',RADIAL.SiteName, datestr(RADIAL.TimeStamp),L,N,acc,nanmax));
perc_reduction = round((length(EDIT_INDEX)./length(R.U)).*100);
xlabel(['Points Removed: ',num2str(length(EDIT_INDEX)),' of ', num2str(length(R.U)), '  (',num2str(perc_reduction),'%)'])

%view figure
if vf
   set(f,'Visible','on')
end

%save figure
if sf
   pstr = sprintf('print(f,''-dpng'',%s_L%1d_N%1d_A%02d_NM%1d.png'')',outfname(1:end-5),L,N,acc,nanmax);
   try
     eval(pstr)
   catch
     disp('Could not save figure to file.')
   end
    
end

end


