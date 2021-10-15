@LAZYGLOBAL OFF.
//boot script to start the autopilot.
//It will:
//	0. Rename the CPU
//	1. Check for connection to Commnet
//		a. Copy autopilot to the local drive
//	2. Check for an autopilto status file (APStatus.json)
//		a. Load the status file
//		b. Run the autopilot with params
//		-a. Run the autopilot with no params



clearguis().
//wait for vessel to load BUG: if this doesn't work consistently, wait for vessel to unpack
WAIT UNTIL ship:loaded.
SET Volume(1):name TO "CPUMain".

// 1. Check for connection to Commnet
LOCAL APLocal TO false.	//tracks whether the AP is present
IF Homeconnection:isconnected {
//		a. Copy autopilot to local drive
	CopyAP().
	SET APLocal TO true.
} ELSE IF EXISTS("CPUMain:/AP") {	//no connection, but AP already present
	SET APLocal TO true.
}

//if AP is local, then check for status and run it
IF APLocal {
	//Check for APStatus.json - holds state of AP when vessel last activated something
	LOCAL StatusFilename TO "APStatus.json".
	IF EXISTS(StatusFilename) {
		//	a. Load filename
		LOCAL StatusState TO readjson(StatusFilename).
		//	b. Run autopilot with status
		RUNPATH("AP/AP",StatusState).
	} ELSE {
		RUNPATH("AP/AP").
	}
}
cd("CPUmain:").

//#open - define functions					
function CopyAP {
	Copypath("0:/AP","CPUMain:").
	Copypath("0:/AP.ks","CPUMain:").
	Copypath("0:/AP_copytoarchive","CPUmain:").
	Deletepath("CPUmain:/AP/json").	//delete these files
	Copypath("0:/AP/json/craft","CPUmain:/AP/json/craft").	//only copy specific files from this directory
	Copypath("0:/AP/json/flightplan","CPUmain:/AP/json/flightplan").
	Copypath("0:/AP/json/runways.json","CPUmain:/AP/json/").
}
//#close - define functions
