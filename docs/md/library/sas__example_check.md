## _example_check {#sas__example_check}
Test a macro using the _example_* programs implemented inside the considered 
macro files.

	%_example_check(macro_name, dir=);

### Arguments
* `macro_name` : string representing the macro name;
* `dir` : (_option_) string storing the location of the macro; in practice, the file 
	<dir>/<macro_name>.sas will be searched for loading the associated; default to
	the location of the autoexec directory.

### Returns
`ans` : the error code of the test, _i.e._:
	* `0` if the variable `var` exists in the dataset,
    * `1` (error: "var does not exist") otherwise.

### Note
A macro _example_<macro_name> needs to be implemented inside <dir>/<macro_name>.sas.
This macro is then automatically ran.

### Example
Run macro `%%_example_check` for examples.
