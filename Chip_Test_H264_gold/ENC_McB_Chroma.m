function [bits_McB_Chroma, mode_last,Seq_r] = ENC_McB_Chroma(McB_Chroma, row_start, col_start, mode_pre_McB,Seq_r)
global bw_pixel;
global QP h w;
global num_op;

bits_McB_Chroma = '';
mode_prev = mode_pre_McB;


if (row_start==1)&&(col_start==1)    % No prediciton
    [icp,pred,sae] = pred_dc_8(McB_Chroma,Seq_r,8,row_start,col_start);
    mode = 11;        % only dc pred available
    bits = enc_golomb(mode - mode_prev, 1);
    mode_prev = mode;
    bits_McB_Chroma = [bits_McB_Chroma bits];
    [icp_r,bits] = code_block_chroma(icp);
    bits_McB_Chroma = [bits_McB_Chroma bits];
    Seq_r(row_start:row_start+7,col_start:col_start+7) = clip(icp_r + pred,2^bw_pixel-1);
elseif (row_start==1)       % Horz prediction
    [icp,pred,sae,mode] = mode_select_8_vertical_boundary(McB_Chroma,Seq_r,8,row_start,col_start);	    
    bits = enc_golomb(mode - mode_prev, 1);
    mode_prev = mode;
    bits_McB_Chroma = [bits_McB_Chroma bits];
    [icp_r,bits] = code_block_chroma(icp);
    bits_McB_Chroma = [bits_McB_Chroma bits];
    Seq_r(row_start:row_start+7,col_start:col_start+7) = clip(icp_r + pred,2^bw_pixel-1);
    num_op = num_op +8*8+1;
elseif (col_start==1)       % Vert prediction
    [icp,pred,sae,mode] = mode_select_8_horizontal_boundary(McB_Chroma,Seq_r,8,row_start,col_start);       
    bits = enc_golomb(mode - mode_prev, 1);
    mode_prev = mode;
    bits_McB_Chroma = [bits_McB_Chroma bits];
    [icp_r,bits] = code_block_chroma(icp);
    bits_McB_Chroma = [bits_McB_Chroma bits];
    Seq_r(row_start:row_start+7,col_start:col_start+7) = clip(icp_r + pred,2^bw_pixel-1);
    num_op = num_op +8*8+1;
else                % Try all different prediction
    [icp,pred,sae,mode] = mode_select_8(McB_Chroma,Seq_r,8,row_start,col_start);
    bits = enc_golomb(mode - mode_prev, 1);
    mode_prev = mode;
    bits_McB_Chroma = [bits_McB_Chroma bits];
    [icp_r,bits] = code_block_chroma(icp);
    bits_McB_Chroma = [bits_McB_Chroma bits];
    Seq_r(row_start:row_start+7,col_start:col_start+7) = clip(icp_r + pred,2^bw_pixel-1);
    num_op = num_op +8*8+1;
end

mode_last = mode;
end % end of function


%--------------------------------------------------------------------------
%% 8x8 Horizontal prediciton
function [icp,pred,sae] = pred_horz_8(McB_Chroma,Seq_r,bs,i,j)
global num_op;
pred = Seq_r(i:i+7,j-1)*ones(1,bs);
icp = McB_Chroma - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 8*8 + 8*8;
end

%-------------------------------------------------------
%% 8x8 Vertical Prediciton
function [icp,pred,sae] = pred_vert_8(McB_Chroma,Seq_r,bs,i,j)
global num_op;
pred = ones(bs,1)*Seq_r(i-1,j:j+7);
icp = McB_Chroma - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 8*8 + 8*8;
end

%-------------------------------------------------------
%% 8x8 DC prediction
function [icp,pred,sae] = pred_dc_8(McB_Chroma,Seq_r,bs,i,j)
global bw_pixel;
global num_op;
if (i==1) && (j==1)
    pred(1:4,1:4) = (2^(bw_pixel-1))*ones(4,4);
    pred(1:4,5:8) = (2^(bw_pixel-1))*ones(4,4);
    pred(5:8,1:4) = (2^(bw_pixel-1))*ones(4,4);
    pred(5:8,5:8) = (2^(bw_pixel-1))*ones(4,4);
elseif(i==1)
	pred(1:4,1:4) = bitshift(sum(Seq_r(i:i+3,j-1)) + 2,-2,'int64');
	pred(1:4,5:8) = bitshift(sum(Seq_r(i:i+3,j-1)) + 2,-2,'int64');
	pred(5:8,1:4) = bitshift(sum(Seq_r(i+4:i+7,j-1)) + 2,-2,'int64');
	pred(5:8,5:8) = bitshift(sum(Seq_r(i+4:i+7,j-1)) + 2,-2,'int64');
elseif(j==1)
	pred(1:4,1:4) = bitshift(sum(Seq_r(i-1,j:j+3)) + 2,-2,'int64');
	pred(1:4,5:8) = bitshift(sum(Seq_r(i-1,j+4:j+7)) + 2,-2,'int64');
	pred(5:8,1:4) = bitshift(sum(Seq_r(i-1,j:j+3)) + 2,-2,'int64');
	pred(5:8,5:8) = bitshift(sum(Seq_r(i-1,j+4:j+7)) + 2,-2,'int64');
else
	pred(1:4,1:4) = bitshift(sum(Seq_r(i-1,j:j+3)) + sum(Seq_r(i:i+3,j-1)) + 4,-3,'int64');
	pred(1:4,5:8) = bitshift(sum(Seq_r(i-1,j+4:j+7)) + 2,-2,'int64');
	pred(5:8,1:4) = bitshift(sum(Seq_r(i+4:i+7,j-1)) + 2,-2,'int64');
	pred(5:8,5:8) = bitshift(sum(Seq_r(i-1,j+4:j+7)) + sum(Seq_r(i+4:i+7,j-1)) + 4,-3,'int64');
end

num_op = num_op + 32;
icp = McB_Chroma - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 8*8 + 8*8;
end

%------------------------------------------------------
%% 8x8 Plane prediction
function [icp,pred,sae] = pred_plane_8(McB_Chroma,Seq_r,bs,i,j)
global bw_pixel;
global num_op;
Seq_r_temp = Seq_r(i-1,j-1);
Seq_r(i-1,j-1) = bitshift(Seq_r(i-1,j) + Seq_r(i,j-1),-1,'int64');
x = 0:3;
H = sum((x+1)*(Seq_r(i+x+4,j-1)-Seq_r(i+2-x,j-1)));
y = 0:3;
V = sum((y+1)*(Seq_r(i-1,j+4+y)'-Seq_r(i-1,j+2-y)'));
Seq_r(i-1,j-1) = Seq_r_temp;

a = 16*(Seq_r(i-1,j+7) + Seq_r(i+7,j-1));
b = bitshift(17*H + 16,-5,'int64');
c = bitshift(17*V + 16,-5,'int64');


num_op = num_op + 3*4*2+2 + 3*4*2;
for m = 1:8
    for n = 1:8
        d = bitshift(a + b*(m-4)+ c*(n-4) + 16,-5,'int64');
        num_op = num_op + 7;
        if d <0
            pred(m,n) = 0;
        elseif d > 2^bw_pixel - 1
            pred(m,n) = 2^bw_pixel - 1;
        else
            pred(m,n) = d;
        end
    end
end

icp = McB_Chroma - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 8*8*2;
end

%---------------------------------------------------------
%% Mode selection for 8*8 first vertical boundary prediction
function [icp,pred,sae,mode] = mode_select_8_vertical_boundary(McB_Chroma,Seq_r,bs,i,j)
global num_op;
[icp1,pred1,sae1] = pred_horz_8(McB_Chroma,Seq_r,bs,i,j);

[icp2,pred2,sae2] = pred_dc_8(McB_Chroma,Seq_r,bs,i,j);

num_op = num_op + 8*8 + 8*8;

[sae,idx]=min([sae1 sae2]);
num_op = num_op +1;
switch idx
    case 1
        icp = icp1;
        pred = pred1; 
        mode = 10;
    case 2
        icp = icp2;
        pred = pred2;
        mode = 11;
end
end

%---------------------------------------------------------
%% Mode selection for 8*8 first horizontal boundary prediction
function [icp,pred,sae,mode] = mode_select_8_horizontal_boundary(McB_Chroma,Seq_r,bs,i,j)
global num_op;
[icp1,pred1,sae1] = pred_vert_8(McB_Chroma,Seq_r,bs,i,j);

[icp2,pred2,sae2] = pred_dc_8(McB_Chroma,Seq_r,bs,i,j);

[sae,idx]=min([sae1 sae2]);
num_op = num_op +1;
switch idx
    case 1
        icp = icp1;
        pred = pred1; 
        mode = 9;
    case 2
        icp = icp2;
        pred = pred2;
        mode = 11;
end
end

%---------------------------------------------------------
%% Mode selection for 8x8 prediciton
function [icp,pred,sae,mode] = mode_select_8(McB_Chroma,Seq_r,bs,i,j)

global num_op;
[icp1,pred1,sae1] = pred_vert_8(McB_Chroma,Seq_r,bs,i,j);
[icp2,pred2,sae2] = pred_horz_8(McB_Chroma,Seq_r,bs,i,j);
[icp3,pred3,sae3] = pred_dc_8(McB_Chroma,Seq_r,bs,i,j);
[icp4,pred4,sae4] = pred_plane_8(McB_Chroma,Seq_r,bs,i,j);

[sae,idx]=min([sae1 sae2 sae3 sae4]);
num_op = num_op + 3;
switch idx
    case 1
        icp = icp1;
        pred = pred1; 
        mode = 9;
    case 2
        icp = icp2;
        pred = pred2;
        mode = 10;
    case 3
        icp = icp3;
        pred = pred3;
        mode = 11;
    case 4
        icp = icp4;
        pred = pred4; 
        mode = 12;
end
end

%--------------------------------------------------------
%********************************************************
%% Transform, Quantization, Entropy coding
%********************************************************
% transform = Integer transform
% Quantization = h.264 
% VLC = CAVLC (H.264)
function [err_r,bits_mb] = code_block_chroma(err)
global num_op;
global QP

[n,m] = size(err);

bits_mb = '';

for i = 1:4:n
    for j = 1:4:m
        c(i:i+3,j:j+3) = integer_transform(err(i:i+3,j:j+3));
	    Wd(round(i/4)+1,round(j/4)+1) = c(i,j);
        num_op = num_op +4;
    end
end

ch = DC_chroma_transform(Wd);
DCq = DC_chroma_quantization(ch,QP);

for i = 1:4:n
    for j = 1:4:n
        cq(i:i+3,j:j+3) = quantization(c(i:i+3,j:j+3),QP);
        cq(i,j) = DCq(round(i/4)+1,round(j/4)+1);
        num_op = num_op +4;
        [bits_b] = enc_cavlc(cq(i:i+3,j:j+3), 0, 0);       
        bits_mb = [bits_mb bits_b] ;
        num_op = num_op +4;
    end
end    

DCi = inv_DC_chroma_quantization(DCq,QP);
chi = inv_DC_chroma_transform(DCi);

for i = 1:4:n
    for j = 1:4:n
        Wi = inv_quantization(cq(i:i+3,j:j+3),QP);
	    Wi(1,1) = chi(round(i/4)+1,round(j/4)+1);
        Y = inv_integer_transform(Wi);        
        err_r(i:i+3,j:j+3) = bitshift(Y,-6,'int64');
        num_op = num_op + 16;
    end
end
end

