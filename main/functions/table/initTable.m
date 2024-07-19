function outTable = initTable(variableNames,height,variableTypes)
%
% Make a new empty table that has specified variables
%
% <Input>
%   variableNames: (text, vector)
%       Column names for the new table.
%   height: (nonnegative integer, 1 x 1)
%       Height for the new table.
% OPTION
%   variableTypes: (text, vector)
%       Variable type for each column. If one type is specified, the type 
%       is used for all columns. Default to cell for all.
%

% HISTORY:
%   1.0 - YYYYMMDD Written by Mitsu
%   1.1 - 20210128 Allow several types of variable type for each column.
%                  Allow char variable name input.

arguments
    variableNames {mustBeTextVector}
    height        {mustBeNonNegIntegerScalar}
    variableTypes {} = []
end

% Validate variableTypes.
if ~isempty(variableTypes)
    mustBeTextVector(variableTypes);
end

% Convert variable names and types to string. (string, 1 x N)
variableNames = convertToRowString(variableNames);
variableTypes = convertToRowString(variableTypes);

% NOTE:
% When variableTypes is empty [], it will be 1x0 empty string array.

% Number of variable names (Table width)
width = numel(variableNames);

% Set variable types for each variable. (string, 1 x width)
variableTypes = createVariableTypesForAll(variableTypes,width);

% Create a table
outTable = table(...
    'Size'         ,[height,width],...
    'VariableNames',variableNames,...
    'VariableTypes',variableTypes...
);
      
end

function variableTypes = createVariableTypesForAll(variableTypes,width)

% Number of variable types.
numTypes = numel(variableTypes);

switch numTypes

    case 0

        % Default to cell.
        variableTypes = repmat("cell",1,width);

    case 1

        % Copy the type to all
        variableTypes = repmat(variableTypes,1,width);


    case width

        % Use the type as it is.

    otherwise

        error(...
            "The number of variable type have to be one or match to the " + ...
            "number of variable names."...
        );

end

end