function mustBePosIntegerScalar(input)
%
% Custom validator for PURPOSE.
%
% Throws an exception if input is not;
%
%   Size and class:
%       a) numeric (1 x 1)
%   Values:
%       b) positive
%       c) integer
%

mustBeNumelOne(input);
mustBePosInteger(input);

end