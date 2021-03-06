classdef closedSetView < handle
    % This class is designed for the OLDEN closed-set speech tests 
    % By Huali  Zhou @ acoustics lab in South China University of
    % Technology, Nov 22, 2020;
    % GUI Layout toolbox needed to run this code
    %----------------------------------------------------------------
    
    properties
        nextButton;
        startButton
        progressText; % the text label for displaying the progress
        revPanel; % the panel for displaying the reversals
        ax_Rev; % axis for ploting the reversals
        hRevPlot;
        fhandle;
        selButtonArray;
        oscilloscope;
        ax_spectrogram;
        ax_wavform;
        testObj;
        mode;
        paraText;
    end
    
    methods
        function obj = closedSetView(testObj)
             % general uicontrols for all the tests
            figw =.95;  figh = .95;
            % ctrl_panel_h = .07;
            set(0,'units','normalized');
            scrndim = get(0,'screensize');
            close(findobj('Tag','test'))
            fh = figure('Tag','test', ...
                'numbertitle','off','menubar','none','resize','on', ...
                'units','normalized','position',[(scrndim(3)-figw)/2 (scrndim(4)-figh)/2 figw figh],...
                'CloseRequestFcn',{@my_closereq,obj});
            obj.fhandle = fh;

          
            nRow = 10;
            nCol = 5;
            
            % need the GUI Layout toolbox to draw the selButton matrix
            mainLayout = uix.HBox('Parent', obj.fhandle, ...
                'position',[0.05 0.15  0.9, 0.83],...
                'spacing',5); % the overall layout area for selbuttons
            for n = 1:nCol % create VBox with a number of nCol
                panel(n) = uix.VBox('Parent', mainLayout,'spacing',20,'Padding',10); % divid into horizontal boxes
                for m = 1:nRow % fill each VBox with buttons
                    obj.selButtonArray(m, n)...
                        = uicontrol('style','pushbutton','string',num2str((n-1)*nCol + m),...
                        'parent',panel(n),'FontSize', 20, 'Fontname','??????','enable','off');
                end % end of filling each VBox
            end % end of creating VBox   
            
            panel = uix.HBox('Parent', obj.fhandle, ...
                'position',[0.05 0.01  0.9, 0.14],...
                'spacing',5); % the overall layout area for selbuttons
             % oscilloscope and two axis
            obj.oscilloscope = uipanel('Parent',panel,'Title','?????????','FontSize',12);
%             audioAx = uix.HBox('Parent',obj.oscilloscope,'spacing',5);
%             obj.ax_wavform = axes('Parent',audioAx,'Position',[.05 .05 .45 .9]);
%             obj.ax_spectrogram = axes('Parent',audioAx,'Position',[.55 .05 .45 .9]);
%             set(audioAx, 'Widths', [-1 -1]);
            obj.ax_wavform = axes('Parent',obj.oscilloscope,'Position',[.05 .05 .45 .9]);
            obj.ax_spectrogram = axes('Parent',obj.oscilloscope,'Position',[.55 .05 .45 .9]);
            
            % Next button
            obj.nextButton = uicontrol('style','pushbutton','string','?????????',...
                        'parent',panel,'FontSize', 20, 'Fontname','??????','Enable','off'); 
            
            % the panel for displaying reversals for SRT and TCT
            obj.revPanel = uipanel('Parent',panel,'Title','?????????','FontSize',12);
            obj.ax_Rev = axes('Parent',obj.revPanel,'Position',[.1 .1 .89 .89]);
            obj.hRevPlot = plot(obj.ax_Rev,1:20,NaN(1,20),'LineWidth',2,'color','r');
            set(obj.ax_Rev,'xlim',[1 20],'ylim',[-8 20]);
 
            
                    
            %START button
            obj.startButton = uicontrol('parent',panel,'style','pushbutton','horizontalalignment','right', ...
                'fontweight','bold','fontsize',12,'string','??????','UserData',0);
            
            set(panel,'Widths',[-4 -2 -2 -1]);
            
            
            wordMatrix = {'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????';...
                    '??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????';...
                    '??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????';...
                    '?????????',	'?????????',	'?????????',	'?????????',	'?????????',	'?????????',	'?????????',	'?????????',	'?????????',	'?????????';...
                    '??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????',	'??????'};
                wordMatrix = wordMatrix';
                for n = 1:nCol
                    for m = 1:nRow
                        set(obj.selButtonArray(m,n),'String',wordMatrix{m,n});
                        setappdata(obj.selButtonArray(m,n),'idx',[m, n]);
                    end
                end
              %  obj.selButtonArray.String =  wordMatrix{};
              
              % text to show current progress
            obj.progressText = uicontrol('parent',fh,'style','text','horizontalalignment','left', ...
                'Fontname','??????',...
                'fontsize',16,'string','', ...
                'units','normalized','position',[.96 0.88 .045 .1]);%'fontweight','bold',
            
            obj.paraText = uicontrol('parent',fh,'style','text','horizontalalignment','left', ...
                'Fontname','??????',...
                'fontsize',16,'string','', ...
                'units','normalized','position',[.96 0.6 .045 .1]);%'fontweight','bold',
            
             if nargin > 0 
                obj.testObj = testObj;                
                obj.mode = testObj.basicInfo.mode;
                set(obj.startButton,'callback',{@startFcnt,testObj});
                set(obj.selButtonArray,'callback',{@selFcnt,testObj});
                set(obj.nextButton,'callback',{@nextFcnt,obj});% the next button
                if strcmp(obj.mode, 'test')
                    set(obj.oscilloscope,'visible','off');  
                    set(obj.revPanel,'visible','off');
                    set(obj.paraText,'visible','off');
                end
            end
        end
        

        
        function plot_revs(obj,ydata)
%             if strcmp(obj.mode,'train')
            set(obj.hRevPlot,'ydata',ydata);
            set(obj.ax_Rev,'ylim',[min(ydata)-5 max(ydata)+5]);
%             end
        end
        
        function refresh(obj, outStruct)
%        Input: outStruct is a struct that contains the following fields:
%           1*.audio,(* denotes modatory, others are optional)
%           2*.fs,
%           3.text, ???????????????????????????
%????????????????????????????????????????????????????????????
 
            % ????????????????????????
            audio = [];% ?????????????????????????????????????????????
            for n = 1:length(outStruct.audio)
                audio = [audio; outStruct.audio(n).sig(:,1)]; %???????????????
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
            response = cell2mat(get(obj.selButtonArray,'UserData'))';
            response = reshape(response,10,5);
            answer = -1 * ones(1,5);
            for n = 1:5
                if sum(response(:,n)) % if there's a button selected
                    answer(n) = find(response(:,n))-1;
                end
            end
        end
    end
end
function nextFcnt(~, ~, obj) % ?????????????????????
set(obj.startButton,'UserData',0,'Enable','on');
uiresume(gcbf);
end

function selFcnt(trigObj,~,obj) % ??????????????????
if trigObj.UserData == 1% if already selected
    set(trigObj,'BackgroundColor',obj.colorNonSel,'UserData',0); % clear color and value
else % the button is not selected
    
    idx = getappdata(trigObj,'idx');
   
    set(obj.viewObj.selButtonArray(:,idx(2)),'BackgroundColor',obj.colorNonSel,'UserData',0);
    
    set(trigObj,'BackgroundColor',obj.colorSel,'UserData',1);% set blue color and set value to 1
end
end

function startFcnt(trigObj, ~,obj) 
% hide this button if nReplay is set to 0 at test mode, change to ?????? if feedback
    if strcmp(obj.basicInfo.mode,'test') && obj.basicInfo.nreplay == 0
        set(obj.viewObj.selButtonArray,'Enable','on','UserData',0);
        set(trigObj,'Visible','off');
        obj.run();
    else
        if strcmp(trigObj.String,'??????')
            set(obj.viewObj.selButtonArray,'Enable','on','UserData',0);
            set(trigObj,'String','??????');
            obj.run();
        else % replay
            obj.replay;
            if strcmp(obj.basicInfo.mode,'test')
                nPlayed = get(trigObj,'UserData');
                set(trigObj,'UserData', nPlayed + 1);
                if nPlayed + 1 >= obj.basicInfo.nreplay
                    set(trigObj,'Visible','off');
                end
            end

        end
    end
  
end

function my_closereq(trigObj,~,obj)
    if obj.testObj.ongoingFlag == 1
        answer = questdlg('??????????????????????????????????????????????????????????', ...
            '????????????????????????', ...
            '?????????????????????','????????????','????????????');
        switch answer
            case '?????????????????????'
                delete(trigObj);
            case '????????????'
        end
    else
        delete(trigObj);
    end
end
