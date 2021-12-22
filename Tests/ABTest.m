classdef ABTest < SubTest
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        para;
        %textArr;
        beforeAudioArr;
        afterAudioArr;
        afterArr; % 处理后的afterAudio在第几个区间播放
        answerArr; % 受试者选择第几个
    end
    
    methods
        function obj = ABTest(para, mainTestObj)
            obj = obj@SubTest();
            if nargin > 0
                obj.para = para;
                obj.mainTestObj = mainTestObj;   
                obj.mainTestObj.viewObj = commonView(mainTestObj, [1 2]);
                obj.mainTestObj.viewObj.set_instruction('请选择你更喜欢哪一个声音');
            end            
        end
        
        function obj = initialize(obj)
            %METHOD1 此处显示有关此方法的摘要
            %   此处显示详细说明
            [obj.beforeAudioArr, obj.afterAudioArr] = get_randomized_text_audio(obj.para.item, obj.para.corpus, obj.para.list);
            
            obj.data.result = [];
            %obj.data.textArr = obj.textArr;
            obj.data.afterArr = randi(2,[size(obj.beforeAudioArr,1),1]);
            obj.data.answerArr = [];
           % obj.data.perferArr = [];
           obj.mainTestObj.currentOutput.viewObj = obj.mainTestObj.viewObj;
        end
        function run(obj)
            for iTrial = 1:size(obj.beforeAudioArr,1)
                set(obj.mainTestObj.viewObj.progressText,'String',sprintf('请选择你更喜欢哪一个声音,当前第%d，共%d',iTrial,size(obj.beforeAudioArr,1)));
                audioStruct = process_audio(obj,iTrial);
                obj.mainTestObj.currentOutput.audio = audioStruct;
                obj.mainTestObj.outputObj.output(obj.mainTestObj.currentOutput);
                uiwait(obj.mainTestObj.viewObj.fhandle);  
                answer = obj.mainTestObj.viewObj.get_answer();
                obj.process_answer(answer);
            end
        end
        
        function audioStruct = process_audio(obj,iTrial)
            % 读取处理前即经opus处理的音频，并调整rms到targetRMS
            [beforeAudio, beforeFs] = audioread(obj.beforeAudioArr(iTrial,:));
            [afterAudio, afterFs] = audioread(obj.afterAudioArr(iTrial,:));
             
             if beforeFs ~= afterFs % 如果处理前后采样率不一样，以处理后的为准
                 beforeAudio = resample(beforeAudio, afterFs, beforeFs);                 
             end
           
             %----------对播放声级的调整—————————————————             
            if strcmp(obj.para.item, 'LTone') % LTone的处理前的rms调到0.05,LTone处理的时候是先调到0.05再处理的
                beforeAudio = beforeAudio / rms(beforeAudio) * 0.05 ;                
            else % EQ的则是把处理前后的rms都调到0.05
                beforeAudio = beforeAudio / rms(beforeAudio) * 0.05;
                afterAudio = afterAudio / rms(afterAudio) * rms(beforeAudio);%调整到rms一样
            end
                       
            % 处理前后出现的顺序按照事先随机好的顺序排列  
            audioStruct(1).sig = beforeAudio;
            audioStruct(1).fs = afterFs;
            audioStruct(2) = audioStruct(1);
            targetInterval = obj.data.afterArr(iTrial);
            audioStruct(targetInterval).sig = afterAudio;
        end
        
        function process_answer(obj,answer)
            %METHOD1 此处显示有关此方法的摘要
            %   此处显示详细说明
            obj.data.answerArr = [obj.data.answerArr; find(answer)];
            set(obj.mainTestObj.viewObj.selButtonArray,'UserData',0);  
            
            obj.mainTestObj.viewObj.feedback(find(answer) == obj.data.afterArr(length(obj.data.answerArr)));
        end
        
         function result = calculate_result(obj)
            result = sum(obj.data.afterArr == obj.data.answerArr)/length(obj.data.answerArr);
            obj.data.result = result;
            msgbox(sprintf('恭喜您，测试结束，结果 %.1f',result));
        end
    end
end

function [beforeAudioArr, afterAudioArr] = get_randomized_text_audio(item, corpus, list)
paraBefore.list = list;
paraBefore.corpus = [corpus,'_OPUS'];
paraAfter.list = list;
paraAfter.corpus = [corpus,'_', item];
before = Corpus(paraBefore);
after = Corpus(paraAfter);
beforeAudioArr = before.audioArr;
afterAudioArr = after.audioArr;
rng('shuffle');
order = randperm(size(beforeAudioArr,1));
beforeAudioArr = beforeAudioArr(order,:);
afterAudioArr = afterAudioArr(order,:);

%     if strcmp(corpus, 'OLDEN')
%         wordMatrix = {'郭毅',	'李锐',	'沈悦',	'王石',	'徐敏',	'杨硕',	'张伟',	'郑贤',	'周明',	'朱婷';...
%             '带走',	'借来',	'看见',	'留下',	'买回',	'拿起',	'弄丢',	'收好',	'需要',	'找出';...
%             '一个',	'两个',	'三个',	'四个',	'五个',	'六个',	'七个',	'八个',	'九个',	'十个';...
%             '彩色的',	'大号的',	'很旧的',	'便宜的',	'漂亮的',	'普通的',	'奇怪的',	'全新的',	'特别的',	'用过的';...
%             '板凳',	'茶杯',	'灯笼',	'饭盒',	'花瓶',	'戒指',	'闹钟',	'书包',	'水壶',	'玩具'};
%         % 生成音频文件名矩阵
%         indexList = importdata(['.\Sounds\ABTest\',item,'\OLDEN\text\OLDEN',num2str(list),'.txt']); %句子成分数字组合
%         indexList = char(indexList);% convert cell to char
%         nSentence = size(indexList,1);
%         preNameM = repmat(['.\Sounds\ABTest\',item,'\OLDEN\before\'], nSentence,1);
%         beforeAudioArr = [preNameM,indexList];
%         preNameM = repmat(['.\Sounds\ABTest\',item,'\OLDEN\after\'], nSentence,1);
%         afterAudioArr = [preNameM,indexList];
%         nSentence = size(beforeAudioArr,1);%句表中的句子数
%         
% %         % 读取文本
% %         textArr = cell(nSentence,5);
% %         for n = 1:5
% %             idxN = str2num(indexList(:,n));
% %             temp = (wordMatrix(n,:))';
% %             textArr(:,n) = temp(idxN+1);
% %         end
%         
%     elseif strcmp(corpus,'Wei2004')
%         nSentence = 100;
%         %生成音频文件名矩阵
%         nChar = repelem((26:50)',4,1);
%         nTone = repmat((1:4)',25,1);
%         beforeAudioArr = char(compose('.\\Sounds\\ABTest\\%s\\Wei2004\\before\\%d_%d.wav',item,nChar,nTone));
%         afterAudioArr = char(compose('.\\Sounds\\ABTest\\%s\\Wei2004\\after\\%d_%d.wav',item,nChar,nTone));
% 
%     else
% %         % 读取文本
%         listTextFile = ['.\Sounds\ABTest\',item,'\',corpus, '\text\',corpus,num2str(list),'.txt'];
%         rawList = importdata(listTextFile);
%         nSentence = size(rawList,1);%句表中的句子数
% %         [~,rawList] = cellfun(@strtok, rawList, 'UniformOutput', false);
% %         rawList = char(rawList);
% %         textArr = rawList(:,2:end);
%         %nSentence = size(textArr,1);%句表中的句子数
% 
%         %生成音频文件名矩阵
% 
%         preName = sprintf('.\\Sounds\\ABTest\\%s\\%s\\before\\%s',item,corpus,lower(corpus));
%         preNameM = repmat(preName, nSentence,1);
%         str1 = sprintf('%03d.wav',(list-1)*nSentence+1:(list-1)*nSentence+nSentence);
%         str2 = reshape(str1,[],nSentence);
%         beforeAudioArr = [preNameM,str2'];
% 
%         preName = sprintf('.\\Sounds\\ABTest\\%s\\%s\\after\\%s',item,corpus,lower(corpus));
%         preNameM = repmat(preName, nSentence,1);
%         str1 = sprintf('%03d.wav',(list-1)*nSentence+1:(list-1)*nSentence+nSentence);
%         str2 = reshape(str1,[],nSentence);
%         afterAudioArr = [preNameM,str2'];
%     end
%     % 文本和音频对应随机顺序
%     rng('shuffle');
%     sentenceOrderArray = randperm(nSentence);
%     %textArr = textArr(sentenceOrderArray,:);
%     beforeAudioArr = beforeAudioArr(sentenceOrderArray,:);
%     afterAudioArr = afterAudioArr(sentenceOrderArray,:);
end

% list = dir('.\before\*wav');
% b = load('C:\ZSCUT\TestProgramme\CommonFunctions\filter.mat');
% for n = 1:length(list)
%     [x,fs] = audioread(['.\before\',list(n).name]);
%     y = filter(b.Num,1,x);
%     audiowrite(['.\after\',list(n).name],y,fs);
% 
% end