function save(obj,filename)
    headernames = {'Filename','SubjectID','ImplantType','Side','NMaxima','StimulationMode','PhaseWidth','IPG','Q','TSPL','CSPL'};
    tabnames = {'Active','EL','F_Low','F_High','THR','MCL','Gain','PulseRate'};
    
    fid = fopen(filename,'w');

    % write header information
    for ii = 1:numel(headernames)
        if ischar(obj.(headernames{ii}))
            fprintf(fid,'%s: %s\n',headernames{ii},obj.(headernames{ii}));
        else
            fprintf(fid,'%d: %s\n',headernames{ii},obj.(headernames{ii}));
        end
    end
    
    % write electrode information
    t = table;
    for ii = 1:numel(tabnames)
        t.(tabnames{ii}) = obj.(tabnames{ii});
    end
    fprintf(fid,'%s\n',strjoin(tabnames,','));
    for ii = 1:22
        for jj = 1:numel(tabnames)
            fprintf(fid,'%d',obj.(tabnames{jj})(ii));
            if jj == numel(tabnames)
                fprintf(fid,'\n');
            else
                fprintf(fid,',');
            end
        end
    end
    
    fclose(fid);
end