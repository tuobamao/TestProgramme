classdef Monosyllable < matlab.mixin.SetGet
%     %MonosyllableTone类，适用于单音节字声调测试
%     本类负责调用界面和constantStimuli流程类，控制声调测试的流程
%     使用示例：
%             testobj = MonosyllableTone(); % 
%             set(testobj.viewObj.instruction,'string','请判断您刚才所听到单字的声调：');
%             testobj.start(app);
%      By Huali Zhou  20200919
% -------------------------------------------------------------------------

    properties %(Access = protected)
        score;
        tonePcnt = [0, 0, 0, 0];% 4个声调的正确率  
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
        targetTone; %用于暂存当前试次播放的声调
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
                set(obj.viewObj.instruction,'string','请判断您刚才所听到单字的声调：');
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
            set(obj.viewObj.selButtonArray,'enable','off');% 一个新试次开始时将选择按钮变灰，等播放完成后再激活
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
                set(obj.viewObj.selButtonArray,'enable','on');% 播放完成后将选择按钮激活，以便选择
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
        answer = 1; % 答对        
        set(obj.viewObj.feedbackButton,'BackgroundColor',[0,1,0]); % green the feedback button            
        % 20201010增加统计单个声调正确率
        n = str2double(trigobj.String(end));
        obj.tonePcnt(n) = obj.tonePcnt(n) + 1/25;
    else
        answer = 0; % 答错
        set(obj.viewObj.feedbackButton,'BackgroundColor',[1,0,0]);% red the feedback button         
    end
    obj.nCorrect = obj.nCorrect + answer; % count how many correct answers in a run
    obj.soundpool.clear; % clear the soundpool for next trial
    obj.iTrial = obj.iTrial + 1; % point to next trial
    if  obj.iTrial <= obj.nTotalTrials % 还没结束
        printCurrent(obj, trigobj.String, answer);
        obj.loadSound();
        obj.playSound();
    else % 结束了
        printCurrent(obj, trigobj.String, answer);
        correctRate = obj.nCorrect/obj.nTotalTrials;%calculate the correct rate
        obj.score = correctRate;
        fprintf(obj.basicInfo.resultFID,sprintf('正确率为%.2f(%d/%d)(一声%.2f 二声%.2f 三声%.2f 四声%.2f)',obj.nCorrect/obj.nTotalTrials,...
        obj.nCorrect,obj.nTotalTrials, obj.tonePcnt(1),obj.tonePcnt(2),obj.tonePcnt(3),obj.tonePcnt(4)));
        errordlg(sprintf('恭喜您，测试结束\n正确率为%.2f(一声%.2f 二声%.2f 三声%.2f 四声%.2f)',correctRate*100,obj.tonePcnt(1),obj.tonePcnt(2),obj.tonePcnt(3),obj.tonePcnt(4)),'Finish'); %if done, exit.
        obj.endProcedure;
    end
end


function refresh_buttons(obj)
    set(obj.viewObj.progressText,'String',sprintf('%d/%d',...
        obj.iTrial,obj.nTotalTrials)); % 更新进度提示
    index = obj.procedure.seqTable(obj.iTrial,:); % 获取当前试次的音节和声调索引
    Fourwords = readline(obj.textFile,2*index(1)-1); % 获取音节对应的四个字
    FourPinyins = readline(obj.textFile,2*index(1)); % 获取对应的四个拼音
    FourPinyins = strsplit(FourPinyins, ' '); % 分割成独立的四个拼音
    for n = 1:4
        set(obj.viewObj.selButtonArray(n),'String',[Fourwords(n),' ',FourPinyins{n},' ',num2str(n)]);
    end
    obj.currentWord = Fourwords(index(2)); % 保存当前播放的汉字和注音，便于保存结果
    obj.currentPinYin = FourPinyins{index(2)};
end

function printCurrent(obj, answerTone, answer)
% 打印当前答题情况
fprintf(obj.basicInfo.resultFID,[obj.currentWord,' ',obj.currentPinYin,',播放声调：',num2str(obj.targetTone),', 回答声调：'...
    answerTone(end),' 正误：',num2str(answer),'\r\n']);
end
