function [outbuffer,z_l,z_r] = fill_outbuffer(out_l,out_r,outbuffer,z_l,z_r,n_amps,lpulsedur,rpulsedur,framedur)

    % define byte indicies
    LEFT_ELECTRODE_START = 7;
    LEFT_ELECTRODE_END = LEFT_ELECTRODE_START + n_amps - 1;
    LEFT_AMPLITUDE_START = 133;
    LEFT_AMPLITUDE_END = LEFT_AMPLITUDE_START + n_amps - 1;
    
    RIGHT_ELECTRODE_START = 265;
    RIGHT_ELECTRODE_END = RIGHT_ELECTRODE_START + n_amps - 1;
    RIGHT_AMPLITUDE_START = 391;
    RIGHT_AMPLITUDE_END = RIGHT_AMPLITUDE_START + n_amps - 1;
    
    % reset values
    outbuffer(LEFT_ELECTRODE_START:LEFT_ELECTRODE_END) = uint8(0); 
    outbuffer(LEFT_AMPLITUDE_START:LEFT_AMPLITUDE_END) = uint8(0); 
    outbuffer(RIGHT_ELECTRODE_START:RIGHT_ELECTRODE_END) = uint8(0); 
    outbuffer(RIGHT_AMPLITUDE_START:RIGHT_AMPLITUDE_END) = uint8(0); 
    
    % prepend left over values
    if ~isempty(out_l) && ~isempty(z_l)
        out_l.electrodes = [z_l.electrodes; out_l.electrodes];
        out_l.current_levels = [z_l.current_levels; out_l.current_levels];
        z_l = [];
    end
    if ~isempty(out_r) && ~isempty(z_r)
        out_r.electrodes = [z_r.electrodes; out_r.electrodes];
        out_r.current_levels = [z_r.current_levels; out_r.current_levels];
        z_r = [];
    end
        
    % fill buffer
    if ~isempty(out_l)
        l_pulses = min(numel(out_l.current_levels),n_amps);
        indvec = 0:(l_pulses-1);
        outbuffer(1,LEFT_ELECTRODE_START+indvec) = uint8(out_l.electrodes(1:l_pulses));
        outbuffer(1,LEFT_AMPLITUDE_START+indvec) = uint8(out_l.current_levels(1:l_pulses));
        if numel(out_l.current_levels) > n_amps
            z_l.electrodes = out_l.electrodes((n_amps+1):end);
            z_l.current_levels = out_l.current_levels((n_amps+1):end);
        end
    else
        l_pulses = 0;
    end
    if ~isempty(out_r)
        r_pulses = min(numel(out_r.current_levels),n_amps);
        indvec = 0:(r_pulses-1);
        outbuffer(1,RIGHT_ELECTRODE_START+indvec) = uint8(out_r.electrodes(1:r_pulses));
        outbuffer(1,RIGHT_AMPLITUDE_START+indvec) = uint8(out_r.current_levels(1:r_pulses));
        if numel(out_r.current_levels) > n_amps
            z_r.electrodes = out_r.electrodes((n_amps+1):end);
            z_r.current_levels = out_r.current_levels((n_amps+1):end);
        end
    else 
        r_pulses = 0;
    end
    
    % define frame bytes
    LEFT_PULSE_PER_FRAME_HIGHBYTE = 507;
    LEFT_PULSE_PER_FRAME_LOWBYTE = 508;
    RIGHT_PULSE_PER_FRAME_HIGHBYTE = 509;
    RIGHT_PULSE_PER_FRAME_LOWBYTE = 510;
    LEFT_RF_CYCLE_HIGHBYTE = 511;
    LEFT_RF_CYCLE_LOWBYTE = 512;
    RIGHT_RF_CYCLE_HIGHBYTE = 513;
    RIGHT_RF_CYCLE_LOWBYTE = 514;
    
    % reset values
    outbuffer(LEFT_PULSE_PER_FRAME_HIGHBYTE:RIGHT_PULSE_PER_FRAME_LOWBYTE) = uint8(0); 
    outbuffer(LEFT_RF_CYCLE_HIGHBYTE:RIGHT_RF_CYCLE_LOWBYTE) = uint8(0); 
    
    if l_pulses > 0 
        l_pulses_per_frame = typecast(uint16(l_pulses),'uint8');
        l_interpulseDuration = framedur*1000/l_pulses - (lpulsedur);
    else
        l_pulses_per_frame = typecast(uint16(r_pulses),'uint8');
        l_interpulseDuration = framedur*1000/r_pulses - (rpulsedur);
    end
    
    if r_pulses > 0 
        r_pulses_per_frame = typecast(uint16(r_pulses),'uint8');
        r_interpulseDuration = framedur*1000/r_pulses - (rpulsedur);
    else
        r_pulses_per_frame = typecast(uint16(l_pulses),'uint8');
        r_interpulseDuration = framedur*1000/l_pulses - (lpulsedur);
    end
        
    l_nRFcycles = typecast(uint16((l_interpulseDuration/0.1)),'uint8'); 
    r_nRFcycles = typecast(uint16((r_interpulseDuration/0.1)),'uint8'); 
    
    outbuffer(LEFT_PULSE_PER_FRAME_HIGHBYTE) = l_pulses_per_frame(2);
    outbuffer(LEFT_PULSE_PER_FRAME_LOWBYTE) = l_pulses_per_frame(1);
    outbuffer(RIGHT_PULSE_PER_FRAME_HIGHBYTE) = r_pulses_per_frame(2);
    outbuffer(RIGHT_PULSE_PER_FRAME_LOWBYTE) = r_pulses_per_frame(1);
    outbuffer(LEFT_RF_CYCLE_HIGHBYTE) = l_nRFcycles(2);
    outbuffer(LEFT_RF_CYCLE_LOWBYTE) = l_nRFcycles(1);
    outbuffer(RIGHT_RF_CYCLE_HIGHBYTE) = r_nRFcycles(2);
    outbuffer(RIGHT_RF_CYCLE_LOWBYTE) = r_nRFcycles(1);
    
end