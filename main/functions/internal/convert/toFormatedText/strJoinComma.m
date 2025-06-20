function text = strJoinComma(text)
%
% Create a comma joined string.
%
% <Syntax>
%   FUN_NAME(INPUT1,INPUT2)
%   
% <Input>
%   text: (text, M x N)
%       EXPLANATION_FOR_INPUT1.
%   
% <Output>
%   text: (string, 1 x 1)
%       EXPLANATION_FOR_OUTPUT.
%   

% HISTORY:
%   1.0 - YYYYMMDD Written by Mitsu
%   1.2 - 20240116 Bug fix: When the input is a char row vector, strjoin()
%                  returned an error.

% Validate the input.
Validator.mustBeText(text);

% Convert it to a string. (string, M x M)
text = string(text);

% Create a comma joined text. (string, 1 x 1)
text = strjoin(text,', ');

end