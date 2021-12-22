function val = get_property(obj,prop)
    varnames = {'preemphasis','agc','state','mode', ...
        'left_sensitivity_gain','right_sensitivity_gain', ...
        'left_volume','right_volume','plotmode'};
    if any(ismember(varnames,prop))
        val = obj.(prop);
    else
        error('Unknown property')
    end
end