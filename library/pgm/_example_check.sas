/**  
## _example_check {#sas__example_check}
Test a macro using the _example_* programs implemented inside the considered 
macro files.

~~~sas
	%_example_check(macro_name, dir=);
~~~

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
*/ /** \cond */

%macro _example_check(macro_name, dir=);
	%if %symexist(EUSILC) %then 	%let SETUP_PATH=&EUSILC;
	%else 		%let SETUP_PATH=/ec/prod/server/sas/0eusilc; 
	/* %include "&SETUP_PATH/library/autoexec/_setup_.sas"; */

	%if "&dir"="" or "&dir"="" %then %do;
		%let dir=&SETUP_PATH/library/autoexec;
	%end;

	%let SASEXT=.sas;

	%local macroExist;
	%let filename=&dir/&macro_name.&SASEXT;
	%put filename=&filename;
	%file_check(&filename, _ans_=macroExist);

	%if &macroExist=no %then %do;
		%put !!! macro &macro_name not found !!!;
		%goto exit;
	%end;

 	%include "&filename";
	%_example_&macro_name;
	
	%exit:
%mend _example_check;


%macro _example_example_run;
	%if %symexist(G_PING_SETUPPATH) EQ 0 %then %do; 
        %if %symexist(G_PING_ROOTPATH) EQ 0 %then %do;	
			%put WARNING: !!! PING environment not set - Impossible to run &sysmacroname !!!;
			%put WARNING: !!! Set global variable G_PING_ROOTPATH to your PING install path !!!;
			%goto exit;
		%end;
		%else %do;
        	%let G_PING_SETUPPATH=&G_PING_ROOTPATH./PING; 
        	%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
        	%_default_setup_;
		%end;
    %end;
	%exit:
	*%_example_check(var_exist);
%mend _example_example_run;
/* %_example_example_check; */

/** \endcond */
