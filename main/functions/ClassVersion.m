classdef (Abstract) ClassVersion < handle
    %
    % Abstract class for maintaining the version of the class definition.
    %

    % HISTORY:
    %   1.0 - 20241025 Written by Mitsu

    properties (Constant, Abstract)

        % Version of the class definition.
        cClassVersion {Validator.mustBeNonNegNumericScalar}

    end

    properties (Access = protected, Constant)

        % Property names.
        cPropertyNameClassVersion = "cClassVersion";

    end

    methods (Access = protected)

        function version = getVersion(obj)

            % Return the current class definition version.
            version = obj.cClassVersion;

        end

    end

end