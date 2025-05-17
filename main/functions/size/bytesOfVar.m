% Returns data size of the variable on the workspace in the unit of bytes.
function bytes = bytesOfVar(var)

s = whos('var');
bytes = s.bytes;

end