% Test CerebellumFlatmap class works properly.

% HISTORY:
%   1.0 - 20230518 Mitsu Written
%

clear;
% close all;

% A path of a 3D volume label image (ex .nii.gz).
labelVolumePath = "C:\Users\Mitsu\Desktop\testCerebellumFlatMap\data\v4 PF with bridge\cerebellum_annotation_centered_refinedDirectionRAI_PC_WM_Cortex_connected_v3.nii.gz";

% A path of a color lookup table file that is created by 3D Slicer (.ctbl).
colorTablePath = "C:\Users\Mitsu\Desktop\testCerebellumFlatMap\data\v4 PF with bridge\cerebellum_annotation_centered_refinedDirectionRAI_PC_WM_Cortex_connected.ctbl";

% Dimension number of sagittal planes.
dimNumSagittal = 1;

% Labels in the volume.
labelBackground  = 0;  % Background
labelIncision    = 46; % Incision lines
labelOrigin      = 45; % Origin lines
labelBridge      = 47; % Bridge lines between objects.
labelWhiteMatter = 44;

% Whether or not printing parsing results in the command window.
verbose = false;

% Labels to remove from the flatmap. Not specify this or specify [] to
% disable it.
labelsToRemove  = [ ...
    labelIncision, ...
    labelBridge, ...
    labelWhiteMatter, ...
];

% A scaling ratio for stretching the flatmap in the X direction.
aspectRatioX = 10; % Best practice: 10 for cortex, 1.5 for others

% Whether or not showing boundaries in animation.
animation = true;

% Plot size for mapped (target) points.
plotSizeTarget = 20;

% Names of colors for figures. (text scalar)
colorNameBoundary = "cyan";
colorNameConcave  = "blue";
colorNameConvex   = "red";
colorNameTarget   = "green";

% NOTE:
% See plot() for the valid color names.

%-------------------------------%

% Temp to make source points.

% % A path of a matlab file that stores coordinates of points within the
% % volume.
% pointPath = "C:\Users\Mitsu\Desktop\testCerebellumFlatMap\data\init_transformed_points.mat";

% % Load the xyz coordinates of points. (double, numPoints x XYZ)
% data = load(pointPath);
% xyzSource = data.whole_section_plotted;

lengY = 593;
lengX = 422;
lengZ = 364;

numSamples = 300;

xs = randperm(lengX,numSamples)';
ys = randperm(lengY,numSamples)';
zs = randperm(lengZ,numSamples)';

xyzSource = [xs,ys,zs];

%-------------------------------%

% Create a CerebellumFlatmap handle. (CerebellumFlatmap, 1 x 1)
hCerebellumFlatmap = CerebellumFlatmap( ...
    labelVolumePath, ...
    dimNumSagittal, ...
    labelBackground, ...
    labelIncision, ...
    labelOrigin, ...
    labelBridge ...
);

% Parse the volume data.
hCerebellumFlatmap.parse(verbose);

%-------------------------------%

% % Show boundaries on each sagittal slice.
% hCerebellumFlatmap.showBoundaries( ...
%     colorTablePath, ...
%     colorName = colorNameBoundary, ...
%     animation = animation ...
% );

%-------------------------------%

% Show a flatmap.
hFig1 = hCerebellumFlatmap.showFlatmap( ...
    colorTablePath, ...
    aspectRatioX = aspectRatioX, ...
    labelsToRemove = labelsToRemove ...
);

%-------------------------------%

% Show a curvature map.
hFig2 = hCerebellumFlatmap.showCurvaturemap( ...
    aspectRatioX = aspectRatioX, ...
    labelsToRemove = labelsToRemove, ...
    colorNameConcave = colorNameConcave, ...
    colorNameConvex = colorNameConvex ...
);

%-------------------------------%

% Get the xy coordinates of the source points on the flatmap.
xyTarget = hCerebellumFlatmap.mapPoints(xyzSource);

% Show the mapped (target) points on the flatmap.
hold on
scatter( ...
    xyTarget(:,1),xyTarget(:,2), ...
    plotSizeTarget, ...
    "filled", ...
    "MarkerFaceColor",colorNameTarget ...
);
hold off
