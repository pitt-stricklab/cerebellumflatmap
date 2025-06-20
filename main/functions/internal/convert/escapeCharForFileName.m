function text = escapeCharForFileName(text)
%
% SUMMARY_OF_THIS_FUNCTION.
%
% <Syntax>
%   FUN_NAME(INPUT1,INPUT2)
%   
% <Input>
%   INPUT1: (CLASS, HEIGHT x WIDTH)
%       EXPLANATION_FOR_INPUT1.
%   INPUT2: (CLASS, HEIGHT x WIDTH)
%       EXPLANATION_FOR_INPUT2.
%   
% <Output>
%   OUTPUT: (CLASS, HEIGHT x WIDTH)
%       EXPLANATION_FOR_OUTPUT.
%   

% HISTORY:
%   1.0 - 20221303 Written by Mitsu
%   

% Escape forbidden characters as a directory name in the text to '_'.
text = regexprep(text,'[\\/:*?"<>|]','_');

% Forbidden characters:
% '\', '/', ':', '*', '?', '"', '<', '>', '|'

end