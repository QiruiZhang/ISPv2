% This script decodes the H264 encoded bitstream from the real Sony DSP 
% chip and tests its validity. 
% Scenario: The whole VGA image is encoded and sent out through AHB 
% debugging path. 

clc;
clear all;
addpath(genpath('./Residual/'));

filename = './ChipTestRes/tb_2_h264_isp37_0829_1429.bin_raw';
%filename = '/afs/eecs.umich.edu/vlsida/projects/VC/users/hyochan/long_sim/vsim/top/fls_1.txt'

bitstream = textread(filename);
bitstream = char(bitstream + 48);
bitstream = bitstream';

% load("bitstream_chip.mat");
% bitstream = bitstream(2:end); 

% load('bitstream_vlog.mat')
%bitstream = bitstream_vlog;

% bitstream = [bitstream '000000'];

% load('Chip_bitstream_gt.mat');
% check = (sum((bitstream(1:14415) == bitstream_cd(1:14415))));

% load("bitstream_cd_gt.mat")
% bitstream = bitstream_cd; 

global bw_pixel;
bw_pixel = 8;

% Set Quantization Parameter here
Quant = (0+(bw_pixel-8)*4):(52+(bw_pixel-8)*4);
global QP;
QP = Quant(11);

h = 480-16*0; w = 640; % VGA

ref_frame = zeros(h, w, 3);
cd_map = ones(h/16,w/16);

%Run Decoding
SetTable
idx = 1;
[Dec_Y_cd,Dec_U_cd, Dec_V_cd, idx, bitstream] = DEC_Frame_FIFOdbg(idx,bitstream,ref_frame,cd_map);

%imshow(uint8(Dec_Y_cd),[])

% maxY = max(max(Dec_Y_cd))
% maxU = max(max(Dec_U_cd))
% maxV = max(max(Dec_V_cd))
% max_pix = max([maxY,maxU,maxV])

figure(1)
Dec_RGB_cd = YUV2RGB(Dec_Y_cd,Dec_U_cd,Dec_V_cd);
% Dec_RGB_cd = imresize(Dec_RGB_cd,[120,160]);
imshow(uint8(Dec_RGB_cd),[])
imwrite(Dec_RGB_cd/max(max(max(Dec_RGB_cd))), './Chip_H264_DecImg_isp37_0822_1052.jpg')
% H264_pic = Dec_RGB_cd/max(max(max(Dec_RGB_cd)));

save("Chip_JPEG_imgCD.mat", "Dec_Y_cd", "Dec_U_cd", "Dec_V_cd");

% figure(2)
% Dec_RGB_cd = YUV2RGB(Dec_Y_cd/max_pix,Dec_U_cd/max_pix,Dec_V_cd/max_pix);
% imshow(Dec_RGB_cd)
