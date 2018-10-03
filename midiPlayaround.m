%Next step is to differentiate between an off and an on MIDI message.
%Should be easily defineable using the 128 144 code messages. Probs want to
%add any note on message to the top of the matrix whilst storing the note
%off message above any other note off message but never replacing a note
%on...effectively producing history of the note of messages, only if there
%is space

%Initialisations
onOffMessages = [];
noteNoMessages = [];
velocityMessages = [];

%Arpeggiator matrix storage
myMatrix = zeros(10,4);
myMatrix(:,1) = linspace(1,10,10);

%Define midi input device
midiInput = mididevice('LPK25');

%Need some sort of WHILE TRUE overarching loop which constantly "listens"
%for new MIDI data from the selected source.

t0 = clock;
while etime(clock, t0) < 60 %run loop for a whole minute
    
    msgs = midireceive(midiInput);
    
    if length(msgs) ~= 0
        for i = 1:length(msgs)   
        %Get midi byte from input.
        midiMessage = msgs(i).MsgBytes;
        onOffMessages(end+1) = midiMessage(1);
        noteNoMessages(end+1) = midiMessage(2);
        velocityMessages(end+1) = midiMessage(3);
        latestMIDIMessage = [midiMessage(1) midiMessage(2) midiMessage(3)];

        %Shifts all notes along in the storage matrix 
            if latestMIDIMessage ~= [0 0 0] %checks midimessage has been received
                for j = length(myMatrix):-1:1 %iterate backwards through values
                    %Shift every stored note down a row in the matrix
                    if myMatrix(j,2:4) ~= [0 0 0] & j < length(myMatrix)
                        myMatrix(j+1,2:4) = myMatrix(j,2:4);
                    end
                end            
                %Inserts the new midi message into the first row of the matrix.
                myMatrix(1,2:4) = latestMIDIMessage;
                latestMIDIMessage = [0 0 0];
            end

        end
        myMatrix
    end
end



% This updates the following row with the previous row's entries.
% current = 1;
% myMatrix(current+1,2:4) = myMatrix(current,2:4);
