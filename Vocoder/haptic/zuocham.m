function S1=zuocham(f0raw)
for i=1:length(f0raw)-1
S1(i) = f0raw(i+1)-f0raw(i);
end
end