function [Seq_r_Luma,Seq_r_ChB,Seq_r_ChR,idx] = Dec_Frame(idx,bitstream, Rec_Y_ref, Rec_U_ref, Rec_V_ref,CD_map)

%global QP;
[h,w,~] = size(Rec_Y_ref);
%--------------------------------------------------
% initialize
bs = 16;
mode_prev_Luma = 0;
mode_prev_ChromaB = 9;
mode_prev_ChromaR = 9;

Seq_r_Luma = Rec_Y_ref;
Seq_r_ChB = Rec_U_ref;
Seq_r_ChR = Rec_V_ref;
for i = 1:bs:h
    for j = 1:bs:w
        if (CD_map(floor(i/16)+1,floor(j/16)+1) == 1)
            for m = i:4:i+15
                for n = j:4:j+15
                    [mode_diff,idx]= dec_golomb(idx,bitstream,1);
                    mode = mode_prev_Luma + mode_diff;
                    [Seq_r_Luma(m:m+3,n:n+3),idx] = dec_mb_4(idx,bitstream,mode,Seq_r_Luma,m,n);
                    mode_prev_Luma = mode;
                end
            end
            i_ch = (i-1)/2 + 1;
            j_ch = (j-1)/2 + 1;
            %ChromaB
            [mode_diff,idx]= dec_golomb(idx,bitstream,1);
            mode = mode_prev_ChromaB + mode_diff;
            [Seq_r_ChB(i_ch:i_ch+7,j_ch:j_ch+7),idx] = dec_mb_8(idx,bitstream,mode,Seq_r_ChB,i_ch,j_ch);
            mode_prev_ChromaB = mode;
            %ChromaC
            [mode_diff,idx]= dec_golomb(idx,bitstream,1);
            mode = mode_prev_ChromaR + mode_diff;
            [Seq_r_ChR(i_ch:i_ch+7,j_ch:j_ch+7),idx] = dec_mb_8(idx,bitstream,mode,Seq_r_ChR,i_ch,j_ch);
            mode_prev_ChromaR = mode;
        end
    end
end

end
%-----------------------------------------------------------------
function [Xi,k] = dec_mb_4(k,bits,mode,Seq_r_Luma,i,j)
pred = find_pred_4(mode,Seq_r_Luma,i,j);
[icp,k] = code_block_4(k,bits);
Xi = pred + icp;
end

%----------------------------------------------------------------
function [icp,k] = code_block_4(k,bits)
global QP
[Z1,m] = dec_cavlc(bits(k:length(bits)),0,0);
Wi = inv_quantization(Z1,QP);
Y = inv_integer_transform(Wi);
X = bitshift(Y,-6,'int64');
icp = X;
k = k + m - 1;
end

%----------------------------------------------------------------
function [pred] = find_pred_4(mode,Seq_r_Luma,i,j)
if (mode==0)
    [pred] = pred_vert_4(Seq_r_Luma,i,j);
elseif (mode==1)
    [pred] = pred_horz_4(Seq_r_Luma,i,j);
elseif (mode==2)
    [pred] = pred_dc_4(Seq_r_Luma,i,j);
elseif (mode==3)
    [pred] = pred_ddl_4(Seq_r_Luma,i,j);
elseif (mode==4)
    [pred] = pred_ddr_4(Seq_r_Luma,i,j);
elseif (mode==5)
    [pred] = pred_vr_4(Seq_r_Luma,i,j);
elseif (mode==6)
    [pred] = pred_hd_4(Seq_r_Luma,i,j);
elseif (mode==7)
    [pred] = pred_vl_4(Seq_r_Luma,i,j);
elseif (mode==8)
    [pred] = pred_hu_4(Seq_r_Luma,i,j);
end

end

%--------------------------------------------------------
%% 4x4 Horizontal prediciton
function [pred] = pred_horz_4(Seq_r,i,j)

pred = Seq_r(i:i+3,j-1)*ones(1,4);

end
%-------------------------------------------------------
%% 4x4 Vertical Prediciton
function [pred] = pred_vert_4(Seq_r,i,j)

pred = ones(4,1)*Seq_r(i-1,j:j+3);

end
%-------------------------------------------------------
%% 4x4 DC prediction
function [pred] = pred_dc_4(Seq_r,i,j)
    global bw_pixel;
    if (i==1) && (j==1)
        pred = (2^(bw_pixel-1)) * ones(4,4);
    elseif (i==1)
        pred = bitshift((sum(Seq_r(i:i+3,j-1)) + 2), -2, 'int64');
    elseif (j==1)
        pred = bitshift(sum(Seq_r(i-1,j:j+3)) + 2, -2, 'int64');
    else
        pred = bitshift((sum(Seq_r(i-1,j:j+3))+ sum(Seq_r(i:i+3,j-1))+4), -3, 'int64');
    end
end
%--------------------------------------------------------
function [pred] = pred_ddl_4(Seq_r,i,j)
for x = 0:3
    for y = 0:3
        if (x==3)&&(y==3)
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j+6) + 3*Seq_r(i-1,j+7) + 2), -2, 'int64');
        else
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j+x+y) + 2*Seq_r(i-1,j+x+y+1) + Seq_r(i-1,j+x+y+2) + 2), -2, 'int64');
        end
    end
end
end
%--------------------------------------------------------
function [pred] = pred_ddr_4(Seq_r,i,j)
tmp = Seq_r(i-1,j-1);
if ((rem(i,16) == 1) && (rem(j,16) == 1))
    Seq_r(i-1,j-1) = bitshift(Seq_r(i-1,j) + Seq_r(i,j-1),-1,'int64');
end
for x = 0:3
    for y = 0:3
        if (x>y)
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j+x-y-2) + 2*Seq_r(i-1,j+x-y-1) + Seq_r(i-1,j+x-y) + 2), -2, 'int64');
        elseif (x<y)
            pred(y+1,x+1) = bitshift((Seq_r(i+y-x-2,j-1) + 2*Seq_r(i+y-x-1,j-1) + Seq_r(i+y-x,j-1) + 2), -2, 'int64');
        else
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j) + 2*Seq_r(i-1,j-1) + Seq_r(i,j-1) + 2), -2, 'int64');
        end
    end
end
Seq_r(i-1,j-1) = tmp;
end
%--------------------------------------------------------
function [pred] = pred_vr_4(Seq_r,i,j)
tmp = Seq_r(i-1,j-1);
if ((rem(i,16) == 1) && (rem(j,16) == 1))
    Seq_r(i-1,j-1) = bitshift(Seq_r(i-1,j) + Seq_r(i,j-1),-1,'int64');
end
for x = 0:3
    for y = 0:3
        z = 2*x-y;
        w = bitshift(y,-1);
        if (z==0 || z==2 || z==4 || z==6)
            pred(y+1,x+1)= bitshift((Seq_r(i-1,j+x-w-1) + Seq_r(i-1,j+x-w) + 1), -1, 'int64');
        elseif (z==1 || z==3 || z==5)
            pred(y+1,x+1)= bitshift((Seq_r(i-1,j+x-w-2) + 2*Seq_r(i-1,j+x-w-1) + Seq_r(i-1,j+x-w) + 2), -2, 'int64');
        elseif z==-1
            pred(y+1,x+1)= bitshift((Seq_r(i,j-1)+ 2*Seq_r(i-1,j-1) + Seq_r(i-1,j) + 2), -2, 'int64');
        else
            pred(y+1,x+1) = bitshift((Seq_r(i-1+y,j-1)+ 2*Seq_r(i+y-2,j-1) + Seq_r(i+y-3,j-1) + 2), -2, 'int64');
        end
    end
end
Seq_r(i-1,j-1) = tmp;
end
%--------------------------------------------------------
function [pred] = pred_hd_4(Seq_r,i,j)
tmp = Seq_r(i-1,j-1);
if ((rem(i,16) == 1) && (rem(j,16) == 1))
    Seq_r(i-1,j-1) = bitshift(Seq_r(i-1,j) + Seq_r(i,j-1),-1,'int64');
end
for x = 0:3
    for y = 0:3
        z = 2*y-x;
        w = bitshift(x,-1);
        if (z==0 || z==2 || z==4 || z==6)
            pred(y+1,x+1)= bitshift((Seq_r(i+y-w-1,j-1) + Seq_r(i+y-w,j-1) + 1), -1, 'int64');
        elseif (z==1 || z==3 || z==5)
            pred(y+1,x+1)= bitshift((Seq_r(i+y-w-2,j-1) + 2*Seq_r(i+y-w-1,j-1) + Seq_r(i+y-w,j-1) + 2), -2, 'int64');
        elseif z==-1
            pred(y+1,x+1)= bitshift((Seq_r(i-1,j)+ 2*Seq_r(i-1,j-1) + Seq_r(i,j-1) + 2), -2, 'int64');
        else
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j+x-1)+ 2*Seq_r(i-1,j+x-2) + Seq_r(i-1,j+x-3) + 2), -2, 'int64');
        end
    end
end
Seq_r(i-1,j-1) = tmp;
end
%--------------------------------------------------------
function [pred] = pred_vl_4(Seq_r,i,j)

for x = 0:3
    for y = 0:3
        w = bitshift(y,-1);
        if rem(y,2)==0
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j+x+w) + Seq_r(i-1,j+x+w+1) + 1),-1,'int64');
        else
            pred(y+1,x+1) = bitshift((Seq_r(i-1,j+x+w) + 2*Seq_r(i-1,j+x+w+1) + Seq_r(i-1,j+x+w+2) + 2),-2,'int64');
        end
    end
end

end
%--------------------------------------------------------
function [pred] = pred_hu_4(Seq_r,i,j)
for x = 0:3
    for y = 0:3
        z = 2*y+x;
        w = bitshift(x,-1);
        if (z==0)||(z==2)||(z==4)
            pred(y+1,x+1)= bitshift((Seq_r(i+y+w,j-1) + Seq_r(i+y+w+1,j-1) + 1), -1, 'int64');
        elseif (z==1)||(z==3)
            pred(y+1,x+1)= bitshift((Seq_r(i+y+w,j-1) + 2*Seq_r(i+y+w+1,j-1) + Seq_r(i+y+w+2,j-1) + 2), -2, 'int64');
        elseif z==5
            pred(y+1,x+1)= bitshift((Seq_r(i+2,j-1)+ 3*Seq_r(i+3,j-1) + 2), -2, 'int64');
        else
            pred(y+1,x+1) = Seq_r(i+3,j-1);
        end
    end
end

end

%% Chroma
%-----------------------------------------------------------------
function [Xi,k] = dec_mb_8(k,bits,mode,Seq_r_Luma,i,j)

pred = find_pred_8(mode,Seq_r_Luma,i,j);
[icp,k] = code_block_8(k,bits);
Xi = pred + icp;

end
%----------------------------------------------------------------
function [pred] = find_pred_8(mode,Seq_r_Luma,i,j)

if (mode==9)
    [pred] = pred_vert_8(Seq_r_Luma,i,j);
elseif (mode==10)
    [pred] = pred_horz_8(Seq_r_Luma,i,j);
elseif (mode==11)
    [pred] = pred_dc_8(Seq_r_Luma,i,j);
elseif (mode==12)
    [pred] = pred_plane_8(Seq_r_Luma,i,j);
end

end 
%-------------------------------------------------------
%% 8x8 Vertical prediciton
function [pred] = pred_vert_8(Seq_r,i,j)

pred = ones(8,1)*Seq_r(i-1,j:j+7);
end
%-------------------------------------------------------
%% 8x8 Vertical Prediciton
function [pred] = pred_horz_8(Seq_r,i,j)

pred = Seq_r(i:i+7,j-1)*ones(1,8);
end
%-------------------------------------------------------
%% 8x8 DC prediction
function [pred] = pred_dc_8(Seq_r,i,j)
global bw_pixel;
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
end
%------------------------------------------------------
%% 8x8 Plane prediction
function [pred] = pred_plane_8(Seq_r,i,j)
global bw_pixel;
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

for m = 1:8
    for n = 1:8
        d = bitshift(a + b*(m-4)+ c*(n-4) + 16,-5,'int64');
        if d <0
            pred(m,n) = 0;
        elseif d>(2^bw_pixel-1)
            pred(m,n) = (2^bw_pixel-1);
        else
            pred(m,n) = d;
        end
    end
end
end
%-----------------------------------------------------------
function [icp,k] = code_block_8(k,bits)

global QP;

for i=1:4:8
    for j=1:4:8
        [Z1(i:i+3,j:j+3,1),m] = dec_cavlc(bits(k:length(bits)),0,0);
	DCq(round(i/4)+1,round(j/4)+1) = Z1(i,j);
        k = k + m - 1;
    end
end

DCi = inv_DC_chroma_quantization(DCq,QP);
chi = inv_DC_chroma_transform(DCi);

for i = 1:4:8
    for j = 1:4:8
        Wi = inv_quantization(Z1(i:i+3,j:j+3),QP);
        Wi(1,1) = chi(round(i/4)+1,round(j/4)+1);
        Y = inv_integer_transform(Wi);
        X = bitshift(Y,-6,'int64');
        icp(i:i+3,j:j+3,1) = X;
    end
end

end
