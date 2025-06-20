classdef CerebellumFlatmapGenerator < ClassVersion
    %
    % This class generates various flatmaps from 3D labeled marmoset
    % cerebellum data.
    %

    % HISTORY:
    %   1.0 - 20250516 a) Written by Mitsu
    %                  b) Moved code for generating various flatmaps from
    %                     marmoset cerebellum label data out of
    %                     MarmosetCerebellumFlatmapTool.mlapp.
    %   1.1 - 20250526 a) Renamed mapPointCloudToFlatmap() to
    %                     mapWorldPointsToFlatmap(), and updated the output
    %                     format.
    %                  b) The curvature flatmap colormap was updated to use
    %                     a gradient based on curvature magnitude, instead
    %                     of three fixed colors for positive, negative, and
    %                     zero values.

    properties (Constant)

        % Version of the class definition.
        cClassVersion = 1.1;

        % Names of the flatmap types.
        cTypeNameLabel     = "label";
        cTypeNameBorder    = "border";
        cTypeNameCurvature = "curvature";
        cTypeNameIntensity = "intensity";

        % Variable names for the colormap table.
        cVarNameId        = "id";
        cVarNameColor     = "color";
        cVarNameLabelName = "labelName";

        % Default range of values for the intensity flatmap.
        cIntensityMax =  7;
        cIntensityMin = -7;
        cIntensityPosTholdInit =  3.28;
        cIntensityNegTholdInit = -3.28;

    end

    properties (GetAccess = public, SetAccess = private)

        % Created flatmap data.
        pFlatmapLabel
        pFlatmapBorder
        pFlatmapCurvature

        % Created colormap data.
        pColormapLabel
        pColormapBorder
        pColormapCurvature

        % World-space X sampling coordinates corresponding to each column
        % of the final flatmap.
        pWorldXCoordsPerColumn

    end

    properties (Access = private)

        % Utility object handles.
        hMatlabColor
        
        % FlatmapGenerator handles for the main part of the cerebellum,
        % flocculus (Fl), and paraflocculus (PFl).
        hFlatmapGeneratorMain
        hFlatmapGeneratorFl
        hFlatmapGeneratorPFl       

        % Index of the first valid X-axis sampling point in world space
        % where a target object exists on the sagittal slice.
        pSampleIdxXFirstMain
        pSampleIdxXFirstFl
        pSampleIdxXFirstPFl           

        % Label IDs in the volume.
        pLabelIdWhiteMatter = 46;
        pLabelIdBridge      = 98;  % Bridge lines between objects.
        pLabelIdIncision    = 99;  % Incision lines
        pLabelIdOrigin      = 100; % Origin lines

        % Predefined label IDs.
        pLabelIdBackground = 0;
        pLabelIdBorder     = 1;

        % Predefined label names.
        pLabelNameBackground = "background";
        pLabelNameBorder     = "border";

        % Predefined label colors.
        pLabelColorBackgroundLabel     = "black";
        pLabelColorBackgroundBorder    = "white";
        pLabelColorBackgroundIntensity = "black";
        pLabelColorBorder              = "black";

        % Label IDs not shown on the flatmap.
        pLabelIdsToRemove

        % Resolution for colormaps.
        pColormapResolution = 256;

        % Vertical padding added to the main flatmap to include the other
        % regions.
        pVerticalPadding = 0; % 23

        % Vertical offset from the main flatmap for positioning the
        % flocculus and paraflocculus.
        pVerticalOffsetPFl = 2376; % 2840
        pVerticalOffsetFl  = 2709; % 2490

    end

    methods (Access = public)
        
        % Constructor.
        
        function obj = CerebellumFlatmapGenerator( ...
                labelVolumePathMain, ...
                labelVolumePathFl, ...
                labelVolumePathPFl, ...
                colorTablePath ...
            )

            % Create and store a MatlabColor. (MatlabColor, 1 x 1)
            obj.hMatlabColor = MatlabColor();
            
            % Set label IDs to be removed from flatmaps.
            obj.pLabelIdsToRemove = [ ...
                obj.pLabelIdWhiteMatter, ...
                obj.pLabelIdBridge, ...
                obj.pLabelIdIncision, ...
                obj.pLabelIdOrigin ...
            ];

            % Create and store FlatmapGenerator handles.
            obj.storeFlatmapGeneratorHandles( ...
                labelVolumePathMain, ...
                labelVolumePathFl, ...
                labelVolumePathPFl ...
            );

            % Create and store a label flatmap. (uint8, M x N)
            obj.pFlatmapLabel = obj.createFlatmap( ...
                FlatmapGenerator.cMethodNameCreateLabelFlatmap ...
            );

            % Create and store a border flatmap. (uint8, M x N)
            obj.pFlatmapBorder = obj.createFlatmap( ...
                FlatmapGenerator.cMethodNameCreateBorderFlatmap ...
            );

            % Create and store a curvature flatmap. (double, M x N)
            obj.pFlatmapCurvature = obj.createFlatmap( ...
                FlatmapGenerator.cMethodNameCreateCurvatureFlatmap ...
            );

            % Create and store colormaps for label, border, and curvature
            % flatmaps. (table, 1 x 3) or (numColors x RGB)
            obj.pColormapLabel     = obj.createLabelColormap(colorTablePath);
            obj.pColormapBorder    = obj.createBorderColormap();
            obj.pColormapCurvature = parula;

            % Extract and store the world-space X sampling coordinates
            % corresponding to each column of the final flatmap.
            % (double, 1 x flatmapWidth)
            obj.pWorldXCoordsPerColumn = obj.extractWorldXCoordsPerColumn();

        end

        function flatmap = createIntensityFlatmap(obj,intensityFilePath)

            % Create the intensity flatmap. (double, M x N)
            flatmap = obj.createFlatmap( ...
                FlatmapGenerator.cMethodNameCreateIntensityFlatmap, ...
                intensityFilePath ...
            );

        end

        function colormap = createIntensityColormap(obj, ...
                intensityNegThold, ...
                intensityPosThold ...
            )

            % Create a colormap for an intensity flatmap.
            % (double, 1 x 3)
            colormap = obj.createIntensityColormapImpl( ...
                intensityNegThold, ...
                intensityPosThold ...
            );

        end

        function [flatRows,flatColumns] = mapWorldPointsToFlatmap(obj, ...
                pointCloudFilePath ...
            )

            % Compute the row and column indices on the flatmap
            % corresponding to the given point cloud in world space.
            % (double, numQueryPoints x 1) 
            [flatRows,flatColumns] = obj.calcRowAndColumnOnFlatmap( ...
                pointCloudFilePath ...
            );

        end

    end

    methods (Access = private)
        
        % Create FlatmapGenerator handles.
        
        function storeFlatmapGeneratorHandles(obj, ...
                labelVolumePathMain, ...
                labelVolumePathFl, ...
                labelVolumePathPFl ...
            )

            % Create and store FlatmapGenerator handles for the main part
            % of the cerebellum, flocculus (Fl), and paraflocculus (PFl).
            % (FlatmapGenerator, 1 x 1)
            obj.hFlatmapGeneratorMain = ...
                obj.createFlatmapGeneratorHandle(labelVolumePathMain);
            obj.hFlatmapGeneratorFl = ...
                obj.createFlatmapGeneratorHandle(labelVolumePathFl);
            obj.hFlatmapGeneratorPFl = ...
                obj.createFlatmapGeneratorHandle(labelVolumePathPFl);

            % Store the index of the first valid X-axis sampling point in
            % world space where a target object exists on the sagittal
            % slice.
            obj.pSampleIdxXFirstMain = obj.hFlatmapGeneratorMain.getSampleIdxXFirst();
            obj.pSampleIdxXFirstFl   = obj.hFlatmapGeneratorFl.getSampleIdxXFirst();
            obj.pSampleIdxXFirstPFl  = obj.hFlatmapGeneratorPFl.getSampleIdxXFirst();

        end

        function hFlatmapGenerator = createFlatmapGeneratorHandle(obj, ...
                labelVolumePath ...
            )

            % Create a FlatmapGenerator handle for the volume data.
            % (FlatmapGenerator, 1 x 1)
            hFlatmapGenerator = FlatmapGenerator( ...
                labelVolumePath, ...
                obj.pLabelIdIncision, ...
                obj.pLabelIdOrigin, ...
                false ...
            );

        end

        % Create flatmaps.

        function flatmap = createFlatmap(obj, ...
                methodNameCreateFlatmap, ...
                varargin ...
            )

            % Create flatmaps for the main cerebellar region, flocculus,
            % and paraflocculus. (numeric, M x N)
            [flatmapMain,flatmapFl,flatmapPFl] = obj.createFlatmaps( ...
                methodNameCreateFlatmap, ...
                varargin{:} ...
            );

            % Combine the flatmaps into a single flatmap.
            flatmap = obj.combineFlatmaps(flatmapMain,flatmapFl,flatmapPFl);

        end

        function [flatmapMain,flatmapFl,flatmapPFl] = createFlatmaps(obj, ...
                methodNameCreateFlatmap, ...
                varargin ...
            )

            % Create flatmaps for the main cerebellar region, flocculus,
            % and paraflocculus. (numeric, M x N) 

            flatmapMain = obj.hFlatmapGeneratorMain.(methodNameCreateFlatmap)( ...
                varargin{:}, ...
                labelIdsToRemove = obj.pLabelIdsToRemove ...
            );  

            flatmapFl = obj.hFlatmapGeneratorFl.(methodNameCreateFlatmap)( ...
                varargin{:}, ...
                labelIdsToRemove = obj.pLabelIdsToRemove ...
            ); 

            flatmapPFl = obj.hFlatmapGeneratorPFl.(methodNameCreateFlatmap)( ...
                varargin{:}, ...
                labelIdsToRemove = obj.pLabelIdsToRemove ...
            );

        end

        function flatmap = combineFlatmaps(obj,flatmapMain,flatmapFl,flatmapPFl)

            % Determine the final flatmap size using the maximum height and
            % width among all flatmaps.
            flatmapSize = [ ...
                size(flatmapMain,1)+obj.pVerticalPadding, ...
                size(flatmapPFl,2), ...
                1 ...
            ];

            % Check whether each flatmap contains any NaN values.
            % (logical, M x N)
            isNanMain = isnan(flatmapMain);
            isNanFl   = isnan(flatmapFl);
            isNanPFl  = isnan(flatmapPFl);

            if any(isNanMain,"all") || any(isNanFl,"all") || any(isNanPFl,"all")

                % Initialize the flatmap as a double array filled with NaNs.
                % (double, M x N)
                flatmap = nan(flatmapSize);

            else

                % Initialize the flatmap while preserving the original data
                % type (class). (numeric, M x N)
                flatmap = zeros(flatmapSize,class(flatmapMain));

            end

            % Insert the flatmap of the main region, flocculus, and
            % paraflocculus into the final flatmap.

            flatmap = obj.insertSubFlatmaps(flatmap, ...
                flatmapMain, ...
                isNanMain, ...
                obj.pSampleIdxXFirstMain, ...
                0 ...
            );

            flatmap = obj.insertSubFlatmaps(flatmap, ...
                flatmapFl, ...
                isNanFl, ...
                obj.pSampleIdxXFirstFl, ...
                obj.pVerticalOffsetFl ...
            );

            flatmap = obj.insertSubFlatmaps(flatmap, ...
                flatmapPFl, ...
                isNanPFl, ...
                obj.pSampleIdxXFirstPFl, ...
                obj.pVerticalOffsetPFl ...
            );

        end

        function flatmapBase = insertSubFlatmaps(obj,flatmapBase, ...
                flatmapInsert, ...
                isNanInsert, ...
                sampleIdxXFirst, ...
                verticalOffset ...
            )

            colToInsertLeft  = obj.calcColumnOnFlatmap(sampleIdxXFirst);
            colToInsertRight = colToInsertLeft+size(flatmapInsert,2)-1;

            rowsToInsert = (1:size(flatmapInsert,1))+verticalOffset;
            colsToInsert = colToInsertLeft:colToInsertRight;

            % Extract the target insertion region from the base flatmap.
            % (numeric, M x N)
            targetRegion = flatmapBase(rowsToInsert,colsToInsert);

            % Identify the pixels with NaN values in the target region.
            % (logical, M x N)
            isNanTarget = isnan(targetRegion);
            
            % Replace NaNs in the target region with 0 where the insert
            % region has numeric values. 
            replaceInBase = isNanTarget & ~isNanInsert;
            targetRegion(replaceInBase) = 0;

            % Replace NaNs in the insert flatmap with 0 where the target
            % region has numeric values.
            replaceInInsert = ~isNanTarget & isNanInsert;
            flatmapInsert(replaceInInsert) = 0;
    
            % Add the target region and the insert flatmap, then insert the
            % result into the base flatmap.
            flatmapBase(rowsToInsert,colsToInsert) = ...
                targetRegion + flatmapInsert;

        end

        function flatColumn = calcColumnOnFlatmap(obj,sampleIdxXFirst)
        
            % Calculate the flatmap column index based on the leftmost
            % X-axis sampling point index of the paraflocculus flatmap.
            flatColumn = sampleIdxXFirst-obj.pSampleIdxXFirstPFl+1;

        end

        % Create colormaps.

        function colormap = createLabelColormap(obj,colorTablePath)

            % Read the color lookup table file. (table, numLabels+1 x 3)
            colormap = obj.readColorTable(colorTablePath);

            % Find rows in the colormap table where the label ID matches
            % any in the removal list.
            rowsToRemove = ismember( ...
                colormap.(obj.cVarNameId), ...
                obj.pLabelIdsToRemove ...
            );

            % Remove the matching rows from the colormap table.
            colormap(rowsToRemove,:) = [];            

        end

        function colormap = readColorTable(obj,colorTablePath)
            
            % Initialize a colormap with the background.
            % (table, 1 x 3)
            colormap = obj.initColormap(obj.pLabelColorBackgroundLabel);

            % Read the color lookup table file. (table, numColors x 6)
            colorTable = readtable( ...
                colorTablePath, ...
                'fileType','delimitedtext', ...
                'Delimiter',' ', ...
                'NumHeaderLines',0 ...
            );

            % Initialize a cell to store the colormap data. (cell, numColors x 3)
            colorCell = cell(height(colorTable),3);

            % Extract the label ID, color, and name.
            colorCell(:,1) = num2cell(colorTable{:,1});
            colorCell(:,2) = num2cell(colorTable{:,3:5},2);
            colorCell(:,3) = colorTable{:,2};

            % Add the data to the colormap. (table, numColors+1 x 3)
            colormap = [colormap;colorCell];
        
        end

        function colormap = initColormap(obj,backgroundColor)
            %
            % Initialize a colormap with the background.
            %
            % <Output>:
            %   colormap: (table, 1 x 3)
            %       1st column: (double, 1 x 1)
            %           Label ID.
            %       2nd column: (uint8, 1 x RGB)
            %           Label color.
            %       3rd column: (string, 1 x 1)
            %           Label name.

            % Initialize a table to store label IDs, colors, and label names.
            % (table, numLabels x 3)
            colormap = initTable( ...
                [ ...
                    obj.cVarNameId, ...
                    obj.cVarNameColor, ...
                    obj.cVarNameLabelName ...
                ], ...
                0, ...
                ["double","uint8","string"] ...
            );

            % Add a background to the colormap.
            colormap = obj.addColormap(colormap, ...
                obj.pLabelIdBackground, ...
                obj.pLabelNameBackground, ...
                backgroundColor ...
            );

        end

        function colormap = addColormap(obj, ...
                colormap, ...
                labelId, ...
                labelName, ...
                colorName ...
            )

            % Validate the color and get the color in RGB triplets format 
            % with values in the range [0,1]. (double, 1 x RGB)
            color = obj.hMatlabColor.convertToRgbTriplets(colorName);

            % Convert the color to uint8. (uint8, 1 x RGB)
            color = uint8(255*color);

            % Add the label to the colormap. (table, numLabels x 3)
            colormap = [colormap;{labelId,color,labelName}];

        end

        function colormap = createBorderColormap(obj)

            % Initialize a colormap with the background.
            % (table, 1 x 3)
            colormap = obj.initColormap(obj.pLabelColorBackgroundBorder);

            % Add a border point to the colormap.
            colormap = obj.addColormap(colormap, ...
                obj.pLabelIdBorder, ...
                obj.pLabelNameBorder, ...
                obj.pLabelColorBorder ...
            );

        end

        function colormap = createIntensityColormapImpl(obj, ...
                intensityNegThold, ...
                intensityPosThold ...
            )

            % Initialize a colormap for an intensity flatmap.
            % (double, numColors x 3)
            colormap = zeros(obj.pColormapResolution,3);

            % Create a range of intensity values from the minimum to
            % maximum for colormap mapping.
            x = linspace( ...
                obj.cIntensityMin, ...
                obj.cIntensityMax, ...
                obj.pColormapResolution ...
            );
            
            for i = 1:obj.pColormapResolution

                val = x(i);
                
                if val <= intensityNegThold
                    
                    % Calculate the green value.
                    g = (val-obj.cIntensityMin)/(intensityNegThold-obj.cIntensityMin);

                    % Insert the color.
                    colormap(i,:) = [0,g,1];

                    % When intensityMin=B and intensityNegThold=b
                    % Value:               B -> b
                    % Green:   (B-B)/(b-B)=0 -> (b-B)/(b-B)=1    
                    % Color:    Blue (0,0,1) -> Cyan (0,1,1)

                elseif val >= intensityPosThold
                    
                    % Calculate the green value.
                    g = (val-intensityPosThold)/(obj.cIntensityMax-intensityPosThold);

                    % Insert the color.
                    colormap(i,:) = [1,g,0];

                    % When intensityMax=A and intensityPosThold=a
                    % Value:             a -> A
                    % Green: (a-a)/(A-a)=0 -> (A-a)/(A-a)=1
                    % Color:   Red (1,0,0) -> Yellow (1,1,0)

                else

                    % Insert the background color.
                    colormap(i,:) = obj.hMatlabColor.convertToRgbTriplets( ...
                        obj.pLabelColorBackgroundIntensity ...
                    );

                end

            end

        end

        % Extract X sampling coordinates for each flatmap column.

        function worldXCoordsPerColumn = extractWorldXCoordsPerColumn(obj)
            %
            % Extract the world-space X sampling coordinates corresponding
            % to each column (sagittal slice) of the final flatmap.
            %

            % Get the coordinates of all sampling points along the X-axis
            % in world space. (double, 1 x numSamples)
            samplesX = obj.hFlatmapGeneratorPFl.getSamplesX();

            % Width of the final flatmap.
            flatmapWidth = size(obj.pFlatmapLabel,2);

            % Extract only those world-space X samples that map onto each
            % flatmap column. (double, 1 x flatmapWidth)
            worldXCoordsPerColumn = samplesX( ...
                obj.pSampleIdxXFirstPFl:obj.pSampleIdxXFirstPFl+flatmapWidth-1 ...
            );

        end

        % Map world-space points to the flatmap.

        function [flatRows,flatColumns] = calcRowAndColumnOnFlatmap(obj,filePath)
            
            % Read the point cloud coordinates in world space.
            % (double, numQueryPoints x XYZ)
            opts = detectImportOptions(filePath,"CommentStyle","#");
            queryWorldXYZs = readmatrix(filePath,opts);

            % Compute the row and column indices on the flatmap
            % corresponding to the given point cloud for each region.
            % (double, numQueryPoints x 1)
            [flatRowsMain,flatColumnsMain] = obj.calcRowAndColumnOnFlatmapEach( ...
                queryWorldXYZs, ...
                obj.hFlatmapGeneratorMain, ...
                obj.pSampleIdxXFirstMain, ...
                0 ...
            );
            [flatRowsFl,flatColumnsFl] = obj.calcRowAndColumnOnFlatmapEach( ...
                queryWorldXYZs, ...
                obj.hFlatmapGeneratorFl, ...
                obj.pSampleIdxXFirstFl, ...
                obj.pVerticalOffsetFl ...
            );
            [flatRowsPFl,flatColumnsPFl] = obj.calcRowAndColumnOnFlatmapEach( ...
                queryWorldXYZs, ...
                obj.hFlatmapGeneratorPFl, ...
                obj.pSampleIdxXFirstPFl, ...
                obj.pVerticalOffsetPFl ...
            );

            % Combine all the row and column indices.
            % (double, numQueryPoints x 1)
            flatRows    = vertcat(flatRowsMain,flatRowsFl,flatRowsPFl);
            flatColumns = vertcat(flatColumnsMain,flatColumnsFl,flatColumnsPFl);

        end

        function [flatRows,flatColumns] = calcRowAndColumnOnFlatmapEach(obj, ...
                queryWorldXYZs, ...
                hFlatmapGenerator, ...
                idxLeft, ...
                verticalOffset ...
            )

            % Compute the row and column indices on the sub flatmap
            % corresponding to the given point cloud in world space.
            % (double, numQueryPoints x 1)
            [flatRows,flatColumns] = hFlatmapGenerator.mapWorldPointsToFlatmap( ...
                queryWorldXYZs(:,1), ...
                queryWorldXYZs(:,2), ...
                queryWorldXYZs(:,3), ...
                false ...
            );

            % Transform row and column indices into final flatmap
            % coordinates.
            flatRows    = flatRows+verticalOffset;
            flatColumns = flatColumns+obj.calcColumnOnFlatmap(idxLeft)-1;

        end

    end
    
end