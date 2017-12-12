/** 
## obs_count {#sas_obs_count}
Check how many observations (rows) of a dataset verify a given condition.

~~~sas
	%obs_count(dsn, _ans_=, where=, pct=yes, distinct=no, lib=WORK);
~~~

### Arguments
* `dsn` : a dataset, for which the condition has to be verified;
* `where` : (_option_) SAS expression used to further refine the selection (`WHERE` option); 
	should be passed with `%%str`; default: empty;
* `pct` : (_option_) a boolean flag (`yes/no`) set to return the result as a percentage of the
	total observations in `dsn` that verify the condition `cond` above; default: `pct=yes`, 
	_i.e._ result is returned as a percentage [0,100] of the total numbers of observations;
* `distinct` : (_option_) boolean flag (`yes/no`) set to count only distinct values; in practice, 
	runs a SQL `SELECT DISTINCT` process instead of a simple `SELECT`; default: `no`, _i.e._ all 
	values are counted;
* `lib` : (_option_) the library in which the dataset `dsn` is stored.

### Returns
`_ans_` : name of the macro variable used to store the (quantitative) output of the test, which
	is, depending on the value of the flag `pct`: 
		+ `n`, the number of observations that verify the condition `cond` when `pct=yes`;
		+ 100*`n/N`, where `N` is the total number of observations in the dataset `dsn`, and `n` 
		is like above;

	hence the nul result corresponds to the situation `n=0`. where no observation in the dataset 
	verifies the input condition. 

### Examples
Let's perform some test on the values of test datatest #1000 (with 1000 observations sequentially
enumerated), _e.g._:
	
~~~sas
	%_dstest1000;
	%let ans=;
	%let cond=%quote(i le 0);
	%obs_count(_dstest1000, where=&cond, _ans_=ans);
~~~
returns `ans=0`, while:

~~~sas
	%let cond=%quote(i gt 0);
	%obs_count(_dstest1000, where=&cond, _ans_=ans);
~~~
returns `ans=100`, and:

~~~sas
	%let cond=%quote(i lt 400);
	%obs_count(_dstest1000, where=&cond, _ans_=ans);
~~~
returns `ans=40`.

Run `%%_example_obs_count` for more examples.

### Notes
1. For very large tables, the accuracy of the result returned when `pct=yes` is relative to
the precision of your machine. 
In practice, for tables with more than 1E9 observations where all but 1 verify the condition 
`cond`, the percentage calculated may still be equal to 100 (instead of a value<100). In that 
case, it is preferred to set the flag `pct` to `no` (see `%%_example_obs_count`).
2. Note in general the use of `%%str` (or `%%quote`) so as to express a condition. 

### Reference
Gupta, S. (2006): ["WHERE vs. IF statements: Knowing the difference in how and when to apply"](http://www2.sas.com/proceedings/sugi31/238-31.pdf).

### See also
[%ds_count](@ref sas_ds_count), [%ds_check](@ref sas_ds_check), [%ds_delete](@ref sas_ds_delete), 
[%ds_select](@ref sas_ds_select).
*/ /** \cond */

/* credits: grazzja */

%macro obs_count(dsn		/* Input reference dataset 										(REQ) */
				, _ans_=	/* Name of the macro variable storing the result of the test 	(REQ) */
				, where=	/* Expression used as a test over all observations 				(OPT) */
				, pct=		/* Boolean flag set to format the output result					(OPT) */
				, distinct=	/* Distinct clause 												(OPT) */
				, lib=		/* Name of the input library 									(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* _ANS_ : check */
	%if %error_handle(ErrorOutputParameter, 
			%macro_isblank(_ans_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _ANS_ not set !!!) %then
		%goto exit;

	/* DSN/LIB: settings/checkings */
 	%if %macro_isblank(lib) %then 	%let lib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&dsn) not found !!!) %then
		%goto exit;

	/* WHERE: further checkings */
	%if %error_handle(WarningInputParameter, 
			%macro_isblank(where) EQ 1, mac=&_mac,		
			txt=! No WHERE condition has been defined !, verb=warn) %then
		%goto warning;
	%warning:

	/* PCT: further checkings */
 	%if %macro_isblank(pct) %then 	%let pct=YES;
	%else							%let pct=%upcase(&pct);

	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&pct), type=CHAR, set=YES NO) EQ 1, mac=&_mac,		
			txt=!!! Wrong value for boolean flag PCT !!!) %then
		%goto exit;

	/* DISTINCT: checking and default settings */
	%if %macro_isblank(distinct)  %then 	%let distinct=NO; 
	%else									%let distinct=%upcase(&distinct);

	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&distinct), type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong parameter for boolean flags DISTINCT !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local nb_obs_0 /* number of observations in the dataset */
		nb_obs_1	/* number of observations in the dataset that verify the condition */
		_ans; 		/* output value of the test */

	/* count the number of observations in the input dataset */
	%if %macro_isblank(where) or %upcase("&pct")="YES" %then %do;
		PROC SQL noprint;
			SELECT 
			%if %upcase("&distinct")="YES" %then %do;
				DISTINCT
			%end;
			COUNT(*) INTO: nb_obs_0 
			FROM &lib..&dsn;
		quit;
	%end;

	/* count the number of observations with the desired condition */
	%if not %macro_isblank(where) %then %do;
		PROC SQL noprint;
			SELECT 
				%if %upcase("&distinct")="YES" %then %do;
				DISTINCT
			%end;
			COUNT(*) /* strip(put(COUNT(DISTINCT *),15.)) */ INTO: nb_obs_1  
			FROM &lib..&dsn
			WHERE &where;
		quit;
	%end;
	%else 
		%let nb_obs_1 = &nb_obs_0;

	%if %error_handle(ErrorInputDataset, 
			%macro_isblank(nb_obs_1) EQ 1, mac=&_mac,		
			txt=%quote(!!! SQL procedure fails, condition %upcase(&where) may be wrong !!!)) %then 
		%goto exit;

	/* Another approach consists in creating a temporary dataset:
		%local _tmp;
		%let _tmp=TMP%upcase(&_mac);
		%ds_select(&dsn, &_tmp, where=&where, ilib=&lib);
		%ds_count(&_tmp, _nobs_=nb_obs_1, lib=&lib);
	* which essentially runs the following DATA step and PROC SQL procedures:
		DATA &_tmp;
			SET &lib..&dsn;
			WHERE &where;
		run;
		PROC SQL;
			SELECT COUNT(*) INTO: nb_obs_1 
			FROM &_tmp;
		quit;
	* but also imply to clean your shit
		%work_clean(&_tmp);
	*/

	/* compute the final value */
	%if %upcase("&pct")="YES" %then
		%let _ans = %sysevalf(100 * &nb_obs_1 / &nb_obs_0);
	%else
		%let _ans = %sysevalf(&nb_obs_1, integer);

	/*%let &_ans_=&_ans;*/
	data _null_;
		call symput("&_ans_",&_ans);
	run;

	%exit:
%mend obs_count;


%macro _example_obs_count;
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

	%local cond ans dsn;
	%let YOU_WANT_TO_WASTE_YOUR_TIME=no;
	%let TEST_CRASH_AS_YOU_LIKE=no;

	%_dstest1000;

	%if &TEST_CRASH_AS_YOU_LIKE=yes %then %do;
		%put; 
		%put (o) Test a dummy condition over a test dataset #1000;
		*options nosource nonotes errors=0;
		%obs_count(_dstest1000, _ans_=ans, where=%quote(DUMMY gt 0));
		*options source notes errors=9007199254740992;
		%if %macro_isblank(ans) %then 	%put OK: TEST PASSED - Wrong parameterisation: fails;
		%else 							%put ERROR: TEST FAILED - Wrong parameterisation: passes;
	%end;

	%put; 
	%put (i) Test a regular expression on a non-existing table;
	%obs_count(DUMMY, _ans_=ans, where=%quote(var>0));
	%if %macro_isblank(ans) %then 	%put OK: TEST PASSED - Wrong parameterisation: fails;
	%else 							%put ERROR: TEST FAILED - Wrong parameterisation: passes;

	%let cond=%quote(i ge 0);
	%put;
	%put (ii) Test the condition: &cond on test dataset #1000;
	%obs_count(_dstest1000, _ans_=ans, where=&cond);
	%if &ans=100 %then 			%put OK: TEST PASSED - Test returns 100% (true for all 1000 observations);
	%else 						%put ERROR: TEST FAILED - Test returns &ans;

	%put (iii) Ibid with PCT set to no;
	%obs_count(_dstest1000, _ans_=ans, where=&cond, pct=no);
	%if &ans=1000 %then 		%put OK: TEST PASSED - Test returns #1000 (true for all 1000 observations);
	%else 						%put ERROR: TEST FAILED - Test returns &ans;

	%let cond=%quote(i gt 600);
	%put;
	%put (iv) Ibid with the condition: &cond;
	%obs_count(_dstest1000, _ans_=ans, where=&cond);
	%if &ans=40 %then 			%put OK: TEST PASSED - Test returns 40% (true for 400/1000 observations);
	%else 						%put ERROR: TEST FAILED - Test returns &ans;

	%put (v) Ibid with PCT set to no;
	%obs_count(_dstest1000, _ans_=ans, where=&cond, pct=no);
	%if &ans=400 %then 			%put OK: TEST PASSED - Test returns #400 (true for 400 observations);
	%else 						%put ERROR: TEST FAILED - Test returns &ans;

	%let cond=%quote(i gt 1000);
	%put;
	%put (v) Ibid with the condition: &cond;
	%obs_count(_dstest1000, _ans_=ans, where=&cond);
	%if &ans=0 %then 			%put OK: TEST PASSED - Test returns 0% (false for all 1000 observations);
	%else 						%put ERROR: TEST FAILED - Test returns &ans;
	
	%let cond=%quote(u ge 0);
	%let dsn=TMP%upcase(&sysmacroname);
	%put;
	%ranuni(&dsn, 100);
	%put (vi) Test on a table with 100 observations generated using macro ranuni;
	%obs_count(&dsn, _ans_ = ans, where=&cond, pct=no) ;
	%if &ans=100 %then 			%put OK: TEST PASSED - Test returns #100 (true for all observations);
	%else 						%put ERROR: TEST FAILED - Test returns &ans;
	
	%if &YOU_WANT_TO_WASTE_YOUR_TIME=yes %then %do;
		%local count res;
		%let cond=%quote(i gt 1);
		%let dsn=TMP%upcase(&sysmacroname);
		%put;
		%let count=100000000; /* 1E8 ... try 1E9: be ready to sleep */
		%let res=%sysevalf(100*(&count-1)/&count);
		DATA &dsn;
			do i = 1 to &count;
			   	output;
			end;
		run;
		%put (vii) Test on a table with &count observations generated using macro ranuni;
		%obs_count(&dsn,_ans_ = ans, where=&cond);
		%if &ans=&res %then 	%put OK: TEST PASSED - Test returns &res% (true for almost all observations);
		%else 					%put ERROR: TEST FAILED - Test returns &ans;
	%end;

	%put;

	%work_clean(_dstest1000);
	%work_clean(&dsn);

	%exit:
%mend _example_obs_count;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_obs_count; 
*/

/** \endcond */
