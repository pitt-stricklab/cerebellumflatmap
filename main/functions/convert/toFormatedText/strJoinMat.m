function str = strJoinMat(mat,delimiter,newline,prefix,suffix)
%
% Create a string from numbers of a matrix.
%
% <Input>
% mat: (double, M x N)
% delimiter: (char)
%   Delimiter to put between numbers.
% newlineStr: (char)
%   String to put between rows.
% prefix: (char) option
%   Prefix for each number. Default to ''. If suffix is specified, prefix
%   is required.
% suffix: (char) option
%   Suffix for each number. Default to ''.
%
% <Output>
% str: (char)
%   A string from numbers of the input matrix.
%

% NOTE:
% Example:
%   delimiter  = ', '
%   newlineStr = '; '
%   prefix     = '#'
%   suffix     = '&'
%
%   1 x N:
%       [0 1 2 3 4 5]  => '#0&, #1&, #2&, #3&, #4&, #5&'
%   M x N:
%       [0 1 2;3 4 5]  => '#0&, #1&, #2&; #3&, #4&, #5&'
%

arguments
    mat       {mustBeA(mat,'double')}
    delimiter {mustBeTextScalar}
    newline   {mustBeTextScalar}
    prefix    {mustBeTextScalar} = '' % Optional
    suffix    {mustBeTextScalar} = '' % Optional
end

% Covert input texts to char if it's scalar string.
[delimiter,newline,prefix,suffix] = ....
    convertStringsToChars(delimiter,newline,prefix,suffix);

% Number of rows
numRows = size(mat,1);

% Initialize a cell (cell, 1 x N)
rowStr = cell(1,numRows);

for r=1:numRows
    
    % Row data (double, 1 x N)
    row = mat(r,:);
    
    % Concatenate each number strings and store in the cell.
    rowStr{r} = [...
        prefix ...
        strjoin(...
            cellfun(...
                @num2str,(num2cell(row)),...
                'UniformOutput',false),...
            [suffix delimiter prefix]...
        ) ...
        suffix...
    ];
    
end

str = strjoin(rowStr,newline);

end