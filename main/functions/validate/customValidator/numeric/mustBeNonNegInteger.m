function mustBeNonNegInteger(input)
%
% Custom validator:
%   Throws exception if input is not;
%   a) numeric
%   b) integer
%   c) nonnegative
%

validateattributes(input,{'numeric'},{'integer','nonnegative'})

end