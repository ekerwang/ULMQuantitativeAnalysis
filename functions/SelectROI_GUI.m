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

function [mask, vertices] = SelectROI_GUI(counterMap)
    fig = figure;
    imagesc(sqrt(counterMap),[0,5]);axis image;colormap("gray")
    im_size = size(counterMap);

    h = impoly(gca);
    
    % Extract vertices from manual ROI and convert to cell
    vertices = getPosition(h);
    vertex_cell = mat2cell(vertices, ones(size(vertices,1),1), 2);
    
    % Interpolate between vertices using a Bezier curve (Hobby spline)
    % Closed curve
    vertex_interpolate = util.hobbysplines(vertex_cell,'cycle',true);
    
    % Generate mask from Hobby spline
    mask = poly2mask(vertex_interpolate(:,1),vertex_interpolate(:,2),im_size(1),im_size(2));
    close(fig)
end