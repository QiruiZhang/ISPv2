% Quantization function, which will return

function [B_Q] = quantization (B, QP)
global num_op;
% q is the power of right shift
q = 15 + floor(QP/6) + 0;
num_op = num_op + 1;

% Quantization table
M = [13107 5243 8066
     11916 4660 7490
     10082 4194 6554
     9362  3647 5825
     8192  3355 5243
     7282  2893 4559];

Q_m = rem (QP,6);
num_op = num_op + 1;

a = M(Q_m+1,1); % (0,0),(0,2),(2,0),(2,2)
b = M(Q_m+1,2); % (1,1),(1,3),(3,1),(3,3)
g = M(Q_m+1,3); % (0,1),(0,3),(1,0),(1,2)
                % (2,1),(2,3),(3,0),(3,2)
                
A = [a g a g
     g b g b
     a g a g
     g b g b];
 
%B.*A
  
% scaling and quantization
%B.*A
%B_Q = round((B.*A)/2^q);
B_Q = roundnew((B.*A)/2^q);
%B_Q0 = bitshift(B.*A,-q,'int64')
num_op = num_op + 32;

end
