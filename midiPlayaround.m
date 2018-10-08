%Probs want to add any note on message to the top of the matrix whilst storing the note
%off message above any other note off message but never replacing a note
%on...effectively producing history of the note of messages, only if there
%is space

%Next step is to add a sound output/work out how that would happen. After
%this the process will need to be split up into defined functions I do
%believe. MIDI data receival should be the first command in a MAIN loop.

%Initialisations
onOffMessages = [];
noteNoMessages = [];
velocityMessages = [];

freqA = 440;
noteA = 69;

%Create an oscillator
osc = audioOscillator('sawtooth', 'Amplitude', 0);
deviceWriter = audioDeviceWriter;
deviceWriter.SupportVariableSizeInput = true;
deviceWriter.BufferSize = 64; % small buffer keeps MIDI latency low

%Arpeggiator matrix storage
midiNotes = zeros(10,4);
midiNotes(:,1) = linspace(1,10,10);
arpeggios = zeros(10,4);

%Define midi input device
midiInput = mididevice('LPK25');

%Need some sort of WHILE TRUE overarching loop which constantly "listens"
%for new MIDI data from the selected source.

t0 = clock;

while true
    
    msgs = midireceive(midiInput);
        
    for i = 1:length(arpeggios)
        %Send notes to the oscillator
        if arpeggios(i,2) == 144
            freq = freqA * 2.^((arpeggios(i,3)-noteA)/12);
            osc.Frequency = freq;
            osc.Amplitude = 1;
            while etime(clock, t0) < 0.15 %run loop for a whole minute
                deviceWriter(osc());
            end
            pause(0.1);
            t0 = clock;
        end
    end
    
    if isempty(msgs) ~= 1
        for noteMessage = 1:length(msgs)
            %Get midi byte from input.
            midiMessage = msgs(noteMessage).MsgBytes;
            
%             onOffMessages(end+1) = midiMessage(1);
%             noteNoMessages(end+1) = midiMessage(2);
%             velocityMessages(end+1) = midiMessage(3);
            latestMIDIMessage = [midiMessage(1) midiMessage(2) midiMessage(3)];
            
            %Shifts all notes along in the storage matrix
            if latestMIDIMessage(1) == 144 %checks midimessage has been received and is a note on
                for i = length(midiNotes):-1:1 %iterate backwards through values
                    %Shift every stored note down a row in the matrix
                    if midiNotes(i,3) ~= 0 && i < length(midiNotes)
                        midiNotes(i+1,2:4) = midiNotes(i,2:4);
                    end
                end
                %Inserts the new midi message into the first row of the matrix.
                midiNotes(1,2:4) = latestMIDIMessage;
                latestMIDIMessage = [0 0 0];
            end
            
            %If a note OFF message is received, remove the corresponding
            %note from the matrix and shift every other note up a row in
            %the matrix.
            if latestMIDIMessage(1) == 128 %checks midimessage has been received and is a note off
                for i = 1:length(midiNotes)
                    if latestMIDIMessage(2) == midiNotes(i,3)
                        midiNotes(10,2:4) = [0 0 0];
                        for j = i:length(midiNotes)
                            if j < length(midiNotes)
                                midiNotes(j,2:4) = midiNotes(j+1,2:4); %This process of shifting every note up or down one place should be made into a callable function.
                            end
                        end
                    end
                end
                latestMIDIMessage = [0 0 0];
            end 
        end
        
%         %     Down Arpeggiator
%         arpeggios = sortrows(midiNotes,3,'descend');  
%         arpeggios(:,1) = linspace(1,10,10);
%         arpeggios
        
        %     %Up Arpeggiator
        arpeggios = sortrows(midiNotes,3);
        arpeggios(:,1) = linspace(1,10,10);
        arpeggios
        %Up Down Arpeggiator
    end
end

% This updates the following row with the previous row's entries.
% current = 1;
% myMatrix(current+1,2:4) = myMatrix(current,2:4);
