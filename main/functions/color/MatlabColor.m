classdef MatlabColor < handle
    %
    % Handle color codes that are generally used in Matlab.
    %

    % HISTORY:
    %   1.0 - YYYYMMDD Written by Mitsu
    %   2.0 - 20220830 a) Renamed from ColorString to MatlabColor.
    %                  b) Changed from Static methods to a handle.
    %                  c) Created getCode() and allow to return short name,
    %                     RGB triplets, and hexadecimal too.
    
    properties (Constant)

        % Valid type names.
        pTypeName        = "name";
        pTypeShort       = "short";
        pTypeTriplet     = "triplet";
        pTypeHexadecimal = "hexadecimal";

    end

    properties (Access = private)      
        
        % Valid color names. (string, M x 1)
        pColorNames = [
            "red"; ...
            "green"; ...
            "blue"; ...
            "cyan"; ...
            "magenta"; ...
            "yellow"; ...
            "black"; ...
            "white"; ...
            ""; ...
            ""; ...
            ""; ...
            ""; ...
            ""; ...
            ""; ...
            ""; ...
        ];
        
        % Valid short color names. (string, M x 1)
        pColorNamesShort = [
            "r"; ...
            "g"; ...
            "b"; ...
            "c"; ...
            "m"; ...
            "y"; ...
            "k"; ...
            "w"; ...
            ""; ...
            ""; ...
            ""; ...
            ""; ...
            ""; ...
            ""; ...
            ""; ...
        ];
        
        % Valid RGB triplet values. (double, M x 3)
        pTripletValues = [
            1 0 0;
            0 1 0;
            0 0 1;
            0 1 1;
            1 0 1;
            1 1 0;
            0 0 0;
            1 1 1;
            0      0.4470 0.7410;
            0.8500 0.3250 0.0980;
            0.9290 0.6940 0.1250;
            0.4940 0.1840 0.5560;
            0.4660 0.6740 0.1880;
            0.3010 0.7450 0.9330;
            0.6350 0.0780 0.1840;
        ];
        
        % Valid hexadecimal codes. (string, M x 1)
        pHexadecimals = [
            "#FF0000"; ...
            "#00FF00"; ...
            "#0000FF"; ...
            "#00FFFF"; ...
            "#FF00FF"; ...
            "#FFFF00"; ...
            "#000000"; ...
            "#FFFFFF"; ...
            "#0072BD"; ...
            "#D95319"; ...
            "#EDB120"; ...
            "#7E2F8E"; ...
            "#77AC30"; ...
            "#4DBEEE"; ...
            "#A2142F"; ...
        ];

    end

    methods (Access = public)

        function code = getCode(obj,id,type)
            %
            % Return color code of the index in the format.
            %
            
            % Validate the inputs.
            Validator.mustBePosIntegerScalar(id);
            Validator.mustBeTextScalar(type);

            % Validate the type. (string, 1 x 1)
            type = validatestring(type, ...
                [ ...
                    obj.pTypeName, ...
                    obj.pTypeShort, ...
                    obj.pTypeTriplet, ...
                    obj.pTypeHexadecimal ...
                ] ...
            );

            % Get all codes of the type. (string, M x 1) or (double, M x 3)
            switch type
                case obj.pTypeName
                    codes = obj.pColorNames;
                case obj.pTypeShort
                    codes = obj.pColorNamesShort;
                case obj.pTypeTriplet
                    codes = obj.pTripletValues;
                case obj.pTypeHexadecimal
                    codes = obj.pHexadecimals;
            end

            % Get the color code of the index. (string, 1 x 1) or (double, 1 x 3)
            code = codes(id,:);

            % Throw an error there is no color code for the index.
            if isstring(code) && code == ""
                error("There is no color code of the type for the index.");
            end

        end

        function colorNames = validateColorNames(obj,colorNames)
            %
            % Validate color names.
            %
            % <Input>
            %   colorNames: (text, M x N)
            %       Color names to validate.
            %   
            % <Output>
            %   colorNames: (string, M x N)
            %       Validated color names in the same size as the input.
            %

            % Validate the color names.
            Validator.mustBeText(colorNames);
            
            % Convert to strings. (string, M x N)
            colorNames = string(colorNames);
            
            % Get valid color names. (string, M x 1)
            validNames = obj.getValidColorNames();
            
            % Number of color names.
            numNames = numel(colorNames);

            for i = 1:numNames
                
                % Validate each color names. (string, M x N)
                colorNames(i) = validatestring(...
                    colorNames(i),...
                    validNames...
                );
            
            end
            
        end

        function rgbTriplets = convertToRgbTriplets(obj,colorName)
            %
            % Convert the color name to an RGB triplets.
            %
            % <Input>
            %   colorName: (text, 1 x 1)
            %       A color name.

            % Validate the input.
            Validator.mustBeTextScalar(colorName);
            
            % Validate the color name. (string, 1 x 1)
            colorName = obj.validateColorNames(colorName);

            % Get the valid color names. (string, M x 1)
            validColorNames = obj.getValidColorNames();

            % Get the id of the color. (double, 1 x 1)
            id = find(strcmp(colorName,validColorNames));

            % Return the RGB triplets of the color. (double, 1 x RGB)
            rgbTriplets = obj.pTripletValues(id,:);

        end

        % Get info.

        function num = numColorNames(obj)

            % Return the number of color names available.
            num = numel(obj.getValidColorNames());

        end

        function num = numColorCodes(obj)

            % Return the number of color codes available.
            num = numel(obj.pColorNames);

        end
        
    end

    methods (Access = private)

        function values = getValidColorNames(obj)

            % Get valid color names. (string, M x 1)
            values = obj.pColorNames;

            % Remove empty names.
            values(values == "") = [];
            
        end

    end

end

