function [speed,dir] = uv2spdir(u,v)
%UV2SPDIR  convert u/v velocity components to speed/direction in degrees.
%
% [SPEED,DIR] = UV2SPDIR(U,V) converts U/V velocity components into
% speed SPEED and direction DIR.  The direction DIR is output in 
% what I call for a lack of a better term the math system, where
% DIR is the vector angle measured in degrees ccw for east,
% where east = 0 degrees, north = 90 degrees ...
%
% NOTE:  Output angles are in degrees 0 < angle < 360.
%
%  See also SPDDIR2UV, TRUE2MATH, MATH2TRUE, MET2OC. 

%  Mike Cook - NPS Oceanography Dept., OCT 96.
%  v 1.1 - replaced find code with mod code to get angles from 0-360 

speed = sqrt(u .^2 + v .^2);
dir = atan2(v,u);
dir = degrees(dir);
dir = mod(dir,360);
