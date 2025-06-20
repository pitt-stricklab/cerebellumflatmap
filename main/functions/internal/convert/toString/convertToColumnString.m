function data = convertToColumnString(data)
%
% Convert data to a string column vector.
%
% <Input>
%   data: (XXX, M x N)
%       Acceptable classes for string().
%
% <Output>
%   data: (string, M x 1)

% Convert data to a row string array. (string, 1 x N)
data = convertToRowString(data);

% Convert to a column vector. (string, M x 1)
data = data'; % Transposed.

end