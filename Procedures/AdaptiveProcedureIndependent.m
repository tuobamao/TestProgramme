classdef AdaptiveProcedureIndependent < AdaptiveProcedure
    % this class is designed for nD1U adaptive procedure.
    % e.g.,
    % a = AdaptiveProcedureSpeech([8 4 2],[2 2 9],2,250, 13, 6, 13.5) for
    % tasks such as pitch ranking 
    % a.next(1);
    
     properties
        geomeanLast; % 20200925新增计算结果
        stdLast; % 20200925新增计算结果
        
        nRevs; % 默认做13个反转点
        nLastRevs; % 依据最后多少个反转点的方差提前结束
        stdSpec;
        
        % parameters that will be calculated in methods
        valueAtRevs;
        continueFlag = 1;

    end
    
    methods
        function obj = AdaptiveProcedureIndependent(steps,nRevEachStep,nD1U,value, nRevs,nLastRevs, stdSpec)
            obj = obj@AdaptiveProcedure(steps,nRevEachStep,nD1U,value); % set parameters of universal adaptive procedure
            if nargin > 0  % set parameters unique for adaptive procedure with limited reversals and earlier stop
                obj.nRevs = nRevs; % total number of reversals ,eg. 13
                obj.nLastRevs = nLastRevs; % if the std of n Last Reversals gets below the spec(below) the procedure stops
                obj.stdSpec = stdSpec; % spec of std of n Last Reversals
                obj.valueAtRevs = NaN(1, obj.nRevs); % for storing the values at each reversal
            end            
        end
      
        function get_next_value(obj,change,~) % to be called by the method next defined in supper class Adaptive procedure
            % This function takes the answers of each trial, and decide the
            % next step.
            if obj.isReversal == 1 % if this is a reversal
                obj.valueAtRevs = circshift(obj.valueAtRevs, -1); 
                obj.valueAtRevs(end) = obj.value; %保存反转点的value
                if numnan(obj.valueAtRevs) <= obj.nRevs - obj.nLastRevs % 若以有6个以上反转点
                    obj.geomeanLast = geomean(obj.valueAtRevs(end-obj.nLastRevs+1:end));
                    obj.stdLast = std(obj.valueAtRevs(end-obj.nLastRevs+1:end));
                    if obj.stdLast <= obj.stdSpec % 则判断最后6个的方差是不是小于某一spec
                        obj.continueFlag = 0; % 若小于，则提前结束
                        return;
                    end
                end
            end
            if obj.nRevs <= sum(obj.reversals) % 若达到了要求的总反转点数
                obj.geomeanLast = geomean(obj.valueAtRevs(end-obj.nLastRevs+1:end));
                obj.stdLast = std(obj.valueAtRevs(end-obj.nLastRevs+1:end));
                obj.continueFlag = 0; % set flag to 0 to stop the test
            else
                obj.value = obj.value *( 10^(change * obj.steps(obj.stage)/20)); %调整value
            end
        end  
    end
end
