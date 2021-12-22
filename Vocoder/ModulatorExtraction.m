classdef ModulatorExtraction < handle
    % This class defines the modulator extraction of CIS and TLE
    
    properties
        fcl = 250; % low-pass cut-off frequency 
        fco = [80.0 140.1 214.9 308.0 424.0 568.3 748.0 971.6 1250.1   1596.7 2028.2 2565.4 3234.1 4066.5 5102.9 6393.0 7999.0]; % for band devision
    end
    methods
        function env = envelopeExtraction(obj, y,Fs)
            y_rec = abs(y); %全波整流
            [b,a] = butter(8,obj.fcl*2/Fs);  % 8阶巴特沃斯低通滤波器，截止频率为fcl
            env = filter(b,a,y_rec);
        end
    end
    methods(Abstract)
        modulator = modulator_for_one_channel(obj);        
    end
end

