classdef FixedSNR < SubTest
% This class is designed to for speech percetption in noise with fiexed SNR.
%
% by Huali Zhou @ Acoustics lab, South China University of Technology
% Sep 27, 2020
    
    properties(Access = protected)
        noise;
        SNR;
    end
    
    methods
        function obj = FixedSNR(para,mainTestObj)
            obj = obj@SubTest(); 
            if nargin > 0
                obj.mainTestObj = mainTestObj;
                obj.SNR = para.snr;
            end
            obj.data.correctRate = [];
            obj.data.answerArr = [];
            obj.data.nCorrectArr = [];
            obj.data.timeArr = [];
        end
        
        function [outAudio,outFs] = process_audio(obj,audioFile)
            [inAudio,Fs] = audioread(audioFile);
            outAudio = myAddNoise(inAudio,obj.SNR,obj.noise,0);
            outFs = Fs;
        end
        
        function process_answer(obj,answer) 
            obj.data.answerArr = [obj.data.answerArr; answer];
            obj.data.nCorrectArr = [obj.data.nCorrectArr; sum(answer)];
            sum(obj.data.nCorrectArr)
            obj.data.timeArr = [obj.data.timeArr; datestr(now,'HHMMSS')];
        end
        function result = calculate_result(obj)
            obj.data.correctRate = sum(obj.data.nCorrectArr)/numel(obj.data.answerArr)*100;
            result = obj.data.correctRate;
            msgbox(sprintf('恭喜您，测试结束，正确率%d',result));
        end
        function initialize(obj, para, ~,viewObj)
            set(viewObj.paraText,'String', sprintf('信噪比 %d dB',(round(obj.SNR,1))));% show current SNR on the figure
            if isfield(para,'noise')% bSRT will not have noiseType
                if contains(para.corpus,'_')
                    corpus = para.corpus(1:strfind(para.corpus,'_')-1);
                end
                fName = ['.\Sounds\Noise\',para.noise,'-',corpus,'.wav'];
                [obj.noise,~] = audioread(fName);
                obj.noise = obj.noise * para.targetRMS/ myRMS(obj.noise);
            end
        end
    end
end

