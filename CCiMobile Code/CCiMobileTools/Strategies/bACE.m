classdef bACE < Strategy
    properties
        % user defined properties
        fftsize
        stimorder
        windowtype
        n_maxima
    end
    
    properties(Access = protected)
        % pre-calculated values (for speed)
        numbins
        window
        lparams
        rparams
        
        % memory
        bufhistory_l
        bufhistory_r
        z_l
        z_r
    end
    
    methods (Access = public)
        function obj = bACE()
            obj.fftsize = 128;
            obj.n_maxima = 8;
            obj.stimorder = 'base-to-apex';
            obj.windowtype = 'hanning';
        end
        
        function initialize(obj,lmap,rmap,framesize,fs)
            assert(~isempty(lmap) && ~isempty(rmap),'bACE must have right & left MAPs')
            assert(lmap.NMaxima == rmap.NMaxima,'bACE currently only supports equal number of maxima on both sides')
            assert(all(lmap.F_Low == rmap.F_Low) && all(lmap.F_High == rmap.F_High), ...
                'bACE currently only supports same frequency mapping on both sides')
            
            obj.lmap = lmap;
            obj.rmap = rmap;
            obj.framesize = framesize;
            obj.fs = fs;
            obj.n_maxima = lmap.NMaxima;
            
            % pre-calculate parameters
            obj.numbins = obj.fftsize/2+1;
            obj.window = set_window(obj.windowtype,obj.framesize);
            
            obj.lmap.set_stim_order(obj.stimorder);
            obj.lparams = calculate_params(obj.lmap,obj);
            obj.bufhistory_l = zeros(1,obj.lparams.overlap);
            obj.z_l = [];
            
            obj.rmap.set_stim_order(obj.stimorder);
            obj.rparams = calculate_params(obj.rmap,obj);
            obj.bufhistory_r = zeros(1,obj.rparams.overlap);
            obj.z_r = [];
        end
        
        function [out_l,out_r] = process(obj,in_l,in_r)
            % convert incoming signal to envelope
            [l_env,obj.z_l,obj.bufhistory_l] = sig2env(obj,in_l,obj.lmap, ...
                obj.lparams,obj.bufhistory_l,obj.z_l);
            [r_env,obj.z_r,obj.bufhistory_r] = sig2env(obj,in_r,obj.rmap, ...
                obj.rparams,obj.bufhistory_r,obj.z_r);
        
            % do binaural peak picking
            [l_env,r_env] = binaural_reject(obj.n_maxima,l_env,r_env);
            
            % apply compression and re-order into vector
            out_l = env2vec(l_env,obj.lmap);
            out_r = env2vec(r_env,obj.rmap);
        end
        
    end
    
end % end ACE

%% helper functions

function [u,z,bufhistory] = sig2env(obj,in,map,params,bufhistory,z)
    % divide incoming audio into time-shifted chunks
    [u,z,bufhistory] = buffer([z;in],obj.framesize,params.overlap,bufhistory);
    nFrames = size(u,2);

    % Apply window
    u = u .* repmat(obj.window,1,nFrames);

    % Perform FFT to give Frequency-Time Matrix and discard symmetric bins
    u = fft(u,obj.fftsize);
    u((obj.numbins+1):end,:) = [];

    % calculate envelope using weighted sum of bin powers
    u = sqrt( params.weights * (u .* conj(u)) );

    % apply channel gains
    u = u .* repmat(map.GainScale,1,nFrames);
end

function [u1,u2] = binaural_reject(num_select,u1,u2)
    [num_bands, num_time_slots] = size(u1);

    [~,u1_i] = sort(u1,1,'descend');
    [~,u2_i] = sort(u2,1,'descend');

    for ii = 1:num_time_slots
        mask = union(u1_i(1:num_select,ii), u2_i(1:num_select,ii));
        mask = mask(1:num_select);% find top electrodes, favoring low frequencies
        delmask = setxor(1:num_bands,mask);

        u1(delmask,ii) = NaN;
        u2(delmask,ii) = NaN;
    end
end

function out = env2vec(u,map)
    nFrames = size(u,2);

    % apply compression
    u = compress(u,map.BaseLevel,map.SaturationLevel,map.LGF_alpha,-1e-10);

    % reorder rows to match patient map channel order
    u = u(map.ChannelOrder,:);

    % vectorize & remove nans
    u = u(:);
    nanmask = isnan(u);
    u(nanmask) = [];

    % electrodes vector
    out.electrodes = map.EL(repmat(map.ChannelOrder,nFrames,1));
    out.electrodes(nanmask) = [];

    % output vector
    out.levels = u;
end

function params = calculate_params(m,obj)
    params.shiftsize = m.Shift;
    params.overlap = obj.framesize - m.Shift;
    
    % create weights matrix
    [params.weights,band_bins] = calculate_weights(m.NumberOfBands,obj.numbins); 
    
    % frequency response equalisation
    params.weights = freq_response_equalization(params.weights,obj.window, ...
        obj.framesize,m.NumberOfBands,band_bins); 
end

function w = set_window(type,blocksize)
    switch lower(type)
        case 'hanning'
            a = [0.5, 0.5, 0.0, 0.0 ];
        case 'hamming'
            a = [0.54, 0.46, 0.0, 0.0 ];
        case 'blackman'
            a = [0.42, 0.5, 0.08, 0.0 ];
        otherwise
            error('Unknown window type')
    end
    n = (0:blocksize-1)';		% Time index vector.
    r = 2*pi*n/blocksize;		% Angle vector (in radians).
    w = a(1) - a(2)*cos(r) + a(3)*cos(2*r) - a(4)*cos(3*r);
end

function [w,band_bins] = calculate_weights(numbands,numbins)
    band_bins = FFT_band_bins(numbands)';
    w = zeros(numbands, numbins);
    bin = 3;	% ignore bins 0 (DC) & 1.
    for band = 1:numbands
        width = band_bins(band);
        w(band, bin:(bin + width - 1)) = 1;
        bin = bin + width;
    end
end

function w = freq_response_equalization(w,window,blocksize,numbands,band_bins)
    freq_response  = freqz(window/2, 1, blocksize);
    power_response = freq_response .* conj(freq_response);
    
    P1 = power_response(1);
    P2 = 2 * power_response(2);
    P3 = power_response(1) + 2 * power_response(3);
    
    power_gains = zeros(numbands, 1);
    for band = 1:numbands
        width = band_bins(band);
        if (width == 1)
            power_gains(band) = P1;
        elseif (width == 2)
            power_gains(band) = P2;
        else
            power_gains(band) = P3;
        end
    end
    
    for band = 1:numbands
        w(band, :) = w(band, :) / power_gains(band);
    end
end

function widths = FFT_band_bins(num_bands)
    switch num_bands
        case 22
            widths = [ 1, 1, 1, 1, 1, 1, 1,    1, 1, 2, 2, 2, 2, 3, 3, 4, 4, 5, 5, 6, 7, 8 ];% 7+15 = 22
        case 21
            widths = [ 1, 1, 1, 1, 1, 1, 1,    1, 2, 2, 2, 2, 3, 3, 4, 4, 5, 6, 6, 7, 8 ];   % 7+14 = 21
        case 20
            widths = [ 1, 1, 1, 1, 1, 1, 1,    1, 2, 2, 2, 3, 3, 4, 4, 5, 6, 7, 8, 8 ];      % 7+13 = 20
        case 19
            widths = [ 1, 1, 1, 1, 1, 1, 1,    2, 2, 2, 3, 3, 4, 4, 5, 6, 7, 8, 9 ];         % 7+12 = 19
        case 18
            widths = [ 1, 1, 1, 1, 1, 2,    2, 2, 2, 3, 3, 4, 4, 5, 6, 7, 8, 9 ];         % 6+12 = 18
        case 17
            widths = [ 1, 1, 1, 2, 2,    2, 2, 2, 3, 3, 4, 4, 5, 6, 7, 8, 9 ];         % 5+12 = 17
        case 16
            widths = [ 1, 1, 1, 2, 2,    2, 2, 2, 3, 4, 4, 5, 6, 7, 9,11 ];         % 5+11 = 16
        case 15
            widths = [ 1, 1, 1, 2, 2,    2, 2, 3, 3, 4, 5, 6, 8, 9,13 ];            % 5+10 = 15
        case 14
            widths = [ 1, 2, 2, 2,    2, 2, 3, 3, 4, 5, 6, 8, 9,13 ];            % 4+10 = 14
        case 13
            widths = [ 1, 2, 2, 2,    2, 3, 3, 4, 5, 7, 8,10,13 ];               % 4+ 9 = 13
        case 12
            widths = [ 1, 2, 2, 2,    2, 3, 4, 5, 7, 9,11,14 ];                  % 4+ 8 = 12
        case 11
            widths = [ 1, 2, 2, 2,    3, 4, 5, 7, 9,12,15 ];                  % 4+ 7 = 11
        case 10
            widths = [ 2, 2, 3,    3, 4, 5, 7, 9,12,15 ];                  % 3+ 7 = 10
        case  9
            widths = [ 2, 2, 3,    3, 5, 7, 9,13,18 ];                     % 3+ 6 =  9
        case  8
            widths = [ 2, 2, 3,    4, 6, 9,14,22 ];                        % 3+ 5 =  8
        case  7
            widths = [ 3, 4,    4, 6, 9,14,22 ];                        % 2+ 5 =  7
        case  6
            widths = [ 3, 4,    6, 9,15,25 ];                           % 2+ 4 =  6
        case  5
            widths = [ 3, 4,    8,16,31 ];                           % 2+ 3 =  5
        case  4
            widths = [ 7,    8,16,31 ];                             % 1+ 3 =  4
        case  3
            widths = [ 7,   15,40 ];                                % 1+ 2 =  3
        case  2
            widths = [ 7,   55 ];                                   % 1+ 1 =  2
        case  1
            widths =  62 ;                                          %         1
        otherwise
            error('illegal number of bands');
    end
end
