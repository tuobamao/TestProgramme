% parameters
stimrate = 1200; % this is the MAP rate

% test audio file
[sig,fs] = audioread('.\Sounds\1kTone.wav');

% calculate analysis rate
block_size = 128;
block_shift = ceil(fs/stimrate);
analysis_rate = round(fs/block_shift);
actual_stim_rate = analysis_rate;

% pad signal to ensure the whole file is processed
sig = [sig; zeros(block_size - block_shift,1)];

% create window
win = 'Hanning';
switch win
    case 'Hanning'
        a = [0.5, 0.5, 0.0, 0.0 ];
    case 'Hamming'
        a = [0.54, 0.46, 0.0, 0.0 ];
    case 'Blackman'
        a = [0.42, 0.5, 0.08, 0.0 ];
    otherwise
        a = [0.5, 0.5, 0.0, 0.0 ];
end
n = (0:block_size-1)';		% Time index vector.
r = 2*pi*n/block_size;		% Angle vector (in radians).
window = a(1) - a(2)*cos(r) + a(3)*cos(2*r) - a(4)*cos(3*r); 

% divide audio into 8 ms chunks
s = buffer(sig,block_size);


%% UTD method
outblock1 = [];
bufferHistory = zeros(block_size - block_shift,1);
for ii = 1:size(s,2)
    [u,z,opt] = buffer(s(:,ii),block_size, block_size-block_shift,bufferHistory);
    u = u .* repmat(window, 1, size(u,2));	% Apply window
    outblock1 = [outblock1 u];
    bufferHistory = s((block_size-(block_size-block_shift)+1):end,ii);
end

outsig = zeros(size(outblock1,2)*block_shift+block_size,1);
overlap_add_buf = zeros(block_size,1);
startindex = 1;
for ii = 1:size(outblock1,2)
    outframe = outblock1(:,ii);
    outframe(1:block_size-block_shift,1) = outframe(1:block_size-block_shift,1) + overlap_add_buf(block_shift+1:block_size,1);
    overlap_add_buf = outframe;
    
    outsig(startindex:startindex + block_shift - 1,1) = overlap_add_buf(1:block_shift,1);
    startindex = startindex + block_shift;
end

figure
hold on
plot([zeros(block_size - block_shift,1); sig],'r')
plot(outsig/max(abs(outsig)))
title('UTD Method')
ylim([-1.2 1.2])
legend('original','reconstructed')
movegui(gcf,'northwest')
ah(1) = gca;

%% correct method
outblock2 = [];
bufferHistory = zeros(block_size - block_shift,1);
z = [];
for ii = 1:size(s,2)
    [u,z,bufferHistory] = buffer([z;s(:,ii)],block_size, block_size-block_shift,bufferHistory);
    u = u .* repmat(window, 1, size(u,2));	% Apply window
    outblock2 = [outblock2 u];
end

outsig2 = zeros(size(outblock2,2)*block_shift+block_size,1);
overlap_add_buf = zeros(block_size,1);
startindex = 1;
for ii = 1:size(outblock2,2)
    outframe = outblock2(:,ii);
    outframe(1:block_size-block_shift,1) = outframe(1:block_size-block_shift,1) + overlap_add_buf(block_shift+1:block_size,1);
    overlap_add_buf = outframe;
    
    outsig2(startindex:startindex + block_shift - 1,1) = overlap_add_buf(1:block_shift,1);
    startindex = startindex + block_shift;
end

figure
hold on
plot([zeros(block_size - block_shift,1); sig],'r')
plot(outsig2/max(abs(outsig2)))
title('Correct Method')
ylim([-1.2 1.2])
legend('original','reconstructed')
movegui(gcf,'northeast')
ah(2) = gca;

linkaxes(ah)