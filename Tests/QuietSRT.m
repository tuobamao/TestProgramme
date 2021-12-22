classdef QuietSRT < SRT
% This class is designed to for adaptive SRT in quiet test.
% The aim of this test is to find the miminum hearing threshold using
% speech material, just like the pure tone threshold in clinical audiology.
% by Huali Zhou @ Acoustics lab, South China University of Technology
% Nov 20, 2020
    
    properties
        calFactor ; % factor to convert rms to spl
    end
%     properties(Access = private)
%         procedureObj; % the procedure object 
%         correctSpec = 0.7; % 答对多少才算这句话听懂了
%         viewObj;
%     end
    
    methods
        function obj = QuietSRT(para,mainTestObj)
            spl = para.inispl;
            para = rmfield(para,'inispl');
            para.snr = spl;
            obj = obj@SRT(para,mainTestObj);
            obj.calFactor = 10^(para.calispl/20)./para.targetRMS;
            obj.data = rmfield(obj.data,'snrArr');
            obj.data.splArr = [];
        end
    
        
        function [outAudio,outFs] = process_audio(obj,audioFile)
            [inAudio,Fs] = audioread(audioFile);            
            spl = obj.mainTestObj.corpusObj.adapObj.currentLevel; % get current SNR; % get current SNR
            obj.data.splArr = [obj.data.splArr; spl];
            set(obj.mainTestObj.viewObj.paraText,'String', sprintf('当前声级 %d dB SPL',(round(spl,1))));
            outAudio = inAudio/myRMS(inAudio)*10^(spl/20)/obj.calFactor;  % 改变语音的SNR
            outFs = Fs;    
            obj.mainTestObj.viewObj.plot_revs([obj.data.splArr;NaN(20-length(obj.data.splArr),1)]');
        end
        
         function initialize(obj,para, corpusObj,viewObj)
            set(viewObj.revPanel,'Visible','On');  % show the reversal plot
            corpusObj.set_adapObj(para.inispl);
         end
    end
end

