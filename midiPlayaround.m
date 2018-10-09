%Need to write a line of code that listens for new messages.

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
    
    %If a message is received then
    if isempty(msgs) ~= 1
        %For each message received
        for noteMessage = 1:length(msgs)
            
            %Get midi byte from input
            midiMessage = msgs(noteMessage).MsgBytes;
            latestMidiMessage = [midiMessage(1) midiMessage(2) midiMessage(3)];
            
            
            %Add any noteOn message notes to the note table
            if latestMidiMessage(1) == 144 %checks midimessage has been received and is a note on
                midiNotes = addNote(latestMidiMessage,midiNotes);
                latestMidiMessage = [0 0 0];
            end

            
            %Remove any noteOff message notes from the note table
            if latestMidiMessage(1) == 128 %checks midimessage is a note off
                midiNotes = removeNote(latestMidiMessage,midiNotes);
                latestMidiMessage = [0 0 0];
            end 

        end
    
        %Down Arpeggiator
        arpeggios = downArp(midiNotes)
        
        % Up arpeggiator
%         arpeggios = upArp(midiNotes)

        %Up Down Arpeggiator
    end
end


function outputNoteTable = downArp(inputNoteTable)
%Sort notes for up arpeggiator
    outputNoteTable = sortrows(inputNoteTable,3,'descend');
    outputNoteTable(:,1) = linspace(1,10,10);
end



function outputNoteTable = upArp(inputNoteTable)
%Sort notes for up arpeggiator
    outputNoteTable = sortrows(inputNoteTable,3);
    outputNoteTable(:,1) = linspace(1,10,10);
end



function outputNoteTable = removeNote(latestMidiMessage,inputNoteTable)
%Remove the note in the corresponding noteOff message from the note table

for i = 1:length(inputNoteTable)
    if latestMidiMessage(2) == inputNoteTable(i,3)
        inputNoteTable(10,2:4) = [0 0 0];
        for j = i:length(inputNoteTable)
            if j < length(inputNoteTable)
                inputNoteTable(j,2:4) = inputNoteTable(j+1,2:4); %This process of shifting every note up or down one place should be made into a callable function.
            end
        end
    end
end

outputNoteTable = inputNoteTable;

end



function outputNoteTable = addNote(latestMidiMessage,inputNoteTable)
%Add note from the corresponding noteOn message to the note table

for i = length(inputNoteTable):-1:1 %iterate backwards through values
    %Shift every stored note down a row in the matrix
    if inputNoteTable(i,3) ~= 0 && i < length(inputNoteTable)
        inputNoteTable(i+1,2:4) = inputNoteTable(i,2:4);
    end
end
%Inserts the new midi message into the first row of the matrix.
inputNoteTable(1,2:4) = latestMidiMessage;
outputNoteTable = inputNoteTable;
end


% % This function will not work but I'm trying to think along these lines.
% function deviceWriter = playSound(inputNoteTable)
% %Output sound
% 
% for i = 1:length(inputNoteTable)
%     %Send notes to the oscillator
%     if inputNoteTable(i,2) == 144
%         freq = freqA * 2.^((inputNoteTable(i,3)-noteA)/12);
%         osc.Frequency = freq;
%         osc.Amplitude = 1;
%         while etime(clock, t0) < 0.15 %run loop for 0.15s
%             deviceWriter(osc());
%         end
%         pause(0.1);
%         t0 = clock;
%     end
% end
% 
% end


% This updates the following row with the previous row's entries.
% current = 1;
% myMatrix(current+1,2:4) = myMatrix(current,2:4);

% Pursuing this idea for storing all data that is processed could be a good
% idea in the long run so to keep a log of work.
%             onOffMessages(end+1) = midiMessage(1);
%             noteNoMessages(end+1) = midiMessage(2);
%             velocityMessages(end+1) = midiMessage(3);