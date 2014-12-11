function [u,v] = spddir2uv(speed, dir)
%SPDDIR2UV  convert speed in degrees and direction to u/v velocities.
%
%  [U,V] = SPDDIR2UV(SPEED,DIR)  converts SPEED/DIR to U,V.  It is assumed
%  that direction is in what I call for a lack of a better term the math
%  system.  So the direction, DIR, is the vector angle measured in degrees 
%  ccw from east, where east = 0 degrees, north = 90 degrees.
%
%  NOTE:  Uses the formula
%         u = |speed| * cos(direction)
%         v = |speed| * sin(direction)
%
%  NOTE:  It is assumed that the angles are in degrees 0 < angle < 360.
%
%  See also UV2SPDIR, TRUE2MATH, MATH2TRUE, MET2OC. 


%  Mike Cook - NPS Oceanography Dept., JUN 95

if nargin ~= 2
   error(' You *MUST* supply both speed and direction (degrees) as inputs')
end

u = abs(speed) .* cos(radians(dir));
v = abs(speed) .* sin(radians(dir));
