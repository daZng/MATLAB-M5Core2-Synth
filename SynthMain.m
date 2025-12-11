%% Initialize M5

clear
disp(serialportlist)
spl = serialportlist;
m5 = spl(7);

ard = arduino(m5, 'ESP32-WROOM-DevKitC', 'Libraries', {'M5Stack/M5Unified', 'M5Stack/M5UnitSynth'});
synth = addon(ard, 'M5Stack/M5UnitSynth', 'RXPin', 13, 'TXPin', 14);
m5u = addon(ard, 'M5Stack/M5Unified');

%% Synth 

%bug for note pitch 0 yet (doesn't get played during loop playback)
%simple fix would be to make 0 10000 and -10000
%or refactor so that its a 3 element array instead of 2 and the third element is on or off

%also this code does not work for multi touch screens since it does not account for record on > note on > record off > note off

synth.setMasterVolume(127);
Synth(synth, m5u);

function Synth(synth, m5u)

    sW = 320;
    sH = 240;
    
    m5u.lcdClear();
    m5u.lcdTextSize(2);
    m5u.lcdTextColor(0xffff, 0);

    %Notes
    keyNotes = [60, 62, 64, 65, 67, 69, 71, 61, 63, 66, 68, 70];
    %keyNotes = [68, 69, 70, 71, 64, 65, 66, 67, 60, 61, 62, 63];
    C  = [60, 64, 67];
    D  = [62, 66, 69];
    E  = [64, 68, 71];
    F  = [65, 69, 72];
    Cm = [60, 65];
    Dm = [60, 63];
    Em = [58, 63, 67];
    Fm = [58, 62, 65];
    % Cm = [60, 63, 67];
    % Dm = [62, 65, 69];
    % Em = [64, 67, 71];
    % Fm = [65, 68, 72];
    C7 = [60, 64, 67, 70];
    D7 = [62, 66, 69, 72];
    E7 = [64, 68, 71, 74];
    F7 = [65, 69, 72, 75];

    chordNotes = {C, D, E, F, Cm, Dm, Em, Fm, C7, D7, E7, F7};
    drumNotes = [42, 39, 35, 40];%[42, 46, 35, 40];%35, 38];

    %Instruments
    instruments = ["Piano       ", "Square       ", "Harpsichord ", "Glockenspiel", ...
                   "MusicBox    ", "Vibraphone   ", "Sawtooth    ", "Organ       ", ...
                   "Pad 2       ", "Bass         ", "Violin      ", "Cello       "];

    instrumentValues = [0, 80, 6, 9, 10, 11, 81, 16, 89, 32, 40, 42];

    %Initialize Buttons

    % Button Colors 

    % based on state numbers
    disabledColors = [0x1169, 0x0b29, 0xc4a3, 0xb928];
    onColors = [0xe75e, 0xcffd, 0xff9a, 0xff5d];
    offBlackColors = [0x2aaf, 0x05f1, 0xfe8c, 0xea4d];
    offWhiteColors = [0x753a, 0x8719, 0xff13, 0xedb8];
    outlineColors = [0x222c, 0x0c8d, 0x8b43, 0xebd2];

    pitchButtonColors = [0xd6ba, 0xb5d7, 0x8410]; %on, off, outline

    %Text Colors
    defaultTextColors = [0xffff, 0];
    textColors = [pitchButtonColors(3), pitchButtonColors(2)];
    keySelectedTextColors = [onColors(1), offWhiteColors(1)];
    keyTextColors = [offWhiteColors(1), offBlackColors(1)]; %window button text colors are the same but reversed
    chordSelectedTextColors = [onColors(2), offWhiteColors(2)];
    chordTextColors = [offWhiteColors(2), offBlackColors(2)];
    loopSelectedTextColors = [onColors(4), offWhiteColors(4)];
    loopTextColors = [offWhiteColors(4), offBlackColors(4)];

    outerSpacing = round(sW/6);

    keyWidth = round((sW-outerSpacing)/4);
    keyHeight = round((sH-outerSpacing)/3);
    keyboardKeyWidth = sW/7;
    keyboardKeyHeight = (sH - outerSpacing)/2;
    
    pitchHeight = round((sH-outerSpacing)/2);
    
    borderThickness = 7;
    
    selectedBoxOffset = 12;
    
    roundingErrorOffset = 1;

    keyButtons = [];
    chordButtons = [];
    drumButtons = [];

    listButtons = [];

    listKeyValues = zeros(1, length(instrumentValues)); %first row for key inst, second row for chord inst
    listChordValues = zeros(1, length(instrumentValues));
    listLoopValues = [];
    listLoopStrings = [];
    setAllLoopNotesOff = []; %used for muting

    listKeyValues(1) = 1; %sets the initial key instrument to piano
    listChordValues(1) = 1; %sets the initial chord instrument to piano

    listWindowIndexKey = 0;
    listWindowIndexChord = 0;
    listWindowIndexLoop = 0;
    listWindowUButton=0;
    listWindowDButton=0;
    listWindowText = [];
    listWindowTextXPos = 10;
    listWindowTextYPoss = [70, 115, 164, 210];
    
    pitchTextColors = [pitchButtonColors(3), pitchButtonColors(2)];

    recordButton=0;
    keyStateButton=0;
    chordStateButton=0;
    drumStateButton=0;
    pUButton=0;
    pDButton=0;
    
    InitializeOuterButtons();
    InitializeKeyButtons();
    InitializeChordButtons();
    InitializeDrumButtons();
    InitializeListButtons();

    recordButton.checkForHold = true;

    function InitializeOuterButtons()
        %Record Button
        recordButton = Button(m5u, [0, keyWidth], [0, outerSpacing], "no", "no", "no");
        
        m5u.lcdDrawFillRect(0, 0, keyWidth, outerSpacing, 0xea4d); %Border
        m5u.lcdDrawFillRect(borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole

        %Key Button
        keyStateButton = Button(m5u, [keyWidth, 2*keyWidth], [0, outerSpacing], "no", "no", "no");
        
        m5u.lcdDrawFillRect(keyWidth, 0, keyWidth, outerSpacing, 0x2aaf); %Border
        m5u.lcdDrawFillRect(keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole
        m5u.lcdDrawFillRect(keyWidth+selectedBoxOffset, selectedBoxOffset, keyWidth-2*selectedBoxOffset, outerSpacing-2*selectedBoxOffset, 0x2aaf); %Selection
        
        keyStateButton.checkForHold = true;

        %Chord Button
        chordStateButton = Button(m5u, [2*keyWidth, 3*keyWidth], [0, outerSpacing], "no", "no", "no");
        
        m5u.lcdDrawFillRect(2*keyWidth, 0, keyWidth, outerSpacing, 0x0eb3); %Border
        m5u.lcdDrawFillRect(2*keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole

        chordStateButton.checkForHold = true;

        %Drum Button
        drumStateButton = Button(m5u, [3*keyWidth, 4*keyWidth], [0, outerSpacing], "no", "no", "no");
        
        m5u.lcdDrawFillRect(3*keyWidth, 0, keyWidth, outerSpacing, 0xfe8c); %Border
        m5u.lcdDrawFillRect(3*keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole

        drumStateButton.checkForHold = true;

        %Pitch Value
        m5u.lcdCursor(280, 20);
        m5u.lcdPrint(sprintf("+%d", 0));
        
        %Pitch Up Button
        pUButton = Button(m5u, [4*keyWidth, 4*keyWidth+outerSpacing], [outerSpacing+roundingErrorOffset, outerSpacing+pitchHeight+roundingErrorOffset], pitchButtonColors(1), pitchButtonColors(2), pitchButtonColors(3));
        m5u.lcdTextColor(pitchTextColors(1), pitchTextColors(2));
        m5u.lcdDrawStr(290, 100, "+")

        %Pitch Down Button
        pDButton = Button(m5u, [4*keyWidth, 4*keyWidth+outerSpacing], [outerSpacing+pitchHeight+roundingErrorOffset, outerSpacing+2*pitchHeight+roundingErrorOffset], pitchButtonColors(1), pitchButtonColors(2), pitchButtonColors(3));
        m5u.lcdDrawStr(290, 185, "-")

    end

    function InitializeKeyButtons()

        bHOffset = outerSpacing;
        
        whiteButtons = [];
        blackButtons = [];
        
        bHalfWidth = 18;
        bCenter = sW/7;
        whiteAttachmentXs = {[0, bCenter-bHalfWidth],...
                             [bCenter+bHalfWidth, (bCenter*2)-bHalfWidth],...
                             [(bCenter*2)+bHalfWidth, keyboardKeyWidth*3],...
                             [keyboardKeyWidth*3, (bCenter*4)-bHalfWidth],...
                             [(bCenter*4)+bHalfWidth, (bCenter*5)-bHalfWidth],...
                             [(bCenter*5)+bHalfWidth, (bCenter*6)-bHalfWidth],...
                             [(bCenter*6)+bHalfWidth, sW]};
        
        for iw=1:7
            whiteX = [keyboardKeyWidth*(iw-1), keyboardKeyWidth*iw];
            whiteY = [bHOffset+keyboardKeyHeight+roundingErrorOffset, bHOffset+keyboardKeyHeight*2];
            
            whiteButtons = [whiteButtons Button2(m5u, whiteX, whiteY, whiteAttachmentXs{iw}, [bHOffset++roundingErrorOffset, bHOffset+keyboardKeyHeight+roundingErrorOffset], offWhiteColors(1), m5u.lcdColor.WHITE, "no")];
        end
        
        blackXs = {[bCenter-bHalfWidth, bCenter+bHalfWidth], ...
                   [(bCenter*2)-bHalfWidth, (bCenter*2)+bHalfWidth], ...
                   [(bCenter*4)-bHalfWidth, (bCenter*4)+bHalfWidth], ...
                   [(bCenter*5)-bHalfWidth, (bCenter*5)+bHalfWidth],...
                   [(bCenter*6)-bHalfWidth, (bCenter*6)+bHalfWidth]};
        
        
        for ib=1:5
            blackButtons = [blackButtons Button2(m5u, blackXs{ib}, [bHOffset+roundingErrorOffset, bHOffset+keyboardKeyHeight+roundingErrorOffset ], [-2, -2], [-2, -2], offBlackColors(1), m5u.lcdColor.BLACK, "no")];
        end
        
        keyButtons = [whiteButtons, blackButtons];
        for ibb=1:12
            keyButtons(ibb).ForceRedraw();
        end

        RedrawLines(-1);

    end

    function InitializeChordButtons()
        
        bbI = [2, 4, 5, 7, 10, 12];

        whitePalette = [0xc7fd, 0x979b];
        blackPalette = [0xc7fd, 0x0eb3];
        outlineColor = 0x0d90;
        
        index = 1;
        
        for j=0:2
            for i=0:3
                xBounds = [i*keyWidth, i*keyWidth+keyWidth];
                yBounds = [j*keyHeight+outerSpacing+roundingErrorOffset, j*keyHeight+keyHeight+outerSpacing+roundingErrorOffset];
                if ismember(index, bbI)
                    onColor = blackPalette(1);
                    offColor = blackPalette(2);
                else
                    onColor = whitePalette(1);
                    offColor = whitePalette(2);
                end
                chordButtons = [chordButtons Button(m5u, xBounds, yBounds, onColor, offColor, outlineColor)];
                index = index + 1;
            end
        end

    end

    function InitializeDrumButtons()
        drumWidth = round((sW-outerSpacing)/2);
        drumHeight = round((sH-outerSpacing)/2);
        
        bbI = [1, 4];
        drumButtons = [];
        
        %M5 uses RGB565 color
        whitePalette = [0xff9a, 0xff13];
        blackPalette = [0xff9a, 0xfe8c];
        outlineColor = 0x8b43;%0xfda1;
        
        index = 1;
        
        for j=0:1
            for i=0:1
                xBounds = [i*drumWidth, i*drumWidth+drumWidth];
                yBounds = [j*drumHeight+outerSpacing+roundingErrorOffset, j*drumHeight+drumHeight+outerSpacing+roundingErrorOffset];
                if ismember(index, bbI)
                    onColor = blackPalette(1);
                    offColor = blackPalette(2);
                else
                    onColor = whitePalette(1);
                    offColor = whitePalette(2);
                end
                drumButtons = [drumButtons Button(m5u, xBounds, yBounds, onColor, offColor, outlineColor)];
                index = index + 1;
            end
        end

    end

    function InitializeListButtons()
        selectionHeight = round((sH-outerSpacing)/4);
        listButtons = [listButtons Button(m5u, [0, sW-2*outerSpacing], [outerSpacing+roundingErrorOffset, outerSpacing+selectionHeight+roundingErrorOffset], "no", "no", "no")];
        listButtons = [listButtons Button(m5u, [0, sW-2*outerSpacing], [outerSpacing+selectionHeight+roundingErrorOffset, outerSpacing+2*selectionHeight+roundingErrorOffset], "no", "no", "no")];
        listButtons = [listButtons Button(m5u, [0, sW-2*outerSpacing], [outerSpacing+2*selectionHeight+roundingErrorOffset, outerSpacing+3*selectionHeight+roundingErrorOffset], "no", "no", "no")];
        listButtons = [listButtons Button(m5u, [0, sW-2*outerSpacing], [outerSpacing+3*selectionHeight+roundingErrorOffset, outerSpacing+4*selectionHeight+roundingErrorOffset], "no", "no", "no")];

        listWindowUButton = Button(m5u, [sW-2*outerSpacing, sW-outerSpacing+roundingErrorOffset], [outerSpacing+roundingErrorOffset, outerSpacing+pitchHeight+roundingErrorOffset], "no", "no", "no");
        listWindowDButton = Button(m5u, [sW-2*outerSpacing, sW-outerSpacing+roundingErrorOffset], [outerSpacing+pitchHeight+roundingErrorOffset, outerSpacing+2*pitchHeight+roundingErrorOffset], "no", "no", "no");
    end

    exitButton = Button(m5u, [0, 320], [240, 275], "no", "no", "no");

    resetButtons = false;

    %State variables
    % State: 1 = keys, 2 = chords, 3 = drums, 4 = key inst, 5 = chord inst, 6 = loop selection
    state = 1; 

    %Instrument Selection
    defaultInst = 0;
    keyInst = 0; %0 indexed
    chordInst = 0; 
    drumInst = 118;
    synth.setInstrument(0, 0, keyInst);
    inst = keyInst;
    channel = 0; %as of right now, there is no way of changing a channel to a drumset: Set channel 9 to drums: F0 41 10 42 12 40 19 15 02 10 F7

    % square 80 (81) -2 -3 pitch
    % sawtooth 81 (82) +1 pitch
    % pad 2 warm 89 (90)

    %Loop limit
    loopLimit = 7;

    %Timers
    masterTimer = 0;

    %Recording variables
    recording = false;
    
    recordings = {}; %cell can store arrays of any size or even dictionaries
    durations = []; %used to multiply and compare against master timer which effectively give a timer for each individual loop, NO WE CANNOT USE MOD
    iterators = []; %used to iterate through the recording
    loopCount = []; %used to compare duration against master timer to see if iterator needs to be reset

    recordingTimer = 0; %used to track duration
    newRecording = [];
    frontPadding = 0; %used to track front padding

    newDuration = 0; %quality of life change, so you're not in a rush to press the record button to ensure durNew < dur1
                     %in other words, spacing between loops only depends on start of loop              

    %Stop variable
    stop = false;

    %State correct buttons and notes
    buttons = keyButtons; %because we arbitrarily established key buttons as default
    notes = keyNotes;

    %Pitch
    pitch = 0;

    %Repeater
    repeat=false;
    timeBetweenRepeaterNotes=0;
    repeaterNoteDuration=0;
    repeaterNotesPerLoop=55;
    playingRepeaterNote=false;
    repeaterTic=0;
    repeaterNote=0;

    % Main Loop
    while ~stop

        %Button Updates
        if m5u.touchIsPressed()
            UpdateButtons()
        elseif ~resetButtons
            ResetButtons()
        end

        %Outer key input

        if recordButton.WasReleased()
            if state ~= 6
                if recordButton.WasLongPressed() && ~recording
                    state = 6;
                    ForceRedraw();
                    ForceRedrawPitchButtons();
                    DrawSelection(recordButton);
                    ForceRedrawListButtons(true);
                    DrawArrowText(listWindowUButton);
                    DrawArrowText(listWindowDButton);
                elseif state ~= 4 && state ~= 5
                    if length(durations) < loopLimit
                        recording = ~recording;
                        DrawSelection(recordButton);
                        Record(recording);
                    end
                end
            end

        end

        if keyStateButton.WasPressed()
            if state == 1
                state = 4;
                %DrawDisabled(recordButton, true);
                ForceRedrawPitchButtons();
                DrawSecondarySelection(keyStateButton);
                SetInitialListIndex();
                ForceRedrawListButtons(true);
                DrawArrowText(listWindowUButton);
                DrawArrowText(listWindowDButton);
            else
                state = 1;
                %DrawDisabled(recordButton, false);
                buttons = keyButtons;
                notes = keyNotes;
                if inst ~= keyInst
                    inst = keyInst;
                    channel = 0;
                    synth.setInstrument(0, 0, keyInst);
                end
                DrawSelection(recordButton);
                ForceRedraw();
            end
        end

        if chordStateButton.WasPressed()
            if state == 2
                state = 5;
                %DrawDisabled(recordButton, true);
                DrawSecondarySelection(chordStateButton);
                SetInitialListIndex();
                ForceRedrawListButtons(true);
                DrawArrowText(listWindowUButton);
                DrawArrowText(listWindowDButton);
            else
                state = 2;
                %DrawDisabled(recordButton, false);
                ForceRedrawPitchButtons();
                buttons = chordButtons;
                notes = chordNotes;
                if inst ~= chordInst
                    inst = chordInst;
                    channel = 0;
                    synth.setInstrument(0, 0, chordInst);
                end
                DrawSelection(recordButton);
                ForceRedraw();
            end
        end

        if drumStateButton.WasPressed()
            if state == 3
                state = 7;
                DrawSecondarySelection(drumStateButton);
                ForceRedraw();
            else
                state = 3;
                ForceRedrawPitchButtons();
                buttons = drumButtons;
                notes = drumNotes;
                if inst ~= drumInst
                    inst = drumInst;
                    channel = 9;
                end
                DrawSelection(recordButton);
                ForceRedraw();
            end
        end

        if pUButton.WasPressed()
            if pitch < 4
                pitch = pitch + 1;
                ChangePitch(true);
            end
        end

        if pUButton.WasReleased()
            DrawArrowText(pUButton);
        end

        if pDButton.WasPressed()
            if pitch > -5
                pitch = pitch - 1;
                ChangePitch(false);
            end
        end

        if pDButton.WasReleased()
            DrawArrowText(pDButton);
        end

        %List Selection input

        if state == 4 || state == 5 || state == 6
            for is=1:length(listButtons)
                if listButtons(is).WasPressed()
                    switch state
                        case 4
                            oldSelectedIndex = find(listKeyValues, 1);
                            listKeyValues(oldSelectedIndex) = 0;
                            newSelectedIndex = listWindowIndexKey*4+is;
                            listKeyValues(newSelectedIndex) = 1;
                            keyInst = instrumentValues(newSelectedIndex);
                        case 5
                            oldSelectedIndex = find(listChordValues, 1);
                            listChordValues(oldSelectedIndex) = 0;
                            newSelectedIndex = listWindowIndexChord*4+is;
                            listChordValues(newSelectedIndex) = 1;
                            chordInst = instrumentValues(newSelectedIndex);
                        case 6
                            if listWindowIndexLoop*4+is <= length(listLoopValues)
                                loopIndex = listWindowIndexLoop*4+is;
    
                                if listLoopValues(loopIndex)
                                    setAllLoopNotesOff(loopIndex) = 0;
                                    listLoopValues(loopIndex) = 0;
                                else
                                    listLoopValues(loopIndex) = 1;
                                end
                            end
                            
                    end

                elseif listButtons(is).WasReleased()
                    ForceRedrawListButtons(false);
                end
            end
            
            if listWindowUButton.WasPressed()
                if state == 4 && listWindowIndexKey - 1 >= 0
                    listWindowIndexKey = listWindowIndexKey - 1;
                    ForceRedrawListButtons(false);
                elseif state == 5 && listWindowIndexChord - 1 >= 0
                    listWindowIndexChord = listWindowIndexChord - 1;
                    ForceRedrawListButtons(false);
                elseif state == 6 && listWindowIndexLoop - 1 >= 0
                    listWindowIndexLoop = listWindowIndexLoop - 1;
                    ForceRedrawListButtons(false);
                end
            end

            if listWindowUButton.WasReleased()
                DrawArrowText(listWindowUButton);
            end
            
            if listWindowDButton.WasPressed()
                if state == 4 && listWindowIndexKey + 1 < ceil(length(listKeyValues)/length(listButtons))
                    listWindowIndexKey = listWindowIndexKey + 1;
                    ForceRedrawListButtons(false);
                elseif state == 5 && listWindowIndexChord + 1 < ceil(length(listChordValues)/length(listButtons))
                    listWindowIndexChord = listWindowIndexChord + 1;
                    ForceRedrawListButtons(false);
                elseif state == 6 && listWindowIndexLoop + 1 < ceil(length(listLoopValues)/length(listButtons))
                    listWindowIndexLoop = listWindowIndexLoop + 1;
                    ForceRedrawListButtons(false);
                end
            end

            if listWindowDButton.WasReleased()
                DrawArrowText(listWindowDButton)
            end
        end

        %Keyboard input

        if state == 1 || state == 2 || state == 3

            for ik=1:length(buttons)
    
                if buttons(ik).WasPressed()

                    %recording key down
                    if recording
                        
                        if isempty(newRecording) %if first key of loop
                            if isempty(durations) %if first loop
                                masterTimer = tic;
                            else %add padding if not first loop
                                frontPadding = toc(masterTimer) - durations(1)*loopCount(1);
                            end
                            recordingTimer = tic; %we set the loop start as when the first key is pressed
                        end

                        if state == 2  %chords
                            for ic=1:length(chordNotes{ik})
                                newRecording = [newRecording ; [(toc(recordingTimer)+frontPadding), chordNotes{ik}(ic)]];
                            end
                        elseif state == 3 %drums
                            newRecording = [newRecording ; [(toc(recordingTimer)+frontPadding), notes(ik)+1000]];
                        else %keys
                            newRecording = [newRecording ; [(toc(recordingTimer)+frontPadding), notes(ik)]];
                        end
                        
                    end
    
                    if state == 2
                        for ic=1:length(chordNotes{ik})
                            synth.setNoteOn(channel, chordNotes{ik}(ic), 100)
                        end
                    else
                        synth.setNoteOn(channel, notes(ik), 100);
                    end

                    if state == 1
                        RedrawLines(ik);
                    end

    
                elseif buttons(ik).WasReleased()

                    %recording key up
                    if recording
                        if state == 2
                            for ic=1:length(chordNotes{ik})
                                newRecording = [newRecording ; [(toc(recordingTimer)+frontPadding), -chordNotes{ik}(ic)]];
                            end
                        elseif state == 3
                            newRecording = [newRecording ; [(toc(recordingTimer)+frontPadding), -notes(ik)-1000]];
                        else
                            newRecording = [newRecording ; [(toc(recordingTimer)+frontPadding), -notes(ik)]];
                        end

                        newDuration = toc(recordingTimer);
                    end
    
                    if state == 2
                        for ic=1:length(chordNotes{ik})
                            synth.setNoteOff(channel, chordNotes{ik}(ic), 100)
                        end
                    else
                        synth.setNoteOff(channel, notes(ik), 0);
                    end

                    if state == 1
                        RedrawLines(ik);
                    end
    
                end
            end
        
        
        %Keyboard input repeater
        elseif state == 7

            for ik=1:length(buttons)
    
                if buttons(ik).WasPressed()

                    repeat = true;
                    repeaterTic = tic;
                    repeaterNote = notes(ik);

                    %recording key down
                    if recording
                        
                        if isempty(newRecording) %if first key of loop
                            if isempty(durations) %if first loop
                                masterTimer = tic;
                            else %add padding if not first loop
                                frontPadding = toc(masterTimer) - durations(1)*loopCount(1);
                            end
                            recordingTimer = tic; %we set the loop start as when the first key is pressed
                        end
                        
                    end

                elseif buttons(ik).WasReleased()

                    repeat = false;
                    playingRepeaterNote = false;

                    %recording key up
                    if recording
                        newRecording = [newRecording ; [(toc(recordingTimer)+frontPadding), -notes(ik)-1000]];
                        newDuration = toc(recordingTimer);
                    end

                    synth.setNoteOff(channel, notes(ik), 0);
    
                end

                if repeat
                    Repeater(channel);
                end

            end

        end

        %loop playback

        for ip=1:length(durations) %loops through recordings

            r = recordings{ip};

            while iterators(ip) <= height(r) %if there are notes to be played at key = timer(i), play all of them
                if (toc(masterTimer) - loopCount(ip)*durations(ip)) >= r(iterators(ip), 1)

                    if listLoopValues(ip) %"mutes" the loop

                        if r(iterators(ip), 2) > 0
                            if r(iterators(ip), 2) > 1000
                                synth.setNoteOn(9, r(iterators(ip), 2)-1000, 100); %play the note on the drum channel
                            else
                                synth.setNoteOn(ip, r(iterators(ip), 2), 100); %play the recorded notes
                            end
                        else
                            if r(iterators(ip), 2) < -1000
                                synth.setNoteOff(ip, -r(iterators(ip), 2)-1000, 0);
                            else
                                synth.setNoteOff(ip, -r(iterators(ip), 2), 0); %negative since we declared negative note as off
                            end
                        end
                    
                    elseif ~setAllLoopNotesOff(ip) %"mutes" the loop
                        for alo=1:size(r, 1)
                            if r(alo, 2) < 0
                                if r(alo, 2) < -1000
                                    synth.setNoteOff(ip, -r(alo, 2)-1000, 0);
                                else
                                    synth.setNoteOff(ip, -r(alo, 2), 0); %negative since we declared negative note as off
                                end
                            end
                            
                        end

                        setAllLoopNotesOff(ip) = 1;
                    end

                else
                    break; %otherwise it gets stuck here
                end

                iterators(ip) = iterators(ip) + 1;
   
            end

            if toc(masterTimer) - loopCount(ip)*durations(ip) > durations(ip)  %can't use mod here
                iterators(ip) = 1;
                loopCount(ip) = loopCount(ip) + 1;
                if ip==1
                    disp("new loop")
                end
            end
 
        end

        %Check Exit Button
        if exitButton.WasPressed()
            stop = true;
        end

    end

    function Record(rec)
        if rec
            %reset variables
            newRecording = [];
            
            %disable outer ui
            DisableTabs();

        elseif ~rec

            %if newRecording is empty don't add, limited channels as it is
            if ~isempty(newRecording)

                if isempty(recordings) %if its the first loop
                    newDuration = toc(recordingTimer);
                    %newDuration = round(newDuration, 1, TieBreaker="plusinf");

                    % %if you SOMEHOW press the recording button within 0.1s after the last release
                    % if newRecording(length(newRecording), 1) > newDuration
                    %     newRecording(length(newRecording), 1) = newDuration;
                    % end

                    timeBetweenRepeaterNotes = newDuration/repeaterNotesPerLoop;
                    repeaterNoteDuration = 0.3*timeBetweenRepeaterNotes;

                else
                    newDuration = newDuration+frontPadding;
                end
                
                %add back padding
                if ~isempty(durations)
                    n = 0;
                    while newDuration > durations(1) * (2^n)
                        n = n+1;
                    end

                    newDuration = (2^n)*durations(1); %minimum amount of dur(1)'s to make up dur(new)
                end

                newIterator = 1;
                newLoopCount = floor(toc(masterTimer)/newDuration);

                % "play" keys that master timer has already gone past
                  
                for i=1:length(newRecording)
                    if toc(masterTimer) - newLoopCount*newDuration > newRecording(i, 1)
                        newIterator = newIterator + 1;
                    end
                end

                iterators = [iterators newIterator];
                loopCount = [loopCount newLoopCount];
                durations = [durations newDuration];
                recordings{end+1} = newRecording;

                if inst ~= defaultInst
                    synth.setInstrument(0, length(durations), inst)
                end

                %Add loop to loop list
                listLoopValues = [listLoopValues 1];
                listLoopStrings = [listLoopStrings sprintf("Loop %d", length(listLoopValues))];
                setAllLoopNotesOff = [setAllLoopNotesOff 0];

                disp(newDuration)
                
                %Draw disabled if loop limit reached
                if length(durations) == loopLimit
                    DrawDisabled(recordButton, true);
                end

                %as long as we set the note and instrument properly,
                %everything will work
            end
            
            %undisable outer ui
            if keyStateButton.GetDisabled()
                UndisableTabs();
            end
        end
    end

    function UpdateButtons()
        tX = m5u.touchGetX();
        tY = m5u.touchGetY();

        %Outer Buttons
        recordButton.UpdateButtonState(tX,tY);
        keyStateButton.UpdateButtonState(tX,tY);
        chordStateButton.UpdateButtonState(tX,tY);
        drumStateButton.UpdateButtonState(tX,tY);

        switch state
            case 1
                for i=1:length(keyButtons)
                    keyButtons(i).UpdateButtonState(tX, tY);
                end
            case 2
                for i=1:length(chordButtons)
                    chordButtons(i).UpdateButtonState(tX, tY);
                end
                pUButton.UpdateButtonState(tX,tY);
                pDButton.UpdateButtonState(tX,tY);
                
            case {3, 7}
                for i=1:length(drumButtons)
                    drumButtons(i).UpdateButtonState(tX, tY);
                end
                pUButton.UpdateButtonState(tX,tY);
                pDButton.UpdateButtonState(tX,tY);

            otherwise

                pUButton.UpdateButtonState(tX,tY);
                pDButton.UpdateButtonState(tX,tY);

                listWindowUButton.UpdateButtonState(tX, tY);
                listWindowDButton.UpdateButtonState(tX, tY);
                
                for i=1:length(listButtons)
                    listButtons(i).UpdateButtonState(tX, tY);
                end
        end

        %Exit button
        exitButton.UpdateButtonState(tX, tY);

        resetButtons = false;
    end

    function ResetButtons()

        keyStateButton.UpdateButtonState(-1, -1);
        chordStateButton.UpdateButtonState(-1, -1);
        drumStateButton.UpdateButtonState(-1, -1);
        pUButton.UpdateButtonState(-1, -1);
        pDButton.UpdateButtonState(-1, -1);
        recordButton.UpdateButtonState(-1, -1);

        switch state
            case 1
                for i=1:length(keyButtons)
                    keyButtons(i).UpdateButtonState(-1, -1);
                end
            case 2
                for i=1:length(chordButtons)
                    chordButtons(i).UpdateButtonState(-1, -1);
                end
            case {3, 7}
                for i=1:length(drumButtons)
                    drumButtons(i).UpdateButtonState(-1, -1);
                end
            otherwise

                listWindowUButton.UpdateButtonState(-1, -1);
                listWindowDButton.UpdateButtonState(-1, -1);

                for i=1:length(listButtons)
                    listButtons(i).UpdateButtonState(-1, -1);
                end
        end

        resetButtons = true;
    end
    
    function DrawSelection(button) %since we have custom graphics for outer buttons

        switch button

            case recordButton
                if recording
                    m5u.lcdDrawFillRect(selectedBoxOffset, selectedBoxOffset, keyWidth-2*selectedBoxOffset, outerSpacing-2*selectedBoxOffset, 0xea4d); %Selection
                elseif state == 6
                    DrawSecondarySelection(recordButton);
                else
                    m5u.lcdDrawFillRect(borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole
                end

            case keyStateButton
                if state == 1
                    m5u.lcdDrawFillRect(keyWidth+selectedBoxOffset, selectedBoxOffset, keyWidth-2*selectedBoxOffset, outerSpacing-2*selectedBoxOffset, 0x2aaf); %Selection
                else
                    m5u.lcdDrawFillRect(keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole
                end

            case chordStateButton
                if state == 2
                    m5u.lcdDrawFillRect(2*keyWidth+selectedBoxOffset, selectedBoxOffset, keyWidth-2*selectedBoxOffset, outerSpacing-2*selectedBoxOffset, 0x0eb3); %Selection
                else
                    m5u.lcdDrawFillRect(2*keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole
                end

            case drumStateButton
                if state == 3
                    m5u.lcdDrawFillRect(3*keyWidth+selectedBoxOffset, selectedBoxOffset, keyWidth-2*selectedBoxOffset, outerSpacing-2*selectedBoxOffset, 0xfe8c); %Selection
                else
                    m5u.lcdDrawFillRect(3*keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole
                end

        end

    end

    function DrawArrowText(button)

        switch button %check color first, then draw the string
            case {pUButton, pDButton}
                if textColors(1) ~= pitchButtonColors(3)
                    textColors = [pitchButtonColors(3), pitchButtonColors(2)];
                    m5u.lcdTextColor(textColors(1), textColors(2))
                end
                switch button
                    case pUButton
                        m5u.lcdDrawStr(290, 100, "+")
                    case pDButton
                        m5u.lcdDrawStr(290, 185, "-")
                end

            case {listWindowUButton, listWindowDButton}
                switch state
                    case 4
                        if textColors(1) ~= keyTextColors(2)
                            textColors = [keyTextColors(2), keyTextColors(1)];
                            m5u.lcdTextColor(textColors(1), textColors(2));
                        end
                    case 5
                        if textColors(1) ~= chordTextColors(2)
                            textColors = [chordTextColors(2), chordTextColors(1)];
                            m5u.lcdTextColor(textColors(1), textColors(2));
                        end
                    case 6
                        if textColors(1) ~= loopTextColors(2)
                            textColors = [loopTextColors(2), loopTextColors(1)];
                            m5u.lcdTextColor(textColors(1), textColors(2))
                        end
                end
                switch button
                    case listWindowUButton
                        m5u.lcdDrawStr(235, 103, "^")
                    case listWindowDButton
                        m5u.lcdDrawStr(235, 183, "v")
                end
                
        end

    end

    function RedrawLines(keyIndex)
        if keyIndex == -1
            for i=1:6
                if i == 3
                    m5u.lcdDrawLine(3*keyboardKeyWidth, sH, 3*keyboardKeyWidth, outerSpacing, m5u.lcdColor.BLACK);
                else
                    m5u.lcdDrawLine(i*keyboardKeyWidth, sH, i*keyboardKeyWidth, outerSpacing+keyboardKeyHeight, m5u.lcdColor.BLACK);
                end
            end
        else
            leftLine = keyIndex-1;
            rightLine = keyIndex;
    
            if leftLine >= 1
                if leftLine == 3
                    m5u.lcdDrawLine(3*keyboardKeyWidth, sH, 3*keyboardKeyWidth, outerSpacing, m5u.lcdColor.BLACK);
                else
                    m5u.lcdDrawLine(leftLine*keyboardKeyWidth, sH, leftLine*keyboardKeyWidth, outerSpacing+keyboardKeyHeight, m5u.lcdColor.BLACK);
                end
            end
    
            if rightLine < 7
                if rightLine == 3
                    m5u.lcdDrawLine(3*keyboardKeyWidth, sH, 3*keyboardKeyWidth, outerSpacing, m5u.lcdColor.BLACK);
                else
                    m5u.lcdDrawLine(rightLine*keyboardKeyWidth, sH, rightLine*keyboardKeyWidth, outerSpacing+keyboardKeyHeight, m5u.lcdColor.BLACK);
                end
            end
        end
        
    end

    function ForceRedraw()
        DrawSelection(keyStateButton);
        DrawSelection(chordStateButton);
        DrawSelection(drumStateButton);
        
        switch state
            case 1
                for i=1:length(keyButtons)
                    keyButtons(i).ForceRedraw();
                end
                RedrawLines(-1);
            case 2
                for i=1:length(chordButtons)
                    chordButtons(i).ForceRedraw();
                end
            case 3
                changeColor = false;
                if drumButtons(1).GetOffColor ~= offBlackColors(3)
                    changeColor = true;
                end
                for i=1:length(drumButtons)
                    if changeColor
                        if i == 1
                            drumButtons(i).SetOffColor(offBlackColors(3));
                        elseif i == 3
                            drumButtons(i).SetOffColor(offWhiteColors(3));
                        end
                    end
                    drumButtons(i).ForceRedraw();
                end
            case 7
                for i=1:length(drumButtons)
                    if i > 2
                        drumButtons(i).SetOffColor(offBlackColors(3));
                    else
                        drumButtons(i).SetOffColor(offWhiteColors(3));
                    end
                    drumButtons(i).ForceRedraw();
                end
        end
    end

    function DrawDisabled(button, disabled)

        if disabled
            color = disabledColors;
        else
            color = offBlackColors;
        end

        switch button 
            case keyStateButton

                m5u.lcdDrawFillRect(keyWidth, 0, keyWidth, outerSpacing, color(1)); %Border
                m5u.lcdDrawFillRect(keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole

                if state == 1
                    m5u.lcdDrawFillRect(keyWidth+selectedBoxOffset, selectedBoxOffset, keyWidth-2*selectedBoxOffset, outerSpacing-2*selectedBoxOffset, color(1)); %Selection
                end

            case chordStateButton

                m5u.lcdDrawFillRect(2*keyWidth, 0, keyWidth, outerSpacing, color(2)); %Border
                m5u.lcdDrawFillRect(2*keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole

                if state == 2
                      m5u.lcdDrawFillRect(2*keyWidth+selectedBoxOffset, selectedBoxOffset, keyWidth-2*selectedBoxOffset, outerSpacing-2*selectedBoxOffset, color(2)); %Selection
                end

            case drumStateButton

                m5u.lcdDrawFillRect(3*keyWidth, 0, keyWidth, outerSpacing, color(3)); %Border
                m5u.lcdDrawFillRect(3*keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole

                if state == 3
                    m5u.lcdDrawFillRect(3*keyWidth+selectedBoxOffset, selectedBoxOffset, keyWidth-2*selectedBoxOffset, outerSpacing-2*selectedBoxOffset, color(3)); %Selection
                elseif state == 7
                    selectedBoxInstOffset = 20;
                    m5u.lcdDrawFillRect(3*keyWidth+selectedBoxInstOffset, selectedBoxInstOffset, keyWidth-2*selectedBoxInstOffset, outerSpacing-2*selectedBoxInstOffset, color(3)); %Selection
                end

            case recordButton
                m5u.lcdDrawFillRect(0, 0, keyWidth, outerSpacing, color(4)); %Border
                m5u.lcdDrawFillRect(borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole
        end

    end

    function DrawSecondarySelection(button)

        selectedBoxInstOffset = 20;

        switch button
            case keyStateButton
                m5u.lcdDrawFillRect(keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole
                m5u.lcdDrawFillRect(keyWidth+selectedBoxInstOffset, selectedBoxInstOffset, keyWidth-2*selectedBoxInstOffset, outerSpacing-2*selectedBoxInstOffset, 0x2aaf); %Secondary Selection
             
            case chordStateButton
                m5u.lcdDrawFillRect(2*keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole
                m5u.lcdDrawFillRect(2*keyWidth+selectedBoxInstOffset, selectedBoxInstOffset, keyWidth-2*selectedBoxInstOffset, outerSpacing-2*selectedBoxInstOffset, 0x0eb3); %Selection

            case drumStateButton
                m5u.lcdDrawFillRect(3*keyWidth+borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole
                m5u.lcdDrawFillRect(3*keyWidth+selectedBoxInstOffset, selectedBoxInstOffset, keyWidth-2*selectedBoxInstOffset, outerSpacing-2*selectedBoxInstOffset, 0xfe8c); %Selection
            
            case recordButton
                m5u.lcdDrawFillRect(borderThickness, borderThickness, keyWidth-2*borderThickness, outerSpacing-2*borderThickness, 0); %Hole
                m5u.lcdDrawFillRect(selectedBoxInstOffset, selectedBoxInstOffset, keyWidth-2*selectedBoxInstOffset, outerSpacing-2*selectedBoxInstOffset, offBlackColors(4)); %Selection
        end
    end

    function ForceRedrawListButtons(changedState)

        values = [];
        index = 0;
        textColor = 0;
        selectedTextColor = 0;

        %update the list strings
        UpdateListStrings();

        switch state
            case 4
                values = listKeyValues;
                index = listWindowIndexKey;
                textColor = keyTextColors;
                selectedTextColor = keySelectedTextColors;
            case 5
                values = listChordValues;
                index = listWindowIndexChord;
                textColor = chordTextColors;
                selectedTextColor = chordSelectedTextColors;
            case 6
                values = listLoopValues;
                index = listWindowIndexLoop;
                textColor = loopTextColors;
                selectedTextColor = loopSelectedTextColors;
        end

        %only change window up down button colors if state has changed

        if changedState
            switch state
                case {4, 5}
                    listWindowUButton.SetOutlineColor(outlineColors(state-3));
                    listWindowUButton.SetOffColor(offWhiteColors(state-3));
                    listWindowUButton.SetOnColor(onColors(state-3));
                    listWindowUButton.ForceRedraw();
                    listWindowDButton.SetOutlineColor(outlineColors(state-3));
                    listWindowDButton.SetOffColor(offWhiteColors(state-3));
                    listWindowDButton.SetOnColor(onColors(state-3));
                    listWindowDButton.ForceRedraw();
                case 6
                    listWindowUButton.SetOutlineColor(outlineColors(4));
                    listWindowUButton.SetOffColor(offWhiteColors(4));
                    listWindowUButton.SetOnColor(onColors(4));
                    listWindowUButton.ForceRedraw();
                    listWindowDButton.SetOutlineColor(outlineColors(4));
                    listWindowDButton.SetOffColor(offWhiteColors(4));
                    listWindowDButton.SetOnColor(onColors(4));
                    listWindowDButton.ForceRedraw();
            end
        end

        %Make sure colors are correct first

        for i=1:length(listButtons)

            iniOutlineColor = listButtons(i).GetOutlineColor();
            iniOffColor = listButtons(i).GetOffColor();
            
            switch state
                case {4, 5}
                    if strcmp(iniOutlineColor, "no")
                        listButtons(i).SetOutlineColor(outlineColors(state-3));
                    elseif iniOutlineColor ~= outlineColors(state-3)
                        listButtons(i).SetOutlineColor(outlineColors(state-3));
                    end
        
                    if index*4+i <= length(values)
                        if values(index*4+i) %if its 1 then we set it to offWhiteColor
                            listButtons(i).SetOffColor(offWhiteColors(state-3))
                        else
                            listButtons(i).SetOffColor(offBlackColors(state-3))
                        end
                    else
                        listButtons(i).SetOffColor(disabledColors(state-3))
                    end
                
                case 6
                    if strcmp(iniOutlineColor, "no")
                        listButtons(i).SetOutlineColor(outlineColors(4));
                    elseif iniOutlineColor ~= outlineColors(4)
                        listButtons(i).SetOutlineColor(outlineColors(4));
                    end
        
                    if index*4+i <= length(values)
                        if values(index*4+i) %if its 1 then we set it to offWhiteColor
                            listButtons(i).SetOffColor(offWhiteColors(4))
                        else
                            listButtons(i).SetOffColor(offBlackColors(4))
                        end
                    else
                        listButtons(i).SetOffColor(disabledColors(4))
                    end
            end

            %Redraw if either outline or off color is not the same as before

            if strcmp(iniOutlineColor, "no") || strcmp(iniOffColor, "no") || changedState
                listButtons(i).ForceRedraw();
            elseif iniOutlineColor ~= listButtons(i).GetOutlineColor() || iniOffColor ~= listButtons(i).GetOffColor()
                listButtons(i).ForceRedraw();
            end

        end

        %Redraw the text

        for i=1:length(listButtons)

            %determine if its a selected button
            colorScheme=textColor;
            
            if index*4+i <= length(values)
                if values(index*4+i)
                    colorScheme = selectedTextColor;
                end
    
                if textColors(1) ~= colorScheme(1)
                    textColors = colorScheme;
                    m5u.lcdTextColor(textColors(1), textColors(2));
                end
                
                m5u.lcdDrawStr(listWindowTextXPos, listWindowTextYPoss(i), listWindowText(i));
            end
        end

    end

    function ForceRedrawPitchButtons()
        pUButton.ForceRedraw()
        pDButton.ForceRedraw()
        DrawArrowText(pDButton)
        DrawArrowText(pUButton)

    end

    function SetInitialListIndex()
        %for the keys and chords we can start the window to where ever the current instrument is
        %for the loops we can always start at the start

        switch state
            case 4
                listWindowIndexKey = floor((find(listKeyValues, 1)-1)/4);
            case 5
                listWindowIndexChord = floor((find(listChordValues, 1)-1)/4);
            case 6
                listWindowIndexLoop = 0;
        end
    end

    function UpdateListStrings()
        index = 0;
        strings = [];

        switch state
            case 4
                index = listWindowIndexKey;
                strings = instruments;
            case 5
                index = listWindowIndexChord;
                strings = instruments;
            case 6
                index = listWindowIndexLoop;
                strings = listLoopStrings;
        end

        listWindowText = [];
        lastIndex = min(length(strings) - index*4, 4);

        for i=1:lastIndex
            listWindowText = [listWindowText strings(index*4+i)];
        end
    end

    function DisableTabs()
        keyStateButton.DisableButton();
        chordStateButton.DisableButton();
        drumStateButton.DisableButton();

        DrawDisabled(keyStateButton, true)
        DrawDisabled(chordStateButton, true)
        DrawDisabled(drumStateButton, true)
    end

    function UndisableTabs()
        keyStateButton.UndisableButton();
        chordStateButton.UndisableButton();
        drumStateButton.UndisableButton();

        DrawDisabled(keyStateButton, false);
        DrawDisabled(chordStateButton, false);
        DrawDisabled(drumStateButton, false);
    end

    function ChangePitch(pitchUp)

        if textColors(1) ~= defaultTextColors(1)
            textColors = defaultTextColors;
            m5u.lcdTextColor(textColors(1), textColors(2))
        end
        
        if pitchUp
            pitchChange = 12;
        else
            pitchChange = -12;
        end

        if pitch >= 0
            m5u.lcdDrawStr(280, 20, sprintf("+%d", pitch));
        else
            m5u.lcdDrawStr(280, 20, sprintf("%d", pitch));
        end

        keyNotes = keyNotes + pitchChange;
        for i=1:length(chordNotes)
            chordNotes{i} = chordNotes{i} + pitchChange;
        end

        if state == 1
            notes = keyNotes;
        elseif state == 2
            notes = chordNotes;
        end

    end

    function Repeater(channel)

        if playingRepeaterNote
            if toc(repeaterTic) > repeaterNoteDuration
                playingRepeaterNote = false;
                newRecording = [newRecording ; [(toc(recordingTimer)+frontPadding), -repeaterNote-1000]];
                synth.setNoteOff(channel, repeaterNote, 0)
                repeaterTic = tic;
            end
        else
            if toc(repeaterTic) > timeBetweenRepeaterNotes
                playingRepeaterNote = true;
                newRecording = [newRecording ; [(toc(recordingTimer)+frontPadding), repeaterNote+1000]];
                synth.setNoteOn(channel, repeaterNote, 100)
                repeaterTic = tic;
            end
        end
    end

end

m5u.lcdClear();
synth.reset();
