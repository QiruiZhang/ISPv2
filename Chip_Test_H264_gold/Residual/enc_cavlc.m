%--------------------------------------------------------------------------
%% enc_cavlc
function [bits] = enc_cavlc(data, nL, nU)

%% CAVLC Encoder. 
% takes in 4x4 block of residual data and produces output bits

global num_op;

% load table.mat;
global Table_coeff0 Table_coeff1 Table_coeff2 Table_coeff3
global Table_run Table_zeros

Table_coeff0 = {'1' '' '' '' %0
                '000101' '01' '' '' %1
                '00000111' '000100' '001' '' %2
                '000000111' '00000110' '0000101' '00011' %3
                '0000000111' '000000110' '00000101' '000011' %4
                '00000000111' '0000000110' '000000101' '0000100' %5
                '0000000001111' '00000000110' '0000000101' '00000100' %6
                '0000000001011' '0000000001110' '00000000101' '000000100' %7
                '0000000001000'  '0000000001010'  '0000000001101'  '0000000100' %8
                '00000000001111'  '00000000001110'  '0000000001001'  '00000000100' %9
                '00000000001011'  '00000000001010'  '00000000001101'  '0000000001100' %10
                '000000000001111'  '000000000001110'  '00000000001001'  '00000000001100' %11
                '000000000001011'  '000000000001010'  '000000000001101'  '00000000001000' %12
                '0000000000001111'  '000000000000001'  '000000000001001'  '000000000001100' %13
                '0000000000001011'  '0000000000001110'  '0000000000001101'  '000000000001000' %14
                '0000000000000111'  '0000000000001010'  '0000000000001001'  '0000000000001100' %15
                '0000000000000100'  '0000000000000110'  '0000000000000101'  '0000000000001000'}; %16
            
Table_coeff1 = {'11'  ''  ''  '' %0
                '001011'  '10'  ''  '' %1
                '000111'  '00111'  '011'  '' %2
                '0000111'  '001010'  '001001'  '0101' %3
                '00000111'  '000110'  '000101'  '0100' %4
                '00000100'  '0000110'  '0000101'  '00110' %5
                '000000111'  '00000110'  '00000101'  '001000' %6
                '00000001111'  '000000110'  '000000101'  '000100' %7
                '00000001011'  '00000001110'  '00000001101'  '0000100' %8
                '000000001111'  '00000001010'  '00000001001'  '000000100' %9
                '000000001011'  '000000001110'  '000000001101'  '00000001100' %10
                '000000001000'  '000000001010'  '000000001001'  '00000001000' %11
                '0000000001111'  '0000000001110'  '0000000001101'  '000000001100' %12
                '0000000001011'  '0000000001010'  '0000000001001'  '0000000001100' %13
                '0000000000111'  '00000000001011'  '0000000000110'  '0000000001000' %14
                '00000000001001'  '00000000001000'  '00000000001010'  '0000000000001' %15
                '00000000000111'  '00000000000110'  '00000000000101'  '00000000000100'}; %16   
            
Table_coeff2 = {'1111'  ''  ''  '' %0
                '001111'  '1110'  ''  '' %1
                '001011'  '01111'  '1101'  '' %2
                '001000'  '01100'  '01110'  '1100' %3
                '0001111'  '01010'  '01011'  '1011' %4
                '0001011'  '01000'  '01001'  '1010' %5
                '0001001'  '001110'  '001101'  '1001' %6
                '0001000'  '001010'  '001001'  '1000' %7
                '00001111'  '0001110'  '0001101'  '01101' %8
                '00001011'  '00001110'  '0001010'  '001100' %9
                '000001111'  '00001010'  '00001101'  '0001100' %10
                '000001011'  '000001110'  '00001001'  '00001100' %11
                '000001000'  '000001010'  '000001101'  '00001000' %12
                '0000001101'  '000000111'  '000001001'  '000001100' %13
                '0000001001'  '0000001100'  '0000001011'  '0000001010' %14
                '0000000101'  '0000001000'  '0000000111'  '0000000110' %15
                '0000000001'  '0000000100'  '0000000011'  '0000000010'}; %16 
            
Table_coeff3 = {'000011'  ''  ''  '' %0
                '000000'  '000001'  ''  '' %1
                '000100'  '000101'  '000110'  '' %2
                '001000'  '001001'  '001010'  '001011' %3
                '001100'  '001101'  '001110'  '001111' %4
                '010000'  '010001'  '010010'  '010011' %5
                '010100'  '010101'  '010110'  '010111' %6
                '011000'  '011001'  '011010'  '011011' %7
                '011100'  '011101'  '011110'  '011111' %8
                '100000'  '100001'  '100010'  '100011' %9
                '100100'  '100101'  '100110'  '100111' %10
                '101000'  '101001'  '101010'  '101011' %11
                '101100'  '101101'  '101110'  '101111' %12
                '110000'  '110001'  '110010'  '110011' %13
                '110100'  '110101'  '110110'  '110111' %14
                '111000'  '111001'  '111010'  '111011' %15
                '111100'  '111101'  '111110'  '111111'}; %16  
            
Table_zeros = {'1'  '011'  '010'  '0011'  '0010'  '00011'  '00010'  '000011'  '000010'  '0000011'  '0000010'  '00000011'  '00000010'  '000000011'  '000000010'  '000000001' '' %1
             '111'  '110'  '101'  '100'  '011'  '0101'  '0100'  '0011'  '0010'  '00011'  '00010'  '000011'  '000010'  '000001'  '000000'  '' '' %2
             '0101'  '111'  '110'  '101'  '0100'  '0011'  '100'  '011'  '0010'  '00011'  '00010'  '000001'  '00001'  '000000'  ''  '' '' %3
             '00011'  '111'  '0101'  '0100'  '110'  '101'  '100'  '0011'  '011'  '0010'  '00010'  '00001'  '00000'  ''  ''  '' '' %4
             '0101'  '0100'  '0011'  '111'  '110'  '101'  '100'  '011'  '0010'  '00001'  '0001'  '00000'  ''  ''  ''  '' '' %5
             '000001'  '00001'  '111'  '110'  '101'  '100'  '011'  '010'  '0001'  '001'  '000000'  ''  ''  ''  ''  '' '' %6
             '000001'  '00001'  '101'  '100'  '011'  '11'  '010'  '0001'  '001'  '000000'  ''  ''  ''  ''  ''  '' '' %7
             '000001'  '0001'  '00001'  '011'  '11'  '10'  '010'  '001'  '000000'  ''  ''  ''  ''  ''  ''  '' '' %8
             '000001'  '000000'  '0001'  '11'  '10'  '001'  '01'  '00001'  ''  ''  ''  ''  ''  ''  ''  '' '' %9
             '00001'  '00000'  '001'  '11'  '10'  '01'  '0001'  ''  ''  ''  ''  ''  ''  ''  ''  '' '' %10
             '0000'  '0001'  '001'  '010'  '1'  '011'  ''  ''  ''  ''  ''  ''  ''  ''  ''  '' '' %11
             '0000'  '0001'  '01'  '1'  '001'  ''  ''  ''  ''  ''  ''  ''  ''  ''  ''  '' '' %12
             '000'  '001'  '1'  '01'  ''  ''  ''  ''  ''  ''  ''  ''  ''  ''  ''  '' '' %13
             '00'  '01'  '1'  ''  ''  ''  ''  ''  ''  ''  ''  ''  ''  ''  ''  '' '' %14
             '0'  '1'  ''  ''  ''  ''  ''  ''  ''  ''  ''  ''  ''  ''  ''  '' ''}; %15
             
         
         
Table_run = {'1'  '1'  '11'  '11'  '11'  '11'  '111' %0
               '0'  '01'  '10'  '10'  '10'  '000'  '110' %1
               ''  '00'  '01'  '01'  '011'  '001'  '101' %2
               ''  ''  '00'  '001'  '010'  '011'  '100' %3
               ''  ''  ''  '000'  '001'  '010'  '011' %4
               ''  ''  ''  ''  '000'  '101'  '010' %5
               ''  ''  ''  ''  ''  '100'  '001' %6
               ''  ''  ''  ''  ''  ''  '0001' %7
               ''  ''  ''  ''  ''  ''  '00001' %8
               ''  ''  ''  ''  ''  ''  '000001' %9
               ''  ''  ''  ''  ''  ''  '0000001' %10
               ''  ''  ''  ''  ''  ''  '00000001' %11
               ''  ''  ''  ''  ''  ''  '000000001' %12
               ''  ''  ''  ''  ''  ''  '0000000001' %13
               ''  ''  ''  ''  ''  ''  '00000000001'}; %14
bits = '';

% Convert 4x4 matrix data into a 1x16 data of zig-zag scan
[row, col] = size(data);

% check the correct size of the block
if((row~=4)||(col~=4))
    disp('Residual block size mismatch - exit from CAVLC')
    return;
end

scan = [1,1;1,2;2,1;3,1;2,2;1,3;1,4;2,3;3,2;4,1;4,2;3,3;2,4;3,4;4,3;4,4];

for i=1:16
   m=scan(i,1);
   n=scan(i,2);
   l(i)=data(m,n); % l contains the reordered data
end

i_last = 16;
% find the last non-zero co-eff in reverse order
while ((i_last>0)&&(l(i_last)==0))
   i_last = i_last - 1; 
   num_op = num_op + 1;
end

i_total = 0; % Total non zero coefficients
i_total_zero = 0; % Total zeros
i_trailing = 0;
sign = ''; % find sign for trailing ones
idx = 1;

%% find level, trailing ones(sign), run and total zero values
while ((i_last>0)&&(abs(l(i_last))==1)&&(i_trailing<3))
    level(idx)=l(i_last);
    i_total = i_total + 1;
    i_trailing = i_trailing + 1;
    
    num_op = num_op + 2;
    
    if l(i_last)==-1
        sign = [sign '1'];
    else 
        sign = [sign '0'];
    end
    
    run(idx) = 0;    
    i_last = i_last - 1;
    num_op = num_op + 1;
    while ((i_last>0)&&(l(i_last)==0))
        run(idx) = run(idx) + 1;
        i_total_zero = i_total_zero + 1;
        i_last = i_last - 1; 
        num_op = num_op + 3;
    end
    idx = idx + 1;
    num_op = num_op + 1;
end

while (i_last>0)
    level(idx)=l(i_last);
    i_total = i_total + 1;
    num_op = num_op + 1;
    
    run(idx) = 0;    
    i_last = i_last - 1;
    num_op = num_op + 1;
    while ((i_last>0)&&(l(i_last)==0))
        run(idx) = run(idx) + 1;
        i_total_zero = i_total_zero + 1;
        i_last = i_last - 1; 
        num_op = num_op + 3;
    end
    idx = idx + 1;
    num_op = num_op + 1;
end

%% Write coeff_token

% find n parameter (context adaptive)
if (nL>0)&&(nU>0)
    n = (nL + nU + 1)/2;
    num_op = num_op + 2;
elseif (nL>0)||(nU>0)
    n = nL + nU;
    num_op = num_op + 1;
else
    n = 0;
end

% Coeff_token mapping
% Rows are the total coefficient(0-16) and columns are the trailing ones(0-3)
% TABLE_COEFF0,1,2,3 ARE STORED IN TABLE.MAT OR CAVLC_TABLES.M FILE
% Choose proper table_coeff based on n value
if 0<=n<2
    Table_coeff = Table_coeff0;
elseif 2<=n<4
    Table_coeff = Table_coeff1;
elseif 4<=n<8
    Table_coeff = Table_coeff2;
elseif 8<=n
    Table_coeff = Table_coeff3;
end

% Assign coeff_token and append it to output bits
% Here coeff_token is cell array so needs to be coverted to char
coeff_token = Table_coeff(i_total + 1,i_trailing + 1);
bits = [bits char(coeff_token)];

% If the total coefficients == 0 exit from this function
if i_total==0
    return;
end

% Append sign of trailing ones to bits
if i_trailing>0
    bits = [bits sign];
end

%% Encode the levels of remaining non-zero coefficients

% find the suffix length
if (i_total>10)&&(i_trailing<3)
   i_sufx_len = 1;
else
   i_sufx_len = 0;
end

% loop
for i=(i_trailing + 1):i_total
    
    if level(i)<0                       %% get levelcode
        i_level_code = -2*level(i) - 1;
        num_op = num_op + 2;
    else
        i_level_code = 2*level(i) - 2;
        num_op = num_op + 2;
    end
    
    if (i == i_trailing + 1)&&(i_trailing<3)
       i_level_code = i_level_code - 2; 
       num_op = num_op + 1;
    end
    
    if bitshift(i_level_code,-i_sufx_len)<14    %% get level prefix and level suffix
        level_prfx = bitshift(i_level_code,-i_sufx_len);
        while(level_prfx>0)
            bits = [bits '0'];
            level_prfx = level_prfx - 1;
            num_op = num_op + 1;
        end
        bits = [bits '1'];
        
        if i_sufx_len>0 
            level_sufx = dec2bin(i_level_code,i_sufx_len);
            x = length(level_sufx);
            if x>i_sufx_len
                level_sufx = level_sufx(x-i_sufx_len+1:x);
            end
            bits = [bits level_sufx];
        end
    elseif (i_sufx_len==0)&&(i_level_code<30)
       level_prfx = 14;
       while(level_prfx>0)
            bits = [bits '0'];
            level_prfx = level_prfx - 1;
            num_op = num_op + 1;
        end
        bits = [bits '1'];
        
       level_sufx = dec2bin(i_level_code-14,4);
       x = length(level_sufx);
            if x>4
                level_sufx = level_sufx(x-4+1:x);
            end
       bits = [bits level_sufx];
    
    elseif (i_sufx_len>0)&&(bitshift(i_level_code,-i_sufx_len)==14)
        level_prfx = 14;
       while(level_prfx>0)
            bits = [bits '0'];
            level_prfx = level_prfx - 1;
            num_op = num_op + 1;
        end
        bits = [bits '1'];
        
        level_sufx = dec2bin(i_level_code,i_sufx_len);
        x = length(level_sufx);
            if x>i_sufx_len
                level_sufx = level_sufx(x-i_sufx_len+1:x);
            end
        bits = [bits level_sufx];
    else
        level_prfx = 15;
       while(level_prfx>0)
            bits = [bits '0'];
            level_prfx = level_prfx - 1;
            num_op = num_op + 1;
        end
        bits = [bits '1'];
        
        i_level_code = i_level_code - bitshift(15,i_sufx_len);
        
        if i_sufx_len==0
           i_level_code = i_level_code - 15; 
           num_op = num_op + 1;
        end
        
        if (i_level_code>=bitshift(1,12))||(i_level_code<0)
            disp('Overflow occured');
        end
        
        level_sufx = dec2bin(i_level_code,12);
        x = length(level_sufx);
            if x>12
                level_sufx = level_sufx(x-12+1:x);
            end
        bits = [bits level_sufx];
    end
    
    if i_sufx_len==0
        i_sufx_len = i_sufx_len + 1;
        num_op = num_op + 1;
    end
    if ((abs(level(i)))>bitshift(3,i_sufx_len - 1))&&(i_sufx_len<6)
        i_sufx_len = i_sufx_len + 1;
        num_op = num_op + 1;
    end

end

%% Encode Total zeros

% Here Rows(1-16) are Total coefficient and colums(0-15) are total zeros
% Rearranged from the standard for simplicity
% Table_zeros is located in table.mat or cavlc_tables.m file
            
if i_total<16
    total_zeros = Table_zeros(i_total,i_total_zero + 1);
    bits = [bits char(total_zeros)];
end

%% Encode each run of zeros
% Rows are the run before, and columns are zeros left
% Table_run is located in table.mat or cavlc_tables.m file

i_zero_left = i_total_zero;
 if i_zero_left>=1   
    for i=1:i_total
       if (i_zero_left>0)&&(i==i_total)
           break;
       end
       if i_zero_left>=1 
           i_zl = min(i_zero_left,7);
           run_before = Table_run(1 + run(i),i_zl);
           bits = [bits char(run_before)];
           i_zero_left = i_zero_left - run(i);
           num_op = num_op + 2;
       end
    end
 end
 
end