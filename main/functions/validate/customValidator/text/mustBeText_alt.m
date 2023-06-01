function mustBeText_alt(input)
%
% This is an alternative validation to mustBeText(). Check the MATLAB
% version and use an alternative method if it's MATLAB R2020a or older.
%
% Throws an exception if input is not;
%
%   Size and class:
%       a) (char, 1 x N) or
%       b) (cell, M x N) < (char, M x 1), (char, 1 x N) or
%       c) (string, M x N)
%

% NOTE:
% mustBeText allows:
% a) (char, 1 x N) or
% b) (cell, M x N) < (char, 1 x N) or
% c) (string, M x N)

% NOTE:
% mustBeText doesn't allow (cell, M x N) < (char, M x 1), but this
% alternative validation allows it since iscellstr in mustBeCellOfChars
% allows it.

if isMATLABReleaseOlderThan("R2020b")
    
    % Validations
    validateattributes(input,{'char','cell','string'},{});

    % If it's a cell, it must be a cell array of char vectors.
    if iscell(input)
        mustBeCellOfChars(input);
    end
    
else
    mustBeText(input);
end

end