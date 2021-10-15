@LAZYGLOBAL OFF.
parameter SequencerState IS lexicon(),
	SequencerIndexes IS list().

{
//initialize SequencerState
//Sequences have: 
	//SeqName - name of the sequence
	//Display - thing to display in lists
	//type - type is Sequencer
	//mode - mode is Sequence
	//Substate - list of phases contained in the sequence, begins with end
		//Phases have:
			//Display - thing to display
			//type, mode - type and mode of the phase
			//substate - substate information of the phase
			//conditions - list of conditions
			//AddDelay - additional delay time after conditions are met
	//SeqPhase - current active phase
		//Index - list of indexes of active phase (list because nested sequences)
		//NestLevel - current nest level
//create state for end
LOCAL EndState IS lexicon("type","None","mode","None","SubState",lexicon()).

//phases is the list of phases, where nested lists contain further nested sequences
SET SequencerState["type"] TO "Sequencer".
SET SequencerState["mode"] TO "Sequence".
IF NOT SequencerState:haskey("SeqName") {SequencerState:add("SeqName","Default").}	//default name
SET SequencerState["Display"] TO "Seq: "+SequencerState["SeqName"].
IF NOT SequencerState:haskey("SubState") {	//default to single state that is the end state with End condition
	SequencerState:add("SubState",list(
		lexicon("Display","END"
			,"type",EndState["type"]
			,"mode",EndState["mode"]
			,"SubState",EndState["SubState"]
			,"Conditions",lexicon("root",lexicon("Display","<b>END</b>","condition","END"
			,"type","End","parent",-1,"children",list()))
			,"AddDelay",0
		)
	)).
}
IF NOT SequencerState:haskey("SeqPhase") {	//default to no state active
	SequencerState:add("SeqPhase",lexicon(
		"Index",list(),
		"NestLevel",0)).
}

//used to set the main function and conditions functions to be checked in Sequencer Main
LOCAL SeqPhaseFunc IS {}. //function used to store the phase main function
LOCAL SeqPhaseEvalConds IS {}.//function used to evaluate the conditions
GLOBAL SequencePhaseStartTime IS timestamp().	//record phase start times (for conditions)
LOCAL SeqDelayStartTime IS timestamp().	//start the delay timer
GLOBAL SequencePhaseStartLocation IS list(ship:geoposition,ship:altitude).

LOCAL SequencerPhasePanelIndex IS list(). //the panel state of the sequencer, contains indexes

LOCAL Grey TO rgb(0.8,0.8,0.8).  //color grey

//function to initialize Sequencer
GLOBAL SeqInit IS {
	MkSeqConditionGui().	//make the main/conditionals gui
	MkSeqPhaseGui().		//make the base level phase gui
	SET SeqButton:ontoggle TO { //set the SeqButton to open/hide the panel on toggle
		parameter s.
		IF s {
			SeqConditionGui:show().	//show condition gui
			FOR item IN SeqPhaseGui {item:show().}	//show phase guis
		} ELSE {
			SeqHide().
			StoreSeqCondLocation().
			StoreSeqPhaseLocation().
		}
	}.
	SET SeqButton:pressed TO TRUE.  //set the button to pressed by default

	RUNONCEPATH("/AP/Sequencer/Conditions").
	//****load conditions
}.

GLOBAL SeqDraggable TO {
	parameter s.
	SET SeqConditionGui:draggable TO s.
	FOR item IN SeqPhaseGui {SET item:draggable TO s.}	
}.

//function to hide all sequencer panels
GLOBAL SeqHide IS {
	//store condition gui location, and hide guis
	StoreSeqCondLocation().
	SeqConditionGui:hide().
	NewConditionGui:hide().
	
	//store phase guis locations and hide guis
	StoreSeqPhaseLocation().
	FOR item IN SeqPhaseGui {item:hide().}
}.

//list of gui locations
LOCAL SeqPhaseGuiXY IS list(list(1472,342)).

//list of guis (one for each level of nested sequence being shown)
LOCAL SeqPhaseGui IS list().

//function to save main sequencer phases panels locations
function StoreSeqPhaseLocation { //store gui locations to file
	UpdateSeqPhaseLocation().
	LOCAL guisizefile TO path("/AP/Sequencer/SeqPhaseXY.json").
	Create(guisizefile).
	writejson(SeqPhaseGuiXY,guisizefile). 
}

//function to load main Sequencer phases panels locations
function GetSeqPhaseLocation { //read gui locations from file
	LOCAL guisizefile TO path("/AP/Sequencer/SeqPhaseXY.json").
	IF EXISTS(guisizefile) {	SET SeqPhaseGuiXY TO readjson(guisizefile). }
}

//function to update the main Sequencer phases panels locations
function UpdateSeqPhaseLocation {
	//updates each position for currently shown windows
	//runs when gui locations are saved and whenever a gui is closed/hidden
	FROM {LOCAL index1 IS 0.} UNTIL index1 = SeqPhaseGui:length STEP {SET index1 TO index1+1.} DO {
		IF SeqPhaseGuiXY:length > index1 {	//if there is already a stored location, edit it
			SET SeqPhaseGuiXY[index1][0] TO SeqPhaseGui[index1]:x.
			SET SeqPhaseGuiXY[index1][1] TO SeqPhaseGui[index1]:y.
		} ELSE {	//add a new stored location
			SeqPhaseGuiXY:add(list(SeqPhaseGui[index1]:x,SeqPhaseGui[index1]:y)).
		}
	}.
	
	
}

//make the phase sequencer gui
//lists to store the buttons/text for changing later (enabling, disabling, or color)
LOCAL AddPhaseButton IS list().
LOCAL ReplacePhaseButton IS list().
LOCAL DeletePhaseButton IS list().
LOCAL ShowPhaseButton IS list().
LOCAL RunPhaseButton IS list().
LOCAL RunButton IS list().

LOCAL PhaseRowText IS list().
LOCAL AllGuiSequences IS list().
LOCAL NameText IS list().

//function
function MkSeqPhaseGui {
	parameter Sequence IS SequencerState.	//default to the main level sequence
	
	AllGuiSequences:add(Sequence).	//add this sequence to the list of gui sequences for use later
	LOCAL NestLevel IS SeqPhaseGui:length.	//get level of gui to be added
	SequencerPhasePanelIndex:add(0).
	PhaseRowText:add(list()).
	//SequencerPhasePanelIndex[NestLevel] is the selected index in this panel
	
	//create gui, location, size, skin, etc.
	LOCAL temp1 IS gui(0).	//create a gui this way. For some reasone if I create it in the add() function it won't stick around
	SeqPhaseGui:add(temp1).	//add the basic gui to the list
	SeqPhaseGui[NestLevel]:show().
	//configure the gui
	SkinSize(SeqPhaseGui[NestLevel]).
	//set the location
	GetSeqPhaseLocation().	//load the phase gui locations
	IF SeqPhaseGuiXY:length > NestLevel {	//if there is already a stored location for this level
		SET SeqPhaseGui[NestLevel]:x TO SeqPhaseGuiXY[NestLevel][0].	//set x coordinate
		SET SeqPhaseGui[NestLevel]:y TO SeqPhaseGuiXY[NestLevel][1].	//set y coordinate
	} ELSE {	//if there is no level already, set x coordinate to 200 left of last gui
		SET SeqPhaseGui[NestLevel]:x TO max(0,SeqPhaseGui[NestLevel-1]:x-201).	//set x coordinate to 200 left of last gui
		SET SeqPhaseGui[NestLevel]:y TO SeqPhaseGui[NestLevel-1]:y.	//set y coordinate
	}

	//set size of gui
	SET SeqPhaseGui[NestLevel]:style:height TO 300.
	SET SeqPhaseGui[NestLevel]:style:width TO 200.
	
	LOCAL SB1 IS MkBox(SeqPhaseGui[NestLevel],"VL",lexicon("padding",OBPad)).
	
	//fill out gui with fields
	
	//row for name and load/save buttons, and exit button
	LOCAL SB11 IS MkBox(SB1,"HB",lexicon("padding",OBPad)).
	//if the first gui add a space, otherwise add a close button
	IF NestLevel=0 {
		SB11:addspacing(17).
	} ELSE {
		MkButton(SB11,"x"
			,{
				SET SeqPhaseGui[Nestlevel-1]:enabled TO TRUE. //enable lower level gui
				
				SeqPhaseGui[NestLevel]:dispose().	//dispose of this gui
				SeqPhaseGui:remove(NestLevel).	//remove the disposed of gui from the list
				AllGuiSequences:remove(NestLevel).	//remove this sequence from the list
				//remove buttons from the lists
				AddPhaseButton:remove(NestLevel).
				ReplacePhaseButton:remove(NestLevel).
				DeletePhaseButton:remove(NestLevel).
				ShowPhaseButton:remove(NestLevel).
				RunPhaseButton:remove(NestLevel).
				RunButton:remove(NestLevel).
				//remove text of each phase from the list
				PhaseRowText:remove(NestLevel).
				NameText:remove(NestLevel).

				//remove index from the list of panel phase indexes
				SequencerPhasePanelIndex:remove(NestLevel).
			}
			,lexicon("color",red,"width",17)).
	}
	//name input field
	NameText:add(MkTextInput(SB11,Sequence,"SeqName",lexicon("hstretch",TRUE,"type","string"))).
	SET NameText[NestLevel]:onconfirm TO {
		parameter s.
		SET Sequence["SeqName"] TO s.
		SET Sequence["Display"] TO "Seq: "+s.
		IF NestLevel>0 {
			SET PhaseRowText[NestLevel-1][SequencerPhasePanelIndex[NestLevel-1]]:text TO Sequence["Display"].
		}
	}.
	
	SET NameText[NestLevel]:style:margin:v TO 3.
		//SAVE/LOAD
	MkButton(SB11,"SAVE",{SaveSequence(Sequence).},lexicon("fontsize",12,"color",mygreen,"width",36)).
	MkButton(SB11,"LOAD"
		,{
			LoadSequence(Sequence,NestLevel,PhaseRowB).
		},lexicon("fontsize",12,"color",red,"width",36)).
	
	//row for Insert, Replace, Delete, Show
	LOCAL SB12 IS MkBox(SB1,"HL",lexicon("padding",OBPad)).
	AddPhaseButton:add(MkButton(SB12,"ADD BEFORE: "+SequencerPhasePanelIndex[NestLevel]
		,{
			AddReplacePhase(Sequence,NestLevel,TRUE).
			PhaseRowB:clear().
			PhaseRow(Sequence,NestLevel,PhaseRowB).

			//increment SequencerState["SeqPhase"]["Index"] if it is later than added phase
			FOR index1 IN RANGE(0,NestLevel+1,1) {
				//if past active phase length, stop loop
				IF index1 = SequencerState["SeqPhase"]["Index"]:length {break.}
				
				//if at the active panel level, increment active phase if after added phase
				IF index1 = Nestlevel 
					AND SequencerState["SeqPhase"]["Index"][index1] >= SequencerPhasePanelIndex[NestLevel] {
					SET SequencerState["SeqPhase"]["Index"][index1] TO SequencerState["SeqPhase"]["Index"][index1]+1.
					break.
				}
				//if panel not in same tree branch as active, stop loop
				IF SequencerState["SeqPhase"]["Index"][index1] <> SequencerPhasePanelIndex[index1] {break.}
			}

			//increment phase level because added phase
			SET SequencerPhasePanelIndex[NestLevel] TO SequencerPhasePanelIndex[NestLevel]+1.
			
			UpdateSeqPhaseButton(Sequence,NestLevel).
			ColorPhase(mygreen).
		}
		,lexicon("fontsize",10,"width",96,"height",14))).
	ReplacePhaseButton:add(MkButton(SB12,"REPLACE: "+SequencerPhasePanelIndex[NestLevel]
		,{
			AddReplacePhase(Sequence,NestLevel,FALSE).
			PhaseRowB:clear().
			PhaseRow(Sequence,NestLevel,PhaseRowB).
			ColorPhase(mygreen).
		}
		,lexicon("fontsize",10,"width",96,"height",14,"color",white))).
	
	LOCAL SB13 IS MkBox(SB1,"HL",lexicon("padding",OBPad)).
	DeletePhaseButton:add(MkButton(SB13,"DELETE: "+SequencerPhasePanelIndex[NestLevel]
		,{
			Sequence["SubState"]:remove(SequencerPhasePanelIndex[NestLevel]).
			PhaseRowB:clear().
			PhaseRow(Sequence,NestLevel,PhaseRowB).
			UpdateSeqPhaseButton(Sequence,NestLevel).
		}
		,lexicon("fontsize",10,"width",96,"height",14,"color",red))).
	ShowPhaseButton:add(MkButton(SB13,"SHOW: "+SequencerPhasePanelIndex[NestLevel]
		,{
			LOCAL type1 IS Sequence["SubState"][SequencerPhasePanelIndex[NestLevel]]["type"].
			LOCAL mode1 IS Sequence["SubState"][SequencerPhasePanelIndex[NestLevel]]["mode"].
			//if it is a sequence, show a new sequence
			IF type1 = "Sequencer" AND mode1="Sequence" {
				//make a new gui
				MkSeqPhaseGui(Sequence["SubState"][SequencerPhasePanelIndex[NestLevel]]).
				//disable the current gui
				SET SeqPhaseGui[NestLevel]:enabled TO FALSE.
				//trigger to redraw this level when re-enabled
			} ELSE {	//if not a sequence show the phase and conditions
				//activate the correct mode panel
				SelectButton(type1,mode1).
				//set it to the right values by running panelinit
				ModeTypes[type1][mode1]["PanelInit"](LCopy(Sequence["SubState"][SequencerPhasePanelIndex[NestLevel]]["SubState"])).
				
				//set condition and additional delay to the right values and update that gui
				SET ConditionList TO LCopy(Sequence["SubState"][SequencerPhasePanelIndex[NestLevel]]["conditions"]).
				SET AddDelay TO Sequence["SubState"][SequencerPhasePanelIndex[NestLevel]]["AddDelay"].
				EditCondBox:clear().   //clear the condition menu
				EditCondRow().			//recreate the edit condition menu
				SET AddDelayEdit:text TO AddDelay:tostring.
			}
		}
		,lexicon("fontsize",10,"width",96,"height",14))).
	
	SB1:addspacing(5).
	
	//run buttons
	LOCAL SB14 IS MkBox(SB1,"HL",lexicon("padding",OBPad)).
	RunButton:add(MkButton(SB14,"START AT: 0",{},lexicon("fontsize",12,"width",96,"color",yellow))).
	RunPhaseButton:add(MkButton(SB14,"START AT: "+SequencerPhasePanelIndex[NestLevel],{},lexicon("fontsize",12,"width",96,"color",white))).
	
	//start stuff functions
	SET RunButton[NestLevel]:onclick TO {
		// SET SequencerState["SeqPhase"]["NestLevel"] TO NestLevel.	//set these to the panelindex BUG:
		SET SequencerState["SeqPhase"]["Index"] TO LCopy(SequencerPhasePanelIndex).
		SET SequencerState["SeqPhase"]["Index"][NestLevel] TO 0.
		SET OtherFunc TO { //start sequencer at end of current tick
			ModeTypes[RunState["Type"]][Runstate["Mode"]]["end"](). //run end function of previous state
			SeqStart().
			SET OtherFunc TO {}.
		}.
	}.

	SET RunPhaseButton[NestLevel]:onclick TO {
		// SET SequencerState["SeqPhase"]["NestLevel"] TO NestLevel.	//set these to the panelindex BUG:
		SET SequencerState["SeqPhase"]["Index"] TO LCopy(SequencerPhasePanelIndex).
		SET SequencerState["SeqPhase"]["Index"][NestLevel] TO SequencerPhasePanelIndex[NestLevel].
		SET OtherFunc TO {	//start sequencer at end of current tick
			ModeTypes[RunState["Type"]][Runstate["Mode"]]["end"](). //run end function of previous state
			SeqStart().
			SET OtherFunc TO {}.
		}.
	}.
	
	//scroll box for phases
	LOCAL ScrollB15 TO MkBox(SB1,"SB").
	SET ScrollB15:valways TO TRUE.	//always show the vertical scroll bar
	//vertical layout to list each one
	LOCAL PhaseRowB TO MkBox(ScrollB15,"VL").//,SB12:style:width-24,76,SB12:style:height-24).
	SET PhaseRowB:style:hstretch TO TRUE.
	SET PhaseRowB:style:vstretch TO TRUE.
	
	//create rows and return buttons
	PhaseRow(Sequence,NestLevel,PhaseRowB).
	//set button starting state
	UpdateSeqPhaseButton(Sequence,NestLevel).
}

//function to update all buttons in multiple guis
GLOBAL UpdateAllSeqPhaseButtons IS {
	//go through all guis
	FROM {LOCAL item IS 0.} UNTIL item=SeqPhaseGui:length STEP {SET item TO item+1.} DO {
		UpdateSeqPhaseButton(AllGuiSequences[item],item).
	}
}.

//function to update button text
function UpdateSeqPhaseButton {
	parameter Sequence, NestLevel.
	SET AddPhaseButton[NestLevel]:text TO "ADD BEFORE: "+SequencerPhasePanelIndex[NestLevel].
	SET ReplacePhaseButton[NestLevel]:text TO "REPLACE: "+SequencerPhasePanelIndex[NestLevel].
	SET DeletePhaseButton[NestLevel]:text TO "DELETE: "+SequencerPhasePanelIndex[NestLevel].
	SET ShowPhaseButton[NestLevel]:text TO "SHOW: "+SequencerPhasePanelIndex[NestLevel].
	SET RunPhaseButton[NestLevel]:text TO "START AT: "+SequencerPhasePanelIndex[NestLevel].
	
	//if the end phase, disable replace, delete, run, and show buttons
	//default is to disable buttons
	LOCAL ModeAdd IS FALSE.
	//if the panel mode is not none, then check the panel mode's state (to avoid adding bad states)
	//specifically, if the Back button has been pressed
	IF RunState["PanelType"] <> "None" AND RunState["PanelMode"] <> "None" {
		SET ModeAdd TO ModeTypes[RunState["PanelType"]][RunState["PanelMode"]]["ModeInfo"]["AddSeq"].
	}
	
	//enable based on phase
	LOCAL Enab IS 
		NOT (Sequence["SubState"][SequencerPhasePanelIndex[NestLevel]]["Display"] = "END").
		
	//loop from 0 to this nestlevel, to tell if this phase is active
	LOCAL ActivePhase IS true.
	FOR index1 IN RANGE(0,NestLevel+1,1) {
		//stop if reached the end of active phase index list
		IF index1 = SequencerState["SeqPhase"]["Index"]:length {
			SET ActivePhase TO false.
			break.
		}	

		IF SequencerState["SeqPhase"]["Index"][index1] <> SequencerPhasePanelIndex[index1] {
			SET ActivePhase TO false.
			break.
		}
	}

	//set buttons that depend on mode and phase selected
	SET ReplacePhaseButton[NestLevel]:enabled TO Enab AND ModeAdd AND NOT(ActivePhase).
	//set buttons that only depend on mode	
	SET AddPhaseButton[NestLevel]:enabled TO ModeAdd AND NOT(ActivePhase).
	//set buttons that only depend on the phase
	SET ShowPhaseButton[NestLevel]:enabled TO Enab.
	SET DeletePhaseButton[NestLevel]:enabled TO Enab AND NOT(ActivePhase).
	SET RunPhaseButton[NestLevel]:enabled TO Enab.
	
	
}

//function to create rows showing phase
function PhaseRow {
	parameter Sequence,	//sequence to create rows of
	NestLevel,	//nest level of sequence
	parent1.	//parent to add rows to
	
	PhaseRowText[NestLevel]:clear().
	FROM {LOCAL item IS 0.} UNTIL item=Sequence["SubState"]:length STEP {SET item TO item+1.} DO {
		LOCAL B1 IS MkBox(parent1,"HB",lexicon("width",177,"padding",OBPad)).
		LOCAL temp1 IS item.
		LOCAL But1 IS MkButton(B1,item:tostring
			,{SET SequencerPhasePanelIndex[NestLevel] TO temp1. UpdateSeqPhaseButton(Sequence, NestLevel).}
			,lexicon("fontsize",10,"width",20)).
		PhaseRowText[NestLevel]:add(MkLabel(B1,Sequence["SubState"][temp1]["Display"],lexicon("hstretch",TRUE))).
	}
	
}

//add phase to sequence
function AddReplacePhase {
	parameter Sequence,
	NestLevel,
	AddB IS TRUE.	//true if add, false if replace
	
	//create the phase listing, based on what is on the panels
	LOCAL TempPhase IS lexicon(
		"Display",ModeTypes[RunState["PanelType"]][RunState["PanelMode"]]["Display"]()
		,"type",RunState["PanelType"]
		,"mode",RunState["PanelMode"]
		,"SubState",RunState["PanelSubState"]
		,"Conditions",ConditionList
		,"AddDelay",AddDelay
		).
	
	//	Ifa sequence is added, then add the "SeqName" field
	IF TempPhase["type"]="Sequencer" AND TempPhase["mode"]="Sequence" {
		SET TempPhase["SeqName"] TO TempPhase["Display"]:replace("Seq: ","").
	}
	
	//if a mode that ends, set conditions to the end condition
	IF ModeTypes[TempPhase["type"]][TempPhase["mode"]]["ModeInfo"]["Ends"] {
		SET TempPhase["Conditions"] TO LCopy(ENDConditionList).
	}
	
	IF AddB {
		//add the phase to the sequence using LCopy to avoid unintentional changes later
		Sequence["SubState"]:insert(SequencerPhasePanelIndex[NestLevel],LCopy(TempPhase)).
	} ELSE {
		//replace the phase in the sequence
		SET Sequence["SubState"][SequencerPhasePanelIndex[NestLevel]] TO LCopy(TempPhase).
	}
}

//function to save the sequence to a file based on the sequence name
function SaveSequence {
	parameter Sequence.
	LOCAL filename TO path("/AP/Sequencer/Sequences/"+Sequence["SeqName"]+".json").
	Create(filename).
	writejson(Sequence,filename). 
	
}

//function to greate a gui and load a sequence
function LoadSequence {
	parameter Sequence	//Sequence to copy into
	, NestLevel	//level to use to get the position of the gui
	, PhaseRowB.	//box to create phases in
	//make a gui at the position of the gui it is called from
	LOCAL LoadSequenceGui IS gui(0).
	SET LoadSequenceGui:x TO SeqPhaseGui[NestLevel]:x.
	SET LoadSequenceGui:y TO SeqPhaseGui[NestLevel]:y.
	SkinSize(LoadSequenceGui).
	SET LoadSequenceGui:draggable TO FALSE.
	SET LoadSequenceGui:style:width TO SeqPhaseGui[NestLevel]:style:width.
	SET LoadSequenceGui:style:height TO SeqPhaseGui[NestLevel]:style:height.
	
	LOCAL LS1 IS MkBox(LoadSequenceGui,"VL",lexicon("padding",OBPad)).
	MkLabel(LS1,"Select Sequence:",lexicon("hstretch",TRUE)).
	//create popup menu to select the file to load
	LoadSequenceGui:show().
	
	cd("/AP/Sequencer/Sequences/").
	LOCAL SeqFiles IS list().
	LIST files IN SeqFiles.
	cd("/").

	LOCAL filename IS 0.
	IF SeqFiles:length>0 { //if files are found
		LOCAL popup IS MkPopup(LS1,LoadSequenceGui:style:width,0).
		FOR item IN SeqFiles {
			LOCAL trimmed IS item:tostring:replace(".json","").
			popup:addoption(trimmed).
		}
		
		SET popup:index TO 0.
		SET filename TO SeqFiles[0]:tostring:replace(".json","").
		
		SET popup:onchange TO {
			parameter s.
			SET filename TO s.
		}.
		
		//load button loads the file and sets the stored sequence to the loaded one
		MkButton(LS1,"LOAD"
			,{
				SET filename TO "/AP/Sequencer/Sequences/"+filename+".json".
				LOCAL SequenceLoad TO readjson(filename).
				
				LoadSequenceGui:dispose().
				LCopyInto(SequenceLoad,Sequence).	//copy all values into the existing structure
				SET SequencerPhasePanelIndex[NestLevel] TO 0.
				PhaseRowB:clear().
				PhaseRow(Sequence,NestLevel,PhaseRowB).
				UpdateSeqPhaseButton(Sequence,NestLevel).
				SET NameText[NestLevel]:text TO SequenceLoad["SeqName"].
			}
			,lexicon("color",red,"width",80,"fontsize",16)
		).
	} ELSE {
		MkLabel(LS1,"No Saved Sequences found.",lexicon("hstretch",TRUE)).
	}
	
	//cancel button closes the gui without doing anything
	MkButton(LS1,"CANCEL"
		,{
			LoadSequenceGui:dispose().
		}
		,lexicon("width",80,"fontsize",16)
	).
	
}

//function to get the phase information
function GetPhase {
	LOCAL PhaseSubstate IS SequencerState.
	FOR iter IN SequencerState["SeqPhase"]["Index"] {
		SET PhaseSubstate TO PhaseSubstate["Substate"][iter].
	}
	return LCopy(PhaseSubstate).
	
}

//function to change SequencerState["SeqPhase"]["Index"] to the next phase
//accounts for nested sequences and ending sequences
function NextPhase {
	LOCAL lastIndex IS SequencerState["SeqPhase"]["Index"]:length-1.	//get last index
	//increment last index
	SET SequencerState["SeqPhase"]["Index"][lastIndex] TO SequencerState["SeqPhase"]["Index"][lastIndex]+1. 

	LOCAL NewPhase IS GetPhase().
	IF NewPhase["type"] = "Sequencer" {//if sequence, add to phase index to access sequence at 0
		SequencerState["SeqPhase"]["Index"]:add(0).
		SET NewPhase TO GetPhase().
	}
	IF NewPhase["type"] = "None"	{	//newphase is the end of a sequence
		//if not the primary sequence, go down a level of nested sequences
		IF SequencerState["SeqPhase"]["Index"]:length > 1 {
			SET lastIndex TO SequencerState["SeqPhase"]["Index"]:length-1.	//update incase new index was added
			SequencerState["SeqPhase"]["Index"]:remove(lastIndex).	//remove last level
			NextPhase().	//run again with lower level as the last index to be incremented.
		}
	}
}

function ColorPhase {
	parameter Color1.
	FOR index1 IN RANGE(0,SequencerState["SeqPhase"]["Index"]:length,1) {
		//if no more panels, break loop (because the current phase isn't shown)
		IF index1 >= SequencerPhasePanelIndex:length {	
			break.
		}
		SET PhaseRowText[index1][SequencerState["SeqPhase"]["Index"][index1]]:style:textcolor TO Color1.
		IF SequencerState["SeqPhase"]["Index"][index1] <> SequencerPhasePanelIndex[index1] {
			break. //if panel phase not equal to phase, break loop, because the next panel isn't active
		}
	}
}

function RedoActiveConditionBox {	//setup active condition box
	ActiveConditionLabel:clear().
	ActiveCondBox:clear().
	ActiveCondRow().
	SET ActiveAddDelayText:text TO TimeFormatApprox(ActiveAddDelay,1,true).
	SET ActiveElapsedTimeText:text TO "0 sec".
}

function SeqPhaseCondInit {	//setup to evaluate conditions
	parameter SeqPhaseCurrent.
	
	SET SequencePhaseStartLocation TO list(ship:geoposition,ship:altitude).
	SET SequencePhaseStartTime TO timestamp().
	SET ActiveAddDelay TO SeqPhaseCurrent["AddDelay"].
	SET ActiveConditionList TO SeqPhaseCurrent["Conditions"].
	ConstructListEval().	//construct the evaluation functions
	SET SeqPhaseEvalConds TO {
		EvaluateAllCond().
		UpdateActiveCondLabel().	//color active conditions gui
		SET ActiveElapsedTimeText:text TO 
			TimeFormatApprox((timestamp() - SequencePhaseStartTime):seconds,1,true).
		SET ActiveDistFromStart:text TO
			NF(2,"m",true,SequencePhaseStartLocation[0]:altitudeposition(SequencePhaseStartLocation[1]):mag).
		IF ActiveConditionList["root"]["state"] {	//if end conditions met
		
			//there is a delay phase, so set start time and change evaluation to that
			IF ActiveAddDelay > 0 {	
				SET SeqDelayStartTime TO timestamp().
				SET SeqPhaseEvalConds TO {
					IF timestamp() > SeqDelayStartTime + ActiveAddDelay {
						SeqPhaseTransition().
					} ELSE {
						SET ActiveAddDelayText:text TO TimeFormatApprox((timestamp() - SeqDelayStartTime):seconds,1,true)
							+" / "+TimeFormatApprox(ActiveAddDelay,1,true).
					}
				}.	//stop evaluating conditions
			} ELSE {	//no delay phase, so transition
				SeqPhaseTransition().
			}
		}
	}.
	// SET SeqDelayTime TO false.
}


//function to initialize SequencerState - runs once when sequencer is Go
function SeqStart {
	LOCAL NewPhase IS GetPhase().	//get starting phase
	
	//SET Runstate (set type, mode, Main Function)
	SET RunState["Type"] TO SequencerState["type"].
	SET RunState["Mode"] TO SequencerState["mode"].
	SET RunState["ModeMain"] TO SeqMain@.
	SET RunState["SubState"] TO NewPhase["SubState"].
	SET RunState["Other"] TO "Go".

	SeqPhaseCondInit(NewPhase).
	
	RedoActiveConditionBox().
	
	//color the phase that is active
	ColorPhase(mygreen).
	//update phase button status to avoid editing active phase
	UpdateAllSeqPhaseButtons().	
	//run phase's type/mode init function
	ModeTypes[NewPhase["type"]][NewPhase["mode"]]["init"]().  //run init function of new state
	// StatusBox:showonly(ModeTypes[NewPhase["type"]][NewPhase["mode"]]["SB"]).  //change the status box
	SET SeqPhaseFunc TO ModeTypes[NewPhase["type"]][NewPhase["mode"]]["main"].
	SaveStatus().	//save new state to file
}

//function (main) that is called every update
// LOCAL MainCount IS 100.
function SeqMain {
	//run SeqPhaseFunc
	SeqPhaseFunc().
	//check conditions
	SeqPhaseEvalConds().	//evaluate conditions and respond
		
}

//function to transition between sequence phases
function SeqPhaseTransition {
	//run current phase type/mode end function
	LOCAL Phase IS GetPhase().
	//run end function of new state
	ModeTypes[Phase["type"]][Phase["mode"]]["End"]().  

	ColorPhase(white). //set old phase back to white
	NextPhase().	//update indexes
	ColorPhase(mygreen).	//color new phase
	UpdateAllSeqPhaseButtons().	//update phase button status
	SET Phase TO GetPhase().
	
	//run new phase type/mode init function
	IF Phase["type"] = "None" {
		SET RunState["Other"] TO "End".
		SeqEnd().
	} ELSE {
		SET RunState["SubState"] TO Phase["SubState"].
		//run init function of new state
		ModeTypes[Phase["type"]][Phase["mode"]]["init"]().  
		//change the status box
		// StatusBox:showonly(ModeTypes[Phase["type"]][Phase["mode"]]["SB"]).  
		//set main function to newstate main
		SET SeqPhaseFunc TO ModeTypes[Phase["type"]][Phase["mode"]]["main"].

		SET RunState["Other"] TO "Go".	//to cancel out any phase which ends with setting other to End

		SeqPhaseCondInit(Phase).
		RedoActiveConditionBox().
	
		//set SeqPhaseFunc (if not ended)
	}
	SaveStatus().	//save new state to file
}

GLOBAL function SeqEnd {
	IF defined SequencerState["SeqPhase"]["Index"] {
		ColorPhase(white).
		SET SequencerState["SeqPhase"]["Index"] TO list().
	}
	IF defined ActiveConditionList {
		SET ActiveConditionList TO lexicon().
		SET ActiveAddDelay TO 0.
		RedoActiveConditionBox().
	}
	SaveStatus().	//save new state to file
}
// #close Sequencer Main stuff


//#open - Condition creation stuff
LOCAL SeqConditionGui IS gui(0).   //initialize GUI
LOCAL SeqCondGuiXY TO list(1200,800).
//function to save main sequencer condition panel location
function StoreSeqCondLocation { //store gui location to file
	UpdateSeqCondLocation().
	LOCAL guisizefile TO path("/AP/Sequencer/SeqCondxy.json").
	Create(guisizefile).
	writejson(SeqCondGuiXY,guisizefile). 
}

//function to load main Sequencer condition gui location
function GetSeqCondLocation { //read gui location from file
	LOCAL guisizefile TO path("/AP/Sequencer/SeqCondxy.json").
	IF EXISTS(guisizefile) {	SET SeqCondGuiXY TO readjson(guisizefile). }
}

//function to update the main Sequencer condition gui location
function UpdateSeqCondLocation { //updates the gui location variable to the current position
	SET SeqCondGuiXY[0] TO SeqConditionGui:x.
	SET SeqCondGuiXY[1] TO SeqConditionGui:y.
}



//create gui within scope
GLOBAL NewConditionGui is gui(0).
SkinSize(NewConditionGui).
SET NewConditionGui:draggable TO FALSE.
NewConditionGui:hide().

//create variable for for conditions
LOCAL DefaultConditionList IS lexicon("root",lexicon("Display","<b>AND</b>"
			,"condition","AND"
			,"type","Logic"
			,"parent",-1
			,"children",list()
			,"eval",{}
			,"state",false
			)).
LOCAL ENDConditionList IS lexicon("root",lexicon("Display","<b>END</b>"
			,"condition","END"
			,"type","END"
			,"parent",-1
			,"children",list()
			,"eval",{}
			,"state",false
			)).
LOCAL ConditionList IS LCopy(DefaultConditionList). //variable that lists the conditions for the current step
//additional delay after all conditions are set
LOCAL AddDelay IS 0.
LOCAL ActiveAddDelay IS 0.

//variable for temporarily storing values to create a condition
//GLOBAL for access by conditions
//Display is the displaytext of the creation
//condition is the condition function
//index is the index to be replaced, or the parent if adding
//Add is whether to add or replace
GLOBAL ConditionCreate IS lexicon("Display","0","condition","0","type","0","index",-1,"Add",TRUE,"Finalize",{}).

//create variables for buttons, to set scope

//outer box of condition creation gui
LOCAL ConditionBox1 IS MkBox(NewConditionGui,"VL",lexicon("padding",OBPad)).
//box for the save and cancel buttons
LOCAL ConditionBox3 IS MkBox(ConditionBox1,"HL",lexicon("padding",OBPad)).
LOCAL ConditionCreateSaveButton TO MkButton(ConditionBox3,"SAVE",{},lexicon("color",mygreen,"width",96,"height",20,"fontsize",14)).
LOCAL ConditionCreateCancelButton TO MkButton(ConditionBox3,"CANCEL",{},lexicon("color",white,"width",96,"height",20,"fontsize",14)).
//popup menu for listing the condition types
LOCAL CB1Popup IS MkPopup(ConditionBox1,0,0,lexicon("hstretch",TRUE)).
//box for each condition type to create its dialogue box in (GLOBAL for access by conditions)
GLOBAL ConditionBox2 IS MkBox(ConditionBox1,"VB"). 

//save button function
SET ConditionCreateSaveButton:onclick TO {
	ConditionCreate["Finalize"]().	//run finalization function
	IF ConditionCreate["Add"] {
		LOCAL tempID IS RandID(8).
		UNTIL NOT ConditionList:haskey(tempID) {SET tempID TO RandID(8).} //generate new unique ID
		ConditionList:add(tempID,lexicon("Display",ConditionCreate["Display"]
			,"condition",ConditionCreate["condition"]
			,"type",ConditionCreate["type"]
			,"parent",ConditionCreate["index"]
			,"children",list()
			,"eval",{}
			,"state",false
			)).
		ConditionList[ConditionCreate["index"]]["children"]:add(tempID).
	} ELSE {
		SET ConditionList[ConditionCreate["index"]]["Display"] TO ConditionCreate["Display"].
		SET ConditionList[ConditionCreate["index"]]["condition"] TO ConditionCreate["condition"].
		SET ConditionList[ConditionCreate["index"]]["type"] TO ConditionCreate["type"].
	}
	EditCondBox:clear().   //clear the condition menu
	EditCondRow(). //recreate the condition menu
	NewConditionGui:hide().
}.

//cancel button function
SET ConditionCreateCancelButton:onclick TO {
	NewConditionGui:hide().
}.


//function to show a gui for making a condition
function MkCondition {
	parameter LogicOnly IS FALSE,	//if only logic conditions should be allowed
	StartState IS lexicon("type","Logic","condition","AND").		//start with logic/AND by default
	CB1Popup:clear().						//clear the popup menu

	SET NewConditionGui:x TO SeqConditionGui:x.   //set gui location
	SET NewConditionGui:y TO SeqConditionGui:y.
	NewConditionGui:show().		//show the gui
	
	//set the original main menu based on what should be shown
	IF LogicOnly {CB1Popup:addoption("Logic").}
	ELSE {	//all options except END
		SET CB1Popup:options TO ConditionSet:keys:sublist(1,ConditionSet:keys:length-1).
	}

	//when it changes, run the individual conditions menu
	SET CB1Popup:onchange TO {
		parameter s.
		ConditionBox2:clear().
		//display the condition type menu which will be used to set ConditionCreate fields
		ConditionSet[s]["Initialize"](). 
		SET ConditionCreate["type"] TO s.
		//the function for that conditionset to finalize the settings
		SET ConditionCreate["Finalize"] TO ConditionSet[s]["Finalize"].		
	}.

	//set the starting state of the menu
	LOCAL tempindex IS 0.
	IF StartState["type"] = "END" {SET CB1Popup:index TO 0.
	} ELSE {
		UNTIL StartState["type"] = CB1Popup:options[tempindex] {SET tempindex TO tempindex+1.}
		SET CB1Popup:index TO tempindex.	//-1 to skip the END condition not being in the list
	}
	//initialize the menu of the starting type
	ConditionSet[StartState["type"]]["Initialize"](StartState["condition"]).
}



//function to make the gui panel to select conditions
LOCAL EditActive TO 0.
function MkSeqConditionGui {
	GetSeqCondLocation().    //get stored location
	SkinSize(SeqConditionGui).    //libGui - set gui to defaults
	SET SeqConditionGui:x TO SeqCondGuiXY[0].   //set gui location
	SET SeqConditionGui:y TO SeqCondGuiXY[1].

	SET SeqConditionGui:style:height TO 300.
	SET SeqConditionGui:style:width TO 200.

	SET NewConditionGui:x TO SeqCondGuiXY[0].   //set gui location
	SET NewConditionGui:y TO SeqCondGuiXY[1].
	SET NewConditionGui:style:height TO 300.
	SET NewConditionGui:style:width TO 200.
	
	//vertical layout containing other boxes
	LOCAL B1 TO MkBox(SeqConditionGui,"VL",lexicon("padding",OBPad)). //vertical box containing others
	
	//box for active, edit buttons
	LOCAL B10 TO MkBox(B1,"HL",lexicon("width",200,"padding",OBPad)).

	//button to set panel to show active ****fill out functions
	LOCAL CondActiveButton TO MkButton(B10,"ACTIVE"
		,{parameter s.}
		,lexicon("color",mygreen,"hstretch",TRUE,"toggle",TRUE,"width",96,"fontsize",14)).
	SET CondActiveButton:exclusive TO TRUE.
	LOCAL CondEditButton TO MkButton(B10,"EDIT",{parameter s. IF s {EditActive:showonly(EditConditionBox).}}
		,lexicon("hstretch",TRUE,"toggle",TRUE,"width",96,"fontsize",14)).
	SET CondEditButton:exclusive TO TRUE.
	
	//box for Edit/Active
	SET EditActive TO MkBox(B1,"VL",lexicon("padding",OBPad)).
	MkCondEditBox().
	MkCondActiveBox().

	SET CondActiveButton:ontoggle TO {
		parameter s. IF s {
		//****show the active condition list
		ActiveConditionLabel:clear().
		ActiveCondBox:clear().
		ActiveCondRow().
		EditActive:showonly(ActiveConditionBox).}
		UpdateActiveCondLabel().
	}.

	//start with edit pressed
	SET CondEditButton:pressed TO TRUE.
}

LOCAL EditConditionBox TO 0. //box that edit and active condition guis are in
LOCAL EditCondBox TO 0.  //box that conditionals are listed in
LOCAL AddDelayEdit TO 0.
function MkCondEditBox {
	SET EditConditionBox TO EditActive:addstack().
	LOCAL EC1 TO MkBox(EditConditionBox,"VL",lexicon("width",200,"padding",OBPad)).
	//key describing buttons
	LOCAL B11 TO MkBox(EC1,"HL",lexicon("width",200,"height",14,"padding",OBPad)).
	MkLabel(B11,"x : Delete",lexicon("color",red,"width",66,"align","CENTER")).
	MkLabel(B11,"a : Add",lexicon("color",white,"width",67,"align","CENTER")).
	MkLabel(B11,"r : Replace",lexicon("color",Grey,"width",66,"align","CENTER")).
	//scroll box with Conditionals
	LOCAL SB12 TO MkBox(EC1,"SB").//,200,SeqConditionGui:style:height - B11:style:height).
	SET SB12:valways TO TRUE.	//always show the vertical scroll bar
	//vertical layout to list each one
	SET EditCondBox TO MkBox(SB12,"VL").//,SB12:style:width-24,76,SB12:style:height-24).
	SET EditCondBox:style:hstretch TO TRUE.
	SET EditCondBox:style:vstretch TO TRUE.
	
	//function to create each line
	EditCondRow().
	
	//create row for additional delay
	LOCAL B13 TO MkBox(EC1,"HL",lexicon("width",200,"height",14,"padding",OBPad)).
	MkLabel(B13,"Additional Delay",lexicon("width",90)).
	SET AddDelayEdit TO MkTextInput(B13,list(""),0,lexicon("width",60,"align","RIGHT")).
	SET AddDelayEdit:text TO AddDelay:tostring.
	SET AddDelayEdit:onconfirm TO {
		parameter s.
		SET AddDelay TO s:tonumber(AddDelay).
		SET AddDelayEdit:text TO AddDelay:tostring.
	}.
	MkLabel(B13,"sec",lexicon("width",30)).
}

function EditCondRow {
	parameter Indent IS 0,	//how many layers to indent
	CondIndex IS "root".		//the condition to chart

	LOCAL B1 TO MkBox(EditCondBox,"HB",lexicon("width",177,"padding",OBPad)).
	LOCAL Index1 IS CondIndex.
	//create delete button
	// IF ConditionList[Index1]["type"] = "END" {
		// B1:addspacing(51).
		// MkLabel(B1,ConditionList[Index1]["Display"],lexicon("hstretch",TRUE)).
	// } ELSE {
		MkButton(B1,"x",{DeleteCond(Index1,TRUE).},lexicon("color",red,"width",17)).

		//if it is a logic condition, add the add, replace buttons and run next level on children
		IF ConditionList[Index1]["type"] = "Logic" {
			//button to add sub condition with Index1 as parent
			MkButton(B1,"a",{AddCond(Index1).},lexicon("color",white,"width",16)).  
			//button to replace condition Index1
			MkButton(B1,"r",{ReplaceCond(Index1).},lexicon("color",Grey,"width",16)).  
			//indent and show display text
			B1:addspacing(Indent*8).
			MkLabel(B1,ConditionList[Index1]["Display"],lexicon("hstretch",TRUE)).
			
			//run row generation for children
			FOR child IN ConditionList[Index1]["children"] {EditCondRow(Indent+1,child). }
		} ELSE {  	//otherwise it is a raw condition
			B1:addspacing(17). //skip "add" button and add spacing
			//button to replace condition Index1
			MkButton(B1,"r",{ReplaceCond(Index1).},lexicon("color",Grey,"width",16)).  
			//indent and show display text
			B1:addspacing(Indent*8).
			//funny stuff to get text wrapping right-ish
			LOCAL labeltext IS ConditionList[Index1]["Display"].
			IF mod(labeltext:length,21-Indent*1.34) < 4 {SET labeltext TO labeltext + "<color=#00000000>aaaaaa</color>".}
			//add label
			MkLabel(B1,labeltext,lexicon("hstretch",TRUE)).
			
		}
	// }
}

//create active condition box
LOCAL ActiveConditionBox TO 0. //box that edit and active condition guis are in
LOCAL ActiveCondBox TO 0.
GLOBAL ActiveConditionList TO lexicon().
LOCAL ActiveAddDelayText TO 0.
LOCAL ActiveDistFromStart TO 0.
LOCAL ActiveElapsedTimeText TO 0.
function MkCondActiveBox {	//make active condition box
	SET ActiveConditionBox TO EditActive:addstack().
	LOCAL AC1 TO MkBox(ActiveConditionBox,"VL",lexicon("width",200,"padding",OBPad)).
	//key describing display
	MkLabel(AC1,"Active Conditions:   <color=#00ff00ff>TRUE</color>   <color=#ffffffff>FALSE</color>",lexicon("hstretch",TRUE)).
	//scroll box with Conditionals
	LOCAL SB12 TO MkBox(AC1,"SB",lexicon("padding",OBPad)).//,200,SeqConditionGui:style:height - B11:style:height).
	SET SB12:valways TO TRUE.	//always show the vertical scroll bar
	//vertical layout to list each one
	SET ActiveCondBox TO MkBox(SB12,"VL",lexicon("padding",OBPad)).//,SB12:style:width-24,76,SB12:style:height-24).
	SET ActiveCondBox:style:hstretch TO TRUE.
	SET ActiveCondBox:style:vstretch TO TRUE.
	
	//create row for distance from start of phase
	LOCAL B13 TO MkBox(AC1,"HL",lexicon("width",200,"height",14)).
	MkLabel(B13,"Dist. from Start:",lexicon("width",90)).
	SET ActiveDistFromStart TO MkLabel(B13,0+" m"
		,lexicon("align","RIGHT","width",83)).

	//create row for elapsed time
	LOCAL B13 TO MkBox(AC1,"HL",lexicon("width",200,"height",14)).
	MkLabel(B13,"Elapsed Time:",lexicon("width",90)).
	SET ActiveElapsedTimeText TO MkLabel(B13,0+" sec"
		,lexicon("align","RIGHT","width",83)).
	
	//create row for additional delay
	LOCAL C13 TO MkBox(AC1,"HL",lexicon("width",200,"height",14)).
	MkLabel(C13,"Additional Delay:",lexicon("width",90)).
	SET ActiveAddDelayText TO MkLabel(C13,ActiveAddDelay:tostring+" sec"
		,lexicon("align","RIGHT","width",83)).
}

//make active conditions box showing conditions of current phase and their state
LOCAL ActiveConditionLabel TO lexicon().
function ActiveCondRow {
	parameter Indent IS 0,	//how many layers to indent
	CondIndex IS "root".		//the condition to chart

	//horizontal row (for visual definition)
	LOCAL B1 TO MkBox(ActiveCondBox,"HB",lexicon("width",177,"padding",OBPad)).
	LOCAL Index1 IS CondIndex.

	IF NOT(ActiveConditionList:haskey(CondIndex)) {return.} //end function if index not found
	//if it is a logic condition, add the label and run the children
	IF ActiveConditionList[Index1]["type"] = "Logic" {
		//indent and show display text
		B1:addspacing(Indent*8).
		ActiveConditionLabel:add(Index1
			,MkLabel(B1,ActiveConditionList[Index1]["Display"],lexicon("hstretch",TRUE))).
		
		//run row generation for children
		FOR child IN ActiveConditionList[Index1]["children"] {ActiveCondRow(Indent+1,child). }
	} ELSE {  	//otherwise it is a raw condition
		//indent and show display text
		B1:addspacing(Indent*8).
		//funny stuff to get text wrapping right-ish
		LOCAL labeltext IS ActiveConditionList[Index1]["Display"].
		IF mod(labeltext:length,26-Indent*1.34) < 4 {SET labeltext TO labeltext + "<color=#00000000>aaaaaa</color>".}
		//add label
		ActiveConditionLabel:add(Index1,MkLabel(B1,labeltext,lexicon("hstretch",TRUE))).
	}
}
	

//delete condition
function DeleteCond {
	parameter Index1,  //index currently being deleted
	rebuild IS TRUE.	//whether to rebuild the list
	
	//delete this child from the parent's list of children
	LOCAL parent1 IS ConditionList[Index1]["parent"].
	IF parent1 <> -1 {
		LOCAL iter TO 0.
		UNTIL ConditionList[parent1]["children"][iter] = Index1 {SET iter TO iter+1.}
		ConditionList[parent1]["children"]:remove(iter).
	}
	
	//delete this items children
	UNTIL ConditionList[Index1]["children"]:length = 0 {	//go until there are no children
		DeleteCond(ConditionList[Index1]["children"][0],FALSE).	//delete the first child
	}
	
	ConditionList:remove(Index1).	//remove the condition

	IF ConditionList:length = 0    //add an AND to the beginning if empty
	{
		SET ConditionList TO LCopy(DefaultConditionList).
	}
	
	IF rebuild {
		EditCondBox:clear().   //clear the condition menu
		EditCondRow(). //recreate the condition menu
	}
}

//insert condition
function AddCond {
	parameter Index1.   //index of parent to add
	SET ConditionCreate["Add"] TO TRUE.
	SET ConditionCreate["index"] TO Index1.
	MkCondition().
}

//replace condition
function ReplaceCond {
	parameter Index1.		//index of item to replace

	//set ConditionCreate values appropriately
	SET ConditionCreate["Add"] TO FALSE.
	SET ConditionCreate["index"] TO Index1.

	//create startstate to duplicate what is being replaced
	LOCAL StartState IS lexicon("type",ConditionList[Index1]["type"],"condition",ConditionList[Index1]["condition"]).
	//run with LogicOnly if condition has no children
	IF ConditionList[Index1]["children"]:length = 0 { MkCondition(FALSE,StartState).
	} ELSE { MkCondition(TRUE,StartState).}
}


//******Condition Evaluation
//get the function to evaluate the condition
function ConstructEvalCondition {
	parameter Index1.	//index in ActiveConditionList to create eval function for

	LOCAL CType IS ActiveConditionList[Index1]["type"].
	LOCAL Construct IS ConditionSet[CType]["Construct"].
	return Construct(ActiveConditionList[Index1]["condition"],ActiveConditionList[Index1]["children"]).
}
	
//set the whole list of functions for evaluation
function ConstructListEval {
	FOR index1 IN ActiveConditionList:keys {
		SET ActiveConditionList[index1]["eval"] TO ConstructEvalCondition(index1).
		SET ActiveConditionList[index1]["state"] TO false.
	}
}

//evaluate all conditions
function EvaluateAllCond {
	FOR index1 IN RANGE(ActiveConditionList:length-1,-1,1)	{
		LOCAL key1 IS ActiveConditionList:keys[index1].
		SET ActiveConditionList[key1]["state"] TO ActiveConditionList[key1]["eval"](ActiveConditionList[key1]["children"]).
	}
}

function UpdateActiveCondLabel {	//update label colors in the active condition screen
	FOR index1 IN ActiveConditionList:keys {
		IF ActiveConditionList[index1]["state"] {
			SET ActiveConditionLabel[index1]:style:textcolor TO mygreen.
		} ELSE {
			SET ActiveConditionLabel[index1]:style:textcolor TO white.
		}
	}
}


//#close



}
