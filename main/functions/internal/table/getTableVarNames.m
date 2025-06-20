function varNames = getTableVarNames(table)

    % Return all variable names of the table. (cell, 1 x numNames)
    varNames = table.Properties.VariableNames;

end