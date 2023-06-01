function setFigurePositionXYWH(hFig,positionXYWH)
%
% Set a position to the figure in [x,y,width,height] format.
%
% <Input>
%   positionXYWH: (numeric, 1 x XYWH)
%       Position and size of the figure to set in [x,y,width,height]
%       format. x and y are the coordinate of the top-left point of the 
%       figure. The top-left corner of the primary display is the origin
%       (x=1, y=1).

% Get the figure size and position to set.
x      = positionXYWH(1);
y      = positionXYWH(2);
width  = positionXYWH(3);
height = positionXYWH(4);

% Get the height of the primary display.
[displayHeight,~] = screenSize();

% Initialize an array for a position in [left,bottom,width,height] format.
positionLBWH = zeros(1,4);

% Convert the figure postion to [left,bottom,width,height] format.
positionLBWH(1) = x;
positionLBWH(2) = displayHeight-y-height+2;
positionLBWH(3) = width;
positionLBWH(4) = height;

% NOTE: [left,bottom,width,height] format
% a) The bottom-left corner of the primary display is the origin 
%    (left=1, bottom=1). 
% b) left is the distance from the left edge of the primary display to the
%    left edge of the figure.
% c) bottom is the distance from the bottom edge of the primary display to
%    the bottom edge of the figure.

% Set the position to the figure.
set(hFig,'Position',positionLBWH);

end