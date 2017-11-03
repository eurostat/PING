/** \cond */
/** 
## _DSTEST3 {#sas_dstest3}
Test dataset #3.

	%_dstest3;
	%_dstest3(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest3`:
| color | value |
|:-----:|------:|
|  blue |   1   |
|  blue |   2   |
|  blue |   3   |
| green |   3   |
| green |   4   |
|  red  |   2   |
|  red  |   3   |
|  red  |   4   |

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest<XX>` storing the 
	following table: 

### Example
To create dataset #3 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest3;
	%ds_print(_dstest3;

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */ 

%macro _dstest3(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			color="blue "; 	value=1; output;
			color="blue"; 	value=2; output;
			color="blue"; 	value=3; output;
			color="green"; 	value=3; output;
			color="green"; 	value=4; output;
			color="red"; 	value=2; output;
			color="red"; 	value=3; output;
			color="red"; 	value=4; output;
		run;
	%end;
	%else %do;
		%if &verb=yes %then %put dataset &_dsn already exists in library &_ilib;
	%end;

	%if %macro_isblank(lib) %then 	%let lib=WORK;

	%if "&lib"^="&_ilib" %then %do;
		DATA &lib..&_dsn;
			set &_ilib..&_dsn;
		run; 
		%if &_ilib=WORK %then %do;
			%work_clean(&_dsn);
		%end;
	%end;

	%if not %macro_isblank(_ds_) %then 	%do;
		data _null_;
			call symput("&_ds_", "&lib..&_dsn");
		run; 
	%end;		

%mend _dstest3;

%macro _example_dstest3;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest3(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest3;
	%ds_print(_dstest3);

	%work_clean(_dstest3);
%mend _example_dstest3;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest3; /* comment your example */

/** \endcond */
