classdef CciStream < handle
    %UNTITLED3 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        cciObj; % call cci-mobile code to apply strategy processing
        sObj; % strategy obj  
        currentOutput = struct(); % 用于输出和重播
    end
    
    methods
        function obj = CciStream(cciPara,strategyPara)
%              carrierType:1-tone,2-noise
%              cciPara: struct with four fields
%                   - cciPara.subject: string, subject name
%                   - cciPara.gain_l
%                   - cciPara.vol_l
%                   - cciPara.gain_r
%                   - cciPara.vol_r
%              strategyPara: struct with two fields
%                   - strategyPara.strategy: string, 'ACE' or 'TLE'
%                   - strategyPara.flim: double, 50 to 300
%             example: 
%                   voc = GaussianVocoder(1, 'ACE'); 
%                   [a,fs] = audioread('.\Sounds\MSP\msp001.wav');
%                   [vocodedAudio, vocodedFs] = voc.output(a,fs);
            if nargin > 0
                % create ccimobile object
                obj.cciObj = CCiMobile();
                obj.cciObj.set_property('mode','bilateral'); % only bilateral implemented
                obj.cciObj.set_property('left_sensitivity_gain',cciPara.gain_l);
                obj.cciObj.set_property('left_volume',cciPara.vol_l);
                obj.cciObj.set_property('right_sensitivity_gain',cciPara.gain_r);
                obj.cciObj.set_property('right_volume',cciPara.vol_r);

                % load map                
                lname = ['.\CCiMobile Code\MAPs\',cciPara.subject,'_left.txt'];
                rname = ['.\CCiMobile Code\MAPs\',cciPara.subject,'_right.txt'];
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
        
        function [outputAudio, outputFs] = output(obj,inputAudio,Fs)
            sound(inputAudio,Fs);
            %---------Front-end scaling and pre-emphasis-----------------
            p.front_end_scaling = 1.0590e+003; 
            p.input_scaling =  5.5325e-004;
            %Preemphasis
            p.pre_numer =    [0.5006   -0.5006];
            p.pre_denom =    [1.0000   -0.0012];            
            y = inputAudio * p.front_end_scaling;
            z = filter(p.pre_numer, p.pre_denom, y);
            inputAudio = z * p.input_scaling;
            %---------- end of pre-emphasis -------------------------------------------------------
            obj.cciObj.process(obj.sObj,{inputAudio,Fs},'rfcoil');
            outputAudio = inputAudio;
            outputFs = Fs;
        end
        

    end
end

