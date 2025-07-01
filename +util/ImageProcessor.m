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

classdef ImageProcessor
    % ImageProcessor - Tools for ULM image processing
    %   Provides methods for ULM image processing, display and overlay
    
    methods (Static)
        function combinedImg = createOverlayImage(mask, baseImage, transparency)
            % createOverlayImage Creates an overlay of ROI mask on ULM image
            %   mask: ROI mask image
            %   baseImage: Base ULM image
            %   transparency: Transparency level, default is 0.5
            
            if nargin < 3
                transparency = 0.5;
            end
            
            % Create transparency layer
            transmap = transparency * ones(size(baseImage));
            
            % Scale base image
            ULMmap_scaled = mat2gray(sqrt(baseImage), [0, 5]);  
            ULMmap_rgb = ind2rgb(uint8(ULMmap_scaled * 255), gray(256));  
            
            % Scale mask image
            mask_scaled = mat2gray(mask, [0, 2.5]); 
            mask_rgb = ind2rgb(uint8(mask_scaled * 255), hot(256));
           
            % Blend images
            transmap_scaled = mat2gray(transmap, [0, 1]); 
            combined_rgb = ULMmap_rgb;
            
            for i = 1:3 
                combined_rgb(:,:,i) = combined_rgb(:,:,i) .* (1 - transmap_scaled) + ...
                                      mask_rgb(:,:,i) .* transmap_scaled;
            end
            
            combinedImg = combined_rgb;
        end
        
        function displayOverlay(mask, baseImage, axesHandle, transparency)
            % displayOverlay Displays overlay image on specified axes
            %   mask: ROI mask image
            %   baseImage: Base ULM image
            %   axesHandle: Handle of axes to display on
            %   transparency: Transparency level, default is 0.5
            
            if nargin < 4
                transparency = 0.5;
            end
            
            % Store current axis settings
            currentXLim = get(axesHandle, 'XLim');
            currentYLim = get(axesHandle, 'YLim');
            currentPosition = get(axesHandle, 'Position');
            currentDataAspectRatio = get(axesHandle, 'DataAspectRatio');
            currentView = get(axesHandle, 'View');
            holdState = ishold(axesHandle);
            
            % Check if axes has been initialized with an image before
            wasInitialized = ~isempty(findobj(axesHandle, 'Type', 'image'));
            
            % Create combined image
            combinedImg = util.ImageProcessor.createOverlayImage(mask, baseImage, transparency);
            
            % Check if there's an existing image in the axes
            existingImg = findobj(axesHandle, 'Type', 'image');
            
            if ~isempty(existingImg)
                % Update existing image data without changing axes properties
                set(existingImg(1), 'CData', combinedImg);
            else
                % No existing image, create a new one with imshow
                % Use imshow for first initialization to get correct orientation and scaling
                imh = imshow(combinedImg, 'Parent', axesHandle);
                
                % Store the image handle for future updates
                setappdata(axesHandle, 'ImageHandle', imh);
            end
            
            % If this is not the first time, restore the original axis settings
            if wasInitialized
                % Restore original axis settings if they were not default
                if ~isequal(currentXLim, [0.5 size(combinedImg, 2)+0.5]) && ~isequal(currentYLim, [0.5 size(combinedImg, 1)+0.5])
                    set(axesHandle, 'XLim', currentXLim, 'YLim', currentYLim);
                end
                
                % Restore other important properties
                set(axesHandle, 'Position', currentPosition);
                set(axesHandle, 'DataAspectRatio', currentDataAspectRatio);
                set(axesHandle, 'View', currentView);
            else
                % For first initialization, ensure the image fills the axes
                axis(axesHandle, 'image');
                axis(axesHandle, 'tight');
            end
            
            % Restore hold state
            if holdState
                hold(axesHandle, 'on');
            else
                hold(axesHandle, 'off');
            end
        end
    end
end 