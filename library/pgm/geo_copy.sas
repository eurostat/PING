/** 
## geo_copy {#sas_geo_copy}
Copy all observations of a given geographical area/country onto another geographical area/country
set of observations.

~~~sas
	geo_copy(dsn, igeo, ogeo, time=, replace=NO, lib=WORK); 
~~~

### Arguments
* `dsn` : an input reference dataset;
* `igeo` : a string representing a country ISO-code or a geographical zone;
* `ogeo` : _ibid_, a string representing a country ISO-code or geographical zone;
* `time` : (_option_) selected year for which the copy is operated; default: not set, and all 
	`igeo` observations are copied into `ogeo` observations;
* `replace` : (_option_) boolean flag (`yes/no`) set to actually replace of `igeo` observations
	by `ogeo` observations; default: `replace=NO`, _i.e_ all `igeo` observations are preserved
	in the dataset;
* `lib` : (_option_) name of the library where `dsn` is stored; by default: empty, _i.e._ `WORK`
	is used.

### Returns
It will update the input dataset `dsn` with `ogeo` observations that are copies of the `igeo`
observations at time `time`.

### Example
Given the table `dsn`: 
| geo  | time | ivalue |
|:----:|-----:|-----:|
| EU28 | 2016 | 1 |
| EU28 | 2015 | 1 |
| EU28 | 2014 | 1 |
| EU27 | 2016 | 2 |
| EU27 | 2015 | 2 |
| EU27 | 2014 | 2 |
| EU   | 2016 | 3 |
the following command:

~~~sas
	%geo_copy(dsn, EU28, EU, time=2015 2014, lib=WORK);
~~~
will update the table `dsn` as follows:
| geo  | time | ivalue |
|:----:|-----:|-----:|
| EU28 | 2016 | 1 |
| EU28 | 2015 | 1 |
| EU28 | 2014 | 1 |
| EU27 | 2016 | 2 |
| EU27 | 2015 | 2 |
| EU27 | 2014 | 2 |
| EU   | 2016 | 3 |
| EU   | 2015 | 1 |
| EU   | 2014 | 1 |

Run macro `%%_example_geo_copy` for more examples.

### See also
[%silc_agg_process](@ref sas_silc_agg_process),
[%obs_duplicate](@ref sas_obs_duplicate), [%meta_countryxzone](@ref meta_countryxzone).
*/ /** \cond */

/* credits: gjacopo */

%macro geo_copy(dsn	/* Input dataset 										(REQ) */
				, igeo
				, ogeo
				, time=
				, lib=
				, replace=
				); 
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* IGEO/OGEO: check */

	/* TIME: check */
	%if not %macro_isblank(time) %then %do;
		%let correct=%list_ones(%list_length(&time), item=0);
		%if %error_handle(ErrorInputParameter, 
				%par_check(&time, type=INTEGER, range=1900/*dumb date */) NE &correct, mac=&_mac,	
				txt=!!! Parameter in TIME must be integer >0 !!!) %then
			%goto exit;
	%end;

	/* LIB: set default */
	%if %macro_isblank(lib) %then 			%let lib=WORK;

	/* REPLACE: set/check */
	%if %macro_isblank(replace) %then 		%let replace=NO;
	%else 									%let replace=%upcase(&replace);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&replace, type=CHAR, set=YES NO) NE 0, mac=&_mac,	
			txt=%bquote(!!! Wrong parameter REPLACE - Must be a boolean flag !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _dsn			/* temporary dataset */
		l_GEO			/* name of GEO label */
		l_TIME;			/* ibid, TIME */
	%let _dsn=_TMP_&ogeo;

	%if %symexist(G_PING_LAB_GEO) %then 		%let l_GEO=&G_PING_LAB_GEO;
	%else										%let l_GEO=geo;
	%if %symexist(G_PING_LAB_TIME) %then 		%let l_TIME=&G_PING_LAB_TIME;
	%else										%let l_TIME=time;

	DATA WORK.&_dsn;
		SET &lib..&dsn(WHERE=(&l_GEO="&igeo" 
			%if not %macro_isblank(time) %then %do;
				and &l_TIME in %sql_list(&time)
			%end;
			));
		&l_GEO="&ogeo";
	run; 

	DATA &lib..&dsn;
		SET &lib..&dsn
			%if "&replace"="YES" %then %do;
				(WHERE=(not(&l_GEO="&ogeo" 
				%if not %macro_isblank(time) %then %do;
					and &l_TIME in %sql_list(&time)
				%end;
				))) 
			%end;
			WORK.&_dsn; 
	run;

	%work_clean(&_dsn); 

	%exit:
%mend geo_copy;

%macro _example_geo_copy;
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

	DATA dumb;
		geo="AT"; time=2016; ivalue=1; output;
		geo="AT"; time=2015; ivalue=1; output; 
		geo="AT"; time=2014; ivalue=1; output;
		geo="AT"; time=2013; ivalue=1; output;
		geo="AT"; time=2012; ivalue=1; output;
		geo="ES"; time=2016; ivalue=2; output;
		geo="ES"; time=2015; ivalue=2; output;
		geo="ES"; time=2014; ivalue=2; output;
		geo="ES"; time=2013; ivalue=2; output;
		geo="ES"; time=2012; ivalue=2; output;
		geo="FR"; time=2016; ivalue=3; output;
		geo="FR"; time=2015; ivalue=3; output;
		geo="FR"; time=2014; ivalue=3; output;
		geo="FR"; time=2013; ivalue=3; output;
		geo="FR"; time=2012; ivalue=3; output;
	run;
	
	DATA dumber;
		SET dumb;
	run;

	%put (i) Create new data as duplicates of existing ones;
	%geo_copy(dumber, AT, DE, lib=WORK);
	%ds_print(dumber, title="DE data CREATED as duplicates of AT data");

	%put (ii) Add redundant data with duplicates of existing ones;
	%geo_copy(dumber, AT, FR, time=2015 2016, lib=WORK);
	%ds_print(dumber, title="2015 and 2016 FR data ADDED with duplicate of ES data");

	%put (iii) Replace data by duplicates of existing ones;
	%geo_copy(dumber, ES, FR, lib=WORK, replace=YES);
 	%ds_print(dumber, title="All FR data REPLACED by duplicates of AT data");

	%exit:
%mend _example_geo_copy;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_geo_copy;
*/
%_example_geo_copy;

/** \endcond */
