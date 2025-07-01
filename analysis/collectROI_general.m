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

%%
clear;
SaveFolder = '.\exampleData\ROISelection\';
DataFolders_general = '.\exampleData\ROISelection\';

% Get a list of all .mat files in the folder
filePattern = fullfile(DataFolders_general, 'ROISel*.mat'); 
matFiles = dir(filePattern);

% Sample first file to determine all available fields
if ~isempty(matFiles)
    sampleData = load(fullfile(matFiles(1).folder, matFiles(1).name));
    sampleROI = sampleData.ROISelection;
    
    % Get basic metadata fields
    metadataFields = {'MouseID', 'ROIName', 'DataName'};
    
    % Get all analyzed maps
    analyzedMaps = {};
    if isprop(sampleROI, 'analyzedMaps') && ~isempty(sampleROI.analyzedMaps)
        analyzedMaps = sampleROI.analyzedMaps;
    else
        % Try to infer analyzed maps from properties
        props = properties(sampleROI);
        for i = 1:length(props)
            propName = props{i};
            if contains(propName, '__')
                parts = strsplit(propName, '__');
                mapName = parts{1};
                if ~ismember(mapName, analyzedMaps)
                    analyzedMaps{end+1} = mapName;
                end
            end
        end
    end
    
    % Define key statistics to collect for each map
    statTypes = {'sum', 'mean', 'effective_pixels', 'total_pixels'};
    
    % Build headers list
    headers = metadataFields;
    
    % Add headers for each map and statistic type
    for i = 1:length(analyzedMaps)
        for j = 1:length(statTypes)
            headers{end+1} = [analyzedMaps{i}, '__', statTypes{j}];
        end
    end

    % Create variable types array
    varTypes = cell(1, length(headers));
    for i = 1:length(metadataFields)
        varTypes{i} = 'string';
    end
    for i = length(metadataFields)+1:length(headers)
        varTypes{i} = 'double';
    end
    
    % Create empty table with correct headers and types
    roiTable = table('Size', [0, length(headers)], 'VariableTypes', varTypes, 'VariableNames', headers);
    
    % Process each file
    for k = 1:length(matFiles)
        fullFileName = fullfile(matFiles(k).folder, matFiles(k).name);
        fprintf('Now reading %s\n', fullFileName);
       
        data = load(fullFileName);
        roi = data.ROISelection;
        
        % Initialize row with NaN values
        rowData = cell(1, length(headers));
        for i = length(metadataFields)+1:length(headers)
            rowData{i} = NaN;
        end
        
        % Fill metadata
        for i = 1:length(metadataFields)
            field = metadataFields{i};
            if isprop(roi, field) && ~isempty(roi.(field))
                rowData{i} = string(roi.(field));
            else
                rowData{i} = "";
            end
        end
        
        % Fill statistics for each map
        for i = 1:length(analyzedMaps)
            mapName = analyzedMaps{i};
            for j = 1:length(statTypes)
                statType = statTypes{j};
                fieldName = [mapName, '__', statType];
                fieldIdx = find(strcmp(headers, fieldName));
                
                if isprop(roi, fieldName)
                    rowData{fieldIdx} = roi.(fieldName);
                end
            end
        end
        
        
        % Add row to table
        roiTable = [roiTable; rowData];
    end
    
    % Save the table to a file (CSV or MAT)
    outputFile = fullfile(SaveFolder, 'ROI_data.csv');
    writetable(roiTable, outputFile, 'WriteVariableNames', true);
    
    % Also save as MAT file for easy MATLAB use
    matOutputFile = fullfile(SaveFolder, 'ROI_data.mat');
    save(matOutputFile, 'roiTable');
    
    fprintf('Data has been saved to %s and %s\n', outputFile, matOutputFile);
else
    fprintf('No .mat files found in the specified folder.\n');
end
