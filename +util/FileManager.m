% Copyright (c) 2025 Pengfei Song Lab. All rights reserved.
% This code is provided for academic and research purposes only.
%
% Reference:
% Y. Wang, et al., "Longitudinal Awake Imaging of Mouse Deep Brain Microvasculature 
% with Super-resolution Ultrasound Localization Microscopy", eLife 13:RP95168, 
% doi: 10.7554/eLife.95168.2.
%
% For more information, please visit: https://elifesciences.org/reviewed-preprints/95168v2
%
% Author: Pengfei Song Lab
% Date: July 2025 

classdef FileManager
    % FileManager - Tools for ULM data file management
    %   Provides methods for loading, parsing and saving ULM data
    
    methods (Static)
        function [ulmData, fileDetails] = loadULMData(filePath, fileName)
            % loadULMData Loads ULM data file
            %   filePath: File path
            %   fileName: File name (optional)
            %   
            %   Returns:
            %   - ulmData: Loaded ULM data
            %   - fileDetails: File details structure
            
            % Initialize return values
            ulmData = [];
            fileDetails = struct('filePath', '', 'fileName', '', 'MouseID', '', 'DataName', '');
            
            % If filename not provided, show dialog to select
            if nargin < 2 || isempty(fileName)
                try
                    [fileName, filePath] = uigetfile('*.mat', 'Select a MAT file', filePath);
                    if isequal(fileName, 0)
                        return; % User canceled selection
                    end
                catch
                    disp('Error when loading the file');
                    return;
                end
            end
            
            % Ensure file path ends with separator
            if ~isempty(filePath) && filePath(end) ~= filesep
                filePath = [filePath, filesep];
            end
            
            % Load data
            try
                ulmData = load(fullfile(filePath, fileName));
                fileDetails.filePath = filePath;
                fileDetails.fileName = fileName;
                
                % Initialize MouseID and DataName as empty, waiting for user input
                fileDetails.MouseID = '';
                fileDetails.DataName = '';
            catch
                disp('Error loading or parsing the file');
                ulmData = [];
            end
        end
        
        
        
        function fullPath = saveROISelection(ROISelection, savePath, overwritePrompt)
            % saveROISelection Saves ROI selection results
            %   ROISelection: ROI selection object
            %   savePath: Save path (optional)
            %   overwritePrompt: Whether to prompt before overwriting (default true)
            %   
            %   Returns full path of saved file
            
            if nargin < 3
                overwritePrompt = true;
            end
            
            % If save path not provided, use path from ROISelection
            if nargin < 2 || isempty(savePath)
                if isprop(ROISelection, 'dirName') && ~isempty(ROISelection.dirName)
                    basePath = ROISelection.dirName;
                else
                    basePath = pwd;
                end
                
                % Create ROISelection subfolder
                savePath = fullfile(basePath, 'ROISelection', filesep);
            end
            
            % Ensure save directory exists
            if ~exist(savePath, 'dir')
                mkdir(savePath);
            end
            

            % Build filename
            if isprop(ROISelection, 'MouseID') && isprop(ROISelection, 'DataName') && ...
               isprop(ROISelection, 'ROIName')
                fileName = ['ROISel_', ROISelection.MouseID, '_', ...
                            ROISelection.DataName, '_', ...
                            ROISelection.ROIName, '.mat'];
            else
                % Use default filename
                fileName = ['ROISel_', datestr(now, 'yyyymmdd_HHMMSS'), '.mat'];
            end
            
            % Full save path
            fullPath = fullfile(savePath, fileName);
            
            % Check if file exists and handle overwrite case
            if exist(fullPath, 'file') && overwritePrompt
                choice = questdlg('The file already exists. Do you want to overwrite it?', ...
                    'File Exists', 'Yes', 'No', 'No');
                
                if strcmp(choice, 'Yes')
                    save(fullPath, 'ROISelection');
                else
                    disp('File not saved. Operation canceled.');
                    fullPath = '';
                end
            else
                save(fullPath, 'ROISelection');
            end
        end
    end
end 