function validatePathsExist(paths)
%
% Throws an error if any of file or folder paths don't exist.
%
% <Input>
%   paths: (text, M x N)
%       Full paths of files or folders to be checked.
%

% HISTORY:
%   1.0 - YYYYMMDD Mitsu Written
%   1.1 - 20210908 Changed mustBeText() to mustBeText_alt() to be
%                  compatible to MATLAB R2020a or older.
%   2.0 - 20230415 Don't need to specify 'file' or 'folder' and allow a
%                  mixed array of files and folders.

%------------------%

% Validate paths.
mustBeText(paths);

% Check if each file or folder path exists. (logical, M x N)
tf = isfile(paths) | isfolder(paths);

% Return if all paths exist.
if all(tf)
    return;
end

% Convert paths to a string array. (string, M x N)
paths = string(paths);

% Paths that don't exist (string, vector)
pathsNotExist = paths(~tf);

% Create a list of non existing paths. (string, vector)
pathsNotExistList = compose("'%s'",pathsNotExist);

% Throw an error.
error( ...
    "Couldn't find the following file(s) or folder(s).\n" + ...
    "%s", ...
    strjoin(pathsNotExistList,newline) ...
);

end