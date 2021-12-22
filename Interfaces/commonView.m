classdef commonView < handle
    % commonView defines general test interface with buttons
    % suitable for Mandarin tone,pitch ranking, MCI, 
    % and is the base class of speech tests
    % example:
    %  obj.interface = commonView();
    %  obj.interface.show_interface([2 2]); %[nRow nCol]
    % Author: Huali Zhou
    % Date: 2020-09-07
    
    properties
        fhandle; % 界面figure的handle
        selButtonArray %选择按钮
        feedbackButton %反馈按钮
        startButton % 开始按钮
        oscilloscope %示波器
        ax_wavform %显示波形的axis
        ax_spectrogram %显示语谱图的axis
        progressText % 用于显示进度
        paraText;%用于显示信噪比等参数
    end
    properties(Access = protected)% for setting color when selected or non-selected
        colorSel = [0.3882 0.6235 0.949];
        colorNonSel = [0.9400 0.9400 0.9400];
        testObj;
        mode;
    end
        methods
        function obj = commonView(testObj, selButtonArraySize)% e.g.,selButtonArraySize:[1 7]
            % general uicontrols for all the tests
            figw =.9;  figh = .9;
            % ctrl_panel_h = .07;
            set(0,'units','normalized');
            scrndim = get(0,'screensize');
            close(findobj('Tag','test'))
            fh = figure('Tag','test', ...
                'numbertitle','off','menubar','none','resize','on', ...
                'units','normalized','position',[(scrndim(3)-figw)/2 (scrndim(4)-figh)/2 figw figh],...
                'CloseRequestFcn',{@my_closereq,obj});
            obj.fhandle = fh;
           
          
            % feedback button
            obj.feedbackButton = uicontrol('parent',fh,'style','pushbutton',...
                'horizontalalignment','right', ...
                'fontweight','bold','fontsize',10,'string','<html>结果提示：<br>绿色正确，红色错误</html>',...
                'BackgroundColor','g','Enable','off',...
                'units','normalized','position',[0.5-0.25/2 .3 0.25 .1]);
            
            %START button
            obj.startButton = uicontrol('parent',fh,'style','pushbutton','horizontalalignment','right', ...
                'fontweight','bold','fontsize',12,'string','开始',...
                'units','normalized','position',[.7 .35 .2 .08],'UserData',0);
            
            % oscilloscope and two axis
            hp = uipanel('Parent',fh,'Title','示波器','FontSize',12,...
                'Position',[.02 .02 .35 .42]);
            obj.oscilloscope = hp;
            obj.ax_wavform = axes('Parent',hp,'Position',[.1 .55 .85 .42]);
            obj.ax_spectrogram = axes('Parent',hp,'Position',[.1 .05 .85 .45]);
            linkaxes([obj.ax_wavform, obj.ax_spectrogram], 'x');
            % add context menu
            c = uicontextmenu;            
            % Assign the uicontextmenu to the plot line
            obj.oscilloscope.UIContextMenu = c;
            % Create child menu items for the uicontextmenu
            m1 = uimenu(c,'Label','undock','Callback',{@undockOscilloscope,obj});

            % text to show current progress
            obj.paraText = uicontrol('parent',fh,'style','text','horizontalalignment','left', ...
                'Fontname','楷体',...
                'fontsize',24,'string','', ...
                'units','normalized','position',[.7 0.88 .28 .1]);%'fontweight','bold',
            obj.progressText = uicontrol('parent',fh,'style','text','horizontalalignment','left', ...
                'Fontname','楷体',...
                'fontsize',24,'string','', ...
                'units','normalized','position',[.05 0.88 .48 .1]);%'fontweight','bold',
            
            if nargin > 0 
                obj.testObj = testObj;
                obj.show_interface(selButtonArraySize);
                obj.mode = testObj.basicInfo.mode;
                set(obj.startButton,'callback',{@startFcnt,testObj});
                set(obj.selButtonArray,'callback',{@selectFcnt,testObj});
                if strcmp(obj.mode, 'test')
                    set(obj.oscilloscope,'visible','off');
                    set(obj.feedbackButton,'visible','off');
                end
            end
            
        end
      
        
        function set_instruction(obj, instruction)
            set(obj.progressText,'string',instruction);
        end
        
        function refresh(obj, outStruct)
            %        Input: outStruct is a struct that contains the following fields:
            %           1*.audio,(* denotes modatory, others are optional)
            %           2*.fs,
            %           3.text, 句子或声调对应汉字
            if isfield(outStruct,'text') % 显示文字  
                text = outStruct.text;
                if iscell(text)
                    for n = 1:numel(text) % show the words on the buttons
                        set(obj.selButtonArray(n),'string',text{n});
                    end
                else
                    for n = 1:numel(text) % show the words on the buttons
                        set(obj.selButtonArray(n),'string',text(n));
                    end
                    
                end
            end
            % 画语谱图和波形图
            audio = [];
            for n = 1:length(outStruct.audio)
                audio = [audio; outStruct.audio(n).sig(:,1)]; %只画左声道
            end
            fs = outStruct.audio(1).fs;
            axes(obj.ax_wavform);
            plot((1:length(audio))/fs,audio);            
            ylim([-1 1]);
            xlim([0 length(audio)/fs]);
            zoom on;
            axes(obj.ax_spectrogram);
            myspectrogram(audio,fs);
            zoom on;
            ylim([0 8000]);
            xlim([0 length(audio)/fs]);
        end
        
        function answer = get_answer(obj)
            answer = cell2mat(get(obj.selButtonArray,'UserData'))';% get responses
        end
        
        function feedback(obj,correctness)            
            set(obj.feedbackButton,'BackgroundColor',[1-correctness,correctness,0]);
        end
    end
    
    methods(Access = protected)
         function show_interface(obj, selButtonArraySize) % eg. obj.showinterface([1 3])
            nRow = selButtonArraySize(1);
            nCol = selButtonArraySize(2);
            % adjust button size for small button numbers
            if nCol < 5, bWidth = 0.2; else, bWidth = 0.9/nCol; end
            if nRow == 1,bHight = 0.3; mainHieght = 0.55; 
            else,bHight = 0.45/nRow; mainHieght = 0.45; end
            
            % need the GUI Layout toolbox
            mainLayout = uix.VBox('Parent', obj.fhandle, ...
                'position',[0.5-bWidth * nCol * 0.5 mainHieght bWidth * nCol  bHight * nRow],...
                'spacing',10); % the overall layout area for selbuttons
            for n = 1:nRow % create HBox with a number of nRow
                panel(n) = uix.HBox('Parent', mainLayout,'spacing',10); % divid into horizontal boxes
                for m = 1:nCol % fill each HBox with buttons
                    obj.selButtonArray((n-1)*nCol + m)...
                        = uicontrol('style','pushbutton','string',num2str((n-1)*nCol + m),...
                        'parent',panel(n),'FontSize', 30, 'Fontname','楷体','enable','off');
                end % end of filling each HBox
            end % end of creating HBox   
        end
    end
end

function undockOscilloscope(~,~,obj)
h = figure('name','do not close this figure');
obj.ax_wavform = axes('Parent',h,'Position',[.1 .55 .85 .42]);
obj.ax_spectrogram = axes('Parent',h,'Position',[.1 .05 .85 .45]);
linkaxes([obj.ax_wavform, obj.ax_spectrogram], 'x');
end

function my_closereq(trigObj,~,obj)
    if obj.testObj.ongoingFlag == 1
        answer = questdlg('正在进行中的测试尚未完成，确定要结束吗?', ...
            '请确认是否要结束', ...
            '是的，我要结束','继续测试','继续测试');
        switch answer
            case '是的，我要结束'
                delete(trigObj);
            case '继续测试'
        end
    else
        delete(trigObj);
    end
end

function startFcnt(trigObj, ~,obj)     
% hide this button if nReplay is set to 0 at test mode, change to 重播 if feedback
    if strcmp(obj.basicInfo.mode,'test') && obj.basicInfo.nreplay == 0
        set(obj.viewObj.selButtonArray,'Enable','on','UserData',0);
        set(trigObj,'Visible','off');
        obj.run();
    else % 除测试模式不重播外
        if strcmp(trigObj.String,'开始')
            set(obj.viewObj.selButtonArray,'Enable','on','UserData',0);
            set(trigObj,'String','重播');
            obj.run();
        else % replay
            obj.replay;
            if strcmp(obj.basicInfo.mode,'test')
                nPlayed = get(trigObj,'UserData');
                set(trigObj,'UserData', nPlayed + 1);
                if nPlayed + 1 >= obj.basicInfo.nreplay
                    set(trigObj,'enable','off');
                end
            end
           % return;
        end
    end
  
end

function selectFcnt(trigObj, ~, obj)
obj.selected = str2double(trigObj.String(end));
set(trigObj,'UserData',1);
uiresume(gcbf);
end