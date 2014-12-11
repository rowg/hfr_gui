function d=latlondist(lat1,lon1,lat2,lon2)

% takes latitude and longitude in decimal degrees, where the 
% first pair is a row vector and the next pair is a 
% column vector of positions, and returns distance(s) in 
% kilometers.
% d=latlondist(lat1,lon1,lat2,lon2)
%
l1=length(lat1);
l2=length(lat2);
lat1=reshape(lat1,l1,1)*ones(1,l2)*pi/180;
lon1=reshape(lon1,l1,1)*ones(1,l2)*pi/180;
lat2=ones(l1,1)*reshape(lat2,1,l2)*pi/180;
lon2=ones(l1,1)*reshape(lon2,1,l2)*pi/180;

r=6370;  % approx. radius of the earth in km

x1=r*cos(lat1).*cos(lon1);
y1=r*cos(lat1).*sin(lon1);
z1=r*sin(lat1);
 
x2=r*cos(lat2).*cos(lon2);
y2=r*cos(lat2).*sin(lon2);
z2=r*sin(lat2);

costh=((x1.*x2)+(y1.*y2)+(z1.*z2))/r^2;

d=real(r*acos(costh));




