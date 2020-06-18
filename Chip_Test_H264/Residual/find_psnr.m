function [PSNR]=find_psnr(A,B, mask)

mse = sum(((A-B).*mask).^2, 'all')/sum(mask, 'all');
PSNR = 10*log10((255.^2)/mse);