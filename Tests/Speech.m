classdef Speech < TopTest
%     % SpeechTest类，适用于安静条件下的句子识别
%      By Huali Zhou  20200919
% -------------------------------------------------------------------------

properties(Hidden) % for setting color when selected or non-selected   
    colorSel = [0.3882 0.6235 0.949];
    colorNonSel = [0.9400 0.9400 0.9400];
    textArr;
    audioArr;
end
properties %(Access = protected)   
    corpusObj;
end

methods
    function obj = Speech(basicInfo,para,outputObj, mainViewObj)
        obj = obj@TopTest(basicInfo,para,outputObj, mainViewObj);        
        if nargin >0
            %------------set viewObj, corpusObj and subTestObj---------
            obj.corpusObj = Corpus(para);
            obj.corpusObj.randomize();
            switch lower(para.set)
                case 'closed'
                    obj.viewObj = closedSetView(obj);
                case 'open'
                    obj.viewObj = SpeechTestView(obj,obj.corpusObj.btnLayout);
            end
            
            % beep sound            
            [beep.sig, beep.fs] = audioread('.\Sounds\Noise\Biiiiii.wav');
            beep.sig = beep.sig / rms(beep.sig) * obj.basicInfo.targetRMS/4;
            if beep.fs ~= obj.corpusObj.corpusFs 
                beep.sig = resample(beep.sig, obj.corpusObj.corpusFs, beep.fs);
                beep.fs = obj.corpusObj.corpusFs;
            end
            obj.currentOutput.beep = beep;
            
             %-------- test initialization-------------------------------
            [obj.textArr, obj.audioArr] = deal(obj.corpusObj.textArr, obj.corpusObj.audioArr);
            obj.subTestObj.initialize(para, obj.corpusObj,obj.viewObj);  
            
            obj.currentOutput.viewObj = obj.viewObj;
            
             %--------set data to be saved in the records----------------
            obj.mainTestData.textArr = obj.textArr;
        end
    end 
    
    function run(obj)
        obj.ongoingFlag = 1;
        if isprop(obj.viewObj,'nextButton'),set(obj.viewObj.nextButton,'Enable','on');end
        for iTrial = 1:size(obj.audioArr,1)
            try
                set(obj.viewObj.progressText,'String',sprintf('当前第%d，共%d',iTrial,size(obj.audioArr,1)));
                [outAudio,outFs] = obj.subTestObj.process_audio(obj.audioArr(iTrial,:));
                obj.currentOutput.audio.sig = outAudio;
                obj.currentOutput.audio.fs = outFs;
                obj.currentOutput.text = obj.textArr(iTrial,:);
                obj.outputObj.output(obj.currentOutput);
                uiwait(obj.viewObj.fhandle);  
                answer = obj.viewObj.get_answer();
                obj.subTestObj.process_answer(answer);
                set(obj.viewObj.selButtonArray,'BackgroundColor',obj.colorNonSel,'UserData',0);
            catch
                warning('程序已关闭');
                return;
            end
        end
        obj.save_result();% 数据保存json文件
        obj.ongoingFlag = 0;
        close(obj.viewObj.fhandle);
    end
end 
end
    






