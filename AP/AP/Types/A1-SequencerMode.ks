@LAZYGLOBAL OFF.
//#open - create sequencer mode for adding sequences to a sequence
{
//Stats about the mode (mostly helpful for Sequencer
LOCAL ModeInfo IS ModeInfoInit().
SET ModeInfo["GoButton"] TO FALSE.
SET ModeInfo["Active"] TO FALSE.

//add necessary variables here as local. They will be accesible 
//in the functions without passing them
LOCAL SelectedSequenceName IS 0.
LOCAL SelectedSequence IS 0.

//Status panel
LOCAL SB to StatusBox:addstack().
LOCAL SB2 TO MkBox(SB,"VB",lexicon("width",300,"height",80,"padding",OBPad)). //blank because the mode can't be activated

//Main Panel
LOCAL MB to ModeControl:addstack().
LOCAL MB2 TO MkBox(MB,"VB",lexicon("width",300,"height",200,"padding",OBPad)).

MkLabel(MB2,"Select Sequence:",lexicon("hstretch",TRUE)).

cd("0:/AP/Sequencer/Sequences/").
LOCAL SeqFiles IS list().
LIST files IN SeqFiles.
cd("/").

LOCAL filename IS 0.
LOCAL SeqPopup IS 0.
IF SeqFiles:length>0 { //if files are found - fill out the popupmenu
	SET SeqPopup TO MkPopup(MB2,0,0,lexicon("hstretch",TRUE)).
	FOR item IN SeqFiles {
		LOCAL trimmed IS item:tostring:remove(item:tostring:findlast(".json"),5).
		SeqPopup:addoption(trimmed).
	}
	
	SET filename TO SeqFiles[0]:tostring:remove(SeqFiles[0]:tostring:findlast(".json"),5).
	SET filename TO "0:/AP/Sequencer/Sequences/"+filename+".json".
	SET SelectedSequence TO readjson(filename).
	SET RunState["PanelSubState"] TO SelectedSequence["SubState"].
	
	SET SeqPopup:onchange TO {
		parameter s.
		SET filename TO "0:/AP/Sequencer/Sequences/"+s+".json".
		SET SelectedSequence TO readjson(filename).
		SET RunState["PanelSubState"] TO SelectedSequence["SubState"].
	}.
	
	SET SeqPopup:index TO 0.
	
} ELSE {MkLabel(MB2,"No Sequences Found.",lexicon("hstretch",TRUE)).}	//no files found

//make a button to refresh the list of sequences
MkButton(MB2,"Refresh List"
	,{
		cd("0:/AP/Sequencer/Sequences/").
		LIST files IN SeqFiles.
		cd("/").
		
		SeqPopup:options:clear().
		FOR item IN SeqFiles {
			LOCAL trimmed IS item:tostring:remove(item:tostring:findlast(".json"),5).
			SeqPopup:addoption(trimmed).
		}
	
		SET filename TO SeqFiles[0]:tostring:remove(SeqFiles[0]:tostring:findlast(".json"),5).
		SET filename TO "0:/AP/Sequencer/Sequences/"+filename+".json".
	}
	,lexicon("width",120)
).


//initialization of the mode - executes once when GO button pressed
function Init {
	SeqStart().	//just if a sequence is passed in
}

//main loop - executes every time through
function Main {

}

//function ending the mode - executes once when GO button pressed and this is the current mode
function End {

}

//PanelInit 
function PanelInit {
	parameter temp1. //state to set PanelSubState to, -99 means don't change
	// SET GoButton:enabled TO true.
	
	IF temp1 <> -99 
	{
		SET SelectedSequence TO temp1.
	}
	SET RunState["PanelSubState"] TO SelectedSequence["SubState"]. //make these change together
}

function Display {
	return "Seq: "+SelectedSequence["SeqName"].
}

RegisterMode("Sequencer","Sequence",Init@,Main@,End@,SB,MB,PanelInit@,ModeInfo,Display@).
} //#close