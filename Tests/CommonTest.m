classdef CommonTest < handle
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
properties(Hidden) % for setting color when selected or non-selected
        currentAudio;  % 用于重播
        currentFs;
    end
    properties
        basicInfo;
        para;
        outputObj;
        mainViewObj; % for history refresh    
        data; % 保存数据
        ongoingFlag; % 1:running test not ended
    end
    
    methods
        function obj = CommonTest(basicInfo,para,outputObj, mainViewObj)
            if nargin > 0
                obj.basicInfo = basicInfo; % pass basic info
                obj.para = para;
                obj.outputObj = outputObj;% set outputObj
                obj.mainViewObj = mainViewObj;                
                obj.data = struct();
            end
        end
        
        function save_result(obj)
            % 在测试历史表格中增加一个记录
            result = obj.calculate_result;
            newRecord = {obj.para.testType,obj.basicInfo.name,obj.basicInfo.fname,result};
            obj.mainViewObj.refresh_history(newRecord);
            % 数据保存json文件
            currentResultsDir = ['.\Records\',obj.para.testType,'\',obj.basicInfo.name,'\'];
            if ~isfolder(currentResultsDir), mkdir(currentResultsDir); end
            fileName = [currentResultsDir,obj.basicInfo.fname, '.json'];
            data.basicInfo = obj.basicInfo;
            data.testPara = obj.para;
            data.progressData = obj.data;
            savejson('', data, 'FileName',fileName,'CompressStringSize',2000);
            warndlg(sprintf('恭喜您，测试结束。结果：%.1f',result));
        end
        
    end
    
    methods(Abstract)
         result = calculate_result(obj);
         replay(obj);
end
end

