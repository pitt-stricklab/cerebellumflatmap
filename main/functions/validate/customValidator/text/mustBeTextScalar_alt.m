function mustBeTextScalar_alt(input)
%
% This is an alternative validation to mustBeTextScalar(). Check the MATLAB
% version and use an alternative method if it's MATLAB 2020a or older.
%
% Throws an exception if input is not;
%
%   Size and class:
%       a) CONDITION1
%   Values:
%       b) CONDITION2
%       c) CONDITION3
%

% Validations.
if isMATLABReleaseOlderThan("R2020b")
    
    if ~isTextScalar(input)
        error("Value must be a character vector or string scalar.");
    end    
    
else
    mustBeTextScalar(input);
end

end