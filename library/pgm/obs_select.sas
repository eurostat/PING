/** 
## obs_select {#sas_obs_select}
Select a given observation/set of observations in a dataset.

~~~sas
	%obs_select(idsn, odsn, var=, where=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : a dataset reference;
* `var` : (_option_) list of fields/variables of `idsn` upon which the extraction is performed; 
	default: `var` is empty and all variables are selected; 
* `where` : (_option_) expression used to refine the selection (`WHERE` option); should be 
	passed with `%%str`; default: empty;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also used.

### Returns
* `odsn` : name of the output dataset (in `WORK` library); it will contain the selection 
	operated on the original dataset;

### Examples
Let us first  consider test dataset #34:
geo | year | ivalue
:--:|:----:|------:
EU27|  2006|   1
EU25|  2004|   2
EA13|  2001|   3
EU27|  2007|   4
... |  ... |  ...
then by the condition one or more rows are selected from the dataset, _e.g._ using the 
instructions below:

~~~sas
	%let var=geo;
    %let obs=EA13;
    %obs_select(_dstest34, TMP, where=%str(&var="&obs"));
~~~
so as to store in the output dataset `odsn` the following table:
geo | year | ivalue
:--:|:----:|------:
EA13|  2001|	3

Run `%%_example_obs_select` for more examples.

### See also
[%ds_select](@ref sas_ds_select), [%obs_count](@ref sas_obs_count).
*/ /** \cond */

/* credits: gjacopo */

%macro obs_select(idsn		/* Input reference dataset 								(REQ) */
				, odsn 		/* Name of output dataset                         		(REQ) */
				, where=	/* WHERE clause: Expression used to select observations (REQ) */
				, var= 	    /* List of variables to keep in the output dataset 		(REQ) */
               	, ilib =	/* Name of the input library 							(OPT) */
				, olib =	/* Name of the output library 							(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* IDSN/ILIB : checking/setting */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
		%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
		txt=%quote(!!! Input dataset %upcase(&idsn) not found !!!)) 
		/* or
			%error_handle(ErrorInputParameter, 
				%macro_isblank(where) EQ 1, mac=&_mac,		
				txt=!!! No condition has been defined !!!) */ %then
		%goto exit;

	/* ODSN/OLIB: set the default output dataset */
	%if %macro_isblank(olib) %then 	%let olib=WORK/*&ilib*/;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,		
			txt=! Output dataset %upcase(&odsn) already exists: will be replaced!, 
			verb=warn) %then
		%goto warning1;
	%warning1:

	/* VAR: set the default list of variables */
	%if %macro_isblank(var) %then %do;
		/* set to all variables in the dataset */
		%let var=_ALL_;
		/* %ds_contents(&idsn, _varlst_=var, varnum=yes, lib=&ilib); */
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

    %local _ans 		/* output value of the %obs_check macro */
		nvar;

	/* check that such observation indeed exists */
	%obs_count(&idsn, where=&where, _ans_=_ans, pct=no, lib=&ilib);
   
	%if %error_handle(ErrorOutputEstimation, 
			&_ans EQ 0, mac=&_mac,		
			txt=%quote(!!! No observation found for given condition in the dataset !!!)) %then
		%goto exit;

	/* actual extraction using ds_select */
	%ds_select(&idsn, &odsn, var=&var, distinct=yes, where=&where, ilib=&ilib, olib=&olib); 

	%exit:
%mend obs_select;


%macro _example_obs_select;
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

	%local odsn nobs var cond obs;
		
	/* temporary dataset */
	%let odsn=TMP%upcase(&sysmacroname);
	
	%let cond=%quote(geo="EA13");
	%put;
  	%put (i) Test the regular expression: &cond on a non-existing table;
	%obs_select(DUMMY, where=&cond, odsn=&odsn); 
    %put; 

  	%_dstest34;

	%put;
	%let cond=%quote(geo="IT");
	%put (ii) Test the condition: &cond on test dataset #34;
	%obs_select(_dstest34, where=&cond, odsn=&odsn);
	%ds_count(&odsn,_nobs_=nobs);
	%if  &nobs= 0 %then 	%put OK: TEST PASSED - Observation 'obs=IT' does not exist  in 'geo' variable on _dstest34;
	%else 					%put ERROR: TEST FAILED - Observation 'obs=IT' exists  in 'geo' variable on _dstest34;
  	%put;
 
    %put (iii) Test the condition: geo="EA13" on test dataset #34;
	%let var=geo;
	%let cond=%quote(geo="EA13");
	%obs_select(_dstest34, where=&cond, odsn=&odsn);
	%ds_count(&odsn,_nobs_=nobs);
    %if &nobs= 1 %then 	%put OK: TEST PASSED - Observation 'obs=EA13' exists  in 'geo' variable on _dstest34;
	%else 			   	%put ERROR: TEST FAILED - Observation  does not  exist  in 'geo' variable on _dstest34;
    %ds_print(&odsn);
	%put; 

	%work_clean(_dstest34 &odsn);

	%exit:
%mend ;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_obs_select; 
*/

/** \endcond */
