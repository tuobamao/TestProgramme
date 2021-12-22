function fig_h = PlotElectrodogram(outstream,map,mode,fig_h)

    if ~exist('mode','var')
        mode = 2;
    end
    
    if ~exist('fig_h','var')
        fig_h = figure();
    end
    
    % convert outstream to struct format for plotting
    stim = get_buffered_values(outstream,map.Side);

    % add necessary fields for using modified plotting function from
    % Cochlear
    stim.phase_widths = map.PhaseWidth;
    stim.phase_gaps = map.IPG;
    stim.periods = 1e6/(map.AnalysisRate*map.NMaxima);
    
    switch mode
        case 0 % unilateral
            Plot_LR_sequences(stim,lower(map.Side),0,1:22,[],fig_h);
        case 1 % left/right separate
            switch lower(map.Side)
                case 'left'
                    Plot_LR_sequences(stim,'Left',0,1:22,[],fig_h);
                case 'right'
                    Plot_LR_sequences(stim,'Right',1,1:22,[],fig_h);
            end
            ah = get(fig_h,'Children');
            xl1 = get(ah(1),'xlim');
            xl2 = get(ah(1),'xlim');
%             linkaxes(ah)
%             xlim([0 max([xl1,xl2])])
        case 2
            switch lower(map.Side)
                case 'left'
                    Plot_LR_sequences(stim,'Sequence',0,1:22,[],fig_h);
                case 'right'
                    Plot_LR_sequences(stim,'Sequence',1,1:22,[],fig_h);
            end
    end
end

function stim = get_buffered_values(outstream,side)
    % define byte indicies
    LEFT_ELECTRODE_START = 7;
    LEFT_ELECTRODE_END = 122;
    LEFT_AMPLITUDE_START = 133;
    LEFT_AMPLITUDE_END = 248;
    
    RIGHT_ELECTRODE_START = 265;
    RIGHT_ELECTRODE_END = 380;
    RIGHT_AMPLITUDE_START = 391;
    RIGHT_AMPLITUDE_END = 506;
    
    % get correct indicies based on side
    switch lower(side)
        case 'left'
            e_index = LEFT_ELECTRODE_START:LEFT_ELECTRODE_END;
            a_index = LEFT_AMPLITUDE_START:LEFT_AMPLITUDE_END;
        case 'right'
            e_index = RIGHT_ELECTRODE_START:RIGHT_ELECTRODE_END;
            a_index = RIGHT_AMPLITUDE_START:RIGHT_AMPLITUDE_END;
    end
    
    % format struct necessary for plotting
    stim.electrodes = [];
    stim.current_levels = [];
    for ii = 1:size(outstream,1)
        el = outstream(ii,e_index);
        cl = outstream(ii,a_index);
        cl(el == 0) = []; el(el == 0) = [];
        stim.electrodes = [stim.electrodes; el'];
        stim.current_levels = [stim.current_levels; cl'];
    end

end
    