function mustBePosInteger(input)
%
% Custom validator:
%   Throws exception if input is not;
%   a) numeric
%   b) integer
%   c) positive
%

validateattributes(input,{'numeric'},{'integer','positive'});

end