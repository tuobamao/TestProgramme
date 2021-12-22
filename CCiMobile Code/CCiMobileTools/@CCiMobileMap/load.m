function load(obj,side,filename)
    % read header lines
    headerlines = 0;
    fid = fopen(filename,'r');
    while true
        line = fgetl(fid);
        line = regexp(line,':','split');
        headerlines = headerlines + 1;
        switch line{1}
            case {'Filename','SubjectID','ImplantType','Side','Strategy','StimulationMode'}
                obj.(line{1}) = strtrim(line{2});
            case {'NMaxima','PhaseWidth','IPG','Q','TSPL','CSPL'}
                obj.(line{1}) = str2double(line{2});
            otherwise
                break
        end
    end
    fclose(fid);
    
    % check side is correct
    assert(strcmpi(obj.Side,side),'Specified map does not correspond to correct side')
        
    % read electrode lines
    eldata = readtable(filename,'filetype','text','headerlines',headerlines-1);
    for ii = 1:numel(eldata.Properties.VariableNames)
        obj.(eldata.Properties.VariableNames{ii}) = eldata.(eldata.Properties.VariableNames{ii});
    end
    
    % for compatibility
    if isempty(obj.Active)
        obj.Active = obj.MCL > 0;
    end
    
    % remove non-active electrodes
    obj.Gain(obj.Active == false) = [];
    obj.EL(obj.Active == false) = [];
    obj.THR(obj.Active == false) = [];
    obj.MCL(obj.Active == false) = [];
    obj.F_Low(obj.Active == false) = [];
    obj.F_High(obj.Active == false) = [];
    obj.PulseRate(obj.Active == false) = [];
    
    % derive parameters for speed (these need to be removed during save)
    obj.GainScale = 10 .^ (obj.Gain / 20);
    obj.Range = obj.MCL - obj.THR;
    obj.NumberOfBands = sum(obj.Active);
    obj.NMaximaReject = obj.NumberOfBands - obj.NMaxima;
    obj.ImplantGeneration = model2cic(obj.ImplantType);
    obj.StimulationModeCode = stimcode(obj.ImplantGeneration,obj.StimulationMode);
    set_stim_order(obj,'base-to-apex'); % set default stimulation as base-to-apex
    set_audio_rate(obj,16000);          % assume default input sample rate of 16000
    
    % need to adjust base and saturation levels if map TSPL and CSPL are not 25 & 65 dB SPL!!!
    if obj.TSPL ~= obj.BASE_SPL
        error('Only TSPL of 25 dB SPL is currently supported')
    elseif obj.CSPL ~= obj.SAT_SPL
        error('Only CSPL of 65 dB SPL is currently supported')
    end
    
    % supported pulse rates are between 250 & 1800 pulses per second
    assert(all(obj.PulseRate >= 250 | obj.PulseRate <= 1800), 'Pulse rate must be between 250 Hz and 1800 Hz') 
    
    % calculate LGF alpha
    obj.LGF_alpha = LGF_alpha(obj.Q, obj.BaseLevel, obj.SaturationLevel);
end

%% helper functions
function c = model2cic(model)
    switch upper(model)
        case {'CI24M','CI24R'}
            c = 'CIC3';
        case {'CI24RE','CI512','CI513','CI422'}
            c = 'CIC4';
        otherwise
            error('unknown implant model')
    end
end

function c = stimcode(gen,mode)
    switch mode
        case 'MP1+2'
            switch gen
                case 'CIC3'
                    c = 30;
                case 'CIC4'
                    c = 28;
            end
    end
end
