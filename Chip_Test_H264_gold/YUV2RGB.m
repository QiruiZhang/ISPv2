function [rgb] = YUV2RGB(Y, U, V)
%SHOWYUV Summary of this function goes here
%   Detailed explanation goes here
[h,w] = size(Y);

reconstructed_img(:,:,1) = Y;                %Convert encoded image back to bayer
reconstructed_img(:,:,2) = imresize(U,[h w]);
reconstructed_img(:,:,3) = imresize(V,[h w]);
reconstructed_img = uint8(reconstructed_img);

RGB_recons = ycbcr2rgb(reconstructed_img);
rgb = double(RGB_recons);
end

