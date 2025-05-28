function appName = buildFormattedAppName(appName,appVersion)
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
%   1.0 - 20250508 Written by Mitsu
%   1.1 - 20250527 Fix the version number display method.

% Validate the input.
Validator.mustBeTextScalar(appName);
Validator.mustBeNumericScalar(appVersion);

if mod(appVersion,1) == 0
    formatVersion = "%.1f";
else
    formatVersion = "%g";
end

% Build a formatted application name string including the app version.
% (string, 1 x 1)
appName = sprintf( ...
    "%s (version "+formatVersion+")", ...
    appName, ...
    appVersion ...
);

end