/** 
## silc_hsum_of_pvar {#sas_silc_hsum_of_pvar}
Sum P varibale by row and  columns

~~~sas
	%silc_hsum_of_pvar(yyyy, odsn=,ds=,var=,rvar=,ovar=,by=,lib=pdb, olib=WORK);
~~~
		   				
### Arguments
* `yyyy` : reference year;  
* `odsn` : a output dataset;
* `ds`   : type of input dataset;
* `var`  : name of variable on which the sum is calculated;
* `by`   : list of variables used for GROUP BY condition in SQL statement; by default: empty, _i.e._ `PB010 PB020 PHID` 
	is used;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `pdb` is used;
  
### Returns
* `odsn` : (_option_) name of the output dataset (in `WORK` library);by default: empty, _i.e._ `hsum` is used;
* `ovar` :  sum variable ;by default: empty, _i.e._ `hsum` is used;
* `rvar` :  sumrow P  variables ;by default: empty, _i.e._ `Ptot` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is used.

### Examples
Let us consider the test dataset #45:
DB020 | DB010 |   RB030  |EQ_INC20 | RB050a
:----:|:-----:|----------:--------:|---------
 BE   | 2015  |   3310   |   10    |   10 
 BE   | 2015  |   3311   |   10    |   10 
 BE   | 2015  |   3312   |   10    |   10 
 BE   | 2015  |   4434   |   20	   |   20 


and run the macro:
	
~~~sas
	%silc_hsum_of_pvar();
~~~
which updates QUANTILE with the following table:
DB020 | DB010 |   RB030  |EQ_INC20 | RB050a | QUINTILE |    QUANTILE
:----:|:-----:|:--------:|:-------:|:------:|:--------:|:------------:
  BE  |	2015  |	  3310	 |   10	   |  10	|     1    |  QUINTILE  1
  BE  |	2015  |	  3311	 |   10	   |  10	|     1    |  QUINTILE  1

 
Run macro `%%_example_income_quantile` for more examples.

### Note
In short, the macro runs the following `PROC SORT` procedure:

~~~sas
	PROC SQL noprint;
		CREATE TABLE &olib..&_dsn AS 
		SELECT
			input.*,		    
			%if %macro_isblank(Pvar) EQ 0 %then %do;
				 sum(&_Pvar,0) as Ptot,
			%end;
			sum(calculated Ptot) as &ovar
		FROM Ppdb.&Pds as input 
		GROUP BY &_by;
	 QUIT;
~~~

### See also
[%ds_isempty](@ref sas_ds_isempty), [%lib_check](@ref sas_lib_check), [%var_check](@ref sas_var_check),
[SORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000057941.htm).
*/ /** \cond */

/* credits: grillma */

%macro silc_hsum_of_pvar(yyyy
						, odsn=
						, ids=
						, var=
						, rvar=
						, ovar=
						, by =
						, ilib=
						, olib=);

	%local _mac;
	%let   _mac=&sysmacroname;
	%macro_put(&_mac);

	%local _i   	/* counter 			 				    */
	   	 _dsn   	/* temporary dataset 				    */
	 	 _Pvar  	/* P variable with comma as separator   */
		 _ans       /* boolean variable - answer a test     */
		 yy         /* two digits of year                   */ 
		 path       /* input libname                        */
		 ds         /* input dataset                        */
		 list       /* check variable                       */
		 _by        /* &by variable with comma separator    */
		;

 	%let _dsn=_TMP&_mac;
	%let _ans=;

    
 	%if %macro_isblank(ilib)        EQ 1   %then    %let ilib=pdb;
	%if %macro_isblank(ids)         EQ 1   %then    %let ids=P;
	%if %macro_isblank(olib)        EQ 1   %then    %let olib=WORK;
	%if %macro_isblank(odsn)        EQ 1   %then    %let odsn=HSUM;
	%if %macro_isblank(by)          EQ 1   %then    %let by=PB010 PB020 PHID;

    %if %error_handle(ErrorInputDataset, 
				%macro_isblank(yyyy) EQ 1, mac=&_mac,		
				txt=!!! YEAR  variable is missing !!!)   %then 
		%goto exit;

    %let yy=%substr(&yyyy,3,2);
    %if %error_handle(ErrorInputDataset, 
				%macro_isblank(var) EQ 1, mac=&_mac,		
				txt=!!! P variables are missing !!!) 
			or %error_handle(ErrorInputDataset, 
				%macro_isblank(ids) EQ 1, mac=&_mac,
				txt=!!! Input dataset is missing!!!)  %then 
		%goto exit;

    	/* set/locate automatically all libraries of interest for the given year */
    %silc_db_locate(X, &yyyy, src=&ilib, db=&ids, _ds_=ds, _path_=path);
	%let Ppath = %scan(&path, 1, %quote( )); %let Pds=%scan(&ds, 1);
	libname Ppdb "&Ppath";
	/*%let Hpath = %scan(&path, 2, %quote( )); %let Hds=%scan(&ds, 2);
	libname Hpdb "&Hpath";*/
	%silc_db_locate(X, &yyyy, src=idb, _ds_=ds, _path_=path);
	libname idb "&path";

	%if %error_handle(ErrorInputDataset, 
				%ds_check(&Pds, lib=Ppdb) EQ 1, mac=&_mac,	
				txt=!!! Input dataset %upcase(&Pds) not found !!! !!!) 
			or %error_handle(ErrorInputDataset, 
				%ds_check(&ds, lib=idb) EQ 1, mac=&_mac,		
				txt=!!! Input dataset %upcase(&ds) not found !!!)  %then 
		%goto exit;
       /* check if list of &Pvar  exit */
     %let _ans=%var_check(&Pds, &Pvar, lib=Ppdb);
	 %do _i=1 %to %list_length(&Pvar);
			%let list=&list 0;
	 %end;
	 %if %error_handle(ErrorInputParameter, 
			&_ans NE  &list, mac=&_mac,	
			txt=!!! Some  %upcase(&Pds) variables not found !!! !!!)  %then 
		%goto exit;


     %let _Pvar=%list_quote(&Pvar, mark=_EMPTY_, rep=%quote(,));
	 %let _by=%list_quote(&by, mark=_EMPTY_, rep=%quote(,));


     %if %macro_isblank(ovar)        EQ 1   %then    %let ovar=hsum;
	 %if %macro_isblank(rvar)        EQ 1   %then    %let rvar=Ptot;

     PROC SQL noprint;
		CREATE TABLE &olib..&_dsn AS 
		SELECT
			input.*,		    
			%if %macro_isblank(Pvar) EQ 0 %then %do;
				 sum(&_Pvar,0) as &rvar,
			%end;
			sum(calculated Ptot) as &ovar
		FROM Ppdb.&Pds as input 
		GROUP BY &_by;
	 QUIT;

	%exit:
%mend silc_hsum_of_pvar;
/*%let pvar=PY010G PY020G;
%silc_hsum_of_pvar(2015	, var=&Pvar, rvar=, ovar=, by =, ilib=pdb, olib=);*/
%macro _example_silc_hsum_of_pvar;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
%mend _example_silc_hsum_of_pvar;

/* Uncomment for quick testing
options NOSOURCE NOMRECALL MLOGIC MPRINT NOTES;
%_example_silc_hsum_of_pvar;
*/


/** \endcond */
%_example_silc_hsum_of_pvar;


