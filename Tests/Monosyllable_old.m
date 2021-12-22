classdef Monosyllable < matlab.mixin.SetGet
%     %MonosyllableTone�࣬�����ڵ���������������
%     ���ฺ����ý����constantStimuli�����࣬�����������Ե�����
%     ʹ��ʾ����
%             testobj = MonosyllableTone(); % 
%             set(testobj.viewObj.instruction,'string','���ж����ղ����������ֵ�������');
%             testobj.start(app);
%      By Huali Zhou  20200919
% -------------------------------------------------------------------------

    properties %(Access = protected)
        score;
        tonePcnt = [0, 0, 0, 0];% 4����������ȷ��  
%         score_1;
%         score_2;
%         score_3;
%         score_4;
        viewObj; % the viewObj object
        soundpool; % the soundpool object
        procedure; % the procedure object
        nAFC = 4;
        basicInfo;% struct including strategy,vocoder, mode,resultFID, etc.
        iTrial = 1;
        nTotalTrials; % total trial number in a run
        nCorrect = 0; % correct trials in a run
        targetTone; %�����ݴ浱ǰ�Դβ��ŵ�����
        textFile = '.\Sounds\Wei2004_sounds\Wei2004_words.txt';
        currentWord; % current presented word
        currentPinYin; % pinyin of current presented word
    end
    
    methods
        function obj = Monosyllable(basicInfo,~)
            if nargin > 0
                % show the pitch ranking viewObj
                obj.viewObj = commonView();
                obj.viewObj.show_interface([2 2]);
                set(obj.viewObj.instruction,'string','���ж����ղ����������ֵ�������');
                obj.basicInfo = basicInfo; % pass basic info
                if strcmp(basicInfo.mode,'test')
                    obj.viewObj.no_feedback;
                end % end of viewObj setting
                % set callback function
                set(obj.viewObj.startButton,'callback',{@startFcnt,obj});
                for n=1:obj.nAFC
                    set(obj.viewObj.selButtonArray(n),'callback',{@selectFcnt,obj});
                end
            end
        end
        

        
        function loadSound(obj) % load a sound into soundPool by index iTrial
            set(obj.viewObj.selButtonArray,'enable','off');% һ�����Դο�ʼʱ��ѡ��ť��ң��Ȳ�����ɺ��ټ���
            % fill the soundpool            
            index = obj.procedure.seqTable(obj.iTrial,:); % index for the syllable(1) and tone(2) 
            obj.targetTone = index(2);
            soundName = ['.\Sounds\Wei2004_sounds\',num2str(index(1)+25),'_',num2str(index(2)),'.wav'];
            soundObj = loadedSounds(soundName);%create an object of a loadedsound
            soundObj.vocoder(obj.basicInfo);% apply vocoder processing
            obj.soundpool.add(soundObj); % add into the soundpool           
            refresh_buttons(obj); % show the 4 words on the 4 buttons
        end
        
        function playSound(obj)%play the sounds in the soundpool           
            soundObj = obj.soundpool.soundArray(1);
            try
                updateOscilloscope(obj, soundObj); % show the waveform and spectrogram
                set(obj.viewObj.selButtonArray,'enable','on');% ������ɺ�ѡ��ť����Ա�ѡ��
            catch
                warning('program end');
                return;
            end
            soundObj.play(obj.basicInfo);

        end % end of function playSound
        
        function endProcedure(obj) % delete objects
            update_history(obj);
            delete(obj.viewObj.fhandle);
            delete(obj.viewObj);
            delete(obj.procedure);
            delete(obj.soundpool);
            delete(obj);
            return;
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
    
    % open an adaptive procedure
    obj.procedure = constantStimuli();
    obj.procedure.get_seqTable(25,4);
    obj.nTotalTrials = size(obj.procedure.seqTable, 1);
    
    % create a soundpool and play the first sound
    obj.soundpool = soundPool();    
    obj.loadSound();
    obj.playSound();
end

% callback function for the select bottons
function selectFcnt(trigobj, ~, obj)
    if str2double(trigobj.String(end)) == obj.targetTone
        answer = 1; % ���        
        set(obj.viewObj.feedbackButton,'BackgroundColor',[0,1,0]); % green the feedback button            
        % 20201010����ͳ�Ƶ���������ȷ��
        n = str2double(trigobj.String(end));
        obj.tonePcnt(n) = obj.tonePcnt(n) + 1/25;
    else
        answer = 0; % ���
        set(obj.viewObj.feedbackButton,'BackgroundColor',[1,0,0]);% red the feedback button         
    end
    obj.nCorrect = obj.nCorrect + answer; % count how many correct answers in a run
    obj.soundpool.clear; % clear the soundpool for next trial
    obj.iTrial = obj.iTrial + 1; % point to next trial
    if  obj.iTrial <= obj.nTotalTrials % ��û����
        printCurrent(obj, trigobj.String, answer);
        obj.loadSound();
        obj.playSound();
    else % ������
        printCurrent(obj, trigobj.String, answer);
        correctRate = obj.nCorrect/obj.nTotalTrials;%calculate the correct rate
        obj.score = correctRate;
        fprintf(obj.basicInfo.resultFID,sprintf('��ȷ��Ϊ%.2f(%d/%d)(һ��%.2f ����%.2f ����%.2f ����%.2f)',obj.nCorrect/obj.nTotalTrials,...
        obj.nCorrect,obj.nTotalTrials, obj.tonePcnt(1),obj.tonePcnt(2),obj.tonePcnt(3),obj.tonePcnt(4)));
        errordlg(sprintf('��ϲ�������Խ���\n��ȷ��Ϊ%.2f(һ��%.2f ����%.2f ����%.2f ����%.2f)',correctRate*100,obj.tonePcnt(1),obj.tonePcnt(2),obj.tonePcnt(3),obj.tonePcnt(4)),'Finish'); %if done, exit.
        obj.endProcedure;
    end
end


function refresh_buttons(obj)
    set(obj.viewObj.progressText,'String',sprintf('%d/%d',...
        obj.iTrial,obj.nTotalTrials)); % ���½�����ʾ
    index = obj.procedure.seqTable(obj.iTrial,:); % ��ȡ��ǰ�Դε����ں���������
    Fourwords = readline(obj.textFile,2*index(1)-1); % ��ȡ���ڶ�Ӧ���ĸ���
    FourPinyins = readline(obj.textFile,2*index(1)); % ��ȡ��Ӧ���ĸ�ƴ��
    FourPinyins = strsplit(FourPinyins, ' '); % �ָ�ɶ������ĸ�ƴ��
    for n = 1:4
        set(obj.viewObj.selButtonArray(n),'String',[Fourwords(n),' ',FourPinyins{n},' ',num2str(n)]);
    end
    obj.currentWord = Fourwords(index(2)); % ���浱ǰ���ŵĺ��ֺ�ע�������ڱ�����
    obj.currentPinYin = FourPinyins{index(2)};
end

function printCurrent(obj, answerTone, answer)
% ��ӡ��ǰ�������
fprintf(obj.basicInfo.resultFID,[obj.currentWord,' ',obj.currentPinYin,',����������',num2str(obj.targetTone),', �ش�������'...
    answerTone(end),' ����',num2str(answer),'\r\n']);
end
