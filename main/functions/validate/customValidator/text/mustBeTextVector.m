function mustBeTextVector(input)
%
% Custom validator for PURPOSE.
%
% Throws an exception if input is not;
%
%   Size and class:
%       a) (char, 1 x N) or 
%       b) (cell, vector) < (char, 1 x N) or 
%       c) (string, vector)
%   Values:
%       b) CONDITION2
%       c) CONDITION3
%

% Validations.
mustBeText(input);
mustBeVector(input);

end