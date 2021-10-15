@LAZYGLOBAL OFF.

GLOBAL PIDAlt TO 0.
GLOBAL PIDVertVelSpeedAdjust TO 0.
GLOBAL PIDThrottle TO 0.
GLOBAL PIDSpeed TO 0.
GLOBAL PIDPitchAng TO 0.
GLOBAL PIDBank TO 0.
GLOBAL PIDYaw TO 0.
GLOBAL ShipEngines TO list().
GLOBAL Flaps TO 0.
GLOBAL ShipThrust TO 0.
LOCAL DesPitchAng TO 0.
LOCAL ControlBearing TO 0.
LOCAL DesBank TO 0.
LOCAL DesHeading IS 0.
LOCAL DesDir IS V(0,0,0).
GLOBAL PlaneFile IS "Default".
LOCAL PitchVel TO 0.
LOCAL DesVertVel TO 0.

//debug
LOCAL DirFore IS vecdraw().
LOCAL DirRoll IS vecdraw().
// end debug

GLOBAL Runways IS RunwaysLoad().

function PlaneDefaults {
	parameter PlaneStatsLocal IS lexicon().
	
	LOCAL ReturnStats IS lexicon(	"PitchMax",		20,		//max pitch
									"PitchMin",		-20,	//min pitch
									"VertVelMax",	200,	//maximum vertical velocity
									"VertVelMin",	-200,	//minimum vertical velocity
									"PitchAoAMax",	15,		//max pitch AoA, lower is smoother but less responsive
									"PitchAoAMin",	-15,		//max pitch AoA, lower is smoother but less responsive
									"TurnAoAMax",	15,		//max turn AoA, lower is smoother but less responsive
									"BankMax",		45,		//max turn bank angle
									"AltCruise",	5000,	//cruising altitude
									"StallSpeed",	70,		//stall speed
									"LandingSpeed",80,	//stall speed with flaps 3 engaged
									"CruiseSpeed",340,		//cruise speed (where it loses performance at higher speed
									"ApproachSlope",0.1,		//slope (horizontal/vertical) for landing approach
									"PlaneRuleSet",	"None",	//ruleset to use
									"TorqueFactorPitch",1,	//torque ratio, lower means it has less control so the steeringmanager will try harder. Adjust if steeringmanager isn't doing well
									"TorqueFactorYaw",1,	
									"TorqueFactorRoll",1,
									"Use Airbrakes",false,	//use airbrakes to slow down if over desired speed
									"TakeOffPitch",	7,		//max pitch angle for takeoff (to avoid tail strikes)
									"MaxWarp",	2).			//maximum physical warp to use
	
	FOR i IN ReturnStats:keys {
		IF PlaneStatsLocal:haskey(i) {SET ReturnStats[i] TO PlaneStatsLocal[i].}	//set to already existing stats, ignore stats no longer used
	}
	return ReturnStats.
}

function FileExists {	//check if file exists
	parameter filename
		, pathwrapper IS {parameter file. return file.}.
	LOCAL PlaneFilePath TO path(pathwrapper(filename)).
	IF EXISTS(PlaneFilePath) {	return true. }
	return false.
}

GLOBAL PlaneStatsFilePath IS {parameter file. return "/AP/json/craft/Plane/"+file+"_Stats.json".}.
LOCAL PlanePresetPath IS "/AP/json/craft/Plane/presets/".
LOCAL PlaneStatsPresetPath IS {parameter file. return PlanePresetPath+file+"_Preset.json".}.

function PlaneStatsExists {
	parameter file.
	return FileExists(file,PlaneStatsFilePath).
}

function LoadPlaneStats {
	parameter file.
	LOCAL PlaneStatsLocal TO lexicon().
	SET file TO PlaneStatsFilePath(file).
	IF EXISTS(file) {	SET PlaneStatsLocal TO readjson(file). }
	SET PlaneStatsLocal TO PlaneDefaults(PlaneStatsLocal).
	return PlaneStatsLocal.
}

function SavePlaneStats {
	parameter PlaneStatsLocal, file.
	SavePlaneStatFile(ship:name,file).
	SET file TO PlaneStatsFilePath(file).
	Create(file).
	writejson(PlaneStatsLocal,file).
}

function LoadPlanePreset {
	parameter file.
	SET file TO PlaneStatsPresetPath(file).
	LOCAL PlaneStatsLocal TO 0.
	IF EXISTS(file) {	SET PlaneStatsLocal TO readjson(file).}
	SET PlaneStatsLocal TO PlaneDefaults(PlaneStatsLocal).
	return PlaneStatsLocal.
}

function SavePlanePreset {
	parameter PlaneStatsLocal, file.
	SET file TO PlaneStatsPresetPath(file).
	Create(file).
	writejson(PlaneStatsLocal,file).
}

function ListPlanePresets {
	LOCAL CurrPath TO path().
	cd(PlanePresetPath).
	LOCAL Presets TO list().
	LIST files IN Presets.
	IF Presets:length > 0 {
		FOR index1 IN RANGE(Presets:length) {
			SET Presets[index1] TO Presets[index1]:tostring:replace("_Preset.json","").
		}
	}
	cd(CurrPath).
	return Presets.
}

LOCAL PlaneStatListPath TO "/AP/json/craft/Plane-Statfiles.json".
function GetPlaneStatFile {	//get the list of plane stat files matched with ship names
	parameter shipname1.
	LOCAL filename IS shipname1.
	LOCAL PlaneFile IS "".
	IF EXISTS(PlaneStatListPath) {
		SET PlaneFile TO readjson(PlaneStatListPath).
		FOR file1 IN PlaneFile:keys {
			IF file1 = shipname1 {SET filename TO PlaneFile[file1].}
		}
	}
	return filename.
}

function SavePlaneStatFile {
	parameter shipname1, filename.
	LOCAL PlaneFile IS lexicon().
	IF EXISTS(PlaneStatListPath) {
		SET PlaneFile TO readjson(PlaneStatListPath).
	}
	SET PlaneFile[shipname1] TO filename.
	Create(PlaneStatListPath).
	writejson(PlaneFile,PlaneStatListPath).
}

function FlightInit {
	SET PIDAlt TO PIDLoop(0.5,0,0.25,PlaneStats["VertVelMin"],PlaneStats["VertVelMax"]). //used to set DesVertVel, KD set based on climb rate and responsiveness
	SET PIDVertVelSpeedAdjust TO PIDLoop(1,1,0.5,0,1). //used to adjust DesVertVel from altitude control if speed is dropping
	SET PIDVertVelSpeedAdjust:setpoint TO 1.
	
	SET PIDThrottle TO PIDLoop(1,0.5,0.5,0,1).
	SET PIDPitchAng TO PIDLoop(0.5,0.5,0.4,PlaneStats["PitchMin"],PlaneStats["PitchMax"]).
	SET PIDBank TO PIDLoop(PlaneStats["BankMax"]*2/PlaneStats["TurnAoAMax"],0.1,2.0,-PlaneStats["BankMax"],PlaneStats["BankMax"]).
	SET PIDYaw TO PIDLoop(1,0.05,1,-PlaneStats["TurnAoAMax"],PlaneStats["TurnAoAMax"]). 
	SET ShipEngines TO list().
	// SET Flaps TO 0. //BUG:
	LIST ENGINES IN ShipEngines.
	SET ShipThrust TO 10.
	SET steeringmanager:rollcontrolanglerange TO 180.
	// SET steeringmanager:YawPID:KI TO 0.
	SET ship:control:mainthrottle TO 0.
	SET steeringmanager:showangularvectors TO FALSE.
	SET steeringmanager:pitchtorquefactor TO PlaneStats["TorqueFactorPitch"].
	SET steeringmanager:yawtorquefactor TO PlaneStats["TorqueFactorYaw"].
	SET steeringmanager:rolltorquefactor TO PlaneStats["TorqueFactorRoll"].
	
	//debug BUG:
	// SET Dirfore TO vecdraw(V(0,0,0),V(0,0,0),yellow,"",10,true).
	// SET DirRoll TO vecdraw(V(0,0,0),V(0,0,0),red,"",5,true).
	//end debug
	
	SET SAS to false.
}

function FlapsAdjust {
	parameter FlapGoal.
	
	//find flaps
	LOCAL TempModules TO ship:modulesnamed("FARControllableSurface").
	FOR Mod1 IN TempModules {
		IF Mod1:hasfield("flap setting") {
			LOCAL i TO Mod1:getfield("flap setting").
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
	
	SET steeringmanager:pitchts TO kuniverse:timewarp:rate^2*2.
	
	//set throttle
	IF ThrottleMode = "Speed" { //if speed, use a two step process (due to jet engine spooling) to get the right thrust

		IF ship:velocity:surface:mag > ThrottleSetting*1.1 {//reset speed control iterms if speed is greater than desspeed and apply the airbrake if allowed
			IF PlaneStats["Use Airbrakes"] AND NOT BRAKES { BRAKES ON.}
		} ELSE IF PlaneStats["Use Airbrakes"] AND BRAKES AND PIDThrottle:Output > 0.3 {BRAKES OFF.}  //turn brakes off if brakes on and throttle over 30%

		SET PIDThrottle:setpoint TO ThrottleSetting.
		SET ship:control:pilotmainthrottle TO PIDThrottle:Update(time:seconds,ship:velocity:surface:mag).
		
	}
	ELSE IF ThrottleMode = "Throttle" {SET ship:control:pilotmainthrottle TO ThrottleSetting.} //if throttle control
	// ELSE {SET ship:control:pilotmainthrottle TO 0.} //if no throttle control desired, don't set throttle to anything


	//set steering

	IF HeadingMode = "None" AND PitchMode = "None" {UNLOCK steering.}
	ELSE {
		//calculate pitch of velocity vector
		SET PitchVel TO arcsin(ship:verticalspeed/ship:velocity:surface:mag). //vertical speed 

		//set pitch control mode
		IF PitchMode = "Target" {
			SET PitchSetting TO PitchSetting:altitude.
			SET PitchMode TO "Altitude".
		}
		IF PitchMode = "Altitude" {
			//set DesVertVel
			SET PIDAlt:setpoint TO PitchSetting.
			SET PIDAlt:KD TO ship:velocity:surface:mag/50.   //make KD bigger the faster you go, to avoid overshooting at high velocity
			//update DesVertVel with PID, then modify based on speed (if speed target is set, reduce DesVertVel if actual speed is below target
			IF ThrottleMode = "Speed" {SET DesVertVel TO PIDAlt:Update(time:seconds,ship:altitude)*(1-PIDVertVelSpeedAdjust:Update(time:seconds,ship:velocity:surface:mag/max(1,ThrottleSetting*0.9))).}
			//else if throttle mode is set, reduce DesVertVel if speed is dropping towards stall speed
			ELSE {SET DesVertVel TO PIDAlt:Update(time:seconds,ship:altitude)*(1-PIDVertVelSpeedAdjust:Update(time:seconds,ship:velocity:surface:mag/max(1,PlaneStats["StallSpeed"]*1.5))).}

			//vertical velocity
			LOCAL PIDPAK TO 0.2*PlaneStats["PitchAoAMax"]/max(ship:velocity:surface:mag/50,1)^1.5. //adjust pitch angle pid based on speed and max AoA of plane. As it gets faster, reduce pitchang PID control
			SET PIDPitchAng:KP TO PIDPAK.
			SET PIDPitchAng:KI TO PIDPAK.
			SET PIDPitchAng:KD TO PIDPAK*0.5.
			SET PIDPitchAng:setpoint TO DesVertVel.
			SET PIDPitchAng:MinOutPut TO max(PitchVel+PlaneStats["PitchAoAMin"],PlaneStats["PitchMin"]).  //adjust pitch min and max output to account for pitchAoAmax
			SET PIDPitchAng:MaxOutPut TO min(PitchVel+PlaneStats["PitchAoAMax"],PlaneStats["PitchMax"]).
			SET DesPitchAng TO PIDPitchAng:Update(time:seconds,ship:verticalspeed).
		}
		
		ELSE IF PitchMode = "Vert.Vel." {
			SET DesVertVel TO PitchSetting.
			LOCAL PIDPAK TO 0.2*PlaneStats["PitchAoAMax"]/max(ship:velocity:surface:mag/50,1)^1.5. //adjust pitch angle pid based on speed and max AoA of plane. As it gets faster, reduce pitchang PID control
			SET PIDPitchAng:KP TO PIDPAK.
			SET PIDPitchAng:KI TO PIDPAK.
			SET PIDPitchAng:KD TO PIDPAK*0.5.
			SET PIDPitchAng:setpoint TO DesVertVel.
			SET PIDPitchAng:MinOutPut TO max(PitchVel+PlaneStats["PitchAoAMin"],PlaneStats["PitchMin"]).
			SET PIDPitchAng:MaxOutPut TO min(PitchVel+PlaneStats["PitchAoAMax"],PlaneStats["PitchMax"]).
			SET DesPitchAng TO PIDPitchAng:Update(time:seconds,ship:verticalspeed).
		}
		ELSE IF PitchMode = "Pitch" {
			SET DesPitchAng TO PitchSetting.
		}
		ELSE IF PitchMode = "AoA" {
			//calculate pitch of current velocity
			SET DesPitchAng TO PitchVel + PitchSetting.
		}
		ELSE IF PitchMode = "None" {
			//calculate actual pitch angle
			LOCAL ShipVertFore TO -1*vdot(ship:facing:forevector,ship:up:forevector)*ship:up:forevector.		//vertical component of ship facing vector
			SET DesPitchAng TO arcsin(ShipVertFore:mag).
		}

		//get current heading if bank selected for heading control
		IF HeadingMode = "Bank" OR HeadingMode = "None" {
			SET DesHeading TO shiphead().
		}
		//if different desired heading, set that
		ELSE IF HeadingMode = "Heading" {SET DesHeading TO HeadingSetting.}
		ELSE IF HeadingMode = "Target" OR HeadingMode = "Lat.Lng." {SET DesHeading TO HeadingSetting:heading. SET HeadingMode TO "Heading".}
		
		
		//calculate heading of current velocity
		LOCAL HeadVel TO VecHeading(ship:velocity:surface).

		//calculate amount to try and turn, based on desired heading, current velocity heading, limited by the max turn amount away from current horizontal velocity heading
		SET ControlBearing TO -PIDYaw:Update(time:seconds,headingrelative(DesHeading-HeadVel)).  //negative because of the coordinate system
		IF HeadingMode = "Heading" OR HeadingMode = "Target" {
			IF abs(ControlBearing) > 1 {		//if more than 3 degrees from control desired heading, bank aircraft
				// steeringmanager:YawPID:reset().
				SET PIDBank:setpoint TO 0.
				//reduce bank angle if near the ground
				IF alt:radar < 500 {SET PIDBank:MinOutPut TO -PlaneStats["BankMax"]*(alt:radar-100)/400. SET PIDBank:MaxOutPut TO PlaneStats["BankMax"]*(alt:radar-100)/400.}
				ELSE {SET PIDBank:MinOutPut TO -PlaneStats["BankMax"]. SET PIDBank:MaxOutPut TO PlaneStats["BankMax"].}
			
				SET DesBank TO PIDBank:Update(time:seconds,ControlBearing).
			
				SET DesDir TO heading(HeadVel+ControlBearing,DesPitchAng,DesBank).

			}
			ELSE {
				SET DesDir TO heading(HeadVel+ControlBearing,DesPitchAng).
			}
		}
		ELSE IF HeadingMode = "Bank" {
			steeringmanager:YawPID:reset().
			SET DesDir TO heading(HeadVel-HeadingSetting/PlaneStats["BankMax"]*PlaneStats["TurnAoAMax"],DesPitchAng,-HeadingSetting).
		}
		ELSE { //HeadingMode = none
			SET ShipVertStar TO -1*vdot(ship:facing:starvector,ship:up:forevector)*ship:up:forevector.  //vertical component of ship starboard vector
			SET DesBank TO arcsin(-1*vdot(ShipVertStar,ship:up:forevector)). //to actual bank angle
			SET DesDir TO heading(HeadVel,DesPitchAng,DesBank).
		}
		LOCK steering TO DesDir.
		
		//debug BUG:
		// SET Dirfore:vec TO DesDir:forevector.
		// SET DirRoll:vec TO DesDir:topvector.
		//end debug
	}
}
	
function FlightEnd {
	// SET ship:control:pilotmainthrottle TO 0.
	SET steeringmanager:pitchts TO 2.
	SET ship:control:neutralize TO true.
	UNLOCK steering.
	IF defined DirFore {SET Dirfore:show TO false.}
	IF defined DirRoll {SET DirRoll:show TO false.}
}

function RunwaysLoad {	//load runways from the file
	LOCAL runwayfile TO path("0:/AP/json/runways.json").
	LOCAL LoadRunways TO lexicon().
	IF EXISTS(runwayfile) {	SET LoadRunways TO readjson(runwayfile). }
	return LoadRunways.
}

function RunwaysSave {	//write runways to the file
	parameter SaveRunways.
	LOCAL runwayfile TO path("0:/AP/json/runways.json").
	Create(runwayfile).
	writejson(SaveRunways,runwayfile). 
}

PRINT "PlaneLib loaded".