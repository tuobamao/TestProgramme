function [a1,f0raw_new]=Tone2(f0raw,x,fs) 
f0raw_nonZero = f0raw(f0raw>0);
f0raw_new = f0raw-min(f0raw_nonZero)+80;
f0raw_new=f0raw_new+f0raw_new/max(f0raw)*50;
f0raw_new(f0raw_new<0) = 0; 
y1=interpft(f0raw_new,length(x));
y2= fmmod(y1, 100, fs, 1);
x_rec = abs(x);
fc = 30;
[b,a] = butter(6,fc/(fs/2));
x_env = filtfilt(b,a,x_rec);
a1 = x_env.*y2;
a1 = a1/max(a1)*0.9;
end