# CerebellumFlatmap
* main\CerebellumFlatmap.m
  
A class for creating a flatmap from the cerebellar volumetric data using the following method.
1. Extract the boundary pixels of the cerebellum from each sagittal slice. 
2. Cut open the boundary line at the pre-defined incision point.
3. Align the one-dimensional boundary line based on the pre-defined origin point with the boundary lines obtained from other sagittal slices.

# Preparation of label volume data
* The cerebellar region to be unfolded must have both an incision line and an origin line defined by arbitrary label IDs. 
* Upon viewing the sagittal slices of the cerebellum, if there are multiple separated parts, any part that does not contain both incision and origin labels on the boundary will be ignored and not included in the flatmap.
* If the parts you want to unfold are separated on the sagittal plane, you need to use an arbitrary label (e.g., Bridge) to connect them.

# Required Toolboxes and versions
* MATLAB (23.2)
* Image Processing Toolbox (23.2)

# Test script
* main\test_CerebellumFlatmap.m

# Example usage
## Create an instance of CerebellumFlatmap.

```matlab

% A single NIfTI image file path. Each voxel value must be a label ID
% (integer). Both NIfTI1 and NIfTI2 formats are supported. (text, 1 x 1)
labelVolumePath = "labelVolume.nii.gz";

% The dimension number corresponding to the direction perpendicular to the
% sagittal plane in the input NIfTI data. (integer, 1 x 1)
dimNumSagittal = 1;

% The label ID used for the incision point. (integer, 1 x 1)
labelIdIncision = 100;

% The label ID used for the origin point. (integer, 1 x 1)
labelIdOrigin = 101;

% Create a CerebellumFlatmap handle. (CerebellumFlatmap, 1 x 1)
hCerebellumFlatmap = CerebellumFlatmap( ...
    labelVolumePath, ...
    dimNumSagittal, ...
    labelIdIncision, ...
    labelIdOrigin ...
);

```

## Parse the volume data.

```matlab

% Whether or not printing parsing results in the command window.
% (logical, 1 x 1)
verbose = true;

% Parse all sagittal slices and extract boundary pixels on each sagittal
% slice.
hCerebellumFlatmap.parse(verbose);

```

## Show extracted boundaries on each sagittal slice.

```matlab

% A path of a color lookup table file created by 3D Slicer (.ctbl).
% (text, 1 x 1)
colorTablePath = "colorTable.ctbl";

% Color name for boundaries. (text, 1 x 1)
colorNameBoundary = "cyan";

% NOTE:
% See plot() for the valid color names.
% https://www.mathworks.com/help/matlab/ref/plot.html

% Whether or not showing boundaries in animation. (logical, 1 x 1)
showAnimation = true;

% Show boundaries on each sagittal slice.
hCerebellumFlatmap.showBoundaries( ...
    colorTablePath, ...
    colorNameBoundary = colorNameBoundary, ...
    showAnimation = showAnimation ...
);

```

https://github.com/user-attachments/assets/7879c0b8-8d27-4b5f-969f-a15475175261

## Create a label flatmap.

```matlab

% A scaling ratio for stretching the flatmap in the X direction. The value
% must be greater than or equal to 1.
aspectRatioX = 10;

% The label ID used for the bridge connecting objects. (integer, 1 x 1)
labelIdBridge = 102;

% The label ID used for white matter. (integer, 1 x 1)
labelIdWhiteMatter = 103;

% Label IDs to be removed from the final flatmap (replaced with the
% background label). To disable, either do not specify this option or
% specify []. (integer, M x N)
labelIdsToRemove = [ ...
    labelIdIncision, ...
    labelIdBridge, ...
    labelIdWhiteMatter, ...
];

% Create and show a label flatmap.
hFig1 = hCerebellumFlatmap.showLabelFlatmap( ...
    colorTablePath, ...
    aspectRatioX = aspectRatioX, ...
    labelIdsToRemove = labelIdsToRemove ...
);

```

![fig1](https://github.com/user-attachments/assets/385de5e7-dc39-4b7b-ac19-577f765d6160)


## Create a border flatmap.

```matlab

% Color name for borders. (text, 1 x 1)
colorNameBorder = "black";

% Create and show a border flatmap that only displays the borders between
% adjacent distinct labels.
hFig2 = hCerebellumFlatmap.showBorderFlatmap( ...
    aspectRatioX = aspectRatioX, ...
    labelsToRemove = labelIdsToRemove, ...
    colorNameBorder = colorNameBorder ...
);

```

![fig2](https://github.com/user-attachments/assets/6bd2dca2-5c73-4059-bd3e-94c5635426a2)


## Create a curvature flatmap.

```matlab

% Color name for concave or convex areas. (text, 1 x 1)
colorNameConcave = "blue";
colorNameConvex  = "red";

% Create and show a flatmap that displays the curvature of the boundaries
% in the volumetric data.
hFig3 = hCerebellumFlatmap.showCurvatureFlatmap( ...
    aspectRatioX = aspectRatioX, ...
    labelsToRemove = labelIdsToRemove, ...
    colorNameConcave = colorNameConcave, ...
    colorNameConvex = colorNameConvex ...
);

```

![fig3](https://github.com/user-attachments/assets/4e05441b-fa7b-4555-8070-1ecc606457f5)


## Create an intensity flatmap.

```matlab

% A path of 3D volumetric data containing the intensity values for each
% voxel in the label volume data. Both NIfTI1 and NIfTI2 formats are
% supported.(text, 1 x 1)
intensityVolumePath = "intensityVolume.nii.gz";

% The minimum and maximum intensity values within the intensity volume data
% (used to optimize the colormap). (numeric, 1 x 1)
intensityMin = -6;
intensityMax = 13;

% Create and show a flatmap that displays the intensity along the
% boundaries of the volumetric data.
hFig4 = hCerebellumFlatmap.showIntensityFlatmap( ...
    intensityVolumePath, ...
    aspectRatioX = aspectRatioX, ...
    labelsToRemove = labelIdsToRemove ...
);

% Apply a predefined colormap.
colormap(hFig4,"jet");

% Adjust the colormap limits.
clim([intensityMin,intensityMax]);

% Show a color bar.
colorbar;

```

![fig4](https://github.com/user-attachments/assets/b2524815-4179-4dad-8710-552fff3bfebc)


## Create a coordinate flatmap.

```matlab

% Create a flatmap that stores the coordinates of each point on its
% sagittal slice. (uint8, M x N x RC)
coordinateFlatmap = hCerebellumFlatmap.getCoordinateFlatmap( ...
    aspectRatioX = aspectRatioX, ...
    labelsToRemove = labelIdsToRemove ...
);

% NOTE:
% The first channel contains row coordinates and the second channel
% contains column coordinates on the sagittal slice.

```

## (Optional) Create a point cloud within the label volume data for testing. 

```matlab

% Size of the label volume data.
lenY = 593;
lenX = 422;
lenZ = 364;

% Number of test points.
numPoints = 350;

% Randomly select coordinates. (double, numPoints x 1)
xs = randperm(lenX,numPoints)';
ys = randperm(lenY,numPoints)';
zs = randperm(lenZ,numPoints)';

% Create a point cloud within the label volume data.
% (double, numPoints x XYZ)
xyzSource = [xs,ys,zs];

```

## Map a point cloud in the volumetric data onto the flatmap.

```matlab

% Get the coordinates (n, m) of the mapped (target) points on the flatmap.
% (double, numTargetPoints x NM)
nmTarget = hCerebellumFlatmap.mapPoints(xyzSource);

% NOTE:
% N represents the horizontal axis value on the flatmap (index of the 
% sagittal slice), and M represents the vertical axis.

% Plot size for the mapped points.
plotSizeTarget = 20;

% Color name for the mapped points. (text, 1 x 1)
colorNameTarget = "red";

% Get the Axes handle of the figure.
figure(hFig1);
hAxes = gca;

% Show the mapped points on the flatmap.
hold on
scatter( ...
    hAxes, ...
    nmTarget(:,1),nmTarget(:,2), ...
    plotSizeTarget, ...
    "filled", ...
    "MarkerFaceColor",colorNameTarget ...
);
hold off

```

![fig5](https://github.com/user-attachments/assets/05903ea4-fc69-4959-98cd-217f91445cd3)
