classdef AdaptiveProcedure < handle
    % this class is designed for nD1U adaptive procedure.
   
     properties        
        steps;
        nRevEachStep;% how many reversals the steps are used. ...
        nD1U;
        
        levelArr;
        
        currentLevel;
        answers = [];
        isReversal;
        stage;
        reversals;
        
        
        tar = 0.5; % 50% intelligibility level
        snrArr; % all the SNRs in a run
        rateArr; % all the recognition rates in a run
        meanLast; % the final SRT, to fit the previous code
        
     end
    properties(Hidden)
        nextObj;
    end
    
    methods
        function obj = AdaptiveProcedure(steps,nRevEachStep,nD1U,value)
            if nargin > 0 % basic info universal of adaptive procedure
                obj.steps = steps;
                obj.nRevEachStep = nRevEachStep;
                obj.nD1U = nD1U;
                obj.currentLevel = value;
%                 if nargin > 4
%                     obj.nextObj = corpusAdapProc(steps,nRevEachStep,value,corpusObj);
%                 else
%                     obj.nextObj = independentAdapProc(steps,nRevEachStep,value);
%                 end
            end
        end
      
        function next(obj,answer)
            isCorrect = obj.nextObj.checkIsCorrect(answer);
            [change, isReversal] = obj.check_change_reversal(isCorrect);
            obj.nextObj.next(answer);
            % This function takes the answers of each trial, and decide the
            % next step.
            %obj.answers = [obj.answers; answer];
            
            
%             if exist('prev')
               % obj.get_next_value(change,prev); % call the abstract method defined in sub classes
               %obj.get_next_value(change,answer); % call the abstract method defined in sub classes
%             else
%                 obj.get_next_value(change)
%             end
            
            
        end % end of functin next    
    end % end of methods
    methods
        function [change] = check_change_reversal(obj, isCorrect)
            obj.answers = [obj.answers; isCorrect];
            [changes, reversals] = deal(zeros(1,size(obj.answers,1))); %preallocate change log
            
            tempanswers = obj.answers;
            %calculate how many corrects(1) between each incorrect(0) and the previous incorrect
            %计算每一个打错的试次号，取负，再连加，以便得到每两次打错之间，都连续答对了几次
            tempanswers(tempanswers(:,1)==0,1) = 1-diff([0;find(tempanswers(:,1)==0)]);
            tally = cumsum(tempanswers,1);%determine length of runs of same answers
            tally(tally==0) = NaN; %replace zeros with NaN. 显示累计正确几次
            
            % 每答对nD1U次就要降一次value, 每答错一次就要升一次dalta
            changes(mod(tally(:,1),obj.nD1U)==0) = -1;%mod by rules(1) to find decrements (==0)
            changes(obj.answers==0) = 1; %每答错一次就要升一次dalta
            change = changes(end); %this is the sign of the needed change, if any
            
            % 计算反转点：
            changes = [changes;1:length(changes)]; %create trial index
            changes(:,changes(1,:)==0) = []; %remove points of no change
            if ~isempty(changes),changes(:,diff([changes(1,1),changes(1,:)])==0) = [];end %remove points of no difference in change
            reversals(changes(2,:)) = 1; %set reversal points to 1,
            reversals(1) = 0; %the first trial cannot be a reversal; set to 0.
            obj.reversals = reversals;
            obj.stage = find(cumsum(obj.nRevEachStep)>sum(reversals),1); %用来判断接下来用第几个步长
            %fprintf(num2str(sum(reversals)));
            
            if reversals(end)==1 % 判断是否是反转点，假如是个反转点，则保存反转点的value
                obj.isReversal = 1;
            else
                obj.isReversal = 0;
            end % end of 反转点判断
        end
        
        function nextLevel_for_OLDEN(obj,prev)
            obj.snrArr = [obj.snrArr; obj.currentLevel];
            obj.rateArr = [obj.rateArr; prev];
            
           nRevs = sum(obj.reversals);
            if nRevs > 5
                nRevs = 5.213;%20210612利用22组实际测得的数据计算得出
            end
            obj.currentLevel = obj.currentLevel - 1.5/(1.41.^(nRevs))*(prev - obj.tar)/0.1; % formula for delta L
             obj.levelArr = [obj.levelArr; obj.currentLevel];
        end
        
        function srtOLDEN = get_OLDEN_result(obj)
            x = obj.snrArr; % SNRs in a run
            y = obj.rateArr; % recognition rates in a run
            c=[0.01 mean(x(end-7:end))]; % initial value: slope at sweetpoint:0.01, SRT: mean of the last 8 sentence
            fun = inline('1./(1+exp(4*c(1)*(c(2)-x)))','c','x'); % fitting modal
            b = nlinfit(x,y,fun,c); % non linear fitting, b(1):slope, b(2):SRT
%             figure; 
%             t = -20:0.01:20; 
%             plot(x,y,'r.',t,fun(b,t));
            srtOLDEN = b(2); % store the calculated SRT in the meanLast property
            
        end
        
        function nextLevel_for_corpus(obj,change)
            obj.currentLevel = obj.currentLevel + change * obj.steps(obj.stage);            
            obj.levelArr = [obj.levelArr; obj.currentLevel];           
        end
        function nextLevel_for_independent(obj)
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
    
    
%     methods(Abstract)
%         get_next_value(obj);
%     end
end
