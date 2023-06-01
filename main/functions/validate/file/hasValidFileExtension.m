function tf = hasValidFileExtension(fileName,validExts)
%
% Check if file name has a valid file name comparing the extension string
% in case-insensitive.
%
% <Syntax>
%   FUN_NAME(INPUT1,INPUT2)
%   
% <Input>
%   fileName: (scalar text)
%       A file name that has file extension.
%   validExts: (char) (cell of char, M x N) (string, M x N)
%       Valid file extensions with a dot. Ex. {'.txt','.jpg'}
%   
% <Output>
%   OUTPUT: (CLASS, HEIGHT x WIDTH)
%       EXPLANATION_FOR_OUTPUT.
%

% HISTORY:
%   1.0 - YYYYMMDD Mitsu Written
%   1.1 - 20210908 Changed mustBeTextScalar() to mustBeTextScalar_alt() and
%                  mustBeText() to mustBeText_alt() to be compatible to
%                  MATLAB R2020a or older.

% Validate inputs.
mustBeTextScalar_alt(fileName);
mustBeText_alt(validExts);

% Get file extension of the file. (char) (string, 1 x 1)
[~,~,ext] = fileparts(fileName);

% Check if the file extension is one of valid extensions.
tf = any(strcmpi(ext,validExts));

end