% DC Quantization function, which will return

function [B_Q] = DC_chroma_quantization (B, QPc)
global num_op;
% q is the power of right shift
q = 15 + floor(QPc/6) + 0;
num_op = num_op + 1;

% Quantization table
M = [13107 5243 8066
     11916 4660 7490
     10082 4194 6554
     9362  3647 5825
     8192  3355 5243
     7282  2893 4559];

Q_m = rem (QPc,6);
num_op = num_op + 1;

a = M(Q_m+1,1); % (0,0),(0,2),(2,0),(2,2)

% scaling and quantization
%B_Q = round((B.*a)/2^(q+1));
B_Q = roundnew((B.*a)/2^(q+1));
num_op = num_op + 32;

end
