classdef Corpus < handle
    % This class is designed to include common activies of corpus
    % By Huali Zhou 20200920
    properties%(Access = protected)
        btnLayout;%需要几个按钮及如何排列，如[1,7]表示需要一行7个按钮
        correctSpec; % 答对多少比例才算对
        corpusFs; % 语料采样率
        adapObj; % 自适应程序
        textArr; %文字列表
        audioArr; % 音频文件名列表
        correctnessArr;
        nLastMean = 8; % 一般取后8句话做平均
    end
     properties(Access = private)
         isOLDEN = 0; % OLDEN标记
     end
    
    methods
        function obj = Corpus(para)
            if nargin > 0
                % 生成随机化的文字和音频列表
                corpus = para.corpus;
                if contains(para.corpus,'_')
                    corpus = corpus(1:strfind(corpus,'_')-1);
                end
                obj.get_text_audio_Arr(corpus,para.list,para.corpus);
                % 设置相关信息
                obj.btnLayout = size(obj.textArr(1,:));%需要几个按钮及如何排列，如[1,7]表示需要一行7个按钮
                info = audioinfo(obj.audioArr(1,:)) ; % 语料采样率
                obj.corpusFs = info.SampleRate;
                switch corpus
                    case 'OLDEN'
                        obj.correctSpec = 0.5; % 答对多少比例才算对
                        obj.isOLDEN = 1;
                    case {'MSP','MHINT'}
                        obj.correctSpec = 0.7;
                    otherwise
                        errordlg('Unknown corpus type');
                end
            end
        end
        
        function set_adapObj(obj, iniSNR)
            steps = [8, 4, 2];
            nRevEachStep = [2, 2, 16];% the last one is set high to assure enough steps
            nD1U = 1;
            obj.adapObj = AdaptiveProcedure(steps, nRevEachStep, nD1U, iniSNR);
        end
        
        function next_level(obj,answerArr)
           isCorrect = (sum(answerArr) / length(answerArr)) >= obj.correctSpec;
           obj.correctnessArr = [obj.correctnessArr; isCorrect];
           [change] = obj.adapObj.check_change_reversal(isCorrect);
            if obj.isOLDEN
                obj.adapObj.nextLevel_for_OLDEN(sum(answerArr) / length(answerArr));
            else
                obj.adapObj.nextLevel_for_corpus(change);
            end
        end
        
        function meanLast = calculate_adap_mean(obj)
            if obj.isOLDEN
                meanLast = obj.adapObj.get_OLDEN_result();
            else
                meanLast = mean(obj.adapObj.levelArr(end - obj.nLastMean + 1 : end));
            end
        end
        
        function randomize(obj)
            % 文本和音频对应随机顺序
            rng('shuffle');
            order = randperm(size(obj.textArr,1));
            obj.textArr = obj.textArr(order,:);
            obj.audioArr = obj.audioArr(order,:);
        end
        
    end

    methods(Access = private)
        function get_text_audio_Arr(obj,corpus,list,folder)
            fName = fullfile(pwd,'Sounds',corpus,'text',[corpus, num2str(list),'.json']);
            data = loadjson(fName);
            % 生成文字数组
            obj.textArr = (data.textArr)';
            switch class(obj.textArr{1})
                case 'char'
                    obj.textArr = char(obj.textArr);
                case 'cell'
                    % 这里待改进
                    temp = [obj.textArr{:}];
                    obj.textArr = (reshape(temp,5,[]))';
                    %textArr = textArr;
                otherwise
                    errordlg('Unknown text type','type Error');
            end
            % 生成音频文件路径+名称数组
            obj.audioArr = char((data.audioArr)');
            audioFolder = fullfile(pwd,'Sounds',folder,'\');
            obj.audioArr = [repmat(audioFolder, size(obj.audioArr,1),1),obj.audioArr];
            

        end
    end
    
end

