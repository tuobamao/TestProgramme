classdef corpusAdapProc < handle
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
         steps;
        nRevEachStep;% how many reversals the steps are used. ...
        value;
        corpusObj;
        answerArr;
    end
    
    methods
        function obj = corpusAdapProc(steps,nRevEachStep,value,corpusObj)
            obj.steps = steps;
            obj.nRevEachStep = nRevEachStep;            
            obj.value = value;
            obj.corpusObj = corpusObj;
        end
        function isCorrect = checkIsCorrect(obj,answerArr)
            obj.answerArr = answerArr;
            isCorrect = (sum(answerArr) / length(answerArr)) >= obj.corpusObj.correctSpec;
        end
        function nextValue = next(obj)
            obj.value = obj.value + change * obj.steps(obj.stage);
            obj.valueAtTrials = circshift(obj.valueAtTrials, -1); %左移一位
            obj.valueAtTrials(end) = obj.value; %保存反转点的value
            obj.meanLast = mean(obj.valueAtTrials);
        end

    end
end

