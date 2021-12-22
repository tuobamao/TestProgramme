classdef iRTProcessor < handle
    properties
        strategylist
        ccimobile
    end
    
    methods
        function obj = iRTProcessor(mpath)
            if ~exist('mpath','var')
                mpath = '.';
            end
            
            obj.strategylist = readtable('StrategyList.txt','filetype','text');
            obj.ccimobile = CCiMobile();
            make_interface(obj,mpath)
        end
    end
end

function make_interface(obj,mpath)
    figw = 6.5;  figh = 6;
    ctrl_panel_h = .7;
    set(0,'units','inches');
    scrndim = get(0,'screensize');
 
    close(findobj('Tag','rtproccessor'))
    fh = figure('name','RTProcessor','Tag','rtproccessor', ...
        'numbertitle','off','menubar','none','resize','off', ...
        'units','inches','position',[(scrndim(3)-figw)/2 scrndim(4)-figh-1 figw figh]);
    
    % controls panel
    cp = uipanel('parent',fh,'bordertype','none', ...
        'units','inches','position',[0 figh-ctrl_panel_h figw ctrl_panel_h]);
  
    % options
    h.preemphasis = uicontrol('parent',cp,'style','checkbox', ...
        'fontsize',14,'fontweight','normal','string','Pre-emphasis', ...
        'value',obj.ccimobile.get_property('preemphasis'),'enable','off','units','normalized', ...
        'position',[.03 .05 .3 .9],'visible','off');
    h.agc = uicontrol('parent',cp,'style','checkbox', ...
        'fontsize',14,'fontweight','normal','string','AGC', ...
        'value',obj.ccimobile.get_property('agc'),'enable','off','units','normalized', ...
        'position',[.34 .05 .2 .9],'visible','off');
    
    % play controls
    h.play = uicontrol('parent',cp,'style','pushbutton','backgroundcolor',[.2 1 .2], ...
        'fontsize',14,'fontweight','bold','string','RUN', ...
        'units','normalized','position',[.67 .05 .3 .85]);
    
    % strategies
    h.strategies = uitabgroup('parent',fh,'units','inches','position',[0 0 figw figh-ctrl_panel_h], ...
        'SelectionChangedFcn',{@ChangeStrategy,obj});
    for ii = 1:size(obj.strategylist,1)
        st = uitab('parent',h.strategies,'title',obj.strategylist.DisplayName{ii},'units','inches');
        sObj = feval(str2func(obj.strategylist.Function{ii}));
        AddStrategy(st,obj,sObj,mpath);
    end
    
    % menu
    bimodal = 'off';
    h.modemenu.main = uimenu(fh,'label','Mode'); 
    h.modemenu.bilateral = uimenu(h.modemenu.main,'label','Bilateral','checked','on');
    h.modemenu.unilateral_l = uimenu(h.modemenu.main,'label','Unilateral (Left)');
    h.modemenu.unilateral_r = uimenu(h.modemenu.main,'label','Unilateral (Right)');
    h.modemenu.bimodal_l = uimenu(h.modemenu.main,'label','Bimodal (CI = Left)','enable',bimodal,'visible','off');
    h.modemenu.bimodal_r = uimenu(h.modemenu.main,'label','Bimodal (CI = Right)','enable',bimodal,'visible','off');
    obj.ccimobile.set_property('mode','bilateral');
    
    % set callbacks
    set([h.preemphasis h.agc],'callback',{@SetOption,obj})
    set(h.play,'callback',{@PlayCtrl,obj,h});
    set(get(h.modemenu.main,'children'),'callback',{@SetMode,obj,h})
    
    % store handles to components
    set(fh,'userdata',h)
end

function AddStrategy(st,obj,sObj,mpath)
    st_size = get(st,'position');
    map_panel_h = .4;
    lrstr = {'LEFT','RIGHT'};
    
    % maps
    t.map_panel = uipanel('parent',st,'bordertype','none','units','inches', ...
        'position',[0 st_size(4)-2*(map_panel_h)-0.35, st_size(3) 2*map_panel_h]);
    for ss = 1:2
        m = uipanel('parent',t.map_panel,'units','normalized','position',[0 1-(ss*.5), 1 .5]);
        uicontrol('parent',m,'style','text','horizontalalignment','right', ...
            'fontweight','bold','fontsize',14,'string',sprintf('%s MAP: ',lrstr{ss}), ...
            'units','normalized','position',[0 0 .2 1]);
        t.map_name(ss) = uicontrol('parent',m,'style','text','backgroundcolor','w', ...
            'horizontalalignment','center','fontweight','normal','fontsize',8, ...
            'string','no map loaded','units','normalized','position',[.2 0 .7 1]);
        t.map_load(ss) = uicontrol('parent',m,'style','pushbutton','string','Load', ...
            'backgroundcolor',[.8 .8 .8],'fontsize',16, ...
            'callback',{@LoadMap,obj,mpath,lower(lrstr{ss}),t.map_name(ss),st}, ...
            'units','normalized','position',[.9 0 .095 1]);
    end
    
    % parameters
    t.parameters = uicontrol('parent',st,'style','pushbutton', ...
        'string','Set Parameters','fontsize',14, ...
        'callback',{@SetParams,st}, ...
        'units','normalized','position',[.55 .71 .4 .1]);
    
    % gain controls
    t.gain_panel = uipanel('parent',st,'title','Sensitivity','fontsize',14, ...
        'units','normalized','position',[.05 .05 .4 .65]);
    propname = {'left_sensitivity_gain','right_sensitivity_gain'};
    MAXGAIN = 30;
    MINGAIN = -MAXGAIN;
    for ss = 1:2
        uicontrol('parent',t.gain_panel,'style','text','horizontalalignment','right', ...
            'fontweight','bold','fontsize',14,'string',lrstr{ss}, ...
            'units','normalized','position',[.05+(ss-1)*.5 .9 .3 .09]);
        t.gain_val(ss) = uicontrol('parent',t.gain_panel,'style','text','backgroundcolor','w', ...
            'fontsize',14,'string',num2str(obj.ccimobile.get_property(propname{ss})), ...
            'units','normalized','position',[.15+(ss-1)*.5 .05 .19 .1]);
        t.gain_slider(ss) = uicontrol('parent',t.gain_panel,'style','slider','backgroundcolor','w', ...
            'min',MINGAIN,'max',MAXGAIN,'sliderstep',[1 3]/(MAXGAIN - MINGAIN), ...
            'value',obj.ccimobile.get_property(propname{ss}), ...
            'callback',{@SetGain,obj,lrstr{ss},t.gain_val(ss)}, ...
            'units','normalized','position',[.15+(ss-1)*.5 .15 .19 .75]);
    end
    
    % volume controls
    t.vol_panel = uipanel('parent',st,'title','Volume','fontsize',14, ...
        'units','normalized','position',[.55 .05 .4 .65]);
    propname = {'left_volume','right_volume'};
    MINVOL = 0;
    MAXVOL = 10;
    for ss = 1:2
        uicontrol('parent',t.vol_panel,'style','text','horizontalalignment','right', ...
            'fontweight','bold','fontsize',14,'string',lrstr{ss}, ...
            'units','normalized','position',[.05+(ss-1)*.5 .9 .3 .09]);
        t.vol_val(ss) = uicontrol('parent',t.vol_panel,'style','text','backgroundcolor','w', ...
            'fontsize',14,'string',num2str(obj.ccimobile.get_property(propname{ss})), ...
            'units','normalized','position',[.15+(ss-1)*.5 .05 .19 .1]);
        t.vol_slider(ss) = uicontrol('parent',t.vol_panel,'style','slider','backgroundcolor','w', ...
            'min',MINVOL,'max',MAXVOL,'sliderstep',[.5 1]/(MAXVOL - MINVOL), ...
            'value',obj.ccimobile.get_property(propname{ss}), ...
            'callback',{@SetVolume,obj,lrstr{ss},t.vol_val(ss)}, ...
            'units','normalized','position',[.15+(ss-1)*.5 .15 .19 .75]);
    end    
    
    % store userdata
    t.strategy = sObj;
    t.lmap = [];
    t.rmap = [];
    set(st,'userdata',t)
end

%% callbacks
function ChangeStrategy(trigObj,event,obj)
    if obj.ccimobile.get_property('state') == 0 % only allow change of strategy if CCiMobile is not running
        t = trigObj.SelectedTab.UserData;
        obj.ccimobile.set_property('left_sensitivity_gain',str2double(t.gain_val(1).String))
        obj.ccimobile.set_property('right_sensitivity_gain',str2double(t.gain_val(2).String))
        obj.ccimobile.set_property('left_volume',str2double(t.vol_val(1).String))
        obj.ccimobile.set_property('right_volume',str2double(t.vol_val(2).String))
    else
        uiwait(errordlg('Cannot change strategy while CCiMobile is running','Error'))
        trigObj.SelectedTab = event.OldValue;
    end
end

function SetMode(trigObj,~,obj,h)
    set(get(h.modemenu.main,'children'),'checked','off')
    switch trigObj.Label
        case 'Bilateral'
            set(h.modemenu.bilateral,'Checked','on');
            obj.ccimobile.set_property('mode','bilateral');
        case 'Unilateral (Left)'
            set(h.modemenu.unilateral_l,'Checked','on');
            obj.ccimobile.set_property('mode','unilateral_left');
        case 'Unilateral (Right)'
            set(h.modemenu.unilateral_r,'Checked','on');
            obj.ccimobile.set_property('mode','unilateral_right');
        case 'Bimodal (CI = Left)'
            set(h.modemenu.bimodal_l,'Checked','on');
            obj.ccimobile.set_property('mode','bimodal_left');            
        case 'Bimodal (CI = Right)'
            set(h.modemenu.bimodal_r,'Checked','on');
            obj.ccimobile.set_property('mode','bimodal_right');
    end
end

function SetOption(trigObj,~,obj)
    switch trigObj.String
        case 'Pre-emphasis'
            obj.ccimobile.set_property('preemphasis',trigObj.Value);
        case 'AGC'
            obj.ccimobile.set_property('agc',trigObj.Value);
    end
    drawnow;
end

function PlayCtrl(trigObj,~,obj,h)
    trigObj.Enable = 'off';
    hndl = h.strategies.SelectedTab.UserData;
    switch obj.ccimobile.get_property('state')
        case 0 % stop -> running
            % initialize strategy
            switch obj.ccimobile.get_property('mode')
                case 'bilateral'
                    if isempty(hndl.lmap) || isempty(hndl.rmap)
                        uiwait(errordlg('Missing MAPs','Error'))
                        trigObj.Enable = 'on';
                        return
                    else
                        hndl.strategy.initialize(hndl.lmap,hndl.rmap,obj.ccimobile.FRAMESIZE,obj.ccimobile.FS);
                    end
                case 'unilateral_left'
                    if isempty(hndl.lmap) 
                        uiwait(errordlg('Missing left MAP','Error'))
                        trigObj.Enable = 'on';
                        return
                    else
                        hndl.strategy.initialize(hndl.lmap,[],obj.ccimobile.FRAMESIZE,obj.ccimobile.FS);
                    end
                case 'unilateral_right'
                    if isempty(hndl.lmap) 
                        uiwait(errordlg('Missing right MAP','Error'))
                        trigObj.Enable = 'on';
                        return
                    else
                        hndl.strategy.initialize([],hndl.rmap,obj.ccimobile.FRAMESIZE,obj.ccimobile.FS);
                    end
            end
            fprintf(1,'Running %s\n',class(hndl.strategy))
            
            % disable gui components
            set(hndl.map_load,'enable','off')
            set(hndl.parameters,'enable','off')
            set(h.modemenu.main,'enable','off')
            set([h.preemphasis,h.agc],'enable','off');
            
            % enable stop button
            trigObj.String = 'Stop';
            trigObj.BackgroundColor = [1 .2 .2];
            trigObj.Enable = 'on';
            drawnow;
            
            % start processing
            obj.ccimobile.process(hndl.strategy,'microphone','rfcoil')
            
        case 1 % running -> stop
            % stop processing
            obj.ccimobile.stop();
            
            % enable gui components
            set(hndl.map_load,'enable','on')
            set(hndl.parameters,'enable','on')
            set(h.modemenu.main,'enable','on')
            set([h.preemphasis,h.agc],'enable','on');

            % enable run button
            trigObj.String = 'Run';
            trigObj.BackgroundColor = [.2 1 .2];
            trigObj.Enable = 'on';
            drawnow;
    end
end

function LoadMap(~,~,obj,mpath,side,h,st)
    hndl = st.UserData;
    [filename,pathname] = uigetfile(fullfile(mpath,'*.txt'));
    if filename ~= 0
        filename = fullfile(pathname,filename);
        try
            mymap = CCiMobileMap(side,filename,obj.ccimobile.FS);
            h.String = filename;
            switch lower(side)
                case 'left'
                    hndl.lmap = mymap;
                case 'right'
                    hndl.rmap = mymap;
            end
        catch
            uiwait(errordlg('Chosen map is for wrong side','Error'))
            h.String = 'no map loaded';
            switch lower(side)
                case 'left'
                    hndl.lmap = [];
                case 'right'
                    hndl.rmap = [];
            end
        end
    else
        h.String = 'no map loaded';
        switch lower(side)
            case 'left'
                hndl.lmap = [];
            case 'right'
                hndl.rmap = [];
        end
    end
    st.UserData = hndl;
    drawnow;
end

function SetParams(~,~,st)
    % get parameters
    strategy = st.UserData.strategy;
    sprop = properties(strategy);
    
    % remove ones that should not be edited
    sprop = setdiff(sprop,{'lmap','rmap','framesize','fs'});
    
    % figure out what type for properties
    svalue = cell(size(sprop)); 
    stype = cell(size(sprop));
    for ii = 1:numel(sprop)
        svalue{ii} = strategy.(sprop{ii});
        if isnumeric(svalue{ii})
            svalue{ii} = num2str(svalue{ii});
            stype{ii} = 'numeric';
        elseif ischar(svalue{ii})
            stype{ii} = 'string';
        elseif isboolean(svalue{ii})
            stype{ii} = 'boolean';
        else
            stype{ii} = 'unknown';
        end
    end
    
    a = inputdlg(sprop,sprintf('%s Properties',class(strategy)),[1 50],svalue);
    if ~isempty(a)
        % convert strings back to original type
        for ii = 1:numel(sprop)
            if strcmp(stype{ii},'numeric')
                a{ii} = str2double(a{ii});
            elseif strcmp(stype,'boolean')
                a{ii} = logical(a{ii});
            end
            strategy.(sprop{ii}) = a{ii};
        end
        
        % save changes
        st.UserData.strategy = strategy;
    end
 end

function SetGain(trigObj,~,obj,side,h)
    val = round(trigObj.Value);
    h.String = num2str(val);
    switch lower(side)
        case 'left'
            obj.ccimobile.set_property('left_sensitivity_gain',val)
        case 'right'
            obj.ccimobile.set_property('right_sensitivity_gain',val)
    end
    drawnow;
end

function SetVolume(trigObj,~,obj,side,h)
    val = round(trigObj.Value,1);
    h.String = num2str(val);
    switch lower(side)
        case 'left'
            obj.ccimobile.set_property('left_volume',val)
        case 'right'
            obj.ccimobile.set_property('right_volume',val)
    end
    drawnow;
end
