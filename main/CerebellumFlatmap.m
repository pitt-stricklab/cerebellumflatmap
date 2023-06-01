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
    %
    
    properties (Access = private)

        % Volume data of labels.
        pLabelVolume

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
        
        % Set the minimum curvature between adjacent fold points.
        pCurvatureThreshold = 0.1;      

        % Index of the first valid slice.
        pIndexValidSliceStart

        % Number of slices that have a valid object.
        pNumValidSlices = 0;        

        % Size of the flatmap.
        pFlatmapHeightTop    = 0;
        pFlatmapHeightBottom = 0;

        % Valid file extensions.
        pValidExtColorTable = ".ctbl";
        
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
                % boundary: (double, numBoundaryPixels x YX) or []
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
            
                % Get the boundary data of the sagittal slice.
                % (double, numBoundaryPixels x 4)
                boundaryData = obj.pBoundaryDataCell{i};

                if ~isempty(boundaryData)

                    % Get the coordinates of the boundary.
                    % (double, numBoundaryPixels x YX)
                    boundary = boundaryData(:,1:2);
    
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

                    % Wait for a moment.
                    pause(0.1);

                else

                    % Wait until user press any key.
                    pause;

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

    end

    methods (Access = private)

        function sagittalSlice = getSagittalSlice(obj,index)
            %
            % Return the sagittal slice of the index.
            %

            % Get the size of the volume.
            [Y,X,Z] = size(obj.pLabelVolume);

            % Prepare all indices of y, x, and z.
            yidx = 1:Y;
            xidx = 1:X;
            zidx = 1:Z;

            % Overwrite the index based on the dimensions of sagittal
            % planes.
            switch obj.pDimNumSagittal
                case 1; yidx = index;
                case 2; xidx = index;
                case 3; zidx = index;
            end

            % Return the sagittal slice. (numeric, M x N)
            sagittalSlice = squeeze(obj.pLabelVolume(yidx,xidx,zidx));

        end

        function [boundary,labels] = getBoundaryPixels(obj,sagittalIndex,verbose)
            %
            % Return the coordinates of boundary pixels of a label area in 
            % the sagittal slice that have incision and origin points, and 
            % the labels of each boundary pixel.
            %
            % <Output>
            %   boundary: (double, numBoundaryPixels x YX) or []
            %       Coordinates of boundary pixels.
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
            % (double, numBoundaryPixels x YX)
            boundary = boundary{1};

            % Number of boundary pixels.
            numBoundaryPixels = size(boundary,1);

            % Initialize the output labels.
            labels = zeros(numBoundaryPixels,1);

            % Return the labels of the boundary pixels.
            for i = 1:numBoundaryPixels
                labels(i) = sagittalSlice(boundary(i,1),boundary(i,2));
            end            

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

        function flatmap = createFlatmap(obj,labelsToRemove,isCurvaturemap)

            % Initialize a flatmap. (uint8, M x numValidSlices)
            flatmap = obj.initImage();

            for i = 1:obj.pNumSagittalSlices
            
                % Get the boundary data of the sagittal slice.
                % (double, numBoundaryPixels x 4)
                boundaryData = obj.pBoundaryDataCell{i};
            
                % NOTE:
                % 1st column: y coordinates
                % 2nd column: x coordinates
                % 3rd column: labels (indices) of brain regions
                % 4th coulmn: indices on the flat map
            
                if size(boundaryData,1) == 0
                    continue;
                end

                % Get the brain region labels of the boundary pixels.
                % (double, numBoundaryPixels x 1)
                labels = boundaryData(:,3);

                if isCurvaturemap

                    % Create labels based on curvature of each boundary
                    % point for the curvature map.
                    labelsToInsert = obj.createCurvatureLabels( ...
                        boundaryData(:,1:2) ...
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
                flatmap = obj.insertLabelsToFlatmap( ...
                    flatmap, ...
                    labelsToInsert, ...
                    boundaryData(:,4), ...
                    i ...
                );
            
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
                indicesOnFlatmap, ...
                sliceIndex ...
            )

            % Convert the indices of each pixel on the flatmap to the pixel 
            % coordinates. (double, numPixels x 1)
            indicesOnFlatmap = indicesOnFlatmap + obj.pFlatmapHeightTop + 1;

            % Calculate the column number for the slice on the flatmap.
            col = sliceIndex - obj.pIndexValidSliceStart + 1;

            % Insert the labels into the flatmap.
            flatmap(indicesOnFlatmap,col) = labels;

        end

        function hFig = createFigure(obj,image,colorMap,colorLabels,aspectRatioX)

            hFig = figure;
            
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
            
            % Set the x and y label.
            xlabel('Slice index in the sagittal planes.');
            ylabel('Distance from the origin line.');

        end

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

    end
    
end