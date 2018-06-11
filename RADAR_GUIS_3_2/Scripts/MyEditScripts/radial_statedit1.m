
function [RADIAL,EDIT_INDEX] = radial_statedit1(R,outfname,vf,sf)

RADIAL=[];
EDIT_INDEX=[];
RADIAL_ORIG = R;

if isfield(R.OtherMetadata,'RawData')
 
[ETMP,ESPC,ERTC,EDVC] = deal(R.OtherMetadata.RawData(:,7),R.OtherMetadata.RawData(:,6),R.OtherMetadata.RawData(:,11),R.OtherMetadata.RawData(:,10));
ETMP(ETMP == 999) = NaN; ESPC(ESPC == 999) = NaN;
EDIT_INDEX = find((ERTC == 2 & ETMP > 12 ) | isnan(ETMP));  % | isnan(ETMP)
inan = find(isnan(ETMP));
disp(['ETMP NaN Count is ',num2str(length(inan))]);



RQ = R;
RQ.U(EDIT_INDEX) = NaN;
RQ.V(EDIT_INDEX) = NaN;
ikeep = find(~isnan(RQ.U));
RADIAL = subsrefRADIAL(RQ, ikeep, ':', 0);

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
  %H0 = m_quiver(R.LonLat(:,1), R.LonLat(:,2), R.U(:).*sc,R.V(:).*sc,0);
  H0 = quiver(R.LonLat(:,1), R.LonLat(:,2), R.U(:).*sc,R.V(:).*sc,0);
  set(H0,'Color','r')
  hold on
  %figure
  H1 = quiver(RQ.LonLat(:,1), RQ.LonLat(:,2), RQ.U(:).*sc,RQ.V(:).*sc,0);
  set(H1,'Color',[0 0.5 0])
  title([RADIAL.SiteName, ' ',datestr(RADIAL.TimeStamp),' (ertc2>12)'])
  perc_reduction = round((length(EDIT_INDEX)./length(ETMP)).*100);
  xlabel(['Points Removed: ',num2str(length(EDIT_INDEX)),' of ', num2str(length(ETMP)), '  (',num2str(perc_reduction),'%)'])

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

else
  disp('Warning: To run this program must have raw data saved in radial file! (e.g.  RADIAL.OtherMetadata.RawData) ')
end