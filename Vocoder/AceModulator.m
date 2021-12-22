classdef AceModulator < ModulatorExtraction
    % modulator extraction for ACE: envelope extraction for all bands    
    
    methods
        function modulator = modulator_for_one_channel(obj,x,Fs)  
            Nband = length(obj.fco)-1;  
            modulator = zeros(size(x,1),Nband);
            for n = 1:Nband
                [b,a]=butter(3,[obj.fco(n)/(Fs/2) obj.fco(n+1)/(Fs/2)]);
                y0 = filter(b,a,x);
                y = obj.envelopeExtraction(y0,Fs);% call the modulator extraction method
                y = y/rms(y)*rms(y0); % 2014/10/22 增加这一句，令每个通道的RMS保持不变。
                modulator(:,n) = y;
            end
        end

    end
end

