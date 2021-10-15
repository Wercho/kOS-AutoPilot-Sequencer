GLOBAL PIDAlt TO 0.
GLOBAL PIDVertVelSpeedAdjust TO 0.
GLOBAL PIDThrottle TO 0.
GLOBAL PIDSpeed TO 0.
GLOBAL PIDPitchAng TO 0.
GLOBAL PIDBank TO 0.
GLOBAL ShipEngines TO list().
GLOBAL Flaps TO 0.
GLOBAL ShipThrust TO 0.


function PlaneDefaults {
	parameter PlaneStats.
	//set defaults
	IF NOT PlaneStats:haskey("PitchMax") {SET PlaneStats["PitchMax"] TO 20.}	//max pitch
	IF NOT PlaneStats:haskey("PitchMin") {SET PlaneStats["PitchMin"] TO -20.}	 //min pitch
	IF NOT PlaneStats:haskey("VertVelMax") {SET PlaneStats["VertVelMax"] TO 200.}	 //maximum vertical velocity
	IF NOT PlaneStats:haskey("VertVelMin") {SET PlaneStats["VertVelMin"] TO -200.}	//minimum vertical velocity
	IF NOT PlaneStats:haskey("PitchAoAMax") {SET PlaneStats["PitchAoAMax"] TO 5.}	 //max angle to set the desired facing compared to current, lower is smoother but less responsive
	IF NOT PlaneStats:haskey("PitchTurnMax") {SET PlaneStats["PitchTurnMax"] TO 15.}	//max pitch to apply during a turn, lower is slower but smoother
	IF NOT PlaneStats:haskey("BankMax") {SET PlaneStats["BankMax"] TO 45.}	  //max bank angle
	IF NOT PlaneStats:haskey("AltCruise") {SET PlaneStats["AltCruise"] TO 5000.}	  //cruising altitude (based on engine, lift)
	IF NOT PlaneStats:haskey("SpeedStall") {SET PlaneStats["SpeedStall"] TO 70.}	  //stall speed
	IF NOT PlaneStats:haskey("ApproachRatio") {SET PlaneStats["ApproachRatio"] TO 10.} //glide ratio for landing approach
	IF NOT PlaneStats:haskey("ApproachDist") {SET PlaneStats["ApproachDist"] TO 20000.}//landing approach characteristic distance
	IF NOT PlaneStats:haskey("PlaneRuleSet") {SET PlaneStats["PlaneRuleSet"] TO "None".}	
	IF NOT PlaneStats:haskey("TorqueFactorPitch") {SET PlaneStats["TorqueFactorPitch"] TO 1.}	//torque ratio, lower means it has less control so the steeringmanager will try harder. Adjust if steeringmanager isn't doing well
	IF NOT PlaneStats:haskey("TorqueFactorYaw") {SET PlaneStats["TorqueFactorYaw"] TO 1.}	
	IF NOT PlaneStats:haskey("TorqueFactorRoll") {SET PlaneStats["TorqueFactorRoll"] TO 1.}	
	IF NOT PlaneStats:haskey("Use Airbrakes") {SET PlaneStats["Use Airbrakes"] TO TRUE.}	 //use brakes on final approach for landing
	IF NOT PlaneStats:haskey("TakeOffPitch") {SET PlaneStats["TakeOffPitch"] TO 7.}	 //takeoff pitch angle
	IF NOT PlaneStats:haskey("MaxWarp") {SET PlaneStats["MaxWarp"] TO 2.}	 //maximum physics warp this plane can handle
	return PlaneStats.
}

function LoadPlaneStats {
	LOCAL PlaneFile TO path("0:/AP/json/craft/Plane/"+ship:name+"_Stats.json").

	LOCAL PlaneStats TO lexicon().
	IF EXISTS(PlaneFile) {	SET PlaneStats TO readjson(PlaneFile). }

	SET PlaneStats TO PlaneDefaults(PlaneStats).
	return PlaneStats.
}

function SavePlaneStats {
	parameter PlaneStats.
	LOCAL PlaneFile TO path("0:/AP/json/craft/Plane/"+ship:name+"_Stats.json").
	writejson(PlaneStats,PlaneFile).
}

function SavePlaneStatsAs {
	parameter PlaneStats,
			filename.
	LOCAL PlaneFile TO path("0:/AP/json/craft/Plane/presets/"+filename+".json").
	writejson(PlaneStats,PlaneFile).
}

function LoadPlaneStatsAs {
	parameter filename.
	LOCAL PlaneFile TO path("0:/AP/json/craft/Plane/presets/"+filename+".json").

	LOCAL PlaneStats TO lexicon().  //set defaults
	IF EXISTS(PlaneFile) {	SET PlaneStats TO readjson(PlaneFile). }
	
	SET PlaneStats TO PlaneDefaults(PlaneStats).
	return PlaneStats.
}


function FlightInit {
	SET PIDAlt TO PIDLoop(0.5,0,0.25,PlaneStats["VertVelMin"],PlaneStats["VertVelMax"]). //used to set DesVertVel, KD set based on climb rate and responsiveness
	SET PIDVertVelSpeedAdjust TO PIDLoop(1,1,0.5,0,1). //used to adjust DesVertVel from altitude control if speed is dropping
	SET PIDVertVelSpeedAdjust:setpoint TO 1.
	
	SET PIDThrottle TO PIDLoop(1,0.5,0,0,1).
	SET PIDSpeed TO PIDLoop(1,0.5,0.5).
	SET PIDPitchAng TO PIDLoop(0.05,0.05,0.1,PlaneStats["PitchMin"],PlaneStats["PitchMax"]).
	SET PIDBank TO PIDLoop(max(PlaneStats["BankMax"],40),0,0.05,-PlaneStats["BankMax"],PlaneStats["BankMax"]).
	SET ShipEngines TO list().
	SET Flaps TO 0.
	LIST ENGINES IN ShipEngines.
	SET ShipThrust TO 10.
	SET steeringmanager:rollcontrolanglerange TO 180.
	// SET steeringmanager:YawPID:KI TO 0.
	SET ship:control:mainthrottle TO 0.
	SET ship:control:pilotmainthrottle TO 0.
	SET steeringmanager:showangularvectors TO FALSE.
	SET steeringmanager:pitchtorquefactor TO PlaneStats["TorqueFactorPitch"].
	SET steeringmanager:yawtorquefactor TO PlaneStats["TorqueFactorYaw"].
	SET steeringmanager:rolltorquefactor TO PlaneStats["TorqueFactorRoll"].
}

function FlapsAdjust {
	parameter FlapGoal.
	
	//find flaps
	LOCAL TempModules TO ship:modulesnamed("FARControllableSurface").
	FOR Mod1 IN TempModules {
		IF Mod1:hasfield("flap setting") {
			SET i TO Mod1:getfield("flap setting").
			UNTIL i = FlapGoal {
				IF i > FlapGoal {
					Mod1:doevent("deflect less").
					SET i TO i-1.
				} ELSE {
					Mod1:doevent("deflect more").
					SET i TO i+1.
				}
			}
		}
	}
}

function FlightUpdate {
	parameter FlightState.
	
	LOCAL PitchMode IS FlightState["PitchMode"].
	LOCAL PitchSetting IS FlightState["PitchSetting"].
	LOCAL HeadingMode IS FlightState["HeadingMode"].
	LOCAL HeadingSetting IS FlightState["HeadingSetting"].
	LOCAL ThrottleMode IS FlightState["ThrottleMode"].
	LOCAL ThrottleSetting IS FlightState["ThrottleSetting"].
	
	//set throttle
	IF ThrottleMode = "Speed" {
		SET ShipThrust TO 0.
		FOR eng IN ShipEngines {SET ShipThrust TO ShipThrust + eng:thrust.}
		SET PIDSpeed:setpoint TO ThrottleSetting.
		SET DesThrust TO PIDSpeed:Update(time:seconds,ship:velocity:surface:mag).

		IF ship:velocity:surface:mag > ThrottleSetting*1.1 {//reset speed control iterms if speed is greater than desspeed and apply the airbrake if allowed
			PIDSpeed:reset().
			IF PlaneStats["Use Airbrakes"] AND NOT BRAKES { BRAKES ON.}
		} ELSE IF PlaneStats["Use Airbrakes"] AND BRAKES AND PIDThrottle:Output > 0.3 {BRAKES OFF.}

		IF PIDThrottle:Output > 0.99 AND PIDSpeed:KI<>0{ //prevent pidspeed windup
			SET PIDSpeed:MaxOutPut TO ship:velocity:surface:mag.
		} ELSE IF PIDSpeed:KI <>0 AND PIDSpeed:MaxOutPut < 999999 {
			SET PIDSpeed:MaxOutPut TO 1000000.
		}
		SET PIDThrottle:setpoint TO DesThrust.
		SET ship:control:pilotmainthrottle TO PIDThrottle:Update(time:seconds,ShipThrust).
		
	}
	ELSE IF ThrottleMode = "Throttle" {SET ship:control:pilotmainthrottle TO ThrottleSetting.} //if throttle control
	//ELSE {SET ship:control:pilotmainthrottle TO 0.} //if no throttle control desired, don't set throttle to anything


	//set steering

	IF HeadingMode = "None" AND PitchMode = "None" {UNLOCK steering.}
	ELSE {
		LOCAL DesHeading TO 0.
		//get current heading if bank selected for heading control
		IF HeadingMode = "Bank" OR HeadingMode = "None" {
			SET DesHeading TO shiphead().
		}
		//if different desired heading, set that
		ELSE IF HeadingMode = "Heading" {SET DesHeading TO HeadingSetting.}
		ELSE IF HeadingMode = "Target" OR HeadingMode = "LatLng" {SET DesHeading TO HeadingSetting:heading. SET HeadingMode TO "Heading".}
		
		
		//calculate ship directions
		SET ShipHorizFore TO ship:facing:forevector + -1*vdot(ship:facing:forevector,ship:up:forevector)*ship:up:forevector.
		SET ShipHorizFore:mag TO 1.
		SET ShipVertFore TO -1*vdot(ship:facing:forevector,ship:up:forevector)*ship:up:forevector.
		SET ShipHorizStar TO ship:facing:starvector + -1*vdot(ship:facing:starvector,ship:up:forevector)*ship:up:forevector.
		SET ShipHorizStar:mag TO 1.
		SET ShipVertStar TO -1*vdot(ship:facing:starvector,ship:up:forevector)*ship:up:forevector.
		//calculate actual pitch angle
		SET PitchAct TO arcsin(-1*vdot(ShipVertFore,ship:up:forevector)).

		// calculate difference between desired and actual heading
		SET HorizDiffFore TO vdot(heading(DesHeading,0):forevector,ShipHorizFore).
		SET HorizDiffStar TO vdot(heading(DesHeading,0):forevector,ShipHorizStar).
		SET VertDiffStar TO vdot(heading(DesHeading,0):forevector,ShipHorizStar).
		IF HorizDiffFore < 0 AND abs(HorizDiffStar) < 0.02 {SET HorizDiffStar TO -1.} //if 180 deg turn, turn left
		IF HorizDiffFore < 0 { SET HorizDiffStar TO HorizDiffStar/abs(HorizDiffStar).} //if more than 90deg, turn as if 90

		
		//set pitch
		IF PitchMode = "Target" {
			SET PitchSetting TO PitchSetting:altitude.
			SET PitchMode TO "Altitude".
		}
		IF PitchMode = "Altitude" {
			//set DesVertVel
			SET PIDAlt:setpoint TO PitchSetting.
			LOCAL PIDPAK TO 10/max(ship:velocity:surface:mag,20).
			SET PIDAlt:KD TO ship:velocity:surface:mag/50.
			IF ThrottleMode = "Speed" {SET DesVertVel TO PIDAlt:Update(time:seconds,ship:altitude)*(1-PIDVertVelSpeedAdjust:Update(time:seconds,ship:velocity:surface:mag/max(1,ThrottleSetting*0.9))).}
			ELSE {SET DesVertVel TO PIDAlt:Update(time:seconds,ship:altitude)*(1-PIDVertVelSpeedAdjust:Update(time:seconds,ship:velocity:surface:mag/max(1,PlaneStats["SpeedStall"]*1.5))).}

			//vertical velocity
			LOCAL PIDPAK TO 10/max(ship:velocity:surface:mag,20).
			SET PIDPitchAng:KP TO PIDPAK.
			SET PIDPitchAng:KI TO PIDPAK.
			SET PIDPitchAng:KD TO PIDPAK*0.5.
			SET PIDPitchAng:setpoint TO DesVertVel.
			SET PIDPitchAng:MinOutPut TO max(PitchAct-PlaneStats["PitchAoAMax"],PlaneStats["PitchMin"]).
			SET PIDPitchAng:MaxOutPut TO min(PitchAct+PlaneStats["PitchAoAMax"],PlaneStats["PitchMax"]).
			IF abs(HorizDiffStar) > 0.08  {SET PIDPitchAng:MinOutPut TO 0.}
			SET DesPitchAng TO PIDPitchAng:Update(time:seconds,ship:verticalspeed).
		}
		
		ELSE IF PitchMode = "Vert.Vel." {
			SET DesVertVel TO PitchSetting.
			LOCAL PIDPAK TO 10/min(ship:velocity:surface:mag,20).
			SET PIDPitchAng:KP TO PIDPAK.
			SET PIDPitchAng:KI TO PIDPAK.
			SET PIDPitchAng:KD TO PIDPAK*0.5.
			SET PIDPitchAng:setpoint TO DesVertVel.
			SET PIDPitchAng:MinOutPut TO max(PitchAct-PlaneStats["PitchAoAMax"],PlaneStats["PitchMin"]).
			SET PIDPitchAng:MaxOutPut TO min(PitchAct+PlaneStats["PitchAoAMax"],PlaneStats["PitchMax"]).
			IF abs(HorizDiffStar) > 0.08  {SET PIDPitchAng:MinOutPut TO 0.}
			SET DesPitchAng TO PIDPitchAng:Update(time:seconds,ship:verticalspeed).
		}
		ELSE IF PitchMode = "Pitch" {
			SET DesPitchAng TO PitchSetting.
		}
		ELSE IF PitchMode = "AoA" {
			//calculate pitch of current velocity
			SET PitchVelAct TO arcsin(ship:verticalspeed/ship:velocity:surface:mag).
			SET DesPitchAng TO PitchVelAct + PitchSetting.
		}
		ELSE IF PitchMode = "None" {
			SET DesPitchAng TO PitchAct.
		}

		LOCAL DesBank TO 0.
		IF HeadingMode = "Heading" OR HeadingMode = "Target" {
			IF abs(HorizDiffStar) > 0.08 {
				steeringmanager:YawPID:reset().
				SET PIDBank:setpoint TO 0.
				IF alt:radar < 500 {SET PIDBank:MinOutPut TO -PlaneStats["BankMax"]*(alt:radar-100)/400. SET PIDBank:MaxOutPut TO PlaneStats["BankMax"]*(alt:radar-100)/400.}
				ELSE {SET PIDBank:MinOutPut TO -PlaneStats["BankMax"]. SET PIDBank:MaxOutPut TO PlaneStats["BankMax"].}
			
				SET DesBank TO PIDBank:Update(time:seconds,-HorizDiffStar).
			
				SET DesDir TO LOOKDIRUP(ShipHorizFore,ship:up:forevector).
				SET DesDir TO AngleAxis(15*sin(DesBank),DesDir:topvector)*DesDir. //yaw adjust
				SET DesDir TO AngleAxis(-DesPitchAng,DesDir:starvector)*DesDir. //pitch adjust
				SET DesDir TO AngleAxis(-DesBank,DesDir:forevector)*DesDir.  //roll adjust
			}
			ELSE {
				SET DesDir TO heading(Desheading,DesPitchAng).
			}
		}
		ELSE IF HeadingMode = "Bank" {
			steeringmanager:YawPID:reset().
			SET DesBank TO HeadingSetting.
			SET DesDir TO LOOKDIRUP(ShipHorizFore,ship:up:forevector).
			SET DesDir TO AngleAxis(15*sin(DesBank),DesDir:topvector)*DesDir. //yaw adjust
			SET DesDir TO AngleAxis(-DesPitchAng,DesDir:starvector)*DesDir. //pitch adjust
			SET DesDir TO AngleAxis(-DesBank,DesDir:forevector)*DesDir.  //roll adjust
		}
		ELSE { //HeadingMode = none
			SET BankAct TO arcsin(-1*vdot(ShipVertStar,ship:up:forevector)).
			SET DesDir TO LOOKDIRUP(ShipHorizFore,ship:up:forevector).
			SET DesDir TO AngleAxis(-DesPitchAng,DesDir:starvector)*DesDir. //pitch adjust
			SET DesDir TO AngleAxis(-DesBank,DesDir:forevector)*DesDir.  //roll adjust
		}
		LOCK steering TO DesDir.
		// SET aa TO vecdraw(v(0,0,0),10*DesDir:forevector,WHITE,"",1,TRUE).
	}
}
	
function FlightEnd {
	SET ship:control:pilotmainthrottle TO 0.
	SET ship:control:neutralize TO true.
}
	
function takeoff {
	parameter TakeOffState.
	//find runway currently at
	IF TakeOffState[0] = "Start" {
		loadrunways().
		LOCAL RunwayAt IS 0.
		LOCAL RunwayDist IS 10^12. //just really large
		IF runways:length > 0 {
			FOR runway IN runways {
				IF RunwayPointGeo(runway["P1point"]):distance < RunwayDist {
					SET RunwayAt TO runway.
					SET RunwayDist TO RunwayPointGeo(runway["P1point"]):distance.
				}
			}
			IF RunwayDist > 5000 {SET RunwayAt TO "None".}
		}
		ELSE {SET RunwayAt TO "None".}
		
		//find end of runway pointed at
		IF RunwayAt = "None" { //set target a long way out in front of ship
			SET TakeOffState[1] TO ship:body:geopositionof(5000*ship:facing:forevector).
		} ELSE {
			IF abs(RunwayPointGeo(RunwayAt["P1point"]):bearing) < abs(RunwayPointGeo(RunwayAt["P2point"]):bearing) {
				SET TakeOffState[1] TO RunwayPointGeo(RunwayAt["P1point"]).
			} ELSE {SET TakeOffState[1] TO RunwayPointGeo(RunwayAt["P2point"]).}
		}
		
		BRAKES OFF.
		SET TakeOffState[0] TO "Launch".
		FlapsAdjust(3).
	}
	
	IF TakeOffState[0] = "Launch" {
		FlightUpdate("Pitch",PlaneStats["TakeOffPitch"],"Throttle",1,"LatLng",TakeOffState[1],FALSE).
		IF abs(TakeOffState[1]:bearing) > 2 AND ship:velocity:surface:mag < 10 {SET ship:control:wheelsteer TO TakeOffState[1]:bearing*-0.02.}
		ELSE {SET ship:control:wheelsteer TO 0.}

		IF alt:radar > 50 AND ship:status <> "landed" {
			GEAR OFF.
			SET TakeOffState[0] TO "Climb".
		}
	} ELSE IF TakeOffState[0] = "Climb" { //climbing
		FlightUpdate("Altitude",ship:geoposition:terrainheight + 2000,"Throttle",1,"Bank",0,FALSE).
		IF alt:radar > 900 {SET TakeOffState[0] TO "Flying".}
	}
	IF TakeOffState[0] = "Flying" {FlapsAdjust(0).}

}

PRINT "PlaneLib loaded".