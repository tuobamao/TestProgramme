function p = FindCCiMobileComPorts
    % get all active serial com ports
    active_com = seriallist;

    % query registry to see which com ports have been associated with a
    % FTDI device
    key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\FTDIBUS\';
    [~, vals] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);
    if ischar(vals) && strcmp('ERROR',vals(1:5))
        disp('Error: EnumSerialComs - No Enumerated USB registry entry')
        return;
    end
    
    % match active ports with registry
    vals = textscan(vals,'%s','delimiter','\t');
    vals = cat(1,vals{:});    
    p = [];
    for ii = 1:numel(vals)
        mval = regexp(vals{ii},'COM\d*','match');
        if ~isempty(mval)
            if ismember(mval,active_com)
                mval = regexp(mval,'\d*','match');
                mval = str2double(mval{1});
                p = [p; mval];
            end
        end
    end
end