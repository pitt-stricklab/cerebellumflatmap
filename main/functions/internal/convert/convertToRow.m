function data = convertToRow(data)
%
% Convert data to a row vector.
%
% <Syntax>
%   FUN_NAME(INPUT1,INPUT2)
%   
% <Input>
%   data: (CLASS, M x N)
%       EXPLANATION_FOR_INPUT1.
%   
% <Output>
%   data: (CLASS, 1 x N)
%       EXPLANATION_FOR_OUTPUT.
%   

% HISTORY:
%   1.0 - YYYYMMDD Written by Mitsu
%   

data = reshape(data,1,[]);

end