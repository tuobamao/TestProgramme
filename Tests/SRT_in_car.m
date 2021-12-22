classdef SRT_in_car <  SRT
    % This class is specially written for a collaborative work with Dr. Linda Liang
    %  Huali Zhou @ Acoustics Lab, SCUT, May 30, 2021
 
    properties(Hidden)
        targetBrir;
        brirFs;
    end
    
    methods
        function obj = SRT_in_car(para,mainTestObj)
            obj = obj@SRT(para,mainTestObj);
        end
        
         function [outAudio,outFs] = process_audio(obj,audioFile)
            [inAudio,Fs] = audioread(audioFile);
            % 有的句子末尾有些纯0，太长影响信噪比计算，去掉末尾的0
            index = find(inAudio > 0.001);            
            inAudio = inAudio(1:index(end));
            
            % 根据信噪比调制目标声rms：以targetRMS为基准（原始噪声信号rms也已经调制到了targetRMS）
            SNR = obj.get_and_fresh_snr();
            inAudio = inAudio / myRMS(inAudio)* obj.mainTestObj.para.targetRMS *10^(SNR/20);  % 噪声的level不变，改变语音的level
            
            %卷积产生目标声方向            
            binauralSpeech(:,1) = conv(inAudio, obj.targetBrir(:,1));
            binauralSpeech(:,2) = conv(inAudio, obj.targetBrir(:,2));
            
            % 加噪声
            binauralNoise = obj.noise(1:length(binauralSpeech),:);
            outAudio = binauralSpeech + binauralNoise;
            outFs = Fs;
         end
         
         function initialize(obj, para, corpusObj,viewObj)
             %set(viewObj.revPanel,'Visible','On');  % show the reversal plot
             para.corpusFs = corpusObj.corpusFs;
             corpusObj.set_adapObj(para.snr);
             [obj.targetBrir, obj.brirFs, obj.noise] = initialize_in_car(para);
         end
    end
        
   
end

