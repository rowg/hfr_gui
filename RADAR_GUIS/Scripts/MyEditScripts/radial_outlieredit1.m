
% radial_outlieredit1.m
% T. Garner May 26 2010
% remove outliers in a radial map
% calculate mean and std dev of all speeds
% find values that are greater than 3 times std dev from the mean 
% then disregard those outliers and calculate another mean and std dev
% remove any values greater than 4 the new std dev from the new mean

function [RADIAL,EDIT_INDEX] = radial_outlieredit1(R,outfname,vf,sf)


RADIAL_ORIG = R;
RADIAL=[];
EDIT_INDEX=[];

m = 4;
[nr,nc]=size(R.U);
[SPD,DIREC] = uv2spdir(R.U,R.V);
disp('All')
avg = mean(SPD(find(~isnan(SPD))))
sig = std(SPD(find(~isnan(SPD))))

[n,p] = size(SPD);
MeanMat = repmat(avg,n,nc);
SigmaMat = repmat(sig,n,nc);
cut1 = abs(SPD-MeanMat) >= SigmaMat*(m-1);
SPDc = SPD; SPDc(cut1) = NaN;  SPDc(cut1) = NaN;  % set outlying speeds to NaN and recalculate stats
disp('After first outlier removal')
avg2 = mean(SPD(find(~isnan(SPDc))))
sig2 = std(SPD(find(~isnan(SPDc))))
MeanMat2 = repmat(avg2,n,nc);  
SigmaMat2 = repmat(sig2,n,nc);
okdata = abs(SPD-MeanMat2) < SigmaMat2*m;  % loosen criteria now that stats do not include large outliers


ikeep = find(okdata == 1);
EDIT_INDEX = find(okdata == 0);
RADIAL = subsrefRADIAL(R, ikeep, ':', 0);


eval(['save ',outfname, ' RADIAL RADIAL_ORIG EDIT_INDEX']);
disp(['Saved to ',outfname]);


if vf || sf

% set scaling based on range difference
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
%set(H1,'Color',[1 0 1])
set(H1,'Color',[0 0.5 0])
title([RADIAL.SiteName, ' ',datestr(RADIAL.TimeStamp),' (outliers: spd > ',num2str(m),'*std)'])
perc_reduction = round((length(EDIT_INDEX)./length(R.U)).*100);
xlabel(['Points Removed: ',num2str(length(EDIT_INDEX)),' of ', num2str(length(R.U)), '  (',num2str(perc_reduction),'%)'])


%view figure
if vf
   set(f,'Visible','on')
end

%save figure
if sf
   %eval(['saveas(f',',',outfname(1:end-5),'.fig''', ',''fig'')'])
   eval(['print(f,''-dpng''',',',outfname(1:end-5),'.png''', ')'])
end

end


