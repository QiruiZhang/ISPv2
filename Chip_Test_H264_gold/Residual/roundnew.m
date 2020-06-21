function [ out ] = roundnew( in )
%ROUNDNEW Summary of this function goes here
%   Detailed explanation goes here
[m,n] = size(in);
out = zeros(m,n);

for i = 1:m
    for j = 1:n
        if (in(i,j) >= 0)
            out(i,j) = round(in(i,j));
        else 
            if (ceil(in(i,j)) - in(i,j) <= 0.5)
                out(i,j) = ceil(in(i,j));
            else
                out(i,j) = floor(in(i,j));
            end
        end
    end
end

end

