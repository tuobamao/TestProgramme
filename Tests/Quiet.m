classdef Quiet < SubTest
% This class is designed to for speech percetption in quiet.
%
% by Huali Zhou @ Acoustics lab, South China University of Technology
% Sep 27, 2020

    methods    
        function obj = Quiet(~,mainTestObj)            
            if nargin > 0
                obj.mainTestObj = mainTestObj; 
            end
        end
        
        function [outAudio,outFs] = process_audio(obj,audioFile)
            [inAudio,Fs] = audioread(audioFile);
            % for speech perception in queit, nothing to do here  
%             if contains(audioFile,'LTone')
%                 % LTone处理时先rms调到0.05再处理
%             else
%                 %inAudio = inAudio / rms(inAudio) * obj.mainTestObj.para.targetRMS;
%                 inAudio = inAudio / rms(inAudio) * 0.05;
%             end
            inAudio = inAudio / rms(inAudio) * obj.mainTestObj.para.targetRMS;
           outAudio = inAudio;
           outFs = Fs;
        end
   
        function process_answer(obj,answer) 
            obj.data.answerArr = [obj.data.answerArr; answer];            
            obj.data.rateArr = [obj.data.rateArr; sum(answer)/numel(answer)];
            obj.data.nCorrectArr = [obj.data.nCorrectArr; sum(answer)];
            obj.data.timeArr = [obj.data.timeArr; datestr(now,'HHMMSS')];
        end
        function result = calculate_result(obj)
            obj.data.correctRate = sum(obj.data.nCorrectArr)/numel(obj.data.answerArr)*100;
            result = obj.data.correctRate;
            msgbox(sprintf('恭喜您，测试结束，正确率%d',obj.data.correctRate));
        end
        function initialize(obj, para, corpusObj,viewObj)
            obj.data.correctRate = [];
            obj.data.answerArr = [];
            obj.data.nCorrectArr = [];
            obj.data.timeArr = [];
            obj.data.rateArr = [];
        end
    end
end




