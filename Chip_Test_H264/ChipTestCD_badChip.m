% This script decodes the H264 encoded bitstream from the real Sony DSP 
% chip and tests its validity. 
% Scenario: Only change detected region encoded. Decode with bitstream and 
% reference frame (JPEG-decoded). 

% For chips with CD problems, CD map overwritten
% Format: 1200 * 32 bits CD map + H264 encoded bitstream

clc;
clear all;
addpath(genpath('./Residual/'));

filename = './ChipTestRes/tb_h264_isp37_0829_1940.bin_raw';
%filename = '/afs/eecs.umich.edu/vlsida/projects/VC/users/hyochan/long_sim/vsim/top/fls_1.txt'

load("Chip_JPEG_img.mat");

global bw_pixel;
bw_pixel = 8;

Quant = (0+(bw_pixel-8)*4):(52+(bw_pixel-8)*4);
global QP;
QP = Quant(11);

bitstream = textread(filename);
% cdmap1 = bitstream(1:1280);
% cdmap1 = reshape(cdmap1, 32,40);
% cdmap1 = cdmap1(1:30,:);

%bitstream = char(bitstream(1281:end) + 48)' ;

cdmap2 = bitstream(1:30*40*32);
cdmap3 = reshape(cdmap2, 30*32,40);

cdmap2 = zeros(30,40);
for j = 1:40
    for i = 1:30
        cdmap2(i,j) = cdmap3((i-1)*32 + 1,j);
    end
end

bitstream = bitstream(30*40*32+1:end);
bitstream = char(bitstream + 48)';

% load('bitstream_cd_gt.mat')
%bitstream = bitstream_vlog;

% bitstream = bitstream(3:end);


h = 480-16*0; w = 640; % VGA

ref_frame = zeros(h, w, 3);
%cd_map = ones(30,40);

% load('JPEG_img_Hyochan.mat')

ref_Y = Y_img;
ref_U = U_img;
ref_V = V_img;

figure(1)
JPEG_RGB = YUV2RGB(Y_img,U_img,V_img);
imshow(uint8(JPEG_RGB),[])

SetTable
idx = 1;
[Dec_Y_cd,Dec_U_cd, Dec_V_cd, idx] = DEC_Frame_YUV_FIFOdbg(idx,bitstream,ref_Y, ref_U, ref_V,cdmap2, h, w);

%imshow(uint8(Dec_Y_cd),[])

% maxY = max(max(Dec_Y_cd))
% maxU = max(max(Dec_U_cd))
% maxV = max(max(Dec_V_cd))
% max_pix = max([maxY,maxU,maxV])

figure(2)
Dec_RGB_cd = YUV2RGB(Dec_Y_cd,Dec_U_cd,Dec_V_cd);
% Dec_RGB_cd = imresize(Dec_RGB_cd,[120,160]);
imshow(uint8(Dec_RGB_cd),[])
imwrite(Dec_RGB_cd/max(max(max(Dec_RGB_cd))), './Chip_H264_DecImgCD_isp37_0829_1558.jpg')
% H264_pic = Dec_RGB_cd/max(max(max(Dec_RGB_cd)));

figure(3)
imshow(imresize(cdmap2, [480, 640])); 

% figure(2)
% Dec_RGB_cd = YUV2RGB(Dec_Y_cd/max_pix,Dec_U_cd/max_pix,Dec_V_cd/max_pix);
% imshow(Dec_RGB_cd)
