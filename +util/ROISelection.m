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

classdef ROISelection < dynamicprops
    % ROISelection - Class for ROI selection data storage and management
    %   Used to store and manage data and metadata related to ROI selection
    %   Implements dynamicprops to allow flexible addition of properties for various map statistics
    
    properties
        % Basic ROI data
        mask            % ROI mask
        ULMmap          % ULM counter map
        
        % File and metadata information
        fileName        % Source filename
        dirName         % Source directory
        MouseID         % Mouse ID
        DataName        % Data type
        ROIName         % ROI name
    end
    
    % Standard analysis results as properties for backward compatibility
    properties
        % Added to store which maps have been analyzed
        analyzedMaps    % Cell array of map names that have been analyzed
    end
    
    methods
        function obj = ROISelection()
            % ROISelection Constructor
            % Initialize analyzedMaps property to track which maps have been analyzed
            obj.analyzedMaps = {};
        end
        
        function addAnalysisResults(obj, results)
            % addAnalysisResults Adds analysis results to the ROI selection object
            %   results: Structure containing analysis results from ROIAnalyzer
            %
            % This method allows adding any fields from analysis results as dynamic properties
            
            % If results is empty, nothing to do
            if isempty(results)
                return;
            end
            
            % Get all field names from results
            fieldNames = fieldnames(results);
            
            % Add each field as a dynamic property
            for i = 1:length(fieldNames)
                fieldName = fieldNames{i};
                
                % Check if it's a map-specific field (contains an underscore)
                if contains(fieldName, '__')
                    % Extract map name (part before first underscore)
                    parts = strsplit(fieldName, '__');
                    mapName = parts{1};
                    
                    % Add to analyzedMaps if not already there
                    if ~ismember(mapName, obj.analyzedMaps)
                        obj.analyzedMaps{end+1} = mapName;
                    end
                end
                
                % Add or update the property
                if ~isprop(obj, fieldName)
                    % Create new dynamic property
                    prop = obj.addprop(fieldName);
                end
                
                % Set property value
                obj.(fieldName) = results.(fieldName);
            end
            
        end
        
        function analyze(obj, ULMdata)
            % analyze Analyzes blood flow parameters in ROI region
            %   ULMdata: ULM data structure containing mapCounter and mapVelocity_Kalman
            
            if isempty(obj.mask) || isempty(ULMdata)
                error('Valid ROI mask and ULM data required for analysis');
            end
            
            % Get counter map and mask
            counterMap = ULMdata.mapCounter;
            mask = logical(obj.mask);
            
            % Prepare velocity map if available
            if isfield(ULMdata, 'mapVelocity_Kalman')
                velocityMap = ULMdata.mapVelocity_Kalman * 1e3;
                
                % Use ROIAnalyzer's flexible interface
                results = util.ROIAnalyzer.analyzeROI(mask, 'vascular', counterMap, 'velocity', velocityMap);
            else
                % Only analyze counter map if velocity map not available
                results = util.ROIAnalyzer.analyzeROI(mask, 'vascular', counterMap);
            end
            
            % Add all results as properties
            obj.addAnalysisResults(results);
        end
        
        function results = getResults(obj, mapNames)
            % getResults Returns analysis results
            %   mapNames: Optional cell array of map names to include in results
            %             If not provided, includes all analyzed maps
            %   Returns a structure containing all analysis results
            
            % Initialize results structure
            results = struct();

            % If no map names specified, use all analyzed maps
            if nargin < 2 || isempty(mapNames)
                mapNames = obj.analyzedMaps;
            end
            
            % For each map, add all its statistics
            for i = 1:length(mapNames)
                mapName = mapNames{i};
                
                % Get all properties of this object
                propList = properties(obj);
                
                % Add properties that start with mapName_
                prefix = [mapName, '_'];
                for j = 1:length(propList)
                    propName = propList{j};
                    if startsWith(propName, prefix)
                        results.(propName) = obj.(propName);
                    end
                end
            end
        end
        
        function savePath = save(obj, savePath, overwritePrompt)
            % save Saves ROI selection object
            %   savePath: Save path (optional)
            %   overwritePrompt: Whether to prompt before overwriting (default true)
            %   
            %   Returns full path of saved file
            
            if nargin < 3
                overwritePrompt = true;
            end
            
            % Use FileManager to save ROI selection
            ROISelection = obj; % Create copy for saving
            savePath = ulmutil.FileManager.saveROISelection(ROISelection, savePath, overwritePrompt);
        end
    end
end 