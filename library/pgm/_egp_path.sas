/** 
## _egp_path {#sas__egp_path}
This macro retrieves either the name of the client SAS EG project (without its extension) 
it is launched in or the path of where it is located.

~~~sas
	%let p=%_egp_path(path=base, dashreplace=no, parent=no);
~~~
  
### Arguments
* `path` : (_option_) flag set to `base/path/drive` when respectively the 
 	project's name/path/drive path shall be returned; default: `path=path`, _i.e._ the 
	path of the current project directory is returned;
* `dashreplace` : (_option_) boolean flag set to `yes` when the `-` in the path needs
	to be trimmed (_i.e._, replaced with a blank); this is used only when `path=base`, 	
	_e.g._ to produce automatically tables whose names are derived from the program used 
	to generate them; default to `no`;
* `parent` : (_option_) boolean flag set to yes when the path of the parent directory of
	the current project shall be returned; this is used only when `path=path` or `drive`; 
	default to `no`.

### Returns
`p` : depending on `path` value:
	+ the name of the current project (the one the command is launched in), without its 
		`egp` extension,
	+ the path or full path,
	+ the path of the parent directory.

### Examples
Imagine the name of the program running this function is `test-01.egp` and is located in 
the directory `Z:\main\test`, then:

~~~sas
	%let p=%_egp_path(path=base);
~~~
returns: `p=test-01`.

~~~sas
	%let p=%_egp_path(path=base, dashreplace=yes);
~~~
returns: `p=test01`.

~~~sas
	%let p=%_egp_path(path=path); 
~~~
returns: `p=Z:/main/test`

~~~sas
	%let p=%_egp_path(path=drive); 
~~~	
returns: `p=/main/test`.

~~~sas
	%let p=%_egp_path(path=path, parent=yes); 
~~~	
returns: `p=Z:/main`.

Run macro `%%_example__egp_path` for examples.

### Notes
1. This macro works only with SAS ENTERPRISE GUIDE since it uses the predefined macro variables 
`_CLIENTPROJECTNAME` and `_CLIENTPROJECTPATH`.
2. Note that whether you are running in local or not (_e.g._, `SASMain`), the path returned with 
option `path=base` or (drive)path is always formatted as a local path, hence there is no 
difference.

### References
Hemedinger, C.: [Special automatic macro variables available in SAS Enterprise Guide](http://blogs.sas.com/content/sasdummy/2012/10/09/special-macro-vars-in-eg).

### See also
[%_egp_prompt](@ref sas__egp_prompt).
*/ /** \cond */

/* credits: gjacopo, marinapippi */

%macro _egp_path(path=			/* Flag defining the type of path to be returned				(OPT) */
				, dashreplace=	/* Boolean flag used to set to reformat the output string		(OPT) */
				, parent=		/* Boolean flag used to return the path of the parent directory (OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* SAS EG version (_CLIENTPROJECTNAME and _CLIENTPROJECTPATH are defined) */
	%if %error_handle(ErrorEnvironment, 
			%symexist(_CLIENTPROJECTNAME) EQ 0,	mac=&_mac,
			txt=!!! This macro runs on SAS EG only !!!) %then
		%goto exit;

	%let thisprog = &_CLIENTPROJECTNAME; /* note: this include the quotes '' */
	%let lenprog = %sysfunc(length(&thisprog));
	%let thispath = &_CLIENTPROJECTPATH; /* ibid: quotes are included */
	%let lenpath = %sysfunc(length(&thispath));


	/* PATH: set default/update parameter */
	%if %macro_isblank(path) %then 	%let path=PATH; 
	%else							%let path=%upcase(&path);

	/* transparent legacy for Marina "nessuno" Grillo */
	%if "&path"="BASENAME" %then %let path=BASE;
	%else %if "&path"="PATHDRIVE" %then %let path=DRIVE;

	%if %error_handle(ErrorInputParameter, 
			%par_check(&path, type=CHAR, set=BASE PATH DRIVE) NE 0, mac=&_mac,	
			txt=!!! Parameter PATH is flag with values in (BASE/PATH/DRIVE) !!!) %then
		%goto exit;

	/* DASHREPLACE/PARENT: set default/update parameter */
	%if %macro_isblank(dashreplace) %then 	%let dashreplace=NO; 
	%else									%let dashreplace=%upcase(&dashreplace);
	%if %macro_isblank(parent) %then 		%let parent=NO; 
	%else									%let parent=%upcase(&parent);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&dashreplace, type=CHAR, set=YES NO) NE 0 OR
			%par_check(&parent, type=CHAR, set=YES NO) NE 0, mac=&_mac,	
			txt=!!! Parameter DASHREPLACE/PARENT are boolean flags with values in (yes/no) !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                  actual operation                              **/
	/************************************************************************************/

	/* first some dummy test */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(thisprog) EQ 1 or %macro_isblank(thispath) EQ 1,	mac=&_mac,		
			txt=Project currently not defined: first save it !!!) %then
		%goto exit;
	/* else proceed... */

	/* and we get rid of the quotes while updating with actual lengths 
	%let thisprog = %quote(%SYSFUNC(substr(&thisprog, 2, %eval(&lenprog-1))));
	%let lenprog = %eval(&lenprog-2);
	%let thispath = %SYSFUNC(substr(&thispath, 2, %eval(&lenpath-1)));
	%let lenpath = %eval(&lenpath-2);
	%put test then;*/

	%if "&path"="BASE" %then %do;
		%let output=%sysfunc(substr(&thisprog, 2, %eval(&lenprog-2))); 
		%if "&dashreplace"="YES" %then %do;
			%let output=%sysfunc(compress(%sysfunc(translate(&output,' ','-'))));
		%end;
	%end;

	%else %do;
		%let output=%sysfunc(substr(&thispath, 2, %eval(&lenpath-&lenprog-1)));
		%let lenpath = %sysfunc(length(&output));
		%if "&path"="DRIVE" %then %do;
			%let i=%sysfunc(find(&output, \));  /*starting from the left */
			/* independent of the system: why?!!!;
			%if &sysscp = WIN %then %do;  
				%let i=%SYSFUNC(find(&output,\));
			%end;
			%else  %do;
				%let i=%SYSFUNC(find(&output,/));
			%end; */
			%let output=%sysfunc(substr(&output,%eval(&i+1),%eval(&lenpath-&i)));
		%end;
		%if "&parent"="YES" %then %do;
			%let i=%sysfunc(find(&output, \, -&lenpath));  /*starting from the right */
			%if &i>0 %then 	%let output=%sysfunc(substr(&output,1,%eval(&i-1)));	
			%else 			%let output=\;
		%end;
		%if &sysscp^=WIN %then %do;  
			%let output=%sysfunc(translate(&output,'/','\'));
		%end;
	%end;

	/** SAS version (SAS_EXECFILENAME and SAS_EXECFILEPATH are defined?)
		** To be developed
		**/
	/* %sysget(SAS_EXECFILEPATH)
		%sysget(SAS_EXECFILENAME)
		proc sql noprint;
			select xpath into :progname
			from sashelp.vextfl where upcase(xpath) like '%.SAS';
		quit;
	*/
	&output

	%exit:
%mend _egp_path;

%macro _example__egp_path; 
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

	%put current project: &_CLIENTPROJECTNAME;

	%let path=base;
	%put;
	%put  (i) Test with with path=%upcase(&path);
	%put 	returns: %_egp_path(path=&path);
	%put;
	%put  (ii) Test with with path=%upcase(&path) and dashreplace=%upcase(yes);
	%put 	returns: %_egp_path(path=&path,dashreplace=yes);

	%let path=path;
	%put;
	%put  (iii) Test with with path=%upcase(&path);
	%put 	returns: %_egp_path(path=&path);

	%let path=drive;
	%put;
	%put  (iv) Test with with path=%upcase(&path);
	%put 	returns: %_egp_path(path=&path);

	%let path=path;
	%put;
	%put  (v) Test with with path=%upcase(&path) and parent=%upcase(yes);
	%put 	returns: %_egp_path(path=&path,parent=yes);

	%let path=drive;
	%put;
	%put  (vi) Test with path=%upcase(&path) and parent=%upcase(yes);
	%put 	returns: %_egp_path(path=&path,parent=yes);

	%put;
	%exit:
%mend _example__egp_path;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example__egp_path; 
*/

/** \endcond */
