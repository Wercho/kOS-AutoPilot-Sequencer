@LAZYGLOBAL OFF.

LOCAL filename IS list(GetPlaneStatFile(ship:name)).
GLOBAL PlaneStats IS lexicon().
SET PlaneStats TO LoadPlaneStats(filename[0]).

{ //Mode Craft Stats - #open
//Stats about the mode (mostly helpful for Sequencer)
LOCAL ModeInfo IS ModeInfoInit().
SET ModeInfo["GoButton"] TO FALSE.
SET ModeInfo["Active"] TO FALSE.
SET ModeInfo["AddSeq"] TO FALSE.

//add necessary variables here as local. They will be accesible 
//in the functions without passing them
function UpdatePanel {
	FOR item IN inputs:keys {SET inputs[item]:text TO PlaneStats[item]:tostring().}
	SET Br:pressed TO PlaneStats["Use Airbrakes"].
}


//run function when mode is GO
function Init {
}

//main loop
function Main {
}

//main loop
function End {
}

//Status panel
LOCAL SB to StatusBox:addstack().
LOCAL SB2 TO MkBox(SB,"VB",lexicon("width",300,"height",80,"padding",OBPad)).
MkLabel(SB2,"PlaneStats",lexicon("width",200)).  //won't ever actually get shown

//Main Panel #open
	LOCAL MB to ModeControl:addstack().
	LOCAL MB2 TO MkBox(MB,"VB",lexicon("width",300,"height",200,"padding",OBPad)).
	LOCAL ignore IS list("PlaneRuleSet","Use Airbrakes").
	//edit values
	LOCAL inputs TO Lexicon_Edit(MB2,PlaneStats,lexicon("columns",2,"width1",98,"width2",48,"ignore",ignore)).

	//bottom panel of pane
	LOCAL MB3 TO MkBox(MB2,"HL",lexicon("width",300,"padding",OBPad)).

	//remaining plane stats
	LOCAL PlaneMore TO MkBox(MB3,"VB",lexicon("width",100,"padding",OBPad)).
	//true false for use brakes during approach
	LOCAL Br TO MkButton(PlaneMore,"Use Airbrakes",
		{parameter var. SET PlaneStats["Use Airbrakes"] TO var.},
		lexicon("toggle",true,"hstretch",true,"height",16)).
	SET Br:pressed TO PlaneStats["Use Airbrakes"].
	SET Br:style:normal:textcolor TO red.
	SET Br:style:on:textcolor TO green.
	// set ruleset for plane
	MkLabel(PlaneMore,"Ruleset:",lexicon("color",green,"hstretch",true)).
	MkLabel(PlaneMore,"Not Implemented").

	//save/load - #open
		MB3:addspacing(22).
		LOCAL SL1 TO MkBox(MB3,"VB",lexicon("width",178,"padding",OBPad)).
		
		//save/load buttons
		LOCAL SL1A TO MkBox(SL1,"HL",lexicon("width",SL1:style:width,"padding",OBPad)).
		MkButton(SL1A,"SAVE <b>"+char(8595)+"</b>",{SavePlaneStats(PlaneStats,filename[0]).}
			,lexicon("color",green,"width",SL1A:style:width*0.5-1,"marginv",0)).
		LOCAL LoadButton IS MkButton(SL1A,"<b>"+char(8595)+"</b> LOAD",{
			LCopyInto(LoadPlaneStats(filename[0]),PlaneStats).	//try to preserve textfield referencing
			UpdatePanel().
			}, lexicon("color",red,"width",SL1A:style:width*0.5-1,"marginv",0)).
		//filename
		LOCAL FileLine IS MkBox(SL1,"HL",lexicon("width",SL1:style:width,"padding",OBPad)).
		MkLabel(FileLine,"Filename:",lexicon("width",55)).
		LOCAL FileInput IS MkTextInput(FileLine,filename,0,lexicon("type","string","hstretch",true)).
		SET FileInput:onconfirm TO {		//make load button not enabled if file doesn't exist
			parameter s.
			SET filename[0] TO s.
			SET LoadButton:enabled TO FileExists(filename[0],PlaneStatsFilePath).
		}.

		//save / load preset
		SL1:addspacing(2).
		LOCAL SL1B TO MkBox(SL1,"HL",lexicon("width",SL1:style:width,"padding",OBPad)).
		MkButton(SL1B,"SAVE Preset <b>"+char(8593)+"</b>",{
				SavePlanePreset(PlaneStats,filename[0]).
				SET PresetSelect:options TO ListPlanePresets().
				SET PresetSelect:index TO -1.
				SET LoadPreset:enabled TO false.
			},lexicon("color",green,"width",SL1B:style:width*0.5-1,"marginv",0)).
		LOCAL LoadPreset TO MkButton(SL1B,"<b>"+char(8595)+"</b> LOAD Preset",{
				LCopyInto(LoadPlanePreset(PresetSelect:value),PlaneStats).	//try to preserve textfield referencing
				SET FileInput:text TO PresetSelect:value.
				UpdatePanel().
			},lexicon("color",green,"width",SL1B:style:width*0.5-1,"marginv",0)).
		
		//Preset Select
		LOCAL PresetLine IS MkBox(SL1,"HL",lexicon("width",SL1:style:width,"padding",OBPad)).
		LOCAL PresetSelect IS MkPopup(SL1,0,0,lexicon("maxvis",5)).
		SET PresetSelect:style:hstretch TO true.
		SET PresetSelect:index TO -1.
		SET PresetSelect:onchange TO {
			parameter val.
			SET LoadPreset:enabled TO PresetSelect:index > -1.
		}.
		SET PresetSelect:options TO ListPlanePresets().
		SET LoadPreset:enabled TO false.
		
	//#close

//#close

//PanelInit 
function PanelInit {
	parameter temp1. //state to set PanelSubState to, -99 means don't change
	SET RunState["PanelSubState"] TO 0.
}

function Display {
	return "Plane:Craft Stats".
}

RegisterMode("Plane","Craft Stats",Init@,Main@,End@,SB,MB,PanelInit@,ModeInfo,Display@).
print "Plane: Craft Stats loaded.".
} //#close


