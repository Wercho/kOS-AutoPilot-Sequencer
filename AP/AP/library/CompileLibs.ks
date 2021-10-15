@LAZYGLOBAL OFF.

cd("0:/AP/library/").
LOCAL libs IS list().
LIST files IN libs.
FOR item IN libs {
	LOCAL temp1 IS item:name.
	IF item:extension = "ks" AND item <> "CompileLibs.ks" {
		compile item TO "ksm/"+temp1:replace(".ks",".ksm").
		Print "Compiled: "+item.
	}
}
cd("/").