@LAZYGLOBAL OFF.

{ //Mode Basic - #open
//initialize mode
//Stats about the mode
LOCAL ModeInfo IS ModeInfoInit().

//add necessary variables here as local. They will be accesible 
//in the functions without passing them

LOCAL PanelSubState IS lexicon("PitchMode","Altitude","PitchSetting",PlaneStats["AltCruise"],"HeadingMode","Bank","HeadingSetting",0,"ThrottleMode","Throttle","ThrottleSetting",1).
LOCAL PitchVals IS list(  
//0-name, 1-starting value,	2-change increment, 3-include entry field and buttons, 4-include zero button (current if false),5-limit values, 6-value for current, 7-minvalue, 8-maxvalue
		//0			1						2	3		4		5		6									7									8
	list("None"		,""						,0	,false),
	list("Altitude"	,PlaneStats["AltCruise"],100,true	,false	,false	,{return round(ship:altitude).}),
	list("Pitch"	,0						,1	,true	,true	,true	,0									,{return PlaneStats["PitchMin"].}	,{return PlaneStats["PitchMax"].}),
	list("Vert.Vel.",0						,1	,true	,true	,true	,0									,{return PlaneStats["VertVelMin"].}	,{return PlaneStats["VertVelMax"].}),
	list("AoA"		,0						,1	,true	,true	,true	,0									,{return -1*PlaneStats["PitchAoAMax"].},{return PlaneStats["PitchAoAMax"].})).
LOCAL HeadingVals IS list(  //name, starting value, change increment, include entry field and buttons, include zero button (current if false), value for current
	list("None"		,""						,0	,false),
	list("Bank"		,0						,1	,true	,true	), //special code to limit to MaxBank angle from PlaneStats
	list("Heading"	,0						,1	,true	,false	,{return round(ShipHead(),1).}), //special code to limit to 0-360 degrees
	list("Lat.Lng."	,latlng(0,0)			,0	,false)).  //special code for entry of lat/lng
LOCAL ThrottleVals IS list(  //name, starting value, change increment, include entry field and buttons, include zero button (current if false), value for current
	list("None"		,""						,0	,false),
	list("Speed"	,200					,10	,true	,false	,{return round(ship:velocity:surface:mag,0).}),
	list("Throttle"	,1						,0.05,true	,true)). //special code below to limit to 0-1 range
// LOCAL Active1 IS {return (RunState["Other"] = "Active").}.  //used to check this inside onclick and onconfirm functions (needed to get fresh values, otherwise it is evaluated at the time the onclick function is created

function UpdatePanel { //update button states and fields to match PanelSubState
	ExclBut(PitchButtons,PanelSubState["PitchMode"]).
	IF NOT(PanelSubState["PitchMode"] = "None") 
		{SET PitchFields[PanelSubState["PitchMode"]]:text TO NumFormat(PanelSubState["PitchSetting"],99).}

	ExclBut(HeadingButtons,PanelSubState["HeadingMode"]).
	IF PanelSubState["HeadingMode"] = "Lat.Lng." {
		SET HeadingFields[PanelSubState["HeadingMode"]][0]:text TO PanelSubState["HeadingSetting"]:lat:tostring.
		SET HeadingFields[PanelSubState["HeadingMode"]][1]:text TO PanelSubState["HeadingSetting"]:lng:tostring.
	} ELSE {
		SET HeadingFields[PanelSubState["HeadingMode"]]:text TO NumFormat(PanelSubState["HeadingSetting"],99).
	}
	
	ExclBut(ThrottleButtons,PanelSubState["ThrottleMode"]).
	IF NOT(PanelSubState["ThrottleMode"] = "None")
		{SET ThrottleFields[PanelSubState["ThrottleMode"]]:text TO PanelSubState["ThrottleSetting"]:tostring.}
}


//Status panel - #open
LOCAL SB to StatusBox:addstack().
LOCAL SB2 TO MkBox(SB,"VB",lexicon("width",300,"height",80,"padding",OBPad)).
MkLabel(SB2,"Basic Control",lexicon("fontsize",15,"width",200)).

//pitch control status
LOCAL PitchInfo TO MkBox(SB2,"HB",lexicon("width",300,"padding",OBPad)).
LOCAL PitchModeInfo TO MkLabel(PitchInfo,PanelSubState["PitchMode"],lexicon("fontsize",12,"width",80)).
LOCAL PitchSettingInfo TO MkLabel(PitchInfo,PanelSubState["PitchSetting"],lexicon("fontsize",12,"width",150)).
//heading control status
LOCAL HeadingInfo TO MkBox(SB2,"HB",lexicon("width",300,"padding",OBPad)).
LOCAL HeadingModeInfo TO MkLabel(HeadingInfo,PanelSubState["HeadingMode"],lexicon("fontsize",12,"width",80)).
LOCAL HeadingSettingInfo TO MkLabel(HeadingInfo,PanelSubState["HeadingSetting"],lexicon("fontsize",12,"width",150)).
//throttle control status
LOCAL ThrottleInfo TO MkBox(SB2,"HB",lexicon("width",300,"padding",OBPad)).
LOCAL ThrottleModeInfo TO MkLabel(ThrottleInfo,PanelSubState["ThrottleMode"],lexicon("fontsize",12,"width",80)).
LOCAL ThrottleSettingInfo TO MkLabel(ThrottleInfo,PanelSubState["ThrottleSetting"],lexicon("fontsize",12,"width",150)).
// #close 

//Main Panel - #open
LOCAL MB to ModeControl:addstack().
LOCAL MB1 TO MkBox(MB,"HL",lexicon("width",300,"height",200,"padding",OBPad)).
LOCAL MB2 TO MkBox(MB1,"VL",lexicon("width",150,"height",200,"padding",OBPad)).

LOCAL bwid IS 45. //button width
LOCAL rowhei IS 20. //row height

//box for pitch controls #open
LOCAL PitchPanelA TO MkBox(MB2,"VB",lexicon("width",150,"height",120,"padding",IBPad)).
MkLabel(PitchPanelA,"Pitch Control:",lexicon("fontsize",12,"align","CENTER")).
//make pitch buttons and entry
LOCAL PitchButtons TO lexicon().
LOCAL PitchFields TO lexicon().

FOR i IN RANGE(0,PitchVals:length,1) {
	LOCAL temp1 IS i. //do this to prevent stuff from changing when i changes in the next round of loop
	LOCAL EntryLine TO MkBox(PitchPanelA,"HL",lexicon("height",rowhei,"padding",OBPad)). //create the horizontal box to put the buttons in
	//make pitch button
	PitchButtons:add(PitchVals[temp1][0],MkButton(EntryLine,PitchVals[temp1][0],
		{	parameter val. 
			IF val {
				SET PanelSubState["PitchMode"] TO PitchVals[temp1][0].   //set the mode and setting
				SET PanelSubState["PitchSetting"] TO PitchVals[temp1][1].
				ExclBut(PitchButtons,PanelSubState["PitchMode"]).
				IF RunState["Other"] = "Active" { //if active, also set the window
					SET PitchModeInfo:text TO PanelSubState["PitchMode"].
					SET PitchSettingInfo:text TO NumFormat(PanelSubState["PitchSetting"],99).
				}
			} 
		}
		, lexicon("toggle",true,"width",bwid,"height",rowhei-2))).
		
	//make entryfield and +/- buttons
	IF NOT PitchVals[temp1][3] { //if it shouldn't show entry field, don't create anything
		MkLabel(EntryLine,"").
	} ELSE {	//create entryfield and adjustment buttons
		PitchFields:add(PitchVals[temp1][0],MkTextInput(EntryLine,PitchVals[temp1],1,lexicon("height",rowhei-2
			,"width",57,"numformat",true))).
		SET PitchFields[PitchVals[temp1][0]]:onconfirm TO { parameter s.
			SET PitchVals[temp1][1] TO NumParse(s,PitchVals[temp1][1]).
			SET PitchFields[PitchVals[temp1][0]]:text TO NumFormat(PitchVals[temp1][1],99).
			IF PanelSubState["PitchMode"] = PitchVals[temp1][0] {
				SET PanelSubState["PitchSetting"] TO PitchVals[temp1][1].
				IF RunState["Other"] = "Active" {SET PitchSettingInfo:text TO NumFormat(PanelSubState["PitchSetting"],99).}
			}
		}.
		LOCAL minus TO MkButton(EntryLine,"-", 
			{	SET PitchVals[temp1][1] TO PitchVals[temp1][1] - PitchVals[temp1][2].
				SET PitchFields[PitchVals[temp1][0]]:text TO NumFormat(PitchVals[temp1][1],99).
				IF PanelSubState["PitchMode"] = PitchVals[temp1][0] {
					SET PanelSubState["PitchSetting"] TO PitchVals[temp1][1].
					IF RunState["Other"] = "Active" {SET PitchSettingInfo:text TO NumFormat(PanelSubState["PitchSetting"],99).}
				}
			}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).
		IF PitchVals[temp1][4] {
			LOCAL zero TO MkButton(EntryLine,"0", 
				{	SET PitchVals[temp1][1] TO 0.
					SET PitchFields[PitchVals[temp1][0]]:text TO NumFormat(PitchVals[temp1][1],99).
					IF PanelSubState["PitchMode"] = PitchVals[temp1][0] {
						SET PanelSubState["PitchSetting"] TO PitchVals[temp1][1].
						IF RunState["Other"] = "Active" {SET PitchSettingInfo:text TO NumFormat(PanelSubState["PitchSetting"],99).}
					}
				}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).
			SET zero:style:margin:h TO 1.
		} ELSE {
			LOCAL curr TO MkButton(EntryLine,"C", 
				{	SET PitchVals[temp1][1] TO PitchVals[temp1][6]().
					SET PitchFields[PitchVals[temp1][0]]:text TO NumFormat(PitchVals[temp1][1],99).
					IF PanelSubState["PitchMode"] = PitchVals[temp1][0] {
						SET PanelSubState["PitchSetting"] TO PitchVals[temp1][1].
						IF RunState["Other"] = "Active" {SET PitchSettingInfo:text TO NumFormat(PanelSubState["PitchSetting"],99).}
					}
				}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).
			SET curr:style:margin:h TO 1.
		}
		LOCAL plus TO MkButton(EntryLine,"+", 
			{	SET PitchVals[temp1][1] TO PitchVals[temp1][1] + PitchVals[temp1][2].
				SET PitchFields[PitchVals[temp1][0]]:text TO NumFormat(PitchVals[temp1][1],99).
				IF PanelSubState["PitchMode"] = PitchVals[temp1][0] {
					SET PanelSubState["PitchSetting"] TO PitchVals[temp1][1].
					IF RunState["Other"] = "Active" {SET PitchSettingInfo:text TO NumFormat(PanelSubState["PitchSetting"],99).}
				}
			}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).
		SET plus:style:margin:h TO 1.
		
		IF PitchVals[temp1][5] { //if the values should be limited to the max range, then reset the button click and textfield actions to do that
			SET PitchFields[PitchVals[temp1][0]]:onconfirm TO { parameter s.
				SET PitchVals[temp1][1] TO Limits(s:tonumber(PitchVals[temp1][1]),PitchVals[temp1][7](),PitchVals[temp1][8]()).
				SET PitchFields[PitchVals[temp1][0]]:text TO NumFormat(PitchVals[temp1][1],99).
				IF PanelSubState["PitchMode"] = PitchVals[temp1][0] {
					SET PanelSubState["PitchSetting"] TO PitchVals[temp1][1].
					IF RunState["Other"] = "Active" {SET PitchSettingInfo:text TO NumFormat(PanelSubState["PitchSetting"],99).}
				}
			}.
			SET minus:onclick TO {	SET PitchVals[temp1][1] TO max(PitchVals[temp1][1] - PitchVals[temp1][2],PitchVals[temp1][7]()).
				SET PitchFields[PitchVals[temp1][0]]:text TO NumFormat(PitchVals[temp1][1],99).
				IF PanelSubState["PitchMode"] = PitchVals[temp1][0] {
					SET PanelSubState["PitchSetting"] TO PitchVals[temp1][1].
					IF RunState["Other"] = "Active" {SET PitchSettingInfo:text TO NumFormat(PanelSubState["PitchSetting"],99).}
				}
			}.
			SET plus:onclick TO {	SET PitchVals[temp1][1] TO min(PitchVals[temp1][1] + PitchVals[temp1][2],PitchVals[temp1][8]()).
				SET PitchFields[PitchVals[temp1][0]]:text TO NumFormat(PitchVals[temp1][1],99).
				IF PanelSubState["PitchMode"] = PitchVals[temp1][0] {
					SET PanelSubState["PitchSetting"] TO PitchVals[temp1][1].
					IF RunState["Other"] = "Active" {SET PitchSettingInfo:text TO NumFormat(PanelSubState["PitchSetting"],99).}
				}
			}.
		}
	}
} // #close


//fill box for heading and throttle controls
LOCAL HeadingButtons TO lexicon().
LOCAL HeadingFields TO lexicon().

//heading control box
LOCAL HeadingPanelA TO MkBox(MB1,"VB",lexicon("width",150,"height",200,"padding",IBPad)).
MkLabel(HeadingPanelA,"Heading Control:",lexicon("fontsize",12,"align","CENTER")).
//make heading controls

//make Heading buttons and entry
FOR i IN RANGE(0,HeadingVals:length,1) {
	LOCAL temp1 IS i. //do this to prevent stuff from changing when i changes in the next round of loop
	LOCAL EntryLine TO MkBox(HeadingPanelA,"HL",lexicon("height",rowhei,"padding",OBPad)). //create the horizontal box to put the buttons in

	//make Heading button
	HeadingButtons:add(HeadingVals[temp1][0],MkButton(EntryLine,HeadingVals[temp1][0],
		{	parameter val. 
			IF val {
				SET PanelSubState["HeadingMode"] TO HeadingVals[temp1][0]. 
				SET PanelSubState["HeadingSetting"] TO HeadingVals[temp1][1].
				ExclBut(HeadingButtons,PanelSubState["HeadingMode"]).
				IF RunState["Other"] = "Active" { //if active, also set the window
					SET HeadingModeInfo:text TO PanelSubState["HeadingMode"].
					IF PanelSubState["HeadingMode"] = "Lat.Lng." {SET HeadingSettingInfo:text TO "("+PanelSubState["HeadingSetting"]:lat+","+PanelSubState["HeadingSetting"]:lng+")". 
					} ELSE {SET HeadingSettingInfo:text TO NumFormat(PanelSubState["HeadingSetting"],99).}
				}
			} 
		}
		, lexicon("toggle",true,"width",bwid,"height",rowhei-2))).
	SET HeadingButtons[HeadingVals[temp1][0]]:exclusive TO true.
		
	//make entryfield and +/- buttons
	IF HeadingVals[temp1][0] = "None" {
		MkLabel(EntryLine,"").
	} ELSE IF HeadingVals[temp1][0] = "Lat.Lng." { //special Lat Long code
		LOCAL LatLngScalar TO list(HeadingVals[temp1][1]:lat, HeadingVals[temp1][1]:lng).
		LOCAL LatEntry TO MkTextInput(EntryLine,LatLngScalar,0,lexicon("height",rowhei-2,"width",49)).
		LOCAL LngEntry TO MkTextInput(EntryLine,LatLngScalar,1,lexicon("height",rowhei-2,"width",49)).
		SET LatEntry:onconfirm TO {  //have to also change the lat,lng geocoordinates in addition to the scalar for editing
			parameter s.
			SET LatLngScalar[0] TO s:tonumber(LatLngScalar[0]).
			SET LatEntry:text TO LatLngScalar[0]:tostring.
			SET HeadingVals[temp1][1] TO latlng(LatLngScalar[0],LatLngScalar[1]).
			IF PanelSubState["HeadingMode"] = HeadingVals[temp1][0] {
				SET PanelSubState["HeadingSetting"] TO HeadingVals[temp1][1].
				IF RunState["Other"] = "Active" {SET HeadingSettingInfo:text TO "("+LatLngScalar[0]+","+LatLngScalar[1]+")".}
			}
		}.
		SET LngEntry:onconfirm TO {
			parameter s.
			SET LatLngScalar[1] TO s:tonumber(LatLngScalar[1]).
			SET LngEntry:text TO LatLngScalar[1]:tostring.
			SET HeadingVals[temp1][1] TO latlng(LatLngScalar[0],LatLngScalar[1]).
			IF PanelSubState["HeadingMode"] = HeadingVals[temp1][0] {
				SET PanelSubState["HeadingSetting"] TO HeadingVals[temp1][1].
				IF RunState["Other"] = "Active" {SET HeadingSettingInfo:text TO "("+LatLngScalar[0]+","+LatLngScalar[1]+")".}
			}
		}.
		HeadingFields:add(HeadingVals[temp1][0],list(LatEntry,LngEntry)).
	} ELSE {	//create entryfield and adjustment buttons
		HeadingFields:add(HeadingVals[temp1][0],MkTextInput(EntryLine,HeadingVals[temp1],1
			,lexicon("height",rowhei-2,"width",57,"numformat",true))).
		LOCAL minus TO MkButton(EntryLine,"-",{}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).

		IF HeadingVals[temp1][4] {
			LOCAL zero TO MkButton(EntryLine,"0", 
				{	SET HeadingVals[temp1][1] TO 0.
					SET HeadingFields[HeadingVals[temp1][0]]:text TO HeadingVals[temp1][1]:tostring.
					IF PanelSubState["HeadingMode"] = HeadingVals[temp1][0] {
						SET PanelSubState["HeadingSetting"] TO HeadingVals[temp1][1].
						IF RunState["Other"] = "Active" {SET HeadingSettingInfo:text TO NumFormat(PanelSubState["HeadingSetting"],99).}
					}
				}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).
		} ELSE {
			LOCAL curr TO MkButton(EntryLine,"C", 
				{	SET HeadingVals[temp1][1] TO HeadingVals[temp1][5]().
					SET HeadingFields[HeadingVals[temp1][0]]:text TO HeadingVals[temp1][1]:tostring.
					IF PanelSubState["HeadingMode"] = HeadingVals[temp1][0] {
						SET PanelSubState["HeadingSetting"] TO HeadingVals[temp1][1].
						IF RunState["Other"] = "Active" {SET HeadingSettingInfo:text TO NumFormat(PanelSubState["HeadingSetting"],99).}
					}
				}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).
		}
		LOCAL plus TO MkButton(EntryLine,"+",{}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).
		
		IF HeadingVals[temp1][0] = "Bank" {
			SET HeadingFields[HeadingVals[temp1][0]]:onconfirm TO { parameter s.
				LOCAL BankMax IS {return PlaneStats["BankMax"].}.
				SET HeadingVals[temp1][1] TO Limits(s:tonumber(HeadingVals[temp1][1]),-1*BankMax(),BankMax()).
				SET HeadingFields[HeadingVals[temp1][0]]:text TO HeadingVals[temp1][1]:tostring.
				IF PanelSubState["HeadingMode"] = HeadingVals[temp1][0] {
					SET PanelSubState["HeadingSetting"] TO HeadingVals[temp1][1].
					IF RunState["Other"] = "Active" {SET HeadingSettingInfo:text TO NumFormat(PanelSubState["HeadingSetting"],99).}
				}
			}.
			SET minus:onclick TO {	
				LOCAL BankMax IS {return PlaneStats["BankMax"].}.
				SET HeadingVals[temp1][1] TO max(HeadingVals[temp1][1] - HeadingVals[temp1][2],-1*BankMax()).
				SET HeadingFields[HeadingVals[temp1][0]]:text TO HeadingVals[temp1][1]:tostring.
				IF PanelSubState["HeadingMode"] = HeadingVals[temp1][0] {
					SET PanelSubState["HeadingSetting"] TO HeadingVals[temp1][1].
					IF RunState["Other"] = "Active" {SET HeadingSettingInfo:text TO NumFormat(PanelSubState["HeadingSetting"],99).}
				}
			}.
			SET plus:onclick TO {	
				LOCAL BankMax IS {return PlaneStats["BankMax"].}.
				SET HeadingVals[temp1][1] TO min(HeadingVals[temp1][1] + HeadingVals[temp1][2],BankMax()).
				SET HeadingFields[HeadingVals[temp1][0]]:text TO HeadingVals[temp1][1]:tostring.
				IF PanelSubState["HeadingMode"] = HeadingVals[temp1][0] {
					SET PanelSubState["HeadingSetting"] TO HeadingVals[temp1][1].
					IF RunState["Other"] = "Active" {SET HeadingSettingInfo:text TO NumFormat(PanelSubState["HeadingSetting"],99).}
				}
			}.
			
		} ELSE IF HeadingVals[temp1][0] = "Heading" {
			SET HeadingFields[HeadingVals[temp1][0]]:onconfirm TO { parameter s.
				SET HeadingVals[temp1][1] TO headingnormal(s:tonumber(HeadingVals[temp1][1])).
				SET HeadingFields[HeadingVals[temp1][0]]:text TO HeadingVals[temp1][1]:tostring.
				IF PanelSubState["HeadingMode"] = HeadingVals[temp1][0] {
					SET PanelSubState["HeadingSetting"] TO HeadingVals[temp1][1].
					IF RunState["Other"] = "Active" {SET HeadingSettingInfo:text TO NumFormat(PanelSubState["HeadingSetting"],99).}
				}
			}.
			SET minus:onclick TO {	
				SET HeadingVals[temp1][1] TO headingnormal(HeadingVals[temp1][1] - HeadingVals[temp1][2]).
				SET HeadingFields[HeadingVals[temp1][0]]:text TO HeadingVals[temp1][1]:tostring.
				IF PanelSubState["HeadingMode"] = HeadingVals[temp1][0] {
					SET PanelSubState["HeadingSetting"] TO HeadingVals[temp1][1].
					IF RunState["Other"] = "Active" {SET HeadingSettingInfo:text TO NumFormat(PanelSubState["HeadingSetting"],99).}
				}
			}.
			SET plus:onclick TO {	
				SET HeadingVals[temp1][1] TO headingnormal(HeadingVals[temp1][1] + HeadingVals[temp1][2]).
				SET HeadingFields[HeadingVals[temp1][0]]:text TO HeadingVals[temp1][1]:tostring.
				IF PanelSubState["HeadingMode"] = HeadingVals[temp1][0] {
					SET PanelSubState["HeadingSetting"] TO HeadingVals[temp1][1].
					IF RunState["Other"] = "Active" {SET HeadingSettingInfo:text TO NumFormat(PanelSubState["HeadingSetting"],99).}
				}
			}.
		}
	}
} // #close	


//throttle control box
LOCAL ThrottleButtons TO lexicon().
LOCAL ThrottleFields TO lexicon().

LOCAL ThrottlePanel TO MkBox(MB2,"VB",lexicon("width",150,"height",80,"padding",IBPad)).
MkLabel(ThrottlePanel,"Throttle Control:",lexicon("fontsize",12,"align","CENTER")).
//box for throttle controls #open

//make Throttle buttons and entry - do it manually because of special cases
FOR i IN RANGE(0,ThrottleVals:length,1) {
	LOCAL temp1 IS i. //do this to prevent stuff from changing when i changes in the next round of loop
	LOCAL EntryLine TO MkBox(ThrottlePanel,"HL",lexicon("height",rowhei,"padding",OBPad)). //create the horizontal box to put the buttons in

	//make Throttle button
	ThrottleButtons:add(ThrottleVals[temp1][0],MkButton(EntryLine,ThrottleVals[temp1][0],
		{	parameter val. 
			IF val {
				SET PanelSubState["ThrottleMode"] TO ThrottleVals[temp1][0]. 
				SET PanelSubState["ThrottleSetting"] TO ThrottleVals[temp1][1].
				ExclBut(ThrottleButtons,PanelSubState["ThrottleMode"]).
				IF RunState["Other"] = "Active" { //if active, also set the window
					SET ThrottleModeInfo:text TO PanelSubState["ThrottleMode"].
					SET ThrottleSettingInfo:text TO PanelSubState["ThrottleSetting"]:tostring.
				}
			} 
		}
		, lexicon("toggle",true,"width",bwid,"height",rowhei-2))).
	SET ThrottleButtons[ThrottleVals[temp1][0]]:exclusive TO true.
		
	//make entryfield and +/- buttons
	IF NOT ThrottleVals[temp1][3] { //if it shouldn't show entry field, don't create anything
		MkLabel(EntryLine,"").
	} ELSE {	//create entryfield and adjustment buttons
		ThrottleFields:add(ThrottleVals[temp1][0],MkTextInput(EntryLine,ThrottleVals[temp1],1
			,lexicon("height",rowhei-2,"width",57,"numformat",true))).
		SET ThrottleFields[ThrottleVals[temp1][0]]:onconfirm TO { parameter s.
				SET ThrottleVals[temp1][1] TO s:tonumber(ThrottleVals[temp1][1]).
				SET ThrottleFields[ThrottleVals[temp1][0]]:text TO NumFormat(ThrottleVals[temp1][1],99).
				IF PanelSubState["ThrottleMode"] = ThrottleVals[temp1][0] {
					SET PanelSubState["ThrottleSetting"] TO ThrottleVals[temp1][1].
					IF RunState["Other"] = "Active" {SET ThrottleSettingInfo:text TO PanelSubState["ThrottleSetting"]:tostring.}
				}
		}.
		LOCAL minus TO MkButton(EntryLine,"-", 
			{	SET ThrottleVals[temp1][1] TO ThrottleVals[temp1][1] - ThrottleVals[temp1][2].
				SET ThrottleFields[ThrottleVals[temp1][0]]:text TO NumFormat(ThrottleVals[temp1][1],99).
				IF PanelSubState["ThrottleMode"] = ThrottleVals[temp1][0] {
					SET PanelSubState["ThrottleSetting"] TO ThrottleVals[temp1][1].
					IF RunState["Other"] = "Active" {SET ThrottleSettingInfo:text TO PanelSubState["ThrottleSetting"]:tostring.}
				}
			}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).
		IF ThrottleVals[temp1][4] {
			LOCAL zero TO MkButton(EntryLine,"0", 
				{	SET ThrottleVals[temp1][1] TO 0.
					SET ThrottleFields[ThrottleVals[temp1][0]]:text TO NumFormat(ThrottleVals[temp1][1],99).
					IF PanelSubState["ThrottleMode"] = ThrottleVals[temp1][0] {
						SET PanelSubState["ThrottleSetting"] TO ThrottleVals[temp1][1].
						IF RunState["Other"] = "Active" {SET ThrottleSettingInfo:text TO PanelSubState["ThrottleSetting"]:tostring.}
					}
				}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).
		} ELSE {
			LOCAL curr TO MkButton(EntryLine,"C", 
				{	SET ThrottleVals[temp1][1] TO ThrottleVals[temp1][5]().
					SET ThrottleFields[ThrottleVals[temp1][0]]:text TO NumFormat(ThrottleVals[temp1][1],99).
					IF PanelSubState["ThrottleMode"] = ThrottleVals[temp1][0] {
						SET PanelSubState["ThrottleSetting"] TO ThrottleVals[temp1][1].
						IF RunState["Other"] = "Active" {SET ThrottleSettingInfo:text TO PanelSubState["ThrottleSetting"]:tostring.}
					}
				}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).
		}
		LOCAL plus TO MkButton(EntryLine,"+", 
			{	SET ThrottleVals[temp1][1] TO ThrottleVals[temp1][1] + ThrottleVals[temp1][2].
				SET ThrottleFields[ThrottleVals[temp1][0]]:text TO NumFormat(ThrottleVals[temp1][1],99).
				IF PanelSubState["ThrottleMode"] = ThrottleVals[temp1][0] {
					SET PanelSubState["ThrottleSetting"] TO ThrottleVals[temp1][1].
					IF RunState["Other"] = "Active" {SET ThrottleSettingInfo:text TO PanelSubState["ThrottleSetting"]:tostring.}
				}
			}, lexicon("width",12,"height",12,"margins",list((rowhei-12)/2,1,1,1))).
		
		IF ThrottleVals[temp1][0] = "Throttle" {
			SET ThrottleFields[ThrottleVals[temp1][0]]:onconfirm TO { parameter s.
				SET ThrottleVals[temp1][1] TO Limits(s:tonumber(ThrottleVals[temp1][1]),0,1).
				SET ThrottleFields[ThrottleVals[temp1][0]]:text TO NumFormat(ThrottleVals[temp1][1],99).
				IF PanelSubState["ThrottleMode"] = ThrottleVals[temp1][0] {
					SET PanelSubState["ThrottleSetting"] TO ThrottleVals[temp1][1].
					IF RunState["Other"] = "Active" {SET ThrottleSettingInfo:text TO PanelSubState["ThrottleSetting"]:tostring.}
				}
			}.
			SET minus:onclick TO {	
				SET ThrottleVals[temp1][1] TO max(0,ThrottleVals[temp1][1] - ThrottleVals[temp1][2]).
				SET ThrottleFields[ThrottleVals[temp1][0]]:text TO NumFormat(ThrottleVals[temp1][1],99).
				IF PanelSubState["ThrottleMode"] = ThrottleVals[temp1][0] {
					SET PanelSubState["ThrottleSetting"] TO ThrottleVals[temp1][1].
					IF RunState["Other"] = "Active" {SET ThrottleSettingInfo:text TO PanelSubState["ThrottleSetting"]:tostring.}
				}
			}.
			SET plus:onclick TO {	
				SET ThrottleVals[temp1][1] TO min(1,ThrottleVals[temp1][1] + ThrottleVals[temp1][2]).
				SET ThrottleFields[ThrottleVals[temp1][0]]:text TO NumFormat(ThrottleVals[temp1][1],99).
				IF PanelSubState["ThrottleMode"] = ThrottleVals[temp1][0] {
					SET PanelSubState["ThrottleSetting"] TO ThrottleVals[temp1][1].
					IF RunState["Other"] = "Active" {SET ThrottleSettingInfo:text TO PanelSubState["ThrottleSetting"]:tostring.}
				}
			}.
		}
	}
} // #close	



 // #close

//initialization of the mode - executes once when GO button pressed
function Init {
	FlightInit().
	SET SAS TO false.
	
	SET TBstatus:text TO "Basic Plane".
	//change the status box
	StatusBox:showonly(SB).  
	
	SET PitchModeInfo:text TO RunState["SubState"]["PitchMode"].
	SET PitchSettingInfo:text TO RunState["SubState"]["PitchSetting"]:tostring.
	//heading control status
	SET HeadingModeInfo:text TO RunState["SubState"]["HeadingMode"].
	IF RunState["SubState"]["HeadingMode"] = "Lat.Lng." {
		SET HeadingSettingInfo:text TO "("+RunState["SubState"]["HeadingSetting"]:lat+","+RunState["SubState"]["HeadingSetting"]:lng+")".
	} ELSE {
		SET HeadingSettingInfo:text TO RunState["SubState"]["HeadingSetting"]:tostring.
	}
	//throttle control status
	SET ThrottleModeInfo:text TO RunState["SubState"]["ThrottleMode"].
	SET ThrottleSettingInfo:text TO RunState["SubState"]["ThrottleSetting"]:tostring.
	
}

//main loop - executes every time through
function Main {
	FlightUpdate(RunState["SubState"]).
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
	UpdatePanel().
	
	
}

function Display {
	LOCAL DispList IS lexicon("None", {return "-".},
							"Altitude",{return "Alt:"+NumFormat(PanelSubState["PitchSetting"],1).},
							"Pitch",{return "Pit:"+round(PanelSubState["PitchSetting"],1).},
							"Vert.Vel.",{return "VV:"+round(PanelSubState["PitchSetting"],1).},
							"AoA",{return "AoA:"+round(PanelSubState["PitchSetting"],1).},
							"Bank",{return "Bank:"+round(PanelSubState["HeadingSetting"],1).},
							"Heading",{return "Head:"+round(PanelSubState["HeadingSetting"],1).},
							"Lat.Lng.",{return "LL:"+round(PanelSubState["HeadingSetting"]:lat,1)+","+round(PanelSubState["HeadingSetting"]:lng,1).},
							"Speed",{return "Sp:"+NumFormat(PanelSubState["ThrottleSetting"],1).},
							"Throttle",{return "Thr:"+round(PanelSubState["ThrottleSetting"],2).}).
							
	LOCAL Disp IS "Pl: "+DispList[PanelSubState["PitchMode"]]().
	SET Disp TO Disp+", "+DispList[PanelSubState["HeadingMode"]]().
	SET Disp TO Disp+", "+DispList[PanelSubState["ThrottleMode"]]().
	return Disp.
}

RegisterMode("Plane","Basic",Init@,Main@,End@,SB,MB,PanelInit@,ModeInfo,Display@).
print "Plane: Basic loaded.".
} //#close
