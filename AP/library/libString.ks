@LAZYGLOBAL OFF.

function NumFormat { //formates a number with SI prefixes, match round arg order
	parameter num, dec IS 1, pad is false.
	LOCAL numletters is lexicon(1000000000000,"T",
								1000000000,"G",
								1000000,"M",
								1000,"k",
								1,"").
	LOCAL minnum TO numletters:keys[numletters:keys:length-1].
	IF dec > 15 {SET dec TO 15.}	//largest allowed by kOS
	SET num TO round(num,dec).
	LOCAL letter TO numletters[minnum].
	FOR ind IN numletters:keys {
		IF num>ind {
			SET num TO round(num/ind,dec).
			SET letter TO numletters[ind].
			break.
		}
	}
	SET num TO num:tostring.
	IF pad {
		LOCAL decplace TO num:find("."). //find the decimal point location
		IF decplace < 0 {	//if none, add and redo
			SET num TO num+".".
			SET decplace TO num:length-1.
		}
		UNTIL num:length = (decplace+dec+1) {//loop until enough decimal places
			SET num TO num+"0".
		}
	}
	return num+letter.
}

function NF {	//wrapper for NumFormat, adds suffix
	parameter dec, addlab, pad, num.
	return NumFormat(num,dec,pad)+addlab.
}

function TimeFormatApprox {	//formats a time to largest unit
	parameter num, dec IS 1, pad is false.
	LOCAL numletters is lexicon(3600," hr",
								60," min",
								1," sec").
	SET num TO round(num,dec).
	LOCAL letter TO numletters[1].
	FOR ind IN numletters:keys {
		IF num>ind {
			SET num TO round(num/ind,dec).
			SET letter TO numletters[ind].
			break.
		}
	}
	SET num TO num:tostring.
	IF pad {
		LOCAL decplace TO num:find("."). //find the decimal point location
		IF decplace < 0 {	//if none, add and redo
			SET num TO num+".".
			SET decplace TO num:length-1.
		}
		UNTIL num:length = (decplace+dec+1) {//loop until enough decimal places
			SET num TO num+"0".
		}
	}
	return num+letter.
}

function TFA {	//wrapper for TimeFormatApprox (switches arguement)
	parameter dec, num.
	return TimeFormatApprox(num,dec).
}

function NumParse {	//parses text input such as "1.1k" as 1100
	parameter intext, default.
	LOCAL numletters is lexicon(
								"T",1000000000000,
								"G",1000000000,
								"M",1000000,
								"k",1000,
								"",1).
	SET intext TO intext:trim.	//trim spaces
	//if pattern is bad, return default
	IF NOT(intext:matchespattern("^-?\d*(\.\d*)?[TGMk]?$")) {return default.}
	
	LOCAL getlast TO intext:substring(intext:length-1,1).
	IF numletters:haskey(getlast) { //if last char is in the list, multiply
		return intext:remove(intext:length-1,1):tonumber*numletters[getlast].
	} ELSE {
		return intext:tonumber.
	}
}

function TimeParse {	//parses text input such as "1.1h" as 3960 (seconds)
	parameter intext, default.
	LOCAL numletters is lexicon(
								"h",3600,
								"m",60,
								"s",1).
	SET intext TO intext:trim.	//trim spaces
	//if pattern is bad, return default
	IF NOT(intext:matchespattern("^-?\d*(\.\d*)?[hms]?$")) {return default.}
	
	LOCAL getlast TO intext:substring(intext:length-1,1).
	IF numletters:haskey(getlast) { //if last char is in the list, multiply
		return intext:remove(intext:length-1,1):tonumber*numletters[getlast].
	} ELSE {
		return intext:tonumber.
	}
}//#close number-string formatting


print "libString loaded".