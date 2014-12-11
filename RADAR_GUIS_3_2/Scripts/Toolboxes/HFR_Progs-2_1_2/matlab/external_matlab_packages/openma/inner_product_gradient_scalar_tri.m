function ip = inner_product_gradient_scalar_tri( p, t, ux1, uy1, ux2, uy2 )
% INNER_PRODUCT_GRADIENT_SCALAR_TRI - computes the "inner product"
% between two current fields defined on a single triangular grid.
%
% Usage: ip = inner_product_gradient_scalar_tri( p, t, u1, u2 )
%        ip = inner_product_gradient_scalar_tri( p, t, ux1, uy1, ux2, uy2 )
%
% The inner product is defined at the integral of the dot product of the
% two current fields divided by the total area.
%
% In the first form, u1 and u2 are scalar fields defined at the points in
% p.  The gradient of each field will be taken and then the inner product
% will be calculated.
%
% In the second form, (ux1,uy1) and (ux2,uy2) are a pair of current
% fields defined at the centers of the triangles in t.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: inner_product_gradient_scalar_tri.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 6
  [ux2,uy2] = pdegrad( p, t, uy1 );
  [ux1,uy1] = pdegrad( p, t, ux1 );
end

area = pdetrg( p, t );
ip = sum( area(:) .* (ux1(:).*ux2(:) + uy1(:).*uy2(:)) ) / sum(area);
