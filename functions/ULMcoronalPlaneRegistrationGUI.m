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

function [shiftedcData, shiftedAtlasData, atlasTransform, confirmed] = ULMcoronalPlaneRegistrationGUI(cData, imgData, dx, dz, atlasData)
    % Initialize variables
    cData_transformed = cData;
    atlasData_transformed = atlasData;
    dB = @(x) 20.*log10(abs(x)./max(abs(x(:))));
    brain_pixel_axial_size = 50e-6;
    brain_pixel_lateral_size = 50e-6;
    dB_lower_limit = -50;
    opacity = 0.3;
    shiftedAtlasData = [];
    shiftedcData = [];
    confirmed = 0;

    % Initialize transform parameters
    atlasTransform = struct();
    atlasTransform.brain_pixel_axial_size = brain_pixel_axial_size;
    atlasTransform.brain_pixel_lateral_size = brain_pixel_lateral_size;
    atlasTransform.h_shift = 0;
    atlasTransform.v_shift = 0;
    atlasTransform.rot_angle = 0;

    % Create main figure window
    fig = figure('Name', 'Atlas Registration GUI', 'NumberTitle', 'off', 'Position', [300, 300, 600, 700]);
    ax = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.1, 0.35, 0.8, 0.6]);

    % Atlas axial pixel size control
    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.1, 0.28, 0.2, 0.025], 'String', 'Atlas Axial Size (um):');
    axial_slider = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.3, 0.28, 0.22, 0.025], 'Min', 10, 'Max', 100, ...
        'Value', brain_pixel_axial_size * 1e6, 'Callback', @(~,~)updateAxialSize());
    % Set appropriate slider steps (small step, big step)
    set(axial_slider, 'SliderStep', [0.01, 0.1]);
    axial_value = uicontrol('Style', 'edit', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.525, 0.28, 0.05, 0.025], 'String', num2str(brain_pixel_axial_size * 1e6), ...
        'Callback', @(~,~)updateAxialSizeFromInput());

    % Atlas lateral pixel size control
    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.1, 0.23, 0.2, 0.025], 'String', 'Atlas Lateral Size (um):');
    lateral_slider = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.3, 0.23, 0.22, 0.025], 'Min', 10, 'Max', 100, ...
        'Value', brain_pixel_lateral_size * 1e6, 'Callback', @(~,~)updateLateralSize());
    % Set appropriate slider steps (small step, big step)
    set(lateral_slider, 'SliderStep', [0.01, 0.1]);
    lateral_value = uicontrol('Style', 'edit', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.525, 0.23, 0.05, 0.025], 'String', num2str(brain_pixel_lateral_size * 1e6), ...
        'Callback', @(~,~)updateLateralSizeFromInput());

    % Rotation control
    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.1, 0.18, 0.2, 0.025], 'String', 'Rotation (degree):');
    rotate_slider = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.3, 0.18, 0.22, 0.025], 'Min', -90, 'Max', 90, ...
        'Value', 0, 'Callback', @(~,~)updateRotation());
    % Set appropriate slider steps (small step, big step)
    set(rotate_slider, 'SliderStep', [1/180, 5/180]);
    rotate_value = uicontrol('Style', 'edit', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.525, 0.18, 0.05, 0.025], 'String', '0', ...
        'Callback', @(~,~)updateRotationFromInput());

    % Shift controls
    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.1, 0.13, 0.2, 0.025], 'String', 'Horizontal Shift (pixels):');
    h_slider = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.3, 0.13, 0.22, 0.025], 'Min', -size(imgData, 2), 'Max', size(imgData, 2), ...
        'Value', 0, 'Callback', @(~,~)updateHorizontalShift());
    % Set appropriate slider steps (small step, big step)
    set(h_slider, 'SliderStep', [1/200, 10/200]);
    h_value = uicontrol('Style', 'edit', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.525, 0.13, 0.05, 0.025], 'String', '0', ...
        'Callback', @(~,~)updateHorizontalShiftFromInput());

    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.1, 0.08, 0.2, 0.025], 'String', 'Vertical Shift (pixels):');
    v_slider = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.3, 0.08, 0.22, 0.025], 'Min', -size(imgData, 1), 'Max', size(imgData, 1), ...
        'Value', 0, 'Callback', @(~,~)updateVerticalShift());
    % Set appropriate slider steps (small step, big step)
    set(v_slider, 'SliderStep', [1/200, 10/200]);
    v_value = uicontrol('Style', 'edit', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.525, 0.08, 0.05, 0.025], 'String', '0', ...
        'Callback', @(~,~)updateVerticalShiftFromInput());

    % Display controls
    dB_input = uicontrol('Style', 'edit', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.8, 0.28, 0.05, 0.025], 'String', num2str(dB_lower_limit));
    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.65, 0.28, 0.15, 0.025], 'String', 'dB Lower Limit');
    
    opacity_input = uicontrol('Style', 'edit', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.8, 0.24, 0.05, 0.025], 'String', num2str(opacity));
    uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.65, 0.24, 0.15, 0.025], 'String', 'Overlay Opacity');

    % Control buttons
    uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.7, 0.15, 0.1, 0.025], 'String', 'Reset', ...
        'Callback', @(~,~)reset());
    uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.65, 0.075, 0.2, 0.06], 'String', 'Confirm', ...
        'Callback', @(~,~)confirmAndClose());
    uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.65, 0.175, 0.1, 0.025], 'String', 'Load', ...
        'Callback', @(~,~)loadMatFile());
    uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.75, 0.175, 0.1, 0.025], 'String', 'Save', ...
        'Callback', @(~,~)saveMatFile());

    % Initialize variables for image display
    IQmean_rgb = [];
    cData_resized = [];
    atlasData_resized = [];
    img_handle = [];

    % Set up initial display
    updateImage();
    set(dB_input, 'Callback', @(~,~)updateImage());
    set(opacity_input, 'Callback', @(~,~)updateImage());
    
    % Wait for user interaction
    uiwait(fig);

    function updateAxialSize()
        % Get the new value first
        brain_pixel_axial_size = get(axial_slider, 'Value') * 1e-6;
        
        % Update the transform parameter
        atlasTransform.brain_pixel_axial_size = brain_pixel_axial_size;
        
        % Update the text display
        set(axial_value, 'String', num2str(brain_pixel_axial_size * 1e6));
        
        % Reset shift parameters
        atlasTransform.h_shift = 0;
        atlasTransform.v_shift = 0;
        
        % Reset shift UI controls - IMPORTANT: set slider value first, then text
        set(h_slider, 'Value', 0);
        set(h_value, 'String', '0');
        set(v_slider, 'Value', 0);
        set(v_value, 'String', '0');
        
        % Update the image
        updateImage();
        
        % Force a drawnow to ensure UI updates
        drawnow;
    end

    function updateAxialSizeFromInput()
        % Get the new value first
        val = str2double(get(axial_value, 'String')) * 1e-6;
        brain_pixel_axial_size = val;
        
        % Update the transform parameter
        atlasTransform.brain_pixel_axial_size = brain_pixel_axial_size;
        
        % Update the slider position
        set(axial_slider, 'Value', val * 1e6);
        
        % Reset shift parameters
        atlasTransform.h_shift = 0;
        atlasTransform.v_shift = 0;
        
        % Reset shift UI controls - IMPORTANT: set slider value first, then text
        set(h_slider, 'Value', 0);
        set(h_value, 'String', '0');
        set(v_slider, 'Value', 0);
        set(v_value, 'String', '0');
        
        % Update the image
        updateImage();
        
        % Force a drawnow to ensure UI updates
        drawnow;
    end

    function updateLateralSize()
        % Get the new value first
        brain_pixel_lateral_size = get(lateral_slider, 'Value') * 1e-6;
        
        % Update the transform parameter
        atlasTransform.brain_pixel_lateral_size = brain_pixel_lateral_size;
        
        % Update the text display
        set(lateral_value, 'String', num2str(brain_pixel_lateral_size * 1e6));
        
        % Reset shift parameters
        atlasTransform.h_shift = 0;
        atlasTransform.v_shift = 0;
        
        % Reset shift UI controls - IMPORTANT: set slider value first, then text
        set(h_slider, 'Value', 0);
        set(h_value, 'String', '0');
        set(v_slider, 'Value', 0);
        set(v_value, 'String', '0');
        
        % Update the image
        updateImage();
        
        % Force a drawnow to ensure UI updates
        drawnow;
    end

    function updateLateralSizeFromInput()
        % Get the new value first
        val = str2double(get(lateral_value, 'String')) * 1e-6;
        brain_pixel_lateral_size = val;
        
        % Update the transform parameter
        atlasTransform.brain_pixel_lateral_size = brain_pixel_lateral_size;
        
        % Update the slider position
        set(lateral_slider, 'Value', val * 1e6);
        
        % Reset shift parameters
        atlasTransform.h_shift = 0;
        atlasTransform.v_shift = 0;
        
        % Reset shift UI controls - IMPORTANT: set slider value first, then text
        set(h_slider, 'Value', 0);
        set(h_value, 'String', '0');
        set(v_slider, 'Value', 0);
        set(v_value, 'String', '0');
        
        % Update the image
        updateImage();
        
        % Force a drawnow to ensure UI updates
        drawnow;
    end

    function updateRotation()
        % Get the new value first
        angle = get(rotate_slider, 'Value');
        
        % Update the transform parameter
        atlasTransform.rot_angle = angle;
        
        % Update the text display
        set(rotate_value, 'String', num2str(angle));
        
        % Reset shift parameters
        atlasTransform.h_shift = 0;
        atlasTransform.v_shift = 0;
        
        % Reset shift UI controls - IMPORTANT: set slider value first, then text
        set(h_slider, 'Value', 0);
        set(h_value, 'String', '0');
        set(v_slider, 'Value', 0);
        set(v_value, 'String', '0');
        
        % Update the transforms
        cData_transformed = imrotate(cData, angle, 'nearest');
        atlasData_transformed = imrotate(atlasData, angle, 'nearest');
        
        % Update the image
        updateImage();
        
        % Force a drawnow to ensure UI updates
        drawnow;
    end

    function updateRotationFromInput()
        % Get the new value first
        angle = str2double(get(rotate_value, 'String'));
        
        % Update the transform parameter
        atlasTransform.rot_angle = angle;
        
        % Update the slider position
        set(rotate_slider, 'Value', angle);
        
        % Reset shift parameters
        atlasTransform.h_shift = 0;
        atlasTransform.v_shift = 0;
        
        % Reset shift UI controls - IMPORTANT: set slider value first, then text
        set(h_slider, 'Value', 0);
        set(h_value, 'String', '0');
        set(v_slider, 'Value', 0);
        set(v_value, 'String', '0');
        
        % Update the transforms
        cData_transformed = imrotate(cData, angle, 'nearest');
        atlasData_transformed = imrotate(atlasData, angle, 'nearest');
        
        % Update the image
            updateImage();
        
        % Force a drawnow to ensure UI updates
        drawnow;
    end

    function updateHorizontalShift()
        % Get the absolute shift value
        h_shift = round(get(h_slider, 'Value'));
        
        % Update the transform parameter
        atlasTransform.h_shift = h_shift;
        
        % Update the text display
        set(h_value, 'String', num2str(h_shift));
        
        % Update the image with new shift
        updateShiftedImage();
        
        % Force a drawnow to ensure UI updates
        drawnow;
    end

    function updateHorizontalShiftFromInput()
        % Get the absolute shift value
        h_shift = round(str2double(get(h_value, 'String')));
        h_shift = min(max(h_shift, get(h_slider, 'Min')), get(h_slider, 'Max'));
        
        % Update the transform parameter
        atlasTransform.h_shift = h_shift;
        
        % Update the slider position
        set(h_slider, 'Value', h_shift);
        
        % Update the image with new shift
        updateShiftedImage();
        
        % Force a drawnow to ensure UI updates
        drawnow;
    end

    function updateVerticalShift()
        % Get the absolute shift value
        v_shift = round(get(v_slider, 'Value'));
        
        % Update the transform parameter
        atlasTransform.v_shift = v_shift;
        
        % Update the text display
        set(v_value, 'String', num2str(v_shift));
        
        % Update the image with new shift
        updateShiftedImage();
        
        % Force a drawnow to ensure UI updates
        drawnow;
    end

    function updateVerticalShiftFromInput()
        % Get the absolute shift value
        v_shift = round(str2double(get(v_value, 'String')));
        v_shift = min(max(v_shift, get(v_slider, 'Min')), get(v_slider, 'Max'));
        
        % Update the transform parameter
        atlasTransform.v_shift = v_shift;
        
        % Update the slider position
        set(v_slider, 'Value', v_shift);
        
        % Update the image with new shift
        updateShiftedImage();
        
        % Force a drawnow to ensure UI updates
        drawnow;
    end

    function updateShiftedImage()
        % Start from the original resized data (before any shifts)
        [cData_base, atlasData_base] = getResizedData();
        
        % Apply horizontal and vertical shifts
        cData_resized = circshift(cData_base, [atlasTransform.v_shift, atlasTransform.h_shift, 0]);
        atlasData_resized = circshift(atlasData_base, [atlasTransform.v_shift, atlasTransform.h_shift]);
        
        % Update the display
        updateDisplay();
    end

    function [cData_base, atlasData_base] = getResizedData()
        % Calculate scaling factors
        scale_z = brain_pixel_axial_size / dz;
        scale_x = brain_pixel_lateral_size / dx;

        % Resize atlas data
        cData_resized_local = imresize(cData_transformed, [round(size(cData_transformed, 1) * scale_z), round(size(cData_transformed, 2) * scale_x)], 'nearest');
        atlasData_resized_local = imresize(atlasData_transformed, [round(size(atlasData_transformed, 1) * scale_z), round(size(atlasData_transformed, 2) * scale_x)], 'nearest');

        % Process image data
        IQmean_scaled = mat2gray(dB(imgData), [dB_lower_limit, 0]);
        IQmean_rgb = ind2rgb(uint8(IQmean_scaled * 255), gray(256));
        [Na, Nl, ~] = size(IQmean_rgb);
        [cNa, cNl, ~] = size(cData_resized_local);

        % Handle size differences
        if cNa > Na
            pad_z = cNa - Na;
            pad_top = floor(pad_z / 2);
            pad_bottom = pad_z - pad_top;
            IQmean_rgb = padarray(IQmean_rgb, [pad_top, 0], 0, 'pre');
            IQmean_rgb = padarray(IQmean_rgb, [pad_bottom, 0], 0, 'post');
        elseif cNa < Na
            padding_z = Na - cNa;
            pad_top = floor(padding_z / 2);
            pad_bottom = padding_z - pad_top;
            cData_resized_local = padarray(cData_resized_local, [pad_top, 0], min(cData_resized_local(:)), 'pre');
            cData_resized_local = padarray(cData_resized_local, [pad_bottom, 0], min(cData_resized_local(:)), 'post');
            atlasData_resized_local = padarray(atlasData_resized_local, [pad_top, 0], min(atlasData_resized_local(:)), 'pre');
            atlasData_resized_local = padarray(atlasData_resized_local, [pad_bottom, 0], min(atlasData_resized_local(:)), 'post');
        end

        if cNl > Nl
            pad_x = cNl - Nl;
            pad_left = floor(pad_x / 2);
            pad_right = pad_x - pad_left;
            IQmean_rgb = padarray(IQmean_rgb, [0, pad_left], 0, 'pre');
            IQmean_rgb = padarray(IQmean_rgb, [0, pad_right], 0, 'post');
        elseif cNl < Nl
            padding_x = Nl - cNl;
            pad_left = floor(padding_x / 2);
            pad_right = padding_x - pad_left;
            cData_resized_local = padarray(cData_resized_local, [0, pad_left], min(cData_resized_local(:)), 'pre');
            cData_resized_local = padarray(cData_resized_local, [0, pad_right], min(cData_resized_local(:)), 'post');
            atlasData_resized_local = padarray(atlasData_resized_local, [0, pad_left], min(atlasData_resized_local(:)), 'pre');
            atlasData_resized_local = padarray(atlasData_resized_local, [0, pad_right], min(atlasData_resized_local(:)), 'post');
        end

        cData_base = im2double(cData_resized_local);
        atlasData_base = atlasData_resized_local;
    end

    function updateImage()
        if ~isvalid(fig)
            return;
        end

        % Get current display parameters
        dB_lower_limit = str2double(get(dB_input, 'String'));
        opacity = str2double(get(opacity_input, 'String'));
        
        % Process image data
        IQmean_scaled = mat2gray(dB(imgData), [dB_lower_limit, 0]);
        IQmean_rgb = ind2rgb(uint8(IQmean_scaled * 255), gray(256));
        
        % Apply current shifts to get the final image
        updateShiftedImage();
    end

    function updateDisplay()
        % Get current opacity
        opacity = str2double(get(opacity_input, 'String'));
        
        % Create transparency map
        transmap = opacity * ones(size(cData_resized, 1), size(cData_resized, 2));
        transmap_scaled = mat2gray(transmap, [0, 1]);
        
        % Combine images
        combined_rgb = IQmean_rgb;
        for i = 1:3
            combined_rgb(:,:,i) = combined_rgb(:,:,i) .* (1 - transmap_scaled) + ...
                                  cData_resized(:,:,i) .* transmap_scaled;
        end

        % If combined image is larger than original image data, crop center region
        [cH, cW, ~] = size(combined_rgb);
        [iH, iW, ~] = size(imgData);
    
        if cH > iH
            startZ = floor((cH - iH) / 2) + 1;
            combined_rgb = combined_rgb(startZ:startZ + iH - 1, :, :);
        end
        if cW > iW
            startX = floor((cW - iW) / 2) + 1;
            combined_rgb = combined_rgb(:, startX:startX + iW - 1, :);
        end

        % Update display
        if isempty(img_handle) || ~isvalid(img_handle)
            img_handle = imshow(combined_rgb, 'Parent', ax);
        else
            set(img_handle, 'CData', combined_rgb);
        end
    end

    function reset()
        % Set parameters to default values
        brain_pixel_axial_size = 50e-6;
        brain_pixel_lateral_size = 50e-6;
        
        % Update transform parameters
        atlasTransform.brain_pixel_axial_size = brain_pixel_axial_size;
        atlasTransform.brain_pixel_lateral_size = brain_pixel_lateral_size;
        atlasTransform.rot_angle = 0;
        atlasTransform.h_shift = 0;
        atlasTransform.v_shift = 0;
        
        % Reset transformed data
        cData_transformed = cData;
        atlasData_transformed = atlasData;
        
        % Update UI controls - IMPORTANT: update in specific order
        set(axial_slider, 'Value', brain_pixel_axial_size * 1e6);
        set(axial_value, 'String', num2str(brain_pixel_axial_size * 1e6));
        set(lateral_slider, 'Value', brain_pixel_lateral_size * 1e6);
        set(lateral_value, 'String', num2str(brain_pixel_lateral_size * 1e6));
        set(rotate_slider, 'Value', 0);
        set(rotate_value, 'String', '0');
        set(h_slider, 'Value', 0);
        set(h_value, 'String', '0');
        set(v_slider, 'Value', 0);
        set(v_value, 'String', '0');
        
        % Update the image
        updateImage();
        
        % Force a drawnow to ensure UI updates
        drawnow;
    end

    function loadMatFile()
        [file, path] = uigetfile('*.mat', 'Select MAT File');
        if isequal(file, 0)
            disp('User canceled file selection.');
            return;
        end
        
        try
            loadedData = load(fullfile(path, file));
            if isfield(loadedData, 'atlasTransform')
                % Get transform parameters
                atlasTransform = loadedData.atlasTransform;
                
                % Update local variables
                brain_pixel_axial_size = atlasTransform.brain_pixel_axial_size;
                brain_pixel_lateral_size = atlasTransform.brain_pixel_lateral_size;
                
                % Apply rotation first
                cData_transformed = imrotate(cData, atlasTransform.rot_angle, 'nearest');
                atlasData_transformed = imrotate(atlasData, atlasTransform.rot_angle, 'nearest');
                
                % Update UI controls - IMPORTANT: update in specific order
                set(axial_slider, 'Value', brain_pixel_axial_size * 1e6);
                set(axial_value, 'String', num2str(brain_pixel_axial_size * 1e6));
                set(lateral_slider, 'Value', brain_pixel_lateral_size * 1e6);
                set(lateral_value, 'String', num2str(brain_pixel_lateral_size * 1e6));
                set(rotate_slider, 'Value', atlasTransform.rot_angle);
                set(rotate_value, 'String', num2str(atlasTransform.rot_angle));
                set(h_slider, 'Value', 0);
                set(h_value, 'String', '0');
                set(v_slider, 'Value', 0);
                set(v_value, 'String', '0');
                
                % Force a drawnow to ensure UI updates
                drawnow;
                
                % Update image with new parameters
                updateImage();
                
                % Apply shifts after resize
                set(h_slider, 'Value', atlasTransform.h_shift);
                set(h_value, 'String', num2str(atlasTransform.h_shift));
                updateHorizontalShiftFromInput();
                
                set(v_slider, 'Value', atlasTransform.v_shift);
                set(v_value, 'String', num2str(atlasTransform.v_shift));
                updateVerticalShiftFromInput();
                
                disp('Transform parameters loaded successfully.');
            else
                errordlg('Selected file does not contain valid transform parameters.', 'Error');
            end
        catch ME
            errordlg(['Error loading file: ' ME.message], 'Error');
        end
    end

    function saveMatFile()
        [file, path] = uiputfile('*.mat', 'Save Transform Parameters');
        if isequal(file, 0)
            disp('User canceled save operation.');
            return;
        end
        
        try
            % Save the transform parameters
            save(fullfile(path, file), 'atlasTransform');
            disp('Transform parameters saved successfully.');
        catch ME
            errordlg(['Error saving file: ' ME.message], 'Error');
        end
   end

    function confirmAndClose()
        atlasData_resized(atlasData_resized==0) = 1;
        shiftedAtlasData = atlasData_resized;
        shiftedcData = cData_resized;
        confirmed = 1;
        uiresume(fig);
        close(fig);
    end
end
