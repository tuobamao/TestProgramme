classdef TonePitch < matlab.mixin.SetGet
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
        soundProp = struct(); % struct that defines the properties of generated sounds.
        viewObj;
        soundpoolObj;
        procedureObj;
        nAFC;        
        basicInfo; % a struct including basicInfo from the app designer
        deltaF;
        targetOrder; %用于暂存目标声在第几个放  
    end
    
    methods
        function obj = TonePitch(basicInfo,para)
            if nargin > 0
                % show the pitch ranking viewObj
                obj.basicInfo = basicInfo;
                obj.nAFC = para.nAFC ;
                obj.viewObj = commonView();
                obj.viewObj.show_interface([1 para.nAFC]);
                if para.nAFC == 2
                    set(obj.viewObj.instruction,'string','请选择你认为音调较高的那个');
                elseif para.nAFC == 3
                    set(obj.viewObj.instruction,'string','请选择你认为音调不同的那个');
                else
                    errdlg('Unknow nAFC, should be 2 or 3');
                    return;
                end
                if strcmp(obj.basicInfo.mode,'test')
                    obj.viewObj.no_feedback;
                end % end of viewObj setting
                
                % set call back for the start button
                set(obj.viewObj.startButton,'callback',{@startFcnt,obj});
                for n=1:obj.nAFC
                    set(obj.viewObj.selButtonArray(n),'callback',{@selectFcnt,obj});
                end
                
                % attibutes of test stimuli: harmonic complex tone
                obj.soundProp.ISI = 300;
                obj.soundProp.duration = 400;
                obj.soundProp.ramp = 10;
                obj.soundProp.harmonicNumber = 5; %谐波个数
                obj.soundProp.nextHarmonicDecrease = 10; %每次谐波衰减（dB）
                obj.soundProp.eachHarmonicLevelroving = 0; %每次谐波随机上下抖动（dB）
                obj.soundProp.RMSroving = 2; %整体rms随机上下抖动（dB）
            end
        end
        
        
        function loadSound(obj) % fill the soundpoolObjs with random order
            set(obj.viewObj.selButtonArray,'enable','off');% 一个新试次开始时将选择按钮变灰，等播放完成后再激活
            f1 = obj.basicInfo.F0 - obj.procedureObj.value/2;
            f2 = obj.basicInfo.F0 + obj.procedureObj.value/2;
            % which is target
            temp = randi(2,1);% 生成单个随机数，1或2. 若为1则表示f1是target，若为2则表f2是target
            if (temp == 1 && obj.nAFC ==3) %只有当放3个音且抽到低的是target时，才选低的f1做为target
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
            obj.targetOrder = randi(obj.nAFC,1); % target stimulus在第几个播放
            for n = 1:obj.nAFC
                if n == obj.targetOrder
                    soundObj = generatedTones(f_tar,obj.soundProp);
                else
                    soundObj = generatedTones(f_ref,obj.soundProp);
                end
                
                soundObj.vocoder(obj.basicInfo);% apply vocoder               
                obj.soundpoolObj.add(soundObj); % add into the soundPool for later play
            end % end of loop  for filling soundpool
            

        end
        
        function playSound(obj)%play the sounds in the soundpoolObj,and flash buttons
            for n = 1:obj.nAFC
                set(obj.viewObj.selButtonArray(n),'BackgroundColor',[0,1,1]);%播放前把对应按钮点亮
                soundObj = obj.soundpoolObj.soundArray(n);
                try                  
                    updateOscilloscope(obj, soundObj); % show the waveform and spectrogram                    
                    if n < obj.nAFC, pause(obj.soundProp.ISI/1000); end % pause ISI
                    set(obj.viewObj.selButtonArray(n),'BackgroundColor',[0.941,0.941,0.941]); %播放完成后再变灰
                catch
                    warning('program end');
                    return;
                end
                soundObj.play(obj.basicInfo);

            end
            set(obj.viewObj.selButtonArray,'enable','on');% 播放完成后将选择按钮激活，以便选择            
        end % end of function playSound
        
        function endprocedureObj(obj) % delete objects
            printProperties(obj,obj.basicInfo.resultFID); % print parameters
            
            % add a record in the history mat file
            update_history(obj);
            
            fclose(obj.basicInfo.resultFID);
            delete(obj.viewObj.fhandle);
            delete(obj.viewObj);
            delete(obj.procedureObj);
            delete(obj.soundpoolObj);
            delete(obj);
            return;
        end
        
        function printLine(obj)
            %             fprintf(obj.basicInfo.resultFID,[num2str(obj.procedureObj.value),' ',num2str(obj.procedureObj.answers(end)),' ',num2str(obj.procedureObj.isReversal),' '...
            %                     num2str(obj.STEPS(obj.procedureObj.stage)),'\r\n']);
            if  obj.procedureObj.continueFlag  == 1 % 
                fprintf(obj.basicInfo.resultFID,[' ',num2str(obj.procedureObj.answers(end)),' ',num2str(obj.procedureObj.isReversal),' '...
                    num2str(obj.STEPS(obj.procedureObj.stage)),'\r\n',num2str(obj.procedureObj.value)]);
            else
                fprintf(obj.basicInfo.resultFID,[' ',num2str(obj.procedureObj.answers(end)),' ',num2str(obj.procedureObj.isReversal),' '...
                    num2str(obj.STEPS(obj.procedureObj.stage)),'\r\n']);
            end
        end
    end
end

%% callback functions
% callback function for the start button
function startFcnt(trigObj, ~,obj)
    % hide this button if no feedback, change to 重播 if feedback
    if strcmp(obj.basicInfo.mode,'test')
        set(trigObj,'Visible','off');
    else
        if strcmp(trigObj.String,'开始')
            set(trigObj,'String','重播');
        else
            obj.playSound;
            return;
        end
    end
    
    % open an adaptive procedureObj
    switch obj.basicInfo.F0
        case 250, stdSpec = 9.77;
        case 313, stdSpec = 12.65;
        case 1000, stdSpec = 23.84;
        case 1063, stdSpec = 25.78;
        otherwise, stdSpec = 0.01;
    end
    %obj.basicInfo.F0 = str2double(obj.basicInfo.F0); % convert F0 to digital
    value = obj.basicInfo.F0/2; % 初始delta
    obj.procedureObj = AdaptiveProcedureIndependent(obj.STEPS,obj.nRevEachStep,...
        obj.nD1U,value, obj.nRevs,obj.nLastRevs, stdSpec);% open an adaptive procedure
     fprintf(obj.basicInfo.resultFID,num2str(obj.procedureObj.value));% record the first presentation level at the beginning 

    % create a soundpoolObj and play the first trial
    obj.soundpoolObj = soundPool();
    obj.loadSound();
    obj.playSound();
end

% callback function for the select bottons
function selectFcnt(trigobj, ~, obj)
    if str2double(trigobj.String) == obj.targetOrder
        answer = 1; % 答对
        set(obj.viewObj.feedbackButton,'BackgroundColor',[0,1,0]);            
    else
        answer = 0; % 答错
        set(obj.viewObj.feedbackButton,'BackgroundColor',[1,0,0]);        
    end
    obj.soundpoolObj.clear; % clear the soundpool for the next trial
    obj.procedureObj.next(answer); % adaptive procedure processing
    obj.printLine; % print record for current trial
    if  obj.procedureObj.continueFlag  == 1 % 还没结束,继续播放下一试次
        obj.loadSound();
        obj.playSound();
    else % 结束了，弹出结果提示，结束测试
        %obj.procedureObj.
        msgbox(sprintf('均值：%.1f,方差%.1f', obj.procedureObj.geomeanLast, obj.procedureObj.stdLast));
        obj.endprocedureObj;
    end
end


