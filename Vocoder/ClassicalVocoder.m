classdef ClassicalVocoder < handle
    % This class defines the classical envelope-based tone or noise vocoder
    % 
    
    properties
        carrierType; % 1:tone, 2:noise
        modExtrObj; % object for modulator extraction
        electrodogramFlag;% 1高斯脉冲声码器将显示电极图，0不显示
    end
    
    methods
        function obj = ClassicalVocoder(carrierType,strategyPara)
%             carrierType:1-tone,2-noise
%              strategyPara: struct with two fields
%              - strategyPara.strategy: string, 'ACE' or 'TLE'
%              - strategyPara.flim: double, 50 to 300
            if nargin > 0                
                obj.carrierType = carrierType;
                switch strategyPara.strategy
                    case 'ACE'
                        obj.modExtrObj = AceModulator();                        
                    case 'TLE'
                        obj.modExtrObj = TleModulator(strategyPara.flim);
                    otherwise
                        errordlg('Unknown strategy for vocoder, only ACE or TLE supported');
                        return;
                end
            end
        end
        
        function [vocodedAudio,vocodedFs] = output(obj,inputAudio,Fs)% apply vocoder
            if size(inputAudio,2) > size(inputAudio,1) % 
                x = inputAudio';
            else
                x = inputAudio;
            end 
            vocodedAudio = zeros(size(x));
            for chan = 1:size(x,2) % vocoder channel by channel
                modulator =  obj.modExtrObj.modulator_for_one_channel(x(:,chan),Fs);
                vocodedAudio(:,chan) = obj.env_vocoder(modulator,obj.modExtrObj.fco,Fs);
            end
            vocodedFs = Fs;
%             sound(vocodedAudio,vocodedFs);
        end
    end
    
    methods(Access = private)
    function o = env_vocoder(obj, env,fco,Fs)% amplitude modulation
            % M 数据长度
            N = length(fco)-1;
            M = size(env,1);
            t = (0:M-1)/Fs;       % 时间坐标   
            s = zeros(size(env));
            if obj.carrierType == 1 % tone carrier
                for m = 1:N
                    ftone = mean(fco(m:m+1));
                    tone = sin(2*pi*ftone*t+rand(1)*2*pi);
                    s(:,m) = tone'.*env(:,m);
                end
            elseif obj.carrierType == 2 % noise carrier
                noise = randn(M,1)/10;  
                for m = 1:N
                    [b,a]  = butter(3,[fco(m)*2/Fs,fco(m+1)*2/Fs]);  % 6阶
                    bandNoise = filter(b,a,noise);
                    s(:,m) = bandNoise.*env(:,m);
                end
            end            
            o2 = sum(s,2);
            o = o2/max(abs(o2))*0.99;
        end

    end

end

%% supporting functions
% 
% % 下面的函数引自FAME. Nie and Zeng 2005. 按照Greenwood 1990 中的公式1进行计算
% function fco = CF_bands(fmin, fmax, N)
%     %根据Greewood 1990中的对公式1的说明
%     k = 1;
%     a = 2.1; % 当a = 2.1时，x为基底膜长度的比例量；当a = 0.06时，x为单位为毫米的长度量
%     A = 165.4;% 对人类来说，是165.4
% 
%     xmin = log10(fmin/A+k)/a;
%     xmax = log10(fmax/A+k)/a;    %relative value
% 
%     dx = (xmax-xmin)/N;
%     x = xmin:dx:xmax;
%     fco=zeros(1,N+1);
% 
%     for i=1:N+1
%        fco(i)=165.4*(10^(x(i)*2.1)-1);
%     end  
% end