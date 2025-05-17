classdef Validator
    %
    % A class for custom validators.
    %

    % HISTORY: mustBeCapableReadRegion()
    %   1.0 - 20240424 Written by Mitsu
    %
    % HISTORY: mustBeLabelType()
    %   1.0 - 20231018 Written by Mitsu
    %
    % HISTORY: mustBeLabelTypeScalar()
    %   1.0 - 20231018 Written by Mitsu
    %
    % HISTORY: mustBeStruct()
    %   1.0 - YYYYMMDD Written by Mitsu
    %   1.1 - 20240807 Bug fix. The validation was not done correctly.
    %
    % HISTORY: mustBeImage()
    %   1.0 - 20240808 Written by Mitsu
    %
    % HISTORY: mustBeImageTile()
    %   1.0 - 20240807 Written by Mitsu
    %
    % HISTORY: mustBeImageTileScalar()
    %   1.0 - 20240807 Written by Mitsu
    %
    % HISTORY: mustBeMultiPointFormat()
    %   1.0 - YYYYMMDD Written by Mitsu
    %   1.1 - 20221115 Renamed from mustBePolylineFormat to
    %                  mustBeMultiPointFormat.
    %
    % HISTORY: hasValidFileExtension()
    %   1.0 - YYYYMMDD Written by Mitsu
    %   1.1 - 20210908 Changed mustBeTextScalar() to mustBeTextScalar_alt()
    %                  and mustBeText() to mustBeText_alt() to be
    %                  compatible to MATLAB R2020a or older.
    %
    % HISTORY: validateFileExt()
    %   1.0 - YYYYMMDD Written by Mitsu
    %   1.1 - 20210908 Changed mustBeText() to mustBeText_alt() to be
    %                  compatible to MATLAB R2020a or older.
    %
    % HISTORY: validateFolderExists()
    %   1.0 - 20220123 Written by Mitsu
    %
    % HISTORY: validatePathsExist()
    %   1.0 - YYYYMMDD Written by Mitsu
    %   1.1 - 20210908 Changed mustBeText() to mustBeText_alt() to be
    %                  compatible to MATLAB R2020a or older.
    %   2.0 - 20230415 Don't need to specify 'file' or 'folder' and allow a
    %                  mixed array of files and folders.
    %   2.1 - 20240111 Bug fix when evaluating all(): all(tf) to all(tf,'all').
    %
    % HISTORY: isCombinedGroundTruthContainer()
    %   1.0 - 20230330 Written by Mitsu
    %
    % HISTORY: isCombinedImageTileObjectsDatastore()
    %   1.0 - 20230330 Written by Mitsu
    %
    % HISTORY: isDetectedObject()
    %   1.0 - 20230322 Written by Mitsu
    %
    % HISTORY: isFilePath()
    %   1.0 - 20240807 Written by Mitsu
    %
    % HISTORY: isGroundTruthContainer()
    %   1.0 - 20230323 Written by Mitsu
    %
    % HISTORY: isGroundTruthDataSource()
    %   1.0 - 20231231 Written by Mitsu
    %
    % HISTORY: isGroundTruthProperty()
    %   1.0 - 20230323 Written by Mitsu
    %
    % HISTORY: isHandleClass()
    %   1.0 - 20231229 Written by Mitsu
    %
    % HISTORY: isImageTile()
    %   1.0 - 20240807 Written by Mitsu
    %
    % HISTORY: isLineString()
    %   1.0 - 20230416 Written by Mitsu
    %
    % HISTORY: isMultiPoint()
    %   1.0 - 20230416 Written by Mitsu
    %
    % HISTORY: isMultiPolygon()
    %   1.0 - 20230416 Written by Mitsu
    %
    % HISTORY: isPolygon()
    %   1.0 - 20230416 Written by Mitsu
    %
    % HISTORY: isText()
    %   1.0 - 20240807 Written by Mitsu
    %
    % HISTORY: isTextAllAlphabetOrNumber()
    %   1.0 - 20240815 Written by Mitsu
    %
    % HISTORY: isTextScalar()
    %   1.0 - YYYYMMDD Written by Mitsu
    %   2.0 - 20210908 Bug fix.
    %   2.1 - 20230223 Use isCharRowVector instead of ischar.
    %
    % HISTORY: isValidForDirectoryName()
    %   1.0 - 20231025 Written by Mitsu
    %
    % HISTORY: isZeroCharactersText()
    %   1.0 - YYYYMMDD Written by Mitsu
    %   1.1 - 20210909 Changed mustBeTextScalar() to mustBeTextScalar_alt() to
    %                  be compatible to MATLAB R2020a or older.
    %   1.1 - 20230411 a) Renamed from textScalarIsEmpty() to
    %                     isZeroCharactersText().
    %                  b) Don't validate the input is text scalar.
    %
    % HISTORY: validateTableHasNecessaryVars()
    %   1.0 - 20230304 Written by Mitsu
    %
    % HISTORY: DetectionResultFileController
    %   1.0 - 20220923 a) Written by Mitsu
    %                  b) Moved from AutoMaskerState.
    %   2.0 - 20220929 Moved from markDetectionsWithinMask.
    %
    % HISTORY: xyIsWithinMask()
    %   1.0 - 20230305 a) Written by Mitsu
    %                  b) Moved from DetectionResultFileController.

    % HISTORY:
    %   1.0 - 20240908 a) Written by Mitsu
    %                  b) Integrated function files.
    %                  c) Renamed mustBeTextNonZeroCharacters() to
    %                     mustBeTextNonzeroLength() and use the built-in
    %                     function mustBeNonzeroLengthText().
    %                  d) Renamed mustBeTextScalarNonZeroCharacters() to 
    %                     mustBeTextScalarNonzeroLength().
    %                  e) Renamed isZeroCharactersText() to
    %                     isTextZeroLength().
    %                  f) Renamed matIsIdentical() to isIdentical().
    %                  g) Renamed mustBeEmptyOrHeiWidFormat() to
    %                     mustBeHeiWidFormatOrEmpty().
    %   1.1 - 20240926 Renamed validateFileExt() to validateFileExtension().
    %   1.2 - 20241010 a) Renamed isValidForDirectoryName() to
    %                     isValidDirNameScalar().
    %                  b) Added mustBeValidVarName(), 
    %                     mustBeValidVarNameScalar(), and
    %                     isValidVarNameScalar().
    %                  c) Removed mustBeValidClassName() and
    %                     mustBeValidClassNameScalar().

    methods (Static)

        function tf = objExists(obj)
            %
            % Check if an object exists.
            %
            % <Input>
            %   obj: (CLASS, HEIGHT x WIDTH)
            %       An object or a object handle.

            if ~isempty(obj) && isvalid(obj)
                tf = true;
            else
                tf = false;
            end

        end

        function mustBeIdentical(input1,input2)
            %
            % Validate that the two values are of the same class, have the
            % same size, and if their elements are equal.
            %

            % Check if each cell element is char.
            if ~Validator.isIdentical(input1,input2)
                error( ...
                    "Two values must have the same class, the same size, " + ...
                    "and each element must be equal." ...
                );
            end

        end

        function tf = isIdentical(input1,input2)
            %
            % Check if the two values are of the same class, have the same
            % size, and if their elements are equal.
            %

            tf = false;

            % Check if the class is identical.
            if ~strcmp(class(input1),class(input2))
                return;
            end

            % Check if the size and values are identical.
            tf = isequal(input1,input2);

        end

        function tf = isGreaterThan4GB(var)

            % Check if data size of the variable is greater than 2^32-1 
            % bytes (~4 GB). (logical, 1 x 1)
            tf = bytesOfVar(var) > 2^32-1;

        end

        function mustBeMember(input,validMembers)

            % Run the built-in validator.
            mustBeMember(input,validMembers);

        end

        function validateTableHasNecessaryVars(table,necessaryVarNames)
            %
            % Validate the table has all necessary variable names.
            %
            % <Input>
            %   table: (table, HEIGHT x WIDTH)
            %       EXPLANATION_FOR_INPUT1.
            %   necessaryVarNames: (text)
            %       EXPLANATION_FOR_INPUT2.

            % Get the table variable names. (cell, 1 x numNames)
            varNames = getTableVarNames(table);

            % Check the table has all the necessary variable names.
            if ~all(cellfun(@(x)any(strcmp(x,varNames)),necessaryVarNames))

                error( ...
                    "The table must have all the variable names %s.", ...
                    strJoinComma(necessaryVarNames) ...
                );

            end

        end

        function tfs = xyIsWithinMask(x,y,binMask,downsampleFactor)
            %
            % Check if each point (x,y) is located in the area of true
            % values in the binary mask.
            %
            % <Input>
            %   x, y: (numeric, vector)
            %       Coordinates of each point.
            %   binMask: (logical, M x N)
            %       A binary mask.
            % OPTION
            %   downsampleFactor: (numeric, 1 x 1)
            %       Downsample factor for the x and y coordinates to match
            %       the scale of the mask.
            %
            % <Output>
            %   tfs: (logical, numPoints x 1)
            %       Whether or not each point (x,y) is located within the
            %       area of true values in the mask.
            %

            arguments
                x                {Validator.mustBePosNumericVector}
                y                {Validator.mustBePosNumericVector}
                binMask          {Validator.mustBeLogical}
                downsampleFactor {Validator.mustBeDownsampleFactorFormat} = 1
            end

            % Number of x values.
            numXs = numel(x);

            % Validate the number of x and y matches.
            if numel(y) ~= numXs
                error("Number of x and y must match.");
            end

            % Height and width of the mask.
            [maskHei,maskWid] = size(binMask);

            % Convert the x and y to coordinates on the mask image.
            x = ceil(x/downsampleFactor);
            y = ceil(y/downsampleFactor);

            % NOTE:
            % x and y are always >= 1 but they could exceed the image bounds by 1 pixel
            % when x is at the very right end and/or y is at the very bottom end.

            % Replace x and y with width and height values if the index exceeds the
            % image bounds by 1 pixel.
            x(x == maskWid+1) = maskWid;
            y(y == maskHei+1) = maskHei;

            % Get the max of x and y.
            xMax = max(x);
            yMax = max(y);

            % Validate all the points within the mask.
            if xMax > maskWid || yMax > maskHei
                error("All points must be located within the mask image.");
            end

            % Initialize a logical array with false. (logical, numPoints x 1)
            tfs = false(numXs,1);

            % Set a true for a point that exist within the area of trues in the mask.
            for i = 1:numXs
                tfs(i) = binMask(y(i),x(i));
            end

        end

        % Base class.

        function mustBeA(input,classNames)

            % Run the built-in validator.
            mustBeA(input,classNames);

        end

        function mustBeA_alt(input,classNames)
            %
            % This is an alternative validation to mustBeA(). Check the
            % MATLAB version and use an alternative method if it's MATLAB
            % 2020a or older.
            %

            % Validations.
            if isMATLABReleaseOlderThan("R2020b")

                % Convert classNames to string.
                classNames = string(classNames);

                % Check if the class is valid.
                if ~any(strcmp(class(input),classNames))
                    error(...
                        "Value must be of the following types: '%s'.",...
                        strjoin(classNames,"' or '")...
                    );
                end

            else
                Validator.mustBeA(input,classNames);
            end

        end

        function mustBeCell(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) cell
            
            % Validations.
            validateattributes(input,{'cell'},{});
            
        end

        function mustBeCellVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) cell
            %       b) vector
            
            % Validations.
            Validator.mustBeA(input,"cell");
            Validator.mustBeVector(input);
            
        end

        function mustBeStruct(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (struct, M x N)

            % Validations.
            Validator.mustBeA(input,"struct");

        end

        function mustBeStructScalar(input)

            % Validations.
            Validator.mustBeStruct(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeLogical(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (logical, M x N)
            
            % Validations.
            Validator.mustBeA(input,"logical");
            
        end

        function tf = isLogical(input)

            % Run the built-in validator.
            tf = islogical(input);

        end

        function mustBeLogicalScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) logical (1 x 1)

            % Validations.
            Validator.mustBeA_alt(input,"logical");
            Validator.mustBeNumelOne(input);

        end

        function mustBeLogicalScalarOrEmpty(input)

            % Validations.

            if isempty(input)
                return;
            end

            Validator.mustBeLogicalScalar(input);

        end

        function mustBeHandleClass(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (handle, M x N)
            
            % Validations.
            Validator.mustBeA(input,"handle");
            
        end

        function tf = isHandleClass(input)

            % Check if the input is a handle class. (logical, 1 x 1)
            tf = isa(input,"handle");

        end

        function mustBeHandleClassScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (handle, 1 x 1)
            
            % Validations.
            Validator.mustBeHandleClass(input);
            Validator.mustBeNumelOne(input);
            
        end

        function mustBeFunctionHandle(input)

            % Validations.
            Validator.mustBeA(input,"function_handle");
            
        end

        function mustBeFunctionHandleScalar(input)

            % Validations.
            Validator.mustBeFunctionHandle(input);
            Validator.mustBeNumelOne(input);
            
        end
        
        function mustBeUiFigure(input)

            % Validations.
            Validator.mustBeA(input,"matlab.ui.Figure");

        end

        function tf = isUiFigure(input)

            % Check if the input is an UI figure handle. (logical, 1 x 1)
            tf = isa(input,"matlab.ui.Figure");

        end

        function mustBeUiFigureScalar(input)

            % Validations.
            Validator.mustBeUiFigure(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeAxes(input)
            
            % Validations.
            Validator.mustBeA(input,"matlab.graphics.axis.Axes");
            
        end

        function mustBeAxesScalar(input)

            % Validations.
            Validator.mustBeAxes(input);
            Validator.mustBeNumelOne(input);
            
        end

        function mustBeGroundTruth(input)
            
            % Validations.
            Validator.mustBeA(input,"groundTruth");
            
        end

        function tf = isGroundTruth(input)

            % Check if the input is a groundTruth object. (logical, 1 x 1)
            tf = isa(input,"groundTruth");

        end

        function mustBeGroundTruthScalar(input)
            
            % Validations.
            Validator.mustBeGroundTruth(input);
            Validator.mustBeNumelOne(input);
            
        end

        function mustBeLabelType(input)           
            
            % Validations.
            Validator.mustBeA(input,"labelType");
            
        end

        function mustBeLabelTypeScalar(input)

            % Validations.
            Validator.mustBeLabelType(input);
            Validator.mustBeNumelOne(input);
            
        end

        function mustBeRectangle(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (images.roi.Rectangle, M x N)

            % Validations.
            Validator.mustBeA(input,"images.roi.Rectangle");

        end

        function mustBeRectangleScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (images.roi.Rectangle, 1 x 1)

            % Validations.
            Validator.mustBeRectangle(input);
            Validator.mustBeNumelOne(input);

        end

        function tf = isValidRectangle(input)

            % Check if the input is a valid images.roi.Rectangle object.
            % (logical, 1 x 1)
            tf = Validator.objExists(input) && ...
                 Validator.isNonZeroSizeRectangle(input);

        end

        function tf = isNonZeroSizeRectangle(input)

            % Validate the input.
            Validator.mustBeRectangleScalar(input);

            tf = false;

            % Check if the input is an images.roi.Rectangle object with a
            % non-zero size. (logical, 1 x 1)

            if isempty(input.Position)
                return;
            end

            if input.Position(1,3) == 0 || input.Position(1,4) == 0
                return;
            end

            tf = true;

        end

        function tf = isBoxLabelDatastore(input)

            % Check if the input is boxLabelDatastore. (logical, 1 x 1)
            tf = isa(input,"boxLabelDatastore");

        end

        function tf = isGroundTruthDataSource(input)

            % Check if the input is groundTruthDataSource. (logical, 1 x 1)
            tf = isa(input,"groundTruthDataSource");

        end

        function tf = isCombinedDatastore(input)

            % Check if the input is CombinedDatastore. (logical, 1 x 1)
            tf = isa(input,"matlab.io.datastore.CombinedDatastore");

        end

        function tf = isYoloxObjectDetector(input)

            % Check if the input is yoloxObjectDetector. (logical, 1 x 1)
            tf = isa(input,"yoloxObjectDetector");

        end

        % Custom class.

        function mustBeFilePath(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (FilePath, M x N)

            % Validations.
            Validator.mustBeA(input,"FilePath");

        end

        function tf = isFilePath(input)

            % Check if the input is FilePath. (logical, 1 x 1)
            tf = isa(input,"FilePath");

        end

        function mustBeFilePathOrImageTile(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (FilePath, M x N) or (ImageTile, M x N)

            % Validations.
            if ~(Validator.isFilePath(input) || Validator.isImageTile(input))
                error("Value must be FilePath or ImageTile.");
            end

        end

        function mustBeFilePathScalar(input)

            % Validations.
            Validator.mustBeFilePath(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeRect(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (Rect, M x N)

            % Validations.
            Validator.mustBeA(input,"Rect");

        end

        function mustBeRectOrEmpty(input)

            % Validations.

            if isempty(input)
                return;
            end

            Validator.mustBeRect(input);

        end

        function mustBeRectScalar(input)

            % Validations.
            Validator.mustBeRect(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeRectVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (Rect, vector)

            % Validations.
            Validator.mustBeRect(input);
            Validator.mustBeVector(input);

        end

        function mustBeTile(input)

            % Validations.
            Validator.mustBeA(input,"Tile");

        end

        function mustBeObject(input)

            % Validations.
            Validator.mustBeA(input,"dl.od.Object");

        end

        function mustBeObjectContainer(input)

            % Validations.
            Validator.mustBeA(input,"dl.od.ObjectContainer");

        end

        function mustBeObjectContainerScalar(input)

            % Validations.
            Validator.mustBeObjectContainer(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeObjectOrEmpty(input)
            
            % Validations.
            
            if isempty(input)
                return;
            end
            
            Validator.mustBeObject(input);
            
        end

        function mustBeObjectScalar(input)

            % Validations.
            Validator.mustBeObject(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeDetectedObject(input)

            % Validations.
            Validator.mustBeA(input,"dl.od.dt.results.DetectedObject");

        end

        function tf = isDetectedObject(input)

            % Check if the input is DetectedObject. (logical, 1 x 1)
            tf = isa(input,"dl.od.dt.results.DetectedObject");

        end

        function mustBeDetectedObjectOrEmpty(input)

            % Validations.

            if isempty(input)
                return;
            end

            Validator.mustBeDetectedObject(input);

        end

        function mustBeClass(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (dl.Class, M x N)

            % Validations.
            Validator.mustBeA(input,"dl.Class");

        end
        
        function mustBeClassScalar(input)

            % Validations.
            Validator.mustBeClass(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeClassVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (dl.Class, vector)

            % Validations.
            Validator.mustBeClass(input);
            Validator.mustBeVector(input);

        end

        function mustBeColor(input)

            % Validations.
            Validator.mustBeA(input,"dl.Color");

        end

        function mustBeColorScalar(input)

            % Validations.
            Validator.mustBeColor(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeColorVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (dl.Color, vector)

            % Validations.
            Validator.mustBeColor(input);
            Validator.mustBeVector(input);

        end

        function mustBeScore(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (dl.Score, M x N)

            % Validations.
            Validator.mustBeA(input,"dl.Score");

        end

        function mustBeScoreScalar(input)

            % Validations.
            Validator.mustBeScore(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeLabel(input)

            % Validations.
            Validator.mustBeA(input,"dl.Label");

        end

        function mustBeLabelScalar(input)

            % Validations.
            Validator.mustBeLabel(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeClassColorContainer(input)

            % Validations.
            Validator.mustBeA(input,"dl.ClassColorContainer");

        end

        function mustBeClassColorContainerScalar(input)

            % Validations.
            Validator.mustBeClassColorContainer(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeImage(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (Image, M x N)

            % Validations.
            Validator.mustBeA(input,"Image");

        end

        function mustBeImageTile(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (ImageTile, M x N)

            % Validations.
            Validator.mustBeA(input,"ImageTile");

        end

        function tf = isImageTile(input)

            % Check if the input is ImageTile. (logical, 1 x 1)
            tf = isa(input,"ImageTile");

        end

        function mustBeImageTileScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (ImageTile, 1 x 1)

            % Validations.
            Validator.mustBeImageTile(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeImageTileReader(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (ImageTileReader M x N)
            %

            % Validations.
            Validator.mustBeA(input,"ImageTileReader");

        end

        function mustBeImageTileReaderScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (ImageTileReader 1 x 1)

            % Validations.
            Validator.mustBeImageTileReader(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeImageContainer(input)

            % Validations.
            Validator.mustBeA(input,"ImageContainer");

        end

        function mustBeImageContainerScalar(input)

            % Validations.
            Validator.mustBeImageContainer(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeImageObjectContainer(input)

            % Validations.
            Validator.mustBeA(input,"dl.od.ImageObjectContainer");

        end

        function mustBeImageObjectContainerScalar(input)

            % Validations.
            Validator.mustBeImageObjectContainer(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeDetectionResultContainer(input)

            % Validations.
            Validator.mustBeA(input,"dl.od.dt.results.DetectionResultContainer");

        end

        function mustBeDetectionResultContainerScalar(input)

            % Validations.
            Validator.mustBeDetectionResultContainer(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeDetectionResultFile(input)

            % Validations.
            Validator.mustBeA(input,"dl.od.dt.results.DetectionResultFile");

        end

        function mustBeDetectionResultFileScalar(input)

            % Validations.
            Validator.mustBeDetectionResultFile(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeDetectionResultTable(input)

            % Validations.
            Validator.mustBeA(input,"dl.od.dt.results.DetectionResultTable");

        end

        function mustBeDetectionResultTableScalar(input)

            % Validations.
            Validator.mustBeDetectionResultTable(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeEvaluateDetections(input)

            % Validations.
            Validator.mustBeA(input,"dl.od.eval.EvaluateDetections");

        end

        function mustBeEvaluateDetectionsScalar(input)

            % Validations.
            Validator.mustBeEvaluateDetections(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeGroundTruthContainer(input)

            % Validations.
            Validator.mustBeA(input,"dl.od.gt.GroundTruthContainer");
            
        end

        function tf = isGroundTruthContainer(input)

            % Check if the input is GroundTruthContainer.
            % (logical, 1 x 1)
            tf = isa(input,"dl.od.gt.GroundTruthContainer");

        end

        function tf = isCombinedGroundTruthContainer(input)

            % Check if the input is CombinedGroundTruthContainer. 
            % (logical, 1 x 1)
            tf = isa(input,"dl.od.gt.CombinedGroundTruthContainer");

        end

        function mustBeGroundTruthContainerScalar(input)

            % Validations.
            Validator.mustBeGroundTruthContainer(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeGroundTruthFile(input)

            % Validations.
            Validator.mustBeA(input,"dl.od.gt.GroundTruthFile");

        end

        function mustBeGroundTruthFileScalar(input)

            % Validations.
            Validator.mustBeGroundTruthFile(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeGroundTruthProperty(input)

            % Validations.
            Validator.mustBeA(input,"dl.od.gt.GroundTruthProperty");

        end

        function tf = isGroundTruthProperty(input)

            % Check if the input is GroundTruthProperty. (logical, 1 x 1)
            tf = isa(input,"dl.od.gt.GroundTruthProperty");

        end

        function mustBeGroundTruthPropertyOrEmpty(input)

            % Validations.

            if isempty(input)
                return;
            end

            Validator.mustBeGroundTruthProperty(input);

        end

        function mustBeGroundTruthPropertyScalar(input)

            % Validations.
            Validator.mustBeGroundTruthProperty(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeTrainingDataProperty(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) dl.od.gt.TrainingDataProperty

            % Validations.
            Validator.mustBeA(input,"dl.od.gt.TrainingDataProperty");

        end

        function mustBeViewerJsonController(input)

            % Validations.
            Validator.mustBeA(input,"ViewerJsonController");

        end

        function mustBeViewerJsonControllerScalar(input)

            % Validations.
            Validator.mustBeViewerJsonController(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeImageDatastore(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) matlab.io.datastore.ImageDatastore

            % Validations.
            Validator.mustBeA(input,"matlab.io.datastore.ImageDatastore");

        end

        function tf = isImageDatastore(input)

            % Check if the input is ImageDatastore. (logical, 1 x 1)
            tf = isa(input,"matlab.io.datastore.ImageDatastore");

        end

        function mustBeImageTileDatastore(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) ImageTileDatastore

            % Validations.
            Validator.mustBeA(input,"ImageTileDatastore");

        end

        function mustBeImageTileDatastoreScalar(input)

            % Validations.
            Validator.mustBeImageTileDatastore(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeImageTileObjectsDatastore(input)

            % Validations.
            Validator.mustBeA(input,"ImageTileObjectsDatastore");

        end

        function mustBeImageTileObjectsDatastoreScalar(input)

            % Validations.
            Validator.mustBeImageTileObjectsDatastore(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeImageTileDatastoreFamily(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (XXX, M x N)
            %          Objects that inherit from ImageTileDatastoreBase, 
            %          like ImageTileDatastore and ImageTileObjectsDatastore.

            % Validations.
            Validator.mustBeA(input,"ImageTileDatastoreBase");

        end

        function mustBeImageTileDatastoreFamilyScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (XXX, 1 x 1)
            %          An objects that inherits from ImageTileDatastoreBase, 
            %          like ImageTileDatastore and ImageTileObjectsDatastore.

            % Validations.
            Validator.mustBeImageTileDatastoreFamily(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeLineString(input)

            % Validations.
            Validator.mustBeA(input,"LineString");

        end

        function tf = isLineString(input)

            % Check if the input is LineString. (logical, 1 x 1)
            tf = isa(input,"LineString");

        end

        function tf = isMultiPoint(input)

            % Check if the input is a MultiPoint object. (logical, 1 x 1)
            tf = isa(input,"MultiPoint");

        end

        function tf = isPolygon(input)

            % Check if the input is a Polygon object. (logical, 1 x 1)
            tf = isa(input,"Polygon");

        end

        function tf = isMultiPolygon(input)

            % Check if the input is a MultiPolygon object. (logical, 1 x 1)
            tf = isa(input,"MultiPolygon");

        end
      
        function mustBePipeline(input)

            % Validations.
            Validator.mustBeA(input,"Pipeline");

        end

        function mustBePipelineScalar(input)

            % Validations.
            Validator.mustBePipeline(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeEventData(input)

            % Validations.
            Validator.mustBeA(input,"EventData");

        end

        function mustBeEventDataScalar(input)

            % Validations.
            Validator.mustBeEventData(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeExecutionEnvironment(input)

            % Validations.
            Validator.mustBeA(input,"ExecutionEnvironment");

        end

        function mustBeExecutionEnvironmentScalar(input)

            % Validations.
            Validator.mustBeExecutionEnvironment(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeOverlapRatioMethod(input)

            % Validations.
            Validator.mustBeA(input,"OverlapRatioMethod");

        end

        function mustBeOverlapRatioMethodScalar(input)

            % Validations.
            Validator.mustBeOverlapRatioMethod(input);
            Validator.mustBeNumelOne(input);

        end

        % Numeric.

        function mustBeNumeric(input)

            % Run the built-in validator.
            mustBeNumeric(input);

        end

        function tf = isNumeric(input)

            % Run the built-in validator.
            tf = isnumeric(input);

        end

        function mustBeNumericScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (1 x 1)

            % Validations.
            Validator.mustBeNumelOne(input);
            Validator.mustBeNumeric(input);

        end

        function mustBeNumericVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (1 x N or M x 1)

            % Validations.
            Validator.mustBeNumeric(input);
            Validator.mustBeVector(input);

        end

        function mustBeNumericRowPair(input)
            %
            % Throws an exception if input is not;
            %
            %   Values:
            %      a) numeric
            %      b) [1,2] size

            validateattributes(input,{'numeric'},{'row','numel',2})

        end

        function mustBeNumeric0Eto1EScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (1 x 1)
            %   Values:
            %       b) 0 < x < 1 (0 and 1 are exclusive)

            % Validations.
            Validator.mustBeNumelOne(input);
            validateattributes(input,{'numeric'},{'positive','<',1});

        end

        function mustBeNumeric0Eto1Scalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (1 x 1)
            %   Values:
            %       b) 0 < x <= 1 (0 is exclusive)

            % Validations.
            Validator.mustBeNumelOne(input);
            validateattributes(input,{'numeric'},{'positive','<=',1});

        end

        function mustBeNumeric0to1(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (M x N)
            %   Values:
            %       b) 0 <= x <= 1

            % Validations.
            validateattributes(input,{'numeric'},{'nonnegative','<=',1});

        end

        function mustBeNumeric0to1Scalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (1 x 1)
            %   Values:
            %       b) 0 <= x <= 1

            % Validations.
            Validator.mustBeNumeric0to1(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeNumeric0to1ScalarOrEmpty(input)

            % Validations.

            if isempty(input)
                return;
            end

            Validator.mustBeNumeric0to1Scalar(input);

        end

        function mustBeNumeric0to1ScalarOrNaN(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (1 x 1)
            %   Values:
            %       b) 0 <= x <= 1 or NaN
            
            % Validations.

            Validator.mustBeNumelOne(input);

            if isnan(input)
                return;
            end

            Validator.mustBeNumeric0to1Scalar(input);

        end

        function tf = isOdd(input)

            % Check if the input is an odd number (integer). (logical, 1 x 1)
            tf = mod(input,2) == 1;

        end

        function tf = isEven(input)

            % Check if the input is an even number (integer). (logical, 1 x 1)
            tf = mod(input,2) == 0;

        end

        function mustBeLessThan(input,value)

            % Run the built-in validator.
            mustBeLessThan(input,value);

        end

        function mustBeLessThanOrEqual(input,value)

            % Run the built-in validator.
            mustBeLessThanOrEqual(input,value);

        end

        function mustBeGreaterThan(input,value)

            % Run the built-in validator.
            mustBeGreaterThan(input,value);
            
        end

        function mustBeGreaterThanOrEqual(input,value)

            % Run the built-in validator.
            mustBeGreaterThanOrEqual(input,value);

        end

        function mustBeInteger(input)

            % Run the built-in validator.
            mustBeInteger(input);

        end

        function mustBeIntegerScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (1 x 1)

            Validator.mustBeInteger(input);
            Validator.mustBeNumelOne(input);

        end

        function mustBeNonnegative(input)

            % Run the built-in validator.
            mustBeNonnegative(input);

        end

        function mustBeNonNegNumericScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (numeric, 1 x 1)
            %   Values:
            %       b) nonnegative

            % Validations.

            Validator.mustBeNumericScalar(input);
            Validator.mustBeNonnegative(input);

        end

        function mustBeNonNegNumericScalarOrEmpty(input)

            % Validations.

            if isempty(input)
                return;
            end

            Validator.mustBeNonNegNumericScalar(input);

        end

        function mustBeNonNegInteger(input)
            %
            % Throws an exception if input is not;
            %
            %   Values:
            %       a) numeric
            %       b) integer
            %       c) nonnegative
            %

            validateattributes(input,{'numeric'},{'integer','nonnegative'})

        end

        function mustBeNonNegIntegerScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (1 x 1)
            %   Values:
            %       b) nonnegative
            %       c) integer

            Validator.mustBeNumelOne(input);
            Validator.mustBeNonNegInteger(input);

        end

        function mustBeNonNegIntegerVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Values:
            %       a) numeric
            %       b) integer
            %       c) nonnegative
            %       d) vector

            % Validations.
            Validator.mustBeNonNegInteger(input);
            Validator.mustBeVector(input);

        end
        
        function mustBePositive(input)

            % Run the built-in validator.
            mustBePositive(input);

        end

        function mustBePosNumericScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (numeric, 1 x 1)
            %   Values:
            %       b) positive

            % Validations.
            Validator.mustBeNumericScalar(input);
            Validator.mustBePositive(input);

        end

        function mustBePosNumericVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (numeric, vector)
            %   Values:
            %       b) positive
            %

            % Validations.
            Validator.mustBeNumericVector(input);
            Validator.mustBePositive(input);

        end

        function mustBePosInteger(input)
            %
            % Throws exception if input is not;
            %
            %   Size and class:
            %       a) numeric
            %       b) integer
            %       c) positive
            
            validateattributes(input,{'numeric'},{'integer','positive'});
            
        end

        function mustBePosIntegerScalar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (1 x 1)
            %   Values:
            %       b) positive
            %       c) integer

            Validator.mustBeNumelOne(input);
            Validator.mustBePosInteger(input);

        end

        function mustBePosIntegerScalarOrEmpty(input)

            % Validations.

            if isempty(input)
                return;
            end

            Validator.mustBePosIntegerScalar(input);

        end

        function mustBePosIntegerVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric
            %       b) integer
            %       c) positive
            %       d) vector

            % Validations.
            Validator.mustBePosInteger(input);
            Validator.mustBeVector(input);

        end

        function mustBeUint8(input)

            % Validations.
            if ~Validator.isUint8(input)
                error("Value must be uint8.");
            end

        end

        function mustBeUint8OrUint16(input)

            % Validations.
            if ~Validator.isUint8(input) && ~Validator.isUint16(input)
                error("Value must be uint8 or uint16.");
            end

        end

        function tf = isUint8(input)

            % Check if the class of the input is uint8. (logical, 1 x 1)
            tf = isa(input,"uint8");

        end

        function tf = isUint16(input)

            % Check if the class of the input is uint16. (logical, 1 x 1)
            tf = isa(input,"uint16");

        end

        % Size.

        function mustBeNonempty(input)

            % Run the built-in validator.
            mustBeNonempty(input);

        end

        function mustBeVector(input)

            % Run the built-in validator.
            mustBeVector(input);

        end

        function mustBeVector_alt(input)
            %
            % This is an alternative validation to mustBeVector(). Check
            % the MATLAB version and use an alternative method if it's
            % MATLAB R2020a or older.
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) M x 1 or 1 x N.

            if isMATLABReleaseOlderThan("R2020b")

                if ~(size(input,1) == 1 || size(input,2) == 1)
                    error("Value must be a 1-by-n vector or an n-by-1 vector.");
                end

            else
                Validator.mustBeVector(input);
            end

        end

        function mustBeRowVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) row vector (1 x N)

            % Validation
            validateattributes(input,{class(input)},{'row'});

        end

        function mustBeColVector(input)
            %
            % Throws exception if input is not;
            %
            %   Size and class:
            %      a) column vector (M x 1)

            validateattributes(input,{class(input)},{'column'});

        end

        function mustBeDims(input,numDims)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) number of demensions matches to numDims

            % Validate numDims
            Validator.mustBeNonNegIntegerScalar(numDims);

            % Validation
            validateattributes(input,{class(input)},{'ndims',numDims});

        end

        function mustBeSize(input,dims)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) size matches to dims
            %
            % <Input>
            %   dims: (numeric, 1 x N)
            %       Valid dimensions of the input. Ex. [2,3,4] Specify NaN
            %       if you want to skip checking the particular dimension.
            %       Ex. [3,4,NaN,2]

            % Validation
            validateattributes(input,{class(input)},{'size',dims});

        end

        function mustBeSameSize(input1,input2)
            %
            % Validate that the two input have the same size.
            %

            % Validations.
            if ~isequal(size(input1),size(input2))
                error("The size of the two values must be the same.");
            end

        end

        function mustBeNumRows(input,numRows)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (numRows x N)
            %

            % Validate numRows
            Validator.mustBeNonNegIntegerScalar(numRows);

            % Validation
            validateattributes(input,{class(input)},{'nrows',numRows});

        end

        function mustBeNumCols(input,numCols)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (M x numCols)

            % Validate numCols
            Validator.mustBeNonNegIntegerScalar(numCols);

            % Validation
            validateattributes(input,{class(input)},{'ncols',numCols});

        end

        function mustBeNumel(input,numEl)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) number of elements matches to numEl

            % NOTE:
            % Don't use validate numEl by a validation that uses this
            % validation mustBeNumel.

            % Validation
            validateattributes(input,{class(input)},{'numel',numEl});

        end

        function mustBeNumelOne(input)

            % Validations.
            Validator.mustBeNumel(input,1);

        end

        % Text.

        function mustBeText(input)

            % Run the built-in validator.
            mustBeText(input);

        end

        function mustBeText_alt(input)
            %
            % This is an alternative validation to mustBeText(). Check the
            % MATLAB version and use an alternative method if it's MATLAB
            % R2020a or older.
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (char, 1 x N) or
            %       b) (cell, M x N) < (char, M x 1), (char, 1 x N) or
            %       c) (string, M x N)
            %

            % NOTE:
            % mustBeText allows:
            % a) (char, 1 x N) or
            % b) (cell, M x N) < (char, 1 x N) or
            % c) (string, M x N)

            % NOTE:
            % mustBeText doesn't allow (cell, M x N) < (char, M x 1), but
            % this alternative validation allows it since iscellstr in
            % mustBeCellOfChars allows it.

            if isMATLABReleaseOlderThan("R2020b")

                % Validations.
                validateattributes(input,{'char','cell','string'},{});

                % If it's a cell, it must be a cell array of char vectors.
                if iscell(input)
                    Validator.mustBeCellOfChars(input);
                end

            else
                Validator.mustBeText(input);
            end

        end

        function tf = isText(input)

            % Check if input is text (a character array or string). (logical, 1 x 1)
            tf = ischar(input) || isstring(input);

        end

        function mustBeTextScalar(input)

            % Run the built-in validator.
            mustBeTextScalar(input);

        end

        function mustBeTextScalar_alt(input)
            %
            % This is an alternative validation to mustBeTextScalar().
            % Check the MATLAB version and use an alternative method if
            % it's MATLAB 2020a or older.
            %

            % Validations.
            if isMATLABReleaseOlderThan("R2020b")

                if ~Validator.isTextScalar(input)
                    error("Value must be a character vector or string scalar.");
                end

            else
                Validator.mustBeTextScalar(input);
            end

        end

        function mustBeTextScalarOrEmpty(input)

            % Validations.

            if isempty(input)
                return;
            end

            Validator.mustBeTextScalar(input);

        end

        function tf = isTextScalar(input)

            % Check if input is a scalar text, a char row vector or string
            % scalar. (logical, 1 x 1)
            tf = Validator.isCharRowVector(input) || ...
                 strcmp(input,'') || ...
                 (isstring(input) && isscalar(input));

            % NOTE:
            % '', "", and missing string are also scalar text.
            % See mustBeTextScalar().

        end

        function mustBeTextVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (char, 1 x N) or
            %       b) (cell, vector) < (char, 1 x N) or
            %       c) (string, vector)
            %   Values:
            %       b) CONDITION2
            %       c) CONDITION3
            %

            % Validations.
            Validator.mustBeText(input);
            Validator.mustBeVector(input);

        end

        function mustBeTextNonzeroLength(input)

            % Run the built-in validator.
            mustBeNonzeroLengthText(input);

        end

        function mustBeTextScalarNonzeroLength(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (text, 1 x 1)
            %   Values:
            %       b) Not '' or "".

            % Validate the input.
            Validator.mustBeTextScalar(input);
            Validator.mustBeTextNonzeroLength(input);

        end

        function tf = isTextZeroLength(input)
            %
            % Check if the input is '' or "".
            %

            tf = true;

            % Check the input.

            if ischar(input) && isempty(input)
                return;
            end

            if isstring(input) && isequal(input,"")
                return;
            end

            tf = false;

        end

        function mustBeTextAllAlphabetOrNumber(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (text, M x N)
            %   Values:
            %       b) All characters must be alphabet or number.

            % NOTE:
            % This accepts '' and "".

            % Validate it's text.
            Validator.mustBeText(input);

            if ~Validator.isTextAllAlphabetOrNumber(input)
                error("Text must consist of only alphabets and numbers.")
            end

        end

        function tf = isTextAllAlphabetOrNumber(input)
            %
            % <Input>
            %   input: (text, M x N)
            %       EXPLANATION_FOR_INPUT1.

            % Check that each character in each text is either an alphabet
            % letter or a number. (cell, M x N) < (logical, 1 x numCharacters)
            tfCell = isstrprop(input,'alphanum','ForceCellOutput',true);

            % Check that all the texts consist only of alphabet letters or
            % numbers. (logical, 1 x 1)
            tf = all(cellfun(@all,tfCell));

        end

        function mustBeCellOfChars(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (cell, M x N)
            %   Values:
            %       b) (char, M x 1) or (char, 1 x N)

            % Check if each cell element is char.
            if ~iscellstr(input)
                error( ...
                    "Value must be a cell array of character vectors or an " + ...
                    "empty cell." ...
                );
            end

        end

        function mustBeCellOfCharsRow(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) cell (1 x N)
            %   Values:
            %       b) char

            % Validations.
            Validator.mustBeRowVector(input);
            Validator.mustBeCellOfChars(input);

        end

        function mustBeCellOfCharsCol(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) cell (M x 1)
            %   Values:
            %       b) char

            % Validations.
            Validator.mustBeColVector(input);
            Validator.mustBeCellOfChars(input);

        end

        function mustBeChar(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (char, M x N)

            % Validations.
            validateattributes(input,{'char'},{});

        end

        function mustBeNonCharTextVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (cell, vector) < (char, 1 x N) or
            %       b) (string, vector)

            % Validations.
            Validator.mustBeTextVector(input);

            if Validator.isCharRowVector(input)
                error("A char row vector is not allowed.");
            end

        end

        function tf = isCharRowVector(input)

            % Check if the input is a row vector of characters 
            % (char, 1 x N) like 'abcdef'. (logical, 1 x 1)
            tf = ischar(input) && isrow(input);

        end

        function mustBeString(input)

            % Validations.
            Validator.mustBeA(input,"string");

        end

        function mustBeStringVector(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) string
            %       b) vector

            % Validations.
            Validator.mustBeString(input);
            Validator.mustBeVector(input);

        end

        function tf = isNumericString(input)

            % Check if the input is a numeric string. (logical, 1 x 1)

            expression = '^(\-|\+)?\d+(\.\d+$|$)';
            matched = regexp(input,expression,'match');

            tf = ~isempty(matched);

            % NOTE:
            % True : '-1', '+1', '1', '01', '0.1'
            % False: 'a', 'a1', '1a', '1.1.1', '1.'

        end

        function mustBeValidVarName(input)
            %
            % Validate that the input are valid variable names.
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (text, M x N)
            %   Values:
            %       b) A value that passes the isvarname() check with a
            %          true result. 
            %

            % Validate the input.
            Validator.mustBeText(input);

            % Convert the texts to string. (string, M x N)
            input = string(input);

            % Validate each text.
            for i = 1:numel(input)
                Validator.mustBeValidVarNameScalar(input(i));
            end

        end

        function mustBeValidVarNameScalar(input)
            %
            % Validate that the input is a valid variable name.
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (text, 1 x 1)
            %   Values:
            %       b) A value that passes the isvarname() check with a
            %          true result. 
            %

            % Validations.
            if ~Validator.isValidVarNameScalar(input)
                error( ...
                    "Input is not a valid variable name. A valid variable " + ...
                    "name begins with a letter and contains not more than " + ...
                    "namelengthmax() characters. Valid variable names can " + ...
                    "include letters, digits, and underscores. MATLAB " + ...
                    "keywords are not valid variable names. To determine " + ...
                    "if the input is a MATLAB keyword, use the iskeyword() " + ...
                    "function." ...
                );
            end

        end

        function tf = isValidVarNameScalar(input)
            %
            % Check if the input is a valid variable name.
            %
            % <Input>
            %   input: (text, 1 x 1)

            % Validate the input.
            Validator.mustBeTextScalar(input);

            % Run the built-in function. (logical, 1 x 1)
            tf = isvarname(input);

            % NOTE:
            % isvarname() expects the input to be either (char, 1 x N) or
            % (string, 1 x 1). 

        end

        function isValid = isValidDirNameScalar(input)
            %
            % Check if the input is a valid file name or folder name.
            %
            % <Input>
            %   input: (text, 1 x 1)

            % Validate the input.
            Validator.mustBeTextScalar(input);

            % Escape forbidden characters as a directory name in the text
            % to '_'.
            textEdited = escapeCharForFileName(input);

            % Check whether the text was edited. (logical, 1 x 1)
            isValid = strcmp(textEdited,input);

        end

        % XXX format.

        function mustBeRectMatFormat(input)
            %
            % Custom validator for rectangle position matrix.
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (M x 4)
            %   Values:
            %       b) positive
            %       c) integer
            %

            % Validations.
            Validator.mustBePosInteger(input);
            Validator.mustBeNumCols(input,4);

        end

        function mustBeHeiWidFormat(input)
            %
            % Custom validator for [height,width] format
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric (1 x 2)
            %   Values:
            %       b) integer
            %       c) positive

            % Validations.
            Validator.mustBeNumericRowPair(input);
            Validator.mustBePosInteger(input);

        end

        function mustBeHeiWidFormatOrEmpty(input)

            % Validations.

            if isempty(input)
                return;
            end

            Validator.mustBeHeiWidFormat(input);

        end

        function mustBeOverlapFormat(input)
            %
            % Throws exception if input is not;
            %
            %   Size and class:
            %       a) numeric
            %       b) integer
            %       c) nonnegative
            %       d) [1,2] size

            Validator.mustBeNumericRowPair(input);
            Validator.mustBeNonNegInteger(input);

        end

        function mustBePixelRegionFormat(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (1 x 2) size cell
            %   Values:
            %       b) (1 x 2) size numric array.
            %       c) values of the numeric array must be positive
            %          integers.

            % Validations.
            validateattributes(input,{'cell'},{'size',[1,2]});
            cellfun(@Validator.mustBeHeiWidFormat,input);

        end

        function mustBeRgbTripletsFormat(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (numeric, M x 3)
            %   Values:
            %       b) 0 <= value <=1

            % Validations.
            if ~Validator.isRgbTriplets(input)
                error( ...
                    "Value must be an M-by-3 numeric matrix with values in " + ...
                    "[0,1]." ...
                );
            end

        end

        function tf = isRgbTriplets(input)
            %
            % Check if the input is color defined as RGB triplets. Ex.
            % [0.5,0.3,1]
            %
            % <Input>
            %   input: (numeric, numColors x RGB)
            %       A matrix of RGB color values in the range of [0,1].
            %

            tf = false;

            if ~Validator.isNumeric(input)
                return;
            end

            if size(input,2) ~= 3
                return;
            end

            if ~all(input >= 0 & input <= 1)
                return;
            end

            tf = true;

        end

        function mustBeDownsampleFactorFormat(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) (numeric, 1 x 1)
            %   Values:
            %       b) values >= 1

            % Validations.
            Validator.mustBeNumelOne(input);
            Validator.mustBeGreaterThanOrEqual(input,1)

        end

        function mustBeMultiPointFormat(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) numeric
            %       b) [M,2] size

            Validator.mustBeNumeric(input);
            Validator.mustBeNumCols(input,2);

        end

        % File.

        function validateFileExtension(filePaths,validExts)
            %
            % Validate that the file paths have valid file extensions
            % (case-insensitive).
            %
            % <Input>
            %   paths: (text, M x N)
            %       File paths with file extensions.
            %   validExts: (text, M x N)
            %       Valid file extensions with a dot. Ex. {'.jp2','.tif'}

            % Check if the file paths have valid file extensions.
            % (logical, M x N)
            hasValidExt = Validator.hasValidFileExtension( ...
                filePaths, ...
                validExts ...
            );

            if all(hasValidExt,"all")
                return;
            end

            % Throw an error.
            error(...
                "The following file paths don't have valid file extensions." + "\n" + ...
                "'%s'"                                                       + "\n" + ...
                "Valid file extension: %s", ...
                strjoin(filePaths(~hasValidExt),"\n"), ...
                strJoinComma(validExts)...
            );

        end

        function tfs = hasValidFileExtension(filePaths,validExts)
            %
            % Check if the file paths have valid file extensions.
            % (case-insensitive).
            %
            % <Input>
            %   filePaths: (text, M x N)
            %       File paths with file extensions.
            %   validExts: (text, M x N)
            %       Valid file extensions with a dot. Ex. {'.txt','.jpg'}
            %
            % <Output>
            %   tfs: (logical, M x N)

            % Validate inputs.
            Validator.mustBeText(filePaths);
            Validator.mustBeText(validExts);

            % Convert the file paths to string. (string, M x N)
            filePaths = string(filePaths);

            % Initialize the output. (logical, M x N)
            tfs = false(size(filePaths));

            for i = 1:numel(filePaths)

                % Get the file extension of the file. (string, 1 x 1)
                [~,~,ext] = fileparts(filePaths(i));
    
                % Check if the file extension is one of valid extensions 
                % (case-insensitive). (logical, 1 x 1)
                tfs(i) = any(strcmpi(ext,validExts),"all");

            end

        end

        function validatePathsExist(paths)
            %
            % Throws an error if any of file or folder paths don't exist.
            %
            % <Input>
            %   paths: (text, M x N)
            %       Full paths of files or folders to be checked.
            %

            % Validate paths.
            Validator.mustBeText(paths);

            % Check if each file or folder path exists. (logical, M x N)
            tf = isfile(paths) | isfolder(paths);

            % Return if all paths exist.
            if all(tf,'all')
                return;
            end

            % Convert paths to a string array. (string, M x N)
            paths = string(paths);

            % Paths that don't exist (string, vector)
            pathsNotExist = paths(~tf);

            % Create a list of non existing paths. (string, vector)
            pathsNotExistList = compose("'%s'",pathsNotExist);

            % Throw an error.
            error( ...
                "Couldn't find the following file(s) or folder(s).\n" + ...
                "%s", ...
                strjoin(pathsNotExistList,newline) ...
            );

        end

        function validateFolderExists(path)
            %
            % Validate the folder of the folder or the file exists.
            %
            % <Syntax>
            %   FUN_NAME(INPUT1,INPUT2)
            %
            % <Input>
            %   path: (text, 1 x 1)
            %       Folder path or file path.

            [folder,~,~] = fileparts(path);
            Validator.validatePathsExist(folder);

        end

        function tf = fileIsEditable(filePath)
            %
            % Check if a file is editable.
            %

            % NOTE:
            % Return false if the file doesn't exist.

            tf = false;

            % Open the file in read/write mode.
            fid = fopen(filePath,'r+');

            % NOTE:
            % 'r+' doesn't create a new file and erase existing content.

            % Return false if it failed to open.
            if fid == -1
                return;
            end

            % Return true if the file is opened successfully.
            tf = true;

            % Close the opened file.
            fclose(fid);

        end

        function mustBeJPEG2000(input)
            %
            % Throws an exception if input is not;
            %
            %   Size and class:
            %       a) isJPEG2000()

            % Validations.
            if ~Validator.isJPEG2000(input)
                error("The data must be JPEG 2000 image.");
            end

        end

        function tf = isJPEG2000(imagePath)

            % Get the image format.
            format = imfinfo(imagePath).Format;

            % Check if the image file is in JPEG 2000 format. (logical, 1 x 1)
            tf = strcmp(format,"JP2");

        end

        function mustBeCapableReadRegion(input)

            % Validations.
            if ~Validator.isCapableReadRegion(input)
                error( ...
                    "The image format must allow reading a specific region " + ...
                    "only, using imread(imagePath,'PixelRegion',{rows, cols})." ...
                );
            end

        end

        function tf = isCapableReadRegion(imagePath)
            %
            % Check if the image is capable of reading a specific region
            % only by using 'PixelRegion' arguments in imread().
            %
            % NOTE:
            % a) Currently, only image formats of jp2, tiff, and
            %    one-column-width ngr are capable.
            % b) If ngr format is not registered in MATLAB file format 
            %    registry and the input image is an ngr, return false.
            %

            % Image format that allows reading a specific region only
            typeJp2 = 'JP2';
            typeTif = 'TIF';
            typeNgr = 'NGR';

            %----------------------------%

            % Validate the input.
            Validator.mustBeTextScalar(imagePath);

            tf = false;

            % Check if ngr format is in MATLAB file format registry to use imread().
            if isempty(imformats(typeNgr))
                imreadAcceptNgr = false;
            else
                imreadAcceptNgr = true;
            end

            % Check if the file is an ngr.
            if isNgr(imagePath)
                imageIsNgr = true;
            else
                imageIsNgr = false;
            end

            % Return false if ngr is not allowed to use imread() and the file is an ngr.
            if ~imreadAcceptNgr && imageIsNgr
                return;
            end

            % Get image information
            info = imfinfo(imagePath);

            % Valid image formats (cell, 1 x N)
            if imreadAcceptNgr
                validFormats = {typeJp2,typeTif,typeNgr};
            else
                validFormats = {typeJp2,typeTif};
            end

            % Return false if the image format is not valid.
            if ~any(strcmpi(info.Format,validFormats))
                return;
            end

            % Return false if it is ngr and is not one-column-width.
            if imageIsNgr && info.ColumnWidth ~= 1
                return;
            end

            tf = true;

        end

        function tf = isValidImageSize(imagePaths,imageHei,imageWid)
            %
            % Check if each image size is the specified size.
            %
            % <Input>
            %   imagePaths: (text, M x N)
            %       EXPLANATION_FOR_INPUT1.
            %   INPUT2: (CLASS, HEIGHT x WIDTH)
            %       EXPLANATION_FOR_INPUT2.
            %
            % <Output>
            %   tf: (logical, M x N)
            %       EXPLANATION_FOR_OUTPUT.

            % Convert imagePaths to a string array. (string, M x N)
            imagePaths = string(imagePaths);

            % Logical indices of images if the size is different from the specified
            % image size. (logical, M x N)
            tfDifferent = arrayfun( ...
                @(x)Validator.isDifferentSize(x,imageHei,imageWid), ...
                imagePaths ...
            );

            % Return the indices of the image files that match the specified size.
            % (logical, M x N)
            tf = ~tfDifferent;

        end

    end

    methods (Static, Access = private)

        function tf = isDifferentSize(imagePath,imageHei,imageWid)

            % Get image info.
            info = imfinfo(imagePath);

            % Check if the image size is the same.
            tf = (info.Height ~= imageHei || info.Width ~= imageWid);

            % NOTE:
            % Checking if it's different is faster.

        end

    end

end