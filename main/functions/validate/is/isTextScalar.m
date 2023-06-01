function tf = isTextScalar(input)
%
% Check if input is a scalar text, a char row vector or string scalar.
%
% <Syntax>
%   FUN_NAME(INPUT1,INPUT2)
%   
% <Input>
%   INPUT1: (CLASS, HEIGHT x WIDTH)
%       EXPLANATION_FOR_INPUT1.
%   INPUT2: (CLASS, HEIGHT x WIDTH)
%       EXPLANATION_FOR_INPUT2.
%   
% <Output>
%   OUTPUT: (CLASS, HEIGHT x WIDTH)
%       EXPLANATION_FOR_OUTPUT.
%

% NOTE:
% '', "", and missing string are also scalar text. See mustBeTextScalar().

% HISTORY:
%   1.0 - YYYYMMDD Mitsu Written
%   2.0 - 20210908 Bug fix.
%   2.1 - 20230223 Use isCharRowVector instead of ischar.

tf = isCharRowVector(input) || strcmp(input,'') || ...
     (isstring(input) && numel(input) == 1);

end