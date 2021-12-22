classdef Wei2004 < handle
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
 properties%(Access = protected)
        corpus;       
        btnLayout;%需要几个按钮及如何排列，如[1,7]表示需要一行7个按钮
        targetArr;
        targetStringArr;
    end
  
    methods
        function obj = Wei2004(~)
            obj.corpus = 'Wei2004';
            obj.btnLayout = [2,2];
        end
         function [textArr, audioArr] = randomized_text_audio_Arr(obj)
              % 读取文本
                rawList = importdata('.\Sounds\Wei2004\Wei2004_words.txt');
                listHanzi = rawList(1:2:50);                
                listHanzi = reshape((char(listHanzi))',[],1);% 汉字排成一列,char型
                
                listPinyin = rawList(2:2:50);
                listPinyin = cellfun(@strsplit,listPinyin,'UniformOutput',false);
                listPinyin = string(reshape([listPinyin{:}],1,[])'); % 拼音排除一列，cell型
                textArr = compose('%s %s %d',listHanzi(:),listPinyin(:),repmat((1:4)',25,1));   
                
                %生成音频文件名矩阵  
                nChar = repelem((26:50)',4,1);
                nTone = repmat((1:4)',25,1);
                audioArr = char(compose('.\\Sounds\\%s\\%d_%d.wav',obj.corpus,nChar,nTone));
                                
                % 文本和音频对应随机顺序
                rng('shuffle');
                orderArray = randperm(length(listHanzi));
                obj.targetStringArr = textArr(orderArray,:);
                audioArr = audioArr(orderArray,:);
                obj.targetArr = nTone(orderArray);
                textArr = repelem((reshape(textArr, 4,[]))',4,1);
                textArr = textArr(orderArray,:);
         end
    end
end

