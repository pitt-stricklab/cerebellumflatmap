function sp = screenPosition()
%
% Return the position and size of the primary display.
%
% <Output>
%   sp: (double, 1 x 4)
%       Position and size of the primary screen in 
%       [left bottom width height] format. The bottom-left of the display 
%       is (left=1, bottom=1). 

gr = groot;
sp = gr.ScreenSize;

end