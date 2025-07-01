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

function transformedMask = applyAtlasTransform(mask, atlasTransform, targetSize, dx, dz)
% APPLYATLASTRANSFORM Applies atlas transformation to a mask
%
% This function applies the transformation parameters from atlasTransform
% to the input mask, performing scaling, rotation, and translation.
%
% Inputs:
%   mask - Input binary mask to transform
%   atlasTransform - Structure containing transformation parameters:
%       .brain_pixel_axial_size - Axial pixel size in meters
%       .brain_pixel_lateral_size - Lateral pixel size in meters
%       .rot_angle - Rotation angle in degrees
%       .h_shift - Horizontal shift in pixels
%       .v_shift - Vertical shift in pixels
%   targetSize - [optional] Size of the target image [height, width]
%   dx - [optional] Original lateral pixel size (default: 50e-6)
%   dz - [optional] Original axial pixel size (default: 50e-6)
%
% Output:
%   transformedMask - The transformed binary mask

    % Check inputs
    if nargin < 2
        error('At least two inputs are required: mask and atlasTransform');
    end
    
    if nargin < 3
        targetSize = [];
    end
    
    % Set default pixel sizes if not provided
    if nargin < 4
        dx = 50e-6; % Default lateral pixel size (50 microns)
    end
    
    if nargin < 5
        dz = 50e-6; % Default axial pixel size (50 microns)
    end
    
    % Validate atlasTransform structure
    requiredFields = {'brain_pixel_axial_size', 'brain_pixel_lateral_size', ...
                     'rot_angle', 'h_shift', 'v_shift'};
    for i = 1:length(requiredFields)
        if ~isfield(atlasTransform, requiredFields{i})
            error(['atlasTransform is missing required field: ' requiredFields{i}]);
        end
    end
    
    % Extract transformation parameters
    brain_pixel_axial_size = atlasTransform.brain_pixel_axial_size;
    brain_pixel_lateral_size = atlasTransform.brain_pixel_lateral_size;
    rot_angle = atlasTransform.rot_angle;
    h_shift = atlasTransform.h_shift;
    v_shift = atlasTransform.v_shift;
    
    % Convert mask to double for better interpolation precision
    mask = double(mask);
    
    % Step 1: Apply rotation using bicubic interpolation
    mask_transformed = imrotate(mask, rot_angle, 'bicubic');
    
    % Step 2: Calculate scaling factors using dx and dz
    scale_z = brain_pixel_axial_size / dz;
    scale_x = brain_pixel_lateral_size / dx;
    
    % Step 3: Apply scaling using bicubic interpolation
    mask_resized = imresize(mask_transformed, [round(size(mask_transformed, 1) * scale_z), ...
                                             round(size(mask_transformed, 2) * scale_x)], 'bicubic');
    
    % Step 4: Handle size differences if targetSize is provided
    if ~isempty(targetSize)
        Na = targetSize(1);
        Nl = targetSize(2);
        [cNa, cNl] = size(mask_resized);
        
        % Handle height differences
        if cNa < Na
            padding_z = Na - cNa;
            pad_top = floor(padding_z / 2);
            pad_bottom = padding_z - pad_top;
            mask_resized = padarray(mask_resized, [pad_top, 0], 0, 'pre');
            mask_resized = padarray(mask_resized, [pad_bottom, 0], 0, 'post');
        end
        
        % Handle width differences
        if cNl < Nl
            padding_x = Nl - cNl;
            pad_left = floor(padding_x / 2);
            pad_right = padding_x - pad_left;
            mask_resized = padarray(mask_resized, [0, pad_left], 0, 'pre');
            mask_resized = padarray(mask_resized, [0, pad_right], 0, 'post');
        end
    end
    
    % Step 5: Apply horizontal and vertical shifts
    % For more accurate interpolation during shift, we could use imtranslate
    % but circshift is more consistent with the original implementation
    shiftedMask = circshift(mask_resized, [v_shift, h_shift]);
    
    % Step 6: Now crop to match target size
    if ~isempty(targetSize)
        [H, W] = size(shiftedMask);
        cropH = targetSize(1);
        cropW = targetSize(2);
    
        startH = floor((H - cropH)/2) + 1;
        endH = startH + cropH - 1;
        startW = floor((W - cropW)/2) + 1;
        endW = startW + cropW - 1;
    
        % Boundary check
        if endH > H
            endH = H;
            startH = endH - cropH + 1;
        end
        if endW > W
            endW = W;
            startW = endW - cropW + 1;
        end
    
        shiftedMask = shiftedMask(startH:endH, startW:endW);
    end

    % Step 7: Binarize the mask with threshold 0.5
    % Values >= 0.5 become 1, values < 0.5 become 0
    transformedMask = shiftedMask >= 0.5;
end 