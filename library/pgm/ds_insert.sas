/** 
## ds_insert {#sas_ds_insert}
Insert  variables into a given dataset using the DATA step statemens 																																																																																																																																																																																																																														.

~~~sas
	%ds_insert(idsn, odsn=, var=, value=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : a dataset reference;
* `var`  : (_option_) list of variables to insert in `odsn` dataset; if empty no variable is inserted;
* `value`: (_option_) list of values that are assigned to each variable;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
* `odsn` : (_option_) name of the output dataset; by default: empty, _i.e._ `idsn` is also used;
    it will contain the variable/s inserted;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also used;

### Examples
Let us consider the test dataset #38:
geo | EQ_INC20 | RB050a
:--:|---------:|------:
 BE |   10     |   10 
 MK |   50     |   10    
 MK |   60     |   10
 .. |   ..     |   ..   
and run the following:
	
~~~sas
	%let var =FMT DIM;
	%let value=%quote('fmt'||'_'||strip(geo)||'_') 4;
    %let odsn=TMP
   	%_dstest38;
	%ds_insert(_dstest38, odsn=&odsn,var=&var, value=&value);
~~~
to create the output table `TMP`:
geo | EQ_INC20 | RB050a   |   FMT  | DIM 
:--:|:--------:|---------:|-------:|-----:
 BE |   10     |    10    |fmt_BE_ |  4
 MK |   50     |    50    |fmt_MK_ |  4     
 MK |   60     |    60    |fmt_MK_ |  4
 .. |  ..      |    ..    |   ..   |  ..  

Run macro `%%_example_ds_insert` for examples.

### Notes
In short the macro runs the following `DATA STEP` statements:

~~~sas
	data &odsn;
	 	set &idsn;
		%do _i=1 %to &_nvar;
			  %scan(&var, &_i, &sep)=%scan(&value, &_i, &sep);
 		%end;
	run;
~~~

### See also
[%ds_contents](@ref sas_ds_contents)
*/ /** \cond */

/* credits: grillma */

%macro ds_insert(idsn		/* Input dataset 														(REQ) */
				, odsn= 	/* Output dataset 														(OPT) */ 
			    , var=		/* List of variables to operate the insert on 	     					(OPT) */
				, value=	/* value of new variable/s  											(OPT) */
				, ilib=		/* Name of the input library 											(OPT) */
				, olib=		/* Name of the output library 											(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local  
		_nvar     /* number of variables to insert  */
		_nvalue   /* number of values to insert     */
		_vardsn   /* temporary variable             */
		diff      /* temporary variable             */
		_diff     /* temporary variable             */
		;  

	/* check the input parameter
	/* IDSN/ILIB: check  the input dataset */
  	%if %macro_isblank(ilib) %then 	%let ilib=WORK;
	
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* ODSN/OLIB: set the default output dataset */
	%if %macro_isblank(olib) %then 	%let olib=WORK ;
	%if %macro_isblank(odsn) %then 	%let odsn=idsn ;

	/* VAR: check if is empty */
	%if %error_handle(ErrorInputParameter, 
				 %macro_isblank(var) NE 0 , mac=&_mac,		
				txt=!!! Var is missing: the variable is not inserted !!!) %then
		%goto exit; 

	/* VAR: check that the variables actually exist in the dataset */
	%ds_contents(&idsn, _varlst_=_vardsn, lib=&ilib);

	%let _nvar=%list_length(&var);
	%let _nvalue=%list_length(&value);

	%if %error_handle(ErrorInputParameter, 
			&_nvar NE &_nvalue, mac=&_mac,		
			txt=!!! Different numbers of variable and values !!!) %then
		%goto exit; 
	 	
	%let diff=%list_difference(&_vardsn, &var);
    %let _diff=%list_difference(&_vardsn, &diff);
	
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_diff) EQ 0 , mac=&_mac,		
			txt=!!! One or more variables are already in the  database !!!) %then
		%goto exit; 														
	
	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local SEP	/* separator character                     */
	    _var    /* temporary variable  used for comparison */
		_i	    /* increment counter                       */
		 ;
	%let SEP=%str( );

	DATA &olib..&odsn;
	 	SET &ilib..&idsn;
		%do _i=1 %to &_nvar;
			  %scan(&var, &_i, &SEP)=%scan(&value, &_i, &SEP);
 		%end;
 	run;
	
	%exit:
%mend ds_insert;

%macro _example_ds_insert;
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

	%local dsn var value;
    %_dstest38;
	%ds_print(_dstest38);
	/* temporary dataset */
	%let dsn=TMP%upcase(&sysmacroname);

 	%put;
	%put (i) Test with variable empty to run on test dataset #38 - no changes in the input dataset;
    %let descr=Test with variable empty to run on test dataset #38 - no changes in the input dataset;
	%let var =;
	%let value=5;
   	%ds_insert(_dstest38, var=&var,value=&value);
	%ds_print(_dstest38, title="(i) &descr");

	%put;
	%put (ii) Test with variable already existing in test dataset #38 - no changes in the input dataset;
	%let descr=Test with variable already existing in test dataset #38 - no changes in the input dataset;
	%let var =geo;
	%let value=%quote('fmt'||'_'||strip(geo)||'_');
    %ds_insert(_dstest38, var=&var,value=&value);
	%ds_print(_dstest38,title="(ii) &descr"); 

	%put;
	%put (iii) Test with two variables: only one exists  in test dataset #38 - no changes in the input dataset;;
	%let descr= Test with two variables: only one exists  in test dataset #38 - no changes in the input dataset;;
	%let var =geo len;
	%let value=IT 4;
   	%ds_insert(_dstest38, var=&var,value=&value);
	%ds_print(_dstest38,title="(iii) &descr");   

	%put;
	%put  (iv) Test with new variable in test dataset #38;
	%let descr= Test with new variable in test dataset #38;
	%let var =fmt;
	%let value=%quote('fmt'||'_'||strip(geo)||'_');
    %ds_insert(_dstest38,odsn=&dsn, var=&var,value=&value);
	%ds_print(&dsn,title="(iv) &descr"); 

	%put;
	%put (v) Test with two variables  and two  values to insert in test dataset #38;
	%let descr=Test with two variables  and two  values to insert in test dataset #38;
	%let var =len dim;
	%let value=%quote('fmt'||'_'||strip(geo)||'_') 4;
   	%ds_insert(_dstest38,odsn=&dsn, var=&var,value=&value);
	%ds_print(&dsn,title="(v) &descr"); 

	%put;
	%put (vi) Test with more values than variables  to insert in test dataset #38;
	%let descr=Test with more values than variables  to insert in test dataset #38;
	%let var =size;
	%let value=6 4;
    %ds_insert(_dstest38,odsn=&dsn, var=&var,value=&value);
	%ds_print(&dsn,title="(vi) &descr");   

	%work_clean(&dsn, _dstest38); 

	%exit:
%mend _example_ds_insert;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;*/
%_example_ds_insert; 
*/

/** \endcond */
 */
