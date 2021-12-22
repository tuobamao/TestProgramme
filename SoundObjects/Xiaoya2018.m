classdef Xiaoya2018 < handle
    %UNTITLED2 此处显示有关此类的摘要
    %   此处显示详细说明
    
 properties%(Access = protected)
        corpus;       
        btnLayout;%需要几个按钮及如何排列，如[1,7]表示需要一行7个按钮
        targetArr;
        targetStringArr;
        periodicity; % 是否测试减少周期性的对比
        list;
 end
  properties(Hidden)
        name;
        wordArr = {'射击','涉及','设计';'平方','平房','平放';'绒花','荣华','融化';...
            '老师','老实','老是';'花香','滑翔','画像'};
        pinyinArr = {'Shè Jī','Shè Jí','Shè Jì';'Píng Fāng','Píng Fáng','Píng Fàng';...
            'Róng Huā','Róng Huá','Róng Huà';'Lǎo Shī','Lǎo Shí','Lǎo Shì';...
            'Huā Xiāng','Huá Xiáng','Huà Xiàng'};
 end  
    
    methods
        function obj = Xiaoya2018(para) % para:a struct with fields: list and periodicity
            obj.corpus = 'Xiaoya2018';
            obj.btnLayout = [2,2];
            if nargin > 0
                obj.list  = para.list;
                obj.periodicity = para.periodicity;
                obj.name = para.name;
            end
        end
         function [textArr, audioArr] = randomized_text_audio_Arr(obj)
              % 读取文本
                data = loadjson(['.\Sounds\Xiaoya2018\',obj.name,'.json']);
                idx = (obj.list-1)*45+(1:45);
                
                audioArr = char((data.fNameArr(idx))');
                obj.targetArr = data.f0ToneArr(idx,:);                
                obj.targetStringArr = audioArr; % 这个保存到结果文件中
                audioArr = [repmat('.\Sounds\Xiaoya2018\',45,1),audioArr];
                
                wordNumArr = data.wordNumArr(idx,:);
                toneArr = repelem([1;2;4],5,1);
                textArr = compose('%s %s %d',char(obj.wordArr{:}),char(obj.pinyinArr{:}),toneArr);
                textArr = reshape(textArr, 5,[]);
                textArr = [textArr,textArr(:,3)];
                
                textArr = textArr(wordNumArr,:);
         end
    end
end

