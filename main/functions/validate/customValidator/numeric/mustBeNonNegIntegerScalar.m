function mustBeNonNegIntegerScalar(input)
%
% Custom validator for PURPOSE.
%
% Throws an exception if input is not;
%
%   Size and class:
%       a) numeric (1 x 1)
%   Values:
%       b) nonnegative
%       c) integer
%

mustBeNumelOne(input);
mustBeNonNegInteger(input);

end