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
LOCAL PanelSubState IS lexicon("TargetType","Lat.Lng."
							,"Target",list(0,0)
							,"TargetBody",ship:body:name).
							
LOCAL WaypointNames IS GetWaypointNames().
LOCAL LatLng IS list(0,0).
LOCAL FilteredRunways TO lexicon().


//used in most/all landing state functions
LOCAL LandRunway IS lexicon().
LOCAL LandPoint IS V(0,0,0).
LOCAL ApproachPoint IS V(0,0,0).
LOCAL TurnPoint IS V(0,0,0).
LOCAL TurnDir IS "".
LOCAL RunwayEnd IS "".
LOCAL ApproachDist TO 0.
LOCAL ApproachHeight TO 0.
LOCAL TurnTime TO 0.
LOCAL TurnRadius TO 0.
LOCAL TurnStartPoint IS V(0,0,0).
LOCAL InitialLandingPoints IS {}.
LOCAL GetLandingPoints IS {}.
LOCAL GetOtherEnd IS {}.
LOCAL OtherEnd IS latlng(0,0).
LOCAL LandTerrainHeight IS 0.
//used in DoDescent
LOCAL SpeedRecord IS 0.
LOCAL DistRecord IS 0.
//used in DoLandingApproach , DoLanding
LOCAL SpeedCheck IS {}.
LOCAL BottomBoundHeight IS 0.
LOCAL TargetDisplay IS "".
LOCAL DesSpeed IS 0.
LOCAL TerrainHeight IS 0.

//#open flight functions
LOCAL InitialLandingPointsRunway IS {
	//Determines which runway end and turn direction to use
	//get runway
	SET LandRunway TO Runways[RunState["SubState"]["Target"]].
	LOCAL RunVec IS LandRunway["P2"]:position - LandRunway["P1"]:position.
	LOCAL RunUpVec IS LandRunway["P1"]:altitudeposition(1) - LandRunway["P1"]:altitudeposition(0).
	//find nearest turnpoint, accounting for valid landing directions
	
	SET RunwayEnd TO "".
	LOCAL tempApproachPoint TO V(0,0,0).
	LOCAL TurnPointVec TO V(10^12,0,0).
	IF LandRunway["Land12"] {
		SET tempApproachPoint TO LandRunway["P1"]:position + -1*ApproachDist*RunVec:normalized+RunUpVec*ApproachHeight.
		LOCAL TurnPointVecL IS tempApproachPoint + angleaxis(-90,RunUpVec)*RunVec:normalized*TurnRadius.
		IF TurnPointVecL:mag < TurnPointVec:mag {
			SET TurnPointVec TO TurnPointVecL.
			SET RunwayEnd TO "P1".
			SET TurnDir TO "L".
			SET ApproachPoint TO Body(RunState["SubState"]["TargetBody"]):geopositionof(tempApproachPoint).
		}
		LOCAL TurnPointVecR IS tempApproachPoint + angleaxis(90,RunUpVec)*RunVec:normalized*TurnRadius.
		IF TurnPointVecR:mag < TurnPointVec:mag {
			SET TurnPointVec TO TurnPointVecR.
			SET RunwayEnd TO "P1".
			SET TurnDir TO "R".
			SET ApproachPoint TO Body(RunState["SubState"]["TargetBody"]):geopositionof(tempApproachPoint).
		}
	}
	IF LandRunway["Land21"] {
		SET tempApproachPoint TO LandRunway["P2"]:position + ApproachDist*RunVec:normalized+RunUpVec*ApproachHeight.
		LOCAL TurnPointVecL IS tempApproachPoint + angleaxis(90,RunUpVec)*RunVec:normalized*TurnRadius.
		IF TurnPointVecL:mag < TurnPointVec:mag {
			SET TurnPointVec TO TurnPointVecL.
			SET RunwayEnd TO "P2".
			SET TurnDir TO "L".
			SET ApproachPoint TO Body(RunState["SubState"]["TargetBody"]):geopositionof(tempApproachPoint).
		}
		LOCAL TurnPointVecR IS tempApproachPoint + angleaxis(-90,RunUpVec)*RunVec:normalized*TurnRadius.
		IF TurnPointVecR:mag < TurnPointVec:mag {
			SET TurnPointVec TO TurnPointVecR.
			SET RunwayEnd TO "P2".
			SET TurnDir TO "R".
			SET ApproachPoint TO Body(RunState["SubState"]["TargetBody"]):geopositionof(tempApproachPoint).
		}
	}
	SET LandPoint TO LandRunway[RunwayEnd].
	SET LandTerrainHeight TO LandPoint:terrainheight.
	SET TurnPoint TO Body(RunState["SubState"]["TargetBody"]):geopositionof(TurnPointVec).
	GetOtherEndRunway().
	UpdateLandingPointsRunway().
	
}.

LOCAL UpdateLandingPointsRunway IS {
	//Updates LandPoint, ApproachPoint, TurnPoint, and TurnDir
	//get runway vector
	
	//set points based on initially established Landingpoints
	LOCAL angledir IS -1. //direction to rotate (this is left rotate to create right turn)
	IF TurnDir = "L" {SET angledir TO 1.}  //this is right rotate, to create left turn
	//do max because arcsin can't take values > 1
	LOCAL TurnPointVec IS TurnPoint:altitudeposition(ApproachHeight+LandTerrainHeight).
	SET TurnStartPoint TO angleaxis(angledir*arcsin(TurnRadius/max(TurnPointVec:mag,TurnRadius)),ship:up:forevector)*TurnPointVec.
}.

LOCAL GetOtherEndRunway IS {
	IF RunwayEnd = "P1" {SET OtherEnd TO LandRunway["P2"].}
	ELSE {SET OtherEnd TO LandRunway["P1"].}
}.

LOCAL LandingPointsNoRunway IS {
	//get terrain height at landingpoint
	SET LandPoint TO RunState["SubState"]["Target"].
	SET LandTerrainHeight TO LandPoint:terrainheight.
	//if ocean, set to 0 if terrainheight is below sea level
	IF Body(LandPoint):hasocean { SET LandTerrainHeight TO max(LandTerrainHeight,0).}
	//convet to geoposition to get ground position
	LOCAL LandPointVec TO LandPoint:position.
	LOCAL LandUpVec TO (LandPoint:altitudeposition(1) - LandPoint:altitudeposition(0)).
	LOCAL LandHVec TO vxcl(LandUpVec,LandPointVec):normalized.
	
	SET LandPoint TO Body(LandPoint):geopositionof(LandPointVec - 300*LandHVec).//move closer to current position
	SET ApproachPoint TO Body(LandPoint):geopositionof(LandPoint:position-ApproachDist*LandHVec).
	SET TurnPoint TO ApproachPoint.
	SET TurnStartPoint TO ApproachPoint:position.
}.

LOCAL GetOtherEndNoRunway TO {
	SET OtherEnd TO Body(LandPoint):geopositionof(1000*vxcl(ship:up:forevector,ship:facing:forevector)). //set out in front of ship
}.

LOCAL LandStart IS {
	//convert strings to useful targets, setup initial control coordinates
	//aproach distance is the distance covered at the plane's stall speed*1.5 in 60 seconds
	SET ApproachDist TO PlaneStats["StallSpeed"]*120.
	//approach height is target vertical distance to above runway at approach dist
	SET ApproachHeight TO ApproachDist*PlaneStats["ApproachSlope"].

	//estimate turn radius
	//360 turntime based on experimental data, very rough estimate
	SET TurnTime TO 6080*constant:E^(-0.0254*PlaneStats["TurnAoAMax"])/PlaneStats["BankMax"].
	//turn circumference is distance traveled while turning 360, divide by 2pi for radius
	SET TurnRadius TO TurnTime*PlaneStats["StallSpeed"]*1.5/(2*constant:pi).
	
	LOCAL BottomBoundHeight IS 0.
	//set points if runway
	IF RunState["SubState"]["TargetType"] = "Runway" {
		SET InitialLandingPoints TO InitialLandingPointsRunway.
		SET GetLandingPoints TO UpdateLandingPointsRunway.
		SET GetOtherEnd TO GetOtherEndRunway.
		SET TargetDisplay TO RunState["SubState"]["Target"].
	} ELSE IF RunState["SubState"]["TargetType"] = "Waypoint" {
		SET TargetDisplay TO "WP: "+RunState["SubState"]["Target"].
		SET RunState["SubState"]["Target"] TO Waypoint(RunState["SubState"]["Target"]):geoposition.
		SET InitialLandingPoints TO LandingPointsNoRunway.
		SET GetLandingPoints TO LandingPointsNoRunway.
		SET GetOtherEnd TO GetOtherEndNoRunway.
	} ELSE IF RunState["SubState"]["TargetType"] = "Lat.Lng." {
		SET TargetDisplay TO "("+round(RunState["SubState"]["Target"][0],2)+","+round(RunState["SubState"]["Target"][1],2)+")".
		SET RunState["SubState"]["Target"] TO latlng(RunState["SubState"]["Target"][0],RunState["SubState"]["Target"][1]).
		SET InitialLandingPoints TO LandingPointsNoRunway.
		SET GetLandingPoints TO LandingPointsNoRunway.
		SET GetOtherEnd TO GetOtherEndNoRunway.
	} ELSE IF RunState["SubState"]["TargetType"] = "Target" {
		SET TargetDisplay TO "Target: "+ship:target:name.
		SET RunState["SubState"]["Target"] TO ship:target:geoposition.
		SET InitialLandingPoints TO LandingPointsNoRunway.
		SET GetLandingPoints TO LandingPointsNoRunway.
		SET GetOtherEnd TO GetOtherEndNoRunway.
	}
	
	//start cruise state
	CruiseSetup().
}.

// //TEST:                  
// LOCAL LandPointDraw IS vecdraw(V(0,0,0),{return 100*ship:up:forevector.},white).
// LOCAL ApproachPointDraw IS vecdraw(V(0,0,0),{return 100*ship:up:forevector.},yellow).
// LOCAL TurnPointDraw IS vecdraw(V(0,0,0),{return 100*ship:up:forevector.},blue).
// LOCAL OtherPointDraw IS vecdraw(V(0,0,0),V(0,0,0),red).
// LOCAL OtherPoint IS V(0,0,0).

// LOCAL ApproachDraw IS vecdraw(V(0,0,0),V(0,0,0),green).
// LOCAL FlyApproachDraw IS vecdraw(V(0,0,0),V(0,0,0),red).

// LOCAL tempFunc IS {
	// GetLandingPoints().
	// SET LandPointDraw:start TO LandPoint:altitudeposition(LandTerrainHeight).
	// SET ApproachPointDraw:start TO ApproachPoint:altitudeposition(ApproachHeight+LandTerrainHeight).
	// SET TurnPointDraw:start TO TurnPoint:altitudeposition(ApproachHeight+LandTerrainHeight).
	// SET ApproachDraw:start TO ApproachPoint:altitudeposition(ApproachHeight+LandTerrainHeight).
	// SET ApproachDraw:vec TO LandPoint:altitudeposition(LandTerrainHeight)-ApproachPoint:altitudeposition(LandTerrainHeight+ApproachHeight).
	// SET OtherPointDraw:vec TO TurnStartPoint.
	
// }.
//end debug

function CruiseSetup {
	SET LandingStatus:text TO "Cruising towards "+TargetDisplay+".".
	InitialLandingPoints().
	SET RunState["SubState"]["LandFunc"] TO DoLandingCruise.
	SET kuniverse:timewarp:warp TO PlaneStats["MaxWarp"].
}

LOCAL DoLandingCruise IS {
	GetLandingPoints().
	LOCAL dist IS TurnStartPoint:mag.
	LOCAL altdif IS ship:altitude - ApproachHeight-LandTerrainHeight.
	// print round(altdif,1)+":"+round(dist*PlaneStats["ApproachSlope"]*2,1).//BUG:
	//check when to start descinding, and set values for DoLandingDescent
	IF (abs(altdif) > dist*PlaneStats["ApproachSlope"]*2 ) OR (dist < ApproachDist) {DescentSetup().}
	
	//fly to TurnStartPoint at cruise altitude at max throttle
	FlightUpdate(lexicon("PitchMode","Altitude"
					,"PitchSetting",PlaneStats["AltCruise"]
					,"HeadingMode","Heading"
					,"HeadingSetting",VecHeading(TurnStartPoint)
					,"ThrottleMode","Speed"
					,"ThrottleSetting",PlaneStats["CruiseSpeed"])).
					
}.

LOCAL DescentSetup IS {
	SET RunState["SubState"]["LandFunc"] TO DoLandingDescent.
	SET LandingStatus:text TO "Descending to landing at "+TargetDisplay+".".
	SET SpeedRecord TO ship:velocity:surface:mag.
	SET DistRecord TO vxcl(ship:up:forevector,TurnStartPoint):mag.
	SET kuniverse:timewarp:warp TO min(PlaneStats["MaxWarp"],2).
	print "Descent".//BUG:
}.

LOCAL DoLandingDescent IS {
	GetLandingPoints().
	LOCAL dist IS vxcl(ship:up:forevector,TurnStartPoint):mag.	//horizontal distance
	LOCAL altdif IS -1*VProjMag(TurnStartPoint,ship:up:forevector).	//vertical distance
	
	//set VV based on speed, distance, and altitude to descend - to hit TurnStartPoint
	LOCAL DesVV IS -1.2*ship:velocity:surface:mag/dist*altdif.
	
	//linearly slow desired speed as approaching turnstart point
	SET DesSpeed TO min(SpeedRecord,dist/DistRecord*(SpeedRecord-PlaneStats["StallSpeed"]*1.5)+PlaneStats["StallSpeed"]*1.5).
	
	//descend to TurnStartPoint at gradually slowing speeds
	FlightUpdate(lexicon("PitchMode","Vert.Vel."
					,"PitchSetting",DesVV
					,"HeadingMode","Heading"
					,"HeadingSetting",VecHeading(TurnStartPoint)
					,"ThrottleMode","Speed"
					,"ThrottleSetting",DesSpeed)).
	
	//if close to TurnStartPoint, go to approach function
	IF TurnPoint:altitudeposition(ApproachHeight+LandTerrainHeight):mag < TurnRadius*1.2 {
		//if not at the right altitude (determined as 10% of ApproachHeight), circle
		IF abs(altdif) > ApproachHeight * 0.1 {CircleSetup().}
		ELSE {ApproachSetup().}//else go to Approach
	}
}.

LOCAL CircleSetup IS {
	SET RunState["SubState"]["LandFunc"] TO DoCircle.
	SET LandingStatus:text TO "Circling to correct approach altitude.".
	Print "Circling".//BUG:
}.

LOCAL DoCircle IS { //fly away from landingpoint until at a close enough altitude to turn back
	GetLandingPoints().
	LOCAL dist IS vxcl(ship:up:forevector,TurnStartPoint):mag.	//horizontal distance
	LOCAL altdif IS -1*VProjMag(TurnStartPoint,ship:up:forevector).	//vertical distance

	//set desVV to 4x the approach slope (accounting for positive or negative with altdif
	LOCAL DesVV IS -4*altdif/abs(altdif)*ship:groundspeed*PlaneStats["ApproachSlope"].
	
	//fly away
	FlightUpdate(lexicon("PitchMode","Vert.Vel."
					,"PitchSetting",DesVV
					,"HeadingMode","Heading"
					,"HeadingSetting",VecHeading(-1*LandPoint:position)
					,"ThrottleMode","Speed"
					,"ThrottleSetting",PlaneStats["StallSpeed"]*1.5)).
	
	//check if far enough away, and go back to descent
	IF 0.5* abs(altdif) < dist*PlaneStats["ApproachSlope"] {
		InitialLandingPoints().	//update incase this step caused to fly to other side of runway
		DescentSetup().
	}
}.

LOCAL ApproachSetup IS {
	SET RunState["SubState"]["LandFunc"] TO DoLandingApproach.
	SET LandingStatus:text TO "On approach to "+TargetDisplay+".".
	//update this to land at more accurate height
	SET SpeedCheck TO SpeedCheck1.
	SET DesSpeed TO PlaneStats["StallSpeed"]*1.5.
	print "Approaching".
	SET kuniverse:timewarp:warp TO min(PlaneStats["MaxWarp"],2).
	SET BottomBoundHeight TO alt:radar - ship:bounds:bottomaltradar.
}.

//speed checks to open flaps on descent
LOCAL SpeedCheck1 IS {
	parameter FlyVec.
	IF abs(VecBearing(FlyVec)) < 5	{	//if facing target vector, more or less, reduce speed and set flaps
		SET DesSpeed TO PlaneStats["LandingSpeed"].
		FlapsAdjust(2).
		IF RunState["SubState"]["TargetType"] = "Runway" { //set gear based on runway
			SET GEAR TO NOT(LandRunway["WaterRunway"]).
		} ELSE IF ship:body:hasocean {	//else based on guess of not ocean
			SET GEAR TO LandTerrainHeight > 0.
		} ELSE { SET GEAR TO true.}	//else assume land
		SET SpeedCheck TO SpeedCheck2.
	}
}.

LOCAL SpeedCheck2 IS {
	parameter s.
	IF ship:velocity:surface:mag < PlaneStats["LandingSpeed"] * 1.5 {
		FlapsAdjust(3).
		
		SET SpeedCheck TO {parameter s.}.
	}
}.

LOCAL DoLandingApproach IS {
	GetLandingPoints().
	
	//set desVV based on distance and altitude to landing point
	LOCAL dist IS vxcl(ship:up:forevector,LandPoint:position):mag.	//horizontal distance
	LOCAL LPVec IS LandPoint:altitudeposition(LandTerrainHeight+BottomBoundHeight).
	LOCAL altdif IS -1*VProjMag(LPVec,ship:up:forevector).	//vertical distance
	LOCAL DesVV IS -1*ship:groundspeed/dist*altdif.

	//set heading based on 2*vector normal to approach vector, plus 1*projected 
	LOCAL ApproachVec IS LPVec - ApproachPoint:altitudeposition(LandTerrainHeight+BottomBoundHeight+ApproachHeight).
	LOCAL AppVecNorm IS vxcl(ApproachVec,LandPoint:position).
	LOCAL DesVV IS DesVV + VprojMag(AppVecNorm,ship:up:forevector)/4.

	LOCAL FlyVec IS VProj(LandPoint:position,ApproachVec) + 5*AppVecNorm.
	SpeedCheck(FlyVec).
	
	//fly
	FlightUpdate(lexicon("PitchMode","Vert.Vel."
					,"PitchSetting",DesVV
					,"HeadingMode","Heading"
					,"HeadingSetting",VecHeading(FlyVec)
					,"ThrottleMode","Speed"
					,"ThrottleSetting",DesSpeed)).
	
	//check if within 5 seconds of runway altitude
	IF ship:verticalspeed * -5 > altdif {
		LandingSetup().
	}
}.

LOCAL LandingSetup IS {
	SET RunState["SubState"]["LandFunc"] TO DoLanding.
	SET LandingStatus:text TO "Landing at "+TargetDisplay+".".
	//backup flaps and gear, incase didn't slow
	FlapsAdjust(3).
	IF RunState["SubState"]["TargetType"] = "Runway" { //set gear based on runway
		SET GEAR TO NOT(LandRunway["WaterRunway"]).
	} ELSE IF ship:body:hasocean {	//else based on guess of not ocean
		SET GEAR TO TerrainHeight > 0.
	} ELSE { SET GEAR TO true.}	//else assume land
	GetOtherEnd().
	kuniverse:timewarp:cancelwarp().
	SET BottomBoundHeight TO alt:radar - ship:bounds:bottomaltradar.
	print "Landing".//BUG:
}.

LOCAL DoLanding IS {
	//update to cut vertical velocity most accurately
	GetLandingPoints().
	LOCAL LPVec IS LandPoint:altitudeposition(LandTerrainHeight+BottomBoundHeight).
	LOCAL altdif IS -1*VProjMag(LPVec,ship:up:forevector).	//vertical distance
	//fly towards far end of runway, no throttle, slow descent
	FlightUpdate(lexicon("PitchMode","Vert.Vel."
					,"PitchSetting",max(-1*ship:groundspeed*PlaneStats["ApproachSlope"],-0.25*altdif-1)
					,"HeadingMode","Heading"
					,"HeadingSetting",VecHeading(OtherEnd:position)
					,"ThrottleMode","Throttle"
					,"ThrottleSetting",0)).

	print "VV: "+round(ship:verticalspeed,1)+" : "+round(altdif,1). //BUG:
	IF ship:status = "LANDED" OR ship:status = "SPLASHED" {
		StopSetup().
	}

}.

LOCAL StopSetup IS {
	SET RunState["SubState"]["LandFunc"] TO DoStop.
	SET LandingStatus:text TO "Stopping".
	SET BRAKES TO true.
	GetOtherEnd().
	print "Stopping".//BUG:
}.

LOCAL DoStop IS {
	//stay pointed at far end, little/no pitch input
	FlightUpdate(lexicon("PitchMode","None"
					,"PitchSetting",0
					,"HeadingMode","Heading"
					,"HeadingSetting",VecHeading(OtherEnd:position)
					,"ThrottleMode","Throttle"
					,"ThrottleSetting",0)).
	//some wheelsteering to stay straight
	SET ship:control:wheelsteer TO -VecBearing(OtherEnd:position)/(ship:groundspeed+1).
	
	//if get air again, go back to landing state
	IF ship:status <> "LANDED" AND ship:status <> "SPLASHED" {
		SET BRAKES TO false.
		LandingSetup().
	} ELSE 
	//if stopped, end phase
	IF ship:groundspeed < 0.1 {	
		FlapsAdjust(0).
		SET RunState["Other"] TO "End".
	}
}.
//#close flight functions

//setup panel display #open
function UpdatePanel {
	SET RunwayButton:pressed TO PanelSubState["TargetType"] = "Runway" AND RunwaySelect:index > -1.
	SET RunwayButton:enabled TO RunwaySelect:index > -1.
	
	IF NOT(RunwayButton:enabled) AND (PanelSubState["TargetType"] = "Runway") {
		SET PanelSubState["TargetType"] TO "Lat.Lng.".
	}

	SET WaypointButton:pressed TO PanelSubState["TargetType"] = "Waypoint" AND WaypointSelect:index > -1.
	SET WaypointButton:enabled TO WaypointSelect:index > -1.
	IF NOT(WaypointButton:enabled) AND (PanelSubState["TargetType"] = "Waypoint") {
		SET PanelSubState["TargetType"] TO "Lat.Lng.".
	}

	SET LatLngButton:pressed TO PanelSubState["TargetType"] = "Lat.Lng.".
	
	SET TargetButton:pressed TO PanelSubState["TargetType"] = "Target" AND hastarget.
	
	SET GoButton:enabled TO PanelSubState["TargetType"] <> "".
}

function UpdateRunwaySelect {
	SET FilteredRunways TO RunwaysLoad().
	//filter by the selected body
	LOCAL BodyName TO BodySelect:value.
	SET FilteredRunways TO FilterByFunc(FilteredRunways,
		{parameter s. return s["P1"]:body:name = BodyName.}).
	//filter by those with at least one valid landing direction
	SET FilteredRunways TO FilterByFunc(FilteredRunways,
		{parameter s. return s["Land12"] OR s["Land21"].}).
	
	RunwaySelect:clear().
	SET RunwaySelect:options TO FilteredRunways:keys.
	IF (PanelSubState["TargetType"] = "Runway") AND (PanelSubState["TargetBody"] = BodySelect:value) {
		FOR ind IN RANGE(0,RunwaySelect:options:length,1) {
			IF RunwaySelect:options[ind] = PanelSubState["Target"] {SET RunwaySelect:index TO ind. break.}
		}
	} ELSE IF FilteredRunways:keys:length > 0 {SET RunwaySelect:index TO 0.
	} ELSE { SET RunwaySelect:index TO -1.}
}

function UpdateWaypointSelect {
	SET WaypointNames TO GetWaypointNames().
	LOCAL BodyName TO BodySelect:value.
	SET WaypointNames TO FilterByFunc(WaypointNames,
		{parameter s. return Waypoint(s):body:name = BodyName.}).

	WaypointSelect:clear().
	SET WaypointSelect:options TO WaypointNames.
	IF (PanelSubState["TargetType"] = "Waypoint") AND (PanelSubState["TargetBody"] = BodySelect:value)  {
		FOR ind IN RANGE(0,WaypointSelect:options:length,1) {
			IF WaypointNames[ind] = PanelSubState["Target"] {SET WaypointSelect:index TO ind. break.}
		}
	} ELSE IF WaypointNames:length > 0 {SET WaypointSelect:index TO 0.
	} ELSE {SET WaypointSelect:index TO -1.}
}

//Status panel
LOCAL SB to StatusBox:addstack().
LOCAL SB2 TO MkBox(SB,"VB",lexicon("width",300,"height",80,"padding",OBPad)).
MkLabel(SB2,"<b>Status: Landing</b>",lexicon("fontsize",15,"width",200)).

//landing status description
LOCAL LandingStatus TO MkLabel(SB2,"Initializing",lexicon("hstretch",true)).

//Main Panel
LOCAL MB to ModeControl:addstack().
LOCAL MB2 TO MkBox(MB,"VB",lexicon("width",300,"height",200,"padding",IBPad)).

//select body (filters Runways and waypoints)
LOCAL BodyLine IS MkBox(MB2,"HL",lexicon("width",300,"padding",OBPad)).
MkLabel(BodyLine,"Body:",lexicon("width",40)).
LOCAL BodySelect IS MkPopup(BodyLine,100,20,lexicon("hstretch",true)).
SET BodySelect:onchange TO {
	parameter val.
	UpdateRunwaySelect().
	UpdateWaypointSelect().
	UpdatePanel().
}.

//status and description
MkLabel(MB2,"This will cruise to the selected landing location, descend, land (with flaps), and stop.",lexicon("Width",300,"marginv",2)).

//runway select line
LOCAL RunwayLine IS MkBox(MB2,"HL",lexicon("width",300,"padding",OBPad)).
LOCAL RunwayButton IS MkButton(RunwayLine,"Runway:",{
		parameter val.
		IF val {
			SET PanelSubState["TargetType"] TO "Runway".
			SET PanelSubState["Target"] TO RunwaySelect:value.
		}
		UpdatePanel().
	},lexicon("width",60,"height",20,"toggle",true)).

LOCAL RunwaySelect IS MkPopup(RunwayLine,0,20,lexicon("hstretch",true)).
SET RunwaySelect:index TO -1.
SET RunwaySelect:onchange TO {
	parameter val.
	IF PanelSubState["TargetType"] = "Runway" {SET PanelSubState["Target"] TO RunwaySelect:value.}
	UpdatePanel().
}.

MkLabel(MB2,"The below assume the selected landing zone is flat and level (i.e. water). Use at your own risk.",lexicon("Width",300,"height",25)).
MkLabel(MB2,"NOTE: Waypoint selection updates only on showing this panel. Back out and reselect this panel to update.",lexicon("Width",300,"height",25)).

//waypoint select line
LOCAL WaypointLine IS MkBox(MB2,"HL",lexicon("width",300,"padding",OBPad)).
LOCAL WaypointButton IS MkButton(WaypointLine,"Waypoint:",{
		parameter val.
		IF val {
			SET PanelSubState["TargetType"] TO "Waypoint".
			SET PanelSubState["Target"] TO WaypointSelect:value.
		}
		UpdatePanel().
	},lexicon("width",60,"height",20,"toggle",true)).
LOCAL WaypointSelect IS MkPopup(WaypointLine,0,20,lexicon("hstretch",true)).
SET WaypointSelect:index TO -1.
SET WaypointSelect:onchange TO {
	parameter val.
	IF PanelSubState["TargetType"] = "Waypoint" {SET PanelSubState["Target"] TO WaypointSelect:value.}
	UpdatePanel().
}.

//lat lng select line
LOCAL LatLngLine IS MkBox(MB2,"HL",lexicon("width",300,"padding",OBPad)).
LOCAL LatLngButton IS MkButton(LatLngLine,"Lat.Lng.:",{
		parameter val.
		IF val {
			SET PanelSubState["TargetType"] TO "Lat.Lng.".
			SET PanelSubState["Target"] TO LatLng.
		}
		UpdatePanel().
	},lexicon("width",60,"height",20,"toggle",true)).
MkLabel(LatLngLine,"Lat:",lexicon("width",30,"height",20)).
LOCAL LatEntry IS MkTextInput(LatLngLine,LatLng,0,lexicon("color",yellow,"width",50,"height",20)).
MkLabel(LatLngLine,"Lng:",lexicon("width",30,"height",20)).
LOCAL LngEntry IS MkTextInput(LatLngLine,LatLng,1,lexicon("color",yellow,"width",50,"height",20)).

LOCAL TargetButton TO MkButton(MB2,"Target:",{
		parameter val.
		IF val {
			SET PanelSubState["TargetType"] TO "Target".
			SET PanelSubState["Target"] TO ship:target.
		}
		UpdatePanel().
	},lexicon("width",60,"height",20,"toggle",true)).
//#close setup panel display

function Init {	//update
	// CLEARVECDRAWS(). //debug BUG:
	// SET LandPointDraw:show TO true.
	// SET ApproachPointDraw:show TO true.
	// SET TurnPointDraw:show TO true.
	// SET OtherPointDraw:show TO true.
	// SET ApproachDraw:show TO true.
	// SET FlyApproachDraw:show TO true.

	FlightInit().

	StatusBox:showonly(SB).  //change the status box
	SET RunState["SubState"]["LandFunc"] TO LandStart.
}

//main loop - executes every time through
function Main {
	RunState["SubState"]["LandFunc"]().
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

	//update BodySelect
	SET BodySelect:options TO GetBodyNames().
	//set index to target body
	LOCAL tempindex TO 0.
	UNTIL BodySelect:options[tempindex] = PanelSubState["TargetBody"] {SET tempindex TO tempindex+1.}
	SET BodySelect:index TO tempindex.

	//update runways selection list, and set the selected runway to previous or to first
	UpdateRunwaySelect().	
	
	//update waypoint selection list
	UpdateWaypointSelect().

	//update LatLng Fields
	IF PanelSubState["TargetType"] = "Lat.Lng." {
		SET LatEntry:text TO PanelSubState["Target"][0]:tostring.
		SET LngEntry:text TO PanelSubState["Target"][1]:tostring.
	}

	UpdatePanel().	//update buttons, text, etc.
	
	SET PanelFunc TO {
		IF RunState["PanelType"] <> "Plane" OR RunState["PanelMode"] <> "Landing" {
			SET PanelFunc TO {}.
		}
		SET TargetButton:enabled TO hastarget.
	}.
}

function Display {
	IF PanelSubState["TargetType"] = "Runway" {return "Pl: Land @ "+PanelSubstate["Target"].}
	IF PanelSubState["TargetType"] = "Waypoint" {return "Pl: Land @ "+PanelSubstate["Target"].}
	IF PanelSubState["TargetType"] = "Lat.Lng." {return "Pl: Land @ "+PanelSubstate["Target"][0]+","++PanelSubstate["Target"][1].}
	IF PanelSubState["TargetType"] = "Target" {return "Pl: Land @ Target".}
}

RegisterMode("Plane","Landing",Init@,Main@,End@,SB,MB,PanelInit@,ModeInfo,Display@).

Print "Plane: Landing loaded.".
} //#close