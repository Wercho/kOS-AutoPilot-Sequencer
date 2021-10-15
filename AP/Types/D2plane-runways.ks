@LAZYGLOBAL OFF.

{ //Mode Runways - #open
//initialize mode
//Stats about the mode (mostly helpful for Sequencer
LOCAL ModeInfo IS ModeInfoInit().
SET ModeInfo["GoButton"] TO FALSE.
SET ModeInfo["Active"] TO FALSE.
SET ModeInfo["AddSeq"] TO FALSE.

//add necessary variables here as local. They will be accesible 
//in the functions without passing them
//runways to be stored as a lexicon of (name, latlng1, latlng2, land in direction from 1 to 2 (land12), land21, takeoff12, takeoff21
//Runways is a Global variable established in PlaneLib
LOCAL Editing is list(false,"","").		//editing (or new), oldname, newname
LOCAL DefaultRunway IS lexicon("P1",	latlng(0,0),	//lat lng of one end
							"P2",		latlng(0,0),	//lat lng of other end
							"Land12",	true,		//enable landing in the direction from P1 to P2
							"Land21",	true,		//enable landing in the direction from P2 to P1
							"TakeOff12",true,		//enable landing in the direction from P1 to P2
							"TakeOff21",true,		//enable landing in the direction from P2 to P1
							"WaterRunway"	,false).	//is it a water landing (so plane shouldn't use landing gear
LOCAL EditRunway IS LCopy(DefaultRunway).
LOCAL P1Vec IS vecdraw({return EditRunway["P1"]:position + ship:up:forevector*10.}
					,{return -ship:up:forevector*10.},black).
LOCAL P2Vec IS vecdraw({return EditRunway["P2"]:position + ship:up:forevector*10.}
					,{return -ship:up:forevector*10.},white).
LOCAL P12Vec IS vecdraw({return EditRunway["P1"]:position + ship:up:forevector*2.}
					,{return EditRunway["P2"]:position-EditRunway["P1"]:position.},red).
LOCAL P21Vec IS vecdraw({return EditRunway["P2"]:position + ship:up:forevector*4.}
					,{return EditRunway["P1"]:position-EditRunway["P2"]:position.},blue).


function RunwaysRefresh { 	//code to refresh the runways list popup
	SET RunwaySelect:options TO Runways:keys.
}

function RightPanelRefresh {	//refresh all the fields in the right panel
	SET NameField:text TO Editing[1].
	SET Line12Land:pressed TO EditRunway["Land12"].
	SET Line12Take:pressed TO EditRunway["TakeOff12"].
	SET Line21Land:pressed TO EditRunway["Land21"].
	SET Line21Take:pressed TO EditRunway["TakeOff21"].
	SET WaterButton:pressed TO EditRunway["WaterRunway"].

	SET SaveButton:enabled TO NOT(Editing[2] = "").	//if new, set to false until a name change is made
}

//Status panel
LOCAL SB to StatusBox:addstack().
LOCAL SB2 TO MkBox(SB,"VB",lexicon("width",300,"height",80,"padding",OBPad)).
MkLabel(SB2,"Runways",lexicon("width",200)).  //won't ever actually get shown

//Main Panel
LOCAL MB to ModeControl:addstack().
LOCAL MB2 TO MkBox(MB,"HB",lexicon("width",300,"height",200,"padding",OBPad)).

//left panel to control what is being edited
LOCAL LeftPanel TO MkBox(MB2,"VB",lexicon("width",100,"height",200,"padding",IBPad)).
//button to create a new Runway
LOCAL NewButton TO MkButton(LeftPanel,"New Runway",{ //**** set this to clear the right panel
		SET Editing to list(false,"","").
		SET EditRunway TO LCopy(DefaultRunway).
		print Editing.
		RightPanelRefresh().
	},lexicon("color",green,"fontsize",14,"hstretch",true)).
LeftPanel:addspacing(5).
//make the runway select popup
LOCAL RunwaySelect IS MkPopup(LeftPanel).
SET RunwaySelect:style:hstretch TO true.
SET RunwaySelect:index TO -1.
SET RunwaySelect:onchange TO {
	parameter val.
	SET EditButton:enabled TO RunwaySelect:index > -1.
	SET DeleteButton:enabled TO RunwaySelect:index > -1.
}.

//edit button
LeftPanel:addspacing(5).
LOCAL EditButton IS MkButton(LeftPanel,"Edit Runway",{
		IF RunwaySelect:index > -1 {					//should be disabled, but check anyway
			SET Editing to list(true,RunwaySelect:value,RunwaySelect:value).
			SET EditRunway TO LCopy(Runways[RunwaySelect:value]).
			RightPanelRefresh().	
		}
	}, lexicon("hstretch",true,"height",16)).
SET EditButton:enabled TO RunwaySelect:index > -1.	//diable button if no runway to edit

//delete runway button
LOCAL DeleteButton IS MkButton(LeftPanel,"Delete Runway",{ //delete a runway from the list
	//make gui to confirm deletion with yes and no buttons.
	LOCAL ConfirmGui IS gui(150,100).
	SkinSize(ConfirmGui).
	SET ConfirmGui:x TO APgui:x + 125.
	SET ConfirmGui:y TO APgui:y + 175.
	LOCAL ConB1 IS MkBox(ConfirmGui,"VB",lexicon("padding",OBPad)).
	MkLabel(ConB1,"Really Delete Runway",lexicon("hstretch",true)).
	MkLabel(ConB1,"<b>"+RunwaySelect:value+"</b>",lexicon("hstretch",true)).
	LOCAL ConB2 IS MkBox(ConB1,"HL").
	MkButton(ConB2,"YES",{
		ConfirmGui:hide().
		Runways:remove(RunwaySelect:value).
		//reset things to avoid the right panel being wrong
		SET RunwaySelect:index TO -1.
		SET RunwaySelect:options TO Runways:keys.
		SET EditButton:enabled TO false.
		SET DeleteButton:enabled TO false.
		SET EditRunway TO LCopy(DefaultRunway).
		SET Editing TO list(false,"","").
		RightPanelRefresh().
		SET APgui:enabled TO true.
	},lexicon("fontsize",14,"color",black,"hstretch",true,"height",16)).
	MkButton(ConB2,"NO",{
		ConfirmGui:hide().
		SET APgui:enabled TO true.
	},lexicon("fontsize",14,"color",white,"hstretch",true,"height",16)).
	SET APgui:enabled TO false.	//disable the main gui until they press something
	ConfirmGui:show().
}, lexicon("Hstretch",true,"color",red,"height",16)).
SET DeleteButton:enabled TO RunwaySelect:index > -1. //disable button if no runway to edit

//right panel to edit runways
LOCAL RightPanel IS MkBox(MB2,"VB",lexicon("width",200,"height",200,"padding",IBPad)).

//edit name
LOCAL NameLine IS MkBox(RightPanel,"HL",lexicon("padding",OBPad)).//,200,0).
MkLabel(NameLine,"Name:",lexicon("fontsize",12,"width",50)).
LOCAL NameField IS MkTextInput(NameLine,Editing,2,lexicon("fontsize",12,"color",yellow,"hstretch",true,"align","CENTER")).
SET NameField:tooltip TO "Input Name".
SET NameField:onconfirm TO {
	parameter val.
	//check if runway is being edited and name is the same, or that name is unique
	IF (Editing[0] AND Editing[1] = val) OR NOT Runways:haskey(val) {SET Editing[2] TO val.} 
	ELSE {SET NameField:text TO Editing[2].}	//otherwise don't allow saving
	SET SaveButton:enabled TO NOT(Editing[2] = "").
}.


RightPanel:addspacing(2).
//mark runway endpoints
MkLabel(RightPanel,"Mark Runway Endpoints (at current location):",lexicon("height",25,"width",125)).
LOCAL MarkLine IS MkBox(RightPanel,"HL").
MkButton(MarkLine,"Mark Point 1",{
	SET EditRunway["P1"] TO ship:geoposition.
},lexicon("color",black,"hstretch",true,"height",16)).
MkButton(MarkLine,"Mark Point 2",{
	SET EditRunway["P2"] TO ship:geoposition.
},lexicon("color",white,"hstretch",true,"height",16)).

//add buttons to enable/disable landing and taking off in each direction
RightPanel:addspacing(2).
MkLabel(RightPanel,"Enable takeoff / landing in the direction of the arrows (For example, disable if there is an obstacle in the flightpath.):").
LOCAL Line12 IS MkBox(RightPanel,"HL",lexicon("padding",OBPad,"margins",NoMar)).
MkLabel(Line12,"<color=red>Red</color> arrow direction:",lexicon("width",100)).
LOCAL Line12Land IS MkButton(Line12,"Landing",{parameter val. SET EditRunway["Land12"] TO val.}
	, lexicon("toggle",true,"hstretch",true)).
LOCAL Line12Take IS MkButton(Line12,"Takeoff",{parameter val. SET EditRunway["TakeOff12"] TO val.}
	, lexicon("toggle",true,"hstretch",true)).
LOCAL Line21 IS MkBox(RightPanel,"HL",lexicon("padding",OBPad,"margins",NoMar)).
MkLabel(Line21,"<color=Blue>Blue</color> arrow direction:",lexicon("width",100)).
LOCAL Line21Land IS MkButton(Line21,"Landing",{parameter val. SET EditRunway["Land21"] TO val.}
	, lexicon("toggle",true,"hstretch",true)).
LOCAL Line21Take IS MkButton(Line21,"Takeoff",{parameter val. SET EditRunway["TakeOff21"] TO val.}
	, lexicon("toggle",true,"hstretch",true)).

RightPanel:addspacing(2).
LOCAL LineWater IS MkBox(RightPanel,"HL",lexicon("padding",OBPad,"margins",NoMar)).
MkLabel(LineWater,"Water Runway? (Planes won't use landing gear.)",lexicon("height",25,"width",115)).
LOCAL WaterButton IS MkButton(LineWater,"Water Runway",{
		parameter val. 
		SET EditRunway["WaterRunway"] TO val.
	}, lexicon("toggle",true,"hstretch",true)).


RightPanel:addspacing(5).
//save Runway, and show/hide vectors
LOCAL SaveLine IS MkBox(RightPanel,"HL",lexicon("padding",OBPad,"margins",NoMar)).
LOCAL SaveButton IS MkButton(SaveLine,"SAVE Runway",{
	IF Editing[0] {	//if editing an existing runway
		RunWays:remove(Editing[1]).
	}
	RunWays:add(Editing[2],LCopy(EditRunway)).	//add runway to list, Lcopy to break referencing
	SET Editing[0] TO True.					//if before it was new, now you are editing
	SET Editing[1] TO Editing[2].			//set previous name to new name

	RunwaysRefresh().		//refresh the popupmenu
	RunwaysSave(Runways).	//save to the file
},lexicon("color",green,"hstretch",true,"height",16)).



LOCAL DisplayButton IS MkButton(SaveLine,"Display Arrows",{
	parameter val.
	SET P1Vec:show TO val.
	SET P2Vec:show TO val.
	SET P12Vec:show TO val.
	SET P21Vec:show TO val.
},lexicon("color",white,"hstretch",true,"toggle",true,"height",16)).
SET DisplayButton:pressed TO true.



//initialization of the mode - executes once when GO button pressed
function Init {
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
	
	SET RunState["PanelSubState"] TO 0. //make these change together
	SET Runways TO RunwaysLoad().
	RightPanelRefresh().
	SET P1Vec:show TO DisplayButton:pressed.
	SET P2Vec:show TO DisplayButton:pressed.
	SET P12Vec:show TO DisplayButton:pressed.
	SET P21Vec:show TO DisplayButton:pressed.
	SET RunwaySelect:options TO Runways:keys.
	
	WHEN NOT (RunState["PanelMode"] = "Runways") THEN {	//hide vectors if you change panels
		SET P1Vec:show TO false.
		SET P2Vec:show TO false.
		SET P12Vec:show TO false.
		SET P21Vec:show TO false.
	}	
	
}

function Display {
	return "Plane:Runway Mark".
}

RegisterMode("Plane","Runways",Init@,Main@,End@,SB,MB,PanelInit@,ModeInfo,Display@).
print "Plane: Runways loaded.".
} //#close

