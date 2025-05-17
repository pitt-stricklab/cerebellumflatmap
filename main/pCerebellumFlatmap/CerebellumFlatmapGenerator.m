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
    %

    properties (Constant)

        % Version of the class definition.
        cClassVersion = 1.0; 

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

    end

    properties (Access = private)

        % Utility object handles.
        hMatlabColor
        
        % FlatmapGenerator handles for the main part of the cerebellum,
        % flocculus (Fl), and paraflocculus (PFl).
        hFlatmapGeneratorMain
        hFlatmapGeneratorFl
        hFlatmapGeneratorPFl       

        % The index of the first sagittal slice where each region begins.
        pIdxLeftMain
        pIdxLeftFl
        pIdxLeftPFl

        % Dimension number of sagittal planes.
        pDimNumSagittal = 1;

        % Label IDs in the volume.
        pLabelIdWhiteMatter = 46;
        pLabelIdBridge      = 98;  % Bridge lines between objects.
        pLabelIdIncision    = 99;  % Incision lines
        pLabelIdOrigin      = 100; % Origin lines

        % Predefined label IDs.
        pLabelIdBackground      = 0;
        pLabelIdBorder          = 1;
        pLabelIdInflectionPoint = 1;
        pLabelIdConcave         = 2;
        pLabelIdConvex          = 3;

        % Predefined label names.
        pLabelNameBackground      = "background";
        pLabelNameBorder          = "border";
        pLabelNameInflectionPoint = "inflection point";
        pLabelNameConcave         = "concave";
        pLabelNameConvex          = "convex";

        % Predefined label colors.
        pLabelColorBackgroundLabel     = "black";
        pLabelColorBackgroundBorder    = "white";
        pLabelColorBackgroundCurvature = "white";
        pLabelColorBackgroundIntensity = "black";
        pLabelColorBorder              = "black";
        pLabelColorInflectionPoint     = "black";
        pLabelColorConcave             = "blue";
        pLabelColorConvex              = "red";

        % Label IDs not shown on the flatmap.
        pLabelIdsToRemove

        % Resolution for the intensity flatmap colormap.
        pIntensityResolution = 256;

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

            % Create and store label, border, and curvature flatmaps.
            % (uint8, M x numValidSlices)
            obj.pFlatmapLabel = obj.createFlatmap( ...
                FlatmapGenerator.cMethodNameCreateLabelFlatmap ...
            );
            obj.pFlatmapBorder = obj.createFlatmap( ...
                FlatmapGenerator.cMethodNameCreateBorderFlatmap ...
            );
            obj.pFlatmapCurvature = obj.createFlatmap( ...
                FlatmapGenerator.cMethodNameCreateCurvatureFlatmap ...
            );

            % Create and store colormaps for label, border, and curvature
            % flatmaps. (table, 1 x 3)
            obj.pColormapLabel     = obj.createLabelColormap(colorTablePath);
            obj.pColormapBorder    = obj.createBorderColormap();
            obj.pColormapCurvature = obj.createCurvatureColormap();
            
        end

        function flatmap = createIntensityFlatmap(obj,intensityFilePath)

            % Create the intensity flatmap. (double, M x numValidSlices)
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

        function nmTarget = mapPointCloudToFlatmap(obj,pointCloudFilePath)

            % Compute the coordinates of the point cloud on the flatmap.
            % (double, numTargetPoints x NM) 
            nmTarget = obj.computeCoordinatesOnFlatmap(pointCloudFilePath);

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
            
            obj.hFlatmapGeneratorMain = obj.createFlatmapGeneratorHandle( ...
                labelVolumePathMain ...
            );

            obj.hFlatmapGeneratorFl = obj.createFlatmapGeneratorHandle( ...
                labelVolumePathFl ...
            );

            obj.hFlatmapGeneratorPFl = obj.createFlatmapGeneratorHandle( ...
                labelVolumePathPFl ...
            );

            % Store the coordinate of the first valid sagittal slice
            % (leftmost slice).
            obj.pIdxLeftMain = obj.hFlatmapGeneratorMain.getIndexValidSliceStart();
            obj.pIdxLeftFl   = obj.hFlatmapGeneratorFl.getIndexValidSliceStart();
            obj.pIdxLeftPFl  = obj.hFlatmapGeneratorPFl.getIndexValidSliceStart();

        end

        function hFlatmapGenerator = createFlatmapGeneratorHandle(obj, ...
                labelVolumePath ...
            )

            % Create a FlatmapGenerator handle for the volume data.
            % (FlatmapGenerator, 1 x 1)
            hFlatmapGenerator = FlatmapGenerator( ...
                labelVolumePath, ...
                obj.pDimNumSagittal, ...
                obj.pLabelIdIncision, ...
                obj.pLabelIdOrigin ...
            );

            % Parse the volume data.
            hFlatmapGenerator.parse(false);

        end

        % Create flatmaps.

        function flatmap = createFlatmap(obj, ...
                methodNameCreateFlatmap, ...
                varargin ...
            )

            % Create flatmaps for the main cerebellar region, flocculus,
            % and paraflocculus. (numeric, M x numValidSlices)
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
            % and paraflocculus. (numeric, M x numValidSlices) 

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

            % Initialize the size of the final flatmap using the maximum
            % height and width among all flatmaps. (numeric, M x N)
            flatmap = zeros( ...
                [ ...
                    size(flatmapMain,1)+obj.pVerticalPadding, ...
                    size(flatmapPFl,2), ...
                    1 ...
                ], ...
                class(flatmapMain) ...
            );

            % Insert the flatmap of the main region, flocculus, and
            % paraflocculus into the final flatmap.

            flatmap = obj.insertSubFlatmaps(flatmap, ...
                flatmapMain, ...
                obj.pIdxLeftMain, ...
                0 ...
            );

            flatmap = obj.insertSubFlatmaps(flatmap, ...
                flatmapFl, ...
                obj.pIdxLeftFl, ...
                obj.pVerticalOffsetFl ...
            );

            flatmap = obj.insertSubFlatmaps(flatmap, ...
                flatmapPFl, ...
                obj.pIdxLeftPFl, ...
                obj.pVerticalOffsetPFl ...
            );

        end

        function flatmap = insertSubFlatmaps(obj,flatmap, ...
                flatmapToInsert, ...
                idxLeft, ...
                verticalOffset ...
            )

            idxToInsertLeft  = obj.shiftSagittalIndex(idxLeft);
            idxToInsertRight = idxToInsertLeft+size(flatmapToInsert,2)-1;

            idxsToInsertVert = (1:size(flatmapToInsert,1))+verticalOffset;
            idxsToInsertHori = idxToInsertLeft:idxToInsertRight;

            flatmap(idxsToInsertVert,idxsToInsertHori) = ...
            flatmap(idxsToInsertVert,idxsToInsertHori) + flatmapToInsert;

        end

        function idx = shiftSagittalIndex(obj,idx)
        
            % Shift the sagittal index to align with the left edge of the
            % paraflocculus flatmap.
            idx = idx-obj.pIdxLeftPFl+1;

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

        function colormap = createCurvatureColormap(obj)

            % Initialize a colormap with the background.
            % (table, 1 x 3)
            colormap = obj.initColormap(obj.pLabelColorBackgroundCurvature);

            % Add an inflection point to the colormap.
            colormap = obj.addColormap(colormap, ...
                obj.pLabelIdInflectionPoint, ...
                obj.pLabelNameInflectionPoint, ...
                obj.pLabelColorInflectionPoint ...
            );

            % Add a concave point to the colormap.
            colormap = obj.addColormap(colormap, ...
                obj.pLabelIdConcave, ...
                obj.pLabelNameConcave, ...
                obj.pLabelColorConcave ...
            );
            
            % Add a convex point to the colormap.
            colormap = obj.addColormap(colormap, ...
                obj.pLabelIdConvex, ...
                obj.pLabelNameConvex, ...
                obj.pLabelColorConvex ...
            );

        end

        function colormap = createIntensityColormapImpl(obj, ...
                intensityNegThold, ...
                intensityPosThold ...
            )

            % Initialize a colormap for an intensity flatmap.
            % (double, 1 x 3)
            colormap = zeros(obj.pIntensityResolution,3);

            % Create a range of intensity values from the minimum to
            % maximum for colormap mapping.
            x = linspace( ...
                obj.cIntensityMin, ...
                obj.cIntensityMax, ...
                obj.pIntensityResolution ...
            );
            
            for i = 1:obj.pIntensityResolution

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

        % Map point cloud.

        function nmTarget = computeCoordinatesOnFlatmap(obj,filePath)
            
            % Read the point cloud coordinates.
            % (double, numSourcePoints x XYZ)
            opts = detectImportOptions(filePath,"CommentStyle","#");
            xyzSource = readmatrix(filePath,opts);

            % Compute the final flatmap coordinates of the given source
            % point cloud for each region. (double, numTargetPoints x NM)
            nmTargetMain = obj.computeCoordinatesOnSubFlatmap( ...
                xyzSource, ...
                obj.hFlatmapGeneratorMain, ...
                obj.pIdxLeftMain, ...
                0 ...
            );
            nmTargetFl = obj.computeCoordinatesOnSubFlatmap( ...
                xyzSource, ...
                obj.hFlatmapGeneratorFl, ...
                obj.pIdxLeftFl, ...
                obj.pVerticalOffsetFl ...
            );
            nmTargetPFl = obj.computeCoordinatesOnSubFlatmap( ...
                xyzSource, ...
                obj.hFlatmapGeneratorPFl, ...
                obj.pIdxLeftPFl, ...
                obj.pVerticalOffsetPFl ...
            );

            % Combine all the coordinates. (double, numTargetPoints x NM)
            nmTarget = vertcat(nmTargetMain,nmTargetFl,nmTargetPFl);

        end

        function nmTarget = computeCoordinatesOnSubFlatmap(obj, ...
                xyzSource, ...
                hFlatmapGenerator, ...
                idxLeft, ...
                verticalOffset ...
            )

            % Compute the coordinates of the given source point cloud on
            % the sub flatmap. (double, numTargetPoints x NM)
            nmTarget = hFlatmapGenerator.mapPoints(xyzSource,false);

            % NOTE:
            % N denotes the x-coordinate, and M denotes the y-coordinate on
            % the flatmap.

            % Translate the coordinates to the final flatmap coordinates.
            nmTarget(:,1) = nmTarget(:,1)+obj.shiftSagittalIndex(idxLeft)-1;
            nmTarget(:,2) = nmTarget(:,2)+verticalOffset;

        end

    end
    
end