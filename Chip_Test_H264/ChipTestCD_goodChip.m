% This script decodes the H264 encoded bitstream from the real Sony DSP 
% chip and tests its validity. 
% Scenario: Only change detected region encoded. Decode with bitstream and 
% reference frame (JPEG-decoded).

% For good chips
% Format: 1280 bits CD map + 1200 * 32 bits CD map + H264 encoded bitstream

clc;
clear;
addpath(genpath('./Residual/'));

% global settings
global bw_pixel;
bw_pixel = 8;

% Set Quantization Parameter here
Quant = 10;
global QP

Compres_ratio_IMGvsCDB = zeros(1, length(Quant));
Compres_ratio_IMGvsCDB_est = zeros(1, length(Quant));
PSNR_IMGvsIMG = zeros(1, length(Quant));

Compres_ratio_CDBvsCDB = zeros(1, length(Quant));
PSNR_CDBvsCDB = zeros(1, length(Quant));

h = 480-16*1; w = 640; % VGA

% load raw CD image and convert it into bayer
load("Chip_Raw_imgCD.mat");
    
lumma = lumma(1:h, 1:w);
imgcb420 = imgcb420(1:(h/2), 1:(w/2));
imgcr420 = imgcr420(1:(h/2), 1:(w/2));
    
RGB_cd = YUV2RGB(lumma, imgcb420, imgcr420);

% show raw lossless CD image
figure(1)
imshow(uint8(RGB_cd),[]);
    
bayer_cd = zeros(h,w);
Ir_cd = RGB_cd(:,:,1);               
Ig_cd = RGB_cd(:,:,2);
Ib_cd = RGB_cd(:,:,3);
for j = 1:2:h
    for k = 1:2:w
        bayer_cd(j,k)    = Ig_cd(j,k);
        bayer_cd(j,k+1)  = Ir_cd(j,k+1);
        bayer_cd(j+1,k)  = Ib_cd(j+1,k);
        bayer_cd(j+1,k+1)= Ig_cd(j+1,k+1);
    end
end

% load the JPEG decompressed reference image from Chip
load("Chip_JPEG_img.mat");
    
ref_Y = Y_img;
ref_U = U_img;
ref_V = V_img;

figure(2)
RGB_ref = YUV2RGB(Y_img, U_img, V_img);
imshow(uint8(RGB_ref),[]);

SetTable

for q = 1:length(Quant)
    QP = Quant(q)
    filename = ['./ChipTestRes_CDsweepQP/tb_8_h264_q', num2str(QP), '_isp37.bin_raw'];

    bitstream = textread(filename);
    
    % parsing CD map output in the first format
    cdmap1 = bitstream(1:1280);
    cdmap1 = reshape(cdmap1, 32,40);
    cdmap1 = cdmap1(1:30,:);

    % parsing CD map output in the second format
    cdmap2 = bitstream(1281:1280+30*40*32);
    cdmap3 = reshape(cdmap2, 30*32,40);

    cdmap2 = zeros(30,40);
    for j = 1:40
        for i = 1:30
            cdmap2(i,j) = cdmap3((i-1)*32 + 1,j);
        end
    end

    % for QP = 5 debugging only
    if (QP == 5)
        cdmap1(28, 25:end) = 0;
        cdmap2(28, 25:end) = 0;
    end
    
    % extract the encoded bitstream
    bitstream = bitstream(1280+30*40*32+1:end);
    bitstream = char(bitstream + 48)';
    
    % decode the bitstream using DeJPEGed reference image and CD map
    idx = 1;
    [Dec_Y_cd,Dec_U_cd, Dec_V_cd, idx] = DEC_Frame_YUV_FIFOdbg(idx,bitstream,ref_Y, ref_U, ref_V, cdmap1, h, w);

    % show decoded image 
    figure(3)
    Dec_RGB_cd = YUV2RGB(Dec_Y_cd,Dec_U_cd,Dec_V_cd);
    imshow(uint8(Dec_RGB_cd),[]);
    imwrite(Dec_RGB_cd/max(max(max(Dec_RGB_cd))), ['./Chip_ImgRes_CDsweepQP/Chip_H264_DecImgCD_isp37_q', num2str(QP), '.jpg']);
    
    %convert decoded change detected frame to bayer
    bayer_cd_dec = zeros(h,w);
    Ir_cd_dec = Dec_RGB_cd(:,:,1);               
    Ig_cd_dec = Dec_RGB_cd(:,:,2);
    Ib_cd_dec = Dec_RGB_cd(:,:,3);
    for j = 1:2:h
        for k = 1:2:w
            bayer_cd_dec(j,k)    = Ig_cd_dec(j,k);
            bayer_cd_dec(j,k+1)  = Ir_cd_dec(j,k+1);
            bayer_cd_dec(j+1,k)  = Ib_cd_dec(j+1,k);
            bayer_cd_dec(j+1,k+1)= Ig_cd_dec(j+1,k+1);
        end
    end
    
    num_cdb = sum(cdmap1, 'all');
    bit_length = length(bitstream)/num_cdb * 120;
    
    Compres_ratio_IMGvsIMG(q) = 256*num_cdb/length(bitstream);
    Compres_ratio_IMGvsCDB(q) = 480*640*12/length(bitstream);
    Compres_ratio_IMGvsCDB_est(q) = 480*640*12/bit_length;
    PSNR_IMGvsIMG(q) = find_psnr(bayer_cd_dec, bayer_cd, ones(h, w));
    
    Compres_ratio_CDBvsCDB(q) = 16*16*8*sum(cdmap1, 'all')/length(bitstream);
    
    mask = zeros(h, w);
    for i = 1:(h/16)
        for j = 1:(w/16)
            if (cdmap1(i,j))
                mask( ((i-1)*16 + 1):((i-1)*16 + 16), ((j-1)*16 + 1):((j-1)*16 + 16) ) = 1;
            end
        end
    end
    
    PSNR_CDBvsCDB(q) = find_psnr(bayer_cd_dec, bayer_cd, mask);
end    

figure(4);
plot(Compres_ratio_IMGvsCDB, PSNR_IMGvsIMG,'-.ro');
hold on;
xlabel('Compression Ratio');
ylabel('PSNR (dB)');

save("CD_IMF_H264_Perform_sweepQP.mat", "Compres_ratio_IMGvsCDB", "Compres_ratio_IMGvsCDB_est", "Compres_ratio_IMGvsIMG", "PSNR_IMGvsIMG");