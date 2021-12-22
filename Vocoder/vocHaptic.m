classdef vocHaptic < handle
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        vocObj; % vocoder object
    end
    
    methods
        function obj = vocHaptic(vocTypeStr, carrierValue,strategyPara)
            if nargin > 0
                fh = str2func(vocTypeStr);
                obj.vocObj = fh(carrierValue,strategyPara);
            end
        end
        
        function [vocodedAudio,vocodedFs] = output(obj,inputAudio,Fs)
            [vocodedAudio,vocodedFs] = obj.vocObj.output(inputAudio,Fs);
            vocodedAudio(:, 2) = haptic(inputAudio(:,1),Fs);
%            sound(vocodedAudio,vocodedFs);
            sound(vocodedAudio(:,2),vocodedFs);
        end
    end
end

