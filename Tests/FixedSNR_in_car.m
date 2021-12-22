classdef FixedSNR_in_car < FixedSNR
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties(Hidden)
        targetBrir;
        brirFs;
    end
    
    methods
        function obj = FixedSNR_in_car(para,mainTestObj)
            obj = obj@FixedSNR(para,mainTestObj);
            if nargin > 0
                
            end
        end
        
        function initialize(obj, para, corpusObj,viewObj)
            set(viewObj.paraText,'String', sprintf('信噪比 %d dB',(round(obj.SNR,1))));% show current SNR on the figure
            para.corpusFs = corpusObj.corpusFs;
            [obj.targetBrir, obj.brirFs, obj.noise] = initialize_in_car(para);
        end
        
        function [outAudio,outFs] = process_audio(obj,audioFile)
             [inAudio,Fs] = audioread(audioFile);
            % 有的句子末尾有些纯0，太长影响信噪比计算，去掉末尾的0
            index = find(inAudio > 0.001);            
            inAudio = inAudio(1:index(end));
            
            % 根据信噪比调制目标声rms：以targetRMS为基准（原始噪声信号rms也已经调制到了targetRMS）
            inAudio = inAudio / myRMS(inAudio)* obj.mainTestObj.para.targetRMS *10^(obj.SNR/20);  % 噪声的level不变，改变语音的level
            
            %卷积产生目标声方向            
            binauralSpeech(:,1) = conv(inAudio, obj.targetBrir(:,1));
            binauralSpeech(:,2) = conv(inAudio, obj.targetBrir(:,2));
            
            % 加噪声
            binauralNoise = obj.noise(1:length(binauralSpeech),:);
            outAudio = binauralSpeech + binauralNoise;
            outFs = Fs;
        end
        
    end
end

