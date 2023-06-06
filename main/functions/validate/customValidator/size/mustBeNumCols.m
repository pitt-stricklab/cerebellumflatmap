function mustBeNumCols(input,numCols)
%
% Custom validator for PURPOSE.
%
% Throws an exception if input is not;
%
%   Size and class:
%       a) (M x numCols)
%

% Validate numCols
mustBeNonNegIntegerScalar(numCols);

% Validation
validateattributes(input,{class(input)},{'ncols',numCols});

end