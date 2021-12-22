classdef ITD_sensitivity < CommonTest
    %UNTITLED2 此处显示有关此类的摘要
    %   此处显示详细说明
    properties(Hidden) % for setting color when selected or non-selected
%         currentAudio;  % 用于重播
%         currentFs;
        rawAudio;
        rawFs;
        selected;
        sampleSet;
    end
    properties
%         basicInfo;
%         para;
%         outputObj;
%         mainViewObj; % for history refresh
        viewObj;
        sampleMtrx;
        selArr;
        answerArr;
%         data; % 保存数据
%         ongoingFlag; % 1:running test not ended
    end
    
    methods
        function obj = ITD_sensitivity(basicInfo,para,outputObj, mainViewObj)
            obj = obj@CommonTest(basicInfo,para,outputObj, mainViewObj);
            if nargin > 0
%                 obj.basicInfo = basicInfo; % pass basic info
%                 obj.para = para;
%                 obj.outputObj = outputObj;% set outputObj
%                 obj.mainViewObj = mainViewObj;
                obj.viewObj = commonView(obj, [1 2]);
                obj.viewObj.set_instruction('请选择你认为第二个声音相对第一个声音的位置');
                set(obj.viewObj.selButtonArray(1),'String','左边_1'); % 正数表示左边
                set(obj.viewObj.selButtonArray(2),'String','右边_2');% 负数表示右边
                obj.sampleSet = [obj.para.samples; -obj.para.samples];
                sampleArr = repmat(obj.sampleSet, obj.para.nrepeat,1);
                rng('shuffle');
                sampleArr = sampleArr(randperm(numel(sampleArr)));
                obj.sampleMtrx = [zeros(size(sampleArr)), sampleArr];
                audioName = '.\Sounds\Noise\itdnoise.wav';
                [obj.rawAudio, obj.rawFs] = audioread(audioName);
                obj.currentAudio{1} = [obj.rawAudio(:),obj.rawAudio(:)];
                obj.currentFs = obj.rawFs;
                obj.selArr = [];
                obj.answerArr = [];
%                 obj.data = struct();
            end
        end
        
        function run(obj)
            obj.ongoingFlag = 1; % 1:running test not ended
            trialN = obj.para.nrepeat * 2;
            for n = 1:trialN
                itdSample = obj.sampleMtrx(n, 2);
                temp = [zeros(abs(itdSample),1); obj.rawAudio(1:end-abs(itdSample))];
                
                if itdSample > 0 % 左
                    obj.currentAudio{2} = [obj.rawAudio, temp];
                else %右
                    obj.currentAudio{2} = [temp, obj.rawAudio];
                end
                obj.viewObj.refresh('',obj.currentAudio{1},obj.currentFs);
                obj.outputObj.output(obj.currentAudio{1},obj.currentFs);
                
                pause(2);
                obj.outputObj.output(obj.currentAudio{2},obj.currentFs);
                
                uiwait(obj.viewObj.fhandle);
                answer = (itdSample == obj.sampleSet(obj.selected));
                set(obj.viewObj.feedbackButton,'BackgroundColor',[1-answer,answer,0]);
                obj.selArr = [obj.selArr, obj.sampleSet(obj.selected)];
                obj.answerArr = [obj.answerArr, answer];
                obj.viewObj.set_instruction(sprintf('请选择你认为第二个声音相对第一个声音的位置,已完成%d\\%d',n,trialN));
             
            end
            obj.ongoingFlag = 0;
            obj.data.sampleMtrx = obj.sampleMtrx;
            obj.data.selArr = obj.selArr;
            obj.data.answerArr = obj.answerArr;
            obj.data.result = obj.calculate_result();
            obj.data.result_left = sum(obj.answerArr(obj.sampleMtrx(:,2) == obj.para.samples))/obj.para.nrepeat*100;
            obj.data.result_right = sum(obj.answerArr(obj.sampleMtrx(:,2) == -obj.para.samples))/obj.para.nrepeat*100;
            msgbox(sprintf('总正确率%d\\%d ',sum(obj.answerArr),trialN));
            obj.save_result();
            close(obj.viewObj.fhandle);%obj.endprocedureObj;
            delete(obj.viewObj);
            delete(obj);
            return;
        end
        
        
        
        
        function replay(obj)
            obj.outputObj.output(obj.currentAudio{1},obj.currentFs);
            pause(1);
            obj.outputObj.output(obj.currentAudio{2},obj.currentFs);
        end
        
        function result = calculate_result(obj)
            result = sum(obj.answerArr)/(obj.para.nrepeat * 2)*100;
        end
        
    end
end

