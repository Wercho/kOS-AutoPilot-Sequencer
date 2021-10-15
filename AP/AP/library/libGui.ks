@LAZYGLOBAL OFF.

global mygreen TO rgb(0/255,255/255,0/255).
global myred TO rgb(153/255,31/255,31/255).
global myyellow to rgb(200/255,200/255,41/255).
global myblue TO rgb(31/255,31/255,153/255).

GLOBAL OBPad TO list(0,0,0,0).
GLOBAL IBPad TO list(3,3,3,3).
GLOBAL NoMar TO list(0,0,0,0).
GLOBAL BMar TO list(2,2,2,2).


function SetTextColor {
	parameter Sty,col.
	SET Sty:normal:textcolor TO col.
	SET Sty:normal_on:textcolor TO col.
	SET Sty:hover:textcolor TO col.
	SET Sty:hover_on:textcolor TO col.
	SET Sty:active:textcolor TO col.
	SET Sty:active_on:textcolor TO col.
	SET Sty:focused:textcolor TO col.
	SET Sty:focused_on:textcolor TO col.
}

function SetMarg {
	parameter Wid,t,b,l,ri.
	IF t>-1 {SET Wid:style:margin:top TO t.}
	IF b>-1 {SET Wid:style:margin:bottom TO b.}
	IF l>-1 {SET Wid:style:margin:left TO l.}
	IF ri>-1 {SET Wid:style:margin:right TO ri.}
}

function SetPad {
	parameter Wid,t,b,l,ri.
	IF t>-1 {SET Wid:style:padding:top TO t.}
	IF b>-1 {SET Wid:style:padding:bottom TO b.}
	IF l>-1 {SET Wid:style:padding:left TO l.}
	IF ri>-1 {SET Wid:style:padding:right TO ri.}
}

function MkButton {
	parameter parent1,
	text,			//display text
	effect,			//function of what happens onclick
	other IS lexicon().
	
	LOCAL T is parent1:addbutton(text).

	//set parameters, if no key, then set defaults for some
	IF other:haskey("fontsize") {SET T:style:fontsize TO other["fontsize"].}
	IF other:haskey("color") {SetTextColor(T:style,other["color"]).}
	IF other:haskey("width") {SET T:style:width TO other["width"].}
	IF other:haskey("height") {SET T:style:height TO other["height"].}
	IF other:haskey("hstretch") {SET T:style:hstretch TO other["hstretch"].}
	IF other:haskey("align") {SET T:style:align TO other["align"].}

	//toggle block
	IF NOT other:haskey("toggle") {other:add("toggle",false).}
	SET T:toggle TO other["toggle"].
	IF other["toggle"] {SET T:ontoggle TO effect.}
	ELSE {SET T:onclick TO effect.}
	
	//margins
	IF other:haskey("margins") {
		SetMarg(T,other["margins"][0],other["margins"][1],other["margins"][2],other["margins"][3]).}
	ELSE IF other:haskey("marginv") {	//for backwards compatibility
		SetMarg(T,other["marginv"],other["marginv"],-1,-1).}

	//padding
	IF other:haskey("padding") {
		SetPad(T,other["padding"][0],other["padding"][1],other["padding"][2],other["padding"][3]).}
	ELSE IF other:haskey("paddingv") {	//for backwards compatibility
		SetPad(T,other["paddingv"],other["paddingv"],-1,-1).}
	
	return T.
}

function MkLabel {
	parameter parent1,
	text,
	other IS lexicon().
	
	LOCAL T is parent1:addlabel(text:tostring).
	//set parameters, if no key, then set defaults for some
	IF other:haskey("fontsize") {SET T:style:fontsize TO other["fontsize"].}
	IF other:haskey("color") {SetTextColor(T:style,other["color"]).}
	IF other:haskey("width") {SET T:style:width TO other["width"].}
	IF other:haskey("height") {SET T:style:height TO other["height"].}
	IF other:haskey("hstretch") {SET T:style:hstretch TO other["hstretch"].}
	IF other:haskey("align") {SET T:style:align TO other["align"].}
		
	//margins
	IF other:haskey("margins") {
		SetMarg(T,other["margins"][0],other["margins"][1],other["margins"][2],other["margins"][3]).}
	ELSE IF other:haskey("marginv") {	//for backwards compatibility
		SetMarg(T,other["marginv"],other["marginv"],-1,-1).}

	//padding
	IF other:haskey("padding") {
		SetPad(T,other["padding"][0],other["padding"][1],other["padding"][2],other["padding"][3]).}
	ELSE IF other:haskey("paddingv") {	//for backwards compatibility
		SetPad(T,other["paddingv"],other["paddingv"],-1,-1).}
	
	return T.
}

function SetBG {
	parameter Wid, bgd.
	SET Wid:normal:bg TO bgd.
	SET Wid:normal_on:bg TO bgd.
	SET Wid:hover:bg TO bgd.
	SET Wid:hover_on:bg TO bgd.
	SET Wid:active:bg TO bgd.
	SET Wid:active_on:bg TO bgd.
	SET Wid:focused:bg TO bgd.
	SET Wid:focused_on:bg TO bgd.
}

function DefaultSkin {
	parameter Sty.
	SET Sty:hstretch TO true.
	SET Sty:vstretch TO false.
	SET Sty:width TO 0.
	SET Sty:height TO 0.
	SET Sty:margin:v TO 1.
	SET Sty:margin:h TO 1.
	SET Sty:padding:v TO 1.
	SET Sty:padding:h TO 3.
	SET Sty:border:h To 1.
	SET Sty:border:v To 1.
	SET Sty:overflow:v TO 0.
	SET Sty:overflow:h TO 0.
	SET Sty:align TO "LEFT".
	SET Sty:font TO "".
	SET Sty:fontsize TO 10.
	SetTextColor(Sty,white).
	SET Sty:wordwrap TO true.
}

function SkinSize {
	parameter gui.
	
	LOCAL boxdim TO list(0,0).
		//default margin
		
	SET gui:style:padding:v TO 1.
	SET gui:style:padding:h TO 1.
	
	SET gui:style:normal:bg TO "AP\GFX\GuiBG".
	SET gui:style:border:h To 1.
	SET gui:style:border:v To 1.
	
	//set label style as base for others
	DefaultSkin(gui:skin:label).
	
	//textfield - first copy label, then change as needed
	DefaultSkin(gui:skin:textfield).
	SET gui:skin:textfield:normal:bg TO "AP\GFX\TextBG".
	SET gui:skin:textfield:hover:bg TO "AP\GFX\TextBG".
	SET gui:skin:textfield:active:bg TO "AP\GFX\TextBG".
	SET gui:skin:textfield:focused:bg TO "AP\GFX\TextBG".
	SetTextColor(gui:skin:textfield,yellow).
	
	//button - first copy label, then change as needed
	DefaultSkin(gui:skin:button).
	SET gui:skin:button:normal:bg TO "AP\GFX\ButtonBGNorm".
	SET gui:skin:button:normal_on:bg TO "AP\GFX\ButtonBGOn".
	SET gui:skin:button:hover:bg TO "AP\GFX\ButtonBGHover".
	SET gui:skin:button:hover_on:bg TO "AP\GFX\ButtonBGHoverOn".
	SET gui:skin:button:active:bg TO "AP\GFX\ButtonBGHover".
	SET gui:skin:button:active_on:bg TO "AP\GFX\ButtonBGHoverOn".
	SET gui:skin:button:align TO "CENTER".
	SET gui:skin:button:wordwrap TO false.
	
	//box - first copy label, then change as needed
	DefaultSkin(gui:skin:box).
	SET gui:skin:box:padding:top TO IBPad[0].
	SET gui:skin:box:padding:bottom TO IBPad[1].
	SET gui:skin:box:padding:left TO IBPad[2].
	SET gui:skin:box:padding:right TO IBPad[3].
	SET gui:skin:box:margin:h TO boxdim[0].
	SET gui:skin:box:margin:v TO boxdim[1].
	SET gui:skin:box:normal:bg TO "AP\GFX\BoxBG".
	SET gui:skin:box:border:h To 2.
	SET gui:skin:box:border:v To 2.
	
	//layout - first copy label, then change as needed
	DefaultSkin(gui:skin:flatlayout).
	SET gui:skin:flatlayout:padding:top TO IBPad[0].
	SET gui:skin:flatlayout:padding:bottom TO IBPad[1].
	SET gui:skin:flatlayout:padding:left TO IBPad[2].
	SET gui:skin:flatlayout:padding:right TO IBPad[3].
	SET gui:skin:flatlayout:margin:h TO boxdim[0].
	SET gui:skin:flatlayout:margin:v TO boxdim[1].

	//scrollbox - first copy label, then change as needed
	SET gui:skin:scrollview TO gui:skin:box.
	SET gui:skin:scrollview:padding:top TO OBPad[0].
	SET gui:skin:scrollview:padding:bottom TO OBPad[1].
	SET gui:skin:scrollview:padding:left TO OBPad[2].
	SET gui:skin:scrollview:padding:right TO OBPad[3].

	//keep trying to change scrollbars
	SET gui:skin:verticalscrollbar:normal:bg TO "AP\GFX\VScrollBarBG".
	SET gui:skin:horizontalscrollbar:normal:bg TO "AP\GFX\BoxBG".

	SetBG(gui:skin:verticalscrollbarthumb,"AP\GFX\ButtonBGNorm").
	SetBG(gui:skin:verticalscrollbarleftbutton,"AP\GFX\ButtonBGNorm").
	SetBG(gui:skin:verticalscrollbarrightbutton,"AP\GFX\ButtonBGNorm").

	SetBG(gui:skin:horizontalscrollbarthumb,"AP\GFX\ButtonBGNorm").
	SetBG(gui:skin:horizontalscrollbarleftbutton,"AP\GFX\ButtonBGNorm").
	SetBG(gui:skin:horizontalscrollbarrightbutton,"AP\GFX\ButtonBGNorm").

	SetBG(gui:skin:verticalsliderthumb,"AP\GFX\ButtonBGNorm").
	SetBG(gui:skin:horizontalsliderthumb,"AP\GFX\ButtonBGNorm").

	//toggle - I don't really use these, I set buttons instead, so ignore

	//popupmenu - first copy label, then change as needed
	DefaultSkin(gui:skin:popupmenu).
	SET gui:skin:popupmenu:normal:bg TO "AP\GFX\ButtonBGNorm".
	SET gui:skin:popupmenu:normal_on:bg TO "AP\GFX\ButtonBGOn".
	SET gui:skin:popupmenu:hover:bg TO "AP\GFX\ButtonBGHover".
	SET gui:skin:popupmenu:hover_on:bg TO "AP\GFX\ButtonBGHoverOn".

	SET gui:skin:popupwindow:normal:bg TO "AP\GFX\BoxBG".
	
	DefaultSkin(gui:skin:popupmenuitem).
	SET gui:skin:popupmenuitem:fontsize TO gui:skin:label:fontsize+2.
	SET gui:skin:popupmenuitem:margin:v TO 0.
	SET gui:skin:popupmenuitem:hstretch TO TRUE.
	SET gui:skin:popupmenuitem:normal:bg TO "AP\GFX\ButtonBGNorm".
	SET gui:skin:popupmenuitem:hover:bg TO "AP\GFX\ButtonBGOn".
}

//set the size of a widget
function Set_Size {
	parameter widget1,
	width1 IS 0,
	height1 IS 0.
	
	SET widget1:style:width TO width1.
	SET widget1:style:height TO height1.
}

//create a box
function MkBox {
	parameter parent1,
	type1,	//"HB" = addhbox; "HL" = addhlayout; "VB" = addvbox; "VL" = addvlayout
	// "SB" = addscrollbox,
	other IS lexicon().
	
	// width1 IS 0,
	// height1 IS 0,
	// mp IS list(0,0), //margin and padding
	// hstretch1 IS false.
	
	LOCAL Types IS lexicon("HB",{LOCAL T TO parent1:addhbox(). return T.}, //h box
		"HL",{LOCAL T TO parent1:addhlayout(). return T.}, //h layout
		"VB",{LOCAL T TO parent1:addvbox(). return T.},  //v box
		"VL",{LOCAL T TO parent1:addvlayout(). return T.},  //v layout
		"SB",{LOCAL T TO parent1:addscrollbox(). return T.}).  //scrollbox
	LOCAL T TO Types[type1]().
	
	IF other:haskey("width") {SET T:style:width TO other["width"].}
	IF other:haskey("height") {SET T:style:height TO other["height"].}
	IF other:haskey("hstretch") {SET T:style:hstretch TO other["hstretch"].}
	IF other:haskey("vstretch") {SET T:style:vstretch TO other["vstretch"].}
		
	//margins
	IF other:haskey("margins") {
		SetMarg(T,other["margins"][0],other["margins"][1],other["margins"][2],other["margins"][3]).}
	//padding
	IF other:haskey("padding") {
		SetPad(T,other["padding"][0],other["padding"][1],other["padding"][2],other["padding"][3]).}

	return T.
}
	
	
//create a textfield which edits a variable on confirm
function MkTextInput {
	parameter parent1, //name of box to add textfield to
		struct1,  //must be a structure (list/lexicon) because those get passed by reference
		index1 IS 0,  //index in the struct. Defaults to 0 so it isn't needed if you pass a structure with only 1 length
		other IS lexicon().

	//set default parameters
	IF NOT other:haskey("fontsize") {other:add("fontsize",parent1:gui:skin:textfield:fontsize).}
	IF NOT other:haskey("color") {other:add("color",yellow).}
	IF NOT other:haskey("width") {other:add("width",0).}
	IF NOT other:haskey("height") {other:add("height",0).}
	IF NOT other:haskey("hstretch") {other:add("hstretch",false).}
	IF NOT other:haskey("align") {other:add("align","LEFT").}
	IF NOT other:haskey("type") {other:add("type","number").}
	IF NOT other:haskey("marginv") {other:add("marginv",parent1:gui:skin:textfield:margin:v).}
	IF NOT other:haskey("paddingv") {other:add("paddingv",parent1:gui:skin:textfield:padding:v).}
	IF NOT other:haskey("numformat") {other:add("numformat",false).}
	IF NOT other:haskey("addfunc") {other:add("addfunc",{}).}	//additional function to run on confirm
	
	LOCAL T IS 0.
	
	IF other["type"] = "number" {
		IF other["numformat"] {
			SET T TO parent1:addtextfield(NumFormat(struct1[index1],99)).
			SET T:onconfirm TO {
				parameter s.
				SET struct1[index1] TO NumParse(s,struct1[index1]).
				SET T:text TO NumFormat(struct1[index1],99).
				other["addfunc"](s).
			}.
		} ELSE {
			SET T TO parent1:addtextfield(struct1[index1]:tostring).
			SET T:onconfirm TO {
				parameter s.
				SET struct1[index1] TO NumParse(s,struct1[index1]).
				SET T:text TO struct1[index1]:tostring.
				other["addfunc"](s).
			}.
		}
	} ELSE IF other["type"] = "string" {
		SET T TO parent1:addtextfield(struct1[index1]).
		SET T:onconfirm TO {
			parameter s.
			SET struct1[index1] TO s.
			other["addfunc"](s).
		}.
	}

	SET T:style:width TO other["width"].
	SET T:style:height TO other["height"].
	SET T:style:fontsize TO other["fontsize"].
	SET T:style:textcolor TO other["color"].
	SET T:style:hstretch TO other["hstretch"].
	SET T:style:align TO other["align"].
	SET T:style:margin:v TO other["marginv"].
	SET T:style:padding:v TO other["paddingv"].
	
	return T.
}

//create a label-textfield pair
function Text_Label_Input {
	parameter parent1, //name of parent box
		struct1, //must be a structure (list/lexicon) because those get passed by reference
		index1, 
		label1,  //label
		width1,  //width of label
		width2.  //width of textfield
	
	LOCAL T is MkBox(parent1,"HL",lexicon("padding",OBPad)).
	MkLabel(T,label1+":",lexicon("width",width1,"align","RIGHT")).
	LOCAL U IS MkTextInput(T,struct1,index1,lexicon("width",width2,"color",yellow,"numformat",true)).
	return U.
}

//create a list of label-textfield pairs from a lexicon
function Lexicon_Edit {
	parameter parent1, 
		lex1,  //lexicon
		other IS lexicon().
		
		//set default parameters
		IF NOT other:haskey("columns") {other:add("columns",1).}
		IF NOT other:haskey("box") {other:add("box",true).}
		IF NOT other:haskey("labels") {other:add("labels",list()).}
		IF NOT other:haskey("width1") {other:add("width1",60).}
		IF NOT other:haskey("width2") {other:add("width2",60).}
		IF NOT other:haskey("ignore") {other:add("ignore",list()).}
	
	LOCAL T IS list().
	LOCAL U IS 1.
	// LOCAL typebox IS 1.
	LOCAL label1 IS 0.
	LOCAL num IS lex1:length - other["ignore"]:length. //number of pairs to add
	LOCAL columnRow IS ceiling(num / other["columns"]). //number of rows in each column
	SET other["columns"] TO ceiling(num/columnRow). //if the number of elements would take fewer columns at the divided amount, get the correct number of colums
	IF other["box"] AND other["columns"] > 1 {SET U TO MkBox(parent1,"HB",lexicon("padding",OBPad)).}
	ELSE {SET U TO MkBox(parent1,"HL",lexicon("padding",OBPad)).}
	
	LOCAL type1 IS "VL".
	IF other["box"] {SET type1 TO "VB".}
	FOR index1 IN RANGE(0,other["columns"],1)  {
		T:add(MkBox(U,type1,lexicon("padding",OBPad))). 
	} 
	
	LOCAL count IS 0.
	LOCAL Inputs IS lexicon().
	FOR index1 IN RANGE(0,lex1:length,1) {
		IF other["labels"]:length-1 <= index1 {SET label1 TO lex1:keys[index1].} 
		ELSE {SET label1 TO other["labels"][index1].}.
		IF NOT(other["ignore"]:contains(lex1:keys[index1])) {
			Inputs:add(lex1:keys[index1],
				Text_Label_Input(T[FLOOR(count/columnRow)],lex1,lex1:keys[index1],label1,other["width1"],other["width2"])). 
			SET count TO count+1.
		}
	}

	//add blank spaces for visual appeal
	FROM {LOCAL index1 TO lex1:length.} UNTIL index1 >= other["columns"]*columnRow STEP {SET index1 TO index1+1.} DO {
		MkBox(T[other["columns"]-1],"HL",lexicon("padding",OBPad)):addlabel(" ").
	}
	return Inputs.
}

function MkPopup {
	parameter parent1,
	width1 IS 0,
	height1 IS 0,
	other IS lexicon().
	
	LOCAL S TO parent1:addpopupmenu().
	
	Set_Size(S,width1,height1).

	//set default parameters
	IF NOT other:haskey("fontsize") {other:add("fontsize",parent1:gui:skin:textfield:fontsize).}
	IF NOT other:haskey("color") {other:add("color",white).}
	IF NOT other:haskey("hstretch") {other:add("hstretch",false).}
	IF NOT other:haskey("vstretch") {other:add("vstretch",false).}
	IF NOT other:haskey("align") {other:add("align","LEFT").}
	IF NOT other:haskey("marginv") {other:add("marginv",parent1:gui:skin:popupmenu:margin:v).}
	IF NOT other:haskey("paddingv") {other:add("paddingv",parent1:gui:skin:popupmenu:padding:v).}
	IF NOT other:haskey("maxvis") {other:add("maxvis",10).}
	IF NOT other:haskey("options") {other:add("options",list()).}

	// SET S:style:margin:v TO other["margin"].
	// SET S:style:margin:h TO other["margin"].
	// SET S:style:padding:v TO other["padding"].
	// SET S:style:padding:h TO other["padding"].
	SET S:style:fontsize TO other["fontsize"].
	SET S:style:textcolor TO other["color"].
	SET S:style:hstretch TO other["hstretch"].
	SET S:style:vstretch TO other["vstretch"].
	SET S:style:align TO other["align"].
	SET S:MaxVisible TO other["maxvis"].
	SET S:options TO other["options"].

	return S.
	
}

function ExclBut {
	parameter Buttons, ind.
	FOR item IN Buttons:keys {SET Buttons[item]:pressed TO item = ind.}
}

function SetPopupIndex {
	parameter popup,option.
	FOR i IN RANGE(0,popup:options:length,1) {
		IF popup:options[i] = option {SET popup:index TO i. break.}
	}
}

print "libGui loaded".
