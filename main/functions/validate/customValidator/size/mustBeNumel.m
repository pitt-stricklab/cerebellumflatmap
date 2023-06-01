function mustBeNumel(input,numEl)
%
% Custom validator for PURPOSE.
%
% Throws an exception if input is not;
%
%   Size and class:
%       a) number of elements matches to numEl
%

% NOTE:
% Don't use validate numEl by a validation that uses this validation
% mustBeNumel.

% Validation
validateattributes(input,{class(input)},{'numel',numEl});

end