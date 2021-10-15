@LAZYGLOBAL OFF.
parameter TempRunState IS lexicon().

IF NOT TempRunState:haskey("Type") {TempRunState:add("Type","None").}
IF NOT TempRunState:haskey("Mode") {TempRunState:add("Mode","None").}
IF NOT TempRunState:haskey("ModeMain") {TempRunState:add("ModeMain",{}).}
IF NOT TempRunState:haskey("SubState") {TempRunState:add("SubState",lexicon()).}
IF NOT TempRunState:haskey("Other") {TempRunState:add("Other","None").}
IF NOT TempRunState:haskey("PanelType") {TempRunState:add("PanelType","None").}
IF NOT TempRunState:haskey("PanelMode") {TempRunState:add("PanelMode","None").}
IF NOT TempRunState:haskey("PanelSubState") {TempRunState:add("PanelSubState",lexicon()).}
SET TempRunState["PanelSubState"] TO TempRunState["SubState"].

//run library files
IF exists("0:/AP/library/ksm/RunLibs.ksm") {runoncepath("0:/AP/library/ksm/RunLibs.ksm").}
ELSE {runoncepath("0:/AP/library/RunLibs.ks").}

//run Sequencer
IF exists("0:/AP/Sequencer/Sequencer.ksm") {runoncepath("0:/AP/Sequencer/Sequencer.ksm").}
ELSE {runoncepath("0:/AP/Sequencer/Sequencer.ks").}


//create the gui, Large mode with all controls
function MkAPgui {
	//create GUI
	GLOBAL APgui IS gui(0).
	SkinSize(APgui).
	GetGuiLocation().
	
	SET APgui:x TO guixy[0].
	SET APgui:y TO guixy[1].
	
	//create main layout
	LOCAL L1 TO MkBox(APgui,"VL",lexicon("padding",OBPad,"margins",NoMar)). //overall box
	LOCAL L2a TO MkBox(L1,"HL",lexicon("padding",OBPad,"margins",NoMar)). //upper portion: title bar and status box
	// LOCAL L2a IS L1:addhlayout(). //upper portion: title bar and status box
	LOCAL TitleBox IS MkTitleBox(L2a). //title bar- write function (include GO button)
	GLOBAL StatusBox IS MkBox(L2a,"VB",lexicon("width",300,"height",80,"padding",OBPad,"margins",BMar)). //Status box, set by the operating mode
	
	GLOBAL L2b TO MkBox(L1,"HL",lexicon("padding",OBPad)).
	// GLOBAL L2b IS L1:addhbox(). //lower half
	LOCAL ModePanel IS MkBox(L2b,"VB",lexicon("width",100,"height",200,"padding",OBPad,"margins",BMar)).
	GLOBAL ModeControl IS MkBox(L2b,"VB",lexicon("width",300,"height",200,"padding",OBPad,"margins",BMar)).

	loadmodes().
	ModeTypes[RunState["Type"]][RunState["Mode"]]["init"]().  //run init function of new state
	SET RunState["ModeMain"] TO ModeTypes[RunState["Type"]][RunState["Mode"]]["main"].
	MkModePanel(ModePanel).
	ModeControl:showonly(ModeTypes[RunState["PanelType"]][RunState["PanelMode"]]["MB"]).
	StatusBox:showonly(ModeTypes[RunState["Type"]][RunState["Mode"]]["SB"]).
	
	ModeInit().
}

function StoreGuiLocation { //store gui location to file
	UpdateGuiLocation().
	LOCAL guisizefile TO path("0:/AP/guixy.json").
	writejson(guixy,guisizefile). 
}

function GetGuiLocation { //read gui location from file
	LOCAL guisizefile TO path("0:/AP/guixy.json").

	GLOBAL guixy TO list(1126,531,1126,531,1126,531,"L").
	IF EXISTS(guisizefile) {	SET guixy TO readjson(guisizefile). }
	SET guixy[6] TO "L".
}

function UpdateGuiLocation { //updates the gui location variable to the current position
	IF guixy[6] = "L" {
		SET guixy[0] TO APgui:x.
		SET guixy[1] TO APgui:y.
	} ELSE IF guixy[6] = "M" {
		SET guixy[2] TO APgui:x.
		SET guixy[3] TO APgui:y.
	} ELSE {
		SET guixy[4] TO APgui:x.
		SET guixy[5] TO APgui:y.
	}
}

function ResizeAPGui { //resize the gui
	parameter size1 IS "L".
	
	UpdateGuiLocation().
	LOCAL HideList IS list().
	LOCAL ShowList IS list().
	LOCAL wh is list().
	IF size1 = "S" {
		SET wh TO list(104,84).
		SET HideList TO list(L2b,GoButton,StatusBox,ActiveButton).
		SET APgui:x TO guixy[4].
		SET APgui:y TO guixy[5].		
	} ELSE IF size1 = "M" {
		SET wh TO list(404,84).
		SET ShowList TO list(StatusBox).
		SET HideList TO list(L2b,GoButton,ActiveButton).
		SET APgui:x TO guixy[2].
		SET APgui:y TO guixy[3].	
	} ELSE {
		SET wh TO list(0,0).
		SET ShowList TO list(L2b,StatusBox,GoButton,ActiveButton).
		SET APgui:x TO guixy[0].
		SET APgui:y TO guixy[1].		
	}
	
	FOR item IN ShowList {item:show().}
	FOR item IN HideList {item:hide().}
	SET APgui:style:width TO wh[0].
	SET APgui:style:height TO wh[1].
	SET guixy[6] TO size1.
}

function MkTitleBox { //make the title box
	parameter parent1.
	LOCAL TB TO MkBox(parent1,"VL",lexicon("width",100,"height",80,"padding",OBPad,"margins",BMar)).
	LOCAL TB2a TO MkBox(TB,"HL",lexicon("padding",OBPad)).
	LOCAL dim TO 12.
	MkButton(TB2a,"X", {SET done TO true. StoreGuiLocation().},lexicon("fontsize",12,"color",red,"width",dim,"height",dim)).
	TB2a:addspacing(3).
	MkButton(TB2a,"L", {ResizeAPGui("L").},lexicon("fontsize",12,"color",blue,"width",dim,"height",dim)).
	MkButton(TB2a,"M", {ResizeAPGui("M").},lexicon("fontsize",12,"color",blue,"width",dim,"height",dim)).
	MkButton(TB2a,"S", {ResizeAPGui("S"). },lexicon("fontsize",12,"color",blue,"width",dim,"height",dim)).

	MkButton(TB2a,char(8596)+char(8597),{parameter s. GuiDrag(s).},lexicon("fontsize",10,"color",black,"width",21,"height",dim,"toggle",true)).
	//make button to open/collapse sequencer
	GLOBAL SeqButton TO MkButton(TB2a,"Seq", {parameter s.},lexicon("fontsize",10,"color",yellow,"width",21,"height",dim,"toggle",TRUE)).
	
	//Add ship name to title block
	LOCAL shname IS MkLabel(TB,ship:name,lexicon("hstretch",true)).
	//Add single line status to title block
	GLOBAL TBstatus IS MkLabel(TB,"Status.",lexicon("fontsize",14,"color",black,"hstretch",true)).
	//Add box for Active, GO, Stop buttons
	LOCAL GO TO MkBox(TB,"HL",lexicon("width",100,"padding",OBPad)).
	MkActiveButton(GO).
	MkGoButton(GO).
	MkStopButton(GO).
}

function GuiDrag {
	parameter s.
	SET APGui:draggable TO s.
	IF defined SeqDraggable {SeqDraggable(s).}
}

GLOBAL OtherFunc IS {}. //to prevent the Active, Go, and Stop Button onclick from interrupting the main
//function midway through and resetting variables that main() needs, this is
//being made synchronus
GLOBAL PanelFunc IS {}.

function MkActiveButton { //make to ActiveButton
	parameter parent1.
	WAIT 0. //buttons function as interrupts, so make sure this all happens in one go
	GLOBAL ActiveButton TO MkButton(parent1,"ACT", {parameter s.},lexicon("fontsize",16,"color",green,"width",34,"toggle",true)).
	SET ActiveButton:ontoggle TO {
		parameter s.
		IF s {
			SET OtherFunc TO {  //set the function to actually do the things
				ModeTypes[RunState["Type"]][Runstate["Mode"]]["end"](). //run end function of previous state
				LOCAL type1 TO RunState["PanelType"].
				LOCAL mode1 TO RunState["PanelMode"].
				SET RunState["Type"] TO type1.  //update runstate variable
				SET RunState["Mode"] TO mode1.
				SET RunState["ModeMain"] TO ModeTypes[type1][mode1]["main"].
				SET RunState["SubState"] TO RunState["PanelSubState"].
				SET RunState["Other"] TO "Active".
				ModeTypes[type1][mode1]["init"]().  //run init function of new state
				StatusBox:showonly(ModeTypes[type1][mode1]["SB"]).  //change the status box
				SET OtherFunc TO {}.  //reset the function to nothing 
				SaveStatus().	//save new state to file
			}.
		} ELSE {
			IF RunState["Other"] = "Active" 
			{	SET OtherFunc TO 
				{
					StopMode(). 
					SET OtherFunc TO {}.
					SET RunState["Other"] TO "None".
				}.
			}
		}
		
	}.
	SET ActiveButton:enabled TO false.
}

function MkGoButton { //make to GO button
	parameter parent1.
	WAIT 0. //buttons function as interrupts, so make sure this all happens in one go
	GLOBAL GoButton TO MkButton(parent1,"GO", {},lexicon("fontsize",16,"color",yellow,"width",30)).
	SET GoButton:onclick TO {
		SET ActiveButton:pressed TO FALSE.  //cancel active
		SET OtherFunc TO {  //set the function to actually do the things
			ModeTypes[RunState["Type"]][Runstate["Mode"]]["end"](). //run end function of previous state
			LOCAL type1 TO RunState["PanelType"].
			LOCAL mode1 TO RunState["PanelMode"].
			SET RunState["Type"] TO type1.  //update runstate variable
			SET RunState["Mode"] TO mode1.
			SET RunState["ModeMain"] TO ModeTypes[type1][mode1]["main"].
			SET RunState["SubState"] TO LCopy(RunState["PanelSubState"]).
			SET RunState["Other"] TO "Go".
			ModeTypes[type1][mode1]["init"]().  //run init function of new state
			StatusBox:showonly(ModeTypes[type1][mode1]["SB"]).  //change the status box
			SET OtherFunc TO {}.  //reset the function to nothing
			SaveStatus().	//save new state to file
		}.
	}.
	SET GoButton:enabled TO false.
}

//function to stop the mode from running
function StopMode {
		ModeTypes[RunState["Type"]][Runstate["Mode"]]["end"](). //run end function of previous state
		// wait 0.
		ModeTypes["None"]["None"]["init"]().  //run init function of new state
		SET RunState["Type"] TO "None".  //update runstate variable
		SET RunState["Mode"] TO "None".
		SET RunState["SubState"] TO lexicon().
		SET RunState["ModeMain"] TO ModeTypes["None"]["None"]["main"].
		StatusBox:showonly(ModeTypes["None"]["None"]["SB"]).  //change the status box
		SET ActiveButton:pressed TO FALSE.
		SET RunState["Other"] TO "None".
		CancelPhases().
		SaveStatus().	//save new state to file
}

function MkStopButton { //make to Stop button
	parameter parent1.
	WAIT 0. //buttons function as interrupts, so make sure this all happens in one go
	LOCAL StopButton  TO MkButton(parent1,"ST", {},lexicon("fontsize",16,"color",red)).
	SET StopButton:onclick TO {
		SET OtherFunc TO {
			StopMode().
			SET OtherFunc TO {}. //reset the function to nothing 
		}.
	}.
}

function CancelPhases { //Function to cancel control (runs when StopMode runs
	FlightEnd().
	SeqEnd().
}

function RegisterMode { //create a mode menu item
	parameter modetype, //plane, rocket, etc. (Category is created if needed)
	modename, //display name
	init, //function called when mode is initialized
	modemain, //function called each loop
	modeend, //function called when mode ends
	SB, //status box
	MB, //main box
	panelinit, //function initializing the panel when mode is selected
	ModeInfo,   //info about the mode used elsewhere
	Display.	//function to create the display
	
	//If the type isn't already listed, create an empty listing
	IF NOT ModeTypes:haskey(modetype) {ModeTypes:add(modetype,lexicon()).}
	//Add the mode info to the appropriate type listing
	ModeTypes[modetype]:add(modename,lexicon("init",init,"main",modemain,"end",modeend,"SB",SB,"MB",MB
		,"PanelInit",panelinit,"ModeInfo",ModeInfo,"Display",Display)).
}

//keep open for new stuff to be added as needed
function APinit { //perform various initialization things
	//declare global variables
	GLOBAL ModeTypes IS lexicon().
	GLOBAL RunState IS TempRunState.
	
}

function loadmodes { //loads the modes from the types files
	{ //None mode
	//Status panel
	LOCAL SB to StatusBox:addstack().
	LOCAL SB2 TO MkBox(SB,"VL").//,lexicon("width",300,"height",80).
	MkLabel(SB2,"<b>Status: Not Running</b>"). 
	//Main Panel 
	LOCAL MB to ModeControl:addstack().
	LOCAL MB2 TO MkBox(MB,"VL").
	MkLabel(MB2,"None"). 
	RegisterMode("None","None",{SET TBstatus:text TO "Mode: None".},{},{},SB,MB,{}
		,ModeInfoInit(),{return "None".}).
	}
	
	//load flight modes from ksm files
	cd("0:/AP/Types").
	LOCAL Types IS list().
	LIST files IN Types.
	LOCAL loaded1 IS list().
	FOR item IN Types {
		IF item:extension = "ksm" {
			runoncepath("0:/AP/Types/"+item).
			loaded1:add(item:name:replace(".ksm","")).
		}
	}
	//loads flight modes from ks files if not already loaded from ksm file (see above)
	FOR item IN Types {
		IF item:extension = "ks" AND NOT loaded1:contains(item:name:replace(".ks",""))
			{runoncepath("0:/AP/Types/"+item).}
	}
	cd("/").
}	

function MkModePanel { //make the type and mode select panel and all stacked boxes
	parameter parent1. //the box the panel goes in

	LOCAL ModePanels TO lexicon().
	//make type selection panel
	LOCAL Select TO parent1:addstack().
	LOCAL Select1 TO MkBox(Select,"SB",lexicon("width",100,"height",200,"padding",OBPad)).
	LOCAL Select2 TO MkBox(Select1,"VL",lexicon("width",86,"height",200)).

	//GLOBAL because used elsewhere
	GLOBAL SelectButton IS { //action when a type select button is pressed
		parameter temp1,
		temp2 IS "None".  //button to press down, "None" means what it says
		SET RunState["PanelType"] TO temp1. 
		parent1:showonly(ModePanels[temp1]).

		//press the correct button down, Lord help me if I ever change something that breaks this
		//ModePanels - lexicon of mode selection panels
		//Runstate["PanelType"] - gets the right ModePanel
		//Widgets[0] - gets the first widget of the panel (the scroll bar)
		//Widgets[0] - gets the first widget of the scroll bar (the box of buttons)
		//Widgets - gets the list of buttons
		FOR item IN ModePanels[temp1]:WIDGETS[0]:WIDGETS[0]:WIDGETS
		{
			IF item:enabled { //to skip the spacing widget, which doesn't have a text field
				IF item:text = temp2 {	SET item:pressed TO true.} ELSE {SET item:pressed TO false.}
			}
		}		
	}.

	//GLOBAL because used in Sequencer
	GLOBAL ModeButton IS { //action when a mode select button is pressed
		parameter temp1,
		temp2 IS -99.  //-99 means don't do anything in PanelInit

		IF RunState["Other"] = "Active" {   //convert active mode to Go mode
			SET RunState["Other"] TO "Go".
			SET RunState["SubState"] TO LCopy(RunState["SubState"]). //break the continued updates
			SET ActiveButton:pressed TO FALSE.  //cancel active mode
		}	

		
		SET RunState["PanelMode"] TO temp1. 
		ModeControl:showonly(ModeTypes[RunState["PanelType"]][RunState["PanelMode"]]["MB"]).
		SET GoButton:enabled TO ModeTypes[RunState["PanelType"]][RunState["PanelMode"]]
					["ModeInfo"]["GoButton"].
		SET ActiveButton:enabled TO ModeTypes[RunState["PanelType"]][RunState["PanelMode"]]
					["ModeInfo"]["Active"].
		ModeTypes[RunState["PanelType"]][RunState["PanelMode"]]["PanelInit"](LCopy(temp2)). //run function to initialize panel
		UpdateAllSeqPhaseButtons().
	}.			
	
	//GLOBAL because used in Sequencer
	GLOBAL BackButton IS { //back button action, which will set all buttons to false and go back to type selection
		parameter temp1.
		SET RunState["PanelType"] TO "None".
		SET RunState["PanelMode"] TO "None".
		FOR item IN temp1:widgets {	//unpress all buttons
			IF item:enabled {SET item:pressed to false.}
			}
		parent1:showonly(Select).
		SET GoButton:enabled TO false.

		IF RunState["Other"] = "Active" {   //convert active mode to Go mode
			SET RunState["Other"] TO "Go".
			SET RunState["SubState"] TO LCopy(RunState["SubState"]). //break the continued updates
			SET ActiveButton:pressed TO FALSE.  //cancel active mode
		}	
		SET ActiveButton:enabled TO FALSE.  //disable active mode
		UpdateAllSeqPhaseButtons().
	}.

	//make the mode selection panels for each type
	FOR item IN ModeTypes:keys {
		IF item <> "None" {
			LOCAL temp2 IS item.
			//add button for this type to the type selection panel
			MkButton(Select2,temp2,{SelectButton(temp2).}	,lexicon("fontsize",14,"width",76)).
			
			//create panel stack box
			ModePanels:add(temp2,parent1:addstack()).
			LOCAL T1 TO MkBox(ModePanels[temp2],"SB",lexicon("width",100,"height",200,"padding",OBPad)).
			LOCAL T2 TO MkBox(T1,"VL",lexicon("width",76,"height",200)).
			
			//add back button to go back to type selection
			MkButton(T2,"Back",{BackButton(T2).},lexicon("fontsize",14,"color",cyan,"width",76)).
			LOCAL T2b TO T2:addspacing(5).
			SET T2b:enabled TO false. //to code for the BackButton() function to skip it
			
			//create the modebuttons for each mode in the type
			FOR item2 IN ModeTypes[temp2]:keys {
				LOCAL temp3 TO item2.
				LOCAL T3 TO MkButton(T2,temp3,{parameter var. IF var {ModeButton(temp3).}}
					,lexicon("fontsize",14,"width",76,"toggle",true)).
				SET T3:Exclusive TO true.
				SET T3:toggle TO true.
				IF temp2 = RunState["PanelType"] AND temp3 = RunState["PanelMode"]
					{SET T3:pressed TO true.}
			}
		}
	}
	
	//show basic Type select menu unless AP was initialized in a mode, 
	//then show that mode
	parent1:showonly(Select).
}

function ModeInit { //sets the select panel and main panel to an initial mode
	IF RunState["Mode"] <> "None" 
	{
		SET RunState["PanelType"] TO RunState["Type"].
		SET RunState["PanelMode"] TO RunState["Mode"].

		//put the correct Mode Selection panel in the selection panel
		SelectButton(RunState["PanelType"],RunState["PanelMode"]).
		
		//put the correct Mode MB in the main panel
		ModeButton(RunState["PanelMode"],RunState["SubState"]).
	}
}	

function ModeInfoInit { //default info for modes
	RETURN lexicon(	"GoButton",TRUE  //Go button is enabled
					,"Active",TRUE	//Mode can be synced with the Panel (constant updates to runtime)
					,"Ends",FALSE	//Mode does NOT end automatically
					,"AddSeq",TRUE	//mode can be added to sequencer
					).
}

GLOBAL function SaveStatus {	//write the status to a file
	writejson(RunState,"/APStatus.json").
}

//start code
APinit(). //initialize AP 
LOCAL done TO false. //set variable for when to end
MkAPgui(). //make the GUI
SeqInit(). //initialize sequencer
GuiDrag(false).
APgui:show().
ModeTypes[RunState["type"]][RunState["mode"]]["init"]().	//if an initial mode is passed in, then start with this
	
UNTIL done {
	WAIT 0.
	RunState["ModeMain"]().
   //The below called functions (StopMode, OtherMode) are normally blank, but get set to something when the button 
	//is pressed. The function resets them back to blank at the end.
	//This means these functions never get called in the middle of main(), but wait
	//until after main to run.
	IF RunState["Other"] = "End" {StopMode().}
	OtherFunc().
	PanelFunc().
}

clearvecdraws().
SeqHide().
APgui:hide().




