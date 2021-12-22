classdef SRT < SubTest
% This class is designed to for adaptive SRT test.
%
% by Huali Zhou @ Acoustics lab, South China University of Technology
% Sep 27, 2020

%     properties(Access = private)
%         
%     end
    properties(Access = protected)
        procedureObj; % the procedure object 
        correctSpec = 0.7; % 答对多少才算这句话听懂了
        noise;
       % noiseFs;
    end
    
    methods
        function obj = SRT(para,mainTestObj)
            obj = obj@SubTest();
            if nargin > 0
                obj.mainTestObj = mainTestObj;
                
                obj.data.srt = [];
                obj.data.snrArr = [];
                obj.data.answerArr = [];
                obj.data.nCorrectArr = [];
                obj.data.correctnessArr = [];
                obj.data.isRevArr = [];
                obj.data.timeArr = [];
            end
        end
        
        function [outAudio,outFs] = process_audio(obj,audioFile)
            [inAudio,Fs] = audioread(audioFile);
            % 去掉末尾的0
            index = find(inAudio > 0.001);            
            inAudio = inAudio(1:index(end));
            
            % 根据信噪比加噪声
            SNR = obj.get_and_fresh_snr();
            outAudio = myAddNoise(inAudio,SNR,obj.noise,0);
            outFs = Fs;           
        end
        
        function process_answer(obj,answer) 
            if isa(obj.mainTestObj.viewObj,'closedSetView')
                target = obj.mainTestObj.audioArr(size(obj.data.answerArr,1)+1,end-8:end-4);
                for n= 1:5
                    answer(n) = isequal(str2double(target(n)),answer(n));
                end
            end
            obj.data.answerArr = [obj.data.answerArr; answer];
            answer
            obj.data.nCorrectArr = [obj.data.nCorrectArr; sum(answer)];            
            obj.mainTestObj.corpusObj.next_level(answer);
            obj.data.isRevArr = [obj.data.isRevArr; obj.mainTestObj.corpusObj.adapObj.isReversal];
            obj.data.timeArr = [obj.data.timeArr; datestr(now,'HHMMSS')];
        end
        
        function result = calculate_result(obj)
            obj.data.srt = obj.mainTestObj.corpusObj.calculate_adap_mean();
            obj.data.correctnessArr = obj.mainTestObj.corpusObj.correctnessArr;
            result = obj.data.srt;      
            msgbox(sprintf('恭喜您，测试结果，结果%.2f',result));
        end
        
        function initialize(obj, para, corpusObj,viewObj)
            %set(viewObj.revPanel,'Visible','On');  % show the reversal plot
            corpusObj.set_adapObj(para.snr); % set initial level for the adaptive procedure
            
            % load noise file, resample to match speech material, and set to a fixed level
            if contains(para.corpus,'_')
                para.corpus = para.corpus(1:strfind(para.corpus,'_')-1);
            end
            fName = ['.\Sounds\Noise\',para.noise,'-',para.corpus,'.wav'];
            [obj.noise,noiseFs] = audioread(fName);            
            speechFs = corpusObj.corpusFs;
            if noiseFs ~= speechFs
                obj.noise = resample(obj.noise, speechFs, noiseFs);
            end
           % obj.noise = obj.noise / myRMS(obj.noise) * para.targetRMS/2; %设为targetRMS时LTone会超幅度，所以将噪声调小
          obj.noise = obj.noise / myRMS(obj.noise) * para.targetRMS;
        end
        
        function SNR = get_and_fresh_snr(obj)
            SNR = obj.mainTestObj.corpusObj.adapObj.currentLevel; % get current SNR
            obj.data.snrArr = [obj.data.snrArr; SNR];
            
            obj.mainTestObj.viewObj.plot_revs([obj.data.snrArr;NaN(20-length(obj.data.snrArr),1)]');
            set(obj.mainTestObj.viewObj.paraText,'String', sprintf('信噪比 %.1f dB',(round(SNR,1))));%num2str(obj.SNR)); % show current SNR on the figure
        end
    end
end

