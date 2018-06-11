function [redblueI] = interp_redblue(n)

%load redblue_hjr;  %original colormap
%figure; plot(x,redblue(:,1),'r-.'); hold on; plot(x,redblue(:,2),'b.'); plot(x,redblue(:,3),'g--');
%colormap(redblue);
%colorbar('vert');
%figure; plot(x/length(x),redblue(:,1),'r-.'); hold on; plot(x/length(x),redblue(:,2),'b.'); plot(x/length(x),redblue(:,3),'g--');
%colormap(redblue);
%colorbar('vert');

% reproduce this structure for a set of n values

% error with interp1 if n is even
even = 0;
if mod(n,2) == 0
   even = 1;
   n = n+1;
end 

% set values at end of line segments
x(1) = 1; y(1,:) = [0 0 0.5625];
x(2) = ceil(0.2*n); y(2,:) = [0 0 1];
x(3) = floor(0.5*n); y(3,:) = [0.6875 0.6875 1];
x(4) = ceil(0.5*n);  y(4,:) = [1 0.6875 0.6875];
x(5) = ceil(0.8*n); y(5,:) = [1 0 0];
x(6) = n; y(6,:) = [0.5625 0 0];

% then linearly interpolate through these for however many values are requested
xI = 1:n;
redblueI = interp1(x,y,xI);

if even
    %take out the last row to get back to original length, won't be exactly
    %symmetric but ok
    redblueI = redblueI(1:n-1,:);
end


% figure; plot(xI,redblueI(:,1),'r-.'); hold on; plot(xI,redblueI(:,2),'b.'); plot(xI,redblueI(:,3),'g--'); set(gca,'XLim',[1 n]);
% colormap(redblueI);
% colorbar('vert');
% figure; plot(xI/length(xI),redblueI(:,1),'r-.'); hold on; plot(xI/length(xI),redblueI(:,2),'b.'); plot(xI/length(xI),redblueI(:,3),'g--');
% colormap(redblueI);
% colorbar('vert');