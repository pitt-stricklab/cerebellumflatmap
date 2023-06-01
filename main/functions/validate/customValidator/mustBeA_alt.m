function mustBeA_alt(input,classNames)
%
% This is an alternative validation to mustBeA(). Check the MATLAB version
% and use an alternative method if it's MATLAB 2020a or older.
%
% Throws an exception if input is not;
%
%   Size and class:
%       a) CONDITION1
%   Values:
%       b) CONDITION2
%       c) CONDITION3
%

% Validations
if isMATLABReleaseOlderThan("R2020b")
    
    % Convert classNames to string.
    classNames = string(classNames);
    
    % Check if the class is valid.
    if ~any(strcmp(class(input),classNames))
        error(...
            "Value must be of the following types: '%s'.",...
            strjoin(classNames,"' or '")...
        );
    end
    
else
    mustBeA(input,classNames);
end

end