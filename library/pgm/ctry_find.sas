/** 
## ctry_find {#sas_ctry_find}
Return the list of countries available in a given dataset and for a given year, or a 
subsample of it, and store it in an output table. 

~~~sas
	%ctry_find(idsn, year, odsn, ctrylst=, 
				sampsize=0, force_overwrite=no, ilib=, olib=);
~~~

### Arguments
* `idsn` : input reference dataset;
* `year` : year to consider for the selection of country;
* `ctrylst` : (_option_) list of (blank-separated) strings representing the set of countries
	ISO-codes (_.e.g._, produced as the output of `%zone_to_ctry` with the option `_ctrylst_`), 
	to look for; default: `ctrylst` is not set and all available countries (_i.e._ actually
	present) are returned in the output table;
* `sampsize` : (_option_) when >0, only a (randomly chosen) subsample of the countries 
	available in `idsn` is stored in the output table `odsn` (see below); default: 0, 
	_i.e._ no sampling is performed; see also the macro [%ds_sample](@ref sas_ds_sample);
* `force_overwrite` : (_option_) boolean argument set to yes when the table `odsn` is
	to be overwritten; default to `no`, _i.e._ the new selection is appended to the table
	if it already exists;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
 
### Returns
* `odsn` : name of the output table where the list of countries is stored; the countries listed
	in this table are a subset of `ctrylst` when this latter variable is passed;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` 
	is used.

### Example
Say that you are at the beginning of year=2020, EU-SILC still exists, UK has left EU28 which
is now EU27, we launch:

~~~sas
	%local countries;
	%let year=2020
	%zone_to_ctry(EU27, time=&year, _ctrylst_=countries);
~~~
so that `countries` contain the list of all countries member of EU27 at this time. Suppose now
that only AT, FI, HU and LV have transmitted data, then the command to retrieve this information
for indicator LI01 is:

~~~sas
	%ctry_find(LI01, &year, out, ctrylst=&countries, ilib=rdb, olib=WORK);
~~~
which will create the following table `out` in `WORK`ing library:
| time | geo |
|-----:|:---:|
| 2016 |  AT |
| 2016 |  FI |
| 2016 |  HU |
| 2016 |  LV |

Run macro `%%_example_ctry_find` for examples.

### See also
[%ds_sample](@ref sas_ds_sample), [%ctry_select](@ref sas_ctry_select).
*/ /** \cond */

/* credits: gjacopo, marinapippi */

%macro ctry_find(idsn
				, time
				, odsn
				, ctrylst=
				, sampsize=
				, force_overwrite=
				, _nctry_=
				, ilib=
				, olib=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _existsOutput;

    /* IDSN, ILIB: check/set */
	%if %macro_isblank(ilib) %then 		%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) NE 0, mac=&_mac,		
			txt=%bquote(!!! Input dataset %upcase(&idsn) not found in library %upcase(&ilib) !!!)) %then
		%goto exit;

	/* FORCE_OVERWRITE */
	%if %macro_isblank(force_overwrite)  %then 	%let force_overwrite=NO; 
	%else										%let force_overwrite=%upcase(&force_overwrite);
 
	%if %error_handle(ErrorInputParameter, 
			%par_check(&force_overwrite, type=CHAR, set=YES NO) NE 0, mac=&_mac,	
			txt=!!! Parameter FORCE_OVERWRITE is boolean flag with values in (yes/no) !!!) %then
		%goto exit;

    /* ODSN, OLIB: check/set */
	%if %macro_isblank(olib) %then 		%let olib=WORK;

	%if %ds_check(&odsn, lib=&olib) EQ 0 %then %do;
		%let _existsOutput=YES;
		%if %error_handle(WarningOutputDataset, 
				&force_overwrite EQ YES, mac=&_mac,		
				txt=%bquote(! Output dataset %upcase(&odsn) already exists in library %upcase(&olib) !), 
				verb=warn) %then 
			%goto warning; 
	%end;
	%else 
		%let _existsOutput=NO;
	%warning:

    /* _NCTRY_: set */
	%if %macro_isblank(_nctry_) %then %do;
		%local __N;
		%let _nctry_=__N;
	%end;

	/* SAMPSIZE */
	%if %macro_isblank(sampsize)  %then 	%let sampsize=0;
 
	%if %error_handle(ErrorInputParameter, 
			%par_check(&sampsize, type=INTEGER, range=0, set=0) NE 0, mac=&_mac,	
			txt=!!! Parameter SAMPSIZE is an integer >=0 !!!) %then
		%goto exit;

	/* CTRYLST: some internal cuisine */
	%if "&ctrylst"="_ALL_" %then 		%let ctrylst=;

	%local _dsn s_dsn;
	%let _dsn=TMP_%upcase(&sysmacroname);

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* set variables' labels */
	%local L_TIME 
		L_GEO;
	%if %symexist(G_PING_LAB_TIME) %then 			%let L_TIME=&G_PING_LAB_TIME;
	%else											%let L_TIME=TIME;
	%if %symexist(G_PING_LAB_GEO) %then 			%let L_GEO=&G_PING_LAB_GEO;
	%else											%let L_GEO=GEO;

	/* looking through the dataset (idsn) in year (time), define among the countries of (ctry_list)
	 * the list (subset) of countries which are available */ 
	PROC SQL noprint;
		CREATE TABLE &_dsn as 
		SELECT DISTINCT 
			&L_TIME, 
			&L_GEO 
		FROM &ilib..&idsn
		WHERE &L_TIME = &time 
		%if not %macro_isblank(ctrylst) %then %do;
			and &L_GEO in %sql_list(&ctrylst)
			/* if ever, some day, we decide to compute aggregate of NUTS: 
			and substr(&L_GEO,1,2) in %sql_list(&ctry_list); 
			* that will not happen anytime soon... or not */
		%end;
		;
		/* this will not work when the dataset is empty 
		SELECT count(&L_GEO) into :__N 
		FROM &olib..&odsn; 
		*/
	quit;

	/* check that we indeed got something */
	%ds_count(&_dsn, _nobs_=&_nctry_, lib=WORK);
	%if %error_handle(ErrorInputParameter, 
			&&&_nctry_ EQ 0, mac=&_mac,	
			txt=! No country found in year &time !, verb=yes) %then
		%goto quit;

	/* possibly subsample: consider only a party of the available countries */
	%if &sampsize>0 %then %do;	
		%let s_dsn=s_&_dsn;
		/* perform the simple sampling */
		%let var=&L_TIME &L_GEO; /* not really useful */
		%ds_sample(&_dsn, &s_dsn, sampsize=&sampsize, var=&var, 
					method=SRS, nreps=no, ilib=WORK, olib=WORK);
		/* "rename" */
		DATA &_dsn;
			SET &s_dsn;
		run;
		%work_clean(s_dsn)	
	%end;
	/* note that the case: sampsize=0 is regarded as if sampsize=nobs, i.e. all countries are selected */

	/* create or append the new observations */
	DATA &olib..&odsn;
		SET
		%if "&_existsOutput"="YES" /*%sysfunc(exist(&olib..&odsn))*/ and "&force_overwrite"="NO" %then %do;
			/* append to the original dataset */
			&olib..&odsn
		%end;
		&_dsn;
	run;

	/* result is returned in &_ctry_part_ 
	%var_to_clist(&odsn, &L_GEO, lib=WORK, _varclst_=&_ctry_part_, num=&ctry_part_n, lib=&olib);
	* this is now done outside!
	*/

	/* clean */
	%quit:
	%work_clean(&_dsn)

	%exit:
%mend ctry_find;


/* test the selection of countries */
%macro _example_ctry_find;  
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

	%local cyear year1 year2 
		ctry_tab ctry_glob ctry_part
		dsn;

	libname rdb "&G_PING_C_RDB"; /* "&eusilc/IDB_RDB_TEST/C_RDB"; */ 

	%let ctry_tab=TMP%upcase(&sysmacroname);

	%let dsn=LI01;
	%put For the dataset dsn=&dsn ...;

	%let ctry_glob=AT BE BG CY CZ DE DK EE ES FI FR EL HU IE 
					IT LT LU LV MT NL PL PT RO SE SI SK UK HR;
	/* instead of manually defining ctry_glob, we could use:
		%local ctry_glob;
		%zone_to_ctry(EU28, time=2016, _ctrylst_=ctry_glob);
	 */ 
	
	/* retrieve current and past years */
	%let date=%sysfunc(datepart(%sysfunc(datetime())));
	%let cyear=%sysfunc(year(&date));
	/* set years of operation */
	%let year1=%eval(&cyear - 1);
	%let year2=%eval(&cyear - 2);
	%let fyear=%eval(&cyear + 1);

	%put (o) Any country available in year &fyear?;
	%ctry_find(&dsn, &fyear, &ctry_tab, ctrylst=&ctry_glob, ilib=rdb, olib=WORK);

	%put (i) The table &ctry_tab of countries available in &year1 is created;
	%ctry_find(&dsn, &year1, &ctry_tab, ctrylst= &ctry_glob, ilib=rdb, olib=WORK);
	%ds_print(&ctry_tab, title="Countries available in &year1");

	%put (ii) The table &ctry_tab of countries available in &year2 is appended;
	%ctry_find(&dsn, &year2, &ctry_tab, ctrylst= &ctry_glob, ilib=rdb);
	%ds_print(&ctry_tab, title="Countries available in &year1 and &year2");
	%var_to_list(&ctry_tab, geo, _varlst_=ctry_part);
	%put Countries available in years &year1 and &year2 (no duplicated countries present in both years):;
	%put &ctry_part;

	/* the table &ctry_tab of countries available in &year1 is reset like before */
	%work_clean(&ctry_tab);
	%ctry_find(&dsn, &year1, &ctry_tab, ctrylst= &ctry_glob, ilib=rdb);
	/* %ds_print(&ctry_tab, title="");*/

	%let sampsize=3; 
	%put (iv) A list of &sampsize randomly chosen countries from &year2 is appended;
	%ctry_find(&dsn, &year2, &ctry_tab, ctrylst= &ctry_glob, sampsize=&sampsize, ilib=rdb);
	%ds_print(&ctry_tab, title="Countries available in &year1 + &sampsize random countries available in &year2");
	%var_to_list(&ctry_tab, geo, _varlst_=ctry_part);
	%put Countries available in year &year1 and randomly chosen in &year2:;
	%put &ctry_part;

	%work_clean(&ctry_tab);

	%exit:
%mend _example_ctry_find;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ctry_find;  
*/

/** \endcond */
