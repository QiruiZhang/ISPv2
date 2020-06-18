% This script decodes the H264 encoded bitstream from the real Sony DSP 
% chip and tests its validity. 
% Scenario: The whole VGA image is encoded and sent out through direct path
% to flash interface. 

clc;
clear;
addpath(genpath('./Residual/'));

filename = './../03_captures/isp2/tb_23_0610_1352.bin_raw';
filename = './../03_captures/isp2/tb_24_0613_1406.bin_raw';
%filename = './../03_captures/h264_1.txt';
%filename = '/afs/eecs.umich.edu/vlsida/projects/VC/users/hyochan/long_sim/vsim/top/fls_1.txt'

global bw_pixel;
bw_pixel = 8;

% Set Quantization Parameter here
Quant = (0+(bw_pixel-8)*4):(52+(bw_pixel-8)*4);
global QP;
QP = Quant(20);

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

h = 480; w = 640; % VGA

ref_frame = zeros(480, 640, 3);
cd_map = ones(30,40);

SetTable
idx = 1;

%[Dec_Y_cd,Dec_U_cd, Dec_V_cd, idx, dbg_buf] = DEC_Frame2_bu(idx,bitstream,ref_frame,cd_map);
[Dec_Y_cd,Dec_U_cd, Dec_V_cd, idx] = DEC_Frame2(idx,bitstream,ref_frame,cd_map);
%imshow(uint8(Dec_Y_cd),[])

% maxY = max(max(Dec_Y_cd))
% maxU = max(max(Dec_U_cd))
% maxV = max(max(Dec_V_cd))     
% max_pix = max([maxY,maxU,maxV])

figure(1)
Dec_RGB_cd = YUV2RGB(Dec_Y_cd,Dec_U_cd,Dec_V_cd);
% Dec_RGB_cd = imresize(Dec_RGB_cd,[120,160]);
imshow(uint8(Dec_RGB_cd),[])
imwrite(Dec_RGB_cd/max(max(max(Dec_RGB_cd))), './Chip_H264_res.jpg')
% H264_pic = Dec_RGB_cd/max(max(max(Dec_RGB_cd)));

% figure(2)
% Dec_RGB_cd = YUV2RGB(Dec_Y_cd/max_pix,Dec_U_cd/max_pix,Dec_V_cd/max_pix);
% imshow(Dec_RGB_cd)
