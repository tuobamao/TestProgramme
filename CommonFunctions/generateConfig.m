% 本脚本用于生成config文件
%% module结构体用于保存右边的测试设置信息
Quiet.Type = 'Quiet';
Quiet.labels={'Corpus';'List';'Set'};
%Quiet.strings = {{'MSP','MHINT','OLDEN'};sprintfc('%g',1:10);{'Open','Closed'}};
Quiet.strings = {{'MSP','MSP_OPUS','MSP_LTone','MSP_EQ',...
    'MHINT','MHINT_OPUS','MHINT_LTone','MHINT_EQ',...
    'OLDEN','OLDEN_OPUS','OLDEN_LTone','OLDEN_EQ'};sprintfc('%g',1:10);{'Open','Closed'}};
Quiet.styles = {'popupmenu';'popupmenu';'popupmenu'};
Quiet.fields_for_fname = {'Corpus';'List'};
Quiet.note = '本测试用于安静环境中的言语识别测试，测试指标为句子识别正确率，播放声级固定为与校准噪声一致。';

% FixedSNR, 在Quiet的基础上增加noise和SNR
FixedSNR = Quiet;
FixedSNR.Type = 'FixedSNR';
FixedSNR.labels{4}='Noise';
FixedSNR.strings{4} = {'SSN','Babble'};
FixedSNR.styles{4} = 'popupmenu';
FixedSNR.labels{5}= 'SNR';
FixedSNR.strings{5} = '10';
FixedSNR.styles{5} = 'edit';
FixedSNR.fields_for_fname = {'Noise';'SNR'};
FixedSNR.note = '本测试用于固定信噪比下的言语识别测试，测试指标为句子识别正确率，播放声级固定为与校准噪声一致。';

% SRT与FixedSNR一样
SRT = FixedSNR;
SRT.Type = 'SRT';
SRT.fields_for_fname = {'Noise'};
SRT.note = '本测试用于言语接受阈（Speech Reception Threshold,SRT）测试，测试指标为一个信噪比，在该信噪比下有50%的概率能听懂，噪声声级固定，目标语音声级自适应变化。';

% bSRT在Quiet的基础上增加 condition 和SNR
bSRT = Quiet;
bSRT.Type = 'bSRT';
bSRT.strings{1} = {'OLDEN'};
bSRT.strings{2} = sprintfc('%g',1:40);
bSRT.labels{4}='Condition';
bSRT.strings{4} = {'S0N0M','S0N10M','S0N0F','S0N10F'};
bSRT.styles{4} = 'popupmenu';
bSRT.labels{5}= 'SNR';
bSRT.strings{5} = '10';
bSRT.styles{5} = 'edit';
bSRT.fields_for_fname = {'Condition'};
bSRT.note = '本测试为Sendai文章后续专门设计的。';

% QuietSRT在Quiet的基础上增加CaliSPL和IniSPL
QuietSRT = Quiet;
QuietSRT.Type = 'QuietSRT';
QuietSRT.labels{4}='CaliSPL';
QuietSRT.strings{4} = '65';
QuietSRT.styles{4} = 'edit';
QuietSRT.labels{5}='IniSPL';
QuietSRT.strings{5} = '65';
QuietSRT.styles{5} = 'edit';
QuietSRT.fields_for_fname = {'Corpus';'List'};
QuietSRT.note = '本测试与SRT测试类似，变化的是语音的播放声级，最后得到一个声级，在该声级下有50%的概率能听懂。';


% SRM202105是2021年5月设计的仿真实验
SRM202105 = Quiet;
SRM202105.Type = 'SRM202105';
SRM202105.strings{1} = {'OLDEN'};
SRM202105.strings{2} = sprintfc('%g',1:40);
SRM202105.labels{4} = 'NoiseAngle';
SRM202105.strings{4} = '90';
SRM202105.styles{4} = 'edit';
SRM202105.labels{5}= 'SNR';
SRM202105.strings{5} = '10';
SRM202105.styles{5} = 'edit';
SRM202105.labels{6}='Nmaxima';
%SRM202105.strings{6} = {'8','4','16'};
%SRM202105.styles{6} = 'popupmenu';
SRM202105.strings{6} =  '8'; % 20210719改为手动输入的
SRM202105.styles{6} = 'edit';

SRM202105.labels{7} = 'T_Value';
SRM202105.strings{7} = '100';
SRM202105.styles{7} = 'edit';
SRM202105.labels{8} = 'C_Value';
SRM202105.strings{8} = '255';
SRM202105.styles{8} = 'edit';
SRM202105.fields_for_fname = {'NoiseAngle';'Nmaxima';'C_Value'};
SRM202105.note = '本测试是2021年5月设计的实验，研究动态范围、通道数、噪声方位对SRT的影响。';

% SRT_in_car是2021年5月与梁博一起设计的车内语言清晰度实验
SRT_in_car = SRT;
SRT_in_car.Type = 'SRT_in_car';
SRT_in_car.strings{1} = {'OLDEN'};
SRT_in_car.labels{4} = 'Noise';
SRT_in_car.strings{4} = {'pink','female','male'};
SRT_in_car.styles{4} = 'popupmenu';
SRT_in_car.labels{6}='Target_loc';
SRT_in_car.strings{6} = {'副驾驶','后右','后中','后左'};
SRT_in_car.styles{6} = 'popupmenu';
SRT_in_car.labels{7} = 'Noise_loc';
SRT_in_car.strings{7} = {'无方位','副驾驶','后右','后中','后左'};
SRT_in_car.styles{7} = 'popupmenu';
SRT_in_car.labels{8} = 'Window';
SRT_in_car.strings{8} = {'开窗','关窗','听音室'};
SRT_in_car.styles{8} = 'popupmenu';
SRT_in_car.labels{9} = 'Orient';
SRT_in_car.strings{9} = sprintfc('%g',-60:5:60);
SRT_in_car.styles{9} = 'popupmenu';
SRT_in_car.fields_for_fname = {'Noise';'Target_loc';'Noise_loc';'Window';'Orient'};
SRT_in_car.note = '本测试为2021年5月与Linda Liang合作实验，研究车内不同说话人位置、反射条件、头朝向对SRT的影响。';


% FixedSNR_in_car是2021年5月与梁博一起设计的车内语言清晰度实验
FixedSNR_in_car = SRT_in_car;
FixedSNR_in_car.Type = 'FixedSNR_in_car';
FixedSNR_in_car.strings{1} = {'OLDEN'};
FixedSNR_in_car.fields_for_fname = {'Noise';'SNR';'Target_loc';'Noise_loc';'Window';'Orient'};
FixedSNR_in_car.note = '本测试为2021年5月与Linda Liang合作实验，研究车内不同说话人位置、反射条件、头朝向对言语识别率的影响。';

%% ***************************************************************
% 修改这里，设置显示在界面上的测试项目
% 如果不想显示这个模块，把这一段注释即可
subSpeech = {Quiet, FixedSNR ,SRT, bSRT,QuietSRT, SRM202105,SRT_in_car,FixedSNR_in_car};
for n = 1:numel(subSpeech)    
    %module.Speech(n) = eval(subSpeech{n});
    module.Speech(n) = subSpeech{n};
end
%--------------------------------------------------------------------------
%% 音高感知模块
Ranking.Type = 'Ranking';
Ranking.labels = {'F0';'ISI_ms';'Duration_ms';'Ramp_ms';'N_harmonics';'Rolloff_Oct_dB';'Roving_harmonic_dB';'Roving_RMS_dB'};
Ranking.strings = {{'250','313','1000','1063'};'300';'400';'10'; '5'; '10'; '0';'2'};
Ranking.styles = {'popupmenu','edit','edit','edit','edit','edit','edit','edit'};
Ranking.fields_for_fname = {'F0'};
Ranking.note = '本测试任务是音高排序，采用2I-2AFC，受试者的任务是选择音高较高的，2D1U自适应调整F0差，测试指标为F0DL';
% 音高分辨与音高排序一样
Discrimination = Ranking;
Discrimination.Type = 'Discrimination';
Discrimination.note = '本测试任务是音高分辨，采用3I-3AFC，受试者的任务是选择3个中与其他两个音高不同的选项，2D1U自适应调整F0差，测试指标为F0DL';
% 音高分辨与音高排序一样
Discrimi3I2AFC = Ranking;
Discrimi3I2AFC.Type = 'Discrimi3I2AFC';
Discrimi3I2AFC.note = '本测试任务是音高分辨，采用3I-2AFC，受试者的任务是选择3个中与其他两个音高不同的选项（只会出现在后两个中），2D1U自适应调整F0差，测试指标为F0DL';

%% ***************************************************************
% 修改这里，设置显示在界面上的测试项目
% 如果不想显示这个模块，把这一段注释即可
subPitch = {Ranking, Discrimination, Discrimi3I2AFC};
for n = 1:numel(subPitch)    
    module.Pitch(n) = subPitch{n};
end
%--------------------------------------------------------------------------
%% 汉语声调模块
% 单音节
Monosyllable.Type = 'Monosyllable';
Monosyllable.labels = {'Corpus'};
Monosyllable.strings = {{'Wei2004','Wei2004OPUS','Wei2004LTone'}};
Monosyllable.styles = {'popupmenu'};
Monosyllable.fields_for_fname = {'Corpus'};
Monosyllable.note = '单音节声调测试，测试指标为识别率百分比';
% Monosyllable.labels = {'PulseRate';'Corpus'};
% Monosyllable.strings = {{'low','middle','high'};{'Wei2004'}};
% Monosyllable.styles = {'popupmenu';'popupmenu'};
% Monosyllable.fields_for_fname = {'PulseRate';'Corpus'};

% 双音节
Disyllable.Type = 'Disyllable';
Disyllable.labels = {'Corpus';'List';'Periodicity'};
Disyllable.strings = {{'Xiaoya2018'};sprintfc('%g',1:6);{'Yes','No'}};
Disyllable.styles = {'popupmenu';'popupmenu';'popupmenu'};
Disyllable.fields_for_fname = {'Corpus';'List';'Periodicity'};
Disyllable.note = '双音节声调测试，测试指标为识别率百分比';

% Disyllable.labels = {'PulseRate';'Corpus';'List';'Periodicity'};
% Disyllable.strings = {{'low','middle','high'};{'Xiaoya2018'};{'Yes','No'}};
% Disyllable.styles = {'popupmenu';'popupmenu';'popupmenu';'popupmenu'};
%% ***************************************************************
% 修改这里，设置显示在界面上的测试项目
% 如果不想显示这个模块，把这一段注释即可
subLexicial = {Monosyllable, Disyllable};
for n = 1:numel(subLexicial)    
    module.LexicalTone(n) = subLexicial{n};
end
%--------------------------------------------------------------------------
%% 其他小测试模块
ITD_sensitivity.Type = 'ITD_sensitivity';
ITD_sensitivity.labels = {'Samples';'nRepeat'};
ITD_sensitivity.strings = {{'10','16'};{'10','20','25','30'}};
ITD_sensitivity.styles = {'popupmenu';'popupmenu'};
ITD_sensitivity.fields_for_fname = {'Samples'};
ITD_sensitivity.note = 'ITD分辨测试，2I-2AFC，先播放正中的参考音，再播放左或后的测试音，选择第二个声音相对第一个声音的位置，测试指标为正确率';
% AB测试模块
ABTest.Type = 'ABTest';
ABTest.labels = {'Item';'Corpus';'List'};
ABTest.strings = {{'LTone','EQ'};{'OLDEN','MSP','MHINT','Wei2004'};sprintfc('%g',1:30)};
ABTest.styles = {'popupmenu';'popupmenu';'popupmenu'};
ABTest.fields_for_fname = {'Item'};
ABTest.note = 'AB主观倾向性测试，2I-2AFC，统计处理后如LTone处理后的倾向百分比';
%% ***************************************************************
% 修改这里，设置显示在界面上的测试项目
% 如果不想显示这个模块，把这一段注释即可
subOthers = {ITD_sensitivity, ABTest};
for n = 1:numel(subOthers)    
    module.Others(n) = subOthers{n};
end
%--------------------------------------------------------------------------
%% basicInfo结构体用于保存左边的通用基本信息
info(1).labels = {'Mode','Strategy','Vocoder','Gain_L','Vol_L'};
info(1).strings = {{'train','test'},...
                {'ACE','TLE','bACE','bTLE'},{'Classical','Gaussian'},...
                sprintfc('%g',0:30),sprintfc('%g',1:10)};
info(1).styles = {'popupmenu','popupmenu','popupmenu','popupmenu',...
                 'popupmenu'};
info(1).enables = {'on','on','off','off','off'};             
info(2).labels = {'Output','flim','Carrier','Gain_R','Vol_R'};
%info(2).strings = {{'default','ccimobile','vocoder','vocHaptic'},{'50','100','200','300'},...
%                 {'Tone','Noise'},sprintfc('%g',0:30),sprintfc('%g',1:10)};
info(2).strings = {{'default','ccimobile','vocoder','vocHaptic'},{'50','100','200','300'},...
                {'Tone','Noise'},sprintfc('%g',0:30),sprintfc('%g',1:10)};
info(2).styles = {'popupmenu','popupmenu','popupmenu','popupmenu','popupmenu'};
info(2).enables = {'on','off','off','off','off'};  

%% 保存 
save('config.mat','module','info')
