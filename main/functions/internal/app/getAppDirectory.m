function appDir = getAppDirectory(app)
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
%   1.0 - 20250626 Written by Mitsu
%

% Validate the input.
Validator.mustBeA(app,"matlab.apps.AppBase");

% Return directory where the application exists.
appDir = fileparts(which(class(app)));

end