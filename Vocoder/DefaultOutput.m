classdef DefaultOutput < handle
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        outStruct;%用于重播
    end
    
    methods        

        function output(obj,outStruct)%inputAudio,Fs,currentText,testViewObj)
            %        Input: outStruct is a struct that contains the following fields:
            %           1*.audio,(* denotes modatory, others are optional)
            %              audio可以是一个结构体数组，包含sig 和 fs两个字段
            %           2.text, 句子或声调对应汉字
            %           3.viewObj, 显示上述汉字的界面
            %           4.beep,a struct with beep.sig, beep.fs
            %--------------------------------------------------------------
            if nargin > 1
                obj.outStruct = outStruct;%保存便于重播
                if isfield(outStruct,'beep')
                    obj.outStruct.audio.sig =[repmat(outStruct.beep.sig,1,size(outStruct.audio.sig,2)); outStruct.audio.sig];% add the beep sound
                end
                outStruct.viewObj.refresh(obj.outStruct); %界面刷新    
                obj.outputSound(); % 播放声音
            else % 重播
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

