function Plot_LR_sequences(varargin)

% Plot_sequence: Plot a cell array of sequences.
% Plots a sequence as one vertical line segment per pulse, 
% with height proportional to magnitude.
% If a cell array of sequences is given, they are displayed one at a time.
%
% User interface:
%
% Zoom is controlled by mouse click and drag.
%
% Key presses:
% numeric keys '1'-'9': display the n'th sequence.
% '0':                  display last sequence
% '['                   display previous sequence
% ']'                   display next sequence
%
% u = Plot_sequence(seq, title_str, channels)
%
% seq:       A sequence or cell array of sequences
% title_str: A string or cell array of strings, used as the window title(s).
% channels:  A vector containing the lowest & highest channel numbers to be displayed.
%              Defaults to the min and max channel numbers present in the sequence(s).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright: Cochlear Ltd
%   $Header: //dsp/Nucleus/_Releases/NMT_4.30/Matlab/Sequence/Plot_sequence.m#1 $
% $DateTime: 2008/03/04 14:27:13 $
%   Authors: Brett Swanson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ischar(varargin{1})
        feval(varargin{:});		% Callbacks
    else
        Init(varargin{:});
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = Init(seq, title_str, channel, channels, show_time_slots, fig_h)

    if ~exist('show_time_slots', 'var') || isempty(show_time_slots)
        show_time_slots = 0;
    end

    if ~exist('fig_h','var') || isempty(fig_h)
        fig_h = gcf;
    end
    
	if iscell(seq)		
		u.seqs = seq;
	else
		u.seqs = {seq};
	end
	u.num_seqs = length(u.seqs);

	if nargin < 2
		title_str = 'Sequence';
	end
	u.title_str = Init_title_strings(title_str, u.num_seqs);
	
	is_channels = 1;
	for n = 1:u.num_seqs	
		if ~isfield(u.seqs{n}, 'channels')
			u.seqs{n}.channels = 23 - u.seqs{n}.electrodes;
			is_channels = 0;
		end
		if ~isfield(u.seqs{n}, 'magnitudes')
			u.seqs{n}.magnitudes = u.seqs{n}.current_levels;
		else
			idles = (u.seqs{n}.magnitudes < 0);
			if any(idles)
				if length(u.seqs{n}.channels) == 1	% replicate constant channel
					u.seqs{n}.channels = repmat(u.seqs{n}.channels, length(u.seqs{n}.magnitudes), 1);
				end
				u.seqs{n}.channels(idles)   = 0;
				u.seqs{n}.magnitudes(idles) = 0;
			end
		end
		min_channels(n) = min(u.seqs{n}.channels);
		max_channels(n) = max(u.seqs{n}.channels);
% 		max_mags(n)     = max(u.seqs{n}.magnitudes); 
        max_mags(n)     = 255; % -AK
		max_times(n)	= Get_sequence_duration(u.seqs{n});
		periods1(n)		= u.seqs{n}.periods(1);
	end
	
	if exist('channels', 'var')
		u.min_channel = min(channels);
		u.max_channel = max(channels);	
	else
		u.min_channel = min(min_channels);
		u.max_channel = max(max_channels);
	end
	u.max_mag   = max(max_mags);
	u.max_time  = max(max_times);
	max_period1 = max(periods1);

	if show_time_slots
		time_scale = max_period1;
		time_label = 'Time slots';
	elseif (u.max_time > 5000)
		time_scale = 1000;
		time_label = 'Time (ms)';
	else
		time_scale = 1;
		time_label = 'Time (us)';
    end
    
    if strcmpi(title_str,'Sequence') % plot left / right in a single plot
        mode = 1;
        u.h_figure = figure(fig_h);
        if channel == 0
            clf
        else
            x_max = max(get(gca,'xtick'));
            x_label = get(get(gca,'xlabel'),'string');
            if strcmp(x_label,'Time (ms)')
                x_max = x_max * 1000;
            end
            u.max_time = max(u.max_time, x_max);
        end
        hold on
    else % plot left & right as 2 separate plots
        mode = 2;
        if channel == 0
            u.h_figure = figure(fig_h);
            %         set(3,'units','normalized','position',[0.1 0.1 0.8 0.8]);
            clf;
            %         u.h_figure = figure('Visible', 'on');
            subplot(1,2,1);
            title(title_str);
        elseif channel == 1
            u.h_figure = figure(fig_h);
            subplot(1,2,2);
            title(title_str);
        end
        %     set(u.h_figure, 'KeyPressFcn', Callback_string('KeyPress'));
        % 	u.h_axes = axes;
    end
	
	yticks = u.min_channel:u.max_channel;
	set(gca, 'YTick', yticks);
	set(gca, 'TickDir', 'out');
	ylabel('Channel');
	if ~is_channels
		set(gca,'YTickLabel', 23 - yticks);
		ylabel('Electrode');
	end
	u.y_scale = 0.75;
	for n = 1:u.num_seqs
		u.h_lines(n) = Plot_sequence_as_lines(u.seqs{n}, u.max_mag/u.y_scale, time_scale,channel,mode);
		set(u.h_lines(n), 'Visible', 'off');
	end
	
	set(gca, 'YLim', [u.min_channel - 1 + u.y_scale, u.max_channel + 1])
	set(gca, 'XLim', [-max_period1, u.max_time]/time_scale);
	if show_time_slots
		set(gca, 'XTick', 0:(u.max_time/time_scale))
	end
	zoom on;
	
	u.cell_index = 1;
	Set_cell_index(u, 1);
	
	xlabel(time_label);
% 	set(u.h_figure, 'Visible', 'on');
	set(gca, 'Box', 'on');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A convenience function to save awkward quoting when setting up the callbacks:

function s = Callback_string(action_string)
	s = [mfilename, '(''', action_string, ''');'];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot sequence as one vertical line segment per pulse, 
% with height proportional to magnitude.
% The scaling factor max_mag is passed in so that multiple sequences
% can all be drawn with the same scale.
% The entire sequence is plotted as one "line" handle.
% This is much faster than a separate handle for each pulse.
% NaNs are used to separate the line segments for each pulse.

function hdl = Plot_sequence_as_lines(seq, max_mag, time_scale,channel,mode)

	t = Get_pulse_times(seq);				% column_vector
	t = t' / time_scale;					% row vector
	z = repmat(NaN, size(t));
	
	x = [t; t; z];
	x = x(:);								% column vector

	c = seq.channels';						% Bottom of line aligns with channel Y axis tick.
	if length(c) == 1
		c = repmat(c, size(t));
	end
	m = seq.magnitudes';
	h = c + m / max_mag;					% Line height is proportional to magnitude.
	y = [c; h; z];
	y = y(:);								% column vector

    switch mode
        case 1
            switch channel
                case 0
                    hdl = line(x, y, 'Color', 'blue','linestyle','-','linewidth',1.5);
                case 1
                    hdl = line(x, y, 'Color', 'red','linestyle',':','linewidth',1.5);
            end
        case 2 % shade color with strength
%             cmap = flipud(jet(256));
%             colormap(cmap)
%             index = round(m);
%             myc = cmap(index+1,:);
%             cnt = 1;
%             for ii = 1:3:size(y,1)
%                 hdl = line(x(ii:(ii+1)), y(ii:(ii+1)), 'Color', myc(cnt,:));
%                 cnt = cnt + 1;
%             end
%             colorbar('location','southoutside')
            hdl = line(x, y, 'Color', 'black');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function KeyPress(c)

	u = Get_figure_data;
	if nargin == 0
		c = get(u.h_figure, 'CurrentCharacter');
	end
	
	if (c >= '0') && (c <= '9')
		Set_cell_index(u, c - '0');
	else 
		switch (c)
			case '['
				Set_cell_index(u, u.cell_index - 1);

			case ']'
				Set_cell_index(u, u.cell_index + 1);
		end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Set_cell_index(u, cell_index)

	set(u.h_lines(u.cell_index), 'Visible', 'off');

	if (cell_index < 1)
		u.cell_index = u.num_seqs;
	elseif (cell_index > u.num_seqs)
		u.cell_index = 1;
	else
		u.cell_index = cell_index;
	end
	
	set(u.h_lines(u.cell_index), 'Visible', 'on');
% 	Window_title(u.title_str{u.cell_index});

	Set_figure_data(u);
end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot sequence as one vertical line segment per pulse, 
% with height proportional to magnitude.
% The scaling factor max_mag is passed in so that multiple sequences
% can all be drawn with the same scale.
% The entire sequence is plotted as one "line" handle.
% This is much faster than a separate handle for each pulse.
% NaNs are used to separate the line segments for each pulse.
function title_str = Init_title_strings(title_str, num_titles)

% Init_title_strings: Initialise a cell array of title strings.
% Used in Plot_sequence, Plot_waveforms.
%
% title_str = Init_title_strings(title_str, num_titles)
%
% title_str:   A string or cell array of strings, used as window title(s).
% num_titles:  The expected number of strings.

    if ischar(title_str)
        title_str = {title_str};
    end

    if num_titles > 1
        if length(title_str) == 1
            title_str = repmat(title_str, 1, num_titles);
        elseif length(title_str) < num_titles
            error('Insufficient number of title strings');
        end

        for n = 1:num_titles
            title_str{n} = [title_str{n}, ' (', num2str(n), ')'];
        end
    end
end

function t = Get_sequence_duration(seq)

% Get_sequence_duration: Get the duration of a sequence.
% The sequence must have a field "periods".
%
% t = Get_sequence_duration(seq)
%
% seq: Sequence struct.
% t:   Duration (in microseconds).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Copyright: Cochlear Ltd
%      $Change: 86418 $
%    $Revision: #1 $
%    $DateTime: 2008/03/04 14:27:13 $
%      Authors: Brett Swanson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    num_pulses = Get_num_pulses(seq);

    if length(seq.periods) == 1
        t = seq.periods * num_pulses;
    else
        t = sum(seq.periods);
    end
end

function [num_pulses, field_lengths] = Get_num_pulses(seq)
    % Get_num_pulses: Returns the number of pulses in a sequence.
    % function [num_pulses, field_lengths] = Get_num_pulses(seq)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %    Copyright: Cochlear Ltd
    %      $Change: 86418 $
    %    $Revision: #1 $
    %    $DateTime: 2008/03/04 14:27:13 $
    %      Authors: Brett Swanson
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    field_names   = fieldnames(seq);
    num_fields    = length(field_names);
    field_lengths = zeros(num_fields, 1);

    for n = 1:num_fields
        name = field_names{n};
        vec  = getfield(seq, name);
        field_lengths(n) = length(vec);
    end

    % Check that all fields have length equal to 1 or N:

    num_pulses = max(field_lengths);	% N
    if num_pulses > 1
        implied_field_lengths = field_lengths;
        % Vectors with length 1 imply that all N pulses have that value:
        implied_field_lengths(field_lengths == 1) = num_pulses;
        short_field_indices = find(implied_field_lengths < num_pulses);
        if (~isempty(short_field_indices))
            disp('Some fields were too short:');
            disp(char(field_names{short_field_indices}));
            error(' ');
        end
    end
end

function [t, duration] = Get_pulse_times(seq)

% Get_pulse_times: Get the time of each pulse of a sequence.
% The sequence must have a field "periods".
% The period is the time from the start of the pulse,
% to the start of the next pulse.
% i.e. the pulse starts at the start of the period.
% The first pulse is defined to occur at time 0.
% The last time (the sequence duration) can be returned as a second output;
% note that there is no pulse there.
% This can be convenient, because:
% seq.periods == diff([t; duration])
%
% [t, duration] = Get_pulse_times(seq)
%
% seq:      Sequence struct
% seq.periods: time from start of pulse to start of next pulse.
%
% t:        Time of the start of each pulse.
% duration: Duration of the sequence (includes last period).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Copyright: Cochlear Ltd
%      $Change: 86418 $
%    $Revision: #1 $
%    $DateTime: 2008/03/04 14:27:13 $
%      Authors: Brett Swanson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

num_pulses = Get_num_pulses(seq);

if length(seq.periods) == 1
	t = seq.periods * (0:num_pulses)';
else
	t = [0; cumsum(seq.periods)];
end

duration = t(end);
t(end) = [];
end

function Set_figure_data(u)

% Set_figure_data: Set data of current callback figure or else current figure.
% An error occurs if there is no figure.
% A GUI that uses this function can have its callbacks
% called from the command line or another function, allowing 
% automated testing.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Copyright: Cochlear Ltd
%      $Change: 86418 $
%    $Revision: #1 $
%    $DateTime: 2008/03/04 14:27:13 $
%      Authors: Brett Swanson
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fig_handle = get(0,'CurrentFigure');
set(fig_handle, 'UserData', u);
end