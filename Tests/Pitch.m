classdef Pitch < handle
   %TonePitch 复合音音高测试的通用部分，包括complex tone discrimination和complex tone ranking
% by Huali Zhou @ Acoustics lab, South China University of Technology
% Sep 27, 2020 
    properties(Constant)
        STEPS = [6, 4, 2, 1.5, 1]; % 步长
        nRevEachStep = [2, 2, 2, 2, 6];% 本来只要13个步长就行了，但是这样最后一个试次保存的时候缺少一个数，...
        %为与上面的对齐，增加到14个步长，只是为了显示，实际不会用到播放中。
        nD1U = 2;%做两下一上        
        nRevs = 13; %一共做13个反转点；
        nLastRevs = 6;% 取最后6个反转点点计算结果
    end
    properties %(Access = protected)
        outputObj;
        viewObj ; % the interface object
        mainViewObj; % for history refresh
        corpusObj;
        targetRMS;
        basicInfo;
        para;
        ongoingFlag; % 1:running test not ended
        
        soundProp = struct(); % struct that defines the properties of generated sounds.
        procedureObj;
        nAFC;        
        deltaF;
        data = struct(); % 需要保存的数据
    end
    properties(Hidden)
        targetOrder; %用于暂存目标声在第几个放  
        selected; %用于暂存受试者选了第几个
        toneArr; % 用于暂存当前声音，便于重播
        Fs;
        flag3I2AFC;
    end
    
    methods
        function obj = Pitch(basicInfo,para,outputObj, mainViewObj)
            if nargin > 0
                obj.basicInfo = basicInfo; % pass basic info
                obj.para = para;
                obj.outputObj = outputObj;% set outputObj
                obj.mainViewObj = mainViewObj;
                
                switch para.testType
                    case 'Ranking'
                        obj.para.nAFC = 2;
                        obj.viewObj = commonView(obj, [1 obj.para.nAFC]);
                        obj.viewObj.set_instruction('请选择你认为音调较高的那个');
                    case 'Discrimination'
                        obj.para.nAFC = 3;
                        obj.viewObj = commonView(obj, [1 obj.para.nAFC]);
                        obj.viewObj.set_instruction('请选择你认为音调不同的那个');
                    case 'Discrimi3I2AFC'
                        obj.para.nAFC = 3;
                        obj.viewObj = commonView(obj, [1 obj.para.nAFC]);
                        obj.viewObj.set_instruction('请选择你认为音调不同的那个');
                        set(obj.viewObj.selButtonArray(1),'Enable','off');
                        obj.flag3I2AFC = 1;
                    otherwise
                        errordlg('Unknown test type, should be ranking or discrimination');
                end

                
                % attibutes of test stimuli: harmonic complex tone
                obj.soundProp.ISI = para.isi_ms;
                obj.soundProp.duration = para.duration_ms;
                obj.soundProp.ramp = para.ramp_ms;
                obj.soundProp.harmonicNumber = para.n_harmonics; %谐波个数
                obj.soundProp.nextHarmonicDecrease = para.rolloff_oct_db; %每次谐波衰减（dB）
                obj.soundProp.eachHarmonicLevelroving = para.roving_harmonic_db; %每次谐波随机上下抖动（dB）
                obj.soundProp.RMSroving = para.roving_rms_db; %整体rms随机上下抖动（dB）
                
%                 % open an adaptive procedureObj
%                 switch obj.para.f0
%                     case 250, stdSpec = 9.77;
%                     case 313, stdSpec = 12.65;
%                     case 1000, stdSpec = 23.84;
%                     case 1063, stdSpec = 25.78;
%                     otherwise, stdSpec = 0.01;
%                 end
                stdSpec = 0.001;
                %obj.para.f0 = str2double(obj.para.f0); % convert F0 to digital
                value = obj.para.f0/2; % 初始delta
                obj.procedureObj = AdaptiveProcedureIndependent(obj.STEPS,obj.nRevEachStep,...
                    obj.nD1U,value, obj.nRevs,obj.nLastRevs, stdSpec);% open an adaptive procedure
               % fprintf(obj.basicInfo.resultFID,num2str(obj.procedureObj.value));% record the first presentation level at the beginning
                
              obj.data.F0DL = [];
              obj.data.deltaF0Arr = [];
              obj.data.correctnessArr = [];
              obj.data.isRevArr = [];
              obj.data.nextStepArr = [];
            end
        end
        
        function run(obj)
            obj.ongoingFlag = 1;
            while  obj.procedureObj.continueFlag  == 1 % 还没结束,继续播放下一试次
                [obj.toneArr ,obj.Fs] = loadSound(obj);
                for n = 1:obj.para.nAFC
                    set(obj.viewObj.selButtonArray(n),'BackgroundColor',[0,1,1]);%播放前把对应按钮点亮
                    obj.viewObj.refresh('12',obj.toneArr(:,n),obj.Fs);
                    obj.outputObj.output(obj.toneArr(:,n),obj.Fs);
                    
                    pause(obj.soundProp.duration/1000); % 应该在输出那里pause，为了调试方便，在这里pause
                    set(obj.viewObj.selButtonArray(n),'BackgroundColor',[0.941,0.941,0.941]); %播放完成后再变灰
                    pause(obj.soundProp.ISI/1000 * (n < 3));                    
                end
                set(obj.viewObj.selButtonArray,'enable','on');% 播放完成后将选择按钮激活，以便选择
                if obj.flag3I2AFC == 1
                     set(obj.viewObj.selButtonArray(1),'Enable','off');
                end
                uiwait(obj.viewObj.fhandle);
                correctness = (obj.targetOrder == obj.selected);
                obj.viewObj.feedback(correctness);
                obj.data.correctnessArr = [obj.data.correctnessArr; correctness];              
                obj.procedureObj.next(correctness); % adaptive procedure processing
                obj.data.isRevArr = [obj.data.isRevArr; obj.procedureObj.isReversal];            
            end
            % 结束了，弹出结果提示，结束测试
            obj.ongoingFlag = 0;
            obj.save_result();
            msgbox(sprintf('均值：%.1f,方差%.1f', obj.procedureObj.geomeanLast, obj.procedureObj.stdLast));
            close(obj.viewObj.fhandle);%obj.endprocedureObj;
            delete(obj.viewObj);
            delete(obj.procedureObj);
            delete(obj);
            
            return;
        end
        
        
        function replay(obj)
            for n = 1:obj.para.nAFC
                set(obj.viewObj.selButtonArray(n),'BackgroundColor',[0,1,1]);%播放前把对应按钮点亮
                obj.viewObj.refresh('12',obj.toneArr(:,n),obj.Fs);
                obj.outputObj.output(obj.toneArr(:,n),obj.Fs);
                pause(obj.soundProp.duration/1000); % 应该在输出那里pause，为了调试方便，在这里pause
                set(obj.viewObj.selButtonArray(n),'BackgroundColor',[0.941,0.941,0.941]); %播放完成后再变灰
                pause(obj.soundProp.ISI/1000 * (n < 3));
            end
        end
    end
    
    methods(Access = private)
        function [toneArr ,Fs] = loadSound(obj) % fill the soundpoolObjs with random order
            set(obj.viewObj.selButtonArray,'enable','off');% 一个新试次开始时将选择按钮变灰，等播放完成后再激活
            obj.data.deltaF0Arr = [obj.data.deltaF0Arr; obj.procedureObj.value];
            f1 = obj.para.f0 - obj.procedureObj.value/2;
            f2 = obj.para.f0 + obj.procedureObj.value/2;
            % which is target
            temp = randi(2,1);% 生成单个随机数，1或2. 若为1则表示f1是target，若为2则表f2是target
            if (temp == 1 && obj.para.nAFC ==3) %只有当放3个音且抽到低的是target时，才选低的f1做为target
                f_tar = f1;
                f_ref = f2;
            else
                f_tar = f2;
                f_ref = f1;
            end
            fprintf('target frequency is %0.1f Hz\n',f_tar);
            fprintf('reference frequency is %0.1f Hz\n', f_ref);
            fprintf('deltaF0 is %0.1f Hz\n',obj.procedureObj.value)
            
            % fill the soundpoolObj
            if obj.flag3I2AFC == 1
                obj.targetOrder = randi([2 3]);
            else
                obj.targetOrder = randi(obj.para.nAFC,1); % target stimulus在第几个播放
            end
            for n = 1:obj.para.nAFC
                if n == obj.targetOrder
                    [toneArr(:,n),Fs] = obj.generate_tone(f_tar);
                else
                    [toneArr(:,n),Fs] = obj.generate_tone(f_ref);
                end
            end % end of loop  for filling soundpool
        end
        
        function [tone, Fs] = generate_tone(obj, F0)
            %obj.F0 = F0;
            Fs = 16000; %采样率
            N = obj.soundProp.duration/1000*Fs;% 采样点数
            t = (0:N-1)/Fs;
            rampDuration = obj.soundProp.ramp/1000;
            harmonicNumber = obj.soundProp.harmonicNumber;
            nextHarmonicDecrease = 10^(obj.soundProp.nextHarmonicDecrease/20);
            
            % generate complex tones,with next harmonic decrease and each harmonic
            % level roving
            ComplexTone = 0.8*sin(2*pi*F0*t+2*pi*rand(1)); % the fundamental frequency
            for n = 1:harmonicNumber
                if n > 1
                    eachHarmonicLevelroving = 10^((rand(1)*obj.soundProp.eachHarmonicLevelroving*2-obj.soundProp.eachHarmonicLevelroving)/20);
                    ComplexTone = ComplexTone + 0.8*sin(2*pi*F0*n*t+2*pi*rand(1))/(nextHarmonicDecrease.^(n-1))*eachHarmonicLevelroving;
                end
            end
            % apply ramp up and ramp down
            tone = ComplexTone;
            
            tone = rampFcnt(tone,Fs,rampDuration);
            
            % apply overall level roving
            RovedLevel = 10^((rand(1)*obj.soundProp.RMSroving*2-obj.soundProp.RMSroving)/20);
            tone = tone * obj.para.targetRMS / rms(tone) * RovedLevel;% apply rms roving
        end
        
        function save_result(obj)
            % 在测试历史表格中增加一个记录
            result = obj.procedureObj.geomeanLast;
            newRecord = {obj.para.testType,obj.basicInfo.name,obj.basicInfo.fname,result};
            obj.mainViewObj.refresh_history(newRecord);
            % 数据保存json文件
            currentResultsDir = ['.\Records\',obj.para.testType,'\',obj.basicInfo.name,'\'];
            if ~isfolder(currentResultsDir), mkdir(currentResultsDir); end
            fileName = [currentResultsDir,obj.basicInfo.fname, '.json'];
            saveData.basicInfo = obj.basicInfo;
            saveData.testPara = obj.para;
            saveData.progressData = obj.data;
            temp = properties(obj.procedureObj);
            for n = 1:numel(temp)
                saveData.progressData.(temp{n}) = obj.procedureObj.(temp{n});
            end          
            savejson('', saveData, fileName);
        end
    end
end

%% callback functions



function y = rampFcnt(tone,Fs,T)
% input: x - could be row or column vectors
%        T - the duration of the ramp in ms
% output: y - column vectors
x = tone;
t = (0:round(T*Fs))/Fs;
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
N0 = Fs*0.04;
z0 = zeros(N0,1);
y = [z0;y,;z0];
%tone = y;
end