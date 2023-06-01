function mustBeCellOfChars(input)
%
% Custom validator for PURPOSE.
%
% Throws an exception if input is not;
%
%   Size and class:
%       a) (cell, M x N)
%   Values:
%       b) (char, M x 1) or (char, 1 x N)
%

% Check if each cell element is char.
if ~iscellstr(input)
    error('Must be a cell array of character vectors or an empty cell.');
end

end