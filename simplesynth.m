function simplesynth(midiDeviceName)
    
    midiInput = mididevice(midiDeviceName);
    osc = audioOscillator('sawtooth', 'Amplitude', 0);
    deviceWriter = audioDeviceWriter;
    deviceWriter.SupportVariableSizeInput = true;
    deviceWriter.BufferSize = 64; % small buffer keeps MIDI latency low
    
    while true
        msgs = midireceive(midiInput);
        for i = 1:numel(msgs)
            msg = msgs(i);
            if isNoteOn(msg)
                osc.Frequency = note2freq(msg.Note);
                osc.Amplitude = msg.Velocity/127;
            elseif isNoteOff(msg)
                if msg.Note == msg.Note
                    osc.Amplitude = 0;
                end
            end
        end
        deviceWriter(osc());
    end
end

function yes = isNoteOn(msg)
    yes = msg.Type == midimsgtype.NoteOn ...
        && msg.Velocity > 0;
end

function yes = isNoteOff(msg)
    yes = msg.Type == midimsgtype.NoteOff ...
        || (msg.Type == midimsgtype.NoteOn && msg.Velocity == 0);
end

function freq = note2freq(note)
    freqA = 440;
    noteA = 69;
    freq = freqA * 2.^((note-noteA)/12);
end