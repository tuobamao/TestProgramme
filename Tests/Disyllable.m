classdef Disyllable < Monosyllable
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
%     properties
%         Property1
%     end
    
    methods
        function obj = Disyllable(para,mainTestObj)
            %UNTITLED 构造此类的实例
            %   此处显示详细说明
            obj = obj@Monosyllable(para,mainTestObj);
            if nargin > 0
                % hide the 3rd button for disyllable
                
                

                
                
                if ~isfile(['.\Sounds\Xiaoya2018\',mainTestObj.basicInfo.name,'.json'])
                    fNameArr = load('.\Sounds\Xiaoya2018\bisyllablesFilnames270.mat'); % 270 filenames in  StimuliFiles
                    fNameArr = fNameArr.StimuliFiles;
                    temp = regexp(cellstr(fNameArr),'F0_(\d*)_(\d*)_Gain_(-?\d*)_(-?\d*).wav','tokens');
                    temp = reshape([temp{:}],[],1);% 去掉一层cell
                    temp = (reshape([temp{:}],4,[]))'; % 再去掉一层cell
                    temp = reshape(str2num(char(temp)),[],4); % 化为数值矩阵
                    f0ToneArr = 1*(temp(:,2) == temp(:,1)) + 2*(temp(:,2) > temp(:,1))...
                        +4*(temp(:,2) < temp(:,1)); % F0变化引起的声调
                    gainToneArr = 1*(temp(:,4) == temp(:,3)) + 2*(temp(:,4) > temp(:,3))...
                        +4*(temp(:,4) < temp(:,3)); % Gain变化引起的声调
                    wordNumArr = repelem((1:5)',54,1);
                    rng('shuffle');
                    order = randperm(270);                                     
                    data.fNameArr = fNameArr(order,:);
                    data.f0ToneArr = f0ToneArr(order,:);
                    data.gainToneArr = gainToneArr(order,:);
                    data.wordNumArr = wordNumArr(order,:);
                    savejson('',data,'FileName',sprintf('.\\Sounds\\Xiaoya2018\\%s.json',mainTestObj.basicInfo.name),'CompressStringSize',10000);                    
                end               
            end 
        end
        
        function initialize(obj)
            initialize@Monosyllable(obj);
            set(obj.mainTestObj.viewObj.selButtonArray(3),'Visible', 'off');
            set(obj.mainTestObj.viewObj.selButtonArray,'FontSize',15);
        end
    end
end

