function outputBuffer = init_out_buffer(maps,durationSYNC,additionalGap,frameDuration)

    % define information bytes
    LEFT_HEADER_BYTES = 1:6;
    RIGHT_HEADER_BYTES = 259:264;    

    % Header values
    header_hex = {'88', 'fe', '05', '01', '04', 'fc'}; 
    header_dec = uint8(hex2dec(header_hex));
    if ~isempty(maps)
        if ~isempty(maps.Left)
            lvalues = formatvalues(maps.Left,durationSYNC,additionalGap,frameDuration);
        end
        if ~isempty (maps.Right)
            rvalues = formatvalues(maps.Right,durationSYNC,additionalGap,frameDuration);
        end
    else
        maps = struct('Left',[],'Right',[]);
    end

    % populate buffer
    outputBuffer = uint8(zeros(1,516));
    outputBuffer(LEFT_HEADER_BYTES) = header_dec;
    outputBuffer(RIGHT_HEADER_BYTES) = header_dec;
    if ~isempty(maps.Left) && ~isempty(maps.Right)
        outputBuffer = set_buffer_values(outputBuffer,lvalues,rvalues);
    elseif ~isempty(maps.Left) % only left map exists % Use left parameters for both left and right ears
        outputBuffer = set_buffer_values(outputBuffer,lvalues,lvalues);
    elseif ~isempty(maps.Right) % only left map exists % Use left parameters for both left and right ears
        outputBuffer = set_buffer_values(outputBuffer,rvalues,rvalues);
    else
        % no maps - create a default output buffer
        v.stim_mode_code = uint8(28); % cic4
        v.pulse_width = typecast(uint16(25),'uint8'); % 25 us
        v.pulses_per_frame_per_channel = floor((8.0 * 1000) / 1000); % 1000 pps
        pulses_per_frame = 8 * v.pulses_per_frame_per_channel;
        v.pulses_per_frame = typecast(uint16(pulses_per_frame),'uint8');
        
        v.total_rate = 1000 * 8;
        v.interpulseDuration = frameDuration*1000/pulses_per_frame - (2*25 + 8 + durationSYNC + additionalGap);
        v.ncycles = uint16((v.interpulseDuration/0.1)); % rf cycles seems to be at 1/10 of a microsecond? - AK
        v.nRFcycles= typecast(v.ncycles,'uint8');
        
        outputBuffer = set_buffer_values(outputBuffer,v,v);
    end
end

function v = formatvalues(mp, durationSYNC, additionalGap,frameDuration)
    v.stim_mode_code = uint8(mp.StimulationModeCode);
    v.pulse_width = typecast(uint16(mp.PhaseWidth),'uint8');
    v.pulses_per_frame_per_channel = floor((8.0 * mp.AnalysisRate) / 1000); % I think the 8.0 stands for 8 ms? - AK
    pulses_per_frame = mp.NMaxima * v.pulses_per_frame_per_channel;
    v.pulses_per_frame = typecast(uint16(pulses_per_frame),'uint8');
    
    v.total_rate = mp.AnalysisRate * mp.NMaxima;
    v.interpulseDuration = frameDuration*1000/pulses_per_frame - (2*mp.PhaseWidth + mp.IPG + durationSYNC + additionalGap);
    v.ncycles = uint16((v.interpulseDuration/0.1)); % rf cycles seems to be at 1/10 of a microsecond? - AK
    v.nRFcycles= typecast(v.ncycles,'uint8');
end

function outputBuffer = set_buffer_values(outputBuffer,v1,v2)
    % define information bytes
    LEFT_STIM_MODE_CODE = 381;
    RIGHT_STIM_MODE_CODE = 382;
    LEFT_PULSE_WIDTH_HIGHBYTE = 383;
    LEFT_PULSE_WIDTH_LOWBYTE = 384;
    RIGHT_PULSE_WIDTH_HIGHBYTE = 385;
    RIGHT_PULSE_WIDTH_LOWBYTE = 386;
    LEFT_PULSE_PER_FRAME_HIGHBYTE = 507;
    LEFT_PULSE_PER_FRAME_LOWBYTE = 508;
    RIGHT_PULSE_PER_FRAME_HIGHBYTE = 509;
    RIGHT_PULSE_PER_FRAME_LOWBYTE = 510;
    LEFT_RF_CYCLE_HIGHBYTE = 511;
    LEFT_RF_CYCLE_LOWBYTE = 512;
    RIGHT_RF_CYCLE_HIGHBYTE = 513;
    RIGHT_RF_CYCLE_LOWBYTE = 514;

    % fill buffer
    outputBuffer(LEFT_STIM_MODE_CODE) = v1.stim_mode_code;
    outputBuffer(RIGHT_STIM_MODE_CODE) = v2.stim_mode_code;
    outputBuffer(LEFT_PULSE_WIDTH_HIGHBYTE) = v1.pulse_width(2);
    outputBuffer(LEFT_PULSE_WIDTH_LOWBYTE) = v1.pulse_width(1);
    outputBuffer(RIGHT_PULSE_WIDTH_HIGHBYTE) = v2.pulse_width(2);
    outputBuffer(RIGHT_PULSE_WIDTH_LOWBYTE) = v2.pulse_width(1);
    outputBuffer(LEFT_PULSE_PER_FRAME_HIGHBYTE) = v1.pulses_per_frame(2);
    outputBuffer(LEFT_PULSE_PER_FRAME_LOWBYTE) = v1.pulses_per_frame(1);
    outputBuffer(RIGHT_PULSE_PER_FRAME_HIGHBYTE) = v2.pulses_per_frame(2);
    outputBuffer(RIGHT_PULSE_PER_FRAME_LOWBYTE) = v2.pulses_per_frame(1);
    outputBuffer(LEFT_RF_CYCLE_HIGHBYTE) = v1.nRFcycles(2);
    outputBuffer(LEFT_RF_CYCLE_LOWBYTE) = v1.nRFcycles(1);
    outputBuffer(RIGHT_RF_CYCLE_HIGHBYTE) = v2.nRFcycles(2);
    outputBuffer(RIGHT_RF_CYCLE_LOWBYTE) = v2.nRFcycles(1);
end