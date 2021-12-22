function [VocodedSound,VocEnv] = electrovocoder(electrodogram,map,vocoderCarrier)
% Transfer a electrodgram to a vocoder simulation sound
% Each pulse is replaced by a Guassian Envelope whose tp is 5 times of
% carrier period. The carrier frequency is in the middle of current band 
% (e.g. for the first channel the carrier frequency is 250 Hz,
% the effective duration of the gaussian envleope is 5/250 = 20ms. The
% whole duration is then expected to be 20*3 ms = 60 ms.
% How to generate the Gaussian Envelope, See Baer, Moore, Glasberg, 1999. JASA
% So the vocoder output is expected to be 60ms longer than the electrodogram to prevent the first and last pulse working).

% About the Gaussian Shaped Tone burst,
% See Fastl and Zwicker. Psychoacoustics:Facts and Models. Fig.1.1.
% 

% Tone carrier, or noise carrier
NumCh = map.NumberOfBands;
NumMax = map.NMaxima;
NumPulses = length(electrodogram.electrodes);
% InterPulsePeriod = electrodogram.periods;
InterPulsePeriod = 1/map.AnalysisRate/map.NMaxima*1000000;  % 20171001 modified by Qinglin to get correct plot x axis   。 1000000的含义我也没搞懂
T = NumPulses*InterPulsePeriod/(1e6)+0.06;
fs = 16000;
NumSampling = round(T*fs);
t = (0:NumSampling-1)/fs;
VocEnv = zeros(NumCh,NumSampling);
VocCarrier = zeros(NumCh,NumSampling);


% get carriers
fftsize = 128;
block_size = 128;
bin_freqres = fs / fftsize; % frequency bin resolution
bin_freqs = bin_freqres * (0:(fftsize-1)); % frequency value for each fft bin
bin_freqs = bin_freqs(1:fftsize/2+1);
[weights,~] = calculate_weights(NumCh,fftsize/2+1); 
switch vocoderCarrier 
    case 1 % If Tone carrier        
        for n = 1:NumCh
            UsefulBins = weights(NumCh-n+1,:)>0;
            fc(n) = sum(UsefulBins.*bin_freqs)/sum(UsefulBins);  % n=1 Highest freq, n = 22 lowest freq
            VocCarrier(n,:) = sin(2*pi*fc(n)*t)/NumMax; % sine wave carriers, initial phase:0
            D(n) = 3/fc(n); % D is the effective duration of Gaussian Envelope
        end
    case 2 % If Noise Carrier        
        for n = 1:NumCh
            VocCarrier(n,:) = zeros(size(t));
            UsefulBins = weights(NumCh-n+1,:)>0;
            fc(n) = sum(UsefulBins.*bin_freqs)/sum(UsefulBins);  % n=1 Highest freq, n = 22 lowest freq
            freqs = bin_freqs(UsefulBins);
            cutoffs = [freqs(1)-fs/block_size/2,freqs(end)+fs/block_size/2];%这是为啥
            bandwidth = diff(cutoffs);
            for m = 1:ceil(bandwidth*0.1) % 0.1约等于24.7*4.37/1000 与ERB有关
                tempFreq = rand(1)*bandwidth+cutoffs(1);
                VocCarrier(n,:) = VocCarrier(n,:)+sin(2*pi*tempFreq*t+rand(1)*2*pi);% adding many sines with random initial phase gets a noise
            end
            D(n) = 3/fc(n); % D is the effective duration of Gaussian Envelope
        end
end

%2018/3/22 现在是两种载波 左右同步的正弦载波和左右不同步的随机噪声载波
% 还可以考虑另外左右同步的载波

% Wnoise = randn(1,NumSampling);
% u = buffer(Wnoise, map.block_size, map.block_size - map.block_shift, []);
% v = u .* repmat(map.window, 1, size(u,2));	% Apply window
% u = fft(v);									% Perform FFT to give Frequency-Time Matrix
% u = [map.weights,map.weights(:,end-1:-1:2)] * u;						% Weighted sum of bin powers.
% u = ifft(u);

v = electrodogram.current_levels/255; % see logarithmic_compression.m
% acousticLevel = r*(map.SaturationLevel - map.BaseLevel)+map.BaseLevel;
% acousticLevel = (exp(v)*(1 + map.LGF_alpha)-1)/map.LGF_alpha;
acousticLevel = ((1 + map.LGF_alpha).^v-1)/map.LGF_alpha; % inverse of logarithmic compression, 20210108

for n = 1:NumPulses
    currentElecrode = electrodogram.electrodes(n);
    if currentElecrode % if not 0
        halfEnvelopePointNum = 3*round((D(currentElecrode)/2)*fs);
        GauEnv = acousticLevel(n)*GaussianEnvelope(D(currentElecrode),halfEnvelopePointNum,fs);
        currentTime = n*InterPulsePeriod/(1e6);
        temp = round(currentTime*fs);
        for tempIndex =  -halfEnvelopePointNum:halfEnvelopePointNum
            if tempIndex+temp > 0
                VocEnv(currentElecrode,tempIndex+temp) = max(VocEnv(currentElecrode,tempIndex+temp), GauEnv(tempIndex+halfEnvelopePointNum+1));
            end
        end
    end
end

ModulatedBands = VocEnv.*VocCarrier;
for n = 1:NumCh
    if rms(ModulatedBands(n,:)) ~=0
        ModulatedBands(n,:) = ModulatedBands(n,:) * rms(electrodogram.current_levels(electrodogram.electrodes == n)) / rms(ModulatedBands(n,:));
    end
end

VocodedSound = sum(ModulatedBands);

% Deemphasis
p.pre_numer =    [0.4994   0.4994];
p.pre_denom =    [1.0000   -0.0012];
VocodedSound = filter(p.pre_numer, p.pre_denom,VocodedSound);

VocodedSound = VocodedSound/max(VocodedSound)*0.5;
% sound(VocodedSound,fs);


% % removed by Huali 20210106
% subplot(311);
% myspectrogram(VocodedSound,fs);
% ylim([0,8000]);
% subplot(312);
% VocEnv = VocEnv / max(VocEnv(:));
% VocEnv(VocEnv==0) = NaN;
% t = (0:size(VocEnv,2)-1)/fs;
% for n = 1:NumCh
% %     if strcmp(map.lr_select,'left')
%         plot(t,VocEnv(n,:)+NumCh-(n-1),'k'); hold on;
% %     else
% %         plot(t,VocEnv(n,:)+NumCh-(n-1),'r'); hold on;
% %     end
% end
% axis([0,t(end),0.5,NumCh+0.9])
end

function GauEnv = GaussianEnvelope(D,halfEnvelopePointNum,fs)
t = (-halfEnvelopePointNum:halfEnvelopePointNum)/fs;
GauEnv = exp(-pi*t.^2/D^2);
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