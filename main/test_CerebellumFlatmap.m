% Test CerebellumFlatmap class works properly.

% HISTORY:
%   1.0 - 20230518 Written by Mitsu 
%

clear;
close all;

% A path of a 3D volume label data (ex .nii.gz).
labelVolumePath = ...
    "C:\Users\Mitsu\Desktop\testCerebellumFlatMap\data\v5\cerebellum_annotation_centered_refinedDirectionRAI_PC_WM_Cortex_connected_v7_MRIspace.nii.gz";

% A path of a color lookup table file that is created by 3D Slicer (.ctbl).
colorTablePath = ...
    "C:\Users\Mitsu\Desktop\testCerebellumFlatMap\data\v5\cerebellum_annotation_centered_refinedDirectionRAI_PC_WM_Cortex_connected_redist_overwriting_laterals_wm_added.ctbl";

% A path of a 3D volume intensity data aligned with the label volume data
% (ex .nii.gz). 
intensityVolumePath = ...
    "C:\Users\Mitsu\Desktop\testCerebellumFlatMap\data\group_30_28_25_Z_40um_masked_cropped_RAI.nii";

% Minimum and maximum intensities (for colormap).
intensityMin = -6;
intensityMax = 13;

% Dimension number of sagittal planes.
dimNumSagittal = 1;

% Label IDs in the volume.
labelIdIncision    = 46; % Incision lines
labelIdOrigin      = 45; % Origin lines
labelIdBridge      = 47; % Bridge lines between objects.
labelIdWhiteMatter = 44;

% Whether or not printing parsing results in the command window.
verbose = false;

% Label IDs to remove from the flatmap. To disable, either do not specify 
% this option or specify [].
labelIdsToRemove = [ ...
    labelIdIncision, ...
    labelIdBridge, ...
    labelIdWhiteMatter, ...
];

% A scaling ratio for stretching the flatmap in the X direction.
aspectRatioX = 10; % Best practice: 10 for cortex, 1.5 for others

% Whether or not showing boundaries in animation.
showAnimation = true;

% Plot size for mapped (target) points.
plotSizeTarget = 20;

% Names of colors for figures. (text, 1 x 1)
colorNameBoundary = "cyan";
colorNameBorder   = "black";
colorNameConcave  = "blue";
colorNameConvex   = "red";
colorNameTarget   = "red";

% NOTE:
% See plot() for the valid color names.

%-------------------------------%

% Create a CerebellumFlatmap handle. (CerebellumFlatmap, 1 x 1)
hCerebellumFlatmap = CerebellumFlatmap( ...
    labelVolumePath, ...
    dimNumSagittal, ...
    labelIdIncision, ...
    labelIdOrigin ...
);

% Parse the label volume data.
hCerebellumFlatmap.parse(verbose);

%-------------------------------%

% Show boundaries on each sagittal slice.
hCerebellumFlatmap.showBoundaries( ...
    colorTablePath, ...
    colorNameBoundary = colorNameBoundary, ...
    showAnimation = showAnimation ...
);

%-------------------------------%

% Show a label flatmap.
hFig1 = hCerebellumFlatmap.showLabelFlatmap( ...
    colorTablePath, ...
    aspectRatioX = aspectRatioX, ...
    labelIdsToRemove = labelIdsToRemove ...
);

%-------------------------------%

% Show a border flatmap.
hFig2 = hCerebellumFlatmap.showBorderFlatmap( ...
    aspectRatioX = aspectRatioX, ...
    labelsToRemove = labelIdsToRemove, ...
    colorNameBorder = colorNameBorder ...
);

%-------------------------------%

% Show a curvature flatmap.
hFig3 = hCerebellumFlatmap.showCurvatureFlatmap( ...
    aspectRatioX = aspectRatioX, ...
    labelsToRemove = labelIdsToRemove, ...
    colorNameConcave = colorNameConcave, ...
    colorNameConvex = colorNameConvex ...
);

%-------------------------------%

% Show an intensity flatmap.
hFig4 = hCerebellumFlatmap.showIntensityFlatmap( ...
    intensityVolumePath, ...
    aspectRatioX = aspectRatioX, ...
    labelsToRemove = labelIdsToRemove ...
);

% Use a predefined colormap.
colormap(hFig4,"jet");

% Adjust the colormap limits.
clim([intensityMin,intensityMax]);

% Show a color bar.
colorbar;

%-------------------------------%

% Get a coordinate flatmap. (uint8, M x N x RC)
coordinateFlatmap = hCerebellumFlatmap.getCoordinateFlatmap( ...
    aspectRatioX = aspectRatioX, ...
    labelsToRemove = labelIdsToRemove ...
);

% NOTE:
% The first channel contains row coordinates and the second channel
% contains column coordinates on the sagittal slice.

%-------------------------------%

% Create a point cloud within the label volume data for testing.

lenY = 593;
lenX = 422;
lenZ = 364;

numPoints = 350;

xs = randperm(lenX,numPoints)';
ys = randperm(lenY,numPoints)';
zs = randperm(lenZ,numPoints)';

xyzSource = [xs,ys,zs]; % (double, numPoints x XYZ)

% Get the coordinates (n, m) of the mapped points on the flatmap.
% (double, numTargetPoints x NM)
nmTarget = hCerebellumFlatmap.mapPoints(xyzSource);

% NOTE:
% N represents the horizontal axis value on the flat map (index of the 
% sagittal slice), and M represents the vertical axis.

% Get the Axes handle of the figure.
figure(hFig1);
hAxes = gca;

% Show the mapped (target) points on the flatmap.
hold on
scatter( ...
    hAxes, ...
    nmTarget(:,1),nmTarget(:,2), ...
    plotSizeTarget, ...
    "filled", ...
    "MarkerFaceColor",colorNameTarget ...
);
hold off