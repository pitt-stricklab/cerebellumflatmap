function data = convertToColumn(data)
%
% Convert data to a column vector.
%
% <Syntax>
%   FUN_NAME(INPUT1,INPUT2)
%   
% <Input>
%   data: (CLASS, M x N)
%       EXPLANATION_FOR_INPUT1.
%   
% <Output>
%   data: (CLASS, M x 1)
%       EXPLANATION_FOR_OUTPUT.
%   

% HISTORY:
%   1.0 - YYYYMMDD Written by Mitsu
%   

data = reshape(data,[],1);

end