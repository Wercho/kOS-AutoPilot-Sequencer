@LAZYGLOBAL OFF.
//Conditions are listed in a lexicon with type, variable, options, field
//type determines the options and the listing order
//variable is what variables can be used
//options are the options
//field marks what kind of field to create

//Make utility lists
LOCAL IntegerRelations IS lexicon(	//j parameter is for matching logic which need an arg
	"<",{parameter h,i,j. return h<i.}
	,">",{parameter h,i,j. return h>i.}
	,"=",{parameter h,i,j. return h=i.}
	).

LOCAL RealRelations IS lexicon(
	"<",{parameter h,i,j. return h()<i().}
	,">",{parameter h,i,j. return h()>i().}
	).


//lexicon of all the conditions for choosing
GLOBAL ConditionSet IS lexicon().

//ConditionSet is a global variable
SET ConditionSet TO lexicon().

//add end category #open
ConditionSet:add("END",lexicon()).

//add options
SET ConditionSet["END"]["options"] TO list(
	lexicon("Display","<b>END</b>","condition","END")
	).

//function to make the selection box
SET ConditionSet["END"]["Initialize"] TO {
	parameter StartCondition IS "END".	//starting condition
	ConditionBox2:clear().	//clear anything previously created
	SET ConditionCreate["type"] TO "END".
	SET ConditionCreate["Displacy"] TO ConditionSet["END"]["options"][0]["Display"].
	SET ConditionCreate["condition"] TO ConditionSet["END"]["options"][0]["condition"].
}.

SET ConditionSet["END"]["Finalize"] TO {
	//nothing for the END set
}.

SET ConditionSet["END"]["Construct"] TO {
	parameter condition	//string denoting what to enter
	, children1 IS 0.		//children to combine
	
	//parameter because Logic conditions need it
	return {parameter s.	return RunState["other"] = "End".	}.
}.	//END #close



//add logic category #open
ConditionSet:add("Logic",lexicon()).

//add options
SET ConditionSet["Logic"]["options"] TO list(
	lexicon("Display","<b>AND</b>","condition","AND"),
	lexicon("Display","<b>OR</b>","condition","OR")
	).

//function to make the selection box
SET ConditionSet["Logic"]["Initialize"] TO {
	parameter StartCondition IS "AND".	//starting condition
	ConditionBox2:clear().	//clear anything previously created
	SET ConditionCreate["type"] TO "Logic".
		
	LOCAL popup IS MkPopup(ConditionBox2,80,0).
	
	FOR item IN ConditionSet["Logic"]["options"] {
		popup:addoption(item["Display"]).
	}
	
	LOCAL tempindex IS 0.
	UNTIL ConditionSet["Logic"]["options"][tempindex]["condition"] = StartCondition {
		SET tempindex TO tempindex+1.}
	SET popup:index TO tempindex.
	SET ConditionCreate["Display"] TO ConditionSet["Logic"]["options"][tempindex]["Display"].
	SET ConditionCreate["condition"] TO ConditionSet["Logic"]["options"][tempindex]["condition"].
	
	SET popup:onchange TO {
		parameter s.
		SET ConditionCreate["Display"] TO s.
		SET ConditionCreate["condition"] TO ConditionSet["Logic"]["options"][popup:index]["condition"].
	}.
}.

SET ConditionSet["Logic"]["Finalize"] TO {
	//nothing for the logic set
}.

SET ConditionSet["Logic"]["Construct"] TO {
	parameter condition	//string denoting what to enter
	, children1.		//children to combine
	IF condition = "AND" {
		return { parameter children1.
			LOCAL ReturnVal IS true.
			FOR Cond1 IN children1 {
				LOCAL Cond1Children TO ActiveConditionList[Cond1]["children"].
				SET ReturnVal TO ReturnVal AND ActiveConditionList[Cond1]["state"].
			}
			return ReturnVal.
		}.
	} ELSE {	//OR
		return { parameter children1.
			LOCAL ReturnVal IS false.
			FOR Cond1 IN children1 {
				LOCAL Cond1Children TO ActiveConditionList[Cond1]["children"].
				SET ReturnVal TO ReturnVal OR ActiveConditionList[Cond1]["state"].
			}
			return ReturnVal.
		}.
	
	}
}.	//#logic #close


//#open math constructions
LOCAL RealCondTypes TO list(
	lexicon("type","Phase Elapsed Time",
		"label","Elapsed Time",
		"numformat",TFA@:bind(2),
		"label2","s",
		"comparewith",{return timestamp() - SequencePhaseStartTime.}),
	lexicon("type","Altitude (ASL)",
		"label","Alt. (ASL)",
		"numformat",NF@:bind(2,"m",false),
		"label2","m",
		"comparewith",{return ship:altitude.}),
	lexicon("type","Altitude (AGL)",
		"label","Alt. (AGL)",
		"numformat",NF@:bind(2,"m",false),
		"label2","m",
		"comparewith",{return alt:radar.}),
	lexicon("type","Speed (Orbital)",
		"label","Speed (Orb)",
		"numformat",NF@:bind(2,"m/s",false),
		"label2","m/s",
		"comparewith",{return ship:velocity:orbit:mag.}),
	lexicon("type","Speed (Surface)",
		"label","Speed (Sur)",
		"numformat",NF@:bind(2,"m/s",false),
		"label2","m/s",
		"comparewith",{return ship:velocity:surface:mag.}),
	lexicon("type","Speed (Vertical)",
		"label","Speed (Vert)",
		"numformat",NF@:bind(2,"m/s",false),
		"label2","m/s",
		"comparewith",{return ship:verticalspeed.}),
	lexicon("type","Speed (Ground)",
		"label","Speed (Ground)",
		"numformat",NF@:bind(2,"m/s",false),
		"label2","m/s",
		"comparewith",{return ship:groundspeed.}),
	lexicon("type","Distance from start of phase",
		"label","Dist. Start",
		"numformat",NF@:bind(2,"m",false),
		"label2","m",
		"comparewith",{return SequencePhaseStartLocation[0]:altitudeposition(SequencePhaseStartLocation[1]):mag.}),
	lexicon("type","Apoapsis",
		"label","Apoapsis",
		"numformat",NF@:bind(2,"m",false),
		"label2","m",
		"comparewith",{return ship:orbit:apoapsis.}),
	lexicon("type","Periapsis",
		"label","Periapsis",
		"numformat",NF@:bind(2,"m",false),
		"label2","m",
		"comparewith",{return ship:orbit:periapsis.})
	).	

FOR condtype1 IN RealCondTypes {
	LOCAL condtype TO LCOPY(condtype1).
	LOCAL type1 TO condtype["type"].
	ConditionSet:add(type1,lexicon()).

	SET ConditionSet[type1]["Initialize"] TO {
		parameter StartCondition IS list(">",0).
		SET ConditionCreate["Display"] TO condtype["label"]+StartCondition[0]+" "+condtype["numformat"](StartCondition[1]).
		SET ConditionCreate["condition"] TO StartCondition.
		SET ConditionCreate["type"] TO type1.
		
		ConditionBox2:clear().
		LOCAL wid TO ConditionBox2:gui:style:width.
		MkLabel(ConditionBox2,condtype["type"],lexicon("width",wid,"fontsize",10)).
		
		LOCAL CondLine TO MkBox(ConditionBox2,"HL",lexicon("width",wid)).
		//make popup to select relationship
		LOCAL popup IS MkPopup(CondLine,40,0).
		SET popup:options TO RealRelations:keys.
		//find the index of StartCondition[0]
		LOCAL tempindex TO 0.
		UNTIL RealRelations:keys[tempindex] = StartCondition[0] {SET tempindex TO tempindex+1.}
		//set popup start conditions
		SET popup:index TO tempindex.

		SET popup:onchange TO {
			parameter s.
			SET ConditionCreate["condition"][0] TO s.
		}.
		
		//text input for creation of the box
		LOCAL RealText IS MkTextInput(CondLine,ConditionCreate["condition"],1
			,lexicon("width",130,"fontsize",10,"marginv",4,"numformat",true)).
		// SET RealText:text TO StartCondition[1]:tostring.
		
		MkLabel(CondLine,condtype["label2"],lexicon("fontsize",10,"width",30,"marginv",6)).
	}.

	SET ConditionSet[type1]["Finalize"] TO {
		SET ConditionCreate["Display"] TO condtype["label"]+ConditionCreate["condition"][0]+" "+condtype["numformat"](ConditionCreate["condition"][1]).
	}.

	SET ConditionSet[type1]["Construct"] TO {	//return a function delegate to evaluate the condition
		parameter condition	//list denoting what to enter
		, children1 IS 0.		//children to combine - included for reference
		
		return RealRelations[condition[0]]@:bind(condtype["comparewith"],
			{return condition[1].}).
	}.
} //#close real constructions

// #open distance from
{	//#open waypoint
	//horizontal or actual distance
	LOCAL disttypes TO lexicon("Actual Distance to Waypoint",{parameter s. return waypoint(s):position:mag.},
		"Horizontal Distance to Waypoint",{parameter s. return waypoint(s):geoposition:altitudeposition(ship:altitude):mag.}).
	
	ConditionSet:add("Waypoint",lexicon()).

	SET ConditionSet["Waypoint"]["Initialize"] TO {
		parameter StartCondition IS list(""	//start with the first waypoint of the current body by default
			,"<",1000
			,disttypes:keys[0]).
		IF StartCondition[0] = "" {
			LOCAL Waypoints IS FilterByFunc(GetWaypointNames(),{parameter s. return waypoint(s):body = ship:body.}).
			IF Waypoints:length>0 {SET StartCondition[0] TO Waypoints[0].}
		}		
		
		LOCAL wid TO ConditionBox2:gui:style:width.
		SET ConditionCreate["Display"] TO StartCondition[0]+" "+StartCondition[1]+" "
			+NF(1,"m",StartCondition[2])+" ("+StartCondition[3]:substring(0,3)+")".

		SET ConditionCreate["condition"] TO StartCondition.
		SET ConditionCreate["type"] TO "Waypoint".

		ConditionBox2:clear().
		LOCAL TopLine TO MkBox(ConditionBox2,"HL",lexicon("width",wid)).
		MkLabel(TopLine,"Body:",lexicon("width",40,"fontsize",10)).

		function UpdateWPSelect { //function to update WP Select
			LOCAL WaypointNames TO GetWaypointNames().
			LOCAL BodyName TO BodySelect:value.
			SET WaypointNames TO FilterByFunc(WaypointNames,
				{parameter s. return Waypoint(s):body:name = BodyName.}).

			WPSelect:clear().
			SET WPSelect:options TO WaypointNames.
			LOCAL tempindex TO 0.
			UNTIL WPSelect:options[tempindex] = StartCondition[0] {SET tempindex TO tempindex+1.}
			SET WPSelect:index TO tempindex.
		}

		
		//make popup to select body
		LOCAL BodySelect IS MkPopup(TopLine,136,0,lexicon("hstretch",true)).
		SET BodySelect:options TO GetBodyNames().
		//set to current body
		LOCAL tempindex TO 0.
		UNTIL BodySelect:options[tempindex] = Waypoint(StartCondition[0]):body:name {SET tempindex TO tempindex+1.}
		SET BodySelect:index TO tempindex.

		SET BodySelect:onchange TO {
			parameter s.
			UpdateWPSelect().
		}.
	
		//select actual or horizontal distance
		LOCAL TypeSelect TO MkPopup(ConditionBox2,180,0).
		SET TypeSelect:options TO disttypes:keys.
		//set start selected entry
		LOCAL tempindex TO 0.
		UNTIL TypeSelect:options[tempindex] = StartCondition[3] {SET tempindex TO tempindex+1.}
		SET TypeSelect:index TO tempindex.
		SET TypeSelect:onchange TO {
			parameter s.
			SET ConditionCreate["condition"][3] TO s.			
		}.

		//make popup to select waypoint
		LOCAL WPSelect IS MkPopup(ConditionBox2,180,0).
		UpdateWPSelect().
		
		SET WPSelect:onchange TO {
			parameter s.
			SET ConditionCreate["condition"][0] TO s.
		}.
		

		LOCAL SelectLine TO MkBox(ConditionBox2,"HL",lexicon("width",wid)).
		//make popup to select relationship
		LOCAL popup IS MkPopup(SelectLine,40,0).
		SET popup:options TO RealRelations:keys.
		//find the index of StartCondition[0]
		LOCAL tempindex TO 0.
		UNTIL popup:options[tempindex] = StartCondition[1] {SET tempindex TO tempindex+1.}
		//set popup start conditions
		SET popup:index TO tempindex.

		SET popup:onchange TO {
			parameter s.
			SET ConditionCreate["condition"][1] TO s.
		}.
		
		//text input for creation of the box
		LOCAL RealText IS MkTextInput(SelectLine,ConditionCreate["condition"],2
			,lexicon("width",80,"fontsize",10,"marginv",4,"numformat",true)).
		
		MkLabel(SelectLine,"m",lexicon("fontsize",10,"width",15,"marginv",6)).
		
	}.

	SET ConditionSet["Waypoint"]["Finalize"] TO {
		SET ConditionCreate["Display"] TO ConditionCreate["condition"][0]+" "+ConditionCreate["condition"][1]+" "
			+NF(1,"m",ConditionCreate["condition"][2])+" ("+ConditionCreate["condition"][3]:substring(0,3)+")".
	}.

	SET ConditionSet["Waypoint"]["Construct"] TO {	//return a function delegate to evaluate the condition
		parameter condition	//list denoting what to enter
		, children1 IS 0.		//children to combine - included for reference
		return RealRelations[condition[1]]@:bind(disttypes[condition[3]]@:bind(condition[0]),{return condition[2].}).
	}.
	
} //#close dist to waypoint

{	//#open lat lng
	
	ConditionSet:add("Lat.Lng.",lexicon()).

	SET ConditionSet["Lat.Lng."]["Initialize"] TO {
		parameter StartCondition IS list(list(0,0)	//default conditions
			,"<",1000).
		
		SET ConditionCreate["Display"] TO "("+StartCondition[0][0]+","+StartCondition[0][1]+") "+StartCondition[1]+" "
			+NF(1,"m",StartCondition[2]).

		SET ConditionCreate["condition"] TO StartCondition.
		SET ConditionCreate["type"] TO "Lat.Lng.".

		ConditionBox2:clear().
		LOCAL wid TO ConditionBox2:gui:style:width.
		MkLabel(ConditionBox2,"Lat.Lng.:",lexicon("width",50,"fontsize",10)).

		LOCAL EntryLine IS MkBox(ConditionBox2,"HL",lexicon("padding",OBPad)).
		LOCAL LatEntry TO MkTextInput(EntryLine,ConditionCreate["condition"][0],0,lexicon("width",90)).
		LOCAL LngEntry TO MkTextInput(EntryLine,ConditionCreate["condition"][0],1,lexicon("width",90)).

		//make popup to select relationship
		LOCAL SelectLine TO MkBox(ConditionBox2,"HL",lexicon("width",wid)).
		LOCAL popup IS MkPopup(SelectLine,40,0).
		SET popup:options TO RealRelations:keys.
		//find the index of StartCondition[0]
		LOCAL tempindex TO 0.
		UNTIL popup:options[tempindex] = StartCondition[1] {SET tempindex TO tempindex+1.}
		//set popup start conditions
		SET popup:index TO tempindex.

		SET popup:onchange TO {
			parameter s.
			SET ConditionCreate["condition"][1] TO s.
		}.
		
		//text input for creation of the box
		LOCAL RealText IS MkTextInput(SelectLine,ConditionCreate["condition"],2
			,lexicon("width",80,"fontsize",10,"marginv",4,"numformat",true)).
		
		MkLabel(SelectLine,"m",lexicon("fontsize",10,"width",15,"marginv",6)).

	}.

	SET ConditionSet["Lat.Lng."]["Finalize"] TO {
		SET ConditionCreate["Display"] TO "("+ConditionCreate["condition"][0][0]+","
			+ConditionCreate["condition"][0][1]+") "+ConditionCreate["condition"][1]+" "
			+NF(1,"m",ConditionCreate["condition"][2]).
	}.

	SET ConditionSet["Lat.Lng."]["Construct"] TO {	//return a function delegate to evaluate the condition
		parameter condition	//list denoting what to enter
		, children1 IS 0.		//children to combine - included for reference
		
		return RealRelations[condition[1]]@:bind({return latlng(condition[0][0],condition[0][1]):altitudeposition(ship:altitude):mag.}
			,{return condition[2].}).
	}.
	
} //#close dist to lat lng

//#close distance to things
