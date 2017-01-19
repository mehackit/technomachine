/*   The Sonic Pi Techno Machine - By Mehackit                                          *
 *   If you have any questions / feedback about it, please contact tommi@mehackit.org   */

import oscP5.*;                   // Please install OscP5 and ControlP5 libraries from
import netP5.*;                   // the menu Sketch / Import Library / Add Library... 
import controlP5.*;

OscP5 oscP5;                      // OscP5 handles OSC communication from Processing to Sonic Pi
NetAddress sonicPi;               // NetAddress is created for OscP5 to 
ControlP5 cp5;                    // ControlP5 is used to create the user interface for this sketch

boolean enableComms = true;       // This boolean enables the OSC communication from this patch
boolean enable3DLogo = true;      // Boolean toggle to enable / disable spinning Mehackit 3D logo
boolean enableLineGFX = true;     // Boolean toggle to enable / disable transparent moving lines animation
boolean debugMessages = false;    // If enabled, prints outgoing OSC messages to terminal

float transparency = 0.25;            // These variables are used to modulate some of the 
float transparencyModifier = 0.25;    // graphics effects in this patch
float ry, sinX, sinY1, sinY2, sinY3;  
static final int NUM_OF_LINES = 7;
float[] sinY = new float[NUM_OF_LINES];
float[] sinYRates = new float[NUM_OF_LINES];
                                                           
PShape logo;                        // Variable for the 3D shape of Mehackit logo
PFont pfont1, pfont2;               // Variables for the custom fonts used in the UI

Toggle a,s,d,f,x;                   // Variables for the Drum Toggle buttons and Low Freq Kill Switch
RadioButton p;                      // Radio button bar for selecting patterns

void setup() {
  
  size(795,600, P3D);
  smooth();    
  
  oscP5 = new OscP5(this, 8000);                  // Initializing this processing to listen to OSC messages
  sonicPi = new NetAddress("127.0.0.1",4559);     // and send them locally to Sonic Pi using port 4559 
  
  logo = loadShape("data/mehackit.obj");          // Loads the 3D Mehackit logo shape
  logo.disableStyle();
  logo.setFill(color(255,255,255,0));
  logo.setStroke(color(255));
  
  pfont1 = createFont("nasalization",12,true);    // Creates custom fonts for "Nasalization"
  pfont2 = createFont("nasalization",16,true);
  textFont(pfont1);
  
  setupUIElements();                              // setupUIElements creates the UI
  enableComms = true;
  for (int i = 0; i < NUM_OF_LINES; i ++) {
    sinYRates[i] = random(0.02, 0.09);
  }
}

void draw() {
  background(30);
  drawBackgroundLines(); 
  drawDynamicElements(); 
}

// This method draws the background "line grid" for the UI 
void drawBackgroundLines() {
  fill(0);
  rect(390,0,width, 174);
  rect(390,438,width, height);
  
  stroke(255);
  line(390,0,390,height);
  line(390,174,width,174);
  line(390,438,width,438);
  line(0,410,390,410);
  line(0,540,390,540);
  line(595,438,595,height);
  line(595,height-25,width,height-25);
  
  stroke(255,120);
  line(127,340,97,310);
  line(97,310,102,310);
  line(97,310,97,315);
  
  line(167,340,197,310);
  line(197,310,197,315);
  line(197,310,192,310); 
}

// This method draws the super fancy dynamic graphic elements (including the 3D logo)
void drawDynamicElements() {
  fill(255);
  float alpha = 255;
  if (enableLineGFX) { 
    float lineY;
    for (int i = 0; i < NUM_OF_LINES; i ++) {
      alpha = map(sin(sinY[i]),-1,1,40,255); 
      fill(255,255,255,alpha);
      stroke(255,255,255,alpha);
      lineY = (height-30) + sin(sinY[i])*30;
      line(0, lineY, 390, lineY);
      sinY[i] += sinYRates[i];
    }
  }
  if (enable3DLogo) {
    pushMatrix();
    translate(width/4, height-52, 40);
    rotateZ(PI);
    rotateY(ry);
    rotateY(PI);
    scale(0.2);
    shape(logo);
    popMatrix();
    ry += 0.02;
  } else {
    text("MEHACKIT", width/4-50, height-26);
  }
  text("THE SONIC PI", width/4 - 165, height-26);
  text("TECHNO MACHINE", width/4 + 50, height-26);
  text("THX TO SAM AARON!", 627, height-8);  
}

/* This function checks the key presses that act as Drum Toggle shortcuts */
void keyPressed() {
  Toggle t = null;
  if (key == 'A' || key == 'a') {
    t = a;
  } else if (key == 'S' || key == 's') {
    t = s;
  } else if (key == 'D' || key == 'd') {
    t = d;
  } else if (key == 'F' || key == 'f') {
    t = f;
  } else if (key == 'X' || key == 'x') {
    t = x;
  } else if (key == '1') {
    p.activate(0);
    sendOscMessage("pattern", 0);
  } else if (key == '2') {
    p.activate(1);
    sendOscMessage("pattern", 1);
  } else if (key == '3') {
    p.activate(2);
    sendOscMessage("pattern", 2);
  } else if (key == '4') {
    p.activate(3);
    sendOscMessage("pattern", 3);
  } else if (key == 'R' || key == 'r') {
    randomizer();
  }
  
  if (t != null && t.getValue() == 1.0) {
    t.setValue(false);
  } else if (t != null) {
    t.setValue(true);
  }
}

void setupUIElements() {
  // Define fonts for the ControlP5 UI interface
  ControlFont font1 = new ControlFont(pfont1);
  ControlFont font2 = new ControlFont(pfont2);

  // Initialize a new ControlP5 interface and set colors and fonts for it
  cp5 = new ControlP5(this);
  cp5.setColorBackground(color(205,172,216, 180));
  cp5.setColorActive(color(255,63,140, 255));
  cp5.setColorForeground(color(255,23,140,160));
  cp5.setFont(font1);
    
  // Create Toggle buttons
  a = cp5.addToggle("beatA").setValue(0).setPosition(10,30).setSize(91,91).setLabel("Perc (A)").align(CENTER,CENTER,CENTER,CENTER);
  s = cp5.addToggle("beatB").setValue(0).setPosition(102,30).setSize(91,91).setLabel("Kick (S)").align(CENTER,CENTER,CENTER,CENTER);
  d = cp5.addToggle("beatC").setValue(0).setPosition(194,30).setSize(91,91).setLabel("Hihats (D)").align(CENTER,CENTER,CENTER,CENTER);
  f = cp5.addToggle("beatD").setValue(0).setPosition(286,30).setSize(91,91).setLabel("FM Bass (F)").align(CENTER,CENTER,CENTER,CENTER);
  x = cp5.addToggle("lowKill").setValue(0).setPosition(30,340).setSize(41,41).setLabel("X").align(CENTER,CENTER,CENTER,CENTER);
  
  // Create Knobs
  cp5.addKnob("drum1Volume").setRange(0,2.0).setValue(1.0).setPosition(30,135).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Vol").setDecimalPrecision(1);
  cp5.addKnob("drum2Volume").setRange(0,2.0).setValue(1.0).setPosition(127,135).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Vol").setDecimalPrecision(1);
  cp5.addKnob("drum3Volume").setRange(0,2.0).setValue(1.0).setPosition(219,135).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Vol").setDecimalPrecision(1);
  cp5.addKnob("drum4Volume").setRange(0,1.0).setValue(1.0).setPosition(306,135).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Vol").setDecimalPrecision(1);
  cp5.addKnob("drum2Decay").setRange(0,1.0).setValue(1.0).setPosition(127,200).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Decay").setDecimalPrecision(1);
  cp5.addKnob("drum3Decay").setRange(0,0.9).setValue(0.1).setPosition(219,200).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Decay").setDecimalPrecision(1);
  cp5.addKnob("drum4Decay").setRange(0,1.5).setValue(0.2).setPosition(306,200).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Decay").setDecimalPrecision(1);
  cp5.addKnob("drum2Pitch").setRange(0.5,1.5).setValue(1.0).setPosition(127,265).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Pitch").setDecimalPrecision(1);
  cp5.addKnob("drum3Pitch").setRange(0.5,1.5).setValue(1.0).setPosition(219,265).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Pitch").setDecimalPrecision(1);
  cp5.addKnob("drumReverb").setRange(0.0,0.9).setValue(0.0).setPosition(127,340).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Drum Reverb").setDecimalPrecision(1);
  cp5.addKnob("synth1Cutoff").setRange(0,129).setValue(50).setPosition(400,30).setRadius(40).setDragDirection(Knob.HORIZONTAL).setLabel("Cutoff");
  cp5.addKnob("synth1Resonance").setRange(0,0.95).setValue(0.5).setPosition(500,30).setRadius(40).setDragDirection(Knob.HORIZONTAL).setLabel("Resonance").setDecimalPrecision(2);
  cp5.addKnob("synth1Attack").setRange(0,0.25).setValue(0).setPosition(600,30).setRadius(40).setDragDirection(Knob.HORIZONTAL).setLabel("Attack").setDecimalPrecision(2);
  cp5.addKnob("synth1Release").setRange(0,1.0).setValue(0.25).setPosition(700,30).setRadius(40).setDragDirection(Knob.HORIZONTAL).setLabel("Release").setDecimalPrecision(2);
  cp5.addKnob("synthReverb").setRange(0,0.95).setValue(0.5).setPosition(400,470).setRadius(40).setDragDirection(Knob.HORIZONTAL).setLabel("Reverb").setDecimalPrecision(2);
  cp5.addKnob("synthDistortion").setRange(0,0.95).setValue(0.2).setPosition(500,470).setRadius(40).setDragDirection(Knob.HORIZONTAL).setLabel("Distortion").setDecimalPrecision(2);
  cp5.addKnob("synth2Volume").setRange(0,1.0).setValue(0).setPosition(620,510).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Osc 2 Vol").setDecimalPrecision(1);
  cp5.addKnob("synth2Transpose").setRange(0,12).setValue(0).setPosition(720,510).setRadius(20).setDragDirection(Knob.HORIZONTAL).setLabel("Transpose");
  
  // Button bars / grids
     
  cp5.addRadioButton("setDrumKit").setPosition(220, 340).setItemsPerRow(2).setItemWidth(78).setItemHeight(20)
  .addItem("Kit 1", 0).addItem("Kit 2", 1).addItem("Kit 3", 2).addItem("Kit 4", 3).align(CENTER,CENTER)
  .activate(0).setNoneSelectedAllowed(false);  
  
  cp5.addRadioButton("setSynth1OSC").setPosition(450, 145).setItemsPerRow(4).setItemWidth(82).setItemHeight(20)
  .addItem(":tb303", 0).addItem(":saw ", 1).addItem(":pulse", 2).addItem(":mod_saw", 3)
  .align(CENTER,CENTER).activate(0).setNoneSelectedAllowed(false);              
              
  cp5.addRadioButton("setSynth2OSC").setPosition(605, 470).setItemsPerRow(3).setItemWidth(57)
  .setItemHeight(20).addItem(":saw", 0).addItem(":pluck", 1).addItem(":bell", 2).align(CENTER,CENTER)
  .activate(0).setNoneSelectedAllowed(false);

  p = cp5.addRadioButton("setDrumPattern").setPosition(10, 440).setItemsPerRow(4).setItemWidth(92)
  .setItemHeight(90).addItem("1", 0).addItem("2", 1).addItem("3", 2).addItem("4", 3)
  .setColorBackground(color(205,172,216,80)).setFont(font2).align(CENTER,CENTER)
  .activate(0).setNoneSelectedAllowed(false);
  
  // Randomizer Button     
  cp5.addButton("randomizer").setPosition(650,180).setSize(130,20).setLabel("Randomize (R)");
  
  // Note Sequencer Sliders
  cp5.addSlider("note1Slider").setPosition(400,210).setSize(20,200).setRange(0,90).setValue(0).setLabel(" 1");
  cp5.addSlider("note2Slider").setPosition(450,210).setSize(20,200).setRange(0,90).setValue(0).setLabel(" 2");
  cp5.addSlider("note3Slider").setPosition(500,210).setSize(20,200).setRange(0,90).setValue(0).setLabel(" 3");
  cp5.addSlider("note4Slider").setPosition(550,210).setSize(20,200).setRange(0,90).setValue(0).setLabel(" 4");
  cp5.addSlider("note5Slider").setPosition(600,210).setSize(20,200).setRange(0,90).setValue(0).setLabel(" 5");
  cp5.addSlider("note6Slider").setPosition(650,210).setSize(20,200).setRange(0,90).setValue(0).setLabel(" 6");
  cp5.addSlider("note7Slider").setPosition(700,210).setSize(20,200).setRange(0,90).setValue(0).setLabel(" 7");
  cp5.addSlider("note8Slider").setPosition(750,210).setSize(20,200).setRange(0,90).setValue(0).setLabel(" 8");

  // Various text labels for the UI
  cp5.addTextlabel("label1").setText("DRUM TOGGLES").setPosition(5,5).setFont(font2);
  cp5.addTextlabel("label2a").setText("SYNTH FILTER").setPosition(395,5).setFont(font2);
  cp5.addTextlabel("label2b").setText("AMP ENVELOPE").setPosition(600,5).setFont(font2);
  cp5.addTextlabel("label3").setText("OSC 1").setPosition(395,145).setFont(font2);  
  cp5.addTextlabel("label4").setText("SYNTH STEP SEQUENCER").setPosition(395,180).setFont(font2);
  cp5.addTextlabel("label5").setText("SYNTH FX").setPosition(395,445).setFont(font2);
  cp5.addTextlabel("label6").setText("OSC 2").setPosition(600,445).setFont(font2);
  cp5.addTextlabel("label7").setText("DRUM PATTERNS").setPosition(5,415).setFont(font2);
  cp5.addTextlabel("label8").setText("LOW KILL").setPosition(20,385).setFont(font1);
  cp5.addTextlabel("label9").setText("DRUM KIT SELECTOR").setPosition(216,385).setFont(font1);
      
}

// The following methods are called you use the buttons, sliders, etc. in the UI.
void setSynth1OSC(int value) {
  switch(value) {
    case 0:
      sendOscMessage("waveform1", 0);
      break;
    case 1:
      sendOscMessage("waveform1", 1);
      break;
    case 2:
      sendOscMessage("waveform1", 2);
      break;
    case 3:
      sendOscMessage("waveform1", 3);
      break;
  }
}
void setSynth2OSC(int value) {
  switch(value) {
    case 0:
      sendOscMessage("waveform2", 0);
      break;
    case 1:
      sendOscMessage("waveform2", 1);
      break;
    case 2:
      sendOscMessage("waveform2", 2);
      break;
  }
}
void setDrumPattern(int value) {
  switch(value) {
    case 0:
      sendOscMessage("pattern", 0);
      break;
    case 1:
      sendOscMessage("pattern", 1);
      break;
    case 2:
      sendOscMessage("pattern", 2);
      break;
    case 3:
      sendOscMessage("pattern", 3);
    break;
  }
}
void setDrumKit(int value) {
  switch(value) {
    case 0:
      sendOscDualMessage("drum2", 4, 0);
      break;
    case 1:
      sendOscDualMessage("drum2", 4, 1);
      break;
    case 2:
      sendOscDualMessage("drum2", 4, 2);
      break;
    case 3:
      sendOscDualMessage("drum2", 4, 3);
    break;
  }
}
void beatA(boolean state) {
  if (enableComms && state) {
    sendOscDualMessage("drum1", 0, 1); // Amen Toggle
  } else if (enableComms && !state) {
    sendOscDualMessage("drum1", 0, 0);    
  }
}
void beatB(boolean state) {
  if (enableComms && state) {
    sendOscDualMessage("drum2", 0, 1); // Kick Toggle
  } else if (enableComms && !state) {
    sendOscDualMessage("drum2", 0, 0);    
  }
}
void beatC(boolean state) {
  if (enableComms && state) {
    sendOscDualMessage("drum3", 0, 1); // Hihat Toggle
  } else if (enableComms && !state) {
    sendOscDualMessage("drum3", 0, 0);    
  }
}
void beatD(boolean state) {
  if (enableComms && state) {
    sendOscDualMessage("drum4", 0, 1); // Perc / FM Toggle
  } else if (enableComms && !state) {
    sendOscDualMessage("drum4", 0, 0);    
  }
}
void lowKill(boolean state) {
  if (enableComms && state) {
    sendOscMessage("lowkill", 1); // "Low Frequency Kill Switch" Toggle
  } else if (enableComms && !state) {
    sendOscMessage("lowkill", 0);    
  }
}
void synth1Cutoff(int theValue) {
  sendOscDualMessage("synth", 0, constrain(theValue,0,130)); // Cutoff
}
void synth1Resonance(float theValue) {
  sendOscDualMessage("synth", 1, constrain(theValue,0,0.99)); // Resonance
}
void synth1Attack(float theValue) {
  sendOscDualMessage("synth", 2, theValue); // Attack
}
void synth1Release(float theValue) {
  sendOscDualMessage("synth", 3, theValue); // Release
}
void synthReverb(float theValue) {
  sendOscDualMessage("synth", 4, theValue); // Reverb
}
void synthDistortion(float theValue) {
  sendOscDualMessage("synth", 5, theValue); // Distortion
}
void synth2Volume(float theValue) {
  sendOscDualMessage("synth", 6, theValue); // OSC2 Volume
}
void synth2Transpose(int theValue) {
  sendOscDualMessage("synth", 7, theValue); // OSC2, transpose
}
void drum1Volume(float theValue) {
  sendOscDualMessage("drum1", 1, theValue); // Amen Volume
}
void drum2Volume(float theValue) {
  sendOscDualMessage("drum2", 1, theValue); // Kick Volume
}
void drum2Decay(float theValue) {
  sendOscDualMessage("drum2", 2, constrain(theValue,0,1.0)); // Kick Decay
}
void drum2Pitch(float theValue) {
  sendOscDualMessage("drum2", 3, theValue); // Kick Decay
}
void drum3Volume(float theValue) {
  sendOscDualMessage("drum3", 1, theValue); // Hihat Volume
}
void drum3Decay(float theValue) {
  sendOscDualMessage("drum3", 2, constrain(theValue,0,0.9)); // Hihat Decay
}
void drum3Pitch(float theValue) {
  sendOscDualMessage("drum3", 3, theValue); // Hihat Decay
}
void drum4Volume(float theValue) {
  sendOscDualMessage("drum4", 1, theValue); // Perc / FM Volume
}
void drum4Decay(float theValue) {
  sendOscDualMessage("drum4", 2, theValue); // Perc / FM Decay
}
void drumReverb(float theValue) {
  sendOscMessage("drumreverb", constrain(theValue,0,0.9)); // Drum Reverb
}

void randomizer() {
  if (debugMessages) println("RANDOMIZER!");
  cp5.getController("note1Slider").setValue((int)random(0,90));
  cp5.getController("note2Slider").setValue((int)random(0,90));
  cp5.getController("note3Slider").setValue((int)random(0,90));
  cp5.getController("note4Slider").setValue((int)random(0,90));
  cp5.getController("note5Slider").setValue((int)random(0,90));
  cp5.getController("note6Slider").setValue((int)random(0,90));
  cp5.getController("note7Slider").setValue((int)random(0,90));
  cp5.getController("note8Slider").setValue((int)random(0,90));
}

void note1Slider(int theValue) {
  sendOscMessage("note1", theValue);
}
void note2Slider(int theValue) {
  sendOscMessage("note2", theValue);
}
void note3Slider(int theValue) {
  sendOscMessage("note3", theValue);
}
void note4Slider(int theValue) {
  sendOscMessage("note4", theValue);
}
void note5Slider(int theValue) {
  sendOscMessage("note5", theValue);
}
void note6Slider(int theValue) {
  sendOscMessage("note6", theValue);
}
void note7Slider(int theValue) {
  sendOscMessage("note7", theValue);
}
void note8Slider(int theValue) {
  sendOscMessage("note8", theValue);
}

// Functions for sending the OSC messages
void sendOscMessage(String msg, float val) {
  OscMessage toSend = new OscMessage("/" + msg);
  toSend.add(val);
  oscP5.send(toSend, sonicPi);
  if (debugMessages) println(toSend); 
}

void sendOscMessage(String msg, int val) {
  OscMessage toSend = new OscMessage("/" + msg);
  toSend.add((int)val);
  oscP5.send(toSend, sonicPi);
  if (debugMessages) println(toSend); 
}

void sendOscDualMessage(String msg, float val1, float val2) {
  OscMessage toSend = new OscMessage("/" + msg);
  toSend.add(val1);
  toSend.add(val2);
  oscP5.send(toSend, sonicPi);
  if (debugMessages) println(toSend); 
}