function F = fangcha(a)
F = sum((a(1,:)-mean(a)).^2)/(length(a)-1);
end