addpath('CCiMobileTools')
addpath('.\CCiMobileTools\Strategies')
addpath('.\CCiMobileTools\CommonFunctions')
addpath('.\DAQ')

usedaq = true; 

% parameters
strategy_name = 'ACE';

lmapname = '.\MAPs\sunmingyuan_left.txt';
rmapname = '.\MAPs\sunmingyuan_right.txt';
mode = 'bilateral';
preemphasis = false; % not implemented
agc = false; % not implemented

% source = '.\sounds\Jane_R.wav'; gain = -30;
source = '.\sounds\E7_transposed_10Hz.wav'; gain = -30;
destination = 'rfcoil';

vol = 10;

%% create CCiMobile Object
cObj = CCiMobile;

% set stimulation mode
cObj.set_property('mode',mode);

% set frontend processing
cObj.set_property('preemphasis',preemphasis)
cObj.set_property('agc',agc)

% set gains
cObj.set_property('left_sensitivity_gain',gain)
cObj.set_property('right_sensitivity_gain',gain)

% set volume
cObj.set_property('left_volume',vol)
cObj.set_property('right_volume',vol)

%% Load MAPs
lmap = CCiMobileMap('left',lmapname,cObj.FS);
rmap = CCiMobileMap('right',rmapname,cObj.FS);

%% Initialize strategy
strategy = feval(str2func(strategy_name));
switch mode
    case 'bilateral'
        strategy.initialize(lmap,rmap,cObj.FRAMESIZE,cObj.FS);
    case 'unilateral_left'
        strategy.initialize(lmap,[],cObj.FRAMESIZE,cObj.FS);
    case 'unilateral_right'
        strategy.initialize([],rmap,cObj.FRAMESIZE,cObj.FS);
end

%% process
if usedaq
    recchannels = [1,2];
    daq_sampling = 500000;
    reclen = 2;
    channel_sampling = floor(daq_sampling/length(recchannels));
    session = beginDAQSession(recchannels,channel_sampling,reclen);
    acquireDAQData(session);
end

cObj.process(strategy,source,destination,false);

if usedaq
    data = closeDAQsession(session);
    time = data.Var1;
    recdata = data{:,2:end};
    
    time = time - time(1);
    
    figure
    plot(time*1000,recdata)
    xlabel('Time (ms)')
end

[stim,fs] = audioread(source);

