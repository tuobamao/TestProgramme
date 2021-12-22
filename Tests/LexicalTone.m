classdef LexicalTone < TopTest
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties(Hidden)
        selected;
        textArr;
        audioArr;
        corpusObj;
    end    

    
    methods
        function obj = LexicalTone(basicInfo,para,outputObj, mainViewObj)
            obj = obj@TopTest(basicInfo,para,outputObj, mainViewObj);              
            if nargin >0
                %------------set viewObj and corpusObj----------------------
                obj.para.name = basicInfo.name;% 双音节测试需要姓名信息来生成测试顺序表
                fh = str2func(para.corpus); % set the corpusObj
                obj.corpusObj = fh(obj.para);
                obj.viewObj = commonView(obj, [2 2]);
                obj.currentOutput.viewObj = obj.viewObj;

                %-------- test initialization-------------------------------
                [obj.textArr, obj.audioArr] = obj.corpusObj.randomized_text_audio_Arr();
                obj.subTestObj.initialize();               
                
                %--------set data to be saved in the records----------------
                % nothing to do here for lexical tone tests
            end                        
        end
        
        function run(obj)
            obj.ongoingFlag = 1;
            for iTrial = 1:size(obj.audioArr,1)
%                 try
%                 if obj.subTestObj.data.targetArr(iTrial) == 3
%                     continue;
%                 end
                    set(obj.viewObj.progressText,'String',sprintf('当前第%d，共%d',iTrial,size(obj.audioArr,1)));
                    [signal,Fs] = audioread(obj.audioArr(iTrial,:));
                    currentText = obj.textArr(iTrial,:);
                    [outAudio,outFs] = obj.subTestObj.process_audio(signal,Fs);
                    obj.currentOutput.audio.sig = outAudio;
                    obj.currentOutput.audio.fs = outFs;
                    obj.currentOutput.text = currentText;
                    obj.outputObj.output(obj.currentOutput);
                    %obj.outputObj.output(outAudio,outFs,currentText,obj.viewObj);
                    uiwait(obj.viewObj.fhandle);
                    answer = obj.viewObj.get_answer();
                    obj.subTestObj.process_answer(answer,iTrial);
                    set(obj.viewObj.selButtonArray,'UserData',0);
%                 catch
%                     warning('程序已关闭');
%                     return;
%                 end
            end
            obj.save_result();% 数据保存json文件
            obj.ongoingFlag = 0;
            close(obj.viewObj.fhandle);
        end
    end
end


