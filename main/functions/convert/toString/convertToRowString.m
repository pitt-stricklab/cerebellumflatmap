function data = convertToRowString(data)
%
% Convert data to a string row vector.
%
% <Input>
%   data: acceptable classes for string(). (M x N)
%
% <Output>
%   data: (string, 1 x N)

% NOTE:
% This is mostly used to count the number of elements of an input that
% allows either of a char, a cell of char, and a string array. size() and
% numel() return the number of characters if it's a char vector.

% NOTE:
% In the case of empty inputs.
%                                                
% a) Inputs: empty char. Ex. '', char().
%    Output: "". (string, 1 x 1)
% b) Inputs: empty string. Ex. string([]).
%    Output: empty string. (string, 1 x 0)
% c) Inputs: empty cell. Ex. {}, cell(0), cell(M,0), cell(0,N).
%    Output: empty string. (string, 1 x 0)

% Convert data to a string array. (string, M x N)
data = string(data);

% Convert to a row vector. (string, 1 x N)
data = reshape(data,1,[]);

end