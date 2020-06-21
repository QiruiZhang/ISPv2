% The standard intra predicitons are used here with no simplifications for DDL and VL prediction modes

function [bits_McB_Luma, mode_last,Seq_r] = ENC_McB_Luma(McB_Luma, row_start, col_start, mode_pre_McB,Seq_r)

% Input
% McB_Luma: current 16 x 16 Luma McB input
% QP: Quantization Parameter
% row_start: row index of the left-top pixel of the current McB in original frame
% col_start: col index of the left-top pixel of the current McB in original frame
% mode_pre_McB: pred mode of the right-bottom 4 x 4 block of the previous McB (the left McB or 
% upper right most McB for a new row of McB)

% Output
% bits_McB_Luma: encoded bitstream for current Luma McB
% mode_last: pred mode of the right bottom 4 x 4 block of the current McB
global bw_pixel;
global num_op;
global h w;
%global Seq_r;

bits_McB_Luma = '';
mode_prev = mode_pre_McB;

for deltaRow = 1:4:16
    for deltaCol = 1:4:16
        row = row_start + deltaRow - 1; % row index of the left top pixel of the current 4 x 4 block in original frame
        col = col_start + deltaCol - 1; % col index of the left top pixel of the current 4 x 4 block in original frame
        if(row==1)&&(col==1) 
            sub_block = McB_Luma(deltaRow:deltaRow+3,deltaCol:deltaCol+3);
            [icp,pred,sae] = pred_dc_4(sub_block,Seq_r,row,col); % only dc pred available
            mode = 2;
            bits = enc_golomb(mode - mode_prev, 1);
            mode_prev = mode;
            bits_McB_Luma = [bits_McB_Luma bits];
            [icp_r,bits] = code_block(icp);
            bits_McB_Luma = [bits_McB_Luma bits];
            Seq_r(row:row+3,col:col+3) = clip(icp_r + pred,2^bw_pixel-1);
        elseif (row==1) % Vertical boundary
            sub_block = McB_Luma(deltaRow:deltaRow+3,deltaCol:deltaCol+3);
            [icp,pred,sae,mode] = mode_select_4_vertical_boundary(sub_block, Seq_r, row, col);
            bits = enc_golomb(mode - mode_prev, 1);
            mode_prev = mode;
            bits_McB_Luma = [bits_McB_Luma bits];

            [icp_r,bits] = code_block(icp);
            bits_McB_Luma = [bits_McB_Luma bits];
            Seq_r(row:row+3,col:col+3) = clip(icp_r + pred,2^bw_pixel-1);
            num_op = num_op + 16 + 1;
        elseif (col==1) % Horizontal boundary
            sub_block = McB_Luma(deltaRow:deltaRow+3,deltaCol:deltaCol+3);
            [icp,pred,sae,mode] = mode_select_4_horizontal_boundary(sub_block, Seq_r, row, col);
            bits = enc_golomb(mode - mode_prev, 1);
            mode_prev = mode;
            bits_McB_Luma = [bits_McB_Luma bits];
                
            [icp_r,bits] = code_block(icp);
            bits_McB_Luma = [bits_McB_Luma bits];
            Seq_r(row:row+3,col:col+3) = clip(icp_r + pred,2^bw_pixel-1);
            num_op = num_op + 16 + 1;
        elseif (col == col_start + 12) % McB-level Right Horizontal boundary
            sub_block = McB_Luma(deltaRow:deltaRow+3,deltaCol:deltaCol+3);
            [icp,pred,sae,mode] = mode_select_4_righthorz_boundary(sub_block, Seq_r, row, col);
            bits = enc_golomb(mode - mode_prev, 1);
            mode_prev = mode;
            bits_McB_Luma = [bits_McB_Luma bits];
                
            [icp_r,bits] = code_block(icp);
            bits_McB_Luma = [bits_McB_Luma bits];
            Seq_r(row:row+3,col:col+3) = clip(icp_r + pred,2^bw_pixel-1);
            num_op = num_op + 16 + 1;
        else
            sub_block = McB_Luma(deltaRow:deltaRow+3,deltaCol:deltaCol+3);
            [icp,pred,sae,mode] = mode_select_4(sub_block, Seq_r, row, col);
            bits = enc_golomb(mode - mode_prev, 1);
            mode_prev = mode;
            bits_McB_Luma = [bits_McB_Luma bits];
                    
            [icp_r,bits] = code_block(icp);
            bits_McB_Luma = [bits_McB_Luma bits];
            Seq_r(row:row+3,col:col+3) = clip(icp_r + pred,2^bw_pixel-1);
            num_op = num_op + 16 + 1;
        end
    end
end

mode_last = mode;

end

%--------------------------------------------------------------------------
%% 4x4 Horizontal prediction
function [icp,pred,sae] = pred_horz_4(sub_block,Seq_r,i,j)
global num_op;
pred = Seq_r(i:i+3,j-1)*ones(1,4);
icp = sub_block - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 16 + 16;
end

%--------------------------------------------------------------------------
%% 4x4 Vertical prediction
function [icp,pred,sae] = pred_vert_4(sub_block,Seq_r,i,j)
global num_op;
pred = ones(4,1)*Seq_r(i-1,j:j+3);
icp = sub_block - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 16 + 16;
end

%--------------------------------------------------------------------------
%% 4x4 DC prediction
function [icp,pred,sae] = pred_dc_4(sub_block,Seq_r,i,j)
global bw_pixel;
global num_op;
if (i==1) && (j==1)
    pred = (2^(bw_pixel-1)) * ones(4,4);
elseif (i==1)
    pred = bitshift((sum(Seq_r(i:i+3,j-1)) + 2), -2, 'int64');
elseif (j==1)
    pred = bitshift(sum(Seq_r(i-1,j:j+3)) + 2, -2, 'int64');
else
    pred = bitshift((sum(Seq_r(i-1,j:j+3)) + sum(Seq_r(i:i+3,j-1))+4), -3, 'int64');
end
icp = sub_block - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 10 + 16 + 16;
end

%--------------------------------------------------------------------------
%% 4x4 DDL prediction
function [icp,pred,sae] = pred_ddl_4(sub_block,Seq_r,i,j)
global num_op;
for x = 0:3
    for y = 0:3
        if (x==3)&&(y==3)
	    pred(y+1,x+1) = bitshift((Seq_r(i-1,j+6) + 3*Seq_r(i-1,j+7) + 2), -2, 'int64');
            num_op = num_op + 4;
        else
	    pred(y+1,x+1) = bitshift((Seq_r(i-1,j+x+y) + 2*Seq_r(i-1,j+x+y+1) + Seq_r(i-1,j+x+y+2) + 2), -2, 'int64');
            num_op = num_op + 5;
        end
    end
end

icp = sub_block - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 16 + 16;
end

%--------------------------------------------------------------------------
%% 4x4 DDR prediction
function [icp,pred,sae] = pred_ddr_4(sub_block,Seq_r,i,j)
global num_op;
tmp = Seq_r(i-1,j-1);
if ((rem(i,16) == 1) && (rem(j,16) == 1))
    Seq_r(i-1,j-1) = bitshift(Seq_r(i-1,j) + Seq_r(i,j-1),-1,'int64');end
for x = 0:3
    for y = 0:3
        if (x>y)
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j+x-y-2) + 2*Seq_r(i-1,j+x-y-1) + Seq_r(i-1,j+x-y) + 2), -2, 'int64');
            num_op = num_op + 5;
        elseif (x<y)
            pred(y+1,x+1) = bitshift((Seq_r(i+y-x-2,j-1) + 2*Seq_r(i+y-x-1,j-1) + Seq_r(i+y-x,j-1) + 2), -2, 'int64');
            num_op = num_op + 5;
        else
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j) + 2*Seq_r(i-1,j-1) + Seq_r(i,j-1) + 2), -2, 'int64');
            num_op = num_op + 5;
        end
    end
end
Seq_r(i-1,j-1) = tmp;
icp = sub_block - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 16 + 16;
end

%--------------------------------------------------------------------------
%% 4x4 VR prediction
function [icp,pred,sae] = pred_vr_4(sub_block,Seq_r,i,j)
global num_op;
tmp = Seq_r(i-1,j-1);
if ((rem(i,16) == 1) && (rem(j,16) == 1))
    Seq_r(i-1,j-1) = bitshift(Seq_r(i-1,j) + Seq_r(i,j-1),-1,'int64');end
for x = 0:3
    for y = 0:3
        z = 2*x-y;
        num_op = num_op + 2;
        w = bitshift(y,-1);
        num_op = num_op + 1;
        if (z==0 || z==2 || z==4 || z==6)
            pred(y+1,x+1)= bitshift((Seq_r(i-1,j+x-w-1) + Seq_r(i-1,j+x-w) + 1), -1, 'int64');
            num_op = num_op + 3;
        elseif (z==1 || z==3 || z==5)
    	    pred(y+1,x+1)= bitshift((Seq_r(i-1,j+x-w-2) + 2*Seq_r(i-1,j+x-w-1) + Seq_r(i-1,j+x-w) + 2), -2, 'int64');
            num_op = num_op + 5;
        elseif z==-1
            pred(y+1,x+1)= bitshift((Seq_r(i,j-1)+ 2*Seq_r(i-1,j-1) + Seq_r(i-1,j) + 2), -2, 'int64');
            num_op = num_op + 5;
        else
            pred(y+1,x+1) = bitshift((Seq_r(i-1+y,j-1)+ 2*Seq_r(i+y-2,j-1) + Seq_r(i+y-3,j-1) + 2), -2, 'int64');
            num_op = num_op + 5;
        end
    end
end
Seq_r(i-1,j-1) = tmp;
icp = sub_block - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 16 + 16;
end

%--------------------------------------------------------------------------
%% 4x4 HD prediction
function [icp,pred,sae] = pred_hd_4(sub_block,Seq_r,i,j)
global num_op;
tmp = Seq_r(i-1,j-1);
if ((rem(i,16) == 1) && (rem(j,16) == 1))
    Seq_r(i-1,j-1) = bitshift(Seq_r(i-1,j) + Seq_r(i,j-1),-1,'int64');
end
for x = 0:3
    for y = 0:3
        z = 2*y-x;
        w = bitshift(x,-1);
        num_op = num_op + 3;
        if (z==0 || z==2 || z==4 || z==6)
            pred(y+1,x+1)= bitshift((Seq_r(i+y-w-1,j-1) + Seq_r(i+y-w,j-1) + 1), -1, 'int64');
            num_op = num_op + 3;
        elseif (z==1 || z==3 || z==5)
            pred(y+1,x+1)= bitshift((Seq_r(i+y-w-2,j-1) + 2*Seq_r(i+y-w-1,j-1) + Seq_r(i+y-w,j-1) + 2), -2, 'int64');
            num_op = num_op + 5;
        elseif z==-1
            pred(y+1,x+1)= bitshift((Seq_r(i-1,j)+ 2*Seq_r(i-1,j-1) + Seq_r(i,j-1) + 2), -2, 'int64');
            num_op = num_op + 5;
        else
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j+x-1)+ 2*Seq_r(i-1,j+x-2) + Seq_r(i-1,j+x-3) + 2), -2, 'int64');
            num_op = num_op + 5;
        end
    end
end
Seq_r(i-1,j-1) = tmp;
icp = sub_block - pred;
%satd = satd_func(icp);
sae = sum(sum(abs(icp)));
num_op = num_op + 16 + 16;
end

%--------------------------------------------------------------------------
%% 4x4 VL prediction
function [icp,pred,sae] = pred_vl_4(sub_block,Seq_r,i,j)
global num_op;

for x = 0:3
    for y = 0:3
        w = bitshift(y,-1);
        num_op = num_op + 1;
        if rem(y,2)==0
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j+x+w) + Seq_r(i-1,j+x+w+1) + 1),-1,'int64');
            num_op = num_op + 3;
        else
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j+x+w) + 2*Seq_r(i-1,j+x+w+1) + Seq_r(i-1,j+x+w+2) + 2),-2,'int64');
            num_op = num_op + 5;
        end
    end
end

icp = sub_block - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 16 + 16;
end

%--------------------------------------------------------------------------
%% 4x4 HU prediction
function [icp,pred,sae] = pred_hu_4(sub_block,Seq_r,i,j)
global num_op;
for x = 0:3
    for y = 0:3
        z = 2*y+x;
        num_op = num_op + 2;
        w = bitshift(x,-1);
        num_op = num_op + 1;
        if (z==0)||(z==2)||(z==4)
            pred(y+1,x+1)= bitshift((Seq_r(i+y+w,j-1) + Seq_r(i+y+w+1,j-1) + 1), -1, 'int64');
            num_op = num_op + 3;
        elseif (z==1)||(z==3)
            pred(y+1,x+1)= bitshift((Seq_r(i+y+w,j-1) + 2*Seq_r(i+y+w+1,j-1) + Seq_r(i+y+w+2,j-1) + 2), -2, 'int64');
            num_op = num_op + 5;
        elseif z==5
            pred(y+1,x+1)= bitshift((Seq_r(i+2,j-1)+ 3*Seq_r(i+3,j-1) + 2), -2, 'int64');
            num_op = num_op + 4;
        else
            pred(y+1,x+1) = Seq_r(i+3,j-1);
        end
    end
end

icp = sub_block - pred;
sae = sum(sum(abs(icp)));
num_op = num_op + 16 + 16;
end

%--------------------------------------------------------------------------
%% Mode selection for 4*4 first vertical boundary predicition
function [icp,pred,sae,mode] = mode_select_4_vertical_boundary(sub_block,Seq_r,i,j)
global num_op;
[icp2,pred2,sae2] = pred_horz_4(sub_block,Seq_r,i,j);
[icp9,pred9,sae9] = pred_hu_4(sub_block,Seq_r,i,j);
[icp3,pred3,sae3] = pred_dc_4(sub_block,Seq_r,i,j);

[sae,idx]=min([sae2 sae3 sae9]);
num_op = num_op +2;
switch idx
    case 1
        icp = icp2;
        pred = pred2; 
        mode = 1;
    case 2
        icp = icp3;
        pred = pred3;
        mode = 2;
    case 3
        icp = icp9;
        pred = pred9; 
        mode = 8;
end

end

%--------------------------------------------------------------------------
%% Mode selection for 4*4 first horizontal boundary predicition
function [icp,pred,sae,mode] = mode_select_4_horizontal_boundary(sub_block,Seq_r,i,j)
global num_op;
[icp1,pred1,sae1] = pred_vert_4(sub_block,Seq_r,i,j);
[icp3,pred3,sae3] = pred_dc_4(sub_block,Seq_r,i,j);

[icp4,pred4,sae4] = pred_ddl_4(sub_block,Seq_r,i,j);
[icp8,pred8,sae8] = pred_vl_4(sub_block,Seq_r,i,j);

[sae,idx]=min([sae1 sae3 sae4 sae8]);
num_op = num_op +3;
switch idx
    case 1
        icp = icp1;
        pred = pred1; 
        mode = 0;
    case 2
        icp = icp3;
        pred = pred3; 
        mode = 2;
    case 3
        icp = icp4;
        pred = pred4; 
        mode = 3;
    case 4
        icp = icp8;
        pred = pred8;
        mode = 7;
end

end

%--------------------------------------------------------------------------
%% Mode selection for 4*4 right horizontal boundary predicition
function [icp,pred,sae,mode] = mode_select_4_righthorz_boundary(sub_block,Seq_r,i,j)
global num_op;
[icp1,pred1,sae1] = pred_vert_4(sub_block,Seq_r,i,j);
[icp2,pred2,sae2] = pred_horz_4(sub_block,Seq_r,i,j);
[icp3,pred3,sae3] = pred_dc_4(sub_block,Seq_r,i,j);
[icp5,pred5,sae5] = pred_ddr_4(sub_block,Seq_r,i,j);
[icp6,pred6,sae6] = pred_vr_4(sub_block,Seq_r,i,j);
[icp7,pred7,sae7] = pred_hd_4(sub_block,Seq_r,i,j);
[icp9,pred9,sae9] = pred_hu_4(sub_block,Seq_r,i,j);

[sae,idx]=min([sae1 sae2 sae3 sae5 sae6 sae7 sae9]);
num_op = num_op + 6;
switch idx
    case 1
        icp = icp1;
        pred = pred1; 
        mode = 0;
    case 2
        icp = icp2;
        pred = pred2;
        mode = 1;
    case 3
        icp = icp3;
        pred = pred3;
        mode = 2;
    case 4
        icp = icp5;
        pred = pred5; 
        mode = 4;
    case 5
        icp = icp6;
        pred = pred6; 
        mode = 5;
    case 6
        icp = icp7;
        pred = pred7; 
        mode = 6;
    case 7
        icp = icp9;
        pred = pred9; 
        mode = 8;
end

end

%--------------------------------------------------------------------------
%% Mode selection for 4x4 predicition
function [icp,pred,sae,mode] = mode_select_4(sub_block,Seq_r,i,j)
global num_op;
[icp1,pred1,sae1] = pred_vert_4(sub_block,Seq_r,i,j);
[icp2,pred2,sae2] = pred_horz_4(sub_block,Seq_r,i,j);
[icp3,pred3,sae3] = pred_dc_4(sub_block,Seq_r,i,j);
[icp4,pred4,sae4] = pred_ddl_4(sub_block,Seq_r,i,j);
[icp5,pred5,sae5] = pred_ddr_4(sub_block,Seq_r,i,j);
[icp6,pred6,sae6] = pred_vr_4(sub_block,Seq_r,i,j);
[icp7,pred7,sae7] = pred_hd_4(sub_block,Seq_r,i,j);
[icp8,pred8,sae8] = pred_vl_4(sub_block,Seq_r,i,j);
[icp9,pred9,sae9] = pred_hu_4(sub_block,Seq_r,i,j);

[sae,idx]=min([sae1 sae2 sae3 sae4 sae5 sae6 sae7 sae8 sae9]);
num_op = num_op +8;
switch idx
    case 1
        icp = icp1;
        pred = pred1; 
        mode = 0;
    case 2
        icp = icp2;
        pred = pred2;
        mode = 1;
    case 3
        icp = icp3;
        pred = pred3;
        mode = 2;
    case 4
        icp = icp4;
        pred = pred4; 
        mode = 3;
    case 5
        icp = icp5;
        pred = pred5; 
        mode = 4;
    case 6
        icp = icp6;
        pred = pred6; 
        mode = 5;
    case 7
        icp = icp7;
        pred = pred7; 
        mode = 6;
    case 8
        icp = icp8;
        pred = pred8; 
        mode = 7;
    case 9
        icp = icp9;
        pred = pred9; 
        mode = 8;
end

end

%--------------------------------------------------------
%********************************************************
%% Transform, Quantization, Entropy coding
%********************************************************
% transform = Integer transform
% Quantization = h.264 
% VLC = CAVLC (H.264)
function [err_r,bits_mb] = code_block(err)
global num_op;
global QP;

[n,m] = size(err);

bits_mb = '';

for i = 1:4:n
    for j = 1:4:m
        c(i:i+3,j:j+3) = integer_transform(err(i:i+3,j:j+3));
        cq(i:i+3,j:j+3) = quantization(c(i:i+3,j:j+3),QP);
        [bits_b] = enc_cavlc(cq(i:i+3,j:j+3), 0, 0);       
        bits_mb = [bits_mb bits_b];       
        Wi = inv_quantization(cq(i:i+3,j:j+3),QP);
        Y = inv_integer_transform(Wi);        
        err_r(i:i+3,j:j+3) = bitshift(Y,-6,'int64');
        num_op = num_op + 16;
    end
end
end

