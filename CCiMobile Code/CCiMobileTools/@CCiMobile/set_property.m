function set_property(obj,prop,val)
    prop = lower(prop);
    
    % check value
    switch prop
        case {'agc','preemphasis'} % boolean properties
            assert(islogical(val),'Must set %s with a boolean value',prop)
            if val
                error('AGC not implemented')
            end
        case 'mode'
            assert(ischar(val),'Must set %s with a string',prop)
            val = lower(val);
            if strcmp(val,'unilateral_left') || strcmp(val,'unilateral_right') || ...
               strcmp(val,'bimodal_left') || strcmp(val,'bimodal_right') || ...
               strcmp(val,'bilateral')
            else
                error('Valid modes are: bilateral, unilateral_left, unilateral_right, bimodal_left, or bimodal_right')
            end
        case 'plotmode'
            assert(isnumeric(val) && (val >=0 || val <= 2),'%s should be either 0, 1, or 2')
        case {'left_sensitivity_gain','right_sensitivity_gain'}
            GAINRANGE = 30;
            assert(isnumeric(val),'Must set %s with a numerical value',prop)
            assert(val >=-GAINRANGE && val <= GAINRANGE,'Gain must be between range of -%d and %d dB',GAINRANGE,GAINRANGE)
        case {'left_volume','right_volume'}
            MAXVOL = 10;
            assert(isnumeric(val),'Must set %s with a numerical value',prop)
            assert(val >=0 && val <= MAXVOL,'Volume must be between range of 0 and %d',MAXVOL)
        otherwise
            error('Unknown property')
    end
    
    % assign value to property
    obj.(prop) = val;
end