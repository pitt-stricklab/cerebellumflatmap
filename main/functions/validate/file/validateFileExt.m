function validateFileExt(paths,validExts)
%
% Validate file extensions in case-insensitive.
%
% <Input>
%   paths: (char) (cell of chars, M x N) (string, M x N)
%       File paths to be validated.
%   validExts: (char) (cell of chars, M x N) (string, M x N)
%       Valid file extensions with a dot. Ex. {'.jp2','.tif'}

% HISTORY:
%   1.0 - YYYYMMDD Mitsu Written
%   1.1 - 20210908 Changed mustBeText() to mustBeText_alt() to be
%                  compatible to MATLAB R2020a or older.

% Validate inputs.
mustBeText_alt(paths);

% NOTE:
% validExts is validated in hasValidFileExtension().

% Convert paths to a string row vector. (string, 1 x N)
paths = convertToRowString(paths);

% Validate each file extension. (logical, 1 x N)
tfIsValid = arrayfun(@(x)hasValidFileExtension(x,validExts),paths);

if ~all(tfIsValid)
    
    error(...
        "The following path doesn't have a valid file extension." + "\n" + ...
        "'%s'"                                                    + "\n" + ...
        "Valid file extension: %s"                                         ...
        ,strjoin(paths(~tfIsValid),"\n"),strJoinComma(validExts)...
    );

end

end