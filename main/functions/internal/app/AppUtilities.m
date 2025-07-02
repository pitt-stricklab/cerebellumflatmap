classdef AppUtilities < handle
    %
    % A class containing utility methods for application development.
    %

    % HISTORY: uiConfirm()
    %   1.0 - YYYYMMDD Written by Mitsu
    %   1.1 - 20210908 Changed mustBeTextScalar() to mustBeTextScalar_alt() to
    %                  be compatible to MATLAB R2020a or older.

    % HISTORY:
    %   1.0 - 20240912 Written by Mitsu
    %   1.1 - 20240913 a) Renamed showAlert() to showAlertDialog().
    %                  b) Migrated uiConfirm() to showConfirmationDialog(),
    %                     uiAlertFileIsNotSelected() to
    %                     showAlertDialogFileNotSelected(),
    %                     uiConfirmWarningInvalidFile() to
    %                     showAlertDialogInvalidFile(), uiGetValidExtFile()
    %                     to askUserToSpecifyFileToInput(), and
    %                     uiPutValidExtFile() to
    %                     askUserToSpecifyFileToOutput().
    %   1.2 - 20241002 a) Added setFigureName().
    %                  b) Make specifying the file extension optional in
    %                     askUserToSpecifyFileToInput() and
    %                     askUserToSpecifyFileToOutput().
    %   1.3 - 20250508 Added showFigure() and hideFigure().
    %   1.4 - 20250626 Added handleException().
    %   1.5 - 20250627 Added markAsFatalExceptionAndThrow().
    %   1.6 - 20250702 Added runWithErrorHandling().
    
    properties (Constant)

        pIconTypeError    = "error";
        pIconTypeWarning  = "warning";
        pIconTypeInfo     = "info";
        pIconTypeQuestion = "question";
        pIconTypeSuccess  = "success";

        pExceptionIdentifiersFatal = "App:FatalError";

    end

    properties (Access = private)
        
        UIFigure
        
        % (matlab.ui.dialog.ProgressDialog, 1 x 1)
        hProgressDialog

        pLastSelectedFolder

        pButtonTextCancel = "Cancel";

    end

    methods (Access = public)

        % Constructor.
        
        function obj = AppUtilities(UIFigure)
            %
            % <Input>
            %   UIFigure: (matlab.ui.Figure, 1 x 1)
            %       EXPLANATION_FOR_INPUT1.
            %
            
            % Validate the input.
            Validator.mustBeUiFigureScalar(UIFigure);

            % Store the app handle.
            obj.UIFigure = UIFigure;
            
        end

        % Set figure name.

        function setFigureName(obj,name)

            % Validate the input.
            Validator.mustBeTextScalar(name);

            % Set the figure name.
            obj.UIFigure.Name = name;

        end

        % Show / Hide figure.
        
        function showFigure(obj)

            % Show the figure.
            obj.UIFigure.Visible = "on";

        end

        function hideFigure(obj)

            % Hide the figure.
            obj.UIFigure.Visible = "off";

        end

        % Last selected folder.

        function folder = getLastSelectedFolder(obj)
            
            % Return the last selected folder. (string, 1 x 1) or []
            folder = obj.pLastSelectedFolder;

        end

        function setLastSelectedFolder(obj,folder)

            % Validate the input.
            Validator.mustBeTextScalar(folder);

            % Set the last selected folder. (string, 1 x 1)
            obj.pLastSelectedFolder = string(folder);

        end

        % Progress dialog.
        
        function showProgressDialog(obj,message)

            % Show a progress dialog.
            obj.hProgressDialog = uiprogressdlg( ...
                obj.UIFigure, ...
                Indeterminate = "on", ...
                Message = message ...
            );

        end

        function updateProgressDialog(obj,message)

            % Update the progress dialog message.
            obj.hProgressDialog.Message = message;

        end

        function deleteProgressDialog(obj)

            % Delete the current progress dialog.
            if Validator.objExists(obj.hProgressDialog)
                delete(obj.hProgressDialog);
            end

        end

        % Alert dialog.

        function showAlertDialog(obj,message,options)

            arguments
                obj {}
                message {}
                options.title {} = "Error"
                options.iconType {} = obj.pIconTypeError
                options.pauseUntilAcknowledged ...
                    {Validator.mustBeLogicalScalar} = false
            end

            pauseUntilAcknowledged = options.pauseUntilAcknowledged;

            if pauseUntilAcknowledged
                closeFun = @(~,~)uiresume(obj.UIFigure);
            else
                closeFun = '';
            end

            % Show an alert dialog.
            uialert( ...
                obj.UIFigure, ...
                message, ...
                options.title, ...
                "Icon",options.iconType, ...
                "CloseFcn",closeFun ...
            );

            % Wait until the user press the OK button or close the dialog.
            if pauseUntilAcknowledged
                uiwait(obj.UIFigure);
            end

        end

        function showAlertDialogFileNotSelected(obj,fileType,options)
            %
            % Show an alert dialog stating that the file is not selected.
            %

            arguments
                obj {}
                fileType {Validator.mustBeTextScalar}
                options.pauseUntilAcknowledged {} = false
            end

            % Show an alert dialog.
            obj.showAlertDialog( ...
                sprintf("%s is not selected yet.",fileType), ...
                title = "Warning", ...
                iconType = obj.pIconTypeWarning, ...
                pauseUntilAcknowledged = options.pauseUntilAcknowledged ...
            );

        end

        function showAlertDialogInvalidFile(obj,validExts,options)
            %
            % Show an alert dialog stating that the file extension in not
            % valid.
            %

            arguments
                obj {}
                validExts {Validator.mustBeText}
                options.pauseUntilAcknowledged {} = false
            end

            % Show an alert dialog.
            obj.showAlertDialog( ...
                sprintf(...
                    "The file extnsion is not valid.\n" + ...
                    "Acceptable extensions are: %s.",...
                    strJoinComma(validExts)...
                ), ...
                title = "Warning", ...
                iconType = obj.pIconTypeWarning, ...
                pauseUntilAcknowledged = options.pauseUntilAcknowledged ...
            );

        end

        % Confirmation dialog.

        function userCanceled = showConfirmationDialog(obj,message,options)

            arguments
                obj {}
                message {}
                options.title {} = "Confirmation"
                options.buttonTextOption {Validator.mustBeTextScalar} = "OK"
                options.iconType {} = obj.pIconTypeQuestion
            end

            buttonTextOption = options.buttonTextOption;

            % Convert the text to string.
            buttonTextOption = string(buttonTextOption);

            % Show a confirmation dialog. (char, 1 x N)
            selection = uiconfirm( ...
                obj.UIFigure, ...
                message, ...
                options.title, ...
                "Options",[buttonTextOption,obj.pButtonTextCancel], ...
                "DefaultOption",1, ...
                "CancelOption",2, ...
                "Icon",options.iconType ...
            );

            % Return whether or not the user has canceled.
            % (logical, 1 x 1)
            userCanceled = strcmp(selection,obj.pButtonTextCancel);

        end

        % Ask users to specify file and folder paths.

        function [fileNames,folder] = askUserToSpecifyFileToInput(obj, ...
                fileType, ...
                options ...
            )
            %
            % <Input>
            %   fileType: (text, 1 x 1)
            % Options
            %   validExts: (text, M x N)
            %   defaultFilePath: (text, 1 x 1)
            %   allowMultiSelect: (logical, 1 x 1)
            %
            % <Output>
            %   fileNames: (string, numFiles x 1) or []
            %   folder: (string, 1 x 1) or []

            arguments
                obj {}
                fileType {}
                options.validExts {} = ''
                options.defaultFolderPath {} = ''
                options.allowMultiSelect {} = false
            end

            % Ask user to specify file(s) to input.
            [fileNames,folder] = askUserToSpecifyFile(obj, ...
                false, ... % Whether to output
                fileType, ...
                validExts = options.validExts, ...
                defaultPath = options.defaultFolderPath, ...
                allowMultiSelect = options.allowMultiSelect ...
            );

        end

        function [fileName,folder] = askUserToSpecifyFileToOutput(obj, ...
                fileType, ...
                options ...
            )
            %
            % <Input>
            %   fileType: (text, 1 x 1)
            %   validExts: (text, M x N)
            % Options
            %   defaultFilePath: (text, 1 x 1)
            %
            % <Output>
            %   fileName: (string, 1 x 1) or []
            %   folder: (string, 1 x 1) or []

            arguments
                obj {}
                fileType {}
                options.validExts {} = ''
                options.defaultFilePath {} = ''
            end

            % Ask user to specify a file to output.
            [fileName,folder] = askUserToSpecifyFile(obj, ...
                true, ... % Whether to output
                fileType, ...
                validExts = options.validExts, ...
                defaultPath = options.defaultFilePath ...
            );

        end

        function folder = askUserToSpecifyFolder(obj,options)
            %
            % <Input>
            % Options
            %   defaultFilePath: (text, 1 x 1)
            %
            % <Output>
            %   folder: (string, 1 x 1) or []

            arguments
                obj {}
                options.purposeForTitle {Validator.mustBeTextScalar} = "to open"
                options.defaultFolderPath {Validator.mustBeTextScalar} = ''
            end

            purposeForTitle = options.purposeForTitle;
            defaultFolderPath = options.defaultFolderPath;

            % If the user didn't specify a default path, use the last
            % selected folder.
            if isempty(defaultFolderPath) && ~isempty(obj.pLastSelectedFolder)
                defaultFolderPath = obj.pLastSelectedFolder;
            end

            % Build a title for a dialog to specify a folder. (string, 1 x 1)
            title = sprintf("Specify a folder %s.",purposeForTitle);

            % Ask user to specify a folder. (char, 1 x N)
            folder = uigetdir(defaultFolderPath,title);

            % NOTE:
            % If user canceled, it returns 0 for the folder.

            % If user canceled, stop asking again.
            if isequal(folder,0)
                folder = [];
                return;
            end

            % Convert the folder path to string and return it.
            % (string, 1 x 1)
            folder = string(folder);

        end

        % Error handling.

        function runWithErrorHandling(obj,functionHandle)

            % Validate the input.
            Validator.mustBeFunctionHandleScalar(functionHandle);
        
            try
            
                % Run the method.
                functionHandle();
            
            catch ME

                % Handle common processing when an exception occurs.
                obj.handleException(ME);

            end
        end

        function markAsFatalExceptionAndThrow(obj,ME)

            % Create a fatal error with a specific ID for app termination.
            fatalME = MException( ...
                obj.pExceptionIdentifiersFatal, ...
                sprintf( ...
                    "A fatal error occurred, and the application will be closed.\n\n" + ...
                    "%s", ...
                    ME.message ...
                ) ...
            );

            % Add the caught exception as a cause, then throw the new fatal
            % exception
            fatalME = addCause(fatalME,ME);
            throw(fatalME);

        end

        function handleException(obj,ME)

            % Delete the progress dialog.
            obj.deleteProgressDialog();

            % Show an alert message.
            obj.showAlertDialog( ...
                ME.message, ...
                pauseUntilAcknowledged = true ...
            );

            % Close the app if it's a fatal error.
            if ME.identifier == obj.pExceptionIdentifiersFatal
                delete(obj.UIFigure);
            end

            % Throw the exception.
            rethrow(ME);

        end

    end

    methods (Access = private)

        function [fileNames,folder] = askUserToSpecifyFile(obj, ...
                toOutput, ...
                fileType, ...
                options ...
            )
            %
            % <Output>
            %   fileNames: (string, numFiles x 1) or []
            %   folder: (string, 1 x 1) or []

            arguments
                obj {}
                toOutput {Validator.mustBeLogicalScalar}
                fileType {Validator.mustBeTextScalar}
                options.validExts {Validator.mustBeText} = ''
                options.defaultPath {Validator.mustBeTextScalar} = ''
                options.allowMultiSelect {Validator.mustBeLogicalScalar} = false
            end

            validExts        = options.validExts;
            defaultPath      = options.defaultPath;
            allowMultiSelect = options.allowMultiSelect;

            if toOutput && allowMultiSelect
                error( ...
                    "Specifying multiple file paths to output is not allowed." ...
                );
            end

            allowAnyExts = Validator.isTextZeroLength(validExts);

            if allowAnyExts

                % Use the default filter.
                filter = '';

            else
    
                % Convert the valid file extensions to a column string.
                % (string, M x 1)
                validExts = convertToColumnString(validExts);
    
                % Build a text for filter. (string, M x 1)
                filter = arrayfun(@(x)sprintf("*%s",x),validExts);
                filter = strjoin(filter,";");
    
                % NOTE:
                % For example, "*.m" for a file extension ".m".
                % If there are multiple extensions, "*.jpg;*.png;*.tif"

            end

            % Build a title. (string, 1 x 1)
            title = obj.buildTitleToSpecifyFiles( ...
                toOutput, ...
                fileType, ...
                validExts, ...
                allowMultiSelect ...
            );

            % If the user didn't specify a default path, use the last
            % selected folder.
            if isempty(defaultPath) && ~isempty(obj.pLastSelectedFolder)
                defaultPath = obj.pLastSelectedFolder;
            end

            if allowMultiSelect
                strMode = "on";
            else
                strMode = "off";
            end

            while true

                if toOutput

                    % Ask user to specify a file to output.
                    [fileNames,folder] = uiputfile( ...
                        filter, ...
                        title, ...
                        defaultPath ...
                    );

                else

                    % Ask user to specify file(s) to input.
                    [fileNames,folder] = uigetfile( ...
                        filter, ...
                        title, ...
                        defaultPath, ...
                        "MultiSelect",strMode ...
                    );

                end
    
                % NOTE:
                % fileNames: (char, 1 x N) or (cell, 1 x numFiles) < (char, 1 x N)
                %   Specified file names with their file extensions.
                % folder: (char, 1 x N)
                %   Folder path of the specified files.
    
                % NOTE:
                % If user canceled, it returns 0 for both the output arguments.
    
                % If user canceled, stop asking again.
                if isequal(fileNames,0)
                    fileNames = [];
                    folder = [];
                    return;
                end
    
                % Convert the file names and folder to string.
                fileNames = convertToColumnString(fileNames);
                folder    = string(folder);
    
                % NOTE:
                % fileNames: (string, numFiles x 1)
                % folder: (string, 1 x 1)

                if allowAnyExts
                    return;
                end
    
                % Check if the file names have valid file extensions.
                % (logical, numFiles x 1)
                hasValidExt = Validator.hasValidFileExtension( ...
                    fileNames, ...
                    validExts ...
                );
    
                % Return if all the file names have valid file extensions.
                if all(hasValidExt)
                    return;
                end
    
                % Show an alert dialog stating that the file extension in
                % not valid.
                obj.showAlertDialogInvalidFile( ...
                    validExts, ...
                    pauseUntilAcknowledged = true ...
                );
                
                if toOutput

                    % Get the file name without the extension.
                    [~,fileNameWithoutExt,~] = fileparts(fileNames);

                    % Use the file name with a valid extension.
                    defaultPath = fullfile( ...
                        folder, ...
                        strcat(fileNameWithoutExt,validExts(1)) ...
                    );

                else

                    % Use the selected folder for the next trial.
                    defaultPath = folder;

                end                

            end

        end

        function title = buildTitleToSpecifyFiles(obj, ...
                toOutput, ...
                fileType, ...
                validExts, ...
                allowMultiSelect ...
            )

            if allowMultiSelect
                strA = "";
                strS = "s";
            else
                strA = "a ";
                strS = "";
            end

            if toOutput
                strPurpose = "output";
            else
                strPurpose = "input";
            end

            if Validator.isTextZeroLength(validExts)
                extensionStr = "";
            else
                extensionStr = sprintf(" (%s)",strJoinComma(validExts));
            end

            % Build a title for a dialog to specify files. (string, 1 x 1)
            title = sprintf( ...
                "Specify %s%s file%s to %s.%s", ...
                strA, ...
                fileType, ...
                strS, ...
                strPurpose, ...
                extensionStr ...
            );

        end

    end
    
end