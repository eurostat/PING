/**
## var_set {#sas_var_set}
Add variable(s) to a dataset and initialize it/them to some value(s). 

~~~sas
    %var_set(idsn, var=, val=, odsn=, force_set=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : input reference dataset, where variables shall be inserted;
* `var` : (_option_) list of variables that should be inserted; 
* `val` : (_option_) list of values that should be used to inizialize the inserted
	variables; the number of arguments passed in `var` and `val` MUST be the same;
* `force_set` : (_option_) boolean flag (`yes/no`) set to force the initialisation
	of the variable passed in `var`:
		+ `yes`: the variable in `var` is/are initialised whether it/they already
		exist/s in the dataset or not,
    	+ `no`: the variable in `var` is/are initialised only when it is added to
		the dataset;

	default: `force_set=no` is used;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is 
	used.

### Returns
* `odsn` : (_option_) name of the output dataset (stored in the `olib` library), that 
	will contain the  data from `idsn`, plus the new variables inserted; default: 
	`odsn=idsn` and the input dataset `idsn` is updated instead;
* `olib` : (_option_) name of the output library; by default: empty, and the value of 
	`ilib` is used.

### Examples
Let us consider test dataset #5 in WORKing directory:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5

then both calls to the macro below:
~~~sas
    %var_set(_dstest5, var=FFF AA, val= 10 20);
 ~~~	

will return the exact same dataset `out1=out2` (in WORKing directory) below:
 f | e | d | c | b | a | FFF | AA   
---|---|---|---|---|---|-----|---  
 . | 1 | 2 | 3 | . | 5 | 10  | 20

Instead, the following instruction:
~~~sas
	%var_set(_dstest5, var=k a, val= 10 20, force_set=YES);
~~~	

will return the exact same dataset `out1=out2` (in WORKing directory) below:
 f | e | d | c | b | a | k  | 
---|---|---|---|---|---|----| 
 . | 1 | 2 | 3 | . |20 | 10 | 

Run macro `%%_example_var_set` for more examples.

### Note
When `force_set=yes`, the value of existing variable/s may be replaced this way.

### See also
[%list_length](@ref sas_list_length), [%var_check](@ref sas_var_check).
*/
/** \cond */ 

/* credits: grillma */

%macro var_set(idsn
			, var=
			, val=
			, force_set=
			, odsn=
			, ilib=
			, olib=
			);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/
	
	%local _ans _res;

	/* IDSN/ILIB: check that the input dataset actually exists */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* FORCE_SET: set default force_set if not passed */
	%if %macro_isblank(force_set) %then 	%let force_set=NO;
	%else 									%let force_set=%upcase(&force_set);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&force_set, type=CHAR, set=YES NO) NE 0, mac=&_mac,
			txt=!!! Wrong value for boolean flag FORCE_SET !!!) %then
		%goto exit;

	/* OLIB: set default output libraries if not passed */
	%if %macro_isblank(olib) %then 		%let olib=&ilib;

	/* ODSN: by default, set the ouput dataset name to the input one
	 * note then that both datasets will be identical iff ilib=olib also stands */
	%if %macro_isblank(odsn) %then 		%let odsn=&idsn;

	/* VAR/VALUES : perform some basic compatibility checking between input parameters */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(var) EQ 1 OR %macro_isblank(val) EQ 1, mac=&_mac,	
			txt=!!! VAR OR VAL is missing !!!) 
			or %error_handle(ErrorInputParameter, 
				%list_length(&var) NE %list_length(&val), mac=&_mac,		
				txt=!!! Number of arguments passed in VAR and VAL differ !!!) %then
		%goto exit;
      
    %let _ans=%var_check(&idsn, &var, lib=&ilib);
	%let _res=%list_ones(%list_length(&var), item=1);
	/* %var_check(&idsn, &var, _varlst_=list); */

    /* check if some variable  already exists */
	%if %error_handle(WarningInputParameter, 
			%quote(&_ans) NE %quote(&_res),		
			txt=! Some variables from VAR already exist in the dataset - Only no existing variable are inserted !, 
			verb=warn) %then
		%goto warning;
    %warning:

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i  /* loop increment           */
		;
	 
	%let list=;
	
    %if "&force_set" = "YES" %then %do;
 	    DATA &olib..&odsn ;
			SET &ilib..&idsn ; 
			%do _i=1 %to %list_length(&var);
			    %scan(&var, &_i)= %scan(&val, &_i);
			%end;
		RUN;
		%goto exit;
	%end;

	DATA &olib..&odsn ;
		SET &ilib..&idsn ;  
    		%do _i=1 %to %list_length(&_ans);
	    		%if %scan(&_ans, &_i)=1 %then %do;
		 			%scan(&var, &_i)= %scan(&val, &_i);
	     		%end;
			%end;
	 run;

	%exit:
%mend var_set;

%macro _example_var_set;
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

	%local dsn;

	%let dsn=TMP%upcase(&sysmacroname);
	/* we will use test dataset #5 in the examples below */
	%_dstest5;              /* create the test dataset #5 in WORK directory */
	%ds_print(_dstest5);

	%put;
	%put (i) Test when he number of variables and values to be inserted are different;
    %var_set(_dstest5, var=FFF a F, val= 10 20);

	%put (ii) Test when one variable already exists in the table;
    %var_set(_dstest5, var=k a, val= 10 20);
	%ds_print(_dstest5);

	%put;
	%put (iii) Test when new variables are added to the table;
    %var_set(_dstest5, odsn=&dsn, var=FFF AA ,val= 10 20);
	%ds_print(&dsn); 

	%work_clean(_dstest5, &dsn);

	%exit:
%mend _example_var_set;
/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_set; 
*/
/** \endcond */

