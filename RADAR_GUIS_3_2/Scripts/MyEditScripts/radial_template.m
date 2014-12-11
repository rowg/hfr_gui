
% radial_template.m
% T. Updyke Nov 28 2012


function [] = radial_template(R,outfname,vf,sf)


RADIAL_ORIG = R;



%-------------------------  add your code here ------------------------%


% output variable must include:
% RADIAL      the new edited radial with flagged data REMOVED from the radial,
%               not simply assigned to NaN or a flag value!! 
% EDIT_INDEX  containing indices for the deleted data in original radial structure 



eval(['save ',outfname, ' RADIAL RADIAL_ORIG EDIT_INDEX']);
disp(['Saved to ',outfname]);



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


