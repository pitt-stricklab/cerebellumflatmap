classdef FlatmapGenerator < ClassVersion
    %
    % This class generates flatmaps from 3D volume data segmented by label
    % indices.
    %
    % Main Processing Steps
    %   1) Extract boundary pixels of the object in the volume data for
    %      each sagittal slice. 
    %   2) Cut open each boundary line at a predefined incision point.
    %   3) Align the one-dimensional boundary lines across slices based on
    %      a predefined origin point.
    %
    % Requirements for Label Volume Data
    %   a) The target region must have both an incision line and an origin
    %      line defined by specific label indices.
    %   b) Any disconnected region lacking both an incision and an origin
    %      label on its boundary will be ignored and excluded from the
    %      flatmap.
    %   c) If the desired regions are separated in the sagittal plane,
    %      connect them using an arbitrary label (e.g., 'Bridge').

    % HISTORY: testCreateBrainFlatMap.m
    %   1.0 - 20230427 Written by Mitsu

    % HISTORY:
    %   1.0 - 20230518 a) Written by Mitsu
    %                  b) Moved functions from testCreateBrainFlatMap.m
    %   2.0 - 20230601 a) Major updates and improvements. 
    %                  b) Added showBoundaries() and showCurvaturemap().
    %                  c) Modified the figure appearance.
    %   2.1 - 20230606 Added mapPoints().
    %   2.2 - 20230608 a) Renamed showFlatmap() to showLabelFlatmap(), and
    %                     showCurvaturemap() to showCurvatureFlatmap().
    %                  b) Added showIntensityFlatmap().
    %   2.3 - 20231004 Added showBorderFlatmap().
    %   2.4 - 20231027 Added getCoordinateFlatmap().
    %   2.5 - 20240719 Organized the codes and updated the docstrings.
    %   3.0 - 20250508 Change the behavior of showLabelFlatmap(),
    %                  showBorderFlatmap(), showCurvatureFlatmap(), and
    %                  showIntensityFlatmap() so that they return the
    %                  flatmap instead of generating a figure. Rename the 
    %                  functions to createLabelFlatmap(),
    %                  createBorderFlatmap(), createCurvatureFlatmap(), and
    %                  createIntensityFlatmap(), respectively.
    %   3.1 - 20250509 Added getIndexValidSliceStart().
    %   3.2 - 20250514 Removed obsolete properties, methods, and options
    %                  and revised comments and method names per the v3.0
    %                  update.
    %   3.3 - 20250516 Renamed CerebellumFlatmap class to FlatmapGenerator.

    properties (Constant)

        % Version of the class definition.
        cClassVersion = 3.3;

        % Method names for creating each type of flatmap.
        cMethodNameCreateLabelFlatmap     = "createLabelFlatmap";
        cMethodNameCreateBorderFlatmap    = "createBorderFlatmap";
        cMethodNameCreateCurvatureFlatmap = "createCurvatureFlatmap";
        cMethodNameCreateIntensityFlatmap = "createIntensityFlatmap";
    
    end

    properties (Access = private)

        % Volume data of labels.
        pLabelVolume

        % Size of the label volume data.
        pLenY
        pLenX
        pLenZ

        % 3D indices for each axis.
        pIdxsY
        pIdxsX
        pIdxsZ

        % A cell to store boundary pixels on each sagittal slice.
        pBoundaryPixelsCell

        % Number of sagittal slices.
        pNumSagittalSlices

        % The dimension number that corresponds to the direction 
        % perpendicular to the sagittal plane in the input NIfTI data.
        pDimNumSagittal

        % Label IDs in the volume.
        pLabelIdIncision % Incision points
        pLabelIdOrigin   % Origin points

        % Predefined label IDs.
        pLabelIdBackground      = 0;
        pLabelIdBorder          = 1;
        pLabelIdInflectionPoint = 1;
        pLabelIdConcave         = 2;
        pLabelIdConvex          = 3;

        % Index of the first valid slice.
        pIndexValidSliceStart

        % Number of slices that have a valid object.
        pNumValidSlices = 0;        

        % Size of the flatmap.
        pFlatmapHeightTop    = 0;
        pFlatmapHeightBottom = 0;

        % Initial radius of sphere to find nearest boundary pixel.
        pRadiusInit = 10;

        % How much to increase the sphere radius while finding the nearest
        % pixel.
        pRadiusDelta = 5;

        % A table that stores coordinates of voxels inside spheres of
        % variety of radius.
        pCoordInUnitSphereTable

        % A MatlabColor handle.
        hMatlabColor
        
        % Variable names for the boundary pixels table.
        pVarNameRow     = "row";
        pVarNameColumn  = "column";
        pVarNameLabelId = "labelId";
        pVarNameOffset  = "offset";
        
    end

    methods (Access = public)
        
        % Constructor.
        
        function obj = FlatmapGenerator( ...
                labelVolumePath, ...
                dimNumSagittal, ...
                labelIdIncision, ...
                labelIdOrigin ...
            )
            %
            % <Input>
            %   labelVolumePath: (text, 1 x 1)
            %       A single NIfTI image file path. Each voxel value must
            %       be a label ID (integer). Both NIfTI1 and NIfTI2 formats
            %       are supported.
            %   dimNumSagittal: (integer, 1 x 1)
            %       The dimension number corresponding to the direction 
            %       perpendicular to the sagittal plane in the input NIfTI
            %       data.
            %   labelIdIncision: (integer, 1 x 1)
            %       The label ID used for the incision point.
            %   labelIdOrigin: (integer, 1 x 1)
            %       The label ID used for the origin point.
            %

            arguments
                labelVolumePath {Validator.mustBeTextScalar}
                dimNumSagittal ...
                    { ...
                        Validator.mustBePosIntegerScalar, ...
                        Validator.mustBeLessThanOrEqual(dimNumSagittal,3) ...
                    }
                labelIdIncision {Validator.mustBeIntegerScalar}
                labelIdOrigin   {Validator.mustBeIntegerScalar}
            end
            
            % Load and store the 3D volume label data. (numeric, Y x X x Z)
            obj.pLabelVolume = niftiread(labelVolumePath);

            % Store the size of the volume.
            [obj.pLenY,obj.pLenX,obj.pLenZ] = size(obj.pLabelVolume);

            % Store 3D indices for each axis (y, x, and z). (double, 1 x N)
            [obj.pIdxsY,obj.pIdxsX,obj.pIdxsZ] = obj.create3dIndices();

            % Store the inputs.
            obj.pDimNumSagittal  = dimNumSagittal;
            obj.pLabelIdIncision = labelIdIncision;
            obj.pLabelIdOrigin   = labelIdOrigin;

            % Create and store a MatlabColor handle.
            obj.hMatlabColor = MatlabColor();

        end

        function parse(obj,verbose)
            %
            % Parse all sagittal slices and extract boundary pixels on each
            % sagittal slice.
            %
            % <Input>
            % OPTIONS
            %   verbose: (logical, 1 x 1)
            %       Whether to show parsing results in the Command Window.

            arguments
                obj
                verbose {Validator.mustBeLogicalScalar} = true;
            end

            % Get the number of sagittal slices.
            obj.pNumSagittalSlices = size(obj.pLabelVolume,obj.pDimNumSagittal);
            
            % Initialize a cell to store boundary pixels on each sagittal
            % slice. (cell, numSagittalSlices x 1)
            obj.pBoundaryPixelsCell = cell(obj.pNumSagittalSlices,1);

            obj.printMsg(verbose, ...
                "* Parsing all sagittal slices in the label volume data ...\n" ...
            );

            for i = 1:obj.pNumSagittalSlices

                obj.printMsg(verbose,"\n  Slice #%d:\n",i);

                % Extract the coordinates of the boundary pixels of the
                % label areas on the sagittal slice, their label IDs at those
                % coordinates, and the offset of each boundary pixel from
                % the origin point on the flatmap.
                % (table, numBoundaryPixels x 4)
                boundaryPixels = obj.extractBoundaryPixels(i,verbose);

                if isempty(boundaryPixels)
                    continue;
                end

                % Store the index of the first valid slice.
                if isempty(obj.pIndexValidSliceStart)
                    obj.pIndexValidSliceStart = i;
                end

                % Count up the number of valid slices.
                obj.pNumValidSlices = obj.pNumValidSlices + 1;

                % Update the height of the flatmap.
                obj.updateFlatmapHeight(boundaryPixels);                

                % Store the boundary pixels in the cell.
                % (cell, numSagittalSlices x 1) < (table, numBoundaryPixels x 4)
                obj.pBoundaryPixelsCell{i} = boundaryPixels;
            
            end

        end

        function showBoundaries(obj,options)
            %
            % Show boundaries on each sagittal slice.
            %
            % <Input>
            % OPTIONS
            %   colorNameBoundary: (text, 1 x 1)
            %       A color name for boundary lines. See plot() for the 
            %       valid color names.
            %   showAnimation: (logical, 1 x 1)
            %       Whether to animate boundary display.
            %

            arguments
                obj
                options.colorNameBoundary {Validator.mustBeTextScalar}    = "cyan"
                options.showAnimation     {Validator.mustBeLogicalScalar} = false
            end

            colorNameBoundary = options.colorNameBoundary;
            showAnimation     = options.showAnimation;

            % Validate the parsing of the volume data is done.
            obj.validateParsingDone();

            % Validate the color name. (string, 1 x 1)
            colorNameBoundary = obj.hMatlabColor.validateColorNames( ...
                colorNameBoundary ...
            );

            % Create a figure.
            figure;
            hAxes = gca;

            if ~showAnimation
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
                imshow(sagittalSlice,Parent=hAxes);

                % Set the title.
                title(sprintf("Slice #%d",i));                

                % Restore the x and y limit.
                if i ~= 1
                    hAxes.XLim = xLim;
                    hAxes.YLim = yLim;
                end

                % Get the boundary pixels on the sagittal slice.
                % (table, numBoundaryPixels x 4) or []
                boundaryPixels = obj.pBoundaryPixelsCell{i};

                if ~isempty(boundaryPixels)
    
                    % Show the boundary.
                    hold on
                    plot(hAxes, ...
                        boundaryPixels.(obj.pVarNameColumn), ...
                        boundaryPixels.(obj.pVarNameRow), ...
                        'LineWidth',2, ...
                        'Color',colorNameBoundary ...
                    );                
                    hold off

                end

                if showAnimation                    
                    pause(0.1); % Wait for a moment.
                else                    
                    pause;      % Wait until user press any key.
                end                    

            end

        end

        function flatmap = createLabelFlatmap(obj,options)
            %
            % Create a label flatmap.
            %
            % <Input>
            % OPTIONS
            %   labelIdsToRemove: (numeric, M x N)
            %       Label ID(s) to be removed from the final flatmap. The 
            %       value(s) must be positive integers.
            %
            % <Output>
            %   flatmap: (uint8, M x numValidSlices)
            %       Resulting label flatmap.
            %

            arguments
                obj {}
                options.labelIdsToRemove {} = []
            end

            labelIdsToRemove = options.labelIdsToRemove;

            % Validate the parsing of the volume data is done.
            obj.validateParsingDone();

            % Validate the label IDs to be removed.
            obj.validateLabelIdsToRemove(labelIdsToRemove);

            % Create a label flatmap. (uint8, M x numValidSlices)
            flatmap = obj.createFlatmapLabel(labelIdsToRemove);            
            
        end        

        function flatmap = createBorderFlatmap(obj,options)
            %
            % Create a border flatmap.
            %
            % <Input>
            % OPTIONS
            %   labelIdsToRemove: (numeric, M x N)
            %       See createLabelFlatmap().
            %
            % <Output>
            %   flatmap: (uint8, M x numValidSlices)
            %       Resulting border flatmap.
            %

            arguments
                obj {}
                options.labelIdsToRemove {} = []
            end

            labelIdsToRemove = options.labelIdsToRemove;

            % Validate the parsing of the volume data is done.
            obj.validateParsingDone();

            % Validate the label IDs to be removed.
            obj.validateLabelIdsToRemove(labelIdsToRemove);

            % Create a border flatmap. (uint8, M x numValidSlices)
            flatmap = obj.createFlatmapBorder(labelIdsToRemove);            

        end

        function flatmap = createCurvatureFlatmap(obj,options)
            %
            % Create a curvature flatmap.
            %
            % <Input>
            % OPTIONS
            %   labelIdsToRemove: (numeric, M x N)
            %       See createLabelFlatmap().
            %
            % <Output>
            %   flatmap: (uint8, M x numValidSlices)
            %       Resulting curvature flatmap.
            %

            arguments
                obj {}
                options.labelIdsToRemove {} = []
            end

            labelIdsToRemove = options.labelIdsToRemove;

            % Validate the parsing of the volume data is done.
            obj.validateParsingDone();

            % Validate the label IDs to be removed.
            obj.validateLabelIdsToRemove(labelIdsToRemove);

            % Create a curvature flatmap. (uint8, M x numValidSlices)
            flatmap = obj.createFlatmapCurvature(labelIdsToRemove);

        end

        function flatmap = createIntensityFlatmap(obj,intensityVolumePath,options)
            %
            % Create an intensity flatmap.
            %
            % <Input>
            %   intensityVolumePath: (text, 1 x 1)
            %       A path of a 3D volume intensity data aligned with the
            %       label volume data (e.g., .nii.gz).
            % OPTIONS
            %   labelIdsToRemove: (numeric, M x N)
            %       See createLabelFlatmap().
            %
            % <Output>
            %   flatmap: (double, M x numValidSlices)
            %       Resulting intensity flatmap.
            %

            arguments
                obj {}
                intensityVolumePath {Validator.mustBeTextScalar}
                options.labelIdsToRemove {} = []           
            end

            labelIdsToRemove = options.labelIdsToRemove;

            % Validate the parsing of the volume data is done.
            obj.validateParsingDone();

            % Validate the label IDs to be removed.
            obj.validateLabelIdsToRemove(labelIdsToRemove);
            
            % Load the 3D volume intensity data. (numeric, Y x X x Z)
            intensityVolume = niftiread(intensityVolumePath);

            % Get the size of the volume.
            [lengY,lengX,lengZ] = size(intensityVolume);

            % Validate the size matches the label volume size.
            if lengY ~= obj.pLenY || lengX ~= obj.pLenX || lengZ ~= obj.pLenZ
                error( ...
                    "The size of the intensity volume data must match the " + ...
                    "label volume size." ...
                );
            end

            % Create a intensity flatmap. (double, M x numValidSlices)
            flatmap = obj.createFlatmapIntensity( ...
                labelIdsToRemove, ...
                intensityVolume ...
            );

        end        

        function flatmap = getCoordinateFlatmap(obj,options)
            %
            % Create a flatmap that represents the coordinates of each
            % contour point on each slice.
            %
            % <Input>
            % OPTIONS
            %   labelIdsToRemove: (numeric, M x N)
            %       See createLabelFlatmap().
            %
            % <Output>
            %   flatmap: (uint8, M x N x RC)
            %       A flatmap representing the coordinates of each
            %       boundary point on each slice. The first channel 
            %       contains row coordinates and the second channel
            %       contains column coordinates on the sagittal slice.
            %

            arguments
                obj {}
                options.labelIdsToRemove {} = []           
            end

            labelIdsToRemove = options.labelIdsToRemove;

            % Validate the parsing of the volume data is done.
            obj.validateParsingDone();

            % Validate the label IDs to be removed.
            obj.validateLabelIdsToRemove(labelIdsToRemove);

            % Create a coordinate flatmap. (uint8, M x numValidSlices x RC)
            flatmap = obj.createFlatmapCoordinate(labelIdsToRemove);

        end

        function nmTarget = mapPoints(obj,xyzSource,verbose)
            %
            % Return the coordinates for mapping points within the 
            % object in the volume data onto the flatmap.
            %
            % <Input>
            %   xyzSource: (numeric, numSourcePoints x XYZ)
            %       Coordinates (x, y, z) of points existing in the label
            %       volume data and mapped to the flatmap. Points outside
            %       the object are ignored.
            % OPTIONS
            %   verbose: (logical, 1 x 1)
            %       Whether to show skipped points in the Command Window.
            %
            % <Output>
            %   nmTarget: (double, numTargetPoints x NM)
            %       Coordinates (n, m) of the mapped points on the flatmap.
            %       N represents the horizontal axis value on the flatmap
            %       (index of the sagittal slice), and M represents the
            %       vertical axis.

            arguments
                obj
                xyzSource {}
                verbose {Validator.mustBeLogicalScalar} = true;
            end

            % Validate the parsing of the volume data is done.
            obj.validateParsingDone();

            % Validate the coordinates of the source points and convert
            % them to pixel indices. (numeric, XYZ)
            xyzSourceIdx = obj.validateSourcePoints(xyzSource);

            % Create 3D binary masks for the boundary and interior of the 
            % object within the label volume data. (logical, Y x X x Z)
            [binMask3dBoundary,binMask3dInterior] = obj.createBinaryMasks3d();

            % Number of source points.
            numPointsSource = size(xyzSourceIdx,1);

            % Initialize a cell to store the coordinates of mapped points
            % on the flatmap. (cell, numSourcePoints x 1) 
            coordinatesOnFlatmapCell = cell(numPointsSource,1);

            for i = 1:numPointsSource

                % Get the coordinates of the source point. (double, 1 x 1)
                xSource = xyzSourceIdx(i,1);
                ySource = xyzSourceIdx(i,2);
                zSource = xyzSourceIdx(i,3);

                % Skip if the point does not exist within the object.
                if ~binMask3dInterior(ySource,xSource,zSource)
                    obj.printMsg(verbose, ...
                        "Point #%d (%s) was skipped as it does not exist " + ...
                        "within the object.\n", ...
                        i,strJoinMatComma(xyzSource(i,:)) ...
                    );
                    continue;
                end

                % Find the coordinate of the nearest boundary voxel to the
                % source point.
                [yNearest,xNearest,zNearest] = obj.findNearestBoundaryVoxel( ...
                    binMask3dBoundary, ...
                    xSource,ySource,zSource ...
                );              

                % Convert the index in 3D volume into an index on a 2D 
                % slice based on the sagittal dimension number.
                switch obj.pDimNumSagittal
                    case 1; sliceIndex = yNearest; row = xNearest; column = zNearest;
                    case 2; sliceIndex = xNearest; row = yNearest; column = zNearest;
                    case 3; sliceIndex = zNearest; row = yNearest; column = xNearest;
                end

                % Get the boundary pixels on the sagittal slice.
                % (table, numBoundaryPixels x 4) or []
                boundaryPixels = obj.pBoundaryPixelsCell{sliceIndex};

                % Get the index of the nearest boundary pixel on the slice.
                % (logical, numBoundaryPixels x 1)
                idxNearest = ...
                    boundaryPixels.(obj.pVarNameRow) == row & ...
                    boundaryPixels.(obj.pVarNameColumn) == column;

                % Get the offset of each boundary pixel on the flatmap.
                % (double, numBoundaryPixels x 1)
                offset = boundaryPixels.(obj.pVarNameOffset);

                % Get the offset of the nearest boundary pixel on the
                % flatmap.
                offsetNearest = offset(idxNearest);

                % Calculate the coordinates (m: vertical axis, n: horizontal
                % axis) on the flatmap for the nearest boundary pixel.
                [n,m] = obj.calcCoordinatesOnFlatmap(offsetNearest,sliceIndex);

                % Store the coordinate in the cell. (double, 1 x nm)
                coordinatesOnFlatmapCell{i} = [n,m];
            
            end

            % Return the coordinates of mapped (target) points on the 
            % flatmap. (double, numTargetPoints x nm)
            nmTarget = vertcat(coordinatesOnFlatmapCell{:});

        end

        function indexValidSliceStart = getIndexValidSliceStart(obj)

            % Return the index of the first valid sagittal slice.
            indexValidSliceStart = obj.pIndexValidSliceStart;

        end

    end

    methods (Access = private)

        function [idxsY,idxsX,idxsZ] = create3dIndices(obj)

            % Create 3D indices for each axis (y, x, and z).
            % (double, 1 x N)
            idxsY = 1:obj.pLenY;
            idxsX = 1:obj.pLenX;
            idxsZ = 1:obj.pLenZ;

        end
        
        % Parse boundary data.

        function boundaryPixels = extractBoundaryPixels(obj,sagittalIndex,verbose)
            %
            % Return the coordinates of the boundary pixels of the label
            % areas on the sagittal slice, their label IDs at those
            % coordinates, and the offset of each boundary pixel from the 
            % origin point on the flatmap. If the slice does not include 
            % both the incision label and the origin label, it returns an
            % empty array [].
            %
            % <Output>
            %   boundaryPixels: (table, numBoundaryPixels x 3) or []
            %       row, column: (double, 1 x 1)
            %           The coordinates of each boundary pixel on the 
            %           sagittal slice.
            %       labelId: (double, 1 x 1)
            %           The label IDs of each each boundary pixel.
            %       offset: (double, 1 x 1)
            %           The the offset of each boundary pixel from the
            %           origin point on the flatmap.

            boundaryPixels = [];

            % Get a sagittal slice of the index. (numeric, M x N)
            sagittalSlice = obj.getSagittalSlice(sagittalIndex);

            % Get the linear indices of the pixels occupied by the target 
            % object that should be unfolded, from the sagittal slice.
            % (double, numPixels x 1)
            pixelIdxsObjectTarget = obj.getPixelIndicesOfTargetObject( ...
                sagittalSlice, ...
                verbose ...
            );

            if isempty(pixelIdxsObjectTarget)
                obj.printMsg(verbose, ...
                    "    Skipped because no objects containing both the " + ...
                    "incision point and the origin point were found.\n" ...
                );
                return;
            end

            % Create a binary image of the target object.
            % (logical, rows x columns)
            binMaskTarget = false(size(sagittalSlice));
            binMaskTarget(pixelIdxsObjectTarget) = true;

            % Get the exterior boundaries of the target object.
            % (cell, numBoundaries x 1)
            boundary = bwboundaries(binMaskTarget);

            if numel(boundary) > 1
                error("Multiple boundaries found for a single object.");
            end

            % Extract the pixel coordinates of the boundary.
            % (double, numBoundaryPixels x 2)
            boundary = boundary{1};

            % NOTE:
            % 1st column:
            %   The coordinates (row) of each pixel in the sagittal slice.
            % 2nd column:
            %   The coordinates (column) of each pixel in the sagittal slice.

            numBoundaryPixels = height(boundary);

            % Initialize a table to store the coordinates of boundary 
            % pixels, their label IDs on the sagittal plane, and their 
            % offsets from the origin point on the flatmap. 
            % (table, numBoundaryPixels x 4)
            boundaryPixels = initTable( ...
                [ ...
                    obj.pVarNameRow, ...
                    obj.pVarNameColumn, ...
                    obj.pVarNameLabelId, ...
                    obj.pVarNameOffset ...
                ], ...
                numBoundaryPixels, ...
                ["double","double","double","double"] ...
            );

            % Store the coordinates of the boundary pixels.
            boundaryPixels{:,1:2} = boundary;

            % Get linear indices of each boundary pixel.
            % (double, numBoundaryPixels x 1)
            idxsBoundary = sub2ind( ...
                size(sagittalSlice), ...
                boundary(:,1),boundary(:,2) ...
            );

            % Get the label IDs of each boundary pixel.
            % (numeric, numBoundaryPixels x 1)
            labelIds = sagittalSlice(idxsBoundary);

            % Store the label IDs.
            boundaryPixels{:,3} = labelIds;

            % Sort the boundary pixels with the incision point at the top.
            boundaryPixels = obj.sortBoundaryPixels(boundaryPixels);

            % Find the boundary pixels with the label of the origin point.
            % (logical, numBoundaryPixels x 1)
            isOriginPoint = ...
                boundaryPixels.(obj.pVarNameLabelId) == obj.pLabelIdOrigin;

            % Get the index where the origin label appears first.
            % (double, 1 x 1)
            idxOriginPoint = find(isOriginPoint,1,'first');

            % Store the offset of each boundary pixel from the origin point
            % on the flatmap. Pixels before the origin point have positive
            % values, and pixels after the origin point have negative
            % values.
            boundaryPixels{:,4} = -1*(1:numBoundaryPixels)'+idxOriginPoint; % Transposed

        end

        function sagittalSlice = getSagittalSlice(obj,sagittalIndex)
            %
            % Return the sagittal slice of the index.
            %

            % Get the index within the label volume data for the sagittal
            % slice.
            [idxsY,idxsX,idxsZ] = obj.getSagittalSliceIndices(sagittalIndex);

            % Return the sagittal slice. (numeric, M x N)
            sagittalSlice = squeeze(obj.pLabelVolume(idxsY,idxsX,idxsZ));

        end

        function [idxsY,idxsX,idxsZ] = getSagittalSliceIndices(obj,sagittalIndex)
            %
            % Get the index within the label volume data for the sagittal
            % slice.
            %

            % Get the 3D indices for each axis.
            idxsY = obj.pIdxsY;
            idxsX = obj.pIdxsX;
            idxsZ = obj.pIdxsZ;

            % Rewrite the index based on the dimension number of sagittal
            % planes.
            switch obj.pDimNumSagittal
                case 1; idxsY = sagittalIndex;
                case 2; idxsX = sagittalIndex;
                case 3; idxsZ = sagittalIndex;
            end

        end

        function pixelIdxsObjectTarget = getPixelIndicesOfTargetObject(obj, ...
                sagittalSlice, ...
                verbose ...
            )
            %
            % Return the linear indices of the pixels occupied by the
            % target object (a single object containing both the incision 
            % point and the origin point) that should be unfolded, from the
            % sagittal slice.
            %

            pixelIdxsObjectTarget = [];

            % Get a binary image of label areas (non-background area).
            % (logical, M x N)
            binImage = sagittalSlice ~= obj.pLabelIdBackground;

            % Return [] if there is no label area.
            if sum(binImage) == 0
                obj.printMsg(verbose,"    No object found.\n");
                return;
            end

            % Fill holes within the label areas.
            binImage = imfill(binImage,"holes");

            % Find and count connected components. (struct, 1 x 1)
            components = bwconncomp(binImage);
        
            % Number of objects found.
            numObjects = components.NumObjects;

            obj.printMsg(verbose,"    %d object(s) found.\n",numObjects);

            numObjectsTarget = 0;

            for i = 1:numObjects

                obj.printMsg(verbose,"      Object #%d: ",i);

                % Get the linear indices of the object's pixels.
                % (double, numPixels x 1)
                pixelIdxsObject = components.PixelIdxList{i};
        
                % Get the labels of the object. (numeric, numPixels x 1)
                labelsObject = sagittalSlice(pixelIdxsObject);

                % Find pixels that have the label of incision and origin 
                % lines. (logical, numPixels x 1)
                isIncisionPoint = labelsObject == obj.pLabelIdIncision;
                isOriginPoint   = labelsObject == obj.pLabelIdOrigin;

                % Skip the object if it does not contain both the incision
                % label and the origin label.
                if sum(isIncisionPoint) == 0 || sum(isOriginPoint) == 0
                    obj.printMsg(verbose, ...
                        "Skipped because it does not contain both the " + ...
                        "incision point and the origin point. (labels: %s)\n", ...
                        strJoinMatComma(double(unique(labelsObject)')) ...
                    );
                    continue;
                end

                % Store the pixel indices of the target object.
                pixelIdxsObjectTarget = pixelIdxsObject;

                obj.printMsg(verbose,"Valid to extract boundary data.\n");

                numObjectsTarget = numObjectsTarget + 1;

            end

            % Disallow a single slice from having multiple objects that
            % contain both the incision point and the origin point. 
            if numObjectsTarget > 1
                error( ...
                    "Currently, multiple objects containing both the " + ...
                    "incision point and the origin point within a single " + ...
                    "slice are not supported." ...
                );
            end

        end

        function boundaryPixels = sortBoundaryPixels(obj,boundaryPixels)
            %
            % Sort the boundary pixels with the incision point at the top.
            %

            % Find pixels that have the label of incision point.
            % (logical, numBoundaryPixels x 1)
            isIncisionPoint = ...
                boundaryPixels.(obj.pVarNameLabelId) == obj.pLabelIdIncision;

            % Get the index where the incision label appears first.
            % (double, 1 x 1)
            idxIncisionPoint = find(isIncisionPoint,1,'first');
       
            % Create indices of boundary pixels after the incision point.
            % (double, 1 x numPoints)
            idxsAfter = (idxIncisionPoint:height(boundaryPixels));
        
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
            boundaryPixels = boundaryPixels(idxsOrdered,:);

        end
        
        function updateFlatmapHeight(obj,boundaryPixels)

            % Get the offset of boundary pixels in the flatmap.
            % (double, numBoundaryPixels x 1)
            offset = boundaryPixels.(obj.pVarNameOffset);

            % Calculate the height of the flatmap above and below the 
            % center line.
            flatmapHeightTop    =    max(offset);
            flatmapHeightBottom = -1*min(offset);

            % Update the height of the flatmap.
            if flatmapHeightTop > obj.pFlatmapHeightTop
                obj.pFlatmapHeightTop = flatmapHeightTop;
            end            
            if flatmapHeightBottom > obj.pFlatmapHeightBottom
                obj.pFlatmapHeightBottom = flatmapHeightBottom;
            end

        end

        % Create flatmaps.

        function flatmap = createFlatmapLabel(obj,labelIdsToRemove)

            % Initialize a flatmap. (uint8, M x numValidSlices)
            flatmap = obj.initFlatmap("uint8",1);

            for i = 1:obj.pNumSagittalSlices

                % Get the boundary pixels on the sagittal slice.
                % (table, numBoundaryPixels x 4) or []
                boundaryPixels = obj.pBoundaryPixelsCell{i};

                if isempty(boundaryPixels)
                    continue;
                end

                % Get the label IDs. (double, numBoundaryPixels x 1)
                valuesToInsert = boundaryPixels.(obj.pVarNameLabelId);

                % Replace the values of pixels with the label ID to be 
                % removed with the background label ID.
                valuesToInsert = obj.replaceValuesWithBackground( ...
                    valuesToInsert, ...
                    boundaryPixels, ...
                    labelIdsToRemove ...
                );

                % Insert the values to the flatmap.
                flatmap = obj.insertValuesToFlatmap( ...
                    flatmap, ...
                    boundaryPixels, ...
                    valuesToInsert, ...
                    i ...
                );
            
            end

        end

        function flatmap = createFlatmapBorder(obj,labelIdsToRemove)

            % Initialize a flatmap. (uint8, M x numValidSlices)
            flatmap = obj.initFlatmap("uint8",1);

            for i = 1:obj.pNumSagittalSlices

                % Get the boundary pixels on the sagittal slice.
                % (table, numBoundaryPixels x 4) or []
                boundaryPixels = obj.pBoundaryPixelsCell{i};

                if isempty(boundaryPixels)
                    continue;
                end

                % Calculate the values based on the border information. 
                % (double, numBoundaryPixels x 1)
                valuesToInsert = obj.calcValuesBorder(boundaryPixels);

                % Replace the values of pixels with the label ID to be 
                % removed with the background label ID.
                valuesToInsert = obj.replaceValuesWithBackground( ...
                    valuesToInsert, ...
                    boundaryPixels, ...
                    labelIdsToRemove ...
                );

                % Insert the values to the flatmap.
                flatmap = obj.insertValuesToFlatmap( ...
                    flatmap, ...
                    boundaryPixels, ...
                    valuesToInsert, ...
                    i ...
                );
            
            end

        end

        function values = calcValuesBorder(obj,boundaryPixels)
            %
            % Calculate the values on the flatmap for each boundary pixel
            % based on the border information.
            %

            numBoundaryPixels = height(boundaryPixels);

            % Initialize a logical array that indicates whether each pixel 
            % is a border pixel between two different labels.
            % (logical, numBoundaryPixels x 1)
            isBorder = false(numBoundaryPixels,1);

            for i = 1:numBoundaryPixels

                % Get the label ID. (double, 1 x 1)
                labelId = boundaryPixels{i,obj.pVarNameLabelId};

                % Consider the first and last pixels as border pixels.
                if i == 1 || i == numBoundaryPixels

                    isBorder(i) = true;

                    labelIdPrevious = labelId;

                    continue;

                end

                if labelId == labelIdPrevious
                    continue;
                end

                % Two pixels with different labels that are adjacent to
                % each other are considered border pixels.
                isBorder(i)   = true;
                isBorder(i-1) = true;

                labelIdPrevious = labelId;

            end

            % Assign the border label ID to the border pixels and the
            % background label ID to all other pixels.
            values = repmat(obj.pLabelIdBackground,[numBoundaryPixels,1]);
            values(isBorder) = obj.pLabelIdBorder;

        end

        function flatmap = createFlatmapCurvature(obj,labelIdsToRemove)

            % Initialize a flatmap. (uint8, M x numValidSlices)
            flatmap = obj.initFlatmap("uint8",1);

            for i = 1:obj.pNumSagittalSlices

                % Get the boundary pixels on the sagittal slice.
                % (table, numBoundaryPixels x 4) or []
                boundaryPixels = obj.pBoundaryPixelsCell{i};

                if isempty(boundaryPixels)
                    continue;
                end

                % Calculate the values based on the curvature information. 
                % (double, numBoundaryPixels x 1)
                valuesToInsert = obj.calcValuesCurvature(boundaryPixels);

                % Replace the values of pixels with the label ID to be 
                % removed with the background label ID.
                valuesToInsert = obj.replaceValuesWithBackground( ...
                    valuesToInsert, ...
                    boundaryPixels, ...
                    labelIdsToRemove ...
                );

                % Insert the values to the flatmap.
                flatmap = obj.insertValuesToFlatmap( ...
                    flatmap, ...
                    boundaryPixels, ...
                    valuesToInsert, ...
                    i ...
                );
            
            end

        end

        function values = calcValuesCurvature(obj,boundaryPixels)
            %
            % Calculate the values based on curvature of each boundary
            % point for the curvature map. Assign a label ID of 2 to points
            % with negative curvature, a label ID of 3 to points with
            % positive curvature, and a label ID of 1 to points with zero
            % curvature (inflection points).
            %

            numBoundaryPixels = height(boundaryPixels);

            % Calculate the curvature at each point on the boundary.
            % (double, numBoundaryPixels x 1)
            curvatures = obj.calcCurvature2D(boundaryPixels);

            % Assign label IDs based on the curvature's sign.
            % (double, numBoundaryPixels x 1)
            values = repmat(obj.pLabelIdInflectionPoint,[numBoundaryPixels,1]);
            values(curvatures < 0) = obj.pLabelIdConcave;
            values(curvatures > 0) = obj.pLabelIdConvex;

        end

        function curvatures = calcCurvature2D(obj,boundaryPixels)

            % Get the column and row coordinates of each boundary pixel. 
            % (double, numBoundaryPixels x 1)
            cs = boundaryPixels.(obj.pVarNameColumn);
            rs = boundaryPixels.(obj.pVarNameRow);
            
            % Calculate the first and second gradients.
            dc  = gradient(cs);
            d2c = gradient(dc);
            dr  = gradient(rs);
            d2r = gradient(dr);
            
            % Calculate the curvature at each point on the boundary curve.
            curvatures = (dc.*d2r - dr.*d2c) ./ ((dc.^2 + dr.^2).^(3/2));
        
        end

        function flatmap = createFlatmapIntensity(obj, ...
                labelIdsToRemove, ...
                intensityVolume ...
            )

            % Initialize a flatmap. (double, M x numValidSlices)
            flatmap = obj.initFlatmap("double",1);

            for i = 1:obj.pNumSagittalSlices

                % Get the boundary pixels on the sagittal slice.
                % (table, numBoundaryPixels x 4) or []
                boundaryPixels = obj.pBoundaryPixelsCell{i};

                if isempty(boundaryPixels)
                    continue;
                end

                % Get intensity values of each boundary point.
                % (double, numBoundaryPixels x 1)
                valuesToInsert = obj.getValuesIntensity( ...
                    intensityVolume, ...
                    boundaryPixels, ...
                    i ...
                );

                % Replace the values of pixels with the label ID to be 
                % removed with the background label ID.
                valuesToInsert = obj.replaceValuesWithBackground( ...
                    valuesToInsert, ...
                    boundaryPixels, ...
                    labelIdsToRemove ...
                );

                % Insert the values to the flatmap.
                flatmap = obj.insertValuesToFlatmap( ...
                    flatmap, ...
                    boundaryPixels, ...
                    valuesToInsert, ...
                    i ...
                );
            
            end

        end

        function values = getValuesIntensity(obj, ...
                intensityVolume, ...
                boundaryPixels, ...
                sliceIndex ...
            )
            %
            % Return the intensity at each boundary pixel based on the
            % volumetric data containing intensity values for each voxel,
            % aligned with the volumetric data containing labels.
            %

            numBoundaryPixels = height(boundaryPixels);

            % Initialize the output. (double, numBoundaryPixels x 1)
            values = zeros(numBoundaryPixels,1);
           
            for i = 1:numBoundaryPixels

                % Get the column and row coordinates of the boundary pixel. 
                % (double, 1 x 1)
                c = boundaryPixels{i,obj.pVarNameColumn};
                r = boundaryPixels{i,obj.pVarNameRow};

                % Convert the indices on the 2D slice into indices in the 
                % 3D volume based on the sagittal dimension number.
                switch obj.pDimNumSagittal
                    case 1; yidx = sliceIndex; xidx = r; zidx = c;
                    case 2; yidx = r; xidx = sliceIndex; zidx = c;
                    case 3; yidx = r; xidx = c; zidx = sliceIndex;
                end

                % Store the intensity of the boundary pixel.
                values(i) = intensityVolume(yidx,xidx,zidx);

            end

        end

        function flatmap = createFlatmapCoordinate(obj,labelIdsToRemove)

            % Initialize a flatmap. (uint8, M x numValidSlices x 2)
            flatmap = obj.initFlatmap("uint8",2);

            for i = 1:obj.pNumSagittalSlices

                % Get the boundary pixels on the sagittal slice.
                % (table, numBoundaryPixels x 4) or []
                boundaryPixels = obj.pBoundaryPixelsCell{i};

                if isempty(boundaryPixels)
                    continue;
                end

                % Get the row and column coordinates of each boundary point
                % on the sagittal slice. (double, numBoundaryPixels x 1 x RC)
                valuesToInsert = obj.getValuesCoordinate(boundaryPixels);

                % Replace the values of pixels with the label ID to be 
                % removed with the background label ID.
                valuesToInsert = obj.replaceValuesWithBackground( ...
                    valuesToInsert, ...
                    boundaryPixels, ...
                    labelIdsToRemove ...
                );

                % Insert the values to the flatmap.
                % (uint8, M x numValidSlices x RC)
                flatmap = obj.insertValuesToFlatmap( ...
                    flatmap, ...
                    boundaryPixels, ...
                    valuesToInsert, ...
                    i ...
                );
            
            end

        end

        function values = getValuesCoordinate(obj,boundaryPixels)

            % Get the row and column coordinates of the boundary pixels on
            % the sagittal slice. (double, numBoundaryPixels x RC)
            coordinates = boundaryPixels{:,[obj.pVarNameRow,obj.pVarNameColumn]};

            % Rearrange the dimensions. (double, numBoundaryPixels x 1 x RC)
            values = permute(coordinates,[1,3,2]);

        end

        function flatmap = initFlatmap(obj,precision,numChannels)

            % Calculate the height of the flatmap.
            flatmapHeight = obj.pFlatmapHeightTop + obj.pFlatmapHeightBottom;

            % Initialize a flatmap. (numeric, M x numValidSlices x numChannels)
            flatmap = zeros( ...
                [flatmapHeight,obj.pNumValidSlices,numChannels], ...
                precision ...
            );

        end

        function values = replaceValuesWithBackground(obj, ...
                values, ...
                boundaryPixels, ...
                labelIdsToRemove ...
            )

            if isempty(labelIdsToRemove)
                return;
            end

            % Get the indices of the pixels with the label ID to be removed.
            % (logical, numBoundaryPixels x 1)
            idxsToReplace = arrayfun( ...
                @(x)any(x == labelIdsToRemove), ...
                boundaryPixels.(obj.pVarNameLabelId) ...
            );

            % Replace the values with the background label ID.
            values(idxsToReplace,:,:) = obj.pLabelIdBackground;

        end

        function flatmap = insertValuesToFlatmap(obj, ...
                flatmap, ...
                boundaryPixels, ...
                valuesToInsert, ...
                sliceIndex ...
            )

            % Get the offset of each boundary pixel from the origin point
            % on the flatmap. (double, numBoundaryPixels x 1)
            offset = boundaryPixels.(obj.pVarNameOffset);

            % Calculate the coordinates (m: vertical axis, n: horizontal
            % axis) on the flatmap for each boundary pixel.
            [n,ms] = obj.calcCoordinatesOnFlatmap(offset,sliceIndex);

            % Insert the values into the flatmap.
            flatmap(ms,n,:) = valuesToInsert;

        end

        function [n,ms] = calcCoordinatesOnFlatmap(obj,offset,sliceIndex)

            % Calculate the vertical axis coordinates on the flatmap for
            % each boundary pixel based on their offset. 
            % (double, numBoundaryPixels x 1)
            ms = offset + obj.pFlatmapHeightBottom + 1;

            % Calculate the horizontal axis coordinates on the flatmap
            % based on the sagittal slice index. (double, 1 x 1)
            n = sliceIndex - obj.pIndexValidSliceStart + 1;

        end

        % Map points.        

        function [binMask3dBoundary,binMask3dInterior] = createBinaryMasks3d(obj)
            %
            % Create 3D binary masks for the boundary and interior of the 
            % object within the label volume data.
            %

            % Initialize 3D binary masks. (logical, Y x X x Z)
            binMask3dBoundary = obj.initBinaryMask3d();
            binMask3dInterior = obj.initBinaryMask3d();

            % Get the size (rows and columns) of sagittal slices.
            switch obj.pDimNumSagittal
                case 1; rows = obj.pLenX; columns = obj.pLenZ;
                case 2; rows = obj.pLenY; columns = obj.pLenZ;
                case 3; rows = obj.pLenY; columns = obj.pLenX;
            end

            % Initialize a binary mask for a sagittal slice. (logical, R x C)
            binMask2d = false(rows,columns);

            for i = 1:obj.pNumSagittalSlices

                % Get the boundary pixels on the sagittal slice.
                % (table, numBoundaryPixels x 4) or []
                boundaryPixels = obj.pBoundaryPixelsCell{i};

                if isempty(boundaryPixels)
                    continue;
                end

                % Get linear indices of each boundary pixel.
                % (double, numBoundaryPixels x 1)
                idxsBoundary = sub2ind( ...
                    [rows,columns], ...
                    boundaryPixels.(obj.pVarNameRow), ...
                    boundaryPixels.(obj.pVarNameColumn) ...
                );

                binMask2dBoundary = binMask2d;

                % Assign True to the boundary pixels.
                binMask2dBoundary(idxsBoundary) = true;                

                % Get the index within the label volume data for the
                % sagittal slice.
                [idxsY,idxsX,idxsZ] = obj.getSagittalSliceIndices(i);

                % Insert the 2D binary mask into the 3D binary mask.
                binMask3dBoundary(idxsY,idxsX,idxsZ) = binMask2dBoundary;

                % Fill the region inside the boundary.
                binMask2dBoundary = imfill(binMask2dBoundary,'holes');

                % Insert the 2D binary mask into the 3D binary mask.
                binMask3dInterior(idxsY,idxsX,idxsZ) = binMask2dBoundary;

            end

        end

        function binaryMask3d = initBinaryMask3d(obj)

            % Create a 3D binary mask of the same size as the label volume 
            % data. (logical, Y x X x Z)
            binaryMask3d = false(obj.getLabelVolumeSize());

        end

        function size = getLabelVolumeSize(obj)

            % Return the size of the label volume. (double, 1 x 3)
            size = [obj.pLenY,obj.pLenX,obj.pLenZ];

        end

        function [yn,xn,zn] = findNearestBoundaryVoxel(obj,binMask3dBoundary,x,y,z)

            % Get linear indices of boundary voxels in the neighborhood
            % of the specified point. (double, numBoundaryVoxels x 1)
            idxsBoundaryVoxelsNeighbor = obj.findNeighborBoundaryVoxels( ...
                binMask3dBoundary, ...
                x,y,z ...
            );        

            % Number of neighbor boundary voxels.
            numBoundaryVoxels = numel(idxsBoundaryVoxelsNeighbor);
        
            % Initialize an array to store squared distances from the 
            % source point to each boundary voxel.
            % (double, numBoundaryVoxels x 1)
            distSquared = zeros(numBoundaryVoxels,1);
        
            for i = 1:numBoundaryVoxels
        
                % Convert the linear index of the current boundary voxel to
                % xyz coordinates.
                [yb,xb,zb] = ind2sub( ...
                    obj.getLabelVolumeSize(), ...
                    idxsBoundaryVoxelsNeighbor(i) ...
                );
        
                % Calculate the distance between the two points.
                distSquared(i) = (x-xb)^2 + (y-yb)^2 + (z-zb)^2;
        
            end
        
            % Find the index of the nearest boundary voxel.
            [~,idxMin] = min(distSquared);
        
            % Linear index of the nearest boundary voxel.
            idxBoundaryVoxelNearest = idxsBoundaryVoxelsNeighbor(idxMin);
            
            % Convert the linear index to xyz coordinates in the volume.
            [yn,xn,zn] = ind2sub(obj.getLabelVolumeSize(),idxBoundaryVoxelNearest);

        end

        function idxsBoundaryVoxelsNeighbor = findNeighborBoundaryVoxels(obj, ...
                binMask3dBoundary, ...
                x,y,z ...
            )
            %
            % Find boundary voxels in the neighborhood of the point by 
            % incrementing the searching radius.
            %

            % Initialize a serching radius.
            radiusCurrent = obj.pRadiusInit;
        
            while true

                % Get coordinates of voxels inside a sphere of the radius.
                % (double, numVoxelsInSphere x XYZ)
                xyzInUnitSphere = obj.getCoordinatesInUnitSphere(radiusCurrent);

                % Create a mask of the sphere centered at the specified
                % point. (logical, Y x X x Z)
                binaryMask3dSphere = obj.createBinaryMasks3dShpere( ...
                    xyzInUnitSphere, ...
                    x,y,z ...
                );
            
                % Get logical indices of boundary voxels inside the sphere.
                % (logical, Y x X x Z)
                binMask3dBoundaryInSphere = binMask3dBoundary & binaryMask3dSphere;
                    
                % Complete the search if any boundary voxel is found within
                % the sphere.
                if sum(binMask3dBoundaryInSphere,"all") ~= 0
                    break;
                end
        
                % Increment the radius.
                radiusCurrent = radiusCurrent + obj.pRadiusDelta;      
        
            end
        
            % Get linear indices of the boundary voxels inside the sphere.
            % (double, numBoundaryVoxels x 1)
            idxsBoundaryVoxelsNeighbor = find(binMask3dBoundaryInSphere);

        end

        function xyz = getCoordinatesInUnitSphere(obj,radius)
            %
            % Return the coordinates of voxels inside a sphere of the 
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

                % Calculate the coordinates of voxels inside a sphere of
                % the radius, centered at (x,y,z) = (0,0,0).
                xyz = obj.calcCoordinatesInSphere(radius);

                % Initialize a table to store the coordinates for the 
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
            % Return the coordinates of voxels inside a sphere with a
            % specified radius, centered at (x,y,z) = (0,0,0).
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

        function binaryMask3dSphere = createBinaryMasks3dShpere(obj, ...
                xyzInUnitSphere, ...
                xCenter,yCenter,zCenter ...
            )

            % Initialize the output mask. (logical, Y x X x Z)
            binaryMask3dSphere = obj.initBinaryMask3d();            
    
            % Shift all coordinates inside the unit sphere so that the 
            % center of the sphere is located at the specified point.
            x = xyzInUnitSphere(:,1) + xCenter;
            y = xyzInUnitSphere(:,2) + yCenter;
            z = xyzInUnitSphere(:,3) + zCenter;
    
            % Get logical indices of voxels inside the sphere that locate 
            % outside the cuboid.
            idxOutOfCuboid = x < 1 | x > obj.pLenX | ...
                             y < 1 | y > obj.pLenY | ...
                             z < 1 | z > obj.pLenZ;
    
            % Remove the voxels outside the cuboid.
            x = x(~idxOutOfCuboid);
            y = y(~idxOutOfCuboid);
            z = z(~idxOutOfCuboid);

            % Convert the voxel indices to linear indices in the volume.
            idxs = sub2ind(obj.getLabelVolumeSize(),y,x,z);   
        
            % Assign True to the voxels inside the sphere.
            binaryMask3dSphere(idxs) = true;        

        end   

        % Print messages.

        function printMsg(~,verbose,format,varargin)

            if ~verbose
                return;
            end

            % Print the message.
            fprintf(format,varargin{:});

        end

        % Validations.

        function validateParsingDone(obj)

            if isempty(obj.pBoundaryPixelsCell)
                error("Run parse() first.");
            end

        end

        function xyzSource = validateSourcePoints(obj,xyzSource)

            % Validate the coordinates of source points.
            Validator.mustBeGreaterThanOrEqual(xyzSource,0.5);
            Validator.mustBeNumCols(xyzSource,3);

            % Convert the spatial coorinates to pixel indices.
            xyzSource = round(xyzSource);

            % Validate the indices are within the volume data.
            if max(xyzSource(:,1)) > obj.pLenX || ...
               max(xyzSource(:,2)) > obj.pLenY || ...
               max(xyzSource(:,3)) > obj.pLenZ
                error( ...
                    "The x, y, z coordinates of source points must be less " + ...
                    "than %.1f, %.1f, %.1f, respectively.", ...
                    obj.pLenX + 0.5, ...
                    obj.pLenY + 0.5, ...
                    obj.pLenZ + 0.5 ...
                );
            end

        end

        function validateLabelIdsToRemove(obj,labelIdsToRemove)

            % Validate the label IDs to be removed.
            if ~isempty(labelIdsToRemove)
                Validator.mustBePosInteger(labelIdsToRemove);
            end

        end

    end
    
end