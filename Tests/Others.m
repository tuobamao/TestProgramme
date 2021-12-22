classdef Others < TopTest
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明

properties %(Access = protected)
%     outputObj;
%     subTestObj;
selected;


end
    
    methods
        function obj = Others(basicInfo,para,outputObj, mainViewObj)
            obj = obj@TopTest(basicInfo,para,outputObj, mainViewObj);
%             if nargin >0
%                 fh = str2func(para.testType); % set the sub test type object
%                 obj.subTestObj = fh(basicInfo,para,outputObj, mainViewObj);
%             end
            obj.subTestObj.initialize(); 
        end
        function run(obj)
            obj.subTestObj.run();
            obj.save_result();% 数据保存json文件
        %obj.ongoingFlag = 0;
            close(obj.viewObj.fhandle);
        end
    
    end
end

