function hapticSig = haptic(x,fs)
t = (0:length(x)-1)/fs;
x_rec = abs(x);
f0raw = MulticueF0v14(x,fs);
f0raw_nonZero = f0raw(f0raw > 0);
S1 = zuocham(f0raw);
F = fangcha(f0raw_nonZero)
delta = sum(S1>0) - sum(S1<0)
if   abs(delta) > 200
   if delta > 0
      [a1,F0] = Tone2(f0raw,x,fs);bool = 2
   else
      [a1,F0] = Tone4(f0raw,x,fs);bool = 4
   end 
elseif F < 0.1
        [a1,F0] = Tone1(f0raw,x,fs);bool = 1
    else
        [a1,F0] = Tone3(f0raw,x,fs);bool = 3
    
end

% figure;plot(F0);
% % sound(a1,fs)
% figure;subplot(311);plot(t,x);subplot(312);plot(t,x_rec);subplot(313);plot(t,a1)
% figure;myspectrogram(a1,fs);ylim([0,500])

hapticSig = a1;

end
