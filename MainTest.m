 classdef MainTest < handle
    % This class serves a test platform for several psychoacoustic tests.
    % This code is a revised version of the speech intelligibility test code from
    % Qinglin Meng @ Acoustics Lab,South China University of Technology.
    % Author: Huali Zhou
    % Date: Jan 15, 2021
    % related resources:the GUI Layout Toolbox and Financial Toolbox
    % Usage: just run
    % Version 2.0
    
    properties
        GUIObj; % handles to the function uicontrols;
    end
    
    methods
        function obj = MainTest()
            add_path();
            obj.GUIObj = MainView();
            set(findobj('Tag','Run'),'Callback',@(src, event)RunTest(obj, src, event));
        end
    end

    methods(Access = private)
        function obj = RunTest(obj, ~, ~)
            [basicInfo, para,outputObj] =  obj.GUIObj.get_info_para_output();
           fh = str2func(para.module);
           fh(basicInfo, para, outputObj,obj.GUIObj);
        end
    end
    
end

%% supporting functions
function add_path()
addpath '.\Interfaces\';
addpath '.\Procedures\';
addpath '.\Sounds\';
addpath '.\SoundObjects\';
addpath '.\Tests\';
addpath '.\vocoder\';
addpath '.\Vocoder\haptic\';
addpath '.\CommonFunctions\';
% addpath '.\History\';
addpath('CCiMobile Code\CCiMobileTools');
addpath('.\CCiMobile Code\CCiMobileTools\Strategies');
addpath('.\CCiMobile Code\CCiMobileTools\CommonFunctions');
end



