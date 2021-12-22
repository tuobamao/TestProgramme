classdef MainView < handle
    % This class will show the main test GUI, and some function purely related to GUI
    % Need the GUI Layout Toolbox
    % Huali Zhou @ Acoustics Lab,South China University of Technology. 
    % Jan 9, 2021
    % All the function buttons for running test are tagged 'RunTest'

    properties(Access = private)
        h; % handles to the function uicontrols
        config; % struct for modules in config file,loaded from config.mat
        para = struct();% selected parameters
        typeIdx; % 保存选中的测试项目在config中的索引
    end
    
    methods
        function obj = MainView()
            % creat GUI and set callbacks
            obj.h = MainView.show_GUI; % create GUI
            obj.show_initial_setting(); % show initail setting from config file
            MainView.set_font_color(); % set font and color
            obj.show_history(); % load test history and show in the table 
            set(findobj('Tag','module'),'Callback',{@module_select,obj}); % 
            set(obj.h.output,'Callback',{@outputChange,obj});
            set(obj.h.strategy,'Callback',{@strategyChange,obj});
            set(obj.h.calibrate,'Callback',@calibrate);
            set(obj.h.hisTable,'CellSelectionCallback',{@selHistory,obj});
            set(obj.h.testTypeMenu,'Callback',{@testType_select,obj});
        end
               
        function [basicInfo, para,outputObj] = get_info_para_output(obj)
            basicInfo = obj.getBasicInfo();
            para = obj.getPara();  
            % add fname into basicInfo
            if isfield(basicInfo,'flim')
                strategy = [basicInfo.strategy, num2str(basicInfo.flim)];
            else
                strategy = basicInfo.strategy;
            end            
            fname = sprintf('%s_%s_',basicInfo.output,strategy);            
            % add fields defined in the config file to the record file name
            module = obj.config.module.(para.module);
            temp = module(obj.typeIdx).fields_for_fname;
            fname = fname(1:end-1);
            for n = 1:numel(temp)
                switch obj.h.(lower(temp{n})).Style
                    case 'popupmenu'
                        fname = [fname,'_',char(obj.h.(lower(temp{n})).String(obj.h.(lower(temp{n})).Value))];
                    case 'edit'
                        fname = [fname,'_',obj.h.(lower(temp{n})).String];
                end
            end
            basicInfo.fname = [fname,'_',datestr(now,'yyyymmddHHMMSS')];
            
            outputObj = obj.create_outputObj();
            if isa(outputObj,'GaussianVocoder') && strcmp(basicInfo.mode,'train') %如果是训练模式，高斯脉冲声码器输出电极图
                outputObj.vocObj.electrodogramFlag = 1;
            end
        end
        
        function refresh_history(obj,newRecord)
            history = load('.\Records\history.mat');
            history = history.history;
            history = [newRecord; history];
            save('.\Records\history.mat','history');
            set(obj.h.hisTable,'Data',history);
        end
    end
    
    methods(Access = private)
        function basicInfo = getBasicInfo(obj)
            basicInfo = struct();
            basicInfo.name = obj.h.name.String;
            controlArr = findobj('Parent',obj.h.infoGrid,'Enable','on','Style','popupmenu');
            for n = 1:numel(controlArr)
                rawString = controlArr(n).String{controlArr(n).Value};
                if regexp(rawString,'^\d*$') % 判断是否是纯数字构成
                    basicInfo.(lower(controlArr(n).Tag)) = str2double(rawString);
                else
                    basicInfo.(lower(controlArr(n).Tag)) = rawString;
                end
            end   
            basicInfo.nreplay = obj.h.nreplay.Value - 1;
            refNoise = audioread('.\Sounds\Noise\SSN-MSP.wav');
            basicInfo.targetRMS = myRMS(refNoise/2);
        end
        
        function para = getPara(obj)
            para = struct();
            para.module = obj.para.module;
            para.testType = obj.para.testType;
            [x,~] = audioread('.\Sounds\Noise\SSN-MSP.wav');
            para.targetRMS = myRMS(x/2);
            % get value of all popupmenus
            controlArr = findobj({'Parent',obj.h.paraGrid_1,'-or','Parent',obj.h.paraGrid_2},...
                'Style','popupmenu');
            for n = 1:numel(controlArr)
                rawString = controlArr(n).String{controlArr(n).Value};
                if regexp(rawString,'^-?\d*.?\d*$') % 判断是否是纯数字构成
                    para.(lower(controlArr(n).Tag)) = str2double(rawString);
                else
                    para.(lower(controlArr(n).Tag)) = rawString;
                end
            end
            % get value of all edits
            controlArr = findobj({'Parent',obj.h.paraGrid_1,'-or','Parent',obj.h.paraGrid_2},...
                'Style','edit');
            for n = 1:numel(controlArr)
                rawString = controlArr(n).String;
                if regexp(rawString,'^-?\d*.?\d*$') % 判断是否是纯数字构成
                    para.(lower(controlArr(n).Tag)) = str2double(rawString);
                else
                    para.(lower(controlArr(n).Tag)) = rawString;
                end
            end
        end
                
        function show_initial_setting(obj)
            obj.config = load('config.mat');
            % fill the setting grid
            info = obj.config.info;
            for n = 1:2
                labels = info(n).labels;
                strings = info(n).strings;
                styles = info(n).styles;
                enables = info(n).enables;
                obj.h = fill_grid(obj.h,obj.h.infoGrid, labels, strings,styles,enables);
            end
            set(obj.h.infoGrid,'Width',[-2 -3 -2 -3],'Heights',-1* ones(1,numel(labels))/2);
            
            obj.para.module = 'Speech';
            stringArr = fieldnames(obj.config.module);
            for n = 1:numel(stringArr)
                obj.h.(stringArr{n}) = uicontrol('Parent',obj.h.moduleBox,'Style','radiobutton',...
                    'String',stringArr{n},'Tag','module');
            end
            obj.h.Speech.Value = 1;
            obj.fill_testType_options(obj.config.module.Speech);
        end
        
        function fill_testType_options(obj,module)% 根据所选模块填充子测试项目
            testType = {module.Type};
            set(obj.h.testTypeMenu,'String',testType,'Value',1);
            set(obj.h.testTypeNote,'String',module(1).note);
            testType_select(obj.h.testTypeMenu,[],obj);
        end
        
        function outputObj = create_outputObj(obj)
            strategyPara.strategy = obj.h.strategy.String{ obj.h.strategy.Value};
            if contains(strategyPara.strategy,'TLE')
                strategyPara.flim = str2double(obj.h.flim.String{obj.h.flim.Value});
            end
           
            output = obj.h.output.String{obj.h.output.Value};
            if strcmpi(output, 'default')
                outputObj = DefaultOutput();
            elseif strcmpi(output, 'ccimobile')
                cciPara.subject = obj.h.name.String;
                cciPara.gain_l = str2double(obj.h.gain_l.String{obj.h.gain_l.Value});
                cciPara.gain_r = str2double(obj.h.gain_r.String{obj.h.gain_r.Value});
                cciPara.vol_l = str2double(obj.h.vol_l.String{obj.h.vol_l.Value});
                cciPara.vol_r = str2double(obj.h.vol_r.String{obj.h.vol_r.Value});
                outputObj = CciStream(cciPara,strategyPara);
            elseif contains(output, 'voc') % vocoder or vocHaptic
                vocTypeStr = obj.h.vocoder.String{obj.h.vocoder.Value};
                vocTypeStr = [vocTypeStr, 'Vocoder'];
                outDevice = obj.h.output.String{obj.h.output.Value};
                fh = str2func(outDevice);
                outputObj = fh(vocTypeStr, obj.h.carrier.Value,strategyPara);
            else
                errordlg('unknown output device');
                return;
            end
%             switch obj.h.output.Value
%                 case 1 % default
%                     outputObj = DefaultOutput();
%                 case 2 % ccimobile
%                     cciPara.subject = obj.h.name.String;
%                     cciPara.gain_l = str2double(obj.h.gain_l.String{obj.h.gain_l.Value});
%                     cciPara.gain_r = str2double(obj.h.gain_r.String{obj.h.gain_r.Value});
%                     cciPara.vol_l = str2double(obj.h.vol_l.String{obj.h.vol_l.Value});
%                     cciPara.vol_r = str2double(obj.h.vol_r.String{obj.h.vol_r.Value});
%                     outputObj = CciStream(cciPara,strategyPara);
%                 case {3,4} % vocoder
%                     vocTypeStr = obj.h.vocoder.String{obj.h.vocoder.Value};
%                     vocTypeStr = [vocTypeStr, 'Vocoder'];
%                     outDevice = obj.h.output.String{obj.h.output.Value};
%                     fh = str2func(outDevice);
%                     outputObj = fh(vocTypeStr, obj.h.carrier.Value,strategyPara);
%                     %outputObj = Vocoder(vocTypeStr, obj.h.carrier.Value,strategyPara);
% %                     if obj.h.vocoder.Value == 1
%                         outputObj = ClassicalVocoder(obj.h.carrier.Value,strategyPara);
%                     else
%                         outputObj = GaussianVocoder(obj.h.carrier.Value,strategyPara);
% %                     end
%                 case 4 % vocoder with haptic
%                     outputObj = VocHaptic(vocTypeStr, obj.h.carrier.Value,strategyPara);
% %                     if obj.h.vocoder.Value == 1
% %                         outputObj = ClassicalVocoder(obj.h.carrier.Value,strategyPara);
% %                     else
% %                         outputObj = GaussianVocoder(obj.h.carrier.Value,strategyPara);
%                     end
%                 otherwise
%                     errordlg('unknown output device');
%             end
        end
        
        function show_history(obj)
            history = load('.\Records\history.mat');
            history = history.history;
            set(obj.h.hisTable,'Data',history);
            clear history;
        end
    end
    methods(Static)
        function h = show_GUI()
            % create a figure, leave the following setting area to be
            % filled:
%             h.infoGrid: basic info setting
%             h.moduleBox: for modules: Speech, Pitch, LexicalTone
%             h.testTypeMenu: for test types: e.g.,Quiet, SRT...
%             h.testTypeNote: for notes
%             h.paraGrid_1: e.g., corpus, list
%             h.paraGrid_2:
            close(findobj('Tag','MainWindow'));
            hwnd = figure('Name', 'Psychoacoustic Tests','Tag','MainWindow',...
                'NumberTitle', 'off', 'MenuBar', 'none', ... ...
                'Toolbar', 'none', 'unit', 'normalized', ...
                'outerPosition', [0.1 0.1 0.8 0.8]);
%             jFrame = get(gcf, 'JavaFrame');	
%             set(jFrame,'Maximized',1);
            
            %&&&&&&&&&&&&&&&&&&&&&&&&& top level    &&&&&&&&&&&&&&&&&&&&&
            % divide the layout into 3 horizontal area: top label, middle
            % work area and bottom button
            vbox = uix.VBox('Parent', hwnd, 'Spacing', 2);
            uicontrol('Parent', vbox,'Style','text','horizontalalignment','left',...
                'String', 'Psychoacoustic Tests for Cochlear Implant. V2.0','Tag','head');
            midPart = uix.HBox('Parent', vbox, 'Spacing', 2);
            uicontrol('Parent', vbox,'Style','text',...
                'String', 'Acoustics Lab, South China University of Technology','Tag','head');
            set(vbox, 'Heights', [-1 -14 -1]);
            % A is the main work area with empty spaces at its left and
            % right
            uix.Empty('Parent', midPart);
            A = uix.VBox('Parent', midPart, 'Spacing', 5);
            uix.Empty('Parent', midPart);
            set(midPart, 'Widths',[-1 -90 -1]);
            
            % ************* main work area divide *************************
            % divide the work area into two parts vertically arranged，
            % the top one for setting, the bottom one for history display.
            aSetting = uix.HBox('Parent', A, 'Spacing', 5);
            aHistory = uix.HBox('Parent', A, 'Spacing', 5);
            set(A, 'Heights',[-7 -6]);
            
            %************  for the top part: settings**********************
            % divide into two parts horizontally arranged
            % one for basicInfor, the other for test setting
            infoPanel = uix.BoxPanel( 'Parent', aSetting, 'Title', 'BasicInfo','Padding',1,'Tag','BoxPanel' );  
            testPanel = uix.BoxPanel( 'Parent', aSetting, 'Title', 'Test Settings', 'Padding', 1,'Tag','BoxPanel');  
            set(aSetting,'Widths',[-1.2 -2]);            
            % divide the basicInfo area into two parts horizontally
            infoBox = uix.VBox('Parent',infoPanel,'Spacing',1);
            namePanel = uix.Panel('Parent',infoBox,'Title','','Padding',8);
            infoPanel = uix.Panel('Parent',infoBox,'Title','');
            set(infoBox,'Heights',[-1 -5]); 
            h = struct();
            nameGrid = uix.Grid('Parent',namePanel,'Spacing', 5 ); 
            h.infoGrid = uix.Grid('Parent',infoPanel,'Spacing', 5,'Padding',10); 
            
            % fill the name grid          
            h = fill_grid(h, nameGrid, {'Name'}, {'test'},{'edit'});
            h = fill_grid(h, nameGrid, {'nReplay'}, {{'0','1'}},{'popupmenu'});
            set(nameGrid,'Width',[-2 -3 -2 -3],'Heights',-1);
            
            %********** test settings************************
            % divide the test setting area into two boxes vertically
            testBox  = uix.VBox('Parent',testPanel,'Spacing',1,'Padding',1);
            modulePanel = uix.Panel('Parent',testBox,'Title','');
            settingBox = uix.HBox('Parent',testBox,'Spacing',5);
            set(testBox,'Heights',[-1  -5]);
            
            % -------------------- the module box to be filled
            h.moduleBox = uix.HBox('Parent',modulePanel,'Spacing',10,'Padding',10);

            % devide the settingBox into two parts horizontally
            typePanel = uix.Panel('Parent',settingBox,'Title','','Padding',10);
            paraArea = uix.VBox('Parent',settingBox,'Spacing',5);
            set(settingBox,'Widths',[-1  -2]);
            
            % -------------------sub test type box to be filled
            testTypeBox = uix.VBox('Parent',typePanel,'Spacing',10);
            h.testTypeMenu = uicontrol(testTypeBox,'Style','popupmenu','String',{'1','2'});
            h.testTypeNote = uicontrol(testTypeBox,'Style','text','String','此处是所选测试项目的简要说明','Tag','note');
            set(testTypeBox,'Heights',[-1  -5]);
            
             % divide the paraArea into two parts vertically
             paraPanel = uix.Panel('Parent',paraArea,'Title','','Padding',10);
             runPanel = uix.Panel('Parent',paraArea,'Title','','Padding',1);
             set(paraArea,'Heights',[-5  -1]);
             % run button in the runPanel with empty area besides it
             runBox = uix.HBox('Parent',runPanel,'Spacing', 10);
             h.calibrate = uicontrol(runBox,'Style','togglebutton',...
                'String','play calibation noise','Tag','Calibration');
             h.run = uicontrol('Parent',runBox,...
                 'Style','pushbutton','String','RUN','Tag','Run');
             set(runBox,'Widths',[-1 -2 ]);
             
             % put a grid in the paraPanel and fill it
             paraBox = uix.HBox('Parent',paraPanel,'Spacing', 5);
             h.paraGrid_1 = uix.Grid('Parent',paraBox,'Spacing', 5 );
             h.paraGrid_2 = uix.Grid('Parent',paraBox,'Spacing', 5);
             set(paraBox,'Widths',[-1 -1]);
             
             %****************** history table and figure ***************************
             h.hisPanel = uix.BoxPanel( 'Parent', aHistory, 'Title', 'Test History', 'Tag','BoxPanel');
             h.figurePanel = uix.BoxPanel( 'Parent', aHistory, 'Title', 'Figure', 'Tag','BoxPanel');
             set(aHistory,'Widths',[-1 -1]);
             h.hisTable = uitable('Parent',h.hisPanel,'ForegroundColor', [0.00,0.45,0.74], ...
                 'FontSize', 8,'ColumnWidth','auto','RowStriping','on');
             h.figure.ax = axes('parent',h.figurePanel,'linewidth',2);
             h.figure.curve = plot(h.figure.ax,1:20,1:20,'b','LineWidth',2,'Marker','o','MarkerFaceColor','b','MarkerSize',4);hold on;
             h.figure.result = plot(h.figure.ax,[1,20],[0,0],'Color',[0.9290 0.6940 0.1250],'LineWidth',2);
             h.figure.circle = plot(h.figure.ax,1:20,1:20,'LineWidth',2,'LineStyle','none','Marker','o','MarkerEdgeColor','r');
             xlabel('Trials','FontSize',10,'FontWeight','bold','Color', [0.00,0.45,0.74]);
             set(gca,'FontSize',10,'FontWeight','bold','box','off','XColor', [0.00,0.45,0.74],'YColor', [0.00,0.45,0.74]);
             zoom on;
             % set ColumnName for hisTable
             set(h.hisTable,'ColumnName',{' TestType  ';'       name    ';...
                 '                      record file name                           ';'   result    '});
 end
    
        function set_font_color()% change font and color
            set(findobj('Tag','BoxPanel'),'ForegroundColor', [1,1,1], 'FontName', 'Helvetica',...
                'FontSize', 16,'FontWeight', 'bold','TitleColor',[0.39,0.62,0.90],...
                'FontAngle','italic');
            set(findobj('Tag','Run'),'BackgroundColor', [0.39,0.62,0.90], 'ForegroundColor', [1, 1, 1], ...
                'FontName', 'Helvetica', 'FontUnits', 'normalized', 'FontSize', 0.35, ...
                'FontWeight', 'bold');
            set(findobj('Tag','Calibration'),'ForegroundColor', [0.00,0.45,0.74], ...
                'FontName', 'Helvetica', 'FontUnits', 'normalized', 'FontSize', 0.35, ...
                'FontWeight', 'bold');
            set(findobj('Style','text'),'ForegroundColor', [0.00,0.45,0.74], 'FontName', 'Helvetica',...
                'FontSize', 10,'FontWeight', 'bold','HorizontalAlignment','right');
            set(findobj('Tag','note'),'ForegroundColor', [0.00,0.45,0.74], 'FontName', 'Helvetica',...
                'FontSize', 10,'FontWeight', 'bold','HorizontalAlignment','left');
            set(findobj('Style','popupmenu'),'ForegroundColor', [0.00,0.45,0.74], 'FontName', 'Helvetica',...
                'FontSize', 12,'FontWeight', 'bold');
            set(findobj('Style','radiobutton'),'ForegroundColor', [0.00,0.45,0.74], 'FontName', 'Helvetica',...
                'FontSize', 12,'FontWeight', 'bold','HorizontalAlignment','right');
            set(findobj('Style','edit'),'ForegroundColor', [0.00,0.45,0.74], 'FontName', 'Helvetica',...
                'FontSize', 10,'FontWeight', 'bold');
                        %'FontUnits', 'normalized', 'FontSize', 0.4,'FontWeight', 'bold');
            set(findobj('Tag','head'),'ForegroundColor', [1, 1, 1], ...
                'FontUnits', 'normalized', 'FontSize', 0.7,'FontAngle','italic',...
                'BackgroundColor', [0.39,0.62,0.90],'HorizontalAlignment','left');
        end
    end
end

%% callback functions
function strategyChange(trigObj,~,obj)
if mod(trigObj.Value,2) == 0
    set(obj.h.flim,'Enable','on');    
else
    set(obj.h.flim,'Enable','off');    
end
end

function calibrate(trigObj,~)
if trigObj.Value == 1
    % use the SSN-MSP for calibration
    [x,Fs] = audioread('.\Sounds\Noise\SSN-MSP.wav');
    player = audioplayer(x/2,Fs);
    set(trigObj,'userdata',player);
    play(player);
else
    try
        player = get(trigObj,'userdata');
        stop(player);
    catch
    end
end
end

function outputChange(trigObj,~,obj)
output = lower(trigObj.String(trigObj.Value));
if contains(output,'voc') % vocoder or vocHaptic
%if trigObj.Value == 3 || trigObj.Value == 4 % vocoder or vocHaptic
try
    set(obj.h.gain_l,'Enable','off');  
    set(obj.h.gain_r,'Enable','off'); 
    set(obj.h.vol_l,'Enable','off'); 
    set(obj.h.vol_r,'Enable','off'); 
    set(obj.h.vocoder,'Enable','on');
    set(obj.h.carrier,'Enable','on');    
catch
end
%elseif trigObj.Value == 2 % ccimobile
elseif strcmp(output, 'ccimobile') % ccimobile
    set(obj.h.gain_l,'Enable','on');  
    set(obj.h.gain_r,'Enable','on'); 
    set(obj.h.vol_l,'Enable','on'); 
    set(obj.h.vol_r,'Enable','on');
    set(obj.h.vocoder,'Enable','off');
    set(obj.h.carrier,'Enable','off');  
else
    try
        set(obj.h.gain_l,'Enable','off');
        set(obj.h.gain_r,'Enable','off');
        set(obj.h.vol_l,'Enable','off');
        set(obj.h.vol_r,'Enable','off');
        set(obj.h.vocoder,'Enable','off');
        set(obj.h.carrier,'Enable','off');
    catch
    end
end
end



function corpusChange(trigObj,~,obj)
corpus = trigObj.String{trigObj.Value};
if contains(corpus,'MSP')
    set(obj.h.list,'String',sprintfc('%g',1:10));
elseif contains(corpus,'MHINT')
    set(obj.h.list,'String',{'1','2','3','4','5','6','7','8','9','10','11','12','P1','P2'});
else
     set(obj.h.list,'String',sprintfc('%g',1:40));
end
% switch trigObj.String{trigObj.Value}
%     case 'MSP'
%         set(obj.h.list,'String',sprintfc('%g',1:10));
%     case 'MHINT'
%         set(obj.h.list,'String',{'1','2','3','4','5','6','7','8','9','10','11','12','P1','P2'});
%     case 'OLDEN'
%         set(obj.h.list,'String',sprintfc('%g',1:40));
% end 

end

function noiseChange(trigObj,~,obj)
if trigObj.Value == 2 && obj.h.corpus.Value == 3 % OLDEN and babble selected
    trigObj.Value = 1;
    msgbox('OLDEN does not support babble noise');
    return;
end
end

function setChange(trigObj,~,obj)
if trigObj.Value == 2
    if ~ contains(obj.h.corpus.String{obj.h.corpus.Value},'OLDEN')% %obj.h.corpus.Value < 3
        msgbox('Only the OLDEN corpus supports closed-set testing');
        trigObj.Value = 1;
        return;
    end
end
end

function h = fill_grid(h,hgrid, labels, strings, styles,enables)
if nargin <6
    enables = repmat({'on'},1,numel(labels));
end
    for n = 1:numel(labels)
        uicontrol('Parent',hgrid,'style','text','String', labels{n});
    end
    for n = 1:numel(strings)
        h.(lower(labels{n})) = uicontrol('Parent',hgrid,'style',styles{n},...
            'String', strings{n},'Enable',enables{n},'Tag',labels{n});
    end
end

function module_select(trigObj,~,obj)
obj.para.module = trigObj.String;
for n = 1:length(trigObj.Parent.Children) %取消选中其他模块
    if ~(trigObj.Parent.Children(n) == trigObj)
        trigObj.Parent.Children(n).Value = 0;
    end
end
% obj.h.testTypeBox.clo;
obj.h.paraGrid_1.clo;
obj.h.paraGrid_2.clo;
module = obj.config.module.(trigObj.String);
obj.fill_testType_options(module);
end

function testType_select(trigObj,~,obj)
obj.para.testType = trigObj.String{trigObj.Value};
note = obj.config.module.(obj.para.module)(trigObj.Value).note;
set(obj.h.testTypeNote,'String',note);
obj.h.paraGrid_1.clo;
obj.h.paraGrid_2.clo;
%obj.typeIdx = get(trigObj,'UserData');
obj.typeIdx = trigObj.Value;
labels = obj.config.module.(obj.para.module)(obj.typeIdx).labels;
strings = obj.config.module.(obj.para.module)(obj.typeIdx).strings;
styles = obj.config.module.(obj.para.module)(obj.typeIdx).styles;
if numel(labels) > 5 % 如果参数多于5个，则一边显示一半
    N = ceil(numel(labels)/2);
    labels_1 = labels(1:N);    labels_2 = labels(N+1:end);
    strings_1 = strings(1:N);   strings_2 = strings(N+1:end);
    styles_1 = styles(1:N);   styles_2 = styles(N+1:end);
    obj.h = fill_grid(obj.h,obj.h.paraGrid_1, labels_1, strings_1,styles_1);
    set(obj.h.paraGrid_1,'Width',[-2 -2],'Heights',-1* ones(1,numel(labels_1)));
    obj.h = fill_grid(obj.h,obj.h.paraGrid_2, labels_2, strings_2,styles_2);
    set(obj.h.paraGrid_2,'Width',[-2 -2],'Heights',-1* ones(1,numel(labels_2)));
else
    obj.h = fill_grid(obj.h,obj.h.paraGrid_1, labels, strings,styles);
    set(obj.h.paraGrid_1,'Width',[-1 -2],'Heights',-1* ones(1,numel(labels)));
end

MainView.set_font_color();
for n = 1:length(trigObj.Parent.Children)
    if ~(trigObj.Parent.Children(n) == trigObj)
        trigObj.Parent.Children(n).Value = 0;
    end
end
try
    set(obj.h.corpus,'Callback',{@corpusChange,obj});
catch
end
try
    set(obj.h.noise,'Callback',{@noiseChange,obj});
catch
end
try
    set(obj.h.set,'Callback',{@setChange,obj});
catch
end
             
             
end

function selHistory(trigObj,event,obj)
try
    testType = trigObj.Data{event.Indices(1),1};
    name =  trigObj.Data{event.Indices(1),2};
    fname = trigObj.Data{event.Indices(1),3};
    data = loadjson(fullfile(pwd,'Records',testType, name, [fname,'.json']));
    axes(obj.h.figure.ax);
    switch testType % 获取曲线信息，并刷新结果横线
        case {'SRT';'bSRT';'SRT_in_car';'SRM202105'}
            y = data.progressData.snrArr;
            ylabel('SNR(dB)');
            set(obj.h.figure.result,'YData',[data.progressData.srt, data.progressData.srt]);
        case 'QuietSRT'
            y = data.progressData.splArr;
            ylabel('SPL(dB)');
        case {'Ranking';'Discrimination';'Discrimi3I2AFC'}
            y = data.progressData.deltaF0Arr;
            ylabel('F0DL(Hz)');
        case 'Quiet'
            y = data.progressData.rateArr;
            ylabel('正确率');
            set(obj.h.figure.result,'YData',[data.progressData.correctRate/100, data.progressData.correctRate/100]);
        otherwise
            return;
    end    
    
    %刷新曲线和翻转点
    x = 1:length(y);
    set(obj.h.figure.curve,'XData',x,'YData',y);
    if isfield(data.progressData,'isRevArr')
        rev  = data.progressData.isRevArr;
        set(obj.h.figure.circle,'XData',x(rev == 1),'YData',y(rev == 1));
        ylim([min(y)-1 max(y)+1]);
    else
        set(obj.h.figure.circle,'XData',x,'YData',y);
        ylim([0 1]);
    end
    xlim([0 x(end)+1]);
catch
end

end

