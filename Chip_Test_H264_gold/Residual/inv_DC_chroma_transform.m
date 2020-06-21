%--------------------------------------------------------------------------
%% This function is used to do invert DC chroma transform for residues
function [Y] = inv_DC_chroma_transform(W)
global num_op;

 % Ci is the inverse core transform matrix
Ci =  [1 1
       1 -1];

 Y = roundnew(Ci'*W*Ci);
%  Y = Ci'*(W.*E)*Ci;

 num_op = num_op + 4*2*2;
 
end