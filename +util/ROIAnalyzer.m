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

classdef ROIAnalyzer
    % ROIAnalyzer - Tools for ROI analysis
    %   Provides methods for ROI selection, analysis and processing
    
    methods (Static)
        function results = analyzeROI(mask, varargin)
            % analyzeROI Analyzes parameters within ROI for multiple maps
            %   mask: ROI mask image (logical)
            %   varargin: Variable number of maps and their names
            %             Format: 'mapName1', map1, 'mapName2', map2, ...
            %   
            %   Example: 
            %     results = analyzeROI(mask, 'vascular', counterMap, 'velocity', velocityMap, 'density', densityMap);
            %
            %   Returns a structure with basic statistical measures for each map:
            %   For each map with name 'mapName':
            %   - mapName_sum: Sum of all values in ROI
            %   - mapName_total_pixels: Total number of pixels in ROI
            %   - mapName_effective_pixels: Number of effective (non-zero) pixels in ROI
            %   - mapName_mean: Mean of effective values
            %   - mapName_values: Array of all values in ROI
            %   - mapName_effective_values: Array of all non-zero values in ROI
            
            % Initialize results structure
            results = struct();
            
            % Ensure mask is logical
            mask = logical(mask);
            
            % Get total pixels in ROI
            totalPixels = sum(mask(:));
            results.totalPixels = totalPixels;
            
            % Process input maps
            for i = 1:2:length(varargin)
                if i+1 <= length(varargin)
                    mapName = varargin{i};
                    mapData = varargin{i+1};
                    
                    % Extract values within mask
                    mapValues = mapData(mask);
                    mapEffectiveValues = mapValues(mapValues ~= 0);
                    
                    % Calculate basic statistics
                    fieldPrefix = [mapName, '__'];
                    results.([fieldPrefix, 'values']) = mapValues;
                    results.([fieldPrefix, 'effective_values']) = mapEffectiveValues;
                    results.([fieldPrefix, 'sum']) = sum(mapValues(:));
                    results.([fieldPrefix, 'total_pixels']) = totalPixels;
                    results.([fieldPrefix, 'effective_pixels']) = length(mapEffectiveValues);
                    
                    % Handle empty case for mean
                    if ~isempty(mapEffectiveValues)
                        results.([fieldPrefix, 'mean']) = mean(mapEffectiveValues);
                    else
                        results.([fieldPrefix, 'mean']) = 0;
                    end
                end
            end
        end
        
        function shifted_mask = shiftROI(mask, shift_amount, direction)
            % shiftROI Shifts ROI mask by specified number of pixels in given direction
            %   mask: Mask to be shifted
            %   shift_amount: Number of pixels to shift
            %   direction: Direction to shift ('up', 'down', 'left', 'right')
            %   shifted_mask: Resulting shifted mask
            
            % Initialize shift vectors
            shift_down = 0;
            shift_right = 0;
            
            % Set appropriate shift based on direction
            switch lower(direction)
                case 'up'
                    shift_down = -shift_amount;
                case 'down'
                    shift_down = shift_amount;
                case 'left'
                    shift_right = -shift_amount;
                case 'right'
                    shift_right = shift_amount;
                otherwise
                    warning('Invalid direction. Valid values are: up, down, left, right');
            end
            
            % Apply the shift
            shifted_mask = circshift(mask, [shift_down, shift_right]);
        end
    end
end 