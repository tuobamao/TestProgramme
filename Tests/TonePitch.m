classdef TonePitch < matlab.mixin.SetGet
%TonePitch ���������߲��Ե�ͨ�ò��֣�����complex tone discrimination��complex tone ranking
% by Huali Zhou @ Acoustics lab, South China University of Technology
% Sep 27, 2020 
    properties(Constant)
        STEPS = [6, 4, 2, 1.5, 1]; % ����
        nRevEachStep = [2, 2, 2, 2, 6];% ����ֻҪ13�����������ˣ������������һ���Դα����ʱ��ȱ��һ������...
        %Ϊ������Ķ��룬���ӵ�14��������ֻ��Ϊ����ʾ��ʵ�ʲ����õ������С�
        nD1U = 2;%������һ��        
        nRevs = 13; %һ����13����ת�㣻
        nLastRevs = 6;% ȡ���6����ת��������
    end
    properties %(Access = protected)
        soundProp = struct(); % struct that defines the properties of generated sounds.
        viewObj;
        soundpoolObj;
        procedureObj;
        nAFC;        
        basicInfo; % a struct including basicInfo from the app designer
        deltaF;
        targetOrder; %�����ݴ�Ŀ�����ڵڼ�����  
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
                    set(obj.viewObj.instruction,'string','��ѡ������Ϊ�����ϸߵ��Ǹ�');
                elseif para.nAFC == 3
                    set(obj.viewObj.instruction,'string','��ѡ������Ϊ������ͬ���Ǹ�');
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
                obj.soundProp.harmonicNumber = 5; %г������
                obj.soundProp.nextHarmonicDecrease = 10; %ÿ��г��˥����dB��
                obj.soundProp.eachHarmonicLevelroving = 0; %ÿ��г��������¶�����dB��
                obj.soundProp.RMSroving = 2; %����rms������¶�����dB��
            end
        end
        
        
        function loadSound(obj) % fill the soundpoolObjs with random order
            set(obj.viewObj.selButtonArray,'enable','off');% һ�����Դο�ʼʱ��ѡ��ť��ң��Ȳ�����ɺ��ټ���
            f1 = obj.basicInfo.F0 - obj.procedureObj.value/2;
            f2 = obj.basicInfo.F0 + obj.procedureObj.value/2;
            % which is target
            temp = randi(2,1);% ���ɵ����������1��2. ��Ϊ1���ʾf1��target����Ϊ2���f2��target
            if (temp == 1 && obj.nAFC ==3) %ֻ�е���3�����ҳ鵽�͵���targetʱ����ѡ�͵�f1��Ϊtarget
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
            obj.targetOrder = randi(obj.nAFC,1); % target stimulus�ڵڼ�������
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
                set(obj.viewObj.selButtonArray(n),'BackgroundColor',[0,1,1]);%����ǰ�Ѷ�Ӧ��ť����
                soundObj = obj.soundpoolObj.soundArray(n);
                try                  
                    updateOscilloscope(obj, soundObj); % show the waveform and spectrogram                    
                    if n < obj.nAFC, pause(obj.soundProp.ISI/1000); end % pause ISI
                    set(obj.viewObj.selButtonArray(n),'BackgroundColor',[0.941,0.941,0.941]); %������ɺ��ٱ��
                catch
                    warning('program end');
                    return;
                end
                soundObj.play(obj.basicInfo);

            end
            set(obj.viewObj.selButtonArray,'enable','on');% ������ɺ�ѡ��ť����Ա�ѡ��            
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
    % hide this button if no feedback, change to �ز� if feedback
    if strcmp(obj.basicInfo.mode,'test')
        set(trigObj,'Visible','off');
    else
        if strcmp(trigObj.String,'��ʼ')
            set(trigObj,'String','�ز�');
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
    value = obj.basicInfo.F0/2; % ��ʼdelta
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
        answer = 1; % ���
        set(obj.viewObj.feedbackButton,'BackgroundColor',[0,1,0]);            
    else
        answer = 0; % ���
        set(obj.viewObj.feedbackButton,'BackgroundColor',[1,0,0]);        
    end
    obj.soundpoolObj.clear; % clear the soundpool for the next trial
    obj.procedureObj.next(answer); % adaptive procedure processing
    obj.printLine; % print record for current trial
    if  obj.procedureObj.continueFlag  == 1 % ��û����,����������һ�Դ�
        obj.loadSound();
        obj.playSound();
    else % �����ˣ����������ʾ����������
        %obj.procedureObj.
        msgbox(sprintf('��ֵ��%.1f,����%.1f', obj.procedureObj.geomeanLast, obj.procedureObj.stdLast));
        obj.endprocedureObj;
    end
end


