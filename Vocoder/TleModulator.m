classdef TleModulator < ModulatorExtraction
    %UNTITLED2 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        flim; % lower limit of frequency downshifting
        bandWidthLimit = 200; % frequency downshiting for bands with width less than 200 
    end
    
    methods
        function obj = TleModulator(flim)
            obj = obj@ModulatorExtraction();
            if nargin > 0
                obj.flim = flim;
            end
        end
        
        function  modulator = modulator_for_one_channel(obj,x,Fs)  
            Nband = length(obj.fco)-1;
            t = (0:1/Fs:(length(x)-1)/Fs)';
            BW = diff(obj.fco);  % 每个频带的带宽
            modulator = zeros(length(x),Nband);
            for n = 1:Nband
                [b,a]=butter(3,[obj.fco(n)/(Fs/2) obj.fco(n+1)/(Fs/2)]);
                y0 = filter(b,a,x); %分频带
                if BW(n) <= obj.bandWidthLimit %V1.4先判断带宽再移频或取包络20200824
                    fc = obj.fco(n) - obj.flim; %移频采用的正弦频率：频带下限-lower limit of temporal pitch
                    y = y0.*cos(2*pi*fc*t); %移频
                    fcl = BW(n) + obj.flim;%V1.4之前只有BW(n)+50，应该还要+flim20200825
                    y = LPF(y,fcl,Fs);%移频后低通滤波，取出想要的低频部分
                else % 带宽超过200的取包络
                     y = obj.envelopeExtraction(y0,Fs); %取包络                 
                end
                y= y/rms(y)*rms(y0); %使modulator的能量与原带限信号一样
                modulator(:,n) = y; %保存
            end
        end
    end
end

%% supporting functions
function SSE = LPF(y,fcl,Fs)
[b,a] = butter(8,fcl*2/Fs);  % 8阶巴特沃斯低通滤波器，截止频率为fcl
SSE = filter(b,a,y);
end
