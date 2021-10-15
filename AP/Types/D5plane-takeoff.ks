@LAZYGLOBAL OFF.
//Mode Takeoff - #open
//initialize mode
{
//Stats about the mode (mostly helpful for Sequencer
LOCAL ModeInfo IS ModeInfoInit().
SET ModeInfo["Active"] TO false.
SET ModeInfo["Ends"] TO true.

//add necessary variables here as local. They will be accesible 
//in the functions without passing them
LOCAL PanelSubState IS lexicon("TOFunc",{}
							,"UseRunway",true
							,"Target","None"
							,"ClimbHeight",500
							,"AGL",true).
LOCAL BottomBoundHeight IS 0.
LOCAL AltChecker IS {return false.}.

function FindNearestRunway {
	LOCAL NearestRunwayName IS 0.
	LOCAL NearestRunway IS 0.
	LOCAL Distance1 IS 0.
	SET Runways TO RunwaysLoad().
	IF Runways:length < 1 {	//no runways marked - can't go
		return -1.
	} ELSE {
		//find nearest runway (by the ends), will work weird if there are crossing runways
		SET NearestRunwayName TO Runways:keys[0].
		SET Distance1 TO Runways[NearestRunwayName]["P1"]:position:mag.
		FOR runway1 IN Runways:keys {
			//see if runway is closer
			LOCAL RunwayDist IS min(Runways[runway1]["P1"]:position:mag,Runways[runway1]["P2"]:position:mag).
			IF RunwayDist < Distance1 {
				SET NearestRunwayName TO runway1.
				SET Distance1 TO RunwayDist.
			}
		}
		return list(NearestRunwayName,LCopy(Runways[NearestRunwayName])).
	}
}

function GetRunwayDist {
	parameter NearestRunway.
	//determine if closest to one end, or if closest to middle
	LOCAL RunwayVec IS NearestRunway["P2"]:position-NearestRunway["P1"]:position.
	//closest to P1
	IF (vang(NearestRunway["P1"]:position,RunwayVec) < 90) {
		return NearestRunway["P1"]:position:mag.
	//closest to P2
	} ELSE IF (vang(NearestRunway["P2"]:position,-1*RunwayVec) < 90) {
		return NearestRunway["P2"]:position:mag.
	//closest to between them
	} ELSE {
		return vxcl(RunwayVec,NearestRunway["P1"]:position):mag.
	}

}

function GetRunwayEndAngle {	//returns a list of the endpoint and the angle
	parameter NearestRunway.
	LOCAL EndVals IS list("None",180).
	IF NearestRunway["TakeOff21"] {
		SET EndVals[1] TO abs(NearestRunway["P1"]:bearing).
		SET EndVals[0] TO "P1".
	}
	IF NearestRunway["TakeOff12"] AND (abs(NearestRunway["P2"]:bearing) < EndVals[1]) {
			SET EndVals[1] TO abs(NearestRunway["P2"]:bearing).
			SET EndVals[0] TO "P2".
	}
	return EndVals.
}

function FindTargetEnd {
	parameter NearestRunwayName, EndName.
	return list(NearestRunwayName,EndName).
}

function GetTargetRunway {
	LOCAL NearestRunway IS FindNearestRunway().
	LOCAL EndAngle IS GetRunwayEndAngle(NearestRunway[1]).
	return FindTargetEnd(NearestRunway[0],EndAngle[0]).
}

function GetTargetNoRunway {
	return list("",0).
}

function TOPanelUpdate {	//update button states, PanelFunc, 
	SET ClimbHeightInput:text TO PanelSubState["ClimbHeight"]:tostring.
	SET UseRunwayButton:pressed TO PanelSubState["UseRunway"].
	SET TakeoffAnywhereButton:pressed TO NOT(PanelSubState["UseRunway"]).
	SET AGLButton:pressed TO PanelSubState["AGL"].
	SET ASLButton:pressed TO NOT(PanelSubState["AGL"]).
	
	IF PanelSubState["UseRunway"] {	//check if should use runway or not
		SET PanelFunc TO {
			//check if still in the right Panel
			IF RunState["PanelMode"] <> "Takeoff" OR RunState["PanelType"] <> "Plane" {
				SET PanelFunc TO {}.
				return.	//end the function call here
			}
		
			//check if on the ground
			IF NOT (ship:status = "LANDED" OR ship:status = "SPLASHED" OR ship:status = "PRELAUNCH") {
				SET StatusText:text TO "Not on the ground.".
				SET StatusText2:text TO "".
				SET GoButton:enabled TO false.
			} ELSE {
				LOCAL NearestRunway IS FindNearestRunway().
				LOCAL Distance1 IS GetRunwayDist(NearestRunway[1]).
		
				//if not close enough, update status as needed
				IF Distance1 > 10 {
					SET StatusText:text TO "Not on runway. Get within 10 meters.".
					SET StatusText2:text TO "Nearest Runway - "+NearestRunway[0]+": "+Round(Distance1,0)+"m".
					SET GoButton:enabled TO false.
				//if close enough, see if bearing is right
				} ELSE {
					
					LOCAL EndVals IS GetRunwayEndAngle(NearestRunway[1]).
					//if angle is low enough, update status and enable go
					IF EndVals[1] < 5 {
						SET GoButton:enabled TO true.
						SET StatusText:text TO "Lined up on runway: "+NearestRunway[0].
						SET StatusText2:text TO "".
						// SET PanelSubState["Target"] TO FindTargetEnd(NearestRunway[0],EndVals[0]).
					} ELSE {
						SET GoButton:enabled TO false.
						SET StatusText:text TO "On Runway "+NearestRunway[0]+". Align within 5 degrees.".
						SET StatusText2:text TO "Vessel misaligned by: "+round(EndVals[1],1)+" deg".
					}
				}
			}
		}.
	} ELSE {	//userunway is false
		//check if on the ground
		SET PanelFunc TO {
			IF NOT (ship:status = "LANDED" OR ship:status = "SPLASHED" OR ship:status = "PRELAUNCH") {
				SET StatusText:text TO "Not on the ground.".
				SET StatusText2:text TO "".
				SET GoButton:enabled TO false.
			} ELSE {// good to go
				SET GoButton:enabled TO true.
				SET StatusText:text TO "<b>Status: Ready to takeoff!</b>".
				SET StatusText2:text TO "".
				// SET PanelSubState["Target"] TO GetTargetNoRunway().
			}
		}.
	}
}

LOCAL DoAccelStart IS {
	IF RunState["SubState"]["UseRunway"] { //get target
		SET Runstate["SubState"]["Target"] TO GetTargetRunway().
	} ELSE { SET Runstate["SubState"]["Target"] TO GetTargetNoRunway().	}
		
	SET TakeOffStatus:text TO "Accelerating down runway.".
	LOCAL TargetPoint IS Runstate["SubState"]["Target"].
	LOCAL OtherPoint IS 0.	//other point for extending
	IF TargetPoint[0] = "" {	//not a runway
		SET Runstate["SubState"]["Target"] TO ship:body:geopositionof(ship:facing:forevector*10000).
	} ELSE { //use runway
		//get target end and other end in vectors
		IF TargetPoint[1] = "P1" {SET OtherPoint TO Runways[TargetPoint[0]]["P2"]:position.}
		ELSE {SET OtherPoint TO Runways[TargetPoint[0]]["P1"]:position.}
		SET TargetPoint TO Runways[TargetPoint[0]][TargetPoint[1]]:position.	//convert from list of runway, pointname to geoposition
		LOCAL RunwayVec IS (TargetPoint - OtherPoint):normalized.
		//set it to a point 1000 meters beyond the end of the runway
		SET Runstate["SubState"]["Target"] TO ship:body:geopositionof(TargetPoint+(RunWayVec*1000)).
	}
	
	FlightInit().
	FlapsAdjust(2).	//flaps to 2 for takeoff
	
	SET RunState["SubState"]["TOFunc"] TO DoAccel.
	SET Brakes TO false.
}.

LOCAL DoAccel IS {
	//fly with no pitch, steer at target
	FlightUpdate(lexicon("PitchMode","Pitch"
						,"PitchSetting",0
						,"HeadingMode","Lat.Lng."
						,"HeadingSetting",Runstate["SubState"]["Target"]
						,"ThrottleMode","Throttle"
						,"ThrottleSetting",1)).
	//wheelsteer also (divided by speed so it isn't too strong
	SET ship:control:wheelsteer TO -Runstate["SubState"]["Target"]:bearing/(ship:velocity:surface:mag+1).
	IF ship:velocity:surface:mag > PlaneStats["LandingSpeed"] {
		SET ship:control:wheelsteer TO 0.
		SET RunState["SubState"]["TOFunc"] TO DoLiftoff.
		SET BottomBoundHeight TO alt:radar - ship:bounds:bottomaltradar.
		//set altitude checker for next step
		IF RunState["SubState"]["AGL"] {SET AltChecker TO {return alt:radar > RunState["SubState"]["ClimbHeight"].}.}
		ELSE {SET AltChecker TO {return alt:radar > RunState["SubState"]["ClimbHeight"].}.}
		SET TakeOffStatus:text TO "Taking Off".
	}
	//if velocity is > stallspeed * 1.3 - set func to rotate
}.

LOCAL DoLiftoff IS {
	FlightUpdate(lexicon("PitchMode","Pitch"
					,"PitchSetting",PlaneStats["TakeOffPitch"]
					,"HeadingMode","Bank"
					,"HeadingSetting",0
					,"ThrottleMode","Speed"
					,"ThrottleSetting",PlaneStats["CruiseSpeed"])).
	
	//if off the ground and above noflaps stall speed, retract flaps and gear
	IF (alt:radar - BottomBoundHeight) > 20 {
		SET Gear TO false.
		SET TakeOffStatus:text TO "Climbing to "+RunState["SubState"]["ClimbHeight"]+"m".//+ CHOOSE "AGL" IF RunState["SubState"]["AGL"] ELSE "ASL".
	}
	
	//retract flaps when above noflaps stall speed
	IF ship:velocity:surface:mag > PlaneStats["StallSpeed"]*1.1 {FlapsAdjust(0).}
	
	//end climb mode
	IF AltChecker() {
		SET RunState["Other"] TO "End".
		FlapsAdjust(0).	//just incase
	}
}.

//Status panel
LOCAL SB to StatusBox:addstack().
LOCAL SB2 TO MkBox(SB,"VB",lexicon("width",300,"height",80,"padding",OBPad)).
MkLabel(SB2,"TakeOff",lexicon("fontsize",15,"width",200)).

//takeoff status description
LOCAL TakeOffStatus TO MkLabel(SB2,"Initializing",lexicon("hstretch",true)).

//Main Panel
LOCAL MB to ModeControl:addstack().
LOCAL MB2 TO MkBox(MB,"VB",lexicon("width",300,"height",200,"padding",OBPad)).

//status and description
LOCAL PanelStatusB IS MkBox(MB2,"VB",lexicon("width",300,"height",120,"padding",OBPad)).
MkLabel(PanelStatusB,"This will takeoff and climb to the set height.",lexicon("Width",300,"marginv",2)).
MkLabel(PanelStatusB,"<b>Use Runway</b>: You must be on and aligned with a marked runway.",lexicon("Width",300,"height",25)).
MkLabel(PanelStatusB,"<b>Takeoff Here</b>: It will takeoff in the direction the craft is currently facing.",lexicon("Width",300,"height",25)).
PanelStatusB:addspacing(5).
LOCAL StatusText IS MkLabel(PanelStatusB,"Status: Initializing",lexicon("width",300,"fontsize",12,"color",white)).
LOCAL StatusText2 IS MkLabel(PanelStatusB,"",lexicon("width",300,"fontsize",12,"color",white)).

//inputs
LOCAL TakeoffOptions IS MkBox(MB2,"VB",lexicon("width",300,"height",80,"padding",OBPad)).

//use runway selection
LOCAL UseRunwayBox IS MkBox(TakeoffOptions,"HB",lexicon("width",300,"padding",OBPad)).
LOCAL UseRunwayButton IS MkButton(UseRunwayBox,"Use Runway",{
			parameter val.
			SET PanelSubState["UseRunway"] TO val.
			TOPanelUpdate().
		},lexicon("toggle",true,"width",100,"height",20)).
SET UseRunwayButton:exclusive TO true.

LOCAL TakeoffAnywhereButton IS MkButton(UseRunwayBox,"Takeoff Here",{
			parameter val.	//everything should happen when UseRunway button is set due to exclusive
			SET PanelSubState["UseRunway"] TO NOT(val).
			TOPanelUpdate().
		},lexicon("toggle",true,"width",100,"height",20)).
SET TakeoffAnywhereButton:exclusive TO true.

//climb altitude selection
LOCAL ClimbBox is MkBox(TakeoffOptions,"HB",lexicon("width",300,"padding",OBPad)).
MkLabel(ClimbBox,"Climb to:",lexicon("width",50,"align","RIGHT","height",18,"paddingv",2)).
LOCAL ClimbHeightInput IS MkTextInput(ClimbBox,PanelSubState,"ClimbHeight"
	,lexicon("width",75,"height",18,"numformat",true)).
LOCAL AGLButton IS MkButton(ClimbBox,"AGL",{
			parameter val.
			SET PanelSubState["AGL"] TO val.
			TOPanelUpdate().
		},lexicon("toggle",true,"width",50,"height",20)).
SET AGLButton:exclusive TO true.
LOCAL ASLButton IS MkButton(ClimbBox,"ASL",{
			parameter val.
			SET PanelSubState["AGL"] TO NOT(val).
			TOPanelUpdate().
		},lexicon("toggle",true,"width",50,"height",20)).
SET ASLButton:exclusive TO true.


function Init {	//update
	StatusBox:showonly(SB).  //change the status box
	SET RunState["SubState"]["TOFunc"] TO DoAccelStart.
}

//main loop - executes every time through
function Main {
	RunState["SubState"]["TOFunc"]().
}

//function ending the mode - executes once when GO button pressed and this is the current mode
function End {

}

//PanelInit 
function PanelInit {
	parameter temp1. //state to set PanelSubState to, -99 means don't change
		
	IF temp1 <> -99 
	{	SET PanelSubState TO LCopy(temp1).	}
	SET RunState["PanelSubState"] TO PanelSubState. //make these change together
	
	TOPanelUpdate().	//update buttons, text, and PanelFunc	
}

function Display {
	IF PanelSubState["UseRunway"] {	return "Pl: TakeOff-Runway "+NumFormat(PanelSubState["ClimbHeight"],1).
	} ELSE { return "Pl: TakeOff-Free "+NumFormat(PanelSubState["ClimbHeight"],1).}
	
}

RegisterMode("Plane","Takeoff",Init@,Main@,End@,SB,MB,PanelInit@,ModeInfo,Display@).

Print "Plane: Takeoff loaded.".
} //#close