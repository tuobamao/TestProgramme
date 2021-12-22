function [targetBrir,brirFs,binauralNoise] = initialize_in_car(para)
% 此函数用于车内语音清晰度实验包括SRT和固定信噪比的初始化阶段，
% 主要作用是对噪声信号的处理和目标BRIR的重采样
% Input: para 结构体，包含如下字段
% noise:噪声类型 female, male, pink
% target_loc:目标方位
% noise_loc：噪声方位
% window：开窗或关窗
% orient：头朝向
% corpusFs：目标语料库采样率

%   此处显示详细说明
    
% 取噪声方位的脉冲
    if ~strcmp(para.noise_loc,'无方位') %噪声无方位，不需要噪声BRIR
        fNoise = ['.\Sounds\CarImpulse\',para.noise_loc,'_',para.window,'_impulse_',num2str(para.orient),'.wav'];
        [noiseBrir , brirFs] = audioread(fNoise);
        noiseBrir = noiseBrir * 2;% 为避免卷积后和无方位的差太多，脉冲统一*2
    end
    

    % 取原始的单通道噪声信号，并调制rms到targetRMS
   switch para.noise
        case 'female'
            [rawNoise, rawNoiseFs] = audioread('.\Sounds\Noise\msplist1.wav');
        case 'male'
            [rawNoise, rawNoiseFs] = audioread('.\Sounds\Noise\mhintlist1.wav');
        case 'pink'
            [rawNoise, rawNoiseFs] = audioread('.\Sounds\Noise\pink_noise.wav');
            rawNoise = [rawNoise;rawNoise];
        otherwise
            errordlg('Unknown noise type');
    end
    % 重采样噪声信号使跟目标语音信号一样
    speechFs = para.corpusFs;
    if rawNoiseFs ~= speechFs
        rawNoise = resample(rawNoise, speechFs, rawNoiseFs);
        rawNoiseFs = speechFs;
    end
    rawNoise = rawNoise / rms(rawNoise) * para.targetRMS; % 调制噪声rms

    % 从原始的单通道噪声信号生成双耳噪声信号
    if strcmp(para.noise_loc,'无方位')
        binauralNoise = [rawNoise, rawNoise]; 
    else
        if rawNoiseFs ~= brirFs
            noiseBrir = resample(noiseBrir, rawNoiseFs, brirFs);
        end
        binauralNoise(:,1) = conv(rawNoise, noiseBrir(:,1));
        binauralNoise(:,2) = conv(rawNoise, noiseBrir(:,2));
    end    
    

    % 重采样目标语音的brir，使与目标语音一样
    fTarget = ['.\Sounds\CarImpulse\',para.target_loc,'_',para.window,'_impulse_',num2str(para.orient),'.wav'];
    [targetBrir , brirFs] = audioread(fTarget);
    if brirFs ~= speechFs
        targetBrir = resample(targetBrir ,speechFs, brirFs);
        brirFs = speechFs;
    end
    targetBrir = targetBrir * 2; % 为避免卷积后和无方位的差太多，脉冲统一*2
end

