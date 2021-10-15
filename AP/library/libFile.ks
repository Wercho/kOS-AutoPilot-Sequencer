@LAZYGLOBAL OFF.

function CreateIfNot {	//creates the file if it doesn't exist
	parameter file.
	IF NOT(EXISTS(file)) {Create(file).}
}