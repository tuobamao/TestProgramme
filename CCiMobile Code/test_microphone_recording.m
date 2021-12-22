addpath('CCiMobileTools')
addpath('.\CCiMobileTools\Strategies')
addpath('.\CCiMobileTools\CommonFunctions')

% parameters
mode = 'bilateral';
source = 'microphone';
destination = 'file';

gain = 0;
vol = 10;
        preemphasis             = false;
        agc                     = false;
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


%% process
cObj.process([],source,destination,'true');