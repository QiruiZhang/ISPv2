%--------------------------------------------------------------------------
%% This function is used to do integer transform for residues
function [W]= integer_transform(X)
global num_op;
% X is a 4x4 block of data
% W is the trasnsformed coefficients

% C is the core transform matrix
C =  [1 1 1 1
      2 1 -1 -2
      1 -1 -1 1
      1 -2 2 -1];
 
  W = roundnew(C*X*C'); 
% W = (C*X*C').*E;  
num_op = num_op + 4*16*2;

end