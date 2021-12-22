addpath('CCiMobileTools')
addpath('.\CCiMobileTools\Strategies')
addpath('.\CCiMobileTools\CommonFunctions')

% parameters
strategy_name = 'TLE';
% lmapname = '.\MAPs\CI1_ACE_Left_900pps.txt';
% rmapname = '.\MAPs\CI1_ACE_Right_900pps.txt';
% lmapname = '.\MAPs\CI1_ACE_Left.txt';
% rmapname = '.\MAPs\CI1_ACE_Right.txt';

lmapname = '.\MAPs\liyongbin_left.txt';
rmapname = '.\MAPs\liyongbin_right.txt';

preemphasis = false;    % not implemented
agc = false;            % not implemented

% mode = 'bilateral';
mode = 'unilateral_left';
% source = '.\sounds\chirp200us.wav'; gain = -27;
% source = '.\sounds\chirp500us.wav'; gain = -27;
% source = '.\sounds\Jane_R.wav'; gain = -28;
%source = '.\sounds\IDA_coherent.wav'; gain = 0;
%source = '.\sounds\125hztone.wav'; gain = 0;
source = '.\sounds\msp001.wav'; gain = 0;
% source = '.\sounds\E7_transposed_10Hz.wav'; gain = -30;
destination = 'rfcoil';
vol = 10;
plotmode = 2;

%% create CCiMobile Object
cObj = CCiMobile();

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

% set electrodogram property
cObj.set_property('plotmode',plotmode)

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
cObj.process(strategy,source,destination);