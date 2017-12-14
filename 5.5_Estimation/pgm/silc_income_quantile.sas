/** 
## silc_income_quantile {#sas_silc_income_quantile}
Quantiles of an income distribution for specific year.

~~~sas
	%silc_income_quantile(idsn, var,by, label=,breakdowns=,weight=,weighted=, odsn=,lib=WORK, olib=WORK);
~~~
		   				
### Arguments
* `idsn` : a dataset reference;
* `var`  :  name of variable on which the quantiles are calculated;
* `by`   :  number of quantiles to calculate ( 10, 100,5,etc. ) ;
* `label`:  type  of quantiles to calculate  ( decile, percentile, quintile, etc.) ;
* `weight` : (_option_) name  of weight variables;default: RB050a ;
* `weighted`:(_option_) boolean variable( YES/NO) ;default: YES ; 
* `breakdowns`  : (_option_) breakdowns variables  ; 	default: DB010 DB020;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
  
### Returns
* `odsn` : (_option_) name of the output dataset (in `WORK` library);
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` 
	is used.

### Examples
Let us consider the test dataset #45:
DB020 | DB010 |   RB030  |EQ_INC20 | RB050a
:----:|:-----:|---------:|--------:|--------:
 BE   | 2015  |   3310   |   10    |   10 
 BE   | 2015  |   3311   |   10    |   10 
 BE   | 2015  |   3312   |   10    |   10 
 BE   | 2015  |   4434   |   20	   |   20 
 BE   | 2015  |   4435   |   20	   |   20 
 BE   | 2015  |   4455   |   20	   |   20 
 BE   | 2015  |   55667  |   20	   |   20 
 IT   | 2015  |  999998  |   10	   |   10 
 IT   | 2015  |  999999  |   10	   |   10 
 IT   | 2015  |  999900  |   10	   |   10 
 IT   | 2015  |  777777  |   20	   |   20 
 IT   | 2015  |  777790  |   20	   |   20 
 IT   | 2015  |  555578  |   20	   |   20 
 IT   | 2015  |  778900  |   20	   |   20 

and run the macro:
	
~~~sas
	%silc_income_quantile(_DSTEST45, EQ_INC20,5,QUINTILE,weight=RB050a);
~~~
which updates QUANTILE with the following table:
DB020 | DB010 |   RB030  |EQ_INC20 | RB050a | QUINTILE |    QUANTILE
:----:|:-----:|:--------:|:-------:|:------:|:--------:|:------------:
  BE  |	2015  |	  3310	 |   10	   |  10	|     1    |  QUINTILE  1
  BE  |	2015  |	  3311	 |   10	   |  10	|     1    |  QUINTILE  1
  BE  |	2015  |	  4435	 |   10	   |  20	| 	  1    |  QUINTILE  1
  BE  |	2015  |	  4434	 |   20	   |  20	|     2    |  QUINTILE  2
  BE  |	2015  |	  4455	 |   30	   |  20    |     3    |  QUINTILE  3
  BE  |	2015  |	 55667	 |   40	   |  20    | 	  4    |  QUINTILE  4
  BE  |	2015  |	  3312	 |   60	   |  10    |	  5    |  QUINTILE  5
  IT  |	2015  |	999998	 |   10	   |  10    |	  1    |  QUINTILE  1  
  IT  |	2015  |	555578	 |   20	   |  20	|     1    |  QUINTILE  1
  IT  |	2015  |	777777	 |   30	   |  20	|     2    |  QUINTILE  2
  IT  |	2015  |	777790	 |   30	   |  20    |     2    |  QUINTILE  2
  IT  |	2015  |	999999	 |   50	   |  10	|     4    |  QUINTILE  4
  IT  |	2015  |	999900	 |   50	   |  10	|     4    |  QUINTILE  4
  IT  |	2015  |	778900	 |   50	   |  20	|     4    |  QUINTILE  4
 
Run macro `%%_example_silc_income_quantile` for more examples.

### Notes
In short, the macro runs the following `PROC SORT` procedure:

~~~sas
	PROC UNIVARIATE data=&ilib..&idsn noprint;
	     var &var;
		 by &breakdowns;
		 weight &weight; 
	     output out=WORK.&_idsn pctlpre=P_ pctlpts=&nquant to 100 by &nquant;
	RUN; 
~~~
where `nquant` depends on `by`:

~~~sas
	nquant=%sysevalf(100/&by)
~~~

### See also
[%ds_isempty](@ref sas_ds_isempty), [%lib_check](@ref sas_lib_check), [%var_check](@ref sas_var_check),
[SORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000057941.htm).
*/ /** \cond */

/* credits: marinapippi */

%macro silc_income_quantile(idsn   /* input dataset    		       (REQ)*/
			 	, var         /* income  variable  		       (REQ)*/
				, by          /* quantile parameter            (REQ)*/
				, label       /* quantile name                 (OPT)*/
			  	, breakdowns= /* breakdowns variables          (OPT)*/
				, weight=     /* weight variable  			   (OPT)*/
				, weighted=   /* boolean variable (YES/NO)     (OPT)*/
			    , odsn=       /* Name of the output database   (OPT)*/
			    , lib=        /* income variable  			   (OPT)*/
			    , olib=       /* Name of the output libname    (OPT)*/
		    	);
			
	 %local _mac;
	 %let   _mac=&sysmacroname;
	 %macro_put(&_mac);

	 %local _i   	/* counter 			 				*/
	  	 i   	    /* counter           				*/
		 j          /* counter          			    */
	  	 _dsn   	/* temporary dataset 				*/
	 	 nquant 	/* number of quantiles, e.g. 100/10 */
		 _ans       /* boolean variable - answer a test */
		;

 	%let _dsn=_TMP&_mac;
	%let _ans=;
	%let j=0;

	%if %macro_isblank(breakdowns)  EQ 1   %then    %let breakdowns=DB010 DB020;
 	%if %macro_isblank(lib)         EQ 1   %then    %let lib=WORK;
	%if %macro_isblank(olib)        EQ 1   %then    %let olib=WORK;
	%if %macro_isblank(odsn)        EQ 1   %then    %let odsn=QUANTILE;
	%if %macro_isblank(weighted)    EQ 1   %then    %let weighted=YES; 

	%if %error_handle(ErrorInputDataset, 
				%macro_isblank(var) EQ 1, mac=&_mac,		
				txt=!!! Income variable is missing !!!) 
			or %error_handle(ErrorInputDataset, 
				%macro_isblank(idsn) EQ 1, mac=&_mac,
				txt=!!! Input dataset is missing!!!) 
			or %error_handle(ErrorInputDataset, 
				%ds_check(&idsn, lib=&lib) EQ 1, mac=&_mac,		
				txt=!!! Input dataset %upcase(&idsn) not found !!!) 
			or %error_handle(ErrorInputParameter, 
			   %macro_isblank(by) EQ 1, 
			   txt=!!! No BY value is found !!!, verb=warn) %then 
		%goto exit;
        /* check the range for &by parameter: 0 <= &by => 100 */
	%if %error_handle(ErrorInputDataset, 
			%par_check(&by, type=NUMERIC, range=1 100,set=1 100)  NE 0, mac=&_mac,		
			txt=!!! Wrong values for  BY parameter !!!) %then
	%goto exit;
        /* check if &idsn empty  */
    %ds_isempty(&idsn, var=&var, _ans_=_ans, lib=WORK);
	%if %error_handle(ErrorInputDataset, 
				&_ans EQ 1, mac=&_mac,		
				txt=!!! Input dataset %upcase(&idsn) is empty !!!) %then
		%goto exit;
		/* check weight */
	%if  "&weighted" EQ "NO" and %macro_isblank(weight) EQ 1 %then %do;
        data &lib..&idsn;
			set &lib..&idsn;
			weight=1;
		run;
		%let weight=weight;
	%end;
	%else %if %macro_isblank(weight)  EQ 1   %then  %let weight=RB050a; 
	%else  											%let weight=&weight; 

	/************************************************************************************/
	/**                                   actual operation                             **/
	/************************************************************************************/

    %let nquant=%sysevalf(100/&by);

	%ds_sort(&idsn, asc=&breakdowns);
 
	PROC UNIVARIATE data=&lib..&idsn noprint;
	     var &var;
		 by &breakdowns;
		 weight &weight; 
	     output out=WORK.&_dsn pctlpre=P_ pctlpts=&nquant to 100 by &nquant;
	RUN; 
  

	PROC SQL;
		CREATE TABLE &lib..&odsn as
	 	SELECT a.*, 
			(CASE 
		   	%do i=&nquant  %to  100 %by &nquant;
		   		%let _i=%sysevalf(&i);
                %let j=%eval(&j+1);	
				WHEN &var <= b.P_&_i THEN &j 
	   		%end;
	   		ELSE  100 
			END ) AS &label 
		FROM &lib..&idsn as a inner join WORK.&_dsn as b on 
		     %do _i=1 %to %list_length(&breakdowns);
                %let _var= %scan(&breakdowns, &_i);  
                %if %list_length(&breakdowns)= 1 %then %do;
				    a.&_var=b.&_var
				%end;
				%else %if %list_length(&breakdowns) >1 and &_i< %list_length(&breakdowns) %then %do;
                	a.&_var=b.&_var and 
					%end;
					%else %do;
                    	a.&_var=b.&_var
					%end;
			  %end;
			 ;
	 QUIT;
     %ds_sort(&odsn, asc=&breakdowns &label );
	  /*  Format  output  */
       DATA WORK.&odsn;
			set WORK.&odsn;
			%do _i=1 %to &by;
				if &label  = &_i  then    QUANTILE = "&label  &_i  " ;
			%end;
		RUN; 

      *%work_clean(&_idsn);
	 %exit:
%mend silc_income_quantile;

%macro _example_silc_income_quantile;
/*	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
*/
	%local ans;

 	%put;
	%put (i) Test the empty test dataset #0;                                           
	%_dstest0;
 	%silc_income_quantile(_dstest0, var,10,DECILE);
	%put;
	%put (ii) Test the dataset #45 without weight;   
 	%_DSTEST45; 
 	%silc_income_quantile(_DSTEST45, EQ_INC20,10,DECILE,weighted=NO);
	%put;
 	%put (iii) Test the dataset #45;  
 	%_DSTEST45; 
 	%silc_income_quantile(_DSTEST45, EQ_INC20,5,QUINTILE,weight=RB050a);
	%put; 

	/*%work_clean(_dstest0);*/
%mend _example_silc_income_quantile;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;*/
%_example_silc_income_quantile;  
*/

/** \endcond */
