@LAZYGLOBAL OFF.

LOCAL libs2 IS list().

cd("0:/AP/library/ksm").
LOCAL libs IS list().
LIST files IN libs.
FOR item IN libs {
	IF item <> "RunLibs.ksm" {
		runoncepath(item).
		libs2:add(item:name:replace(".ksm","")).
	}
}
cd("0:/AP/library").
LIST files IN libs.
FOR item IN libs {
	IF item = "RunLibs.ks" OR
		item = "CompileLibs.ks" OR
		NOT item:isfile OR
		libs2:contains(item:name:replace(".ks",""))
		{}
	ELSE {runoncepath(item).}
}

cd("/").