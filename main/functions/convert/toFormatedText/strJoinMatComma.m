function str = strJoinMatComma(mat,delimiter,newline)
%
% Create a comma joined string from numbers of a matrix.
%

arguments
    mat
    delimiter {} = ',';
    newline   {} = ';';
end

% NOTE:
% Example:
%
%   1 x N:
%       [0 1 2 3 4 5]  => '0,1,2,3,4,5'
%   M x N:
%       [0 1 2;3 4 5]  => '0,1,2;3,4,5'
%

%------------------%

str = strJoinMat(mat,delimiter,newline);

end