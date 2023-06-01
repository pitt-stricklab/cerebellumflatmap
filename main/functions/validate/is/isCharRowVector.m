function tf = isCharRowVector(input)

% HISTORY:
%   1.0 - YYYYMMDD Mitsu Written
%

% Check if the input is a row vector of characters (char, 1 x N) like
% 'abcdef'.
tf = ischar(input) && isrow(input);

end