classdef vocoder < handle
    %UNTITLED2 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        vocObj; % vocoder object
        outStruct;%用于重播
       % electrodogramFlag;% 1高斯脉冲声码器将显示电极图，0不显示
    end
    
    methods
        function obj = vocoder(vocTypeStr, carrierValue,strategyPara)
            if nargin > 0
                fh = str2func(vocTypeStr);
                obj.vocObj = fh(carrierValue,strategyPara);                
            end
        end
        

        function [vocodedAudio,vocodedFs] = output(obj,inStruct)%inputAudio,Fs,currentText,testViewObj)
            %        Input: outStruct is a struct that contains the following fields:
            %           1*.audio,(* denotes modatory, others are optional)
            %           2*.fs,
            %           3.text, 句子或声调对应汉字
            %           4.viewObj, 显示上述汉字的界面
            %           5.beep,a struct with beep.sig, beep.fs
            %--------------------------------------------------------------
            if nargin > 1
                if isempty(obj.outStruct) % 第一次的时候重采样beep，保存后用
                    obj.outStruct = inStruct;%保存便于重播                    
                else % 第一次以后只更新audio和text
                    obj.outStruct.audio = inStruct.audio;
                    if isfield(inStruct,'text')
                        obj.outStruct.text = inStruct.text;
                    end
                end                
                
                % 声音分别经vocoder处理
                if length(obj.outStruct.audio) == 1 %如果只有一个声音
                    [vocodedAudio,vocodedFs] = obj.vocObj.output(inStruct.audio.sig,inStruct.audio.fs);
                    obj.outStruct.audio.fs = vocodedFs;
                    if isfield(inStruct,'beep')% 第一次的时候重采样beep，保存后用
                        if obj.outStruct.beep.fs ~= vocodedFs
                            obj.outStruct.beep.sig = resample(obj.outStruct.beep.sig, vocodedFs, obj.outStruct.beep.fs);
                            obj.outStruct.beep.fs = vocodedFs;
                        end
                        obj.outStruct.audio.sig =[repmat(obj.outStruct.beep.sig,1,size(vocodedAudio,2)); vocodedAudio];% add the beep sound
                    end
                else % 如果有一个以上的声音，则分别进行声码器处理
                    for n = 1:length(obj.outStruct.audio)
                        [obj.outStruct.audio(n).sig,obj.outStruct.audio(n).fs] = obj.vocObj.output(inStruct.audio(n).sig,inStruct.audio(n).fs);
                    end
                end
                inStruct.viewObj.refresh(obj.outStruct); %界面刷新    
                obj.outputSound(); % 播放声音
                            
            else
                obj.outputSound();
            end
            
        end
      
    end
     methods(Access = private)
        function outputSound(obj)
            if length(obj.outStruct.audio) == 1 %如果只有一个声音
                sound(obj.outStruct.audio.sig,obj.outStruct.audio.fs);
            else % 如果有一个以上的声音，则播放时点亮界面上的相应按钮
                for n = 1:length(obj.outStruct.audio)
                    set(obj.outStruct.viewObj.selButtonArray(n),'BackgroundColor',[0,1,1]);%播放前把对应按钮点亮
                    sound(obj.outStruct.audio(n).sig,obj.outStruct.audio(n).fs);
                    pause(length(obj.outStruct.audio(n).sig)/obj.outStruct.audio(n).fs + 0.2);
                    set(obj.outStruct.viewObj.selButtonArray(n),'BackgroundColor',[0.941,0.941,0.941]); %播放完成后再变灰
                end
            end
        end
    end
end

