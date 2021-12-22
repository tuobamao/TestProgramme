classdef TopTest < handle
    % This class defines some general properties and methods for all tests
    %   此处显示详细说明
    
properties(Hidden) % for setting color when selected or non-selected   
%     currentAudio;  % 用于重播
%     currentFs;
      currentOutput = struct(); % 用于输出和重播
%     textArr;
%     audioArr;
end
properties %(Access = protected)
    outputObj;
    subTestObj;
    viewObj ; % the interface object，
    mainViewObj; % for history refresh
    basicInfo;
    para;
    ongoingFlag; % 1:running test not ended
    mainTestData = struct(); % for saving in records，to be set in detailed tests
end

methods
    function obj = TopTest(basicInfo,para,outputObj, mainViewObj)
        if nargin >0
            obj.basicInfo = basicInfo; % pass basic info
            obj.para = para;
            obj.outputObj = outputObj;% set outputObj
            obj.mainViewObj = mainViewObj;
            fh = str2func(para.testType); % set the sub test type object
            obj.subTestObj = fh(para,obj);            
        end
    end 
    

    function save_result(obj)
        % 在测试历史表格中增加一个记录
        result = obj.subTestObj.calculate_result;
        newRecord = {obj.para.testType,obj.basicInfo.name,obj.basicInfo.fname,result};
        obj.mainViewObj.refresh_history(newRecord);
        % 数据保存json文件
        currentResultsDir = ['.\Records\',obj.para.testType,'\',obj.basicInfo.name,'\'];
        if ~isfolder(currentResultsDir), mkdir(currentResultsDir); end
        fileName = [currentResultsDir,obj.basicInfo.fname, '.json'];
        data.basicInfo = obj.basicInfo;
        data.testPara = obj.para;
        data.progressData = obj.subTestObj.data;
        data.mainTestData = obj.mainTestData;
        savejson('', data, 'FileName',fileName,'CompressStringSize',2000);
        %warndlg(sprintf('恭喜您，测试结束。结果：%.1f',result));
    end
    
    function replay(obj)
        obj.outputObj.output();    
    end

end 

methods(Abstract)
    run(obj)
end


end
    

