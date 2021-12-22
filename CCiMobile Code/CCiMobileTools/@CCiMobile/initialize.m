function s = initialize(obj,outbuffer) %#ok<INUSL>

    % connect
    s = initializeBoard;
    
    % clear stimulation buffers by sending null frames
    frame_no = 1;
    while frame_no < 3 % send 2 null frames to clear out memory
        if Wait(s) >= 512
            x = Read(s, 512);  %#ok<NASGU>
            
            Write(s, outbuffer, 516); % Write output to the board
            frame_no = frame_no + 1;
        end
    end
    
end
