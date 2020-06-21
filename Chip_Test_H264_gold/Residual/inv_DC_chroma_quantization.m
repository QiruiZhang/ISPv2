%--------------------------------------------------------------------------
%% This function is used to do inverse quantization for residues
function [Wi]= inv_DC_chroma_quantization(Z,QPc)
global bw_pixel;
global num_op;
% q is qbits
q = floor(QPc/6) + 0;
q;
% The scaling factor matrix V depend on the QP and the position of the
% coefficient.
%   delta lambda miu
SM = [10 16 13
      11 18 14
      13 20 16
      14 23 18
      16 25 20
      18 29 23];
 
 x = rem(QPc,6);
 num_op = num_op + 1;
 
 % find delta, lambda and miu values
 d = SM(x+1,1);
  
 % find the inverse quantized coefficients
  Wi = Z.*d;
  Wi;
  if QPc >= 6 + 4*(bw_pixel - 8)
      %Wi = round(Wi*2^(q-1));
     Wi = bitshift(Wi,q-1,'int64');
  else
     %Wi = round(Wi/2);
     Wi = roundnew(Wi/2);
  end
 num_op = num_op + 16 + 16;
 
end
