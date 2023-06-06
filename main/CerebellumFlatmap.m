classdef CerebellumFlatmap < handle
    %
    % Create a flat map of cerebellum that maps brain surface on each 
    % sagittal slice onto a one-dimensional representation.
    %

    % HISTORY: testCreateBrainFlatMap.m
    %   1.0 - 20230427 Mitsu Written.

    % HISTORY:
    %   1.0 - 20230518 Mitsu Written. Moved functions from
    %                  testCreateBrainFlatMap.m
    %   2.0 - 20230601 a) Major updates and improvements. 
    %                  b) Added showBoundaries() and showCurvaturemap().
    %                  c) Modified the figure appearance.
    %   2.1 - 20230606 Added mapPoints().
    
    properties (Access = private)

        % Volume data of labels.
        pLabelVolume

        % Size of the volume data.
        pLengY
        pLengX
        pLengZ

        % A cell to store boundary pixels on each sagittal slice.
        pBoundaryDataCell

        % Number of saggital slices.
        pNumSagittalSlices

        % Dimension number of sagittal planes.
        pDimNumSagittal

        % Labels in the volume.
        pLabelBackground % Background
        pLabelIncision   % Incision lines
        pLabelOrigin     % Origin lines
        pLabelBridge     % Bridge lines between objects. 

        % Index of the first valid slice.
        pIndexValidSliceStart

        % Number of slices that have a valid object.
        pNumValidSlices = 0;        

        % Size of the flatmap.
        pFlatmapHeightTop    = 0;
        pFlatmapHeightBottom = 0;

        % Valid file extensions.
        pValidExtColorTable = ".ctbl";

        % Default figure size.
        pFigureSizeDefault = 1000;

        % Initial radius of shpere to find nearest boundary pixel.
        pRadiusInit = 10;

        % How much to increase the sphere radius while finding the nearest
        % pixel.
        pRadiusDelta = 5;

        % A table that stores coordinates of voxels inside spheres of
        % variety of radius.
        pCoordInUnitSphereTable
        
    end

    methods (Access = public)
        
        % Constructor.
        
        function obj = CerebellumFlatmap( ...
                labelVolumePath, ...
                dimNumSagittal, ...
                labelBackground, ...
                labelIncision, ...
                labelOrigin, ...
                labelBridge ...
            )
            %
            % <Input>
            %   INPUT1: (CLASS, HEIGHT x WIDTH)
            %       EXPLANATION_FOR_INPUT1.
            %   INPUT2: (CLASS, HEIGHT x WIDTH)
            %       EXPLANATION_FOR_INPUT2.
            %

            arguments
                labelVolumePath {mustBeTextScalar}
                dimNumSagittal  {mustBePosIntegerScalar,mustBeLessThanOrEqual(dimNumSagittal,3)}
                labelBackground {mustBeIntegerScalar}
                labelIncision   {mustBeIntegerScalar}
                labelOrigin     {mustBeIntegerScalar}
                labelBridge     {mustBeIntegerScalar}
            end

            % Validate the file exists.
            validatePathsExist(labelVolumePath);
            
            % Load and store the 3D volume label image.
            % (numeric, Y x X x Z)
            obj.pLabelVolume = niftiread(labelVolumePath);

            % Store the size of the volume.
            [obj.pLengY,obj.pLengX,obj.pLengZ] = size(obj.pLabelVolume);

            % Store the inputs.
            obj.pDimNumSagittal  = dimNumSagittal;
            obj.pLabelBackground = labelBackground;
            obj.pLabelIncision   = labelIncision;
            obj.pLabelOrigin     = labelOrigin;
            obj.pLabelBridge     = labelBridge;

        end

        function parse(obj,verbose)
            %
            % Parse all sagittal slices and extract boundary data on each
            % slice.
            %
            % <Input>
            % OPTIONS
            %   verbose: (logical, 1 x 1)
            %       Whether or not printing parsing results in the command
            %       window.

            arguments
                obj
                verbose {mustBeLogicalScalar} = true;
            end

            % Get the number of sagittal slices.
            obj.pNumSagittalSlices = size(obj.pLabelVolume,obj.pDimNumSagittal);
            
            % Initialize a cell to store coordinates of boundary pixels and
            % their labels on each sagittal slice.
            % (cell, numSagittalSlices x 1)
            obj.pBoundaryDataCell = cell(obj.pNumSagittalSlices,1);

            if verbose
                fprintf("* Parsing all sagittal slices in the label volume data ...\n");
            end

            for i = 1:obj.pNumSagittalSlices

                if verbose
                    fprintf("\n  Slice #%d:\n",i);
                end

                % Get the coordinates of boundary pixels that surrounds a 
                % label area in the sagittal slice, and the labels of each
                % boundary pixel. 
                [boundary,labels] = obj.getBoundaryPixels(i,verbose);

                % NOTE:
                % boundary: (double, numBoundaryPixels x MN) or []
                % labels:   (double, numBoundaryPixels x 1) or []

                % Number of boundary pixels.
                numBoundaryPixels = size(boundary,1);

                if numBoundaryPixels == 0
                    continue;
                end

                % Store the index of the first valid slice.
                if isempty(obj.pIndexValidSliceStart)
                    obj.pIndexValidSliceStart = i;
                end

                % Count up the number of valid slices.
                obj.pNumValidSlices = obj.pNumValidSlices + 1;

                % Sort the boundary pixels using the incision point.
                [boundary,labels] = obj.sortBoundaryPixels(boundary,labels);

                % Find pixels that have the label of origin point.
                % (logical, numBoundaryPixels x 1)
                isOriginPoint = labels == obj.pLabelOrigin;
    
                % Get the index where the origin label appears first.
                % (double, 1 x 1)
                idxOriginPoint = find(isOriginPoint,1,'first');

                % Create indices of each boundary pixel on the flatmap
                % where an index of the pixel at the origin is 0, pixels 
                % before it are negative, pixels after it are positive.
                % (double, numBoundaryPixels x 1)
                indicesOnFlatmap = (1:numBoundaryPixels)'-idxOriginPoint; % Transposed

                % Store the height of the flatmap.
                obj.storeFlatmapHeight(indicesOnFlatmap);

                % Store the boundary data in the cell.
                % (double, numBoundaryPixels x 4)
                obj.pBoundaryDataCell{i} = [boundary,labels,indicesOnFlatmap];
            
            end

        end

        function showBoundaries(obj,colorTablePath,options)
            %
            % Show boundaries on each sagittal slice.
            %
            % <Input>
            %   colorTablePath: (text scalar)
            %       See showFlatmap().
            % OPTIONS
            %   colorName: (text scalar)
            %       A boundary color name. See plot() for the valid color
            %       names.
            %   animation: (logical, 1 x 1)
            %       Whether or not showing boundaries in animation.
            %

            arguments
                obj
                colorTablePath
                options.colorName {mustBeTextScalar}    = "cyan"
                options.animation {mustBeLogicalScalar} = false
            end

            colorName = options.colorName;
            animation = options.animation;

            % Validate the parsing of the volume data is done.
            obj.validateParsingDone();

            % Validate the color lookup table file path.
            obj.validateColorTablePath(colorTablePath);

            % Create a MatlabColor handle.
            hMatlabColor = MatlabColor();

            % Validate the color name. (string, 1 x 1)
            colorName = hMatlabColor.validateColorNames(colorName);

            % Read the color map. (uint8, numColors+1 x RGB)
            [colorMap,~] = obj.readColorMap(colorTablePath);

            % Create a figure.
            figure;
            hAxes = gca;

            if ~animation
                fprintf( ...
                    "Press any key to show the next slice.\n" + ...
                    "Press Ctrl+C to quit.\n" ...
                );
            end

            for i = 1:obj.pNumSagittalSlices

                % Get a sagittal slice of the index. (numeric, M x N)
                sagittalSlice = obj.getSagittalSlice(i);

                % Convert the slice to uint8. (uint8, M x N)
                sagittalSlice = uint8(sagittalSlice);

                % Get the current x and y limit. (double, 1 x 2)
                if i ~= 1
                    xLim = hAxes.XLim;
                    yLim = hAxes.YLim;
                end

                % Show the slice.
                imshow(sagittalSlice,colorMap,'Parent',hAxes);
                title(sprintf("Slice #%d",i));                

                % Restore the x and y limit.
                if i ~= 1
                    hAxes.XLim = xLim;
                    hAxes.YLim = yLim;
                end

                % Get the coordinates of boundary pixels of an object on
                % the sagittal slice. (double, numBoundaryPixels x MN)
                boundary = obj.getBoundary(i);

                if ~isempty(boundary)
    
                    % Show the boundary.
                    hold on
                    plot(hAxes, ...
                        boundary(:,2),boundary(:,1), ...
                        'LineWidth',2, ...
                        'Color',colorName ...
                    );                
                    hold off

                end

                if animation                    
                    pause(0.1); % Wait for a moment.
                else                    
                    pause;      % Wait until user press any key.
                end                    

            end

        end

        function hFig = showFlatmap(obj,colorTablePath,options)
            %
            % Create and show a flatmap.
            %
            % <Input>
            %   colorTablePath: (text scalar)
            %       A path of a color lookup table file for the labels in 
            %       the valume data that is created by 3D Slicer. Valid 
            %       file extension is ".ctbl".
            % OPTIONS
            %   aspectRatioX: (numeric, 1 x 1)
            %       A scaling ratio for stretching the flatmap in the X 
            %       direction. The value must be greater than or equal to
            %       1.
            %   labelsToRemove: (numeric, M x N)
            %       Label(s) to be removed from the final flatmap. The 
            %       value(s) must be positive integers.
            %
            % <Output>
            %   hFig: (matlab.ui.Figure, 1 x 1)
            %       A figure handle of the flatmap.
            %

            arguments
                obj {}
                colorTablePath         {}
                options.aspectRatioX   {} = 1
                options.labelsToRemove {} = []
            end

            aspectRatioX   = options.aspectRatioX;
            labelsToRemove = options.labelsToRemove;

            % Validate the parsing of the volume data is done.
            obj.validateParsingDone();

            % Validate the color lookup table file path.
            obj.validateColorTablePath(colorTablePath);

            % Validate the aspect ratio for the x axis.
            mustBeNumericScalar(aspectRatioX)
            mustBeGreaterThanOrEqual(aspectRatioX,1);

            % Validate the labels to be removed.
            if ~isempty(labelsToRemove)
                mustBePosInteger(labelsToRemove);
            end

            % Read the color map.
            % (uint8, numColors+1 x RGB), (string, numColors+1 x 1)
            [colorMap,colorLabels] = obj.readColorMap(colorTablePath);

            % Create a flatmap. (uint8, M x N)
            flatmap = obj.createFlatmap(labelsToRemove,false);            
            
            % Show the flatmap.
            hFig = obj.createFigure( ...
                flatmap, ...
                colorMap, ...
                colorLabels, ...
                aspectRatioX ...
            );
            
        end        

        function hFig = showCurvaturemap(obj,options)
            %
            % Create and show a curvature map.
            %
            % <Input>
            % OPTIONS
            %   aspectRatioX: (numeric, 1 x 1)
            %       See showFlatmap().
            %   labelsToRemove: (numeric, M x N)
            %       See showFlatmap().
            %   colorNameConcave, colorNameConvex: (text scalar)
            %       Color names for boundary points that have a negative 
            %       and positive curvature, respectively. See plot() for 
            %       the valid color names.
            %
            % <Output>
            %   hFig: (matlab.ui.Figure, 1 x 1)
            %       A figure handle of the flatmap.
            %

            arguments
                obj {}
                options.aspectRatioX     {} = 1
                options.labelsToRemove   {} = []
                options.colorNameConcave {} = "blue"
                options.colorNameConvex  {} = "red"              
            end

            aspectRatioX     = options.aspectRatioX;
            labelsToRemove   = options.labelsToRemove;
            colorNameConcave = options.colorNameConcave;
            colorNameConvex  = options.colorNameConvex;

            % Validate the parsing of the volume data is done.
            obj.validateParsingDone();

            % Create a color map and color labels for a cuvature map.
            % (uint8, 3+1 x RGB), (string, 3+1 x 1)
            [colorMap,colorLabels] = createColorMapForCurvature(obj, ...
                colorNameConcave, ...
                colorNameConvex ...
            );

            % Create a curvature map. (uint8, M x N)
            curvaturemap = obj.createFlatmap(labelsToRemove,true);  

            % Show the curvature map.
            hFig = obj.createFigure( ...
                curvaturemap, ...
                colorMap, ...
                colorLabels, ...
                aspectRatioX ...
            );

        end

        function xyTarget = mapPoints(obj,xyzSource)
            %
            % Map the specified points in the cerebellum to the flatmap.
            %
            % <Input>
            %   xyzSource: (numeric, numPoints x XYZ)
            %       xyz coordiantes of source points to be mapped on a
            %       flatmap. The value must be greater than or equal to
            %       0.5. Points that doesn't exist within the brain region,
            %       which is used to create the flatmap, will be skipped.
            %
            % <Output>
            %   xyTarget: (double, numTargetPoints x xy)
            %       xy coordinates of the mapped (target) points on the
            %       flatmap.

            % Validate the parsing of the volume data is done.
            obj.validateParsingDone();

            % Validate the coordinates of the source points and convert
            % them to pixel indices. (numeric, XYZ)
            xyzSourceIdx = obj.validateSourcePoints(xyzSource);

            % Create a mask of the extracted boundaries. (logical, Y x X x Z)
            [boundaryMask,regionMask] = obj.createBoundaryMask();

            % Number of source points.
            numPointsSource = size(xyzSourceIdx,1);

            % Initialize a cell to store the indices of mapped points on
            % the flatmap. (cell, numPointsSource x 1) 
            indicesOnFlatmapCell = cell(numPointsSource,1);

            for i = 1:numPointsSource

                xSource = xyzSourceIdx(i,1);
                ySource = xyzSourceIdx(i,2);
                zSource = xyzSourceIdx(i,3);

                % Skip if the point does not exist within the cerebellum.
                if ~regionMask(ySource,xSource,zSource)
                    fprintf( ...
                        "Point #%d (%s) was skipped as it does not exist " + ...
                        "within the cerebellum.\n", ...
                        i,strJoinMatComma(xyzSource(i,:)) ...
                    );
                    continue;
                end

                % Find the coordinate of the nearest boundary voxel to the
                % source point.
                [yNear,xNear,zNear] = obj.findNearestBoundaryVoxel( ...
                    boundaryMask, ...
                    xSource,ySource,zSource ...
                );              

                % Convert the index in 3D volume into an index on a 2D 
                % slice based on the sagittal dimension number.
                switch obj.pDimNumSagittal
                    case 1; sliceIndex = yNear; mIndex = xNear; nIndex = zNear;
                    case 2; sliceIndex = xNear; mIndex = yNear; nIndex = zNear;
                    case 3; sliceIndex = zNear; mIndex = yNear; nIndex = xNear;
                end

                % Get the coordinates of boundary pixels of an object on
                % the sagittal slice. (double, numBoundaryPixels x MN)
                boundary = obj.getBoundary(sliceIndex);

                % Get the index of the nearest boundary pixel on the slice.
                % (logical, numBoundaryPixels x 1)
                idx = boundary(:,1) == mIndex & boundary(:,2) == nIndex;

                % Get indices of boundary pixels on the flatmap.
                indicesOnFlatmap = obj.getIndicesOnFlatmap(sliceIndex);

                % Get the index of the nearest boundary pixel on the
                % flatmap.
                indexOnFlatmap = indicesOnFlatmap(idx);

                % Convert the index of the nearest boundary pixel and slice
                % index to xy coordinates on the flatmap.
                [x,y] = obj.covertIndexToCoordOnFlatmap(indexOnFlatmap,sliceIndex);

                % Store the coordinate in the cell. (double, 1 x xy)
                indicesOnFlatmapCell{i} = [x,y];
            
            end

            % Return the xy coordinates of mapped (target) points on the 
            % flatmap. (double, numTargetPoints x xy)
            xyTarget = vertcat(indicesOnFlatmapCell{:});

        end        

    end

    methods (Access = private)
        
        % Parsing boundary data.

        function [boundary,labels] = getBoundaryPixels(obj,sagittalIndex,verbose)
            %
            % Return the coordinates of boundary pixels of a label area in 
            % the sagittal slice that have incision and origin points, and 
            % the labels of each boundary pixel.
            %
            % <Output>
            %   boundary: (double, numBoundaryPixels x MN) or []
            %       Coordinates of boundary pixels on the sagittal slice.
            %   labels: (double, numBoundaryPixels x 1) or []
            %       Labels of each boundary pixel.

            % Initialize the outputs.
            boundary = [];
            labels   = [];

            % Get a sagittal slice of the index. (numeric, M x N)
            sagittalSlice = obj.getSagittalSlice(sagittalIndex);

            % Get a binary image of label areas (non-background area).
            % (logical, M x N)
            binImage = sagittalSlice ~= obj.pLabelBackground;

            % Return [] if there is no label area.
            if sum(binImage) == 0
                
                if verbose
                    fprintf("    No object found.\n");
                end

                return;
            end

            % Fill holes within the label areas.
            binImage = imfill(binImage,'holes');

            % Find and count connected components. (struct, 1 x 1)
            components = bwconncomp(binImage);
        
            % Number of objects found.
            numObjects = components.NumObjects;

            if verbose
                fprintf("    %d object(s) found.\n",numObjects);
            end

            pixelIdxListTarget = [];

            for i = 1:numObjects

                if verbose
                    fprintf("    Object #%d: ",i);
                end

                % Linear indices of pixel of the object.
                % (double, numPixels x 1)
                pixelIdxList = components.PixelIdxList{i};
        
                % Get the labels of the object. (numeric, numPixels x 1)
                labelsObject = sagittalSlice(pixelIdxList);

                % Find pixels that have the label of incision and origin 
                % lines. (logical, numPixels x 1)
                isIncisionPoint = labelsObject == obj.pLabelIncision;
                isOriginPoint   = labelsObject == obj.pLabelOrigin;

                if sum(isIncisionPoint) == 0 || sum(isOriginPoint) == 0
                    obj.printObjectSkipped(labelsObject,verbose);
                    continue;
                end

                if ~isempty(pixelIdxListTarget)
                    error("There are multiple objects that have incision and origin point.");
                end

                pixelIdxListTarget = pixelIdxList;

                if verbose
                    fprintf("Valid to extract boundary data.\n");
                end
        
            end

            if isempty(pixelIdxListTarget)
                obj.printSliceSkipped(verbose);
                return;
            end

            % Create a binary image of the target object. (logical, M x N)
            binMaskTarget = false(size(binImage));
            binMaskTarget(pixelIdxListTarget) = true;

            % Get the boundary of the target object. (cell, numBoundaries x 1)
            boundary = bwboundaries(binMaskTarget);

            if numel(boundary) > 1
                error("Multiple boundaries found for a single object.");
            end

            % Return the pixel coordinates of the boundary.
            % (double, numBoundaryPixels x MN)
            boundary = boundary{1};

            % NOTE:
            % MN: The row and column on the sagittal slice.

            % Number of boundary pixels.
            numBoundaryPixels = size(boundary,1);

            % Initialize the output labels.
            labels = zeros(numBoundaryPixels,1);

            % Return the labels of the boundary pixels.
            for i = 1:numBoundaryPixels
                labels(i) = sagittalSlice(boundary(i,1),boundary(i,2));
            end            

        end

        function sagittalSlice = getSagittalSlice(obj,index)
            %
            % Return the sagittal slice of the index.
            %

            % Prepare all indices of y, x, and z.
            yidx = 1:obj.pLengY;
            xidx = 1:obj.pLengX;
            zidx = 1:obj.pLengZ;

            % Overwrite the index based on the dimension number of sagittal
            % planes.
            switch obj.pDimNumSagittal
                case 1; yidx = index;
                case 2; xidx = index;
                case 3; zidx = index;
            end

            % Return the sagittal slice. (numeric, M x N)
            sagittalSlice = squeeze(obj.pLabelVolume(yidx,xidx,zidx));

        end

        function [boundary,labels] = sortBoundaryPixels(obj,boundary,labels)
            %
            % Sort the boundary pixels using the incision point.
            %

            % Find pixels that have the label of incision point.
            % (logical, numBoundaryPixels x 1)
            isIncisionPoint = labels == obj.pLabelIncision;

            % Get the index where the incision label appears first.
            % (double, 1 x 1)
            idxIncisionPoint = find(isIncisionPoint,1,'first');

            % Number of boundary pixels.
            numBoundaryPixels = size(boundary,1);
        
            % Create indices of boundary pixels after the incision point.
            % (double, 1 x numPoints)
            idxsAfter = (idxIncisionPoint:numBoundaryPixels);
        
            % Create indices of boundary pixels before the incision point.
            % (double, 1 x numPoints)
            if idxIncisionPoint == 1
                idxsBefore = [];
            else
                idxsBefore = (1:idxIncisionPoint-1);
            end
        
            % Combine the two index groups such that the indices after the 
            % incision point come before the other.
            % (double, 1 x numBoundaryPixels)
            idxsOrdered = [idxsAfter,idxsBefore];
        
            % Sort the boundary pixels by the ordered indices.
            boundary = boundary(idxsOrdered,:);
            labels   = labels(idxsOrdered);

        end
        
        function storeFlatmapHeight(obj,indicesOnFlatmap)

            % Calculate the height of the flatmap above and below the 
            % center line.
            flatmapHeightTop    = -1*min(indicesOnFlatmap);
            flatmapHeightBottom =    max(indicesOnFlatmap);

            % Update the height of the flatmap.
            if flatmapHeightTop > obj.pFlatmapHeightTop
                obj.pFlatmapHeightTop = flatmapHeightTop;
            end            
            if flatmapHeightBottom > obj.pFlatmapHeightBottom
                obj.pFlatmapHeightBottom = flatmapHeightBottom;
            end

        end

        % Create color maps.

        function [colorMap,colorLabels] = readColorMap(obj,colorTablePath)
            
            % Read the file. (table, numColors x 6)
            colorTable = readtable( ...
                colorTablePath, ...
                'fileType','delimitedtext', ...
                'Delimiter',' ', ...
                'NumHeaderLines',2 ...
            );
        
            % Extract the RGB triplets and their labels.
            % (double, numColors x RGB), (cell, numColors x 1)
            colorMap    = colorTable{:,3:5};
            colorLabels = colorTable{:,2};
        
            % Add a background (white) for pixels with values 0.
            colorMap    = [255,255,255;colorMap];
            colorLabels = ['background';colorLabels];
        
            % Convert the colors to uint8. (uint8, numColors+1 x RGB)
            colorMap = uint8(colorMap);
        
            % Convert the labels to string. (string, numColors+1 x 1)
            colorLabels = string(colorLabels);
        
        end

        function [colorMap,colorLabels] = createColorMapForCurvature(obj, ...
                colorNameConcave, ...
                colorNameConvex ...
            )

            % Create a MatlabColor handle.
            hMatlabColor = MatlabColor();

            % Validate the color names and get the colors in RGB triplets 
            % format in [0,1]. (double, 1 x RGB)
            colorConcave = hMatlabColor.convertToRgbTriplets(colorNameConcave);
            colorConvex  = hMatlabColor.convertToRgbTriplets(colorNameConvex);

            % Create a color map. (uint8, 4 x RGB)
            colorMap = uint8(255*[
                1,1,1;
                0,0,0;
                colorConcave;
                colorConvex
            ]);

            % Create color labels. (string, 4 x 1)
            colorLabels = [
                "background";
                "inflection point";
                "concave";
                "convex"
            ];

        end

        % Creating flatmaps.

        function flatmap = createFlatmap(obj,labelsToRemove,isCurvaturemap)

            % Initialize a flatmap. (uint8, M x numValidSlices)
            flatmap = obj.initImage();

            for i = 1:obj.pNumSagittalSlices

                % Get the labels of boundary pixels of an object on the
                % sagittal slice. (double, numBoundaryPixels x 1)
                labels = obj.getLabels(i);

                if isempty(labels)
                    continue;
                end

                if isCurvaturemap

                    % Create labels based on curvature of each boundary
                    % point for the curvature map.
                    labelsToInsert = obj.createCurvatureLabels( ...
                        obj.getBoundary(i) ...
                    );

                else

                    % Use the brain region labels for the flatmap.
                    labelsToInsert = labels;

                end                

                if ~isempty(labelsToRemove)
                
                    % Get the indices of brain region labels that user
                    % wants to remove. (logical, numLabels x 1)
                    idxsToReplace = obj.getIndicesToReplace(labels,labelsToRemove);
        
                    % Replace the labels to be inserted with the label of
                    % background (0).
                    labelsToInsert(idxsToReplace) = 0;

                end

                % Insert the labels to the flatmap.
                flatmap = obj.insertLabelsToFlatmap(flatmap,labelsToInsert,i);
            
            end

        end

        function image = initImage(obj)

            % Calculate the height of the flatmap and curvature map.
            height = obj.pFlatmapHeightTop + obj.pFlatmapHeightBottom;

            % Initialize the image. (uint8, M x numValidSlices)
            image = uint8(zeros(height,obj.pNumValidSlices));

        end

        function labels= createCurvatureLabels(obj,boundary)
            %
            % Create labels based on curvature of each boundary
            % point for the curvature map. Assign a value of 2 to points
            % with negative curvature, a value of 3 to points with positive
            % curvature, and a value of 1 to points with zero curvature 
            % (inflection points).
            %

            % Number of boundary pixels.
            numBoundaryPixels = size(boundary,1);

            % Calculate curvature of each boundary point.
            % (double, numBoundaryPixels x 1)
            curvatures = obj.calcCurvature2D(boundary(:,2),boundary(:,1));

            % Create labels for the boundary pixels.
            % (double, numBoundaryPixels x 1)
            labels = ones(numBoundaryPixels,1);

            % Assign 2 and 3 to pixels that have a negative and positive 
            % curvature, respectively.
            labels(curvatures < 0) = 2;
            labels(curvatures > 0) = 3;

        end

        function curvatures = calcCurvature2D(obj,xs,ys)
            %
            % Calculate the curvature of a 2D contour given by x and y
            % coordinates.
            %
            
            dx  = gradient(xs);
            d2x = gradient(dx);
            dy  = gradient(ys);
            d2y = gradient(dy);
            
            curvatures = (dx.*d2y - dy.*d2x) ./ ((dx.^2 + dy.^2).^(3/2));
        
        end

        function idxsToReplace = getIndicesToReplace(obj,labels,labelsToRemove)

            % Return the indices of labels that user wants to remove
            % (replace with the label of background). (logical, numLabels x 1)
            idxsToReplace = arrayfun(@(x)any(x == labelsToRemove),labels);

        end

        function flatmap = insertLabelsToFlatmap(obj, ...
                flatmap, ...
                labels, ...
                sliceIndex ...
            )

            % Get the indices of boundary pixels of an object on a flatmap.
            % (double, numBoundaryPixels x 1)
            indicesOnFlatmap = obj.getIndicesOnFlatmap(sliceIndex);

            % Convert the indices of boundary pixels and slice index to xy
            % coordinates on the flatmap.
            [x,ys] = obj.covertIndexToCoordOnFlatmap(indicesOnFlatmap,sliceIndex);

            % Insert the labels into the flatmap.
            flatmap(ys,x) = labels;

        end

        function [x,ys] = covertIndexToCoordOnFlatmap(obj,pixelIndices,sliceIndex)

            % Convert the indices of pixels to y coordinates on the flatmap.
            % (double, numPixels x 1)
            ys = pixelIndices + obj.pFlatmapHeightTop + 1;

            % Convert the slice index to x coordinate on the flatmap.
            x = sliceIndex - obj.pIndexValidSliceStart + 1;

        end

        function hFig = createFigure(obj,image,colorMap,colorLabels,aspectRatioX)

            hFig = figure("Visible","off");

            % Show the flatmap.
            imshow(image,colorMap);
            colorbar( ...
                "Direction","reverse", ...
                "TickLabels",colorLabels, ...
                "TickLabelInterpreter","none", ...
                "Ticks",(0:numel(colorLabels))+0.5 ...
            );
            
            % Adjust the x and y axes.
            axes = gca;
            axes.YDir = "normal";
            daspect(axes,[1,aspectRatioX,1]);
            axes.OuterPosition = [0,0,1,1];

            % Set the figure size.
            setFigurePositionXYWH(hFig, ...
                [ ...
                    200, ...
                    200, ...
                    obj.pFigureSizeDefault, ...
                    obj.pFigureSizeDefault ...
                ] ...
            );

            % Set the x and y label.
            xlabel("Index of Sagittal Plane Slices");
            ylabel('Perimeter of Cerebellar Surface');

            hFig.Visible = "on";
            drawnow;

        end

        % Mapping points.        

        function [boundaryMask,regionMask] = createBoundaryMask(obj)

            % Initialize binary masks for boundary voxels and the enclosed
            % region. (logical, Y x X x Z)
            boundaryMask = obj.createMaskVolume();
            regionMask   = obj.createMaskVolume();

            switch obj.pDimNumSagittal
                case 1; lengM = obj.pLengX; lengN = obj.pLengZ;
                case 2; lengM = obj.pLengY; lengN = obj.pLengZ;
                case 3; lengM = obj.pLengY; lengN = obj.pLengX;
            end

            % Initialize a binary mask for a sagittal slice. (logical, M x N)
            binMaskSlice = false(lengM,lengN);

            % Prepare all indices of y, x, and z.
            yidx = 1:obj.pLengY;
            xidx = 1:obj.pLengX;
            zidx = 1:obj.pLengZ;    

            for i = 1:obj.pNumSagittalSlices

                boundaryMaskSlice = binMaskSlice;

                % Get the coordinates of boundary pixels of an object on
                % the sagittal slice. (double, numBoundaryPixels x MN)
                boundary = obj.getBoundary(i);

                if size(boundary,1) == 0
                    continue;
                end

                % Convert the mn coordinates to linear indices.
                % (double, numBoundaryPixels x 1)
                idxsBoundary = sub2ind( ...
                    [lengM,lengN], ...
                    boundary(:,1),boundary(:,2) ...
                );

                % Assign True to the boundary pixels.
                boundaryMaskSlice(idxsBoundary) = true;                

                % Overwrite the index based on the dimension number of
                % sagittal planes.
                switch obj.pDimNumSagittal
                    case 1; yidx = i;
                    case 2; xidx = i;
                    case 3; zidx = i;
                end

                % Insert the bounday mask slice to the volume.
                boundaryMask(yidx,xidx,zidx) = boundaryMaskSlice;

                % Fill the enclosed region.
                boundaryMaskSlice = imfill(boundaryMaskSlice,'holes');

                % Insert the region mask slice to the volume.
                regionMask(yidx,xidx,zidx) = boundaryMaskSlice;

            end

        end

        function [yn,xn,zn] = findNearestBoundaryVoxel(obj,boundaryMask,x,y,z)

            % Get linear indices of boundary voxels in the neighborhood
            % of the specified point. (double, numBoundaryVoxels x 1)
            idxsBoundaryNeighbor = obj.findNeighborBoundaryVoxels( ...
                boundaryMask, ...
                x,y,z ...
            );        

            % Number of neighbor boundary voxels.
            numBoundaryVoxels = numel(idxsBoundaryNeighbor);
        
            % Initialize an array to store squared distances from the 
            % source point to each boundary voxel. (double, numBoundaryVoxels x 1)
            distSquared = zeros(numBoundaryVoxels,1);
        
            for i = 1:numBoundaryVoxels
        
                % Convert the linear index of the current boundary voxel to
                % xyz coordinates.
                [yb,xb,zb] = ind2sub(obj.getVolumeSize(),idxsBoundaryNeighbor(i));
        
                % Calculate the distance between the two points.
                distSquared(i) = (x-xb)^2 + (y-yb)^2 + (z-zb)^2;
        
            end
        
            % Find the index of the nearest boundary voxel.
            [~,idxMin] = min(distSquared);
        
            % Linear index of the nearest boundary voxel.
            idxBoundaryNearest = idxsBoundaryNeighbor(idxMin);
            
            % Convert the linear index to xyz coordinates in the volume.
            [yn,xn,zn] = ind2sub(obj.getVolumeSize(),idxBoundaryNearest);

        end

        function idxsBoundaryInSphere = findNeighborBoundaryVoxels(obj, ...
                boundaryMask, ...
                x,y,z ...
            )
            %
            % Find boundary voxels in the neighborhood of the point by 
            % incrementing the searching radius.
            %

            radiusCurrent = obj.pRadiusInit;
        
            while true

                % Get coordinates of voxels inside a sphere of the radius.
                % (double, numVoxelsInSphere x XYZ)
                xyzInUnitSphere = obj.getCoordinatesInUnitSphere(radiusCurrent);

                % Create a mask of the sphere centered at the specified
                % point. (logical, Y x X x Z)
                sphereMask = obj.createShpereMask(xyzInUnitSphere,x,y,z);
            
                % Get logical indices of boundary voxels inside the sphere.
                % (logical, Y x X x Z)
                boundaryInSphere = boundaryMask & sphereMask;

%                 volshow(boundaryMask | sphereMask);
                    
                if sum(boundaryInSphere,'all') ~= 0
                    break;
                end
        
                % Increment the radius.
                radiusCurrent = radiusCurrent + obj.pRadiusDelta;      
        
            end
        
            % Get linear indices of the boundary voxels inside the sphere.
            % (double, numBoundaryVoxels x 1)
            idxsBoundaryInSphere = find(boundaryInSphere);

        end

        function xyz = getCoordinatesInUnitSphere(obj,radius)
            %
            % Return the coordinate of voxels inside a sphere of the 
            % radius, centered at (x,y,z) = (0,0,0).
            %
            % <Output>
            %   xyz: (double, numVoxelsInSphere x xyz)
            %

            % Table variable names.
            varNameRadius = "radius";
            varNameCoords = "coords";

            %--------------%

            if isempty(obj.pCoordInUnitSphereTable)

                % Calculate coordinate of voxels inside a sphere of the 
                % radius, centered at (x,y,z) = (0,0,0).
                xyz = obj.calcCoordinatesInSphere(radius);

                % Initialize a table and store the coordinates for the 
                % radius. (table, numRadius x 2)
                obj.pCoordInUnitSphereTable = table( ...
                    radius,{xyz}, ...
                    'VariableNames',[varNameRadius,varNameCoords] ...
                );

                return;
            end

            % Get the table index of the radius. (logical, numRadius x 1)
            idx = obj.pCoordInUnitSphereTable.(varNameRadius) == radius;
            
            if sum(idx) == 0

                % Calculate coordinate of voxels inside a sphere of the 
                % radius, centered at (x,y,z) = (0,0,0).
                xyz = obj.calcCoordinatesInSphere(radius);

                % Store the coordinate for the radius in the table.
                obj.pCoordInUnitSphereTable(end+1,:) = {radius,{xyz}};

                return;
            end

            % Return the coordinates for the radius.
            xyz = obj.pCoordInUnitSphereTable.(varNameCoords){idx};

        end

        function xyz = calcCoordinatesInSphere(obj,radius)
            %
            % Return coordinate of voxels inside a sphere with a specified
            % radius, centered at (x,y,z) = (0,0,0).
            %
        
            % Define the size of the cube that encloses the sphere and the 
            % number of voxels inside that cube.
            length = 2*radius + 1;
            cubeSize = [length,length,length];
            numVoxelsInCube = length^3;
        
            % Get all indices of the voxels in the cube.
            % (double, numVoxelsInCube x 1)
            [ys,xs,zs] = ind2sub(cubeSize,1:numVoxelsInCube);
        
            % Distance to convert the voxel indices to xyz coordinates 
            % so that the center of the cube is at (0,0,0).
            offset = radius+1;
        
            % Convert the indices to xyz coordinates.
            xs = xs - offset;
            ys = ys - offset;
            zs = zs - offset;
        
            % Calculate the distance between the cube center and each voxel.
            % (double, length x length x length)
            Xs = reshape(xs,cubeSize);
            Ys = reshape(ys,cubeSize);
            Zs = reshape(zs,cubeSize);
            distSquare = Xs.^2 + Ys.^2 + Zs.^2;
        
            % Linear indices of voxels that located inside the sphere.
            % (double, numVoxelsInSphere x 1)
            idxsInSphere = find(distSquare <= radius^2);

            % Get the indices of the voxels inside the sphere.
            [ys,xs,zs] = ind2sub(cubeSize,idxsInSphere);
        
            % Convert the indices to xyz coordinates.
            xs = xs - offset;
            ys = ys - offset;
            zs = zs - offset;
        
            % Return the xyz coordinates. (double, numVoxelsInSphere x xyz)
            xyz = [xs,ys,zs];

        end

        function sphereMask = createShpereMask(obj, ...
                xyzInUnitSphere, ...
                xCenter,yCenter,zCenter ...
            )

            % Initialize the output mask. (logical, Y x X x Z)
            sphereMask = obj.createMaskVolume();            
    
            % Shift all coordinates inside the unit sphere so that the 
            % center of the sphere is located at the specified point.
            x = xyzInUnitSphere(:,1) + xCenter;
            y = xyzInUnitSphere(:,2) + yCenter;
            z = xyzInUnitSphere(:,3) + zCenter;
    
            % Get logical indices of voxels inside the sphere that locate 
            % outside the cuboid.
            idxOutOfCuboid = x < 1 | x > obj.pLengX | ...
                             y < 1 | y > obj.pLengY | ...
                             z < 1 | z > obj.pLengZ;
    
            % Remove the voxels outside the cuboid.
            x = x(~idxOutOfCuboid);
            y = y(~idxOutOfCuboid);
            z = z(~idxOutOfCuboid);

            % Convert the voxel indices to linear indices in the volume.
            idxs = sub2ind(obj.getVolumeSize(),y,x,z);   
        
            % Assign True to the voxels inside the sphere.
            sphereMask(idxs) = true;        

        end

        function binMaskVolume = createMaskVolume(obj)

            % Create a volume of binary mask. (logical, Y x X x Z)
            binMaskVolume = false(obj.getVolumeSize());

        end

        function size = getVolumeSize(obj)

            % Return the size of the volume. (double, 1 x 3)
            size = [obj.pLengY,obj.pLengX,obj.pLengZ];

        end

        % Get parsed boundary data.

        function boundaryData = getBoundaryData(obj,sliceIndex)

            % Get the boundary data of an object on the sagittal slice.
            % (double, numBoundaryPixels x 4) or []
            boundaryData = obj.pBoundaryDataCell{sliceIndex};
        
            % NOTE:
            % 1st column: y coordinates on the sagittal slice.
            % 2nd column: x coordinates on the sagittal slice.
            % 3rd column: labels (indices) of brain regions.
            % 4th coulmn: indices on the flat map.

        end

        function labels = getLabels(obj,sliceIndex)

            labels = [];

            % Get the boundary data of an object on the sagittal slice.
            % (double, numBoundaryPixels x 4) or []
            boundaryData = obj.getBoundaryData(sliceIndex);

            if isempty(boundaryData)
                return;
            end

            % Get the labels of the boundary pixels.
            % (double, numBoundaryPixels x 1)
            labels = boundaryData(:,3);            

        end

        function boundary = getBoundary(obj,sliceIndex)

            boundary = [];

            % Get the boundary data of an object on the sagittal slice.
            % (double, numBoundaryPixels x 4) or []
            boundaryData = obj.getBoundaryData(sliceIndex);

            if isempty(boundaryData)
                return;
            end

            % Get the coordinates of the boundary pixels.
            % (double, numBoundaryPixels x MN)
            boundary = boundaryData(:,1:2);

            % NOTE:
            % MN: The row and column on the sagittal slice.

        end

        function indicesOnFlatmap = getIndicesOnFlatmap(obj,sliceIndex)

            indicesOnFlatmap = [];

            % Get the boundary data of an object on the sagittal slice.
            % (double, numBoundaryPixels x 4) or []
            boundaryData = obj.getBoundaryData(sliceIndex);

            if isempty(boundaryData)
                return;
            end

            % Get the indices of the boundary pixels on a flatmap.
            % (double, numBoundaryPixels x 1)
            indicesOnFlatmap = boundaryData(:,4);

        end        

        % Printing messages.
        
        function printSliceSkipped(obj,verbose)

            if ~verbose
                return;
            end
            
            fprintf("    Skipped due to no object with incision and origin point.\n");

        end

        function printObjectSkipped(obj,labels,verbose)

            if ~verbose
                return;
            end

            fprintf( ...
                "Skipped due to no incision or origin point. (labels: %s)\n", ...
                strJoinMatComma(double(unique(labels)')) ...
            );

        end

        % Validations.

        function validateParsingDone(obj)

            if isempty(obj.pBoundaryDataCell)
                error("Run parse() first.");
            end

        end

        function validateColorTablePath(obj,colorTablePath)

            % Validate the input.
            mustBeTextScalar(colorTablePath);
        
            % Validate the file exists.
            validatePathsExist(colorTablePath);
        
            % Validate the file extension.
            validateFileExt(colorTablePath,obj.pValidExtColorTable);

        end

        function xyzSource = validateSourcePoints(obj,xyzSource)

            % Validate the coordinates of source points.
            mustBeGreaterThanOrEqual(xyzSource,0.5);
            mustBeNumCols(xyzSource,3);

            % Convert the spatial coorinates to pixel indices.
            xyzSource = round(xyzSource);

            % Validate the indices are within the volume data.
            if max(xyzSource(:,1)) > obj.pLengX || ...
               max(xyzSource(:,2)) > obj.pLengY || ...
               max(xyzSource(:,3)) > obj.pLengZ
                error( ...
                    "The x, y, z coordinates of source points must be less " + ...
                    "than %.1f, %.1f, %.1f, respectively.", ...
                    obj.pLengX + 0.5, ...
                    obj.pLengY + 0.5, ...
                    obj.pLengZ + 0.5 ...
                );
            end

        end

    end
    
end