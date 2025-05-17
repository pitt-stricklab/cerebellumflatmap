function tf = isNgr(ngrPath)
%
% Determine if a file is an ngr file. If the header is the ngr format,
% consider it is an ngr file.

try
    
    % Read the header
    readNgrHeader(ngrPath);
    
    tf = true;
    
catch

    tf = false;
    
end

end