function noisySpeech = myAddNoise(speech,SNR,noise,samples)

LN = length(noise);
LS = length(speech);

if LN>LS
%     begin_point = randi(LN-LS);
    begin_point = 1; % 20180727 changed to this Ϊ�˱�֤����Ҳ�о�ȷ��ʱ�����
    noise = noise(begin_point:begin_point+LS-1);
elseif LN<LS
    noise = [noise;zeros(LS-LN,1)];     % ��������ᷢ����һ���������Ƚϳ���
end
if samples(1) == 0
    speech1 = speech/myRMS(speech)*myRMS(noise)*10^(SNR/20);  % ������level���䣬�ı�������level
    %rms(speech1)
else
    speech1 = speech/myRMS(speech(samples))*myRMS(noise(samples))*10^(SNR/20);  % ������level���䣬�ı�������level
end

noisySpeech = speech1 + noise;
