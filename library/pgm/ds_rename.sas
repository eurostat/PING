/** 
## ds_rename {#sas_ds_rename}
Rename one or more datasets in the same `SAS` library.

~~~sas
	%ds_rename(idsn, odsn=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : old name(s) of reference dataset(s);
* `ilib` : (_option_) name of the library where the old dataset(s) is (are) 
	stored; default: `ilib=WORK`.
	
### Returns
* `odsn` : new name(s); must be of the same length as `olddsn`;
* `olib` : (_option_) name of the library where the new dataset(s) will be
	stored; default: `olib=WORK`.

### Note
In short, this macro runs:
~~~sas
	DATA &olib..&odsn;
		SET &ilib..&idsn;
	run;

	PROC DATASETS library=&ilib;
		DELETE &idsn;
	run;
~~~

### See also
[%ds_change](@ref sas_ds_change).
*/ /** \cond */

/* credits: gjacopo */

%macro ds_rename(idsn		/* (List of) old name(s) of datasets 					(REQ) */
				, odsn=	/* (List of) new name(s) of datasets 					(REQ) */
				, ilib=		/* Name of the library where the datasets are stored 	(OPT) */
				, olib=		/* Name of the library where the datasets are stored 	(OPT) */
				, force=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local i 	/* local increment counter */
		num; 	/* length of input lists */

	/* IDSN/ILIB: check/set */
	%if %macro_isblank(ilib)	%then 	%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) NE 0, mac=&_mac,		
			txt=!!! Input dataset &idsn not found !!!) %then
		%goto exit;

	/* FORCE: check/set */
	%if %macro_isblank(force)	%then 	%let force=NO;
	%else 								%let force=%upcase(&force);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&force, type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=!!! Wrong value for boolean flag FORCE !!!) %then
		%goto exit;

	/* ODSN/OLIB: check/set */
	%if %macro_isblank(olib)	%then 	%let olib=WORK;

	%if %macro_isblank(odsn)	%then 	%let odsn=&idsn;

	%if %error_handle(WarningSkipOperation, 
			"&olib" EQ "&ilib" and "&odsn" EQ "&idsn", mac=&_mac,		
			txt=! Identical input/output - Operation will skipped !, verb=warn) %then 
		%goto exit;

	%if %ds_check(&odsn, lib=&olib) EQ 0 %then %do;
		%if %error_handle(WarningOutputDataset, 
				"&force" EQ "YES", mac=&_mac,		
				txt=! Input dataset &odsn already exists - Will be overwritten !, verb=warn) %then 
			%goto warning;
		%else %if %error_handle(ErrorOutputDataset, 
				"&force" EQ "NO", mac=&_mac,		
				txt=! Input dataset &odsn already exists - Operation will be skipped !, verb=warn) %then 
			%goto exit;
		%warning:
	%end;

	/************************************************************************************/
	/**                                  actual operation                              **/
	/************************************************************************************/


	/* solution 1: DATA STEP procedures */
	DATA &olib..&odsn;
		SET &ilib..&idsn;
	run;

	PROC DATASETS library=&ilib nolist;
		DELETE &idsn;
	run;

	/* solution 2: PROC SQL procedure
	PROC SQL;
		CREATE TABLE &olib..&odsn AS 
		SELECT * 
		FROM &ilib..&idsn;
		DROP TABLE &ilib..&idsn;
	quit;  */

	%exit:
%mend ds_rename;

%macro _example_ds_rename;
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

	%put;
	%put (i) Create test dataset #1 and rename it;
	%_dstest1;
	%ds_rename(_dstest1, odsn=_dummy1);
	%if %ds_check(_dummy1) EQ 0 and %ds_check(_dstest1) EQ 1 %then 	
		%put OK: TEST PASSED - Dataset renamed: _dummy1;
	%else 									
		%put ERROR: TEST FAILED - Dataset not renamed;

	%put;
	%work_clean(_dummy1);

	%exit:
%mend _example_ds_rename;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_rename; 
*/

/** \endcond */
