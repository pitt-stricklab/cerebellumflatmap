function mustBeLogicalScalar(input)
%
% Custom validator for PURPOSE.
%
% Throws an exception if input is not;
%
%   Size and class:
%       a) logical (1 x 1)
%

% Validations
mustBeA_alt(input,'logical');
mustBeNumelOne(input);

end