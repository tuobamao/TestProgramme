classdef CCiMobileMap < handle
    properties %(Access = protected)
        Filename                    % map filename
        SubjectID                   % subject id
        ImplantType                 % implant model
        Side                        % side (left or right)
        NMaxima                     % number of maxima 
        StimulationMode             % MP1+2
        PhaseWidth                  % duration of each phase (us)
        IPG                         % interphase gap (us)
        Q                           % Q value for compression function
        TSPL                        % SPL to map to THR
        CSPL                        % SPL to map to MCL
        
        % electrode properties (vectors)
        Active                      % vector that determines if an electrode is active
        EL                          % electrodes
        F_Low                       % low frequency cutoff for electrode
        F_High                      % high frequency cutoff for electrode
        THR                         % threshold current level for electrode
        MCL                         % most comfortable current level for electrode
        Gain                        % gain for each electrode (in dB)
        PulseRate                   % pulse rate for electrode
        
        % pre-defined values
        BaseLevel       = 0.0156    % digital value that gets mapped to THR
        SaturationLevel = 0.5859    % digital value that gets mapped to MCL
        
        % derived properties used by CCiMobile
        AnalysisRate                % actual stimulation rate (the rates are different because of length of incoming audio buffer)
        Shift                       % size of one shift of overlap-add buffer
        GainScale                   % linear gain values for each electrode 
        Range                       % dynamic range between THR and MCL
        NumberOfBands               % number of active electrodes
        NMaximaReject               % number of maximas to reject
        ImplantGeneration           % code for implant chipset
        StimulationModeCode         % code for determining stimulation ground mode
        ChannelOrder                % electrode stimulation order
        LGF_alpha                   % alpha value for loudness growth function
    end
    
    properties (Constant)
        BASE_SPL = 25               % default SPL that gets mapped to THR
        SAT_SPL = 65                % default SPL that gets mapped to MCL
    end
    
    methods 
        function obj = CCiMobileMap(varargin)
            if nargin > 0
                if isa(varargin{1},'CCIMobileMap') % copy constructor
                    fnames = fieldnames(obj);
                    for ii = 1:numel(fnames)
                        obj.(fnames) = varargin{1}.(fnames);
                    end
                elseif ischar(varargin{1})
                    assert(strcmpi(varargin{1},'left') || strcmpi(varargin{1},'right'), ...
                        'First argument for CCiMobileMap must specify side')
                    side = varargin{1};
                    obj.load(side,varargin{2});
                else
                    error('First argument should either be a filename or CCiMobileMap')
                end
            elseif nargin > 1
                assert(isnumeric(varargin{2}),'Second argument should be audio sampling rate')
                obj.set_audio_rate(varargin{2})
            end
        end
    end
    
end % end CCIMobileMap