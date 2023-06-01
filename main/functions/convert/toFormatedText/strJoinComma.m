function text = strJoinComma(text)
%
% Create a comma joined string.
%
% <Syntax>
%   FUN_NAME(INPUT1,INPUT2)
%   
% <Input>
%   text: (char, 1 x N) (cell of char, M x N) (string, M x N)
%       EXPLANATION_FOR_INPUT1.
%   INPUT2: (CLASS, HEIGHT x WIDTH)
%       EXPLANATION_FOR_INPUT2.
%   
% <Output>
%   text: (string, 1 x 1)
%       EXPLANATION_FOR_OUTPUT.
%   

% HISTORY:
%   1.0 - YYYYMMDD Mitsu Written
%   

% Create a comma joined text. (char, 1 x N) (string, 1 x 1)
text = strjoin(text,', ');

% NOTE:
% If the input text is a char row vector, returns as it was.

% Convert it to a string. (string, 1 x 1)
text = string(text);

end