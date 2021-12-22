classdef AdaptiveProcedureWithCorpus < AdaptiveProcedure
    %UNTITLED3 此处显示有关此类的摘要
    %   此处显示详细说明
    properties(Hidden)
        corpusObj;
    end
    properties
        valueAtTrials; % the value for each sentence
        nLastTrials = 8; 
        meanLast;
    end
    
    methods
        function obj = AdaptiveProcedureWithCorpus(steps,nRevEachStep,nD1U,value,corpusObj)
            obj = obj@AdaptiveProcedure(steps,nRevEachStep,nD1U,value,corpusObj);
            obj.valueAtTrials = NaN(1,obj.nLastTrials);
%             if nargin > 0
%                 obj.corpusObj = corpusObj;
%             end
        end
        
        function get_next_value(obj,change,~)
            % This function takes the answers of each trial, and decide the
            % next step.           
            obj.value = obj.value + change * obj.steps(obj.stage);
            obj.valueAtTrials = circshift(obj.valueAtTrials, -1); %左移一位
            obj.valueAtTrials(end) = obj.value; %保存反转点的value
            obj.meanLast = mean(obj.valueAtTrials);
        end
    end
end

