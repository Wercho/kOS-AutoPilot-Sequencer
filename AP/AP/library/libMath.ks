@LAZYGLOBAL OFF.

function Limits {
	parameter input1, 
		minval,	//minimum limit
		maxval. //maximum limit
	return min(maxval,max(minval,input1)).
}

function headingnormal { //convert a heading to range [0,360)
	parameter heading1.
	SET heading1 TO MOD(heading1,360).
	IF heading1 < 0 {SET heading1 TO heading1 + 360.}
	
	// UNTIL heading1 >= 0 AND heading1<360 {
		// IF heading1 < 0 {SET heading1 TO heading1 + 360.}
		// ELSE IF heading1 >= 360 {set heading1 TO heading1 - 360.}
	// }
	return heading1.
}

function headingrelative {
	parameter heading1.
	SET heading1 TO MOD(heading1,360).
	IF heading1 > 180 {SET heading1 TO heading1 - 360.}
	IF heading1 < -180 {SET heading1 TO heading1 + 360.}
	return heading1.
}

function VecHeading {  //get a heading from a vector
	parameter Vector.
	LOCAL VectorH TO vxcl(ship:up:forevector,Vector).
	LOCAL VectorN TO vdot(VectorH,ship:north:forevector).
	LOCAL VectorE TO vdot(VectorH,vcrs(ship:up:forevector,ship:north:forevector)).
	LOCAL VecHead TO arccos(VectorN/VectorH:mag).
	IF VectorE < 0 {SET VecHead TO -1*VecHead.}
	RETURN headingnormal(VecHead).
}

function ShipHead { //get ship's current heading
	return headingnormal(-1*latlng(90,0):bearing).
}

function VecBearing { //get bearing of a vector
	parameter Vector.
	LOCAL ShipForeH IS vxcl(ship:up:forevector,ship:facing:forevector).
	LOCAL ShipStarH IS vxcl(ship:up:forevector,ship:facing:starvector).
	LOCAL VecForeH IS VProjMag(Vector,ShipForeH).
	LOCAL VecH IS vxcl(ship:up:forevector,Vector).
	LOCAL VecBear TO arccos(VecForeH/max(VecH:mag,VecForeH)).	//calculates angle from forward
	IF VProjMag(Vector,ShipStarH) < 0 {SET VecBear TO -1*VecBear.} //determines left or right
	return VecBear.
}

function ShipRel {		//convert a vector to ship relative
	parameter temp1.
	return ship:facing:inverse * temp1.
}

//deep copies a list or lexicon, 
//meaning it copies it value by value, and nothing by reference 
function LCopy { 
	parameter lex1.
	LOCAL lex2 IS lex1.  //copies it if it is a value
	IF lex2:istype("lexicon")   //could be either a list or lexicon, so check
	{
		SET lex2 TO lex1:copy().	//shallow copy the lexicon
		IF lex2:length>0 {
			FOR item IN lex2:keys   //loop through keys of lexicon
			{
				//if the value is a list or lexicon, recursive call this function
				IF lex2[item]:istype("lexicon") OR lex2[item]:istype("list") 
				{ SET lex2[item] TO LCopy(lex2[item]).}
			}
		}
	}
	ELSE IF lex2:istype("list") 
	{
		SET lex2 TO lex1:copy().	//shallow copy the list
		IF lex2:length>0 {
			FOR iter IN RANGE(0,lex2:length,1) {
				//if the value is a list or lexicon, recursive call this function
				IF lex2[iter]:istype("lexicon") OR lex2[iter]:istype("list") 
				{ SET lex2[iter] TO LCopy(lex2[iter]).}
			}
		}
	}
	RETURN lex2.  //return the deep copied list/lexicon/value
}

function LCopyInto { 	//only works for single level
	parameter lex1, lex2.
	IF lex1:istype("lexicon") {
		FOR item IN lex1:keys {
			SET lex2[item] TO lex1[item].
		}
	} ELSE {
		FOR item IN RANGE(0,lex1:length,1) {
			SET lex2[item] TO lex1[item].
		}
	}
}


function RandID {	//creates a random ID of uppercase letters
	parameter length1.	//length of string to return
	
	LOCAL IDvar IS "".
	FROM {LOCAL index1 IS length1.} UNTIL index1=0 STEP {SET index1 TO index1-1.} DO {
		SET IDvar TO IDvar:replace(IDvar,IDvar + char(random()*26+65)).
	}
	RETURN IDvar.
}


function MakeGeo {
	parameter GeoList.	//body, lat, lng
	// IF BodyExists(GeoList[0]) {
		return Body(GeoList[0]):geopositionlatlng(GeoList[1],GeoList[2]).
	// } ELSE {return latlng(0,0).}
}

function GetWaypointNames {
	LOCAL Waypoints IS allwaypoints().
	LOCAL WPNames IS list().
	FOR ind IN Waypoints {WPNames:add(ind:name).}
	return WPNames.
}

function FilterByFunc {
	parameter item1, func.
	LOCAL ReturnItems TO 0.
	IF item1:istype("lexicon") {
		SET ReturnItems TO lexicon().
		FOR item IN item1:keys {
			IF func(item1[item]) {ReturnItems:add(item,item1[item]).}
		}
	} ELSE IF item1:istype("list") {
		SET ReturnItems TO list().
		FOR item in item1 {
			IF func(item) {ReturnItems:add(item).}
		}
	}
	return ReturnItems.	
}

function GetBodyNames {
	LOCAL AllBodies IS list().
	LOCAL BodyNames IS list().
	LIST Bodies IN AllBodies.
	FOR body1 IN AllBodies {
		BodyNames:add(body1:name:tostring).
	}
	return BodyNames.
}

function VProjMag { //magnitude of projection of v1 onto v2
	parameter v1, v2.
	return vdot(v1,v2:normalized).
}

function VProj {	//projection of v1 onto v2
	parameter v1, v2.
	return vdot(v1,v2:normalized)*v2:normalized.
}

print "libmath loaded".