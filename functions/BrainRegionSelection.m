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

function [region_indices, region_condition] = BrainRegionSelection(atlas,slice_idx)
    data = atlas.('Regions');
    % Define cData as a variable accessible within the function scope
    cData = [];
    % Store the original image data for highlighting
    originalData = [];
    % Track current highlighted region
    currentRegionIdx = 0;
    % Variable to store selected region indices (multiple selections)
    selectedRegionIndices = [];
    % Variable to store region condition (both, left, right)
    region_condition = '';
    % Variable to track if Ctrl key is pressed
    isCtrlPressed = false;
    % Variable to store highlighted regions mask
    selectedRegionsMask = [];

    fig = figure('Name', 'Coronal Plane Viewer', 'NumberTitle', 'off', ...
                 'Position', [300, 300, 800, 600], 'CloseRequestFcn', @close_gui_callback);

    ax = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.1, 0.15, 0.8, 0.75]);
    
    % Add text display area for brain region information - increase font size
    region_text = uicontrol('Style', 'text', 'String', '', ...
                           'Units', 'normalized', 'Position', [0.1, 0.05, 0.8, 0.05], ...
                           'HorizontalAlignment', 'left', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Add debug text area - decrease font size
    debug_text = uicontrol('Style', 'text', 'String', 'Debug Info', ...
                          'Units', 'normalized', 'Position', [0.1, 0.01, 0.8, 0.04], ...
                          'HorizontalAlignment', 'left', 'FontSize', 8);
    
    % Add selected regions text area
    selected_regions_text = uicontrol('Style', 'text', 'String', 'Hold Ctrl to select multiple regions', ...
                                     'Units', 'normalized', 'Position', [0.1, 0.92, 0.8, 0.05], ...
                                     'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    
    % Add confirm button for selections - always visible
    confirm_button = uicontrol('Style', 'pushbutton', 'String', 'Confirm Selections', ...
                              'Units', 'normalized', 'Position', [0.75, 0.92, 0.2, 0.05], ...
                              'Callback', @confirm_selections_callback);
    
    % Add multi-select mode indicator
    multiselect_indicator = uicontrol('Style', 'text', 'String', 'MULTI-SELECT: OFF', ...
                                     'Units', 'normalized', 'Position', [0.1, 0.92, 0.2, 0.05], ...
                                     'HorizontalAlignment', 'left', 'FontSize', 10, 'FontWeight', 'bold', ...
                                     'ForegroundColor', [0.8, 0, 0]); % Red color for OFF
    
    plotImg();
    
    % Add mouse movement event listener
    set(fig, 'WindowButtonMotionFcn', @mouse_move_callback);
    
    % Add mouse click event listener (changed from double-click to single click)
    set(fig, 'WindowButtonDownFcn', @mouse_click_callback);
    
    % Add key press and release event listeners - use correct callback names
    set(fig, 'KeyPressFcn', @key_press_callback);
    set(fig, 'KeyReleaseFcn', @key_release_callback);
    
    % Set figure to detect key events
    set(fig, 'KeyPressFcn', @key_press_callback);
    set(fig, 'KeyReleaseFcn', @key_release_callback);
    
    % Enable key capture for the figure
    set(fig, 'WindowStyle', 'normal');
    set(fig, 'HandleVisibility', 'callback');

    uiwait(fig);
    
    % Default return values if GUI is closed without selection
    if isempty(selectedRegionIndices)
        region_indices = [];
    else
        region_indices = selectedRegionIndices;
    end
    
    function close_gui_callback(~, ~)
        region_indices = [];
        region_condition = '';
        uiresume(fig);
        delete(fig);
    end
    
    function key_press_callback(~, event)
        % Check if Ctrl key is pressed (check both 'control' and 'command' for Mac compatibility)
        if strcmp(event.Key, 'control') || strcmp(event.Key, 'command')
            isCtrlPressed = true;
            % Update multi-select indicator
            set(multiselect_indicator, 'String', 'MULTI-SELECT: ON');
            set(multiselect_indicator, 'ForegroundColor', [0, 0.7, 0]); % Green color for ON
            % Update status text
            updateSelectedRegionsText();
            
            % Debug message for Ctrl press
            set(debug_text, 'String', 'Ctrl KEY PRESSED - Multi-select mode ON');
        end
    end
    
    function key_release_callback(~, event)
        % Check if Ctrl key is released (check both 'control' and 'command' for Mac compatibility)
        if strcmp(event.Key, 'control') || strcmp(event.Key, 'command')
            isCtrlPressed = false;
            % Update multi-select indicator
            set(multiselect_indicator, 'String', 'MULTI-SELECT: OFF');
            set(multiselect_indicator, 'ForegroundColor', [0.8, 0, 0]); % Red color for OFF
            
            % If no regions were selected, reset
            if isempty(selectedRegionIndices)
                updateSelectedRegionsText();
            end
            
            % Debug message for Ctrl release
            set(debug_text, 'String', 'Ctrl KEY RELEASED - Multi-select mode OFF');
        end
    end
    
    function confirm_selections_callback(~, ~)
        if ~isempty(selectedRegionIndices)
            % Ask for region condition (both, left, right)
            condition_msg = 'Select hemisphere condition for all selected regions:';
            condition_choice = questdlg(condition_msg, 'Select Hemisphere', ...
                                       'Both Hemispheres', 'Left Only', 'Right Only', 'Both Hemispheres');
            
            % Process condition choice
            switch condition_choice
                case 'Both Hemispheres'
                    region_condition = 'both';
                case 'Left Only'
                    region_condition = 'left';
                case 'Right Only'
                    region_condition = 'right';
                otherwise
                    % Dialog was closed or cancelled
                    return;
            end
            
            % Return the selected region indices by ending the function
            uiresume(fig);
            delete(fig);
        else
            msgbox('No regions selected. Please select at least one region.', 'No Selection', 'warn');
        end
    end
    
    function updateSelectedRegionsText()
        if isempty(selectedRegionIndices)
            if isCtrlPressed
                set(selected_regions_text, 'String', 'Hold Ctrl and click to select multiple regions');
            else
                set(selected_regions_text, 'String', 'Click to select a region (Hold Ctrl for multiple)');
            end
        else
            % Create a string with all selected region names
            region_names = '';
            for i = 1:length(selectedRegionIndices)
                idx = selectedRegionIndices(i);
                if idx > 0 && idx <= size(atlas.infoRegions.name, 2)
                    if i > 1
                        region_names = [region_names, ', '];
                    end
                    region_names = [region_names, atlas.infoRegions.acr{idx}];
                end
            end
            set(selected_regions_text, 'String', ['Selected: ', region_names]);
        end
    end
    
    function mouse_click_callback(src, ~)
        % Check for Ctrl key state using Java Robot
        try
            import java.awt.Robot;
            import java.awt.event.KeyEvent;
            robot = Robot;
            ctrlPressed = robot.isKeyPressed(KeyEvent.VK_CONTROL) || robot.isKeyPressed(KeyEvent.VK_META);
            
            % Update isCtrlPressed based on direct keyboard check
            isCtrlPressed = ctrlPressed;
            
            % Update multi-select indicator based on current state
            if isCtrlPressed
                set(multiselect_indicator, 'String', 'MULTI-SELECT: ON');
                set(multiselect_indicator, 'ForegroundColor', [0, 0.7, 0]); % Green color for ON
            else
                set(multiselect_indicator, 'String', 'MULTI-SELECT: OFF');
                set(multiselect_indicator, 'ForegroundColor', [0.8, 0, 0]); % Red color for OFF
            end
        catch
            % If Java Robot fails, fall back to using figure's CurrentModifier property
            modifiers = get(fig, 'CurrentModifier');
            isCtrlPressed = ismember('control', modifiers) || ismember('command', modifiers);
            
            % Update multi-select indicator based on current state
            if isCtrlPressed
                set(multiselect_indicator, 'String', 'MULTI-SELECT: ON');
                set(multiselect_indicator, 'ForegroundColor', [0, 0.7, 0]); % Green color for ON
            else
                set(multiselect_indicator, 'String', 'MULTI-SELECT: OFF');
                set(multiselect_indicator, 'ForegroundColor', [0.8, 0, 0]); % Red color for OFF
            end
        end
        
        % Only process left clicks (normal clicks)
        if strcmp(get(src, 'SelectionType'), 'normal') || strcmp(get(src, 'SelectionType'), 'alt')
            % Get current mouse position
            cp = get(ax, 'CurrentPoint');
            x = round(cp(1, 1));
            y = round(cp(1, 2));
            
            % Get image dimensions from the data directly
            img_data = squeeze(data(:, slice_idx, :));
            [img_height, img_width] = size(img_data);
            
            % Check if mouse is within image boundaries
            if x >= 1 && x <= img_width && y >= 1 && y <= img_height
                % Get brain region index at current position
                region_idx = data(y, slice_idx, x);
                
                % If it's a valid region
                if region_idx > 0 && region_idx <= size(atlas.infoRegions.name, 2)
                    try
                        region_name = atlas.infoRegions.name{region_idx};
                        region_acr = atlas.infoRegions.acr{region_idx};
                        
                        % Update debug info with current selection state
                        debug_info = sprintf('Click at x=%d, y=%d | Region: %s | Ctrl: %s', ...
                                           x, y, region_acr, mat2str(isCtrlPressed));
                        set(debug_text, 'String', debug_info);
                        
                        if isCtrlPressed
                            % Multi-selection mode
                            % Check if region is already selected
                            if ~isempty(selectedRegionIndices) && any(selectedRegionIndices == region_idx)
                                % Remove from selection
                                selectedRegionIndices = selectedRegionIndices(selectedRegionIndices ~= region_idx);
                                set(region_text, 'String', ['Removed: ', region_name, ' (', region_acr, ')']);
                            else
                                % Add to selection
                                if isempty(selectedRegionIndices)
                                    selectedRegionIndices = region_idx;
                                else
                                    selectedRegionIndices = [selectedRegionIndices, region_idx];
                                end
                                set(region_text, 'String', ['Added: ', region_name, ' (', region_acr, ')']);
                            end
                        else
                            % Single selection mode - replace any existing selection
                            selectedRegionIndices = region_idx;
                            set(region_text, 'String', ['Selected: ', region_name, ' (', region_acr, ')']);
                        end
                        
                        % Update selected regions text
                        updateSelectedRegionsText();
                        
                        % Update the highlighted regions display
                        updateSelectedRegionsDisplay();
                    catch err
                        msgbox(['Error accessing region data: ', err.message], 'Error', 'error');
                    end
                end
            end
        end
    end
    
    function updateSelectedRegionsDisplay()
        if isempty(originalData)
            return;
        end
        
        % First display the original image
        imagesc(ax, originalData);
        axis image;
        axis off;
        hold on;
        
        % Create a mask for all selected regions
        img_data = squeeze(data(:, slice_idx, :));
        
        % Process each selected region
        for i = 1:length(selectedRegionIndices)
            region_idx = selectedRegionIndices(i);
            mask = (img_data == region_idx);
            
            % Find boundaries of the region
            [B, ~] = bwboundaries(mask, 'noholes');
            
            % Plot boundaries with thick red line
            for k = 1:length(B)
                boundary = B{k};
                plot(ax, boundary(:,2), boundary(:,1), 'k', 'LineWidth', 3);
            end
        end
        
        hold off;
    end
    
    function mouse_move_callback(~, ~)
        % Check for Ctrl key state using the same approach as in mouse_click_callback
        try
            import java.awt.Robot;
            import java.awt.event.KeyEvent;
            robot = Robot;
            ctrlPressed = robot.isKeyPressed(KeyEvent.VK_CONTROL) || robot.isKeyPressed(KeyEvent.VK_META);
            
            % Update isCtrlPressed based on direct keyboard check
            isCtrlPressed = ctrlPressed;
            
            % Update multi-select indicator based on current state
            if isCtrlPressed
                set(multiselect_indicator, 'String', 'MULTI-SELECT: ON');
                set(multiselect_indicator, 'ForegroundColor', [0, 0.7, 0]); % Green color for ON
            else
                set(multiselect_indicator, 'String', 'MULTI-SELECT: OFF');
                set(multiselect_indicator, 'ForegroundColor', [0.8, 0, 0]); % Red color for OFF
            end
        catch
            % If Java Robot fails, fall back to using figure's CurrentModifier property
            modifiers = get(fig, 'CurrentModifier');
            isCtrlPressed = ismember('control', modifiers) || ismember('command', modifiers);
            
            % Update multi-select indicator based on current state
            if isCtrlPressed
                set(multiselect_indicator, 'String', 'MULTI-SELECT: ON');
                set(multiselect_indicator, 'ForegroundColor', [0, 0.7, 0]); % Green color for ON
            else
                set(multiselect_indicator, 'String', 'MULTI-SELECT: OFF');
                set(multiselect_indicator, 'ForegroundColor', [0.8, 0, 0]); % Red color for OFF
            end
        end
        
        % Get current mouse position
        cp = get(ax, 'CurrentPoint');
        x = round(cp(1, 1));
        y = round(cp(1, 2));
        
        % Get image dimensions from the data directly
        img_data = squeeze(data(:, slice_idx, :));
        [img_height, img_width] = size(img_data);
        
        % Debug info - always show mouse coordinates and Ctrl state
        debug_info = sprintf('Mouse: x=%d, y=%d | Image: %dx%d | Ctrl: %s', ...
                           x, y, img_width, img_height, mat2str(isCtrlPressed));
        
        % Check if mouse is within image boundaries
        if x >= 1 && x <= img_width && y >= 1 && y <= img_height
            % Get brain region index at current position
            region_idx = data(y, slice_idx, x);
            
            % Add region index to debug info
            debug_info = sprintf('%s | Region Index: %d', debug_info, region_idx);
            
            % If index is 0 (background) or out of range, clear display
            if region_idx == 0 || region_idx > size(atlas.infoRegions.name, 2)
                set(region_text, 'String', 'No region detected');
                debug_info = sprintf('%s | Condition: No valid region (idx=0 or out of range)', debug_info);
                
                % If we moved from a region to no region, restore original image if no selections
                if currentRegionIdx > 0 && isempty(selectedRegionIndices)
                    currentRegionIdx = 0;
                    restoreOriginalImage();
                end
            else
                % Get region name and abbreviation
                try
                    region_name = atlas.infoRegions.name{region_idx};
                    region_acr = atlas.infoRegions.acr{region_idx};
                    
                    % Update display text
                    if ~isempty(selectedRegionIndices) && any(selectedRegionIndices == region_idx)
                        region_info = sprintf('Brain Region: %s (%s) [SELECTED]', region_name, region_acr);
                    else
                        region_info = sprintf('Brain Region: %s (%s)', region_name, region_acr);
                    end
                    set(region_text, 'String', region_info);
                    
                    debug_info = sprintf('%s | Found region: %s', debug_info, region_acr);
                    
                    % Highlight the current region if it's different from the previously highlighted one
                    % and we don't have any selections yet, and we're not in multi-select mode
                    if region_idx ~= currentRegionIdx && isempty(selectedRegionIndices) && ~isCtrlPressed
                        highlightRegion(region_idx);
                        currentRegionIdx = region_idx;
                    end
                catch err
                    % If there's an error accessing the region info
                    set(region_text, 'String', 'Error accessing region data');
                    debug_info = sprintf('%s | ERROR: %s', debug_info, err.message);
                    
                    % Restore original image if there was an error and no selections
                    if currentRegionIdx > 0 && isempty(selectedRegionIndices)
                        currentRegionIdx = 0;
                        restoreOriginalImage();
                    end
                end
            end
        else
            % Mouse is outside the image, clear display
            set(region_text, 'String', 'Outside image boundaries');
            debug_info = sprintf('%s | Condition: Outside image boundaries', debug_info);
            
            % Restore original image if mouse moves outside and no selections
            if currentRegionIdx > 0 && isempty(selectedRegionIndices)
                currentRegionIdx = 0;
                restoreOriginalImage();
            end
        end
        
        % Update debug text
        set(debug_text, 'String', debug_info);
    end

    function highlightRegion(region_idx)
        % Store original data if not already stored
        if isempty(originalData)
            originalData = cData;
        end
        
        % First display the original image
        imagesc(ax, originalData);
        axis image;
        axis off;
        hold on;
        
        % Create a mask for the current region
        img_data = squeeze(data(:, slice_idx, :));
        mask = (img_data == region_idx);
        
        % Find boundaries of the region
        [B, ~] = bwboundaries(mask, 'noholes');
        
        % Plot boundaries with thick red line
        for k = 1:length(B)
            boundary = B{k};
            plot(ax, boundary(:,2), boundary(:,1), 'k', 'LineWidth', 3);
        end
        
        hold off;
    end
    
    function restoreOriginalImage()
        % Restore the original image
        if ~isempty(originalData)
            imagesc(ax, originalData);
            axis image;
            axis off;
        end
    end

    function plotImg()
        colorComp.method = 'index';
        colorComp.cmap = atlas.infoRegions.rgb;
        colorComp.caxis = [0 128];
        cData = rgbfunc(squeeze(data(:, slice_idx, :)), colorComp);
        originalData = cData; % Store the original image data
        imagesc(ax, cData);
        axis image;
        axis off;
        title(ax, sprintf('Coronal Plane Viewer'));
    end
end

function b = rgbfunc(a, colorstr)
    [nx, ny] = size(a);
    aa = double(a(:));
    method = colorstr.method;
    cmap = colorstr.cmap;
    if strcmp(method, 'index')
        aa(aa == 0) = 1;
        b = cmap(abs(aa), :);
        b = reshape(b, nx, ny, 3);
    else
        error('mapscan unknown rgb method')
    end
end
