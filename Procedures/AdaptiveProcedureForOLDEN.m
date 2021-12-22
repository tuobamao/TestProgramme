classdef AdaptiveProcedureForOLDEN < AdaptiveProcedure
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        tar = 0.5; % 50% intelligibility level
        snrArr; % all the SNRs in a run
        rateArr; % all the recognition rates in a run
        meanLast; % the final SRT, to fit the previous code

    end
    
    methods
        function obj = AdaptiveProcedureForOLDEN(initValue)
            %UNTITLED 构造此类的实例
            %   此处显示详细说明
            obj = obj@AdaptiveProcedure();
            obj.nD1U = 1;
            obj.value = initValue;
            obj.snrArr = NaN(1,20);
            obj.rateArr = NaN(1,20);
        end
        
        function get_next_value(obj,~,prev)
            % This function takes the answers of each trial, and decide the
            % next step.
            % store the SNR and recognition rate
            obj.snrArr = [obj.snrArr(1,2:end),obj.value];
            obj.rateArr = [obj.rateArr(1,2:end),prev];
            
            % calculate next snr using the formula
            nRevs = sum(obj.reversals);
            if nRevs > 5
                nRevs = 5.28;
            end
            obj.value = obj.value - 1.5/(1.41.^(nRevs))*(prev - obj.tar)/0.1; % formula for delta L
              
            % calculate SRT at the last trial
            if ~any(isnan(obj.snrArr))
                x = obj.snrArr; % SNRs in a run
                y = obj.rateArr; % recognition rates in a run
                c=[0.01 mean(x(end-7:end))]; % initial value: slope at sweetpoint:0.01, SRT: mean of the last 8 sentence
                fun = inline('1./(1+exp(4*c(1)*(c(2)-x)))','c','x'); % fitting modal
                b = nlinfit(x,y,fun,c); % non linear fitting, b(1):slope, b(2):SRT
                figure; t = -20:0.01:20; plot(x,y,'r.',t,fun(b,t));
                obj.meanLast = b(2); % store the calculated SRT in the meanLast property
            end
            
        end
    end
end

