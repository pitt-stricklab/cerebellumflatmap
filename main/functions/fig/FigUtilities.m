classdef FigUtilities < handle
    %
    % Utility class for figure and axes operations, such as checking
    % whether the cursor is inside the axes area, retrieving the current
    % cursor position, and obtaining axes area position.
    %

    % HISTORY:
    %   1.0 - 20250618 Written by Mitsu
    %

    properties (Access = private)
        
        hFigure
        hAxes

    end

    methods (Access = public)
        
        % Constructor.
        
        function obj = FigUtilities( ...
                hFigure, ...
                hAxes ...
            )
            %
            % <Input>
            %   INPUT1: (CLASS, HEIGHT x WIDTH)
            %       EXPLANATION_FOR_INPUT1.
            %   INPUT2: (CLASS, HEIGHT x WIDTH)
            %       EXPLANATION_FOR_INPUT2.
            %
            
            % Store the input handles.
            obj.hFigure = hFigure;
            obj.hAxes   = hAxes;
            
        end

        function tf = isCursorInAxes(obj)
            
            % Get the current cursor point. (double, 1 x 2)
            currentPoint = obj.getCurrentCursorPoint();

            % Get the current position of the axes area in arbitrary units.
            [axesX,axesY] = obj.getCurrentAxesAreaPosition();

            % Get the current size of the axes area in arbitrary units.
            [axesWidth,axesHeight] = obj.getCurrentAxesAreaSize();

            % Check whether the cursor is inside the axes area.
            tf = currentPoint(1) >= axesX && currentPoint(1) <= axesX + axesWidth && ...
                 currentPoint(2) >= axesY && currentPoint(2) <= axesY + axesHeight;

        end

        function currentPoint = getCurrentCursorPoint(obj)

            % Return the current X and Y position of the cursor relative to
            % the lower-left corner of the figure in arbitrary units.
            % (double, 1 x 2)
            currentPoint = obj.hFigure.CurrentPoint;
            
            % NOTE:
            % Units are as specified by the Axes' Units property.

        end

        function [axesWidth,axesHeight] = getCurrentAxesAreaSize(obj)

            % Return the current size of the axes area in arbitrary units.
            axesWidth  = obj.hAxes.InnerPosition(3);
            axesHeight = obj.hAxes.InnerPosition(4);

        end

    end

    methods (Access = private)
        
        function [axesX,axesY] = getCurrentAxesAreaPosition(obj)

            % Return the current position of the axes area in arbitrary
            % units.
            axesX = obj.hAxes.InnerPosition(1);
            axesY = obj.hAxes.InnerPosition(2);

        end
        
    end
    
end