addpath('CCiMobileTools')
addpath('.\CCiMobileTools\Strategies')
addpath('.\CCiMobileTools\CommonFunctions')

% parameters
strategy_name = 'ACE';
lmapname = '.\MAPs\sunmingyuan_left.txt';
rmapname = '.\MAPs\sunmingyuan_right.txt';
% lmapname = '.\MAPs\CI1_ACE_Left.txt';
% rmapname = '.\MAPs\CI1_ACE_Right.txt';


mode = 'bilateral';
preemphasis = false; % not implemented
agc = false; % not implemented
source = 'microphone';
destination = 'rfcoil';

gain = 0;
vol = 8;

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
cObj.process(strategy,source,destination,true);