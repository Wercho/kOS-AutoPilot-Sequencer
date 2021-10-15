//Mode Rocket Launch - #open
{
//Stats about the mode (mostly helpful for Sequencer
LOCAL ModeInfo IS ModeInfoInit().
SET ModeInfo["Ends"] TO TRUE.
SET ModeInfo["Active"] TO FALSE.

//#open - variables
LOCAL PanelSubState TO PanelDefaults().
//launchers					name		start function
LOCAL Launchers TO lexicon("Generic",	Start_Default@
							).
LOCAL LaunchFunc TO {}.
//#close - variables


//#open - functions
function PanelDefaults {
	parameter PanelSS IS lexicon().
	
	LOCAL ReturnSS TO lexicon(	"Launcher","Generic" 	//launcher
								,"UseTarget",false
								,"Apoapsis",100000
								,"Periapsis",0
								,"Circular",true
								,"Incl",0		//inclination
								,"UseLOAN",false
								,"LOAN",0		//longitude of ascending node
								).
								
	FOR i IN ReturnSS:keys {
		IF PanelSS:haskey(i) {SET ReturnSS[i] TO PanelSS[i].}	//set to already existing stats, ignore stats no longer used
	}
	return ReturnSS.	//LCopy to preserve referencing
}
//#close - functions

//flight functions at end

//#open - panel function
function UpdatePanel {	//updates the panel (called when a button is pressed, mostly)
	SET LauncherSelect:options TO Launchers:keys.
	SetPopupIndex(LauncherSelect,PanelSubState["Launcher"]).

	CheckValidTarget().	//checks for valid target, and sets things accordingly
	
	// CheckApoPeri().	//swaps values if apo greater than peri
	
	SET ApoField:text TO NF(3,"",false,PanelSubState["Apoapsis"]).
	SetPeri().	//checks for circular, sets accordingly
	SET InclField:text TO NF(3,"",false,PanelSubState["Incl"]).
	SetLOAN().	//checks for use, sets accordingly
}

function CheckValidTarget {
	IF HASTARGET {	//if it has a target, then show target orbit stats
		IF TARGET:HASBODY AND (TARGET:body = ship:body) {	//if target is orbiting same body, set to target
			SetTarget().
			SET TargetStatus:text TO "Target: "+TARGET:name.
		} ELSE {	
			SET TargetStatus:text TO "Target must orbit "+ship:body:name+".".
		}
	} ELSE { 
		SET TargetStatus:text TO "No target selected".
	}
	SET PanelSubState["Target"] TO false.	//update and then back to false
}

function SetTarget {	//shows appropriate fields, and sets target values
	IF PanelSubState["UseTarget"] {
		//set text to target values
		SET PanelSubState["Apoapsis"] TO TARGET:OBT:periapsis.
		SET PanelSubState["Periapsis"] TO TARGET:OBT:periapsis.
		SET PanelSubState["Incl"] TO TARGET:OBT:inclination.
		SET PanelSubState["LOAN"] TO TARGET:OBT:lan.
		SET PanelSubState["UseLOAN"] TO true.
		SET PanelSubState["Circular"] TO true.	//always go for circular with targets
	}
}

function CheckApoPeri {
	IF PanelSubState["Apoapsis"] < PanelSubState["Periapsis"] {
		LOCAL temp1 TO PanelSubState["Apoapsis"].
		SET PanelSubState["Apoapsis"] TO PanelSubState["Periapsis"].
		SET PanelSubState["Periapsis"] TO temp1.
	}
}

function SetPeri {
	SET CircButton:pressed TO PanelSubState["Circular"].
	IF PanelSubState["Circular"] {
		SET PanelSubState["Periapsis"] TO PanelSubState["Apoapsis"].
		SET PeriField:enabled TO false.
		SET PeriField:text TO NF(3,"",false,PanelSubState["Periapsis"]).
	} ELSE {
		SET PeriField:enabled TO true.
	}
}

function SetLOAN {
	//if target, then SetTarget handles it, else
	//set visibility
	SET LOANField:visible TO PanelSubState["UseLOAN"].	
	SET LOANLabel:visible TO NOT(PanelSubState["UseLOAN"]).
	SET LOANLabel:text TO "Any".	//set label to this value (only different if target)
}

//#close - panel function

//initialize mode
function Init {
	SET LaunchFunc TO Launchers[PanelSubState["Launcher"]].
}

//main loop
function Main {
	LaunchFunc().
}

//end function
function End {
}


//Status panel
LOCAL SB to StatusBox:addstack().
LOCAL SB2 TO MkBox(SB,"VB",lexicon("width",300,"height",80,"padding",OBPad)).
MkLabel(SB2,"<b>Status: Launching</b>",lexicon("fontsize",15,"width",200)).
//landing status description
LOCAL LaunchStatus1 TO MkLabel(SB2,"Initializing",lexicon("hstretch",true)).


//Main Panel #open
LOCAL Bwid TO 96.	//width of buttons
LOCAL Fwid TO 96.	//width of field entry blocks
LOCAL MB to ModeControl:addstack().
LOCAL MB2 TO MkBox(MB,"VB",lexicon("width",300,"height",200,"padding",IBPad)).

//select launcher - default to generic
LOCAL LauncherLine IS MkBox(MB2,"HL",lexicon("width",294,"padding",OBPad)).
MkLabel(LauncherLine,"Launcher:",lexicon("width",Bwid,"height",20,"align","RIGHT")).

LOCAL LauncherSelect IS MkPopup(LauncherLine,0,20,lexicon("hstretch",true)).
SET LauncherSelect:index TO -1.
SET LauncherSelect:onchange TO {
	parameter val.
	SET PanelSubState["Launcher"] TO val.
}.

//set Apo and Periapsis
LOCAL ApoLine TO MkBox(MB2,"HL",lexicon("width",294,"padding",OBPad)).
MkLabel(ApoLine,"Apoapsis:",lexicon("width",Bwid,"height",20,"align","RIGHT")).
LOCAL ApoField TO MkTextInput(ApoLine,PanelSubState,"Apoapsis",lexicon("height",20,"width",Fwid,"numformat",true,"addfunc",{parameter s. 
	SET PanelSubState["Apoapsis"] TO NumParse(s,PanelSubState["Apoapsis"]).
	UpdatePanel().})).

LOCAL PeriLine TO MkBox(MB2,"HL",lexicon("width",294,"padding",OBPad)).
MkLabel(PeriLine,"Periapsis:",lexicon("width",Bwid,"height",20,"align","RIGHT")).
LOCAL PeriField TO MkTextInput(PeriLine,PanelSubState,"Periapsis",lexicon("height",20,"width",Fwid,"numformat",true,"addfunc",{parameter s. 
	SET PanelSubState["Periapsis"] TO NumParse(s,PanelSubState["Periapsis"]).
	UpdatePanel().})).
LOCAL CircButton TO MkButton(PeriLine,"Circular",{
		parameter val.
		SET PanelSubState["Circular"] TO val.
		UpdatePanel().
	},lexicon("width",Bwid,"height",20,"toggle",true)).

//set Inclination
LOCAL InclLine TO MkBox(MB2,"HL",lexicon("width",294,"padding",OBPad)).
MkLabel(InclLine,"Inclination:",lexicon("width",Bwid,"height",20,"align","RIGHT")).
LOCAL InclField TO MkTextInput(InclLine,PanelSubState,"Incl",lexicon("height",20,"width",Fwid,"numformat",true,"addfunc",{parameter s. 
	SET PanelSubState["Incl"] TO NumParse(s,PanelSubState["Incl"]).
	UpdatePanel().})).

//set Longitude of ascending node
LOCAL LOANLine TO MkBox(MB2,"HL",lexicon("width",294,"padding",OBPad)).
LOCAL LOANButton TO MkButton(LOANLine,"LongOfAscNode:",{
		parameter val.
		SET PanelSubState["UseLOAN"] TO val.
		UpdatePanel().
	},lexicon("width",Bwid,"height",20,"toggle",true,"align","RIGHT")).
LOCAL LOANField TO MkTextInput(LOANLine,PanelSubState,"LOAN",lexicon("height",20,"width",Fwid,"numformat",true,"addfunc",{parameter s. 
	SET PanelSubState["LOAN"] TO NumParse(s,PanelSubState["LOAN"]).
	UpdatePanel().})).
LOCAL LOANLabel TO MkLabel(LOANLine,NF(3,"",false,PanelSubState["LOAN"]),lexicon("height",20,"width",Fwid,"numformat",true)).

//align to target target
MB2:addspacing(5).
LOCAL TargetLine IS MkBox(MB2,"HL",lexicon("width",294,"padding",OBPad)).
LOCAL TargetButton IS MkButton(TargetLine,"Align to Target",{
		SET PanelSubState["Target"] TO true.
		UpdatePanel().
	},lexicon("width",Bwid,"height",20)).
LOCAL TargetStatus TO MkLabel(TargetLine,"Default",lexicon("width",300-Bwid,"height",20)).


//Main panel #close

//PanelInit 
function PanelInit {
	parameter temp1. //state to set PanelSubState to, -99 means don't change
	IF temp1 <> -99 
	{	SET PanelSubState TO LCopy(temp1).	}
	SET PanelSubState TO LCopy(PanelDefaults(PanelSubState)).
	
	SET RunState["PanelSubState"] TO PanelSubState. //make these change together

	UpdatePanel().

}

function Display {
	return "Rocket:Launch".
}

RegisterMode("Rocket","Launch",Init@,Main@,End@,SB,MB,PanelInit@,ModeInfo,Display@).
print "Rocket: Launch loaded.".

//Generic Launcher #open
function Start_Default {
	print "Generic Launch".
}
//Generic #close




}
//#close
