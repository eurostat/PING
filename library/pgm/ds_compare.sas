/** 
## ds_compare {#sas_ds_compare}
Compare two datasets.

~~~sas
	%ds_compare(dsn1, dsn2, _ans_=,lib1=, lib2=);
~~~

### Arguments
* `dsn1` `dsn1`: two datasets reference (_request_);
* `lib1`       : input(_option_) library for dsn1 dataset;
* `lib2`       : input (_option_) library for dsn2 dataset;

### Returns
`ans` : the boolean result of the comparison test of the "sets" associated to the input lists, 
	i.e.:
		+ `0` when two datasets are equal: `dsn1 = dsn2`,
		+ `1` when `dsn1`has less variables then `dsb2`,

### Examples
Consider the test dataset #5:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5
One can retrieve the ordered list of variables in the dataset with the command:

~~~sas
	%let list=;
	%ds_compare(_dstest5, _varlst_=list);
~~~
which returns `list=f e d c b a`, while:

~~~sas
	%ds_compare(_dstest5, _varlst_=list, varnum=no);
~~~
returns `list=a b c d e f`. Similarly, we can also run it on our database, _e.g._:

~~~sas
	libname rdb "&G_PING_C_RDB"; 
	%let lens=;
	%let typs=;
	%ds_compare(PEPS01, _varlst_=list, _typlst_=typs, _lenlst_=lens, lib=rdb);
~~~
returns:
	* `list=geo time age sex unit ivalue iflag unrel n ntot totwgh lastup lastuser`,
	* `typs=  2    1   2   2    2      1     2     1 1    1      1      2        2`,
	* `lens=  5    8  13   3   13      8     1     8 8    8      8      7        7`.

Another useful use: we can retrieve data of interest from existing tables, _e.g._ the list of geographical 
zones in the EU:

~~~sas
	%let zones=;
	%ds_compare(&G_PING_COUNTRYxZONE, _varlst_=zones, lib=&G_PING_LIBCFG);
	%let zones=%list_slice(&zones, ibeg=2);
~~~
which will return: `zones=EA EA12 EA13 EA16 EA17 EA18 EA19 EEA EEA18 EEA28 EEA30 EU15 EU25 EU27 EU28 EFTA EU07 EU09 EU10 EU12`.

Run macro `%%_example_ds_compare` for more examples.

### Note
In short, the program runs (when `varnum=yes`):

~~~sas
	PROC CONTENTS DATA = &dsn 
		OUT = tmp(keep = name type length varnum);
	run;
	PROC SORT DATA = tmp 
		OUT = &tmp(keep = name type length);
     	BY varnum;
	run;
~~~
and retrieves the resulting `name`, `type` and `length` variables.

### References
1. Smith,, C.A. (2005): ["Documenting your data using the CONTENTS procedure"](http://www.lexjansen.com/wuss/2005/sas_solutions/sol_documenting_your_data.pdf).
2. Thompson, S.R. (2006): ["Putting SAS dataset variable names into a macro variable"](http://analytics.ncsu.edu/sesug/2006/CC01_06.PDF).
3. Mullins, L. (2014): ["Give me EVERYTHING! A macro to combine the CONTENTS procedure output and formats"](http://www.pharmasug.org/proceedings/2014/CC/PharmaSUG-2014-CC43.pdf).

### See also
[%var_to_list](@ref sas_var_to_list), [%ds_check](@ref sas_ds_check),
[CONTENTS](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000085766.htm).
*/ /** \cond */ 

/* credits: marinapippi */

%macro ds_compare(dsn1		/* Input reference dataset 				(REQ) */
                , dsn2		/* Input reference dataset 				(REQ) */
				, _ans_=    /* output result                        (REQ) */
				, lib1=		/* Name of the input library dsn1		(OPT) */
				, lib2=		/* Name of the input library dsn2   	(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* various checkings */
	


	%local __istyplst	/* output of the test of _TYPLST_ parameter setting */
		_ans            /* output answer             */
        __varnum		/* temporary VARNUM parameter */
		__tmp			/* temporary dataset */
		__vars 			/* output list of variable names */
		__lens			/* (optional) output list of variable lengths */
		__typs			/* (optional) output list of variable types */
		SEP;			/* arbitrary chosen separator for the output lists */
	%let _dsn=TMP_&_mac;
	%let SEP=%str( );
    %let _ans=0;
	
	/* DSN/LIB: check/set */
	%if %error_handle(ErrorInputParameter,           /*check if the dsn datasets are missing at the same time */
			%macro_isblank(dsn1) NE 0 OR %macro_isblank(dsn2) NE 0 , mac=&_mac,		
			txt=!!! %upcase(&dsn1) or  %upcase(&dsn2) not set !!!) %then
		%goto exit;

	%if %macro_isblank(lib1) %then 		%let lib1=WORK;
	%if %macro_isblank(lib2) %then 		%let lib2=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn1, lib=&lib1) EQ 1 OR %ds_check(&dsn2, lib=&lib2) EQ 1, mac=&_mac,		
			txt=%bquote(!!! Input datasets %upcase(&dsn1) in library %upcase(&lib1) OR %upcase(&dsn2) in library %upcase(&lib2)  not found !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local list1   /* the list of variables/fields of the dataset dsn1 are stored      */
		nobs1      /* variable used to store the result number of observations  dsn1   */
        len1       /* the length of list1                                              */
     	list2      /* the list of variables/fields of the dataset dsn2 are stored      */
		nobs2      /* variable used to store the result number of observations dsn2    */
		len2       /* the length of list2                                              */
			;
	/* the list of variables   in &dsn1 datset */	
	%ds_contents(&dsn1, _varlst_=list1,lib=&lib1);        
    %let len1=%list_length(list1, sep=%quote( ));
	%put &list1 step1);
	/* number of observations  in &dsn1 datset */
	%ds_count(&dsn1, _nobs_=nobs1);
	%put &nobs1  step1);;
	/* the list of variables   in &dsn1 datset */	
	%ds_contents(&dsn2, _varlst_=list2,lib=&lib2);
    %let len2=%list_length(list2, sep=%quote( ));
    %put &list2  step2);;
		/* the list of variables   in &dsn1 datset */	
	%ds_count(&dsn2, _nobs_=nobs2);
	%put &nobs2  step2);;
    /* compare the list of variables in &dsn1 and &dsn2 */
    %if %error_handle(ErrorInputDataset, 
			%list_compare(&list1, &list2, casense=no, sep=%quote( )) NE 0, mac=&_mac,		
			txt=%bquote(!!! %upcase(&dsn1) and %upcase(&dsn2) have different variables !!!)) %then %do;
			%let _ans=1;          /* set the anwser variable */
		%goto ans_output;
	%end;
 
	/* compare the variables contents of variables  */
   
	data a;
	set &dsn1;
	run;
	data b;
	set &dsn2;
	run;
    
	%let a=%sysfunc(open(a));
    %let b=%sysfunc(open(b));

/*
    %let a=%sysfunc(open(&lib1..&dsn1));
    %let b=%sysfunc(open(&lib2..&dsn2));*/

	PROC COMPARE base=a compare=b /*listequalvar novalues nodate*/ noprint 
		OUTSTAT=&_dsn(where=(_type_='NDIF' and sum(_BASE_, _COMP_)=0));
		var %do i=1 %to %sysfunc(attrn(&a., nvars));
	    		%do j=1 %to %sysfunc(attrn(&b., nvars));
          			%sysfunc(varname(&a., &i.))
        		%end;
    		%end;
		;
		with %do i=1 %to %sysfunc(attrn(&a., nvars));
	             %do j=1 %to %sysfunc(attrn(&b., nvars));
	           		 %sysfunc(varname(&b., &j.))
                 %end;
		    %end;
    	;
    run;
    %let rc=%sysfunc(close(&a.));
    %let rc=%sysfunc(close(&b.));

	/* return the answer */
   /* %ans_output:
 	data _null_;
		call symput("&_ans_","&_ans");
	run;*/

	%exit:
%mend ds_compare;


%macro _example_ds_compare;
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

	/* inputs: set some local parameters of your own */
 	%local ans;
	%let odsn=TMP;
	%_dstest41;
	%let dsn2=_dstest41;
  /* %let dsn1=DUMMY;

	%put;
	%put (i) Compare DUMMY with _dstest41 with  DUMMY dataset;
    %ds_compare(&dsn1,&dsn2,_ans_=ans);
	%put;*/
	%ds_copy(&dsn2, &odsn, mirror=COPY);
	*%ds_alter(&odsn, drop = age);
    %put (ii) compare two identical datasets: &dsn2, &odsn  ;
    %ds_compare(&dsn2, &odsn,_ans_=ans);
	%put (ii) result: &ans ;

	%put;

	%exit:
/*	%ds_alter(&odsn, drop = age);
	%put (iii) Compare two different datasets;
	%ds_compare(_dstest41,&odsn,_ans_=ans);
	%put (iii) result: &ans;*/

	*%work_clean(_dstest1,_dstest5,_dstest35);
%mend _example_ds_compare;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES; */
%_example_ds_compare;  
 
/** \endcond   */
 
