/** 
## ds_nvars {#sas_ds_nvars}
Retrieve the number of variables of a given dataset.

~~~sas
	%let nvars = %ds_nvars(dsn, lib=WORK);
~~~

### Arguments
* `dsn` : a dataset reference;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
`nvars` : number of variables in dataset `dsn`.

### Example
Let us consider test dataset #5:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5
then:

~~~sas
	%_dstest5;
	%let nvars=%ds_nvars(_dstest5);
~~~
returns `nvars=5` as expected.

Run `%%_example_ds_nvars` for more examples.

### See also
[%ds_count](@ref sas_ds_count).
*/
/** \cond */ 

/* credits: grazzja, grillma */

%macro ds_nvars(dsn 		/* Input dataset 				(REQ) */
				, lib=		/* Name of the input library	(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac); /* avoid conflict with returned value */

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(dsn) NE 0, mac=&_mac,		
			txt=!!! Input parameter DSN not set !!!) %then
		%goto exit;

	%if %macro_isblank(lib) %then 		%let lib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&dsn) not found !!!) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local nvars /* output answer */	
		_dsid _rc;		
	%let nvars=0;
	
	%let _dsid=%sysfunc(open(&lib..&dsn));
	%if %error_handle(WrongInputDataset, 
			&_dsid EQ 0 /*&ds_check(&dsn, lib=&lib) NE 0*/, mac=&_mac, 
			txt=!!! Input dataset %upcase(&dsn) not found !!!) %then 	
		%goto clean_exit;

	%let nvars=%sysfunc(attrn(&_dsid,NVARS));

	/* other methods:
	* using a DATA step:
	DATA _null_;
  		SET DICTIONARY.TABLES;
    	WHERE upcase(LIBNAME)="&lib" and upcase(MEMNAME)="&dsn";
	  	put nvar=;
	run;
	* using a PROC SQL:
	PROC SQL noprint;
  		SELECT nvar INTO: &_nvars_
    	FROM DICTIONARY.TABLES
    	WHERE upcase(LIBNAME)="&lib" and upcase(MEMNAME)="&dsn";
	quit;*/	
		
	%quit: /* ... return the answer */
	&nvars

	%clean_exit:
	/* in all cases, free the dataset identifier */
	%let _rc=%sysfunc(close(&_dsid));

	%exit:
%mend ds_nvars;

%macro _example_ds_nvars;
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

	%local nvars;

	%_dstest1;
	%put;
	%put (i) Test dataset _dstest1;
	%let nvars = %ds_nvars(_dstest1);
	%if &nvars EQ 1 %then 	%put OK: TEST PASSED - Dataset _dstest1 has 1 variable;
	%else					%put ERROR: TEST FAILED - wrong variable number returned: &nvars;

	%_dstest5;
	%put;
	%put (ii) Test dataset _dstest5;
	%let nvars = %ds_nvars(_dstest5);
	%if &nvars EQ 6 %then 	%put OK: TEST PASSED - Dataset _dstest1 has 6 variables;
	%else					%put ERROR: TEST FAILED - wrong variable number returned: &nvars;

	%_dstest20;
	%put;
	%put (iii) Test dataset _dstest20;
	%let nvars = %ds_nvars(_dstest20);
	%if &nvars EQ 8 %then 	%put OK: TEST PASSED - Dataset _dstest1 has 8 variables;
	%else					%put ERROR: TEST FAILED - wrong variable number returned: &nvars;

	%put;

	%work_clean(_dstest1, _dstest5, _dstest20);

	%exit:
%mend _example_ds_nvars;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_nvars; 
*/

/** \endcond */
