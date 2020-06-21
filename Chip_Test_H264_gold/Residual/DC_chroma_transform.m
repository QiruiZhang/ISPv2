%--------------------------------------------------------------------------
%% This function is used to do DC chroma transform for residues
function [Yd]= DC_chroma_transform(Wd)
global num_op;
% X is a 2x2 block of integer transformed chroma 4*4Blk
% Yd is the trasnsformed coefficients

% C is the core transform matrix
C =  [1 1
      1 -1];
 
Yd = roundnew(C*Wd*C'); 
% W = (C*X*C').*E;  
num_op = num_op + 2*4*2;

end