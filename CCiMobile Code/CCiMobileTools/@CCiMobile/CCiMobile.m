classdef CCiMobile < handle
    properties (Access = protected)
        preemphasis             = false; %true; % false
        agc                     = false
        state                   = 0             % 0 = stopped, 1 = running
        mode                    = 'bilateral'
        left_sensitivity_gain   = 0             % additional input gain (dB)
        right_sensitivity_gain  = 0             % additional input gain (dB)
        left_volume             = 8             % scales stimulation levels between THR and MCL values
        right_volume            = 8             % scales stimulation levels between THR and MCL values
        plotmode                = 2             
    end
    
    properties (Constant)
        FS = 16000              % sampling rate of device
        FRAMEDURATION = 8       % duration of one block (in ms)
        FRAMESIZE = 128         % samples per frame
        MAXAMPLITUDES = 116     % number of allowable amplitude words per frame
        ADCGAIN = 26            % gain required to bring ADC values into usable range (dB)£» it was set at 26 by Alan Kan
        DURATIONSYNC = 6
        ADDITIONALGAP = 1
    end
    
    methods (Access = public)
        function obj = CCiMobile
            obj.state = 0;
        end
    end
end