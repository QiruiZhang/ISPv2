%--------------------------------------------------------------------------
%% Exp-Golomb
function [bits] = enc_golomb(symbol, sign)
% Encodes exponential golomb codes for a SINGLE SYMBOL
% if singed_symbols=1, singed mapping is used
% otherwise unsigned mapping is used

% symbols = -3;
% signed_symbols = 1;

global num_op;

bits = '';

% If signed_symbol flag is 1
if (sign)
    if (symbol ==0)
%         symbol = symbol;
    elseif (symbol>0)
        symbol = 2*symbol -1;
        num_op = num_op + 2;
    else 
        symbol = (-2)*symbol;
        num_op = num_op + 1;
    end
% if unsigned integers are used    
else
%     symbol = symbol;
end

% Here code_num = symbol
% M is prefix, info is suffix
M = floor(log2(symbol + 1));
info = dec2bin(symbol + 1 - 2^M,M);
num_op = num_op + 7;

for j=1:M
    bits = [bits '0'];
end
bits = [bits '1'];
bits = [bits info];

end