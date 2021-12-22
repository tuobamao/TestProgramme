classdef SpeechTestView < commonView
    % SpeechTestView is a subclass of class commonView designed to add some 
    % buttons for speech tests
    % suitable for sentence in quiet , SRT, etc.
    % example:
    %  obj.interface = SpeechTestView();
    %  obj.interface.show_interface([1 10]); %[nRow nCol]
    % By: Huali Zhou 2020-09-20
    
    properties
        nextButton;
        allButton;
        noneButton;
        progressBar;
        revPanel; % the panel for displaying the reversals
        ax_Rev; % axis for ploting the reversals
        hRevPlot;
    end
    
    methods
        function obj = SpeechTestView(testObj, selButtonArraySize)
            obj = obj@commonView(testObj, selButtonArraySize);
            set(obj.selButtonArray,'Value',0);
            obj.progressBar = uicontrol('parent',obj.fhandle,'style','slider',...
                'value',0,'BackgroundColor',[0.3882 0.6235 0.949],...
                'unit','normalized','position',[.05 0.92 .5 .05],'Visible','off');
            set(obj.feedbackButton,'visible','off');% hide the feedback button
            mainLayout = uix.VBox('Parent', obj.fhandle, ...
                'position',[0.38  0.1 .3 .34],'spacing',20,'padding',10); 
            panel(1) = uix.HBox('Parent', mainLayout,'spacing',30);
            panel(2) = uix.HBox('Parent', mainLayout);
            obj.allButton = uicontrol('style','pushbutton','string','全对',...
                        'parent',panel(1),'FontSize', 20, 'Fontname','楷体');
            obj.noneButton = uicontrol('style','pushbutton','string','全错',...
                        'parent',panel(1),'FontSize', 20, 'Fontname','楷体'); 
            obj.nextButton = uicontrol('style','pushbutton','string','下一句',...
                        'parent',panel(2),'FontSize', 20, 'Fontname','楷体');  
                    
            % the panel for displaying reversals for SRT and TCT
            obj.revPanel = uipanel('Parent',obj.fhandle,'Title','自适应过程','FontSize',12,...
                'Position',[.7 .02 .28 .3],'Visible','On');
            if strcmp(obj.mode, 'test')
                set(obj.revPanel,'visible','off');
            end
            obj.ax_Rev = axes('Parent',obj.revPanel,'Position',[.1 .1 .85 .85]);
            obj.hRevPlot = plot(obj.ax_Rev,1:20,NaN(1,20),'LineWidth',2,'color','r');
            set(obj.ax_Rev,'xlim',[1 20],'ylim',[-8 20]);
            
            set(obj.allButton,'callback',{@allFcnt,obj}); % select all button
            set(obj.noneButton,'callback',{@noneFcnt,obj}); % select none button
            set(obj.nextButton,'callback',{@nextFcnt,obj});% the next button
            set(obj.selButtonArray,'callback',{@selFcnt,obj}); % the interval choose
        end    
        
        function plot_revs(obj,ydata) % 画自适应过程
            set(obj.hRevPlot,'ydata',ydata);
            set(obj.ax_Rev,'ylim',[min(ydata)-5 max(ydata)+5]);
        end

        
        function answer = get_answer(obj)
            answer = cell2mat(get(obj.selButtonArray,'UserData'))';% get responses
        end
    end
end

function allFcnt(~,~,obj) % 全对按钮回调
set(obj.selButtonArray,'BackgroundColor',obj.colorSel,'UserData',1);% set blue color and set value to 1
end
function noneFcnt(~,~,obj) % 全错按钮回调
set(obj.selButtonArray,'BackgroundColor',obj.colorNonSel,'UserData',0);
end

function nextFcnt(~,~,obj) % 下一句按钮回调
set(obj.startButton,'UserData',0,'Enable','on');
uiresume(gcbf);
end

function selFcnt(trigObj,~,obj) % 单字按钮回调
    if trigObj.UserData == 1% if already selected
        set(trigObj,'BackgroundColor',obj.colorNonSel,'UserData',0); % clear color and value
    else % the button is not selected 
        if isa(obj,'closedSetView')
            idx = getappdata(trigObj,'idx');
            set(obj.selButtonArray(:,idx(2)),'BackgroundColor',obj.colorNonSel,'UserData',0);
        end
        set(trigObj,'BackgroundColor',obj.colorSel,'UserData',1);% set blue color and set value to 1
    end
end
