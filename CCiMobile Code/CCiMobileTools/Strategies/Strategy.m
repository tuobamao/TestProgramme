classdef Strategy < handle
    properties
        lmap        % left map
        rmap        % right map
        framesize   % number of samples in one frame
        fs          % sampling rate of audio
    end
    
    methods
        function obj = Strategy()
            
        end
        
        function initialize(obj,lmap,rmap,framesize,fs)
            obj.lmap = lmap;
            obj.rmap = rmap;
            obj.framesize = framesize;
            obj.fs = fs;
        end
        
        function [out_l,out_r] = process(obj,in_l,in_r)
            out_l = in_l;
            out_r = in_r;
        end
        
    end
end