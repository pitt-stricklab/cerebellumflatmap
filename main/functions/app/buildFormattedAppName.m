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
%

% Validate the input.
Validator.mustBeTextScalar(appName);
Validator.mustBeNumericScalar(appVersion);

% Build a formatted application name string including the app version.
% (string, 1 x 1)
appName = sprintf( ...
    "%s (version %s)", ...
    appName, ...
    num2str(appVersion,"%.2f") ...
);

end