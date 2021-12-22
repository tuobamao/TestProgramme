classdef Monosyllable < Quiet
% properties(Hidden)
%     viewObj; % 为了显示反馈信息
% end
    
    methods
        function obj = Monosyllable(~,mainTestObj)
            obj = obj@Quiet();
            obj.data = rmfield(obj.data,'nCorrectArr'); % 此项不适用声调测试，去掉
            if nargin > 0 
                obj.mainTestObj = mainTestObj;
            end
            
        end
        
        function [outAudio,outFs] = process_audio(obj,inAudio,Fs)
            % for speech perception in queit, nothing to do here  
            inAudio(:,1) = inAudio(:,1)/ rms(inAudio(:,1)) * obj.mainTestObj.basicInfo.targetRMS;
           outAudio = [inAudio(:,1),inAudio(:,1)];
           outFs = Fs;
        end
        
        function process_answer(obj,answer,iTrial) 
            answer = find(answer);
            obj.data.answerArr = [obj.data.answerArr; answer];
            correctness = isequal(answer, obj.data.targetArr(iTrial));
            obj.mainTestObj.viewObj.feedback(correctness);
            %obj.data.nCorrectArr = [obj.data.nCorrectArr; sum(answer)];
            obj.data.timeArr = [obj.data.timeArr; datestr(now,'HHMMSS')];
        end
        function result = calculate_result(obj)
            %obj.data.correctArr = (obj.data.answerArr == obj.data.targetArr);
            %obj.data.correctRate = sum(obj.data.correctArr)/numel(obj.data.answerArr)*100;
            
            obj.data.targetArr = obj.data.targetArr(obj.data.targetArr~=3);
            obj.data.correctArr = (obj.data.answerArr == obj.data.targetArr);
            obj.data.correctRate = sum(obj.data.correctArr)/numel(obj.data.answerArr)*100;
            
            result = obj.data.correctRate;
            warndlg(sprintf('恭喜您，测试结束。结果：%.1f',result));
        end
        
        function initialize(obj)
%             set(obj.mainTestObj.viewObj.selButtonArray(3),'Visible','off');
%             obj.mainTestObj.viewObj.selButtonArray(3) = obj.mainTestObj.viewObj.selButtonArray(4);
            obj.data.targetArr = obj.mainTestObj.corpusObj.targetArr;
            obj.data.targetStringArr = obj.mainTestObj.corpusObj.targetStringArr;
%             set(obj.mainTestObj.viewObj.selButtonArray(3),'Visible', 'off');
%             set(obj.mainTestObj.viewObj.selButtonArray,'FontSize',15);
        end
    end
end

