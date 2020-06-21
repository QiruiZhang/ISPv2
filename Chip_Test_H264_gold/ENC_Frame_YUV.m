function [bitstream,Rec_Frame_Luma,Rec_Frame_ChromaB,Rec_Frame_ChromaR] = ENC_Frame_YUV(cur_Y,cur_U,cur_V, ref_Y, ref_U, ref_V, CD_map)
%ENC_FRAME Summary of this function goes here
% The function is for H.264 encoding of a frame with change detection map
% and reference frame.
global bw_pixel;
% convert current frame from 8-bit RGB to 12-bit YUV
[h,w,~] = size(ref_Y);

%Convert to YUV

%subsample as 4:2:0 and extend to 12-bit pixel   
Y_cur = cur_Y * 2^(bw_pixel-8);
U_cur = cur_U * 2^(bw_pixel-8);         
V_cur = cur_V * 2^(bw_pixel-8);

% convert reference frame from 8-bit RGB to 12-bit YUV

%Convert to YUV
%Iyuv_ref  = rgb2ycbcr(ref_frame); 
%Iyuv_ref = double(Iyuv_ref);
%Iy_ref = Iyuv_ref(:,:,1);
%Iu_ref = Iyuv_ref(:,:,2);
%Iv_ref = Iyuv_ref(:,:,3);

%subsample as 4:2:0 and extend to 12-bit pixel   
%Y_ref = Iy_ref(:,:) * 2^(bw_pixel-8);
%U_ref = Iu_ref(1:2:h,1:2:w) * 2^(bw_pixel-8);         
%V_ref = Iv_ref(1:2:h,1:2:w) * 2^(bw_pixel-8);

Y_ref = ref_Y;
U_ref = ref_U;
V_ref = ref_V;

mode_pre_McB_Luma = 0;
mode_pre_McB_ChromaB = 9;
mode_pre_McB_ChromaR = 9;
bitstream = [];

Rec_Frame_Luma = Y_ref;
Rec_Frame_ChromaB = U_ref;
Rec_Frame_ChromaR = V_ref;

i = 0;

%Hardware encoding
for row_start = 1:16:h
    for col_start = 1:16:w
        if (CD_map(floor(row_start/16)+1,floor(col_start/16)+1) == 1)
            %i = i + 1
            McB_Luma = Y_cur(row_start:row_start+15,col_start:col_start+15);
            [bits_McB_Luma, mode_last_Luma,Rec_Frame_Luma] = ENC_McB_Luma(McB_Luma, row_start, col_start, mode_pre_McB_Luma,Rec_Frame_Luma);
            mode_pre_McB_Luma = mode_last_Luma;
            bitstream = [bitstream bits_McB_Luma];
            %Chroma
            row_start_ch = (row_start - 1)/2 + 1;
            col_start_ch = (col_start - 1)/2 + 1;
            %ChromaB
            McB_ChromaB = U_cur(row_start_ch:row_start_ch+7,col_start_ch:col_start_ch+7);
            [bits_McB_ChromaB, mode_last_ChromaB,Rec_Frame_ChromaB] = ENC_McB_Chroma(McB_ChromaB, row_start_ch, col_start_ch, mode_pre_McB_ChromaB,Rec_Frame_ChromaB);
            mode_pre_McB_ChromaB = mode_last_ChromaB;
            bitstream = [bitstream bits_McB_ChromaB];
            %ChromaR
            McB_ChromaR = V_cur(row_start_ch:row_start_ch+7,col_start_ch:col_start_ch+7);
            [bits_McB_ChromaR, mode_last_ChromaR,Rec_Frame_ChromaR] = ENC_McB_Chroma(McB_ChromaR, row_start_ch, col_start_ch, mode_pre_McB_ChromaR,Rec_Frame_ChromaR);
            mode_pre_McB_ChromaR = mode_last_ChromaR;
            bitstream = [bitstream bits_McB_ChromaR];
        end
    end
end

end

