classdef FlatmapGenerator < ClassVersion
    %
    % This class generates 2D flatmaps from a 3D NIfTI label volume, where
    % each voxel holds an integer index.
    %
    % User Data Preparation:
    %   1) Provide a 3D NIfTI label volume, labelVolume, containing integer
    %      indices.
    %   2) Define an incision line on the object surface by assigning a
    %      dedicated incision label to those voxels. This specifies where
    %      the surface will be cut open.
    %   3) Define an origin line on the object surface by assigning a
    %      dedicated origin label to those voxels. This specifies the
    %      reference point for alignment.
    %   4) Ensure that each sagittal slice contains at most one object with
    %      exactly one incision point and one origin point on its contour
    %      line. To flatten multiple objects as one, use a bridge label to
    %      connect them into a single closed contour. Any disconnected
    %      objects lacking both an incision and an origin label will be
    %      ignored and excluded from the flatmap.
    %
    % Algorithm:
    %   1) Extract the object's surface voxels for each sagittal slice.
    %   2) For each slice, cut the surface voxel sequence at the incision
    %      point and unroll it into a 1D line.
    %   3) Align these 1D surface lines across slices using the origin
    %      point.
    %

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
    %   4.0 - 20250524 a) Removed the parse() method; contour pixel
    %                     extraction is now performed in the constructor. 
    %                  b) Renamed showBoundaries() to showContours(), and
    %                     updated the figure axes to use world-space units. 
    %                  c) Renamed getCoordinateFlatmap() to
    %                     createCoordinateFlatmap(), and updated the output
    %                     to provide world-space Y and Z coordinates
    %                     instead of pixel indices on the sagittal slice.
    %                  c) createCurvatureFlatmap() now creates a flatmap
    %                     that stores curvature values directly, rather
    %                     than assigning labels based on curvature sign.
    %                  d) Renamed mapPoints() to mapWorldPointsToFlatmap(),
    %                     and updated the function to map arbitrary point
    %                     coordinates in world space (X, Y, Z) instead of
    %                     voxel-space indices (j, j, k). Also changed the
    %                     input and output format from a (numPoints × 3)
    %                     array to separate arrays for each axis, allowing
    %                     arbitrary input sizes. Additionally, the
    %                     nearest-neighbor search algorithm was improved.
    %                  e) Previously, createIntensityFlatmap() only
    %                     accepted intensity NIfTI data with the same voxel
    %                     array size as the label volume. It now supports
    %                     arbitrary NIfTI data. However, meaningful mapping
    %                     requires that the label and intensity data be
    %                     properly aligned in world space.
    %                  f) Flatmaps with discrete values (e.g., label
    %                     indices) use uint8 arrays, while those with
    %                     continuous values (e.g., intensity) use double
    %                     arrays filled with NaNs.
    %                  g) Fixed a bug in the flatmap width calculation.
    %                  h) Renamed getIndexValidSliceStart() to
    %                     getSampleIdxXFirst().
    %                  i) Added getSamplesX().

    properties (Constant)

        % Version of the class definition.
        cClassVersion = 4.0;

        % Method names for creating each type of flatmap.
        cMethodNameCreateLabelFlatmap     = "createLabelFlatmap";
        cMethodNameCreateBorderFlatmap    = "createBorderFlatmap";
        cMethodNameCreateCurvatureFlatmap = "createCurvatureFlatmap";
        cMethodNameCreateIntensityFlatmap = "createIntensityFlatmap";
    
    end

    properties (Access = private)

        % Label volume data.
        pLabelVolumeData

        % Metadata for the label volume data.
        pLabelVolumeInfo

        % affine3d transform mapping voxel coordinates to world space.       
        pVoxelToWorldTransform

        % Coordinates of sampling points in world space.
        pSamplesX
        pSamplesY
        pSamplesZ

        % Number of sampling points along each axis.
        pNumSamplesX
        pNumSamplesY
        pNumSamplesZ

        % 2D coordinate grids for the Y and Z sampling points.
        pSamplesYZGridY
        pSamplesYZGridZ

        % Size of the sampling grid.
        pSamplesYZGridSize
        pSamplesXYZGridSize       

        % A cell to store contour pixels on each sagittal slice.
        pContourPixelsCell

        % Index of the first and last valid X-axis sampling point in world
        % space where a target object exists on the sagittal slice.
        pSampleIdxXFirst
        pSampleIdxXLast

        % Label IDs in the volume.
        pLabelIdIncision % Incision points
        pLabelIdOrigin   % Origin points

        % Predefined label IDs.
        pLabelIdBackground = 0;
        pLabelIdBorder     = 1;  

        % Size of the flatmap.
        pFlatmapHeightTop    = 0;
        pFlatmapHeightBottom = 0;

        % Flatmap value type name.
        pValueTypeNameDiscrete   = "discrete";
        pValueTypeNameContinuous = "continuous";

        % A MatlabColor handle.
        hMatlabColor
        
        % Variable names for the contour pixels table.
        pVarNameSampleIdxY = "sampleIdxY";
        pVarNameSampleIdxZ = "sampleIdxZ";
        pVarNameLabelId    = "labelId";
        pVarNameOffset     = "offset";       
        
    end

    methods (Access = public)
        
        % Constructor.
        
        function obj = FlatmapGenerator( ...
                labelVolumePath, ...
                labelIdIncision, ...
                labelIdOrigin, ...
                verboseSliceParsing ...
            )
            %
            % <Input>
            %   labelVolumePath: (text, 1 x 1)
            %       A single NIfTI image file path. Each voxel value must
            %       be a label ID (integer). Both NIfTI1 and NIfTI2 formats
            %       are supported.
            %   labelIdIncision: (integer, 1 x 1)
            %       The label ID used for the incision point.
            %   labelIdOrigin: (integer, 1 x 1)
            %       The label ID used for the origin point.
            % OPTIONS
            %   verboseSliceParsing: (logical, 1 x 1)
            %       If true, display messages in the command window during
            %       slice parsing, such as skipped slices or detected
            %       objects.
            %

            arguments
                labelVolumePath     {Validator.mustBeTextScalar}
                labelIdIncision     {Validator.mustBeIntegerScalar}
                labelIdOrigin       {Validator.mustBeIntegerScalar}
                verboseSliceParsing {Validator.mustBeLogicalScalar} = true;
            end
            
            % Store label volume metadata and data.
            obj.pLabelVolumeInfo = niftiinfo(labelVolumePath);
            obj.pLabelVolumeData = niftiread(obj.pLabelVolumeInfo);

            % Store the affine3d transform mapping voxel coordinates to
            % world (scanner) space.           
            obj.pVoxelToWorldTransform = obj.pLabelVolumeInfo.Transform;

            % Compute the coordinates of sampling points in world space.
            % (double, 1 x numSamples)
            [obj.pSamplesX,obj.pSamplesY,obj.pSamplesZ] = ...
                obj.calcWorldSamplingPoints();

            % Store the number of sampling points along each axis.
            obj.pNumSamplesX = numel(obj.pSamplesX);
            obj.pNumSamplesY = numel(obj.pSamplesY);
            obj.pNumSamplesZ = numel(obj.pSamplesZ);

            % Store the sampling grid size.
            obj.pSamplesYZGridSize = [
                obj.pNumSamplesY, ...
                obj.pNumSamplesZ
            ];
            obj.pSamplesXYZGridSize = [
                obj.pNumSamplesX, ...
                obj.pNumSamplesY, ...
                obj.pNumSamplesZ
            ];

            % Generate 2D coordinate grids for the Y and Z sampling points
            % in world space. (double, numSamplesY x numSamplesZ)
            [obj.pSamplesYZGridY,obj.pSamplesYZGridZ] = ndgrid( ...
                obj.pSamplesY, ...
                obj.pSamplesZ ...
            );

            % Store user-defined label IDs.
            obj.pLabelIdIncision = labelIdIncision;
            obj.pLabelIdOrigin   = labelIdOrigin;

            % Create and store a MatlabColor handle.
            obj.hMatlabColor = MatlabColor();

            % Extract and store contour pixels from each sagittal slice.
            % (cell, numSagittalSlices x 1) < (table, numContourPixels x 4)
            obj.pContourPixelsCell = obj.extractContourPixels( ...
                verboseSliceParsing ...
            );

        end

        function showContours(obj,options)
            %
            % Show contours on each sagittal slice.
            %
            % <Input>
            % OPTIONS
            %   colorNameContour: (text, 1 x 1)
            %       A color name for contour lines. See plot() for the 
            %       valid color names.
            %   showAnimation: (logical, 1 x 1)
            %       Whether to animate contour display.
            %

            arguments
                obj
                options.colorNameContour {Validator.mustBeTextScalar}    = "cyan"
                options.showAnimation    {Validator.mustBeLogicalScalar} = false
            end

            colorNameContour = options.colorNameContour;
            showAnimation    = options.showAnimation;

            % Validate the color name. (string, 1 x 1)
            colorNameContour = obj.hMatlabColor.validateColorNames( ...
                colorNameContour ...
            );

            % Show contours on each sagittal slice.
            obj.showContoursImpl(showAnimation,colorNameContour);

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
            %   flatmap: (uint8, M x N)
            %       Resulting label flatmap.
            %

            arguments
                obj {}
                options.labelIdsToRemove {} = []
            end

            labelIdsToRemove = options.labelIdsToRemove;

            % Validate the label IDs to be removed.
            obj.validateLabelIdsToRemove(labelIdsToRemove);

            % Create a label flatmap. (uint8, M x N)
            flatmap = obj.createLabelFlatmapImpl(labelIdsToRemove);            
            
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
            %   flatmap: (uint8, M x N)
            %       Resulting border flatmap.
            %

            arguments
                obj {}
                options.labelIdsToRemove {} = []
            end

            labelIdsToRemove = options.labelIdsToRemove;

            % Validate the label IDs to be removed.
            obj.validateLabelIdsToRemove(labelIdsToRemove);

            % Create a border flatmap. (uint8, M x N)
            flatmap = obj.createBorderFlatmapImpl(labelIdsToRemove);            

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
            %   flatmap: (double, M x N)
            %       Resulting curvature flatmap.
            %

            arguments
                obj {}
                options.labelIdsToRemove {} = []
            end

            labelIdsToRemove = options.labelIdsToRemove;

            % Validate the label IDs to be removed.
            obj.validateLabelIdsToRemove(labelIdsToRemove);

            % Create a curvature flatmap. (double, M x N)
            flatmap = obj.createCurvatureFlatmapImpl(labelIdsToRemove);

        end

        function flatmap = createCoordinateFlatmap(obj,options)
            %
            % Create a flatmap where each pixel stores its Y and Z
            % coordinates in world space.
            %
            % <Input>
            % OPTIONS
            %   labelIdsToRemove: (numeric, M x N)
            %       See createLabelFlatmap().
            %
            % <Output>
            %   flatmap: (double, M x N x YZ)
            %       A flatmap where each pixel (corresponding to a contour
            %       pixel) stores its Y and Z coordinates in world space.
            %       The first channel stores Y coordinates, and the second
            %       channel stores Z coordinates.
            %

            arguments
                obj {}
                options.labelIdsToRemove {} = []           
            end

            labelIdsToRemove = options.labelIdsToRemove;

            % Validate the label IDs to be removed.
            obj.validateLabelIdsToRemove(labelIdsToRemove);

            % Create a coordinate flatmap. (double, M x N x YZ)
            flatmap = obj.createCoordinateFlatmapImpl(labelIdsToRemove);

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
            %   flatmap: (double, M x N)
            %       Resulting intensity flatmap.
            %

            arguments
                obj {}
                intensityVolumePath {Validator.mustBeTextScalar}
                options.labelIdsToRemove {} = []           
            end

            labelIdsToRemove = options.labelIdsToRemove;

            % Validate the label IDs to be removed.
            obj.validateLabelIdsToRemove(labelIdsToRemove);

            % Create a intensity flatmap. (double, M x N)
            flatmap = obj.createIntensityFlatmapImpl( ...
                labelIdsToRemove, ...
                intensityVolumePath ...
            );

        end

        function [flatRows,flatColumns] = mapWorldPointsToFlatmap(obj, ...
                queryWorldXs, ...
                queryWorldYs, ...
                queryWorldZs, ...
                verbose ...
            )
            %
            % Map arbitrary point clouds in world space (X, Y, Z) onto the
            % flatmap.
            %
            % <Input>
            %   queryWorldXs, queryWorldYs, queryWorldZs: (numeric, M x N)
            %       World-space (X, Y, Z) coordinates of arbitrary points.
            %       Points outside the object used for flatmap generation
            %       are ignored.
            % OPTIONS
            %   verbose: (logical, 1 x 1)
            %       Whether to show skipped points in the Command Window.
            %
            % <Output>
            %   flatRows, flatColumns: (double, M x N)
            %       Flatmap row and column indices corresponding to each
            %       query point. For points outside the object that could
            %       not be mapped, NaN is assigned.

            arguments
                obj
                queryWorldXs {Validator.mustBeNumeric}
                queryWorldYs {Validator.mustBeNumeric}
                queryWorldZs {Validator.mustBeNumeric}
                verbose {Validator.mustBeLogicalScalar} = true;
            end

            % Validate that the X, Y, and Z coordinate arrays have the same
            % size.
            Validator.mustBeSameSize(queryWorldXs,queryWorldYs);
            Validator.mustBeSameSize(queryWorldXs,queryWorldZs);

            % Compute the row and column indices on the flatmap
            % corresponding to the given point cloud in world space.
            % (double, M x N)
            [flatRows,flatColumns] = obj.mapWorldPointsToFlatmapImpl( ...
                queryWorldXs, ...
                queryWorldYs, ...
                queryWorldZs, ...
                verbose ...
            );            

        end

        function sampleIdxXFirst = getSampleIdxXFirst(obj)

            % Return the index of the first valid X-axis sampling point in
            % world space where a target object exists on the sagittal
            % slice.
            sampleIdxXFirst = obj.pSampleIdxXFirst;

        end

        function samplesX = getSamplesX(obj)

            % Return the coordinates of the sampling points along the
            % X-axis in world space. (double, 1 x numSamples)
            samplesX = obj.pSamplesX;

        end

    end

    methods (Access = private)

        % Create sampling points.

        function [samplesX,samplesY,samplesZ] = calcWorldSamplingPoints(obj)
            %
            % Compute the coordinates of sampling points in world space.
            %
    
            % Transform voxel corner at (1,1,1) to world space.
            [xMin,yMin,zMin] = transformPointsForward( ...
                obj.pVoxelToWorldTransform, ...
                1,1,1 ...
            );
    
            % Transform opposite corner at (I,J,K) to world space.
            [xMax,yMax,zMax] = transformPointsForward( ...
                obj.pVoxelToWorldTransform, ...
                obj.pLabelVolumeInfo.ImageSize(1), ...
                obj.pLabelVolumeInfo.ImageSize(2), ...
                obj.pLabelVolumeInfo.ImageSize(3) ...
            );
    
            % Sampling step sizes in world units.
            xStep = obj.pLabelVolumeInfo.PixelDimensions(1);
            yStep = obj.pLabelVolumeInfo.PixelDimensions(2);
            zStep = obj.pLabelVolumeInfo.PixelDimensions(3);
    
            % Generate world-space sampling vectors. (double, 1 x numSamples)
            samplesX = xMin:xStep:xMax;
            samplesY = yMin:yStep:yMax;
            samplesZ = zMin:zStep:zMax;

        end
        
        % Extract contour pixels.

        function contourPixelsCell = extractContourPixels(obj,verbose)
            %
            % Extract contour pixels from each sagittal slice.
            %
            
            % Initialize a cell to store contour pixels on each sagittal
            % slice. (cell, numSamplesX x 1)
            contourPixelsCell = cell(obj.pNumSamplesX,1);

            obj.printMsg(verbose, ...
                "* Extracting contour pixels from each sagittal slice...\n" ...
            );

            for sampleIdxX = 1:obj.pNumSamplesX

                obj.printMsg(verbose,"\n  Slice #%d:\n",sampleIdxX);

                % Get the contour pixels on the sagittal slice.
                % (table, numContourPixels x 4) or []
                contourPixels = obj.extractContourPixelsEach(sampleIdxX,verbose);

                if isempty(contourPixels)
                    continue;
                end

                % Store the first index of X-axis sampling points
                % containing the object for flat mapping.
                if isempty(obj.pSampleIdxXFirst)
                    obj.pSampleIdxXFirst = sampleIdxX;
                end

                % Update the last index of X-axis sampling points
                % containing the object for flat mapping.
                obj.pSampleIdxXLast = sampleIdxX;

                % Update the height of the flatmap.
                obj.updateFlatmapHeight(contourPixels);                

                % Store the contour pixels in the cell.
                % (cell, numSagittalSlices x 1) < (table, numContourPixels x 4)
                contourPixelsCell{sampleIdxX} = contourPixels;
            
            end

        end

        function contourPixels = extractContourPixelsEach(obj,sampleIdxX,verbose)
            %
            % Return a table containing the contour pixel indices,
            % corresponding label IDs, and their offsets from the origin on
            % the flatmap for the specified sagittal slice. If the slice
            % does not contain a target object, return an empty array ([]).
            %
            % <Output>
            %   contourPixels: (table, numContourPixels x 4) or []
            %       sampleIdxY, sampleIdxZ: (uint16, 1 x 1)
            %           Indices of contour pixels on the sagittal slice.
            %           sampleIdxY corresponds to Y-axis sampling points
            %           (rows) in world coordinates. sampleIdxZ corresponds
            %           to Z-axis sampling points (columns) in world
            %           coordinates.
            %       labelId: (uint8, 1 x 1)
            %           The label IDs of each each contour pixel.
            %       offset: (int16, 1 x 1)
            %           The the offset of each contour pixel from the
            %           origin point on the flatmap.

            contourPixels = [];

            % Get a sagittal slice of the index.

            % Get label values at each sampling point on the sagittal slice.
            % (numeric, numSamplesY x numSamplesZ)
            sagittalSlice = obj.getSagittalSlice(sampleIdxX);

            % Get linear indices of target object pixels within the
            % sagittal slice. (double, numPixels x 1) or []
            linIdxsTargetObject = obj.getTargetObjectIndices( ...
                sagittalSlice, ...
                verbose ...
            );

            if isempty(linIdxsTargetObject)
                obj.printMsg(verbose, ...
                    "    Skipped because no objects containing both the " + ...
                    "incision point and the origin point were found.\n" ...
                );
                return;
            end

            % Create a logical mask indicating the target object's area as
            % True. (logical, numSamplesY x numSamplesZ)
            targetObjectMask = obj.createSagittalSliceMask();
            targetObjectMask(linIdxsTargetObject) = true;

            % Get pixel indices of the target object's contour. 
            % (double, numContourPixels x 2)
            contour = bwboundaries(targetObjectMask);
            contour = contour{1};           

            % NOTE:
            % 1st column:
            %   Indices of sampling points along the Y-axis on the sagittal
            %   slice.
            % 2nd column:
            %   Indices of sampling points along the Z-axis on the sagittal
            %   slice.

            numContourPixels = height(contour);

            % Initialize a table storing contour pixel indices,
            % corresponding label IDs, and their offsets from the origin on
            % the flatmap. (table, numContourPixels x 4)
            contourPixels = initTable( ...
                [ ...
                    obj.pVarNameSampleIdxY, ...
                    obj.pVarNameSampleIdxZ, ...
                    obj.pVarNameLabelId, ...
                    obj.pVarNameOffset ...
                ], ...
                numContourPixels, ...
                ["double","double","double","double"] ...
            );

            % Store the contour pixel indices in the table.
            contourPixels{:,1:2} = contour;

            % Convert Y and Z sampling indices on the sagittal slice to a
            % linear index. (double, numContourPixels x 1) 
            linIdxsContour = obj.getLinearIndicesOnSagittalSlice( ...
                contour(:,1),contour(:,2) ...
            );

            % Get the label IDs of each contour pixel.
            % (numeric, numContourPixels x 1)
            labelIdsContour = sagittalSlice(linIdxsContour);

            % Store the label IDs in the table.
            contourPixels{:,3} = labelIdsContour;

            % Sort the contour pixels with the incision point at the top.
            contourPixels = obj.sortContourPixels(contourPixels);

            % Find the contour pixels with the label of the origin point.
            % (logical, numContourPixels x 1)
            isOriginPoint = ...
                contourPixels.(obj.pVarNameLabelId) == obj.pLabelIdOrigin;

            % Get the index where the origin label appears first.
            % (double, 1 x 1)
            idxOriginPoint = find(isOriginPoint,1,'first');

            % Store the offset of each contour pixel from the origin point
            % on the flatmap. Pixels before the origin point have positive
            % values, and pixels after the origin point have negative
            % values.
            contourPixels{:,4} = -1*(1:numContourPixels)'+idxOriginPoint; % Transposed

        end

        function sagittalSlice = getSagittalSlice(obj,sampleIdxX)

            % Retrieve voxel values at specified (Y, Z) world coordinates
            % on a sagittal slice defined by an X-axis sampling index.
            % Retrieve label values corresponding to the Y and Z sampling
            % points on the sagittal slice at the specified X-axis sampling
            % point in world space. (numeric, numSamplesY x numSamplesZ)
            sagittalSlice = obj.getVoxelValuesAtWorldCoords( ...
                sampleIdxX, ...
                obj.pSamplesYZGridY, ...
                obj.pSamplesYZGridZ, ...
                obj.pLabelVolumeData, ...
                obj.pVoxelToWorldTransform ...
            );

        end

        function values = getVoxelValuesAtWorldCoords(obj, ...
                sampleIdxX, ...
                worldYs, ...
                worldZs, ...
                voxelData, ...
                voxelToWorldTransform ...
            )
            %
            % Retrieve voxel values at specified (Y, Z) world coordinates
            % on a sagittal slice defined by an X-axis sampling index.
            %

            % Validate that the Y and Z coordinate arrays are the same size.
            Validator.mustBeSameSize(worldYs,worldZs);

            % Size of the Y and Z coordinate arrays.
            coordArraySize = size(worldYs);

            % Get the value at the specified X-axis sampling point.
            x = obj.pSamplesX(sampleIdxX);

            % Get the voxel-space indices corresponding to arbitrary (Y, Z)
            % coordinates on the sagittal slice at the specified X-axis
            % sampling point. (double, M x N)
            [i,j,k] = transformPointsInverse( ...
                voxelToWorldTransform, ...
                ones(coordArraySize)*x, ...
                worldYs, ...
                worldZs ...
            );

            % Convert to linear indices.
            linIdxs = sub2ind(size(voxelData),round(i),round(j),round(k));

            % Return voxel values at each coordinate on the sagittal slice.
            % (numeric, M x N)
            values = reshape(voxelData(linIdxs),coordArraySize);

        end

        function linIdxsTargetObject = getTargetObjectIndices(obj, ...
                sagittalSlice, ...
                verbose ...
            )
            %
            % Return linear indices of target object pixels within the
            % sagittal slice.
            %

            linIdxsTargetObject = [];

            % Generate a logical mask identifying non-background pixels in
            % the sagittal slice. (logical, numSamplesY x numSamplesZ)
            objectMask = sagittalSlice ~= obj.pLabelIdBackground;

            % Return [] if there is no object.
            if sum(objectMask) == 0
                obj.printMsg(verbose,"    No object found.\n");
                return;
            end

            % Fill holes within the object.
            objectMask = imfill(objectMask,"holes");

            % Find and count connected components. (struct, 1 x 1)
            components = bwconncomp(objectMask);
        
            % Number of objects found.
            numObjects = components.NumObjects;

            obj.printMsg(verbose,"    %d object(s) found.\n",numObjects);

            numTargetObjects = 0;

            for i = 1:numObjects

                obj.printMsg(verbose,"      Object #%d: ",i);

                % Get the linear indices of the object's pixels.
                % (double, numPixels x 1)
                linIdxsObject = components.PixelIdxList{i};
        
                % Get the labels of the object. (numeric, numPixels x 1)
                labelsObject = sagittalSlice(linIdxsObject);

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
                % (double, numPixels x 1)
                linIdxsTargetObject = linIdxsObject;

                obj.printMsg(verbose,"Valid to extract contour data.\n");

                numTargetObjects = numTargetObjects + 1;

            end

            % Disallow a single slice from having multiple objects that
            % contain both the incision point and the origin point. 
            if numTargetObjects > 1
                error( ...
                    "Currently, multiple objects containing both the " + ...
                    "incision point and the origin point within a single " + ...
                    "slice are not supported." ...
                );
            end

        end

        function mask = createSagittalSliceMask(obj)

            % Create a logical mask for a sagittal slice.
            % (logical, numSamplesY x numSamplesZ) 
            mask = false(obj.pSamplesYZGridSize);

        end

        function linIdxs = getLinearIndicesOnSagittalSlice(obj, ...
                sampleIdxsY, ...
                sampleIdxsZ ...
            )

            % Convert Y and Z sampling indices on the sagittal slice to a
            % linear index. (double, numIndices x 1)
            linIdxs = sub2ind( ...
                obj.pSamplesYZGridSize, ...
                sampleIdxsY, ...
                sampleIdxsZ ...
            );

        end

        function contourPixels = sortContourPixels(obj,contourPixels)
            %
            % Sort the contour pixels with the incision point at the top.
            %

            % Find pixels that have the label of incision point.
            % (logical, numContourPixels x 1)
            isIncisionPoint = ...
                contourPixels.(obj.pVarNameLabelId) == obj.pLabelIdIncision;

            % Get the index where the incision label appears first.
            % (double, 1 x 1)
            idxIncisionPoint = find(isIncisionPoint,1,'first');
       
            % Create indices of contour pixels after the incision point.
            % (double, 1 x numPoints)
            idxsAfter = (idxIncisionPoint:height(contourPixels));
        
            % Create indices of contour pixels before the incision point.
            % (double, 1 x numPoints)
            if idxIncisionPoint == 1
                idxsBefore = [];
            else
                idxsBefore = (1:idxIncisionPoint-1);
            end
        
            % Combine the two index groups such that the indices after the 
            % incision point come before the other.
            % (double, 1 x numContourPixels)
            idxsOrdered = [idxsAfter,idxsBefore];
        
            % Sort the contour pixels by the ordered indices.
            contourPixels = contourPixels(idxsOrdered,:);

        end
        
        function updateFlatmapHeight(obj,contourPixels)

            % Get the offset of contour pixels in the flatmap.
            % (double, numContourPixels x 1)
            offset = contourPixels.(obj.pVarNameOffset);

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

        % Show contours on each sagittal slice.

        function showContoursImpl(obj,showAnimation,colorNameContour)

            % Create a figure.
            figure;
            hAxes = gca;

            if ~showAnimation
                fprintf( ...
                    "Press any key to show the next slice.\n" + ...
                    "Press Ctrl+C to quit.\n" ...
                );
            end

            for sampleIdxX = 1:obj.pNumSamplesX

                % Get label values at each sampling point on the sagittal
                % slice. (uint8, numSamplesY x numSamplesZ)
                sagittalSlice = uint8(obj.getSagittalSlice(sampleIdxX));

                % Get the current X- and Y-axis limits of the figure.
                % (double, 1 x 2)
                if sampleIdxX ~= 1
                    figureLimX = hAxes.XLim;
                    figureLimY = hAxes.YLim;
                end

                % Display the sagittal slice with actual world-space Y and
                % Z values shown on the figure's Y- and X-axes, respectively.
                imagesc(hAxes,obj.pSamplesZ,obj.pSamplesY,sagittalSlice);

                % Set the title.
                title(sprintf("Slice #%d",sampleIdxX));                

                % Restore the x and y limit.
                if sampleIdxX ~= 1
                    hAxes.XLim = figureLimX;
                    hAxes.YLim = figureLimY;
                end

                % Get the contour pixels on the sagittal slice.
                % (table, numContourPixels x 4) or []
                contourPixels = obj.pContourPixelsCell{sampleIdxX};

                if ~isempty(contourPixels)

                    % Get the Y- and Z-axis coordinates of each contour
                    % pixel. (double, numContourPixels x 1)
                    [ys,zs] = obj.getContourPixelCoordsYZ(contourPixels);
    
                    % Show the contour.
                    hold on
                    plot(hAxes,zs,ys, ...
                        'LineWidth',2, ...
                        'Color',colorNameContour ...
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

        function [ys,zs] = getContourPixelCoordsYZ(obj,contourPixels)

            % Return the Y and Z coordinates of the given contour pixels.
            % (double, numContourPixels x 1)
            ys = obj.pSamplesY(contourPixels.(obj.pVarNameSampleIdxY))'; % Transposed
            zs = obj.pSamplesZ(contourPixels.(obj.pVarNameSampleIdxZ))'; % Transposed

        end

        % Create flatmaps.

        function flatmap = createLabelFlatmapImpl(obj,labelIdsToRemove)

            % Initialize a flatmap. (uint8, M x N)
            flatmap = obj.initFlatmap(obj.pValueTypeNameDiscrete,1);

            for sampleIdxX = 1:obj.pNumSamplesX

                % Get the contour pixels on the sagittal slice.
                % (table, numContourPixels x 4) or []
                contourPixels = obj.pContourPixelsCell{sampleIdxX};

                if isempty(contourPixels)
                    continue;
                end

                % Get the label IDs. (double, numContourPixels x 1)
                valuesToInsert = contourPixels.(obj.pVarNameLabelId);

                % Replace the values of pixels with the label ID to be 
                % removed with the background label ID.
                valuesToInsert = obj.replaceValuesWithBackground( ...
                    valuesToInsert, ...
                    contourPixels, ...
                    labelIdsToRemove, ...
                    obj.pValueTypeNameDiscrete ...
                );

                % Insert the values to the flatmap.
                flatmap = obj.insertValuesToFlatmap( ...
                    flatmap, ...
                    contourPixels, ...
                    valuesToInsert, ...
                    sampleIdxX ...
                );
            
            end

        end

        function flatmap = initFlatmap(obj,valueTypeName,numChannels)

            % Calculate the size of the flatmap.
            flatmapSize = [
                obj.pFlatmapHeightTop + obj.pFlatmapHeightBottom + 1, ...
                obj.pSampleIdxXLast - obj.pSampleIdxXFirst + 1, ...
                numChannels
            ];

            % Initialize a flatmap. (numeric, M x N x numChannels)
            switch valueTypeName
                case obj.pValueTypeNameDiscrete
                    flatmap = zeros(flatmapSize,"uint8");
                case obj.pValueTypeNameContinuous
                    flatmap = nan(flatmapSize);
            end

            % NOTE:
            % Flatmaps with discrete values (e.g., label indices) use uint8
            % arrays, while those with continuous values (e.g., intensity)
            % use double arrays filled with NaNs.

        end

        function values = replaceValuesWithBackground(obj, ...
                values, ...
                contourPixels, ...
                labelIdsToRemove, ...
                valueTypeName ...
            )

            if isempty(labelIdsToRemove)
                return;
            end

            % Get the indices of the pixels with the label ID to be removed.
            % (logical, numContourPixels x 1)
            idxsToReplace = arrayfun( ...
                @(x)any(x == labelIdsToRemove), ...
                contourPixels.(obj.pVarNameLabelId) ...
            );

            switch valueTypeName
                case obj.pValueTypeNameDiscrete
                    valueToInsert = obj.pLabelIdBackground;
                case obj.pValueTypeNameContinuous
                    valueToInsert = NaN;
            end

            % Replace the values with background values.
            values(idxsToReplace,:,:) = valueToInsert;

        end

        function flatmap = insertValuesToFlatmap(obj, ...
                flatmap, ...
                contourPixels, ...
                valuesToInsert, ...
                sampleIdxX ...
            )

            % Get the offset of each contour pixel from the origin point
            % on the flatmap. (double, numContourPixels x 1)
            offset = contourPixels.(obj.pVarNameOffset);

            % Compute the row and column indices on the flatmap for each
            % contour pixel.
            [flatRows,flatColumn] = obj.calcRowAndColumnOnFlatmap( ...
                offset, ...
                sampleIdxX ...
            );

            % Insert the values into the flatmap.
            flatmap(flatRows,flatColumn,:) = valuesToInsert;

        end

        function [flatRows,flatColumn] = calcRowAndColumnOnFlatmap(obj, ...
                offset, ...
                sampleIdxX ...
            )

            % Compute the column indices on the flatmap for each contour
            % pixel based on the X-axis sampling index of the sagittal
            % slice. (double, 1 x 1)
            flatColumn = sampleIdxX - obj.pSampleIdxXFirst + 1;

            % Compute the row indices on the flatmap for each contour pixel
            % based on their offset.
            % (double, numContourPixels x 1)
            flatRows = offset + obj.pFlatmapHeightBottom + 1;

        end

        function flatmap = createBorderFlatmapImpl(obj,labelIdsToRemove)

            % Initialize a flatmap. (uint8, M x N)
            flatmap = obj.initFlatmap(obj.pValueTypeNameDiscrete,1);

            for sampleIdxX = 1:obj.pNumSamplesX

                % Get the contour pixels on the sagittal slice.
                % (table, numContourPixels x 4) or []
                contourPixels = obj.pContourPixelsCell{sampleIdxX};

                if isempty(contourPixels)
                    continue;
                end

                % Calculate the values based on the border information. 
                % (double, numContourPixels x 1)
                valuesToInsert = obj.calcValuesBorder(contourPixels);

                % Replace the values of pixels with the label ID to be 
                % removed with the background label ID.
                valuesToInsert = obj.replaceValuesWithBackground( ...
                    valuesToInsert, ...
                    contourPixels, ...
                    labelIdsToRemove, ...
                    obj.pValueTypeNameDiscrete ...
                );

                % Insert the values to the flatmap.
                flatmap = obj.insertValuesToFlatmap( ...
                    flatmap, ...
                    contourPixels, ...
                    valuesToInsert, ...
                    sampleIdxX ...
                );
            
            end

        end

        function values = calcValuesBorder(obj,contourPixels)
            %
            % Calculate the values on the flatmap for each contour pixel
            % based on the border information.
            %

            numContourPixels = height(contourPixels);

            % Initialize a logical array that indicates whether each pixel 
            % is a border pixel between two different labels.
            % (logical, numContourPixels x 1)
            isBorder = false(numContourPixels,1);

            for i = 1:numContourPixels

                % Get the label ID. (double, 1 x 1)
                labelId = contourPixels{i,obj.pVarNameLabelId};

                % Consider the first and last pixels as border pixels.
                if i == 1 || i == numContourPixels

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
            values = repmat(obj.pLabelIdBackground,[numContourPixels,1]);
            values(isBorder) = obj.pLabelIdBorder;

        end

        function flatmap = createCurvatureFlatmapImpl(obj,labelIdsToRemove)

            % Initialize a flatmap. (double, M x N)
            flatmap = obj.initFlatmap(obj.pValueTypeNameContinuous,1);

            for sampleIdxX = 1:obj.pNumSamplesX

                % Get the contour pixels on the sagittal slice.
                % (table, numContourPixels x 4) or []
                contourPixels = obj.pContourPixelsCell{sampleIdxX};

                if isempty(contourPixels)
                    continue;
                end

                % Calculate the curvature at each point on the contour.
                % (double, numContourPixels x 1)
                valuesToInsert = obj.calcCurvature2D(contourPixels);

                % Replace the values of pixels with the label ID to be 
                % removed with the background label ID.
                valuesToInsert = obj.replaceValuesWithBackground( ...
                    valuesToInsert, ...
                    contourPixels, ...
                    labelIdsToRemove, ...
                    obj.pValueTypeNameContinuous ...
                );

                % Insert the values to the flatmap.
                flatmap = obj.insertValuesToFlatmap( ...
                    flatmap, ...
                    contourPixels, ...
                    valuesToInsert, ...
                    sampleIdxX ...
                );
            
            end

        end

        function curvatures = calcCurvature2D(obj,contourPixels)

            % Get the Y- and Z-axis coordinates of each contour pixel.
            % (double, numContourPixels x 1)
            [ys,zs] = obj.getContourPixelCoordsYZ(contourPixels);
            
            % Calculate the first and second gradients.
            dz  = gradient(zs);
            d2z = gradient(dz);
            dy  = gradient(ys);
            d2y = gradient(dy);
            
            % Calculate the curvature at each point on the contour curve.
            % (double, numContourPixels x 1)
            curvatures = (dz.*d2y - dy.*d2z) ./ ((dz.^2 + dy.^2).^(3/2));
        
        end

        function flatmap = createCoordinateFlatmapImpl(obj,labelIdsToRemove)

            % Initialize a flatmap. (double, M x N x 2)
            flatmap = obj.initFlatmap(obj.pValueTypeNameContinuous,2);

            for sampleIdxX = 1:obj.pNumSamplesX

                % Get the contour pixels on the sagittal slice.
                % (table, numContourPixels x 4) or []
                contourPixels = obj.pContourPixelsCell{sampleIdxX};

                if isempty(contourPixels)
                    continue;
                end

                % Get the Y- and Z-axis coordinates of each contour pixel.
                % (double, numContourPixels x 1 x YZ)
                valuesToInsert = obj.getValuesCoordinate(contourPixels);

                % Replace the values of pixels with the label ID to be 
                % removed with the background label ID.
                valuesToInsert = obj.replaceValuesWithBackground( ...
                    valuesToInsert, ...
                    contourPixels, ...
                    labelIdsToRemove, ...
                    obj.pValueTypeNameContinuous ...
                );

                % Insert the values to the flatmap. (double, M x N x YZ)
                flatmap = obj.insertValuesToFlatmap( ...
                    flatmap, ...
                    contourPixels, ...
                    valuesToInsert, ...
                    sampleIdxX ...
                );
            
            end

        end

        function values = getValuesCoordinate(obj,contourPixels)

            % Get the Y- and Z-axis coordinates of each contour pixel.
            % (double, numContourPixels x 1) 
            [ys,zs] = obj.getContourPixelCoordsYZ(contourPixels);

            % Rearrange the dimensions. (double, numContourPixels x 1 x YZ)
            values = permute([ys,zs],[1,3,2]);

        end

        function flatmap = createIntensityFlatmapImpl(obj, ...
                labelIdsToRemove, ...
                intensityVolumePath ...
            )

            % Read intensity volume metadata and data.
            intensityVolumeInfo = niftiinfo(intensityVolumePath);
            intensityVolume = niftiread(intensityVolumeInfo);

            % Get the affine3d transform mapping voxel coordinates to
            % world (scanner) space. 
            voxelToWorldTransformIntensity = intensityVolumeInfo.Transform;

            % Initialize a flatmap. (double, M x N)
            flatmap = obj.initFlatmap(obj.pValueTypeNameContinuous,1);

            for sampleIdxX = 1:obj.pNumSamplesX

                % Get the contour pixels on the sagittal slice.
                % (table, numContourPixels x 4) or []
                contourPixels = obj.pContourPixelsCell{sampleIdxX};

                if isempty(contourPixels)
                    continue;
                end

                % Get the Y- and Z-axis coordinates of each contour pixel.
                % (double, numContourPixels x 1) 
                [ys,zs] = obj.getContourPixelCoordsYZ(contourPixels);

                % Retrieve intensity values corresponding to the Y and Z
                % coordinates of the contour pixels on the sagittal slice
                % at the specified X-axis sampling point in world space.
                % (numeric, numContourPixels x 1) 
                valuesToInsert = obj.getVoxelValuesAtWorldCoords( ...
                    sampleIdxX, ...
                    ys, ...
                    zs, ...
                    intensityVolume, ...
                    voxelToWorldTransformIntensity ...
                );

                % Replace the values of pixels with the label ID to be 
                % removed with the background label ID.
                valuesToInsert = obj.replaceValuesWithBackground( ...
                    valuesToInsert, ...
                    contourPixels, ...
                    labelIdsToRemove, ...
                    obj.pValueTypeNameContinuous ...
                );

                % Insert the values to the flatmap.
                flatmap = obj.insertValuesToFlatmap( ...
                    flatmap, ...
                    contourPixels, ...
                    valuesToInsert, ...
                    sampleIdxX ...
                );
            
            end

        end

        % Map world-space points to the flatmap.

        function [flatRows,flatColumns] = mapWorldPointsToFlatmapImpl(obj, ...
                queryWorldXs, ...
                queryWorldYs, ...
                queryWorldZs, ...
                verbose ...
            )

            % Save the original dimensions of the query coordinate array.
            sizeQueryArray = size(queryWorldXs);

            % Reshape the query coordinate array into a column vector.
            % (numeric, numQueryPoints x 1)
            queryWorldXs = convertToColumn(queryWorldXs);
            queryWorldYs = convertToColumn(queryWorldYs);
            queryWorldZs = convertToColumn(queryWorldZs);

            % Keep track of the linear indices of the query coordinate
            % array. (double, 1 x numQueryPoints)
            linIdxsQueryArray = 1:numel(queryWorldXs);

            % Create two 3D masks that identify whether each world-space
            % sampling point lies on the object’s surface or inside its
            % volume. (logical, numSamplesX x numSamplesY x numSamplesZ) 
            [samplesXYZGridMaskSurface,samplesXYZGridMaskInterior] = ...
                obj.createSurfaceAndInteriorMask();

            % Remove query points that lie outside the object.
            % (numeric, numQueryPoints x 1)
            [queryWorldXs,queryWorldYs,queryWorldZs,linIdxsQueryArray] = ...
                obj.removeQueryPointsOutsideObject( ...
                    queryWorldXs, ...
                    queryWorldYs, ...
                    queryWorldZs, ...
                    linIdxsQueryArray, ...
                    samplesXYZGridMaskInterior, ...
                    verbose ...
                );
            
            % For each query point, find the nearest sampling point among
            % those corresponding to the object's surface, and return its
            % indices along the X, Y, and Z axes in world space.
            % (double, numQueryPoints x 1)
            [sampleIdxsXNearest,sampleIdxsYNearest,sampleIdxsZNearest] = ...
                obj.findNearestSurfaceSamplingPoints( ...
                    queryWorldXs, ...
                    queryWorldYs, ...
                    queryWorldZs, ...
                    samplesXYZGridMaskSurface ...
                );
            
            % Convert the indices of the nearest sampling points in world
            % space to corresponding row and column indices on the flatmap.
            % (double, numQueryPoints x 1)
            [flatRowsVector,flatColumnsVector] = obj.convertSamplingIndicesToFlatmap( ...
                sampleIdxsXNearest, ...
                sampleIdxsYNearest, ...
                sampleIdxsZNearest ...
            );

            % Create arrays with the same size as the original query
            % coordinate array, and store the corresponding flatmap row and
            % column indices at each location. Points that lie outside the
            % object and were not mapped are assigned NaN.
            % (double, M x N)
            flatRows    = nan(sizeQueryArray);
            flatColumns = nan(sizeQueryArray);
            flatRows(linIdxsQueryArray)    = flatRowsVector;
            flatColumns(linIdxsQueryArray) = flatColumnsVector;

        end

        function [samplesXYZGridMaskSurface,samplesXYZGridMaskInterior] = ...
                createSurfaceAndInteriorMask(obj)
            %
            % Create two 3D masks that identify whether each world-space
            % sampling point lies on the object’s surface or inside its
            % volume.
            %

            % Initialize a 3D logical mask corresponding to sampling points
            % along the X, Y, and Z axes in world space.
            % (logical, numSamplesX x numSamplesY x numSamplesZ) 
            samplesXYZGridMask = false(obj.pSamplesXYZGridSize);
            samplesXYZGridMaskSurface = samplesXYZGridMask;
            samplesXYZGridMaskInterior = samplesXYZGridMask;

            % Initialize a 2D logical mask corresponding to sampling points
            % along the Y and Z axes in world space, representing a
            % sagittal slice at an X-axis sampling point.
            % (logical, numSamplesY x numSamplesZ)
            samplesYZGridMask = obj.createSagittalSliceMask();

            for sampleIdxX = 1:obj.pNumSamplesX

                % Get the contour pixels on the sagittal slice.
                % (table, numContourPixels x 4) or []
                contourPixels = obj.pContourPixelsCell{sampleIdxX};

                if isempty(contourPixels)
                    continue;
                end

                % Convert Y and Z sampling indices on the sagittal slice to
                % a linear index. (double, numContourPixels x 1)
                linIdxsContour = obj.getLinearIndicesOnSagittalSlice( ...
                    contourPixels.(obj.pVarNameSampleIdxY), ...
                    contourPixels.(obj.pVarNameSampleIdxZ) ...
                );

                samplesYZGridMaskContour = samplesYZGridMask;

                % Assign true to the contour pixels.
                samplesYZGridMaskContour(linIdxsContour) = true;                

                % Insert the 2D mask into the 3D mask.
                samplesXYZGridMaskSurface(sampleIdxX,:,:) = samplesYZGridMaskContour;

                % Fill the region inside the contour.
                samplesYZGridMaskContour = imfill(samplesYZGridMaskContour,"holes");

                % Insert the 2D mask into the 3D mask.
                samplesXYZGridMaskInterior(sampleIdxX,:,:) = samplesYZGridMaskContour;

            end

        end

        function [queryWorldXs,queryWorldYs,queryWorldZs,linIdxsQueryArray] = ...
                removeQueryPointsOutsideObject(obj, ...
                    queryWorldXs, ...
                    queryWorldYs, ...
                    queryWorldZs, ...
                    linIdxsQueryArray, ...
                    samplesXYZGridMaskInterior, ...
                    verbose ...
                )
            %
            % Remove query points that lie outside the object.
            %

            % Construct a gridded interpolant from the interior mask to
            % determine whether a given world-space point lies inside the
            % object.
            F = griddedInterpolant( ...
                {obj.pSamplesX,obj.pSamplesY,obj.pSamplesZ}, ... % sample points
                double(samplesXYZGridMaskInterior), ... % corresponding values
                "nearest", ...
                "nearest" ...
            );
            
            % Determine whether each world-space query point lies inside
            % the object. (logical, numQueryPoints x 1)
            isInsideObject = logical(F(queryWorldXs,queryWorldYs,queryWorldZs));

            if all(isInsideObject)
                return;
            end

            willBeSkipped = ~isInsideObject;
            
            dataToPrint = [
                find(willBeSkipped), ...
                queryWorldXs(willBeSkipped), ...
                queryWorldYs(willBeSkipped), ...
                queryWorldZs(willBeSkipped)
            ];
            
            % Log the world-space query points points that are going to
            % be skipped.
            obj.printMsg(verbose, ...
                "The following query points were skipped because they " + ...
                "are not inside the target object in the label volume:\n" + ...
                "  #%d: (%.3f, %.3f, %.3f)\n", ...
                dataToPrint.' ...
            );

            % Remove the query points outside the object.
            queryWorldXs(willBeSkipped) = [];
            queryWorldYs(willBeSkipped) = [];
            queryWorldZs(willBeSkipped) = [];

            % Remove the linear index of the query points outside the
            % object.
            linIdxsQueryArray(willBeSkipped) = [];
               
        end

        function [sampleIdxsXNearest,sampleIdxsYNearest,sampleIdxsZNearest] = ...
                findNearestSurfaceSamplingPoints(obj, ...
                    queryWorldXs, ...
                    queryWorldYs, ...
                    queryWorldZs, ...
                    samplesXYZGridMaskSurface ...
                )
            %
            % For each query point, find the nearest sampling point among
            % those corresponding to the object's surface, and return its
            % indices along the X, Y, and Z axes in world space.
            %

            % Generate 3D coordinate grids for the X, Y, and Z sampling
            % points in world space.
            % (double, numSamplesX x numSamplesY x numSamplesZ)
            [samplesXYZGridX,samplesXYZGridY,samplesXYZGridZ] = ndgrid( ...
                obj.pSamplesX, ...
                obj.pSamplesY, ...
                obj.pSamplesZ ...
            );            

            % Get the linear indices of sampling points in world space (X,
            % Y, Z) that correspond to the surface of the object.
            % (double, numSurfaceVoxels x 1)
            linIdxsSamplesXYZGridSurface = find(samplesXYZGridMaskSurface);
            
            % Get the X, Y, and Z coordinates of sampling points in world
            % space that correspond to the object's surface.
            % (double, numSurfaceVoxels x XYZ)
            samplesXYZSurface = [
                samplesXYZGridX(linIdxsSamplesXYZGridSurface), ...
                samplesXYZGridY(linIdxsSamplesXYZGridSurface), ...
                samplesXYZGridZ(linIdxsSamplesXYZGridSurface) ...
            ];

            % Create a k-d tree model from the object's surface coordinates
            % for fast nearest-neighbor queries.
            NS = createns(samplesXYZSurface,"NSMethod","kdtree");
            
            % Find the nearest surface point for each world-space query
            % point using the k-d tree model. (double, numQueryPoints x 1)
            [idxsSamplesXYZSurfaceNearest,dist] = knnsearch( ...
                NS, ...
                [queryWorldXs,queryWorldYs,queryWorldZs] ...
            );

            % Get the linear indices of the surface sampling points in
            % world space (X, Y, Z) that are closest to each point in the
            % given query point set. (double, numQueryPoints x 1)
            linIdxsSamplesXYZGridSurfaceNearest = ...
                linIdxsSamplesXYZGridSurface(idxsSamplesXYZSurfaceNearest);

            % Convert the linear indices of the nearest surface sampling
            % points into X, Y, and Z subscripts.
            % (double, numQueryPoints x 1) 
            [sampleIdxsXNearest,sampleIdxsYNearest,sampleIdxsZNearest] = ind2sub( ...
                obj.pSamplesXYZGridSize, ...
                linIdxsSamplesXYZGridSurfaceNearest ...
            );

        end

        function [flatRows,flatColumns] = convertSamplingIndicesToFlatmap(obj, ...
                sampleIdxsX, ...
                sampleIdxsY, ...
                sampleIdxsZ ...
            )
            %
            % Convert sampling point indices in world space to
            % corresponding row and column indices on the flatmap.
            %

            numPoints = numel(sampleIdxsX);

            % Initialize arrays to store row and column indices.
            % (double, numPoints x 1)
            flatRows    = zeros(numPoints,1);
            flatColumns = zeros(numPoints,1);

            for i = 1:numPoints

                sampleIdxX = sampleIdxsX(i);
                sampleIdxY = sampleIdxsY(i);
                sampleIdxZ = sampleIdxsZ(i);

                % Get the contour pixels on the sagittal slice.
                % (table, numContourPixels x 4) or []
                contourPixels = obj.pContourPixelsCell{sampleIdxX};

                % Find the contour pixel on the sagittal slice that
                % corresponds to the specified sampling point.
                % (logical, numContourPixels x 1)
                idx = contourPixels.(obj.pVarNameSampleIdxY) == sampleIdxY & ...
                      contourPixels.(obj.pVarNameSampleIdxZ) == sampleIdxZ;

                % Get the offset of the contour pixel on the flatmap.
                % (double, 1 x 1)
                offset = contourPixels.(obj.pVarNameOffset)(idx);

                % Compute and store the row and column indices on the
                % flatmap for the contour pixel.
                [flatRows(i),flatColumns(i)] = obj.calcRowAndColumnOnFlatmap( ...
                    offset, ...
                    sampleIdxX ...
                );
            
            end

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

        function validateLabelIdsToRemove(obj,labelIdsToRemove)

            % Validate the label IDs to be removed.
            if ~isempty(labelIdsToRemove)
                Validator.mustBePosInteger(labelIdsToRemove);
            end

        end

    end
    
end