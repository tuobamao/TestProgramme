classdef constantStimuli < handle
    %this class is designed for the control of the constant stimuli
    %procedure
    
    properties
        seqTable; % generated overall sequence table
        nRepeat = 1 ; % default not to repreat
    end
    
    methods
        function obj = get_seqTable(obj, varargin)
            nVariable = numel(varargin); 
            nCombination = prod(cell2mat(varargin)); 
                obj.seqTable = zeros(nCombination * obj.nRepeat,nVariable);
                for iRepeat = 1:obj.nRepeat
                    for n=1:nVariable %生成数字排列组合
                        obj.seqTable((iRepeat-1)*nCombination+(1:nCombination),n) = repmat(repelem((1:varargin{n})',prod(cell2mat(varargin(n+1:end))),1), prod(cell2mat(varargin(1:n-1))),1);
                    end
                obj.seqTable((iRepeat-1)*nCombination+(1:nCombination),:) = obj.seqTable((iRepeat-1)*nCombination+randperm(nCombination),:); % 顺序随机化
                end

        end 

  
    end
end

