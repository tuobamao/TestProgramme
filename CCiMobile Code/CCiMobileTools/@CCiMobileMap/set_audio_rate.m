function set_audio_rate(obj,fs)
    obj.Shift	= ceil(fs / max(obj.PulseRate));
    obj.AnalysisRate = round(fs / obj.Shift);
