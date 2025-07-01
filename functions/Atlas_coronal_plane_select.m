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

function slice_idx = Atlas_coronal_plane_select(atlas)

    current_atlas = 'Regions';
    data = atlas.(current_atlas);

    fig = figure('Name', 'Coronal Plane Viewer', 'NumberTitle', 'off', ...
                 'Position', [300, 300, 800, 600], 'CloseRequestFcn', @close_gui_callback);
    slice_idx = 1; 
    selected_slice_idx = 1;
    minSlice = 1;
    maxSlice = size(data, 2); 

    atlas_menu = uicontrol('Style', 'popupmenu', 'String', {'Regions', 'Histology', 'Vascular'}, ...
                           'Units', 'normalized', 'Position', [0.1, 0.92, 0.2, 0.05], ...
                           'Callback', @atlas_menu_callback);

    slider = uicontrol('Style', 'slider', 'Min', minSlice, 'Max', maxSlice, 'Value', slice_idx, ...
                       'Units', 'normalized', 'Position', [0.1, 0.05, 0.8, 0.05], ...
                       'SliderStep', [1/(maxSlice-minSlice), 5/(maxSlice-minSlice)], ...
                       'Callback', @slider_callback);
  
    sliceNumEdit = uicontrol('Style', 'edit', 'Units', 'normalized', ...
                             'Position', [0.45, 0.01, 0.1, 0.03], ...
                             'String', sprintf('%d', slice_idx), ...
                             'Callback', @edit_callback);
    
    ax = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.1, 0.15, 0.8, 0.75]);
    
    plotImg();
    confirm_button = uicontrol('Style', 'pushbutton', 'String', 'Confirm Selection', ...
                               'Units', 'normalized', 'Position', [0.75, 0.92, 0.15, 0.05], ...
                               'Callback', @confirm_button_callback);

    uiwait(fig);
    
    function slider_callback(src, ~)
        selected_slice_idx = round(get(src, 'Value'));
        set(sliceNumEdit, 'String', sprintf('%d', selected_slice_idx));
        plotImg();
    end

    function edit_callback(src, ~)
        val = str2double(get(src, 'String'));
        if isnan(val) || val < minSlice || val > maxSlice
            set(src, 'String', sprintf('%d', selected_slice_idx));
        else
            selected_slice_idx = round(val);
            set(slider, 'Value', selected_slice_idx);
            plotImg();
        end
    end
  
    function atlas_menu_callback(src, ~)
        selected_atlas = get(src, 'Value');
        atlas_types = {'Regions', 'Histology', 'Vascular'};
        current_atlas = atlas_types{selected_atlas};
        data = atlas.(current_atlas);
        maxSlice = size(data, 2);
        set(slider, 'Max', maxSlice, 'SliderStep', [1/(maxSlice-1), 5/(maxSlice-1)]);
        plotImg();
    end

    function colorComp = set_colorComp()
        switch current_atlas
            case 'Histology'
                colorComp.method = 'fix';
                colorComp.cmap = gray(256);
                colorComp.caxis = [0 256];
            case 'Vascular'
                colorComp.method = 'auto';
                colorComp.cmap = gray(128);
                colorComp.caxis = [0 128];
            case 'Regions'
                colorComp.method = 'index';
                colorComp.cmap = atlas.infoRegions.rgb;
                colorComp.caxis = [0 128];
        end
    end

    function confirm_button_callback(~, ~)
        choice = questdlg(sprintf('Are you sure you want to select slice %d?', selected_slice_idx), ...
                          'Confirm Selection', 'Yes', 'No', 'No');
        
        switch choice
            case 'Yes'
                slice_idx = selected_slice_idx;
                uiresume(fig);
                delete(fig);
            case 'No'
        end
    end

    function close_gui_callback(~, ~)
        slice_idx = [];
        uiresume(fig);
        delete(fig);
    end

    function plotImg()
        colorComp = set_colorComp();
        cData = rgbfunc(squeeze(data(:, selected_slice_idx, :)), colorComp);
        imagesc(ax, cData);
        axis image;
        axis off;
        title(ax, sprintf('Coronal Plane Viewer - %s', current_atlas));
    end
end

function b = rgbfunc(a, colorstr)
    [nx, ny] = size(a);
    aa = double(a(:));
    method = colorstr.method;
    cmap = colorstr.cmap;
    caxis_values = colorstr.caxis;
    if strcmp(method, 'auto')
        norm_val = max(aa) - min(aa);
        aa = (aa - min(aa)) / norm_val;
        aa = uint16(round(aa(:) * (length(cmap) - 1) + 1));
        aa(aa == 0) = 1;
        b = cmap(aa, :);
        b = reshape(b, nx, ny, 3);
    elseif strcmp(method, 'fix')
        aa = (aa - caxis_values(1)) / (caxis_values(2) - caxis_values(1));
        aa = uint16(round(aa(:) * (length(cmap) - 1) + 1));
        aa(aa < 1) = 1;
        aa(aa > length(cmap)) = length(cmap);
        b = cmap(aa, :);
        b = reshape(b, nx, ny, 3);
    elseif strcmp(method, 'index')
        aa(aa == 0) = 1;
        b = cmap(abs(aa), :);
        b = reshape(b, nx, ny, 3);
    else
        error('mapscan unknown rgb method')
    end
end
