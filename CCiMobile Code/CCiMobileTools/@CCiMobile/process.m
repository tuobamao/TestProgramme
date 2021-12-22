% function process(obj,strategy,source,destination,show_interface)
% source: 'microphone','file', {wavdata,wavfs} added by Huali 20201018
% destination: 'file','rfcoil','electrodogram'
% show_interface: flag whether to show start/stop buttons
function process(obj,strategy,source,destination,show_interface)

    % check input arguments
    if ~exist('show_interface','var')
        show_interface = false;
    end
    
    if show_interface
        make_interface(obj);
    end
    
    [sourcetype,in] = checksource(source);
    [destinationtype,out] = checkdestination(destination);
    
    % initialize buffers
    if ~isempty(strategy)
        maps = struct('Left', strategy.lmap, 'Right', strategy.rmap);
        outbuffer = init_out_buffer(maps, obj.DURATIONSYNC, obj.ADDITIONALGAP, obj.FRAMEDURATION);
    else
        assert(strcmp(destinationtype,'file'),'Strategy must be defined')
        outbuffer = init_out_buffer([], obj.DURATIONSYNC, obj.ADDITIONALGAP, obj.FRAMEDURATION);
    end

    % define process path based on destination 
    if (strcmp(destinationtype,'file') || strcmp(destinationtype,'electrodogram')) % destination is file, screen or memory
        
        % source is a file
        if strcmp(sourcetype,'file') || strcmp(sourcetype,'wavdata')
            [outstream,lmap,rmap,mode] = process_file(in,outbuffer,strategy,obj);
            outstream = double(outstream);
            
            % send to destination
            if strcmp(destinationtype,'file')                           % destination is file
                [~,~,ext] = fileparts(out);
                assert(strcmp(ext,'.mat'),'.mat filename required')
                writestream(out,outstream,lmap,rmap,mode)
                
            elseif strcmp(destinationtype,'electrodogram')              % destination is electrodogram
                fh = figure('name',class(strategy));
                if strcmpi(mode,'unilateral_left') || strcmpi(mode,'bimodal_left') || strcmpi(mode,'bilateral')
                    PlotElectrodogram(outstream,lmap,obj.plotmode,fh);
                end
                if strcmpi(mode,'unilateral_right') || strcmpi(mode,'bimodal_right') || strcmpi(mode,'bilateral')
                    PlotElectrodogram(outstream,rmap,obj.plotmode,fh);
                end
            end
            
            % source is microphone
        elseif strcmp(sourcetype,'microphone')
            % initialize CCiMobile
            s = obj.initialize(outbuffer);
            
            if strcmp(destinationtype,'file')                           % destination is a file
                [~,~,ext] = fileparts(out);
                assert(strcmp(ext,'.wav'),'.wav filename required')
                stream_to_file(s,out,obj,outbuffer);
            else                                                        % destination is electrodogram
                stream_to_live_electrodogram(s,obj,strategy,outbuffer)
            end
            
            delete(s);  % clean up
        end
        
         
            
    else % destination is rfcoil
        s = obj.initialize(outbuffer);
        z_l = []; z_r = [];
        
        obj.state = 1;
        if strcmp(sourcetype,'file') % source is a file
            % load from file
            outstream = process_file(in,outbuffer,strategy,obj);
            
            count = 1;
            nFrames = size(outstream,1);
            while count <= nFrames
                if Wait(s) >= 512
                    AD_data_bytes = Read(s, 512);           % dummy read line (but required)
                    outbuffer = outstream(count,:);         % read frame of audio
                    count = count + 1;                      % increment frame index
                    Write(s, outbuffer,516);                % Write to coil
                end
            end 
            
        elseif strcmp(sourcetype,'microphone') % source is microphone 
            
            lpulsedur = 2*strategy.lmap.PhaseWidth + strategy.lmap.IPG + obj.DURATIONSYNC + obj.ADDITIONALGAP;
            rpulsedur = 2*strategy.rmap.PhaseWidth + strategy.rmap.IPG + obj.DURATIONSYNC + obj.ADDITIONALGAP;
            
            while obj.state == 1 
                drawnow;
                if Wait(s)>= 512 % guo: micro, read data from USB with SPI
                    AD_data_bytes = Read(s, 512);                                                           % Read audio from BTE
                    AD_data = double(typecast(int8(AD_data_bytes),'int16'))/32768;                          % convert to range between -1 & 1
                    lin = AD_data(1:2:end)'; rin = AD_data(2:2:end)';                                       % split L/R channel
                    [out_l,out_r] = process_buffer(lin,rin,strategy,obj);                                   % apply strategy
                    [outbuffer,z_l,z_r] = fill_outbuffer(out_l,out_r,outbuffer, ...
                        z_l,z_r,obj.MAXAMPLITUDES,lpulsedur,rpulsedur,obj.FRAMEDURATION);                   % fill output buffer
                    Write(s, outbuffer,516);                                                                % Write to coil
                end
            end % end when stop button is pressed
            
        elseif strcmp(sourcetype,'wavdata') % source is wavdata
            % load from file
            outstream = process_file(in,outbuffer,strategy,obj);
            
            count = 1;
            nFrames = size(outstream,1);
            while count <= nFrames
                if Wait(s) >= 512
                    AD_data_bytes = Read(s, 512);           % dummy read line (but required)
                    outbuffer = outstream(count,:);         % read frame of audio
                    count = count + 1;                      % increment frame index
                    Write(s, outbuffer,516);                % Write to coil
                end
            end 
            
        end
        delete(s);  % clean up
    end
    
end % end process

%% helper functions

function stream_to_file(s,out,obj,outbuffer)
    try
        afw = dsp.AudioFileWriter(out,'SampleRate',obj.FS);
        streamToDisk = true;
    catch
        audio_stream = [];
        streamToDisk = false;
    end

    % run main loop
    obj.state = 1;
    fprintf(1,'Recording ');
    count = 1;
    while obj.state == 1
        drawnow;
        if Wait(s)>= 512
            AD_data_bytes = Read(s, 512);                                   % Read audio from BTE
            AD_data = double(typecast(int8(AD_data_bytes),'int16'))/32768;  % convert to range between -1 & 1
            stereo_signal = reshape(AD_data,2,128)';

            % store data
            if streamToDisk
                afw(stereo_signal);
            else
                audio_stream = [audio_stream; stereo_signal];
            end

            if isvalid(s)
                Write(s, outbuffer,516);                                    % write a dummy frame to CCiMobile
                if mod(count,125) == 0
                    fprintf(1,'.\n');
                else
                    fprintf(1,'.');
                end
                count = count + 1;
            end
        end
    end % end while loop, until stop button is pressed
    fprintf(1,'\n');

    if ~streamToDisk
        if isempty(audio_stream)
            disp('Audio Stream is empty');
        else
            audiowrite(out,audio_stream,obj.FS);
        end
    else
        release(afw);
    end
    fprintf(1,' Recording stopped\n');
end

function stream_to_live_electrodogram(s,obj,strategy,outbuffer)

    figw = 6;  figh = 4;
    set(0,'units','inches'); scrndim = get(0,'screensize');
    figure('name','CCiMobile','Tag','Realtime Electrodogram', ...
        'numbertitle','off','menubar','none','resize','off', ...
        'units','inches','position',[(scrndim(3)-figw)/2 scrndim(4)-figh-1 figw figh]);
    lefta = subplot('position',[.1 .1 .35 .8]);
    righta = subplot('position',[.6 .1 .35 .8]);

    % run main loop
    obj.state = 1;
    while obj.state == 1
        drawnow;
        if Wait(s)>= 512
            AD_data_bytes = Read(s, 512);                                           % Read audio from BTE
            AD_data = double(typecast(int8(AD_data_bytes),'int16'))/32768;          % convert to range between -1 & 1
            lin = AD_data(1:2:end)'; rin = AD_data(2:2:end)';                       % split L/R channel
            [out_l,out_r] = process_buffer(lin,rin,strategy,obj);                   % apply strategy

            % plot only the first frame of pulses
            l_el = out_l.electrodes(1:strategy.lmap.NMaxima);
            l_cl = out_l.current_levels(1:strategy.lmap.NMaxima);
            r_el = out_r.electrodes(1:strategy.rmap.NMaxima);
            r_cl = out_r.current_levels(1:strategy.rmap.NMaxima);

            % plot pulses
            lbars = zeros(1,22); lbars(l_el) = l_cl;
            rbars = zeros(1,22); rbars(r_el) = r_cl;
            bar(lefta,lbars,'FaceColor', [0.4 0 0.4]);
            bar(righta,rbars,'FaceColor', [0.4 0 0.4]);

            % plot THR and MCL values
            hold(lefta,'on'); hold(righta,'on')
            line(lefta,flipud([strategy.lmap.EL-0.5 strategy.lmap.EL+0.5])', ...
                [strategy.lmap.MCL strategy.lmap.MCL]','color','k')
            line(righta,flipud([strategy.rmap.EL-0.5 strategy.rmap.EL+0.5])', ...
                [strategy.rmap.MCL strategy.rmap.MCL]','color','k')
            line(lefta,flipud([strategy.lmap.EL-0.5 strategy.lmap.EL+0.5])', ...
                [strategy.lmap.THR strategy.lmap.THR]','color','b')
            line(righta,flipud([strategy.rmap.EL-0.5 strategy.rmap.EL+0.5])', ...
                [strategy.rmap.THR strategy.rmap.THR]','color','b')
            hold(lefta,'off'); hold(righta,'off')

            % fix axes and add labels
            set(lefta,'xtick',2:2:22,'xdir','reverse','ytick',0:16:256, ...
                'xlim',[0.5 22.5],'ylim',[0 256])
            set(righta,'xtick',2:2:22,'xdir','reverse','ytick',0:16:256, ...
                'xlim',[0.5 22.5],'ylim',[0 256])
            title(lefta,'Left')
            title(righta,'Right')
            xlabel(lefta,'Electrode Number')
            xlabel(righta,'Electrode Number')
            ylabel(lefta,'Current Units')

            Write(s, outbuffer,516);                                                % write a dummy frame to CCiMobile
        end
    end % end while loop, until stop button is pressed
end

function h = make_interface(ccimobile_obj,str)
    if ~exist('str','var')
        str = [];
    end

    figw = 3;  figh = 2;
    set(0,'units','inches');
    scrndim = get(0,'screensize');
 
    close(findobj('Tag','simple_controls'))
    h.fig = figure('name','CCiMobile','Tag','simple_controls', ...
        'numbertitle','off','menubar','none','resize','off', ...
        'units','inches','position',[2 scrndim(4)-figh-1 figw figh]);
    
    % display str
    h.text = uicontrol('parent',h.fig,'style','text','horizontalalignment','center', ...
        'fontweight','bold','fontsize',14,'string',str,'units','normalized','position',[.1 .75 .8 .1]);
    
    % play controls
    h.play = uicontrol('parent',h.fig,'style','pushbutton','backgroundcolor',[1 .2 .2], ...
        'fontsize',14,'fontweight','bold','string','STOP','units','normalized','position',[.1 .1 .8 .6]);
    set(h.play,'callback',{@(~,~,x)(ccimobile_obj.stop)});
    
    drawnow;
end

function [outstream,lmap,rmap,mode] = process_file(filename,outbuffer,strategy,obj)
    if ~iscell(filename) % if input is not a cell, do filename analysis
        [~,~,ext] = fileparts(filename);
    else
        ext = '';
    end
    
     % change switch to if-elseif-end to support cell input by Huali
     % 20201018
%     switch ext(2:end)
%         case 'wav'  % wave file
    if iscell(filename) || strcmp(ext(2:end),'wav')
        % create input by dividing audio into 8 ms frames (to mimic realtime processing)
        [lin,rin] = make_buffered_audio(filename,obj);

        % process
        lpulsedur = 2*strategy.lmap.PhaseWidth + strategy.lmap.IPG + obj.DURATIONSYNC + obj.ADDITIONALGAP;
        % if checked added by Huali 20200411, Alan's oringinal code
        % only has the line in the else part
        if isempty(strategy.rmap)
            rpulsedur =lpulsedur; % added by Huali
        else
            rpulsedur = 2*strategy.rmap.PhaseWidth + strategy.rmap.IPG +obj.DURATIONSYNC + obj.ADDITIONALGAP;
        end
        outstream = uint8(zeros(size(lin,2),size(outbuffer,2)));
        z_l = []; z_r = [];
        for ii = 1:size(lin,2)
            [out_l,out_r] = process_buffer(lin(:,ii),rin(:,ii),strategy,obj);           % apply strategy
            [outbuffer,z_l,z_r] = fill_outbuffer(out_l,out_r,outbuffer, ...
                z_l,z_r,obj.MAXAMPLITUDES,lpulsedur,rpulsedur,obj.FRAMEDURATION);       % fill output buffer
            outstream(ii,:) = outbuffer;                                                % save output
        end

        % re-assign variables (used for plotting)
        lmap = strategy.lmap; rmap = strategy.rmap; mode = obj.mode;

        %         case 'mat' % load from a pre-computed stream
    elseif strcmp(ext(2:end),'mat')
        [outstream,lmap,rmap,mode] = readstream(filename);
    end
end



function [lbuffer,rbuffer] = make_buffered_audio(filename,obj)
        if iscell(filename) % added by Huali to support direct wavdata input
            inbuffer = filename{1};
            if size(inbuffer,2) == 1 % copy single channel signal to two-channel signal
                inbuffer = [inbuffer,inbuffer];
            end
            fs = filename{2};
        else
            [inbuffer,fs] = audioread(filename); % original from Alan
        end

        % resample if incoming audio is different sampling rate
        if fs ~= obj.FS
            inbuffer = ResampleAudio(inbuffer,obj.FS,fs);
        end

        % check number of channels
        switch lower(obj.mode)
            case {'unilateral_left','unilateral_right'}
                assert(size(inbuffer,2) == 1,'input audio must be mono for unilateral processing')
                switch lower(obj.mode)
                    case 'unilateral_left'
                        inbuffer = [inbuffer zeros(size(inbuffer))];
                    case 'unilateral_right'
                        inbuffer = [zeros(size(inbuffer)) inbuffer];
                end
            case {'bilateral','bimodal_left','bimodal_right'}
                assert(size(inbuffer,2) == 2,'input audio must be stereo for bilateral/bimodal processing')
        end

        % divide signal into chunks (to mimic microphone signal)
        lbuffer = buffer(inbuffer(:,1),obj.FRAMESIZE);
        rbuffer = buffer(inbuffer(:,2),obj.FRAMESIZE);
end

function [out_l,out_r] = process_buffer(in_l,in_r,strategy,obj)
    % apply gains
    in_l = in_l * 10^((obj.ADCGAIN + obj.left_sensitivity_gain)/20);
    in_r = in_r * 10^((obj.ADCGAIN + obj.right_sensitivity_gain)/20);

    % apply processing
    switch lower(obj.mode)
        case 'bilateral'
            [out_l,out_r] = strategy.process(in_l,in_r);
            
            % apply volume control and patient level mapping
            out_l.current_levels = map_levels(out_l.levels, out_l.electrodes, ...
                obj.left_volume,strategy.lmap);
            out_r.current_levels = map_levels(out_r.levels, out_r.electrodes, ...
                obj.right_volume,strategy.rmap);
        case {'unilateral_left','bimodal_left'}
            [out_l,~] = strategy.process(in_l,[]);
            
            % apply volume control and patient level mapping
            out_l.current_levels = map_levels(out_l.levels, out_l.electrodes, ...
                obj.left_volume,strategy.lmap);
            
            switch lower(obj.mode)
                case 'unilateral_left'
                    out_r = [];
                case 'bimodal_left'
                    out_r = in_r;
            end
        case {'unilateral_right','bimodal_right'}
            [out_r,~] = strategy.process([],in_r);
            
            % apply volume control and patient level mapping
            out_r.current_levels = map_levels(out_r.levels, out_r.electrodes, ...
                obj.right_volume,strategy.rmap);
            
            switch lower(obj.mode)
                case 'unilateral_right'
                    out_l = [];
                case 'bimodal_right'
                    out_l = in_l;
            end
    end
end

function cl = map_levels(u,electrodes,vol,map)
    mag = min(u, 1.0);
    [~,ind] = ismember(electrodes,map.EL);
    cl = round(map.THR(ind) + map.Range(ind) .* mag .* (vol/10));
    cl(mag < 0) = 0;
end

function [sourcetype,filename] = checksource(source)
%function varargout = checksource(source)
    if iscell(source) % added by Huali 20201018 to process direct wavdata
        sourcetype = 'wavdata';
        filename = source; % in this case, filename is a cell including{wavdata,wavfs}
        
    elseif exist(source,'file') == 2    % filename given
        sourcetype = 'file';
        filename = source;
        
    elseif ischar(source)
        sourcetype = lower(source);
        filename = [];
        switch sourcetype
            case 'microphone'       % use microphone for input
                % nothing to do here. initialization occurs later
                
            case 'file'             % get file for source
                [filename,pathname] = uigetfile('*.wav; *.mat','Select file to open');
                if filename ~= 0
                    filename = fullfile(pathname,filename);
                end
                
            otherwise
                error('Unknown source')
        end
    
    else
        error('Unknown source')
    end
end

function [destinationtype,out] = checkdestination(destination)
    if ischar(destination)
        destinationtype = lower(destination);
        out = [];
        switch destinationtype
            case 'rfcoil'       % use ccimobile for output
                % nothing to do here. initialization occurs later
                
            case 'file'             % get filename for destination
%                 [filename,pathname] = uiputfile('*.wav; *.mat','Save as');
%                 if filename ~= 0
%                     out = fullfile(pathname,filename);
%                 end
                % by Huali 20210106 to fix an output filename
                out = '.\outstream.mat';
            case 'electrodogram'
                % nothing to do here. 
                
            otherwise
                error('Unknown destination')
        end
    else
        error('Unknown destination')
    end
end


