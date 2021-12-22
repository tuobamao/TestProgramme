function [v, sub, sat] = compress(u,base_level,saturation_level,lgf_alpha,sub_mag)

    % Scale the input between BaseLevel and SaturationLevel:
    r = (u - base_level)/(saturation_level - base_level);

    % Find all the inputs that are above SaturationLevel (i.e. r > 1)
    % and move them down to SaturationLevel:
    sat = r > 1;		% This is a logical matrix, same size as r.
    r(sat) = 1;
    
    % Find all the inputs that are below BaseLevel (i.e. r < 0)
    % and temporarily move them up to BaseLevel:
    sub = r < 0;		% This is a logical matrix, same size as r.
    r(sub) = 0;
    
    % Logarithmic compression:
    v = log(1 + lgf_alpha * r) / log(1 + lgf_alpha);
    
    % Handle values that were below BaseLevel:
    v(sub) = sub_mag;
