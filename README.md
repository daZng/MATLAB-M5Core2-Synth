### **_Description_**

This project demos the capabilities of the MATLAB M5Unified and M5UnitSynth Add-On Libraries using the M5Core2 and M5 Unit Synth.

It implements a full synthesizer controlled entirely through the M5Core2 touchscreen supporting:

- Instrument key playback

- Chords

- Drum pads

- Up to 12 selectable instruments

- Up to 7 concurrent recording loops

- Real-time pitch adjustment

- Drum arpeggiation mode

### **_Setup Instructions_**

**MATLAB**

Install MATLAB Support Package for Arduino Hardware

Install M5Unified Add-On Library

Install M5UnitSynth Add-On Library

Run SynthMain.m

Ensure Button.m and Button2.m (helper classes) are in the same folder as SynthMain.m

### **_How to Use_**

**Tabs**

Blue Tab — Instrument keys

Green Tab — Instrument chords

Yellow Tab — Drums

### **_Instrument Selection_**

Press the Blue or Green tab again to open the instrument selector

Use the inner vertical buttons to scroll through available instruments

### **_Pitch Adjustment_**

Use the outer vertical buttons to increase or decrease pitch

### **_Recording Loops_**

Press the Red Tab to begin recording.

First loop:
Recording starts on the first note press and stops when you press the record button again.

Subsequent loops:
Recording starts on the first note press and stops when you release the last note.

Supports up to 7 simultaneous loops.

### **_Drum Arpeggiation_**

Press the Yellow (Drum) Tab again to activate drum arpeggiation mode.
This triggers drum notes automatically at 55 notes per loop duration.

### **_Stopping the Program_**

Press any of the hardware buttons M5 A, B, or C.
