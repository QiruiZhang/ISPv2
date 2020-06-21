function out = clip( in, uplim )
%CLIP Summary of this function goes here
%   Detailed explanation goes here

[m,n] = size(in);
out = zeros(m,n);
for i = 1:m
    for j = 1:n
        if (in(i,j) < 0) 
            out(i,j) = 0;
        elseif (in(i,j) > uplim)
            out(i,j) = uplim;
        else 
            out(i,j) = in(i,j);
        end
    end
end

end

