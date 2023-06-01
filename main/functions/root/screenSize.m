function [height,width] = screenSize()

% Return the height and width of the primary display.
sp = screenPosition();
width  = sp(3);
height = sp(4);

end