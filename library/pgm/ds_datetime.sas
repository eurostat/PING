/** 
## ds_datetime {#sas_ds_datetime}
* Convert date and time (datetime) character variables from dataset or from macro variables in one integer variable.

~~~sas
	%let dt_integer=%ds_datetime_integer(vardate=,vartime=, _dt_integer_=);
~~~

* retrieve time (currentdate variable) and date (lastup variable) from a dsn or from macro variable. Cnvert them in one integer variable.

~~~sas
	%let dt_integer=%ds_datetime_integer(dsn=, _dt_integer_=, currentdate=currentdate, lastup=lastup,lib=WORK);
~~~

### Arguments
* `dsn` : a dataset reference;
* `vardate` : (_option_) variable dataset name for  time;
* `vartime` : (_option_) variable dataset name for  date.
* `currentdate` : (_option_) variable  time;
* `lastup` : (_option_) variable date.
 
### Returns
* `_dt_integer_` :  integer value , _i.e._:
   YYYYMMDDHHMMSS

### Examples
Two semple examples of use, namely: 
Using variables:

~~~sas
	%let vartime=12:52:24;
	%let vardate=09FEB17;	
	%ds_datetime_integer(vardate=&vardate,vartime=&vartime, _dt_integer_=);
~~~

returns: `dt_integer=20170209125224`.
 
Using  test dataset #41:

~~~sas
    %let dsn=_dstest41;
	%ds_datetime_integer(dsn=&dsn,_dt_integer_=, currentdate=currentdate, lastup=lastup,lib=);
~~~
	
returns: `dt_integer=YYYMMDDHHMMSS`	 

Run macro `%%_example_ds_datetime_integer` for more examples.
### Notes
Accepted formats for:
	     vartime is HH:MM:SS
         vardate is DDMMMYY
 
Examples: 
~~~sas
	%let vartime=12:52:24;
    %let vardate=09FEB17;
~~~

### See also
*/ 
/** \cond */

/* credits: grillma */

%macro ds_datetime_integer( dsn=  	    	 /* Input dataset 	        		(REQ) */
                           	, vartime=       /* input variable    				(REQ) */
							, vardate=       /* input variable   				(REQ) */
							, _dt_integer_=  /* output result                   (REQ) */
                            , currentdate=   /* dataset variable name           (OPT) */
  							, lastup=        /* dataset variable name           (OPT) */
							, lib=	         /* Name of the input library		(OPT) */
			        		);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);
  

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/
 	%local  _ansds   /* boolean variable result of check whether dsn macro variable is empty or not        */
		;

	%let _ansds=0;   /* input dsn is setted     */

	/* DSN,VARTIME,VARDATE, LIB: set/check */
	%if %error_handle(ErrorInputParameter,   /*check if the three input variables are missing at the same time */
			%macro_isblank(dsn) NE 0 AND %macro_isblank(vardate) NE 0 AND %macro_isblank(vartime) NE 0, mac=&_mac,		
			txt=!!! Input parameters not set !!!) %then
		%goto exit;
	%if %error_handle(ErrorInputParameter,   /*check if the three input variable are setted at the same time */
			%macro_isblank(dsn) EQ 0 AND %macro_isblank(vardate) EQ 0 AND %macro_isblank(vartime) EQ 0, mac=&_mac,		
			txt=!!! Input parameters error: not all input parameters have to be setted at the same time !!!) %then
		%goto exit;  

	%if %error_handle(InputParameter,       /*check whether dsn (input data set ) is not set */
			%macro_isblank(dsn) NE 0, mac=&_mac,		
			txt=!!! Input parameter DSN does not  set !!!,verb=WARM) %then %do;
		%let _ansds=1;
		%goto continue;
	%end;
    %if %error_handle(ErrorInputParameter, /* check whether vartime or vardate input variables are not setted */ 
			(%macro_isblank(vartime) NE 0 OR %macro_isblank(vardate) NE 0) and &_ansds=1, mac=&_mac,		
			txt=!!! None of the variables defined in vartime(for time)  or in vardate (for date) is  setted !!!) %then
		%goto exit;
    
    %continue:
	/* if &_ansds=0 %then dsn must be setted: time and date could be retrieved from dataset */
	%if &_ansds=0  %then %do;
	%if %macro_isblank(lib) 		%then 	%let lib=WORK;
	
	%if %error_handle(ErrorInputDataset,    /* check whether dsn exist */
				%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
				txt=!!! Input dataset %upcase(&dsn) not found !!!) %then
		%goto exit;
	%if %macro_isblank(currentdate) %then 	%let currentdate=CURRENTDATE;
	%if %macro_isblank(lastup) 		%then 	%let lastup=LASTUP;

   	%if %error_handle(ErrorInputParameter, /* check whether &lastup (date) and &currentdate (time) variable are empty */
				%var_check(&dsn, &currentdate, lib=WORK) NE 0 OR %var_check(&dsn, &lastup, lib=WORK), mac=&_mac,		
				txt=!!! None of the variables defined in %upcase(&currentdate) or %upcase(&lastup) was found in dataset %upcase(&dsn) !!!) %then
		%goto exit;
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/
    %local _dt		   	/* temporary time variable   */
		__dt			/* temporary time variable   */
		_day 	    	/* temporary day variable    */
		_dt_integer     /* output answer             */
        ;
	%if &_ansds=0  %then %do;        /* case dsn setted: retrieve time and day from dsn */
    	data _null_;
			set &dsn;
			call symput("_dt",&currentdate);
			call symput("_day",&lastup);
		run;
	/* check  whether date and day macro variable  are empty*/
    	%if %error_handle(ErrorInputParameter, 
				%macro_isblank(_dt) NE 0 OR %macro_isblank(_day) NE 0 , mac=&_mac,		
				txt=!!! time or day macro variable are empty  !!!) %then
		%goto exit;
	%end;
	%else %if &_ansds=1 %then %do;   /* case: dsn not setted */
	 	%let _dt=&vartime;    	
        %let _day=&vardate;
	%end;

	%let __day=%sysfunc(inputn(&_day,date9.),yymmdd10.);     /* change day format from  09FEB17 in 2017-02-09  */
	%let ___day=%sysfunc(compress(%sysfunc(tranwrd(&__day, -,%quote()))));
	%let __dt=%sysfunc(compress(%sysfunc(tranwrd(&_dt, :,%quote()))));
	%let _dt_integer=&___day&__dt;

     /* return the answer */
 	data _null_;
		call symput("&_dt_integer_","&_dt_integer");
	run;
	 
	%exit:
%mend ds_datetime_integer;
%macro _example_ds_datetime_integer;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	%put;
	%local dt_integer;
	%put (i) dsn vartime and vardate do not exit  ;
    %ds_datetime_integer(_dt_integer_=dt_integer);
	%put;
	%put (ii) dsn, vartime and vardate are  setted  ;
	%_DSTEST41;
	%let dsn=_DSTEST41;
	%let vartime=12:52:24;
	%let vardate=09FEB17;
    %ds_datetime_integer(dsn=&dsn,vartime=&vartime,vardate=&vardate,_dt_integer_=dt_integer);
	%put;
	%put (iii) date variable does not not exit in &dsn ;
	*%let dsn=_DSTEST41;
    %ds_datetime_integer(dsn=&dsn,_dt_integer_=dt_integer,currentdate=current);
	%put;
	%put (vi) case: vartime and vardate  setted and not dsn ;
	%let vartime=12:52:24;
	%let vardate=09FEB17;
    %ds_datetime_integer(vartime=&vartime,vardate=&vardate,_dt_integer_=dt_integer);
	%put dt_integer=&dt_integer  ;
	%put;
	%put (v) case: dsn setted: currentdate and lastup variable are merged in one integer variable ;
   	%ds_datetime_integer(dsn=&dsn,_dt_integer_=dt_integer,currentdate=currentdate, lastup=lastup,lib=WORK);
    %put dt_integer=&dt_integer;
	%work_clean(_dstest41);
%mend _example_ds_datetime_integer;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;*/
%_example_ds_datetime_integer; 
*/
/* VFORMAT(var)*/
