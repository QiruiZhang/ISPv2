% take the JPEG decompressed reference frame as reference (same as when encoding)
function [Seq_r_Luma,Seq_r_ChB,Seq_r_ChR,idx, dbg_buf] = Dec_Frame2(idx,bitstream, ref_frame, CD_map)
global bw_pixel;
%global QP;
[h,w,~] = size(ref_frame);
%--------------------------------------------------
% initialize
bs = 16;
mode_prev_Luma = 0;
mode_prev_ChromaB = 9;
mode_prev_ChromaR = 9;


%Convert ref_frame to YUV
Iyuv_ref  = rgb2ycbcr(ref_frame);
Iyuv_ref = double(Iyuv_ref);
Iy_ref = Iyuv_ref(:,:,1);
Iu_ref = Iyuv_ref(:,:,2);
Iv_ref = Iyuv_ref(:,:,3);

%subsample as 4:2:0 and extend to 12-bit pixel
Y_ref = Iy_ref(:,:) * 2^(bw_pixel-8);
U_ref = Iu_ref(1:2:h,1:2:w) * 2^(bw_pixel-8);
V_ref = Iv_ref(1:2:h,1:2:w) * 2^(bw_pixel-8);

Seq_r_Luma = Y_ref;
Seq_r_ChB = U_ref;
Seq_r_ChR = V_ref;

err_flag = 0;
err_flagC = 0;
temp_err_flagR = 0;
temp_err_flagB = 0;
errcnt = 0;

num_stack = 1200+1;
mode_prev_Luma_lastmcb = zeros(num_stack,1);
mcb_ss_idx = zeros(num_stack,1);        mcb_ss_idx(1)=idx;
mode_prev_ChromaR = zeros(num_stack,1); mode_prev_ChromaR(1)=9;
mode_prev_ChromaB = zeros(num_stack,1); mode_prev_ChromaB(1)=9;
errcnt = zeros(num_stack,1);

dbg_buf = zeros(30*40,25);

%for i = 1:bs:h
mcb_idx = 0;
while(1)
    if(mcb_idx >= h*w/(bs*bs))
        break;
    end
    i = floor(mcb_idx/(w/bs));
    j = mcb_idx - i*(w/bs);
    i = i*16+1;
    j = j*16+1;
    cur_mcb_idx = mcb_idx+1;
    fprintf("\n cur_mcb_idx="+ num2str(cur_mcb_idx)+"\n");
    fprintf("i, j = "+ num2str(i)+", "+num2str(j)+"\n");
    if (CD_map(floor(i/16)+1,floor(j/16)+1) == 1)
        while(1)
            idx = mcb_ss_idx(cur_mcb_idx);
            fprintf("McB row is " + num2str(floor(i/16)+1) + "\n");
            fprintf("McB col is " + num2str(floor(j/16)+1) + "\n");
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %if( (floor(i/16)+1) == 12 &&  (floor(j/16)+1) == 23)
            %    fprintf("DBG point :: "+ "\n");
            %      mcb_ss_idx(cur_mcb_idx) = mcb_ss_idx(cur_mcb_idx) + 1;
            %      idx = mcb_ss_idx(cur_mcb_idx);
            %end
            %
            %if( (floor(i/16)+1) == 2&&  (floor(j/16)+1) == 20)
            %    fprintf("DBG point :: "+ "\n");
            %end
            %if( (floor(i/16)+1) == 12&&  (floor(j/16)+1) == 23)
            %    fprintf("DBG point :: "+ "\n");
            %end
            %% debug buffer
            %temp = dbg_buf((floor(i/16))*40+(floor(j/16)+1), :);
            %temp = update_stack(temp, idx, 1, 25);
            %dbg_buf((floor(i/16))*40+(floor(j/16)+1), :) = temp;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            for m = i:4:i+15
                for n = j:4:j+15
                    fprintf("idx before dec_golomb: " + num2str(idx) + "\n");
                    [mode_diff, idx]= dec_golomb(idx,bitstream,1);
                    fprintf("idx after dec_golomb: " + num2str(idx) + "\n");
                    fprintf("mode_diff is " + num2str(mode_diff) + "\n");
                    mode = mode_prev_Luma + mode_diff;
                    fprintf("mode is " + num2str(mode) + "\n");
                    [Seq_r_Luma(m:m+3,n:n+3), idx, err_flag] = dec_mb_4(idx,bitstream,mode,Seq_r_Luma,m,n);
                    if( err_flag == 1 )
                        % error happening in the middle of Luma decoding
                        errcnt(cur_mcb_idx) = errcnt(cur_mcb_idx) + 1;
                        fprintf("Error("+errcnt(cur_mcb_idx)+"): mode="+num2str(mode)+", m="+num2str(m)+", n="+num2str(n)+"\n");
                        break;
                    else
                        mode_prev_Luma = mode;
                    end
                end
                if (err_flag == 1)
                    % error happening in the middle of Luma decoding
                    break;
                end
            end
            if (err_flag == 1)
                if(errcnt(cur_mcb_idx) == 1)
                    % single error : start from this mcb again
                    mcb_ss_idx(cur_mcb_idx) = mcb_ss_idx(cur_mcb_idx) + 1;
                    mode_prev_Luma = mode_prev_Luma_lastmcb(cur_mcb_idx);
                    fprintf("Retry!\n")
                    continue; % need a chance to correct
                else
                    % error more than 2 : start from previous mcb
                    break;
                end
            else
                % No error;
                break;
            end
        end
        if(err_flag ~= 1)
            i_ch = (i-1)/2 + 1;
            j_ch = (j-1)/2 + 1;
            %ChromaB
            [mode_diff,idx]= dec_golomb(idx,bitstream,1);
            modeB = mode_prev_ChromaB(cur_mcb_idx) + mode_diff;
            [Seq_r_ChB(i_ch:i_ch+7,j_ch:j_ch+7),idx,temp_err_flagB] = dec_mb_8(idx,bitstream,modeB,Seq_r_ChB,i_ch,j_ch);
            %ChromaC
            [mode_diff,idx]= dec_golomb(idx,bitstream,1);
            modeR = mode_prev_ChromaR(cur_mcb_idx) + mode_diff;
            [Seq_r_ChR(i_ch:i_ch+7,j_ch:j_ch+7),idx,temp_err_flagR] = dec_mb_8(idx,bitstream,modeR,Seq_r_ChR,i_ch,j_ch);
            
            err_flagC = (temp_err_flagR == 1) || (temp_err_flagB == 1);
            if( err_flagC == 1)
                % error happening in the middle of Chroma decoding
                errcnt(cur_mcb_idx) = errcnt(cur_mcb_idx) + 1;
                fprintf("Chroma Error("+errcnt(cur_mcb_idx)+"): modeB="+num2str(modeB)+"modeR="+num2str(modeR)+", m="+num2str(m)+", n="+num2str(n)+"\n");
            else
                % no error
                mode_prev_ChromaB(cur_mcb_idx+1) = modeB;
                mode_prev_ChromaR(cur_mcb_idx+1) = modeR;
                mode_prev_Luma_lastmcb(cur_mcb_idx+1) = mode_prev_Luma;
                mcb_ss_idx(cur_mcb_idx+1) = idx;
            end
        else
            fprintf("Error count over(err_flag==1): go back to the previous MCB\n");
        end
    end
    if(err_flag ~= 1 && err_flagC ~= 1)
        % no error case : next mcb
        mcb_idx = mcb_idx + 1;
    elseif (err_flag ~= 1 && err_flagC == 1 && errcnt(cur_mcb_idx) == 1)
        % single error in Chroma : this mcb again
        mcb_ss_idx(cur_mcb_idx) = mcb_ss_idx(cur_mcb_idx) + 1;
        mode_prev_Luma = mode_prev_Luma_lastmcb(cur_mcb_idx);
    else
        % double error cases : previous mcb
        togo_mcb_idx=cur_mcb_idx;
        for i=1:1:num_stack
            errcnt(togo_mcb_idx) = 0;
            mcb_idx = mcb_idx - 1;
            togo_mcb_idx = mcb_idx + 1;
            if(errcnt(togo_mcb_idx) == 0)
                break;
            end
        end
        mcb_ss_idx(togo_mcb_idx) = mcb_ss_idx(togo_mcb_idx) + 1;
        errcnt(togo_mcb_idx) = errcnt(togo_mcb_idx) + 1;
        mode_prev_Luma = mode_prev_Luma_lastmcb(togo_mcb_idx);
    end
end

end


%-----------------------------------------------------------------
function [updated_stack] = update_stack(stack, value, fwd, stack_size)
updated_stack = zeros(stack_size,1);
if(fwd == 1)
    updated_stack(1) = value;
    for i=2:1:stack_size
        updated_stack(i) = stack(i-1);
    end
else
    for i=1:1:stack_size-1
        updated_stack(i) = stack(i+1);
    end
end
end

%-----------------------------------------------------------------
function [Xi,k,err] = dec_mb_4(k,bits,mode,Seq_r_Luma,i,j)
[pred,err] = find_pred_4(mode,Seq_r_Luma,i,j);
%%%%err%%%%%%%%%
if (err == 1)
    Xi=1;k=1; return;
end
[icp,k,err] = code_block_4(k,bits);
if( k > length(bits))
    err=1;Xi=1;k=1; return;
end
Xi = pred + icp;
end

%----------------------------------------------------------------
function [icp,k,err] = code_block_4(k,bits)
global QP
[Z1,m,err] = dec_cavlc(bits(k:length(bits)),0,0);
Wi = inv_quantization(Z1,QP);
Y = inv_integer_transform(Wi);
X = bitshift(Y,-6,'int64');
icp = X;
k = k + m - 1;
end

%----------------------------------------------------------------
function [pred,err] = find_pred_4(mode,Seq_r_Luma,i,j)
err =0;
if (mode==0)
    [pred,err] = pred_vert_4(Seq_r_Luma,i,j);
elseif (mode==1)
    [pred,err] = pred_horz_4(Seq_r_Luma,i,j);
elseif (mode==2)
    [pred,err] = pred_dc_4(Seq_r_Luma,i,j);
elseif (mode==3)
    [pred,err] = pred_ddl_4(Seq_r_Luma,i,j);
elseif (mode==4)
    [pred,err] = pred_ddr_4(Seq_r_Luma,i,j);
elseif (mode==5)
    [pred,err] = pred_vr_4(Seq_r_Luma,i,j);
elseif (mode==6)
    [pred,err] = pred_hd_4(Seq_r_Luma,i,j);
elseif (mode==7)
    [pred,err] = pred_vl_4(Seq_r_Luma,i,j);
elseif (mode==8)
    [pred,err] = pred_hu_4(Seq_r_Luma,i,j);
elseif (mode > 8 || mode < 0)
    pred = zeros(4,4);
    err = 1;
end

end

function err = outofind(idx_range, min_1, max_1, min_2, max_2)
if(min_1<1 || min_2<1 || max_1>idx_range(1) || max_2>idx_range(2))
    err = 1;
else
    err = 0;
end
end
%--------------------------------------------------------
%% 4x4 Horizontal prediciton
function [pred,err] = pred_horz_4(Seq_r,i,j)
err = 0;
if( outofind(size(Seq_r), i, i+3, j-1, j-1) == 1 )
    err = 1; pred = zeros(4,4); return
end
pred = Seq_r(i:i+3,j-1)*ones(1,4);
end
%-------------------------------------------------------
%% 4x4 Vertical Prediciton
function [pred,err] = pred_vert_4(Seq_r,i,j)
err = 0;
if( outofind(size(Seq_r), i-1, i-1, j, j+3) == 1 )
    err = 1; pred = zeros(4,4); return
end
pred = ones(4,1)*Seq_r(i-1,j:j+3);
end
%-------------------------------------------------------
%% 4x4 DC prediction
function [pred,err] = pred_dc_4(Seq_r,i,j)
err = 0;
idx_range = size(Seq_r);
global bw_pixel;
if (i==1) && (j==1)
    pred = (2^(bw_pixel-1)) * ones(4,4);
elseif (i==1)
    if( outofind(size(Seq_r), i, i+3, j-1, j-1) == 1 )
        err = 1; pred = zeros(4,4); return
    end
    pred = bitshift((sum(Seq_r(i:i+3,j-1)) + 2), -2, 'int64');
elseif (j==1)
    if( outofind(size(Seq_r), i-1, i-1, j, j+3) == 1 )
        err = 1; pred = zeros(4,4); return
    end
    pred = bitshift(sum(Seq_r(i-1,j:j+3)) + 2, -2, 'int64');
else
    if( outofind(size(Seq_r), i-1, i+3, j-1, j+3) == 1 )
        err = 1; pred = zeros(4,4); return
    end
    pred = bitshift((sum(Seq_r(i-1,j:j+3))+ sum(Seq_r(i:i+3,j-1))+4), -3, 'int64');
end
end
%--------------------------------------------------------
function [pred,err] = pred_ddl_4(Seq_r,i,j)
err = 0;
idx_range = size(Seq_r);
for x = 0:3
    for y = 0:3
        if (x==3)&&(y==3)
            if( outofind(size(Seq_r), i-1, i-1, j+6, j+7) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp = (Seq_r(i-1,j+6) + 3*Seq_r(i-1,j+7) + 2);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1) = bitshift(temp, -2, 'int64');
        else
            if( outofind(size(Seq_r), i-1, i-1, j+x+y, j+x+y+2) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp = (Seq_r(i-1,j+x+y) + 2*Seq_r(i-1,j+x+y+1) + Seq_r(i-1,j+x+y+2) + 2);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1) = bitshift(temp, -2, 'int64');
        end
    end
end
end
%--------------------------------------------------------
function [pred,err] = pred_ddr_4(Seq_r,i,j)
err = 0;
idx_range = size(Seq_r);

if(i-1<1 || j-1<1)
    err = 1;
    pred = zeros(4,4);
    return
end
tmp = Seq_r(i-1,j-1);
if ((rem(i,16) == 1) && (rem(j,16) == 1))
    Seq_r(i-1,j-1) = bitshift(Seq_r(i-1,j) + Seq_r(i,j-1),-1,'int64');
end
for x = 0:3
    for y = 0:3
        if (x>y)
            if( outofind(size(Seq_r), i-1, i-1, j+x-y-2, j+x-y) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i-1,j+x-y-2) + 2*Seq_r(i-1,j+x-y-1) + Seq_r(i-1,j+x-y) + 2);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1) = bitshift(temp, -2, 'int64');
        elseif (x<y)
            if( outofind(size(Seq_r), i+y-x-2, i+y-x, j-1, j-1) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i+y-x-2,j-1) + 2*Seq_r(i+y-x-1,j-1) + Seq_r(i+y-x,j-1) + 2);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1) = bitshift(temp, -2, 'int64');
        else
            if( outofind(size(Seq_r), i-1, i, j-1, j) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i-1,j) + 2*Seq_r(i-1,j-1) + Seq_r(i,j-1) + 2);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1) = bitshift(temp, -2, 'int64');
        end
    end
end
Seq_r(i-1,j-1) = tmp;
end
%--------------------------------------------------------
function [pred,err] = pred_vr_4(Seq_r,i,j)
err = 0;
if(i-1<1 || j-1<1)
    err = 1;
    pred = zeros(4,4);
    return
end
tmp = Seq_r(i-1,j-1);
if ((rem(i,16) == 1) && (rem(j,16) == 1))
    temp=Seq_r(i-1,j) + Seq_r(i,j-1);
    if(floor(temp) ~= temp)
        err = 1;
        pred = zeros(4,4);
        return
    end
    Seq_r(i-1,j-1) = bitshift(temp,-1,'int64');
end
for x = 0:3
    for y = 0:3
        z = 2*x-y;
        w = bitshift(y,-1);
        if (z==0 || z==2 || z==4 || z==6)
            if( outofind(size(Seq_r), i-1, i-1, j+x-w-1, j+x-w) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i-1,j+x-w-1) + Seq_r(i-1,j+x-w) + 1);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1)= bitshift(temp, -1, 'int64');
        elseif (z==1 || z==3 || z==5)
            if( outofind(size(Seq_r), i-1, i-1, j+x-w-2, j+x-w) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i-1,j+x-w-2) + 2*Seq_r(i-1,j+x-w-1) + Seq_r(i-1,j+x-w) + 2);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1)= bitshift(temp, -2, 'int64');
        elseif z==-1
            if( outofind(size(Seq_r), i-1, i, j-1, j) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i,j-1)+ 2*Seq_r(i-1,j-1) + Seq_r(i-1,j) + 2);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1)= bitshift(temp, -2, 'int64');
        else
            if( outofind(size(Seq_r), i+y-3, i+y-1, j-1, j-1) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i-1+y,j-1)+ 2*Seq_r(i+y-2,j-1) + Seq_r(i+y-3,j-1) + 2);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1) = bitshift(temp, -2, 'int64');
        end
    end
end
Seq_r(i-1,j-1) = tmp;
end
%--------------------------------------------------------
function [pred,err] = pred_hd_4(Seq_r,i,j)
err = 0;
if(i==1 || j==1)
    err = 1;
    pred = zeros(4,4);
    return
end
tmp = Seq_r(i-1,j-1);
if ((rem(i,16) == 1) && (rem(j,16) == 1))
    temp=Seq_r(i-1,j) + Seq_r(i,j-1);
    Seq_r(i-1,j-1) = bitshift(temp,-1,'int64');
end
for x = 0:3
    for y = 0:3
        z = 2*y-x;
        w = bitshift(x,-1);
        if (z==0 || z==2 || z==4 || z==6)
            if( outofind(size(Seq_r), i+y-w-1, i+y-w, j-1, j-1) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i+y-w-1,j-1) + Seq_r(i+y-w,j-1) + 1);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1)= bitshift(temp, -1, 'int64');
        elseif (z==1 || z==3 || z==5)
            if( outofind(size(Seq_r), i+y-w-2, i+y-w, j-1, j-1) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i+y-w-2,j-1) + 2*Seq_r(i+y-w-1,j-1) + Seq_r(i+y-w,j-1) + 2);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1)= bitshift(temp, -2, 'int64');
        elseif z==-1
            if( outofind(size(Seq_r), i-1, i, j-1, j) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i-1,j)+ 2*Seq_r(i-1,j-1) + Seq_r(i,j-1) + 2);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1)= bitshift(temp, -2, 'int64');
        else
            if( outofind(size(Seq_r), i-1, i-1, j+x-3, j+x-1) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i-1,j+x-1)+ 2*Seq_r(i-1,j+x-2) + Seq_r(i-1,j+x-3) + 2);
            if(floor(temp) ~= temp)
                err = 1;
                pred = zeros(4,4);
                return
            end
            pred(y+1,x+1) = bitshift(temp, -2, 'int64');
        end
    end
end
Seq_r(i-1,j-1) = tmp;
end
%--------------------------------------------------------
function [pred,err] = pred_vl_4(Seq_r,i,j)
err =0;
if(i==1)
    err = 1;
    pred = zeros(4,4);
    return
end

for x = 0:3
    for y = 0:3
        w = bitshift(y,-1);
        if rem(y,2)== 0
            if( outofind(size(Seq_r), i-1, i-1, j+x+w, j+x+w+1) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp = Seq_r(i-1,j+x+w) + Seq_r(i-1,j+x+w+1) + 1;
            if(floor(temp) ~= temp)
                err=1;
                pred = zeros(4,4);
                return;
            end
            pred(y+1,x+1) = bitshift(temp,-1,'int64');
        else
            if( outofind(size(Seq_r), i-1, i-1, j+x+w, j+x+w+2) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp =(Seq_r(i-1,j+x+w) + 2*Seq_r(i-1,j+x+w+1) + Seq_r(i-1,j+x+w+2) + 2);
            if(floor(temp) ~= temp)
                err=1;
                pred = zeros(4,4);
                return;
            end
            pred(y+1,x+1) = bitshift(temp,-2,'int64');
        end
    end
end

end
%--------------------------------------------------------
function [pred,err] = pred_hu_4(Seq_r,i,j)
err =0;
if(j==1)
    err = 1;
    pred = zeros(4,4);
    return
end

for x = 0:3
    for y = 0:3
        z = 2*y+x;
        w = bitshift(x,-1);
        if (z==0)||(z==2)||(z==4)
            if( outofind(size(Seq_r), i+y+w, i+y+w+1, j-1, j-1) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i+y+w,j-1) + Seq_r(i+y+w+1,j-1) + 1);
            if(floor(temp) ~= temp)
                err=1;
                pred = zeros(4,4);
                return;
            end
            pred(y+1,x+1)= bitshift(temp, -1, 'int64');
        elseif (z==1)||(z==3)
            if( outofind(size(Seq_r), i+y+w, i+y+w+2, j-1, j-1) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i+y+w,j-1) + 2*Seq_r(i+y+w+1,j-1) + Seq_r(i+y+w+2,j-1) + 2);
            if(floor(temp) ~= temp)
                err=1;
                pred = zeros(4,4);
                return;
            end
            pred(y+1,x+1)= bitshift(temp, -2, 'int64');
        elseif z==5
            if( outofind(size(Seq_r), i+2, i+3, j-1, j-1) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            temp=(Seq_r(i+2,j-1)+ 3*Seq_r(i+3,j-1) + 2);
            if(floor(temp) ~= temp)
                err=1;
                pred = zeros(4,4);
                return;
            end
            pred(y+1,x+1)= bitshift(temp, -2, 'int64');
        else
            if( outofind(size(Seq_r), i+3, i+3, j-1, j-1) == 1 )
                err = 1; pred = zeros(4,4); return
            end
            if(floor(Seq_r(i+3,j-1)) ~= Seq_r(i+3,j-1))
                err=1;
                pred = zeros(4,4);
                return;
            end
            pred(y+1,x+1) = Seq_r(i+3,j-1);
        end
    end
end

end

%% Chroma
%-----------------------------------------------------------------
function [Xi,k,err] = dec_mb_8(k,bits,mode,Seq_r_Luma,i,j)
[pred,err] = find_pred_8(mode,Seq_r_Luma,i,j);
if (err == 1)
    Xi=1;k=1; return;
end
[icp,k,err] = code_block_8(k,bits);
if (err == 1)
    Xi=1;k=1; return;
end
Xi = pred + icp;

end
%----------------------------------------------------------------
function [pred,err] = find_pred_8(mode,Seq_r_Luma,i,j)
err = 0;
if (mode==9)
    [pred,err] = pred_vert_8(Seq_r_Luma,i,j);
elseif (mode==10)
    [pred,err] = pred_horz_8(Seq_r_Luma,i,j);
elseif (mode==11)
    [pred,err] = pred_dc_8(Seq_r_Luma,i,j);
elseif (mode==12)
    [pred,err] = pred_plane_8(Seq_r_Luma,i,j);
else
    pred = zeros(8,8);
    err = 1;
end

end
%-------------------------------------------------------
%% 8x8 Vertical prediciton
function [pred,err] = pred_vert_8(Seq_r,i,j)
err = 0;
if( outofind(size(Seq_r), i-1, i-1, j, j+7) == 1 )
    err = 1; pred = zeros(4,4); return
end
pred = ones(8,1)*Seq_r(i-1,j:j+7);
end
%-------------------------------------------------------
%% 8x8 Vertical Prediciton
function [pred,err] = pred_horz_8(Seq_r,i,j)
err = 0;
if( outofind(size(Seq_r), i, i+7, j-1, j-1) == 1 )
    err = 1; pred = zeros(4,4); return
end
pred = Seq_r(i:i+7,j-1)*ones(1,8);
end
%-------------------------------------------------------
%% 8x8 DC prediction
function [pred,err] = pred_dc_8(Seq_r,i,j)
err = 0;
global bw_pixel;
if (i==1) && (j==1)
    pred(1:4,1:4) = (2^(bw_pixel-1))*ones(4,4);
    pred(1:4,5:8) = (2^(bw_pixel-1))*ones(4,4);
    pred(5:8,1:4) = (2^(bw_pixel-1))*ones(4,4);
    pred(5:8,5:8) = (2^(bw_pixel-1))*ones(4,4);
elseif(i==1)
    if( outofind(size(Seq_r), i, i+7, j-1, j-1) == 1 )
        err = 1; pred = zeros(4,4); return
    end
    temp1 = sum(Seq_r(i:i+3,j-1)) + 2;
    temp3 = sum(Seq_r(i+4:i+7,j-1)) + 2;
    if(floor(temp1)~=temp1 || floor(temp3)~=temp3 )
        err = 1;
        pred = zeros(8,8);
        return;
    end
    pred(1:4,1:4) = bitshift(temp1,-2,'int64');
    pred(1:4,5:8) = bitshift(temp1,-2,'int64');
    pred(5:8,1:4) = bitshift(temp3,-2,'int64');
    pred(5:8,5:8) = bitshift(temp3,-2,'int64');
elseif(j==1)
    if( outofind(size(Seq_r), i-1, i-1, j, j+7) == 1 )
        err = 1; pred = zeros(4,4); return
    end
    temp1 = sum(Seq_r(i-1,j:j+3))   + 2;
    temp2 = sum(Seq_r(i-1,j+4:j+7)) + 2;
    if(floor(temp1)~=temp1 || floor(temp2)~=temp2 )
        err = 1;
        pred = zeros(8,8);
        return;
    end
    pred(1:4,1:4) = bitshift(temp1,-2,'int64');
    pred(1:4,5:8) = bitshift(temp2,-2,'int64');
    pred(5:8,1:4) = bitshift(temp1,-2,'int64');
    pred(5:8,5:8) = bitshift(temp2,-2,'int64');
else
    if( outofind(size(Seq_r), i-1, i+4, j-1, j+7) == 1 )
        err = 1; pred = zeros(4,4); return
    end
    temp1 = sum(Seq_r(i-1,j:j+3)) + sum(Seq_r(i:i+3,j-1)) + 4    ;
    temp2 = sum(Seq_r(i-1,j+4:j+7)) + 2                          ;
    temp3 = sum(Seq_r(i+4:i+7,j-1)) + 2                          ;
    temp4 = sum(Seq_r(i-1,j+4:j+7)) + sum(Seq_r(i+4:i+7,j-1)) + 4;
    if(floor(temp1)~=temp1 || floor(temp2)~=temp2 || floor(temp3)~=temp3  || floor(temp4)~=temp4)
        err = 1;
        pred = zeros(8,8);
        return;
    end
    pred(1:4,1:4) = bitshift(temp1,-3,'int64');
    pred(1:4,5:8) = bitshift(temp2,-2,'int64');
    pred(5:8,1:4) = bitshift(temp3,-2,'int64');
    pred(5:8,5:8) = bitshift(temp4,-3,'int64');
end
end
%------------------------------------------------------
%% 8x8 Plane prediction
function [pred,err] = pred_plane_8(Seq_r,i,j)
err = 0;
global bw_pixel;
if( outofind(size(Seq_r), i-1, i, j-1, j) == 1 )
    err = 1; pred = zeros(4,4); return
end

Seq_r_temp = Seq_r(i-1,j-1);
%%%%%%%%%%
temp1 = Seq_r(i-1,j) + Seq_r(i,j-1);
if(floor(temp1)~=temp1)
    err = 1;
    pred = zeros(8,8);
    return;
end
%%%%%%%%%%

Seq_r(i-1,j-1) = bitshift(temp1,-1,'int64');
x = 0:3;
H = sum((x+1)*(Seq_r(i+x+4,j-1)-Seq_r(i+2-x,j-1)));
y = 0:3;
V = sum((y+1)*(Seq_r(i-1,j+4+y)'-Seq_r(i-1,j+2-y)'));
Seq_r(i-1,j-1) = Seq_r_temp;

%%%%%%%%%
temp2 =17*H + 16;
temp3 =17*V + 16;
if(floor(temp1)~=temp1 || floor(temp2)~=temp2)
    err = 1;
    pred = zeros(8,8);
    return;
end
%%%%%%%%
a = 16*(Seq_r(i-1,j+7) + Seq_r(i+7,j-1));
b = bitshift(17*H + 16,-5,'int64');
c = bitshift(17*V + 16,-5,'int64');


for m = 1:8
    for n = 1:8
        %%%%%%%%%
        temp4 =a + b*(m-4)+ c*(n-4) + 16;
        if(floor(temp4)~=temp4)
            err = 1;
            pred = zeros(8,8);
            return;
        end
        %%%%%%%%
        d = bitshift(temp4,-5,'int64');
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
function [icp,k,err] = code_block_8(k,bits)

global QP;

for i=1:4:8
    for j=1:4:8
        [Z1(i:i+3,j:j+3,1),m,err] = dec_cavlc(bits(k:length(bits)),0,0);
	if(err==1)
		icp=zeros(4,8); k=0; return
	end
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
