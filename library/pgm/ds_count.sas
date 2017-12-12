/** 
## ds_count {#sas_ds_count}
Count the number of observations in a dataset, possibly missing or non missing for a given 
variable.

~~~sas
	%ds_count(dsn, _nobs_=, miss=, nonmiss=, distinct=no, lib=WORK);
~~~

### Arguments
* `dsn` : a dataset;
* `miss` : (_option_) the name of variable/field in the dataset for which only missing
	observations are considered; default: `miss` is not set;
* `nonmiss` : (_option_) the names of variable/field in the dataset for which only NON 
	missing observations are considered; this is obviously compatible with the `miss` 
	argument above only when the variables differ; default: `nonmiss` is not set;
* `distinct` : (_option_) boolean flag (`yes/no`) set to count only distinct values; in practice, 
	runs a SQL `SELECT DISTINCT` process instead of a simple `SELECT`; default: `no`, _i.e._ all 
	values are counted;
* `lib` : (_option_) name of the input library; by default: `WORK` is used.

### Returns
`_nobs_` : name of the macro variable used to store the result number of observations; 
	by default (_i.e._, when neither miss nor nonmiss is set, the total number of 
	observations is returned).

### Example
Let us consider the table `_dstest28`:
geo | value 
:--:|------:
 ' '|  1    
 AT |  .  
 BG |  2  
 '' |  3 
 FR |  .  
 IT |  5 

then we can compute the TOTAL number of observations in `_dstest28`:

~~~sas
	%local nobs;
	%ds_count(_dstest28, _nobs_=nobs);
~~~
returns `nobs=6`, while:

~~~sas
	%ds_count(_dstest28, _nobs_=nobs, nonmiss=value);
~~~
returns the number of observations with NON MISSING `value`, _i.e._ `nobs=4`, and:

~~~sas
	%ds_count(_dstest28, _nobs_=nobs, miss=value, nonmiss=geo);
~~~
returns the number of observations with MISSING `value` and NON MISSING `geo` at the same 
time, _i.e._ `nobs=1`.

Run macro `%%_example_ds_count` for more examples.

### Notes
1. This macro relies on [%obs_count](@ref sas_obs_count) macro since it actually runs:

~~~sas
	%obs_count(&dsn, _ans_=&_nobs_, where=&where, pct=no, lib=&lib);
~~~
with `where` defined, when both `miss` and `nonmiss` parameters are passed for instance,
as the SAS expression `&miss is missing and not(&nonmiss is missing)`.
2. In practice, running the commands (which imply the creation of an intermediary table):

 ~~~sas
	 %ds_count(dsn, _nobs_=c0, lib=lib);
	 %ds_select(dsn, _tmp, where=&cond, ilib=lib);
	 %ds_count(_tmp, _nobs_=c1, lib=lib);
~~~
provides with a result equivalent to simply launching:
	
~~~sas
	%let ans=;
	%obs_count(dsn, where=&cond, _ans_=ans, pct=yes, lib=WORK);
~~~
and comparing the values of `c0` and `c1`:

~~~sas
	 %if &c1=&c0 %then 			%let ans=100;
	 %else %if &c1 < &c0 %then 	%let ans=%sysevalf(100* &c1/&c0);
	 %else						%let ans=0;
~~~

### References
1. ["Counting the number of missing and non-missing values for each variable in a data set"](<http://support.sas.com/kb/44/124.html>).
2. Hamilton, J. (2001): ["How many observations are in my dataset?"](http://www2.sas.com/proceedings/sugi26/p095-26.pdf).

### See also
[%obs_count](@ref sas_obs_count), [%var_count](@ref sas_var_count), [%ds_check](@ref sas_ds_check), 
[%ds_isempty](@ref sas_ds_isempty), [%var_check](@ref sas_var_check).
*/ /** \cond */

/* credits: grazzja, lamarpi */

%macro ds_count(dsn			/* Input dataset 										(REQ) */
				, _nobs_=	/* Output number of observations 						(REQ) */
				, nonmiss=	/* Name of the variable to test for nonmissing values	(OPT) */
				, miss=		/* Name of the variable to test for missing values		(OPT) */
				, distinct=	/* Distinct clause 										(OPT) */
				, lib=		/* Name of the input library 							(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _miss_isblank 
		_nonmiss_isblank
		_where_isblank
		_nobs_count;

	/* _NOBS_: check that the output macro variable is set */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_nobs_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _NOBS_ not set !!!) %then
		%goto exit;

	/* DSN/LIB: check/set */
    %if %macro_isblank(lib) %then %let lib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&dsn) not found !!!) %then
		%goto exit;

	/* MISS/NONMIS: perform some test on the arguments passed to the macro */
	%let _nonmiss_isblank=%macro_isblank(nonmiss); 	/* 1 when NONMISS is not passed */
	%let _miss_isblank=%macro_isblank(miss); 		/* 1 when MISS is not passed */

	%if &_nonmiss_isblank=0 and &_miss_isblank=0 %then %do;
		%if %error_handle(ErrorInputParameter,
			&nonmiss EQ &miss, mac=&_mac,
			txt=!!! Identical variable used for both MISS and NONMISS arguments !!!) %then
			%goto exit;
	%end;
	%else %if &_miss_isblank=0 %then %do;
		%if %error_handle(ErrorInputParameter, 
				%var_check(&dsn, &miss, lib=&lib) EQ 1, mac=&_mac,		
				txt=!!! Variable %upcase(&miss) does not exist in dataset %upcase(&dsn) !!!) %then
			%goto exit;
	%end;
	%else %if &_nonmiss_isblank=0  %then %do;
		%if %error_handle(ErrorInputParameter, 
				%var_check(&dsn, &nonmiss, lib=&lib) EQ 1, mac=&_mac,		
				txt=!!! Variable %upcase(&nonmiss) does not exist in dataset %upcase(&dsn) !!!) %then
			%goto exit;
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local where;

	%if &_nonmiss_isblank=0 or &_miss_isblank=0 %then %do;
	   	%if &_nonmiss_isblank=0 %then 
 			 %let where=&where %quote( not(&nonmiss is missing)) /*&nonmiss is not null*/;
	   	%if &_nonmiss_isblank=0 and &_miss_isblank=0 %then 
			%let where=&where %quote( and);
		%if &_miss_isblank=0 %then 
 			%let where=&where %quote( &miss is missing);
	%end;
	/* in case neither miss no nomiss is passed
	%local _dsid _nobs;
	%let _nobs=0;
	%let _dsid=%sysfunc(open(&lib..&dsn));
	%if &_dsid>0 %then %do;
		%let _nobs=%sysfunc(attrn(&_dsid,nobs));
	    %let _dsid=%sysfunc(close(&_dsid));
		%let _rc = %sysfunc( close(&_dsid) ); 
	%end;
	*/

	/* run the "counting" procedure */
	%obs_count(&dsn, _ans_=&_nobs_, where=&where, distinct=&distinct, pct=no, lib=&lib);

	/*PROC SQL noprint;
	   	SELECT COUNT(*) INTO:_nobs_count
	  	FROM &lib..&dsn
	   	%if &_nonmiss_isblank=0 or &_miss_isblank=0 or &_where_isblank=0 %then %do;
			WHERE
		%end;
	   	%if &_where_isblank=0 %then %do;
			&where
		%end;
	   	%if &_where_isblank=0 and (&_nonmiss_isblank=0 or &_miss_isblank=0) %then %do;
			and
		%end;
	   	%if &_nonmiss_isblank=0 %then %do;
 			 not(&nonmiss is missing)
		%end;
	   	%if &_nonmiss_isblank=0 and &_miss_isblank=0 %then %do;
			and
		%end;
		%if &_miss_isblank=0 %then %do;
 			&miss is missing
		%end;
		;
	quit;

	data _null_;
		call symput("&_nobs_",%sysevalf(&_nobs_count,integer));
	run;*/

	%exit:
%mend ds_count;


%macro _example_ds_count;
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

	%local nobs;
	%_dstest28;
	%*ds_print(_dstest28);

	%put;
	%put (i) Count the total number of observations in _dstest28...;
	%ds_count(_dstest28, _nobs_=nobs);
	%if &nobs=6 %then 		%put OK: TEST PASSED - Count returns: 6 observations;
	%else 					%put ERROR: TEST FAILED - Count returns: wrong number of observations;

	%put;
	%put (ii) Count the observations with missing VALUE in _dstest28...;
	%ds_count(_dstest28, _nobs_=nobs, miss=value);
	%if &nobs=2 %then 		%put OK: TEST PASSED - Count returns: 2 obervations with missing VALUE;
	%else 					%put ERROR: TEST FAILED - Count returns: wrong number of observations with missing VALUE;

	%put;
	%put (iii) Count the observations with non missing VALUE and missing GEO in _dstest28...;
	%ds_count(_dstest28, _nobs_=nobs, nonmiss=value, miss=geo);
	%if &nobs=1 %then 		%put OK: TEST PASSED - Count returns: 1 obervation with non missing VALUE and missing GEO;
	%else 					%put ERROR: TEST FAILED - Count returns: wrong number of observations with non missing VALUE and missing GEO;

	%let nobs=; /*reset*/
	%put;
	%put (iv) Just fail ...;
	%ds_count(_dstest28, _nobs_=nobs, nonmiss=geo, miss=geo);
	%if &nobs= %then 		%put OK: TEST PASSED - Wrong parameterisation: fails;
	%else 					%put ERROR: TEST FAILED - Wrong parameterisation: passes;

	%put;

	/* clean your shit... */
	%work_clean(_dstest28);

	%exit:
%mend _example_ds_count;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_count; 
*/

/** \endcond */
