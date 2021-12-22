% function newsig = ResampleAudio(sig,targetfs,fs)
function newsig = ResampleAudio(sig,targetfs,fs)
    [p, q] = rat(fs/targetfs, 0.001);
    for jj = 1:size(sig,2)
        newsig(:,jj) = resample(sig(:,jj),q,p);
    end
    
end