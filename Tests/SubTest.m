classdef SubTest < handle
    properties
        result; % for printing record.
        data = struct();
        mainTestObj;
    end
    methods(Abstract)
        initialize(obj);
        [audio,fs] = process_audio(obj);
        process_answer(obj);
        calculate_result(obj);        
    end
end

