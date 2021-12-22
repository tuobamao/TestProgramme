classdef generatedTones < handle
%      generatedTones is used to generate pure tones or harmonic complex tones.
%      example:
%       a = generatedTones();
%       a.generate(250) % generate a 5-harmonic complex tone with F0=250 Hz;
%       a.play % to play the generated tone.
%      Developed by Huali Zhou, 20200908,  mshualizhou@mail.scut.edu.cn
%***********************************************************************
    
properties
    %      Fs = 16000;
    %      signal;
    %       targetRMS = 0.4;%MSP-SSN是0.0523
    %dur = 400;

    F0; % default value for initial testing
end

methods
    
    function obj = generatedTones(F0,soundProp)
        if nargin > 0
            obj.F0 = F0;
            Fs = obj.Fs; %采样率
            N = soundProp.duration/1000*Fs;% 采样点数
            t = (0:N-1)/Fs;
            rampDuration = soundProp.ramp/1000;
            harmonicNumber = soundProp.harmonicNumber;
            nextHarmonicDecrease = 10^(soundProp.nextHarmonicDecrease/20);
            
            % generate complex tones,with next harmonic decrease and each harmonic
            % level roving
            ComplexTone = 0.8*sin(2*pi*F0*t+2*pi*rand(1)); % the fundamental frequency
            for n = 1:harmonicNumber
                if n > 1
                    eachHarmonicLevelroving = 10^((rand(1)*soundProp.eachHarmonicLevelroving*2-soundProp.eachHarmonicLevelroving)/20);
                    ComplexTone = ComplexTone + 0.8*sin(2*pi*F0*n*t+2*pi*rand(1))/(nextHarmonicDecrease.^(n-1))*eachHarmonicLevelroving;
                end
            end
            % apply ramp up and ramp down
            obj.signal = ComplexTone;
            
            obj.signal = rampFcnt(obj,rampDuration);
            
            % apply overall level roving
            RovedLevel = 10^((rand(1)*soundProp.RMSroving*2-soundProp.RMSroving)/20);
            obj.signal = obj.signal * obj.targetRMS / rms(obj.signal) * RovedLevel;% apply rms roving
        end
    end
end
end


      function y = rampFcnt(obj,T)
            % input: x - could be row or column vectors
            %        T - the duration of the ramp in ms
            % output: y - column vectors  
            x = obj.signal;
            t = (0:round(T*obj.Fs))/obj.Fs;
            ramp_N = length(t);
            ramp_frequency = 1/(4*T);
            r_on = (sin(2*pi*ramp_frequency*t)).^2;
            r_on = r_on(:);
            r_off = flipud(r_on);
            
            if size(x,1) <3 % if input is a row vector, convert into a column vector.
                y = x';
            else
                y = x;
            end
            y(1:ramp_N,:) = y(1:ramp_N,:).*r_on;
            y(end-ramp_N+1:end,:) = y(end-ramp_N+1:end,:).*r_off;
            
            % 在开头结尾分别增加 0.005s的0
            N0 = obj.Fs*0.04;
            z0 = zeros(N0,1);
            y = [z0;y,;z0];
            %obj.signal = y;
        end
        

