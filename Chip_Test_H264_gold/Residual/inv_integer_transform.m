%--------------------------------------------------------------------------
%% This function is used to do inverse integer transform for residues
function [Y] = inv_integer_transform(W)
global num_op;

 % Ci is the inverse core transform matrix
Ci =  [1 1 1 1
      1 1/2 -1/2 -1
      1 -1 -1 1
      1/2 -1 1 -1/2];
 Y = roundnew(W*Ci);
 Y = roundnew(Ci'*Y);
%  Y = Ci'*(W.*E)*Ci;

 num_op = num_op + 16*4*2;
 
end