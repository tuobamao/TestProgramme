classdef SRM202105 < SRT
    % This class is specially designed on May 12  2021
    % % 仿真实验方案
    % 1、题目：
    % 最大值数目和动态范围大小对双侧人工耳蜗植入者在噪声下的言语识别影响的仿真实验研究
    %
    % 2、实验对象：
    % 10个正常听力者，各频段纯音听阈均小于25dB.
    %
    % 3、实验条件：
    % 声码器：高斯声码器，22通道
    % 影响因素（3个）：
    % ①最大值数目：4、8、16个
    % ②动态范围大小：100-255、100-150？
    %   ③空间配置：S0N0M 、S0N+90M
    %   测试条件：3×2×2=12个，每个条件各测试1遍，随机条件。
    % 4、测试指标：
    %    ①SRT
    %    ②SRM
    % by Huali Zhou @ Acoustics lab, South China University of Technology
    
    
    
    properties(Access = private)
        speechHRIR;
    end
    
    methods
        function obj = SRM202105(para,mainTestObj) %SNR,basicInfo.sncondition,corpusName,closeSetOrNo)
            obj = obj@SRT(para,mainTestObj);
            if nargin > 0
                outputObj = mainTestObj.outputObj;
                if isa(outputObj,'DefaultOutput') % support non-vocoded
                    % nothing to do here
                elseif isa(outputObj,'vocoder') && isa(outputObj.vocObj,'GaussianVocoder') % or gaussian vocoder
                    outputObj.vocObj.sObj.lmap.NMaxima = para.nmaxima; % change map setting according para from GUI
                    outputObj.vocObj.sObj.lmap.NMaximaReject = 22 - para.nmaxima;
                    outputObj.vocObj.sObj.lmap.THR = para.t_value(ones(22,1));
                    outputObj.vocObj.sObj.lmap.MCL = para.c_value(ones(22,1));
                    outputObj.vocObj.sObj.lmap.Range = outputObj.vocObj.sObj.lmap.MCL - outputObj.vocObj.sObj.lmap.THR;
                    outputObj.vocObj.sObj.rmap.NMaxima = para.nmaxima;
                    outputObj.vocObj.sObj.rmap.NMaximaReject = 22 - para.nmaxima;
                    outputObj.vocObj.sObj.rmap.THR = para.t_value(ones(22,1));
                    outputObj.vocObj.sObj.rmap.MCL = para.c_value(ones(22,1));
                    outputObj.vocObj.sObj.rmap.Range = outputObj.vocObj.sObj.rmap.MCL - outputObj.vocObj.sObj.rmap.THR;
                else
                    errordlg('only supports default output or GaussianVovoder, please change output device');
                end
                obj.data.correctRateArr = [];
                obj.data = rmfield(obj.data,'correctnessArr');
            end
        end
        
        
        function [outAudio,outFs] = process_audio(obj,audioFile)
            % scale the speech signal for the SNR rative to targetRMS, then apply hrir
            [inAudio,Fs] = audioread(audioFile);
            SNR = obj.get_and_fresh_snr();            
            inAudio = inAudio/myRMS(inAudio) * obj.mainTestObj.para.targetRMS * 10^(SNR/20);  % 噪声的level不变，改变语音的level
            speech(:,1) = conv(inAudio, obj.speechHRIR.left);
            speech(:,2) = conv(inAudio, obj.speechHRIR.right);
            
            % randomly pick a noise piece already convolved with HRIR
            %             begin_point = 1; % 20180727 changed to this 为了保证噪声也有精确的时间控制
            audioLength = length(speech);
%             begin_point = randi(length(obj.noise) - audioLength);
%             noise = obj.noise(begin_point:begin_point + audioLength - 1,:);
            % add speech and noise
%             outAudio(:,1) = noise(:,1) + speech(:,1);
%             outAudio(:,2) = noise(:,2) + speech(:,2);

            % 20210719改为噪声提前300开始并延后300ms结束
            begin_point = randi(length(obj.noise) - audioLength - 0.6*Fs);
            noise = obj.noise(begin_point : begin_point + audioLength + 0.6*Fs -1,:);
            outAudio  = noise;
            outAudio(0.3*Fs : 0.3*Fs+audioLength-1,:) = speech + outAudio(0.3*Fs : 0.3*Fs+audioLength-1,:);

            outFs = Fs;
        end
        
        
        
        function initialize(obj,para, corpusObj,viewObj)
            set(viewObj.revPanel,'Visible','On');  % show the reversal plot
            corpusObj.set_adapObj(para.snr); % set initial level for the adaptive procedure
            
            % load noise, resample to match speech material, and set to
            % a fixed level
            %[noise,noiseFs] = audioread('.\sounds\Noise\msplist1.wav');2021年5月实验室仿真用的是这个噪声
            %2021年7月远程测试用的是下面这个噪声
            [noise,noiseFs] = audioread('.\sounds\Noise\Babble-OLDEN.wav');
            speechFs = corpusObj.corpusFs;
            if noiseFs ~= speechFs
                noise = resample(noise, speechFs, noiseFs);
                noiseFs = speechFs;
            end
            noise = noise / myRMS(noise) * para.targetRMS;
            
            % load HRIR database
            load('.\Sounds\Noise\QU_KEMAR_anechoic_SennheiserHD25_2m.mat');
            HRIR_fs = irs.fs;
            if para.noiseangle == 0 % azimuth 0 equals azimuth 360
                azimuth = 360;
            elseif para.noiseangle < 0 
                azimuth = 360 + para.noiseangle;% e.g. -90° means 270°
            else
                azimuth = para.noiseangle;
            end          
            
            % get hrir for input azimuth, and resample it for conv
            % with noise audio
            left_ir_noise = irs.left(:,azimuth);
            right_ir_noise = irs.right(:,azimuth);            
            left_ir_noise = resample(left_ir_noise, noiseFs, HRIR_fs);
            right_ir_noise = resample(right_ir_noise, noiseFs, HRIR_fs);
            
            left_ir_speech = irs.left(:,360);
            right_ir_speech = irs.right(:,360);
            left_ir_speech = resample(left_ir_speech, speechFs, HRIR_fs);
            right_ir_speech = resample(right_ir_speech, speechFs, HRIR_fs);
            % 此处用于调试，如果卷积后噪声太小了，可以在这里统一把脉冲响应调大（噪声和目标声都调）
            factor = 1;
            [left_ir_noise, right_ir_noise, left_ir_speech, right_ir_speech]...
                = deal(left_ir_noise * factor, right_ir_noise * factor, left_ir_speech * factor, right_ir_speech * factor);
            
            obj.noise(:,1) = conv(noise,left_ir_noise);
            obj.noise(:,2) = conv(noise,right_ir_noise);            
            obj.speechHRIR.left = left_ir_speech;
            obj.speechHRIR.right = right_ir_speech;
            clear irs;
            
        end
        
    end
    
    
    
end

