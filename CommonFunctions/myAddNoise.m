function noisySpeech = myAddNoise(speech,SNR,noise,samples)

LN = length(noise);
LS = length(speech);

if LN>LS
%     begin_point = randi(LN-LS);
    begin_point = 1; % 20180727 changed to this 为了保证噪声也有精确的时间控制
    noise = noise(begin_point:begin_point+LS-1);
elseif LN<LS
    noise = [noise;zeros(LS-LN,1)];     % 极少情况会发生，一般噪声都比较长。
end
if samples(1) == 0
    speech1 = speech/myRMS(speech)*myRMS(noise)*10^(SNR/20);  % 噪声的level不变，改变语音的level
    %rms(speech1)
else
    speech1 = speech/myRMS(speech(samples))*myRMS(noise(samples))*10^(SNR/20);  % 噪声的level不变，改变语音的level
end

noisySpeech = speech1 + noise;
