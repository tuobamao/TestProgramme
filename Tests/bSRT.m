classdef bSRT < SRT
% This class is designed to for adaptive SRT test with binaural control.
% to be specific: the Sendai test
% by Huali Zhou @ Acoustics lab, South China University of Technology
% Oct 19, 2020
    
    
    properties(Access = private)
        nSpeechITD; % speech ITD in samples
        nNoiseITD; % noise ITD in samples
%         noise; % audio file of noise 
%         targetRMS;% for keeping the noise level
    end
    
    methods
        function obj = bSRT(para,mainTestObj) %SNR,basicInfo.sncondition,corpusName,closeSetOrNo)
            obj = obj@SRT(para,mainTestObj);
               if nargin > 0
                   obj.nSpeechITD = str2double(regexp(para.condition,'(?<=^\w)\d+(?=\w)','match'));% speech ITD in samples
                   obj.nNoiseITD = str2double(regexp(para.condition,'(?<=\w)\d+(?=\w\>)','match')); % noise ITD in samples
                   obj.noise = ['.\sounds\Noise\Sendai_OLDEN_',para.condition(end),'.wav']; % noise audio file name             
               end   
               obj.data.correctRateArr = [];
             
        end
        
        function [outAudio,outFs] = process_audio(obj,audioFile)
            [inAudio,Fs] = audioread(audioFile);
            % 去掉末尾的0
            index = find(inAudio > 0.001);            
            inAudio = inAudio(1:index(end));
            
            % get current SNR and show on the interface
            SNR = obj.get_and_fresh_snr();
            
            % pick two noise segments as two competetors
            rng('shuffle');
            %L_noise = 364215-0.3*Fs-length(inAudio); % 实际总长度为364215，但为了多留300ms
            if Fs == 16000
                L_noise = 364215 - 16000 * (0.3+length(inAudio)/Fs);
            else % for OLDEN which has fs = 44100
                L_noise = 1242898 - 44100 * (0.3+length(inAudio)/Fs);
            end
            for n = 1: 2
                start = round((rand(1)*0.95+0.02)*L_noise); % start point for reading noise audio
                stop = start + ceil(Fs * (0.3*2+length(inAudio)/Fs));%0.3*2*Fs + length(inAudio);% stop point for reading noise audio
                [temp,noiseFs] = audioread(obj.noise,[start,stop]); % read noise
                if noiseFs ~= Fs % if noise fs is not equal to that of speech
                    rawNoise(:,n) = resample(temp,Fs,noiseFs);
                else
                    rawNoise(:,n) = temp;
                end 
                rawNoise(:,n) = rawNoise(:,n) * obj.mainTestObj.basicInfo.targetRMS/ myRMS(rawNoise(:,n));% rms level adjusted to targetRMS
            end % end of noise segments picking
              
            
            noise = zeros(size(rawNoise));
            
            % noise in one channel is composed of one original noise and
            % one delayed noise(i.e., A+B[n-10],or A[n-10]+B)
            m = [0 obj.nNoiseITD; obj.nNoiseITD 0]; % matrix for delay selection
            idx = randperm(2); % random row index for noise delay selction
            for n = 1: 2% random assign to the left and right channel
                iDelay = idx(n); 
                noise(:,n) = [zeros(m(iDelay,1),1);rawNoise(1:end-m(iDelay,1),1)]+...
                    [zeros(m(iDelay,2),1);rawNoise(1:end-m(iDelay,2),2)]; % one raw noise plus one delayed noise
            end
            
            
            % assign same speech to left and right channels
            speech = [zeros(0.3*Fs,1);inAudio;zeros(0.3*Fs,1)]; % add zeros before and after sound signal to make the speech the same legnth as noise
            speechL = myAddNoise(speech,SNR,noise(:,1),(0.3*Fs+1):(0.3*Fs+length(inAudio)));
            speechR = myAddNoise(speech,SNR,noise(:,2),(0.3*Fs+1):(0.3*Fs+length(inAudio)));
            outAudio = [speechL,speechR];   
            %outAudio = inAudio/(myRMS(inAudio))*obj.mainTestObj.basicInfo.targetRMS;
            outFs = Fs;
            obj.mainTestObj.viewObj.plot_revs([obj.data.snrArr;NaN(20-length(obj.data.snrArr),1)]');
        end
        
         function initialize(obj,para, corpusObj,viewObj)
            set(viewObj.revPanel,'Visible','On');  % show the reversal plot
            corpusObj.set_adapObj(para.snr);
         end

    end
end

