classdef EnableCustomFigureZoomPan < handle
    %
    % This class enables custom zoom and pan for MATLAB figures,
    % restoring standard-like interactions even when custom mouse callbacks
    % are used.
    %
    % By default, assigning callbacks to WindowButtonDownFcn,
    % WindowButtonMotionFcn, or WindowButtonUpFcn disables MATLAB's
    % built-in zoom and pan, including scroll wheel zoom and drag-to-pan.
    % 
    % NOTE:
    % Instantiating this class with a UIFigure, UIAxes, and a function
    % handle for WindowButtonMotionFcn automatically enables zooming and
    % panning that mimic MATLAB's default behavior, while also executing
    % the custom motion callback on mouse movement. No further method calls
    % are required.

    % HISTORY:
    %   1.0 - 20250617 Written by Mitsu
    %   1.1 - 20250618 Fixed a bug that allowed zooming and panning outside
    %                  the axes area.
       
    properties (Access = private)

        hFigure
        hAxes

        hFigUtilities

        pIsPanning
        pLastPoint

        pImagePlacementX
        pImagePlacementY

        pValueRangeMinX
        pValueRangeMinY

        pImageAspect
        
        pZoomFactor = 1.1;

    end

    methods (Access = public)
        
        % Constructor.
        
        function obj = EnableCustomFigureZoomPan( ...
                hFigure, ...
                hAxes, ...
                hWindowButtonMotionFcn ...
            )
            %
            % <Input>
            %   INPUT1: (CLASS, HEIGHT x WIDTH)
            %       EXPLANATION_FOR_INPUT1.
            %   INPUT2: (CLASS, HEIGHT x WIDTH)
            %       EXPLANATION_FOR_INPUT2.
            %

            arguments
                hFigure {}
                hAxes {}
                hWindowButtonMotionFcn {Validator.mustBeFunctionHandleScalar} = []
            end
            
            % Store the input handles.
            obj.hFigure = hFigure;
            obj.hAxes   = hAxes;

            % Create a FigUtilities. (FigUtilities, 1 x 1)
            obj.hFigUtilities = FigUtilities(obj.hFigure,obj.hAxes);

            % Get an image handle in the axes.
            hImage = findobj(obj.hAxes,"Type","image");

            % Store the placement along the X and Y axes of the image.
            obj.pImagePlacementX = hImage.XData;
            obj.pImagePlacementY = hImage.YData;

            % Store the minimum range of axis values as  the value
            % difference per pixel.
            obj.pValueRangeMinX = obj.calcValueRangeMin(obj.pImagePlacementX);
            obj.pValueRangeMinY = obj.calcValueRangeMin(obj.pImagePlacementY);

            % Store the image aspect ratio based on the placement values.
            obj.pImageAspect = obj.calcValueRange(obj.pImagePlacementX) / ...
                               obj.calcValueRange(obj.pImagePlacementY);

            % Configure the axes toolbar.
            obj.configAxesToolbar();

            % Initialize properties.
            obj.pIsPanning = false;
            obj.pLastPoint = [0,0];

            % Set callbacks for mouse controls on the figure.
            obj.hFigure.WindowButtonDownFcn = ...
                @(~,~)obj.windowButtonDownFcn();
            obj.hFigure.WindowButtonUpFcn = ...
                @(~,~)obj.windowButtonUpFcn();
            obj.hFigure.WindowButtonMotionFcn = ...
                @(~,~)obj.windowButtonMotionFcn(hWindowButtonMotionFcn);
            obj.hFigure.WindowScrollWheelFcn = ...
                @(~,event)obj.WindowScrollWheelFcn(event);

        end

    end

    methods (Access = private)

        function valueRangeMin = calcValueRangeMin(obj,imagePlacement)

            numPlacements = numel(imagePlacement);

            if numPlacements == 2
                numPixels = imagePlacement(end);
            else
                numPixels = numPlacements;
            end

            % Define the minimum range of axis values as the value
            % difference per pixel.
            valueRangeMin = obj.calcValueRange(imagePlacement)/numPixels;

        end

        function valueRange = calcValueRange(obj,imagePlacement)

            % Calculate the value range of the placement along the image
            % axes.
            valueRange = abs(imagePlacement(1)-imagePlacement(end));

        end

        function configAxesToolbar(obj)

            % Create an axes toolbar containing only the default export
            % button.
            tb = axtoolbar(obj.hAxes,{'export'});

            % Add the "restoreview" button.
            btn = axtoolbarbtn(tb,"push");
            btn.Icon = "restoreview";
            btn.Tooltip = "Restore view";
            btn.ButtonPushedFcn = @(~,~)obj.restoreView();

            % NOTE:
            % a) At present, if you use this class to implement zoom and
            %    pan on a figure, the default zoom, pan, and data cursor
            %    tools do not function correctly.
            % b) Since the default "restoreview" button also does not
            %    function correctly as is, set a callback to reproduce its
            %    normal behavior.

        end

        function restoreView(obj)

            % Reset the axes limits.
            obj.hAxes.XLim = [obj.pImagePlacementX(1),obj.pImagePlacementX(end)];
            obj.hAxes.YLim = [obj.pImagePlacementY(1),obj.pImagePlacementY(end)];

        end

        function windowButtonDownFcn(obj)

            if ~obj.hFigUtilities.isCursorInAxes()
                return;
            end

            % Store the current cursor point. (double, 1 x 2)
            obj.pLastPoint = obj.hFigUtilities.getCurrentCursorPoint();

            % Set the pan state to active.
            obj.pIsPanning = true;

        end

        function windowButtonUpFcn(obj)

            % Set the pan state to inactive.
            obj.pIsPanning = false;

            % NOTE:
            % To ensure that panning stops even if the mouse is released
            % outside the axes area, do not check the axes area when
            % handling the release event.

        end

        function windowButtonMotionFcn(obj,hFunction)

            % If pan is not active, execute the specified function.
            if ~obj.pIsPanning && ~isempty(hFunction)
                hFunction();
                return;
            end

            if ~obj.hFigUtilities.isCursorInAxes()
                return;
            end

            % Get the current cursor point. (double, 1 x 2)
            currentPoint = obj.hFigUtilities.getCurrentCursorPoint();
            
            % Calculate the displacement of the cursor between the current
            % and previous positions. (double, 1 x 2)
            delta = currentPoint - obj.pLastPoint;

            % Store the current cursor point.
            obj.pLastPoint = currentPoint;
            
            % Get the value range of the currently displayed data.
            valueRangeX = obj.getCurrentValueRange(obj.hAxes.XLim);
            valueRangeY = obj.getCurrentValueRange(obj.hAxes.YLim);

            % Get the current size of the axes area in arbitrary units.
            [axesWidth,axesHeight] = ...
                obj.hFigUtilities.getCurrentAxesAreaSize();
            
            % Convert the cursor displacement to the corresponding data
            % value displacement.
            valueMoveX = valueRangeX * delta(1) / axesWidth;
            valueMoveY = valueRangeY * delta(2) / axesHeight;
            
            % Shift the data range of the axes.
            axisLimNewX = obj.hAxes.XLim - valueMoveX;
            axisLimNewY = obj.hAxes.YLim + valueMoveY;

            % Clip the axis limit to the placement range along the image
            % axes.
            obj.hAxes.XLim = obj.clipAxesLimit( ...
                axisLimNewX, ...
                obj.pImagePlacementX ...
            );
            obj.hAxes.YLim = obj.clipAxesLimit( ...
                axisLimNewY, ...
                obj.pImagePlacementY ...
            );                

        end

        function valueRange = getCurrentValueRange(obj,limit)

            % Return the current axis value range.
            valueRange = abs(limit(1) - limit(2));

        end

        function axisLim = clipAxesLimit(obj,axisLim,imagePlacement)

            % Clip the axis limit to the placement range along the image
            % axes.

            axisLimMin = axisLim(1);
            axisLimMax = axisLim(2);
            valueMin = imagePlacement(1);
            valueMax = imagePlacement(end);
            
            if axisLimMin < valueMin
                axisLim = axisLim + (valueMin - axisLimMin);
            end

            if axisLimMax > valueMax
                axisLim = axisLim - (axisLimMax - valueMax);
            end

            if abs(axisLimMin - axisLimMax) > obj.calcValueRange(imagePlacement)
                axisLim = [valueMin,valueMax];
            end

        end

        function WindowScrollWheelFcn(obj,event)

            if ~obj.hFigUtilities.isCursorInAxes()
                return;
            end
        
            % Calculate the zoom level based on the scroll count.
            zoomLevel = obj.pZoomFactor^event.VerticalScrollCount;
        
            % Get the value range of the currently displayed data.
            valueRangeX = obj.getCurrentValueRange(obj.hAxes.XLim);            
        
            % Calculate the value range after zooming.
            valueRangeNewX = valueRangeX * zoomLevel;

            % Use the greater of the calculated range and the minimum range.
            valueRangeNewX = obj.selectGraterValueRange( ...
                valueRangeNewX, ...
                obj.pValueRangeMinX ...
            );

            % Scale the axis range about the center of the axis area.
            obj.hAxes.XLim = obj.scaleAxesLimitAtCenter( ...
                valueRangeNewX, ...
                obj.hAxes.XLim, ...
                obj.pImagePlacementX ...
            );

            % Calculate the Y-axis range based on the X-axis range while
            % maintaining the image aspect ratio.
            valueRangeNewY = valueRangeNewX / obj.pImageAspect;

            % Use the greater of the calculated range and the minimum range.
            valueRangeNewY = obj.selectGraterValueRange( ...
                valueRangeNewY, ...
                obj.pValueRangeMinY ...
            );

            % Scale the axis range about the center of the axis area.
            obj.hAxes.YLim = obj.scaleAxesLimitAtCenter( ...
                valueRangeNewY, ...
                obj.hAxes.YLim, ...
                obj.pImagePlacementY ...
            );

        end

        function valueRange = selectGraterValueRange(obj,valueRange,valueRangeMin)

            % Use the greater of the calculated range and the minimum range.
            valueRange = max(valueRange,valueRangeMin);

        end

        function axisLim = scaleAxesLimitAtCenter(obj, ...
                valueRange, ...
                axisLim, ...
                imagePlacement ...
            )

            valueRangeHalf = valueRange/2;
        
            % Get the central value of the axis region.
            valueMean = mean(axisLim);

            % Clip the center of the axes area and calculate the new value
            % range.
            axisLimXNew = [
                valueMean - valueRangeHalf, ...
                valueMean + valueRangeHalf
            ];
        
            % Clip the axis limit to the placement range along the image
            % axes.
            axisLim = obj.clipAxesLimit(axisLimXNew,imagePlacement);

        end      

    end
    
end