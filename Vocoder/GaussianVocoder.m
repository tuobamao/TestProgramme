classdef GaussianVocoder < handle
    %UNTITLED2 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        cciObj; % call cci-mobile code to apply strategy processing
        sObj; % strategy obj
        carrierType; % 1:tone, 2:noise
        electrodogramFlag;% 1高斯脉冲声码器将显示电极图，0不显示
    end
    
    methods
        function obj = GaussianVocoder(carrierType,strategyPara)
%             carrierType:1-tone,2-noise
%              strategyPara: struct with two fields
%              - strategyPara.strategy: string, 'ACE' or 'TLE'
%              - strategyPara.flim: double, 50 to 300
%             example: 
%             sp.strategy = 'TLE'; sp.flim = 100;
%             voc = GaussianVocoder(1, sp); 
%             [a,fs] = audioread('.\Sounds\MSP\msp001.wav');
%             [vocodedAudio, vocodedFs] = voc.output(a,fs);
            if nargin > 0
                obj.carrierType = carrierType; % 1:tone, 2:noise
                % load map
                obj.cciObj = CCiMobile();
                lname = ['.\CCiMobile Code\MAPs\sample_left.txt'];
                rname = ['.\CCiMobile Code\MAPs\sample_right.txt'];
                if exist(lname,'file') && exist(rname,'file')
                    lmap = CCiMobileMap('left',lname,obj.cciObj.FS);
                    rmap = CCiMobileMap('right',rname,obj.cciObj.FS);
                else
                    uiwait(errordlg('left or right map file does not exist','Error'));
                    return;
                end
                
                % create strategy object
                obj.sObj = feval(str2func(strategyPara.strategy));
                obj.sObj.initialize(lmap,rmap,obj.cciObj.FRAMESIZE,obj.cciObj.FS);
                if isa(obj.sObj,'ACE') || isa(obj.sObj,'bACE')
                    fprintf(1,'Running %s\n',class(obj.sObj));
                else
                    obj.sObj.fltp = strategyPara.flim;
                    fprintf(1,'Running %s%d\n',class(obj.sObj),obj.sObj.fltp);
                end
                
            end
        end
        
        function [vocodedAudio, vocodedFs] = output(obj,inputAudio,Fs)%
            % Inputs:
            %     - inputAudio: the sound signal to be vocoded
            %     - Fs: the sampling frequency of the sound signal, e.g., 16000 or 44100
            % Outputs:
            %     - vocodedAudio: the vocoded sound signal
            %     - vocodedFs: sampling rate of vocoded sound signal
            
            %---------Front-end scaling and pre-emphasis-----------------
            p.front_end_scaling = 1.0590e+003; 
            p.input_scaling =  5.5325e-004;
            %Preemphasis
            p.pre_numer =    [0.5006   -0.5006];
            p.pre_denom =    [1.0000   -0.0012];            
            y = inputAudio * p.front_end_scaling;
            z = filter(p.pre_numer, p.pre_denom, y);
            inputAudio = z * p.input_scaling;
            %---------- end of pre-emphasis -------------------------------
            
            obj.cciObj.process(obj.sObj,{inputAudio,Fs},'file');
            % 20210719新增输出电极图
            if obj.electrodogramFlag
                obj.cciObj.process(obj.sObj,{inputAudio,Fs},'electrodogram');
            end
            load outstream.mat; % load the mat file, data in variable stimubuffer
            
            electroLeft = get_buffered_values(stimbuffer,'left'); % decode electrodogram from ccimobile outstream
            electroRight = get_buffered_values(stimbuffer,'right');
            
            % apply Gussian vocoder on electrodogram data
            [vocodedLeft,~] = electrovocoder(electroLeft,lmap,obj.carrierType);
            [vocodedRight,~] = electrovocoder(electroRight,rmap,obj.carrierType);
            if min(size(inputAudio)) == 1
                vocodedAudio = [vocodedLeft(:)];
            else
                vocodedAudio = [vocodedLeft(:), vocodedRight(:)];
            end            
            vocodedFs = 16000; % fixed
%             sound(vocodedAudio,vocodedFs);
        end
       
    end
end

%% supporting functions
function stim = get_buffered_values(outstream,side)
    % define byte indicies
    LEFT_ELECTRODE_START = 7;
    %LEFT_ELECTRODE_END = 122;
    LEFT_ELECTRODE_END = 7-1+outstream(1,508); % pulses per frame, left
    LEFT_AMPLITUDE_START = 133;
    LEFT_AMPLITUDE_END = 133-1+outstream(1,508); % pulses per frame, left
    %LEFT_AMPLITUDE_END = 248;
    
    RIGHT_ELECTRODE_START = 265;
    RIGHT_ELECTRODE_END = 265-1+outstream(1,510); % pulses per frame, right
    %RIGHT_ELECTRODE_END = 380;
    RIGHT_AMPLITUDE_START = 391;
    RIGHT_AMPLITUDE_END = 391-1+outstream(1,510); % pulses per frame, right
    %RIGHT_AMPLITUDE_END = 506;
    
    % get correct indicies based on side
    switch lower(side)
        case 'left'
            e_index = LEFT_ELECTRODE_START:LEFT_ELECTRODE_END;
            a_index = LEFT_AMPLITUDE_START:LEFT_AMPLITUDE_END;
        case 'right'
            e_index = RIGHT_ELECTRODE_START:RIGHT_ELECTRODE_END;
            a_index = RIGHT_AMPLITUDE_START:RIGHT_AMPLITUDE_END;
    end
    
    % format struct necessary for plotting
    stim.electrodes = [];
    stim.current_levels = [];
    for ii = 1:size(outstream,1)
        el = outstream(ii,e_index);
        cl = outstream(ii,a_index);
        cl(el == 0) = []; el(el == 0) = [];
        stim.electrodes = [stim.electrodes; el'];
        stim.current_levels = [stim.current_levels; cl'];
    end

end

function plot_vocEnv(VocEnv,NumCh,fs,color)
% plot envelopes of each electrode
if nargin < 4 % set default color
    color = 'k';
end

% plot envelopes on each electrode
VocEnv = VocEnv / max(VocEnv(:));
VocEnv(VocEnv==0) = NaN;
t = (0:size(VocEnv,2)-1)/fs;
for n = 1:NumCh
	plot(t,VocEnv(n,:)+NumCh-(n-1),color); hold on; % #22 at the bottom, #1 on top
end
axis([0,t(end),0.5,NumCh+0.9]);
end
