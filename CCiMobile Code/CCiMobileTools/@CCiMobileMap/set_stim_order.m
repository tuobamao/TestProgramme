function set_stim_order(obj,stimorder)
    switch stimorder
        case 'base-to-apex'
            obj.ChannelOrder = (obj.NumberOfBands:-1:1)';
        case 'apex-to-base'
            obj.ChannelOrder = (1:obj.NumberOfBands)';
    end
end
