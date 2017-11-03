/** 
## ctry_select {#sas_ctry_select}
Build the list of countries/years to take into consideration in order to calculate the 
aggregate value for a given indicator and a given area.
 
~~~sas
	%ctry_select(idsn, geo, time, ctrydsn, ilib=, _pop_infl_=, _run_agg_=, _pop_part_=,
				max_yback=0, sampsize=0, max_sampsize=0, thr_min=, thr_cum=,
				cds_popxctry=META_POPULATIONxCOUNTRY, cds_ctryxzone=META_COUNTRYxZONE, 
				clib=LIBCFG);
~~~

### Arguments
* `dsn` : a dataset storing the indicator for which an aggregated value is estimated;
* `geo` : list of (blank-separated) strings representing the ISO-codes of all the countries 
	that belong to a given geographical area;
* `time` : year of interest;
* `max_yback` : (_option_) look backward in time, _i.e._ consider the `max_yback` years prior to 
	the considered year; default: `max_yback=0`, _i.e._ only data available for current year shall 
	be considered; `max_yback` can also be set to `_ALL_` so as to take all available data from 
	the input dataset, whatever the year considered: in that case, all other arguments normally 
	used for building the list of countries (see below: `sampsize, max_sampsize, thr_min, thr_cum`) 
	are ignored; default: `max_yback=0` (_i.e._, only current year);
* `sampsize` : (_option_) size of the set of countries from previous year that is sequentially 
	added to the list of available countries so as to reach the desired threshold; this parameter 
	is ignored (_i.e._, set to 0) when `max_yback=_ALL_`; default: `sampsize=0`, _i.e._ all data 
	shall be added at once when available;
* `max_sampsize` : (_option_) maximum number of additional countries from previous to take into
	consideration for the estimation; default: `max_sampsize=0`;
* `thr_min` : (_option_) value (in range [0,1]) of the threshold to test whether:
		`pop_part / pop_glob >= thr_min` ? 
	default: `thr_min=0.7` (_i.e._ `pop_part` should be at least 70% of `pop_glob`); seting `thr_min=0`
	ensures `_run_agg_=yes`;
* `thr_cum` : (_option_) value (in range [0,1]) of the second threshold considered when cumulating
	the list of currently available countries with countries from previous years; this parameter is 
	set to `thr_cum=1` when `max_yback=_ALL_`, and to `thr_cum=0` and `max_yback=0`; default: not 
	set; 
* `ilib` : (_option_) input dataset library; default (not passed or ' '): `ilib=WORK`.

### Returns
* `ctrydsn` : name of the output table where the list of countries with the year of estimation is
	stored;
* `_pop_infl_` : name of the macro variables storing the 'inflation' rate between both global and
	partial population, _i.e._ the ratio pop_glob / pop_part;
* `_run_agg_` : name of the macro variables storing the result of the test whhether some aggregates
	shall be computed or not, _i.e._ the result (`yes/no`) of the test:
		`pop_part / pop_glob >= thr_min` ?
* `_pop_part_` : name of the macro variable storing the final cumulated population considered for 
	the estimation of the aggregate.

### References
1. World Bank [aggregation rules](http://data.worldbank.org/about/data-overview/methodologies).

### Example
Run macro `%%_example_aggregate_build`.

### See also
[%str_isgeo](@ref sas_str_isgeo), [%ctry_find](@ref sas_ctry_find),
[%ctry_population](@ref sas_ctry_population), [%population_compare](@ref sas_population_compare), 
[%zone_replace](@ref sas_zone_replace).
*/ /** \cond */

/* credits: grazzja */

%macro ctry_select(idsn
				, geo
				, time
				, ctrydsn 	/* Name of the table where to store the presence+year of countries */	
				, _pop_infl_=
				, _run_agg_=
				, _pop_part_=
				, max_yback=
				, ilib=
				, olib=
				, sampsize=
				, max_sampsize=
				, thr_min=
				, thr_cum=
				, cds_popxctry=
				, cds_ctryxzone=
				, clib=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local MAX_NYEARS
		ISLIBALLOC;
	%let ISLIBALLOC=NO;

	/* MAX_NYEARS: set */
	/* 2003: first EU-SILC year... */
	%let MAX_NYEARS=%eval(%sysfunc(year(%sysfunc(datepart(%sysfunc(datetime())))))-2003);  
	/* %let MAX_NYEARS=10; /* or let's still be reasonable: 10 years back is enough */

	/* GEO: this is done through the call to %zone_replace */

    /* IDSN, ILIB: check/set */
	%if "&idsn"="_ANY_" %then %do;
		%if %symexist(G_PING_PEPS01) %then 				%let idsn=&G_PING_PEPS01;
		%else 											%let idsn=PEPS01; 
		%if %symexist(G_PING_LIBCRDB) %then 			%let ilib=&G_PING_LIBCRDB;
		%else %if %symexist(G_PING_C_RDB) %then %do;
			%let ISLIBALLOC=YES;
			libname rdb "&G_PING_C_RDB";
			%let ilib=rdb;
		%end;
	%end;

	%if %macro_isblank(ilib) %then 		%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) NE 0, mac=&_mac,		
			txt=%bquote(!!! Input dataset %upcase(&idsn) not found in library %upcase(&ilib) !!!)) %then
		%goto exit;

    /* CTRYDSN, OLIB: check/set */
	%if %macro_isblank(olib) %then 		%let olib=WORK;

	/* this is done in %ctry_find already 
	%if %error_handle(WarningOutputDataset, 
			%ds_check(&ctrydsn, lib=&olib) EQ 0, mac=&_mac,		
			txt=%bquote(! Output dataset %upcase(&ctrydsn) already exists in library %upcase(&olib) !), 
			verb=warn) %then
		%goto warning;
	%warning:
	*/

	/* _POP_INFL_, _RUN_AGG_, _POP_PART_: check/set */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_pop_infl_) EQ 1 and %macro_isblank(_run_agg_) EQ 1, mac=&_mac,		
			txt=!!! Output macro variable _POP_INFL_ and _RUN_AGG_ need to be set !!!) %then 
		%goto exit;

	%if %macro_isblank(_pop_part_) %then %do;
		%local ___pop_part; /* dummy variable */
		%let _pop_part_=___pop_part;
	%end;

	/* THR_MIN: check tresholds, possibly set default values */
	%if %symexist(G_PING_AGG_POP_THRESH) %then 		%let DEF_AGG_POP_THRESH=&G_PING_AGG_POP_THRESH;
	%else 											%let DEF_AGG_POP_THRESH=0.7; /* yep... */
	%if %macro_isblank(thr_min) %then				%let thr_min=&DEF_AGG_POP_THRESH; 

	%if %error_handle(ErrorInputParameter, 
			%par_check(&thr_min, type=NUMERIC, set=0 1, range=0 1) NE 0, mac=&_mac,	
			txt=%bquote(!!! Parameter THR_MIN is a numeric value in range [0,1] !!!)) %then
		%goto exit;

	/* MAX_YBACK: check/set */
	%if %macro_isblank(max_yback) %then				%let max_yback=0;
	%else %if "&max_yback"="_ALL_" 	%then %do;
		/* we go backward in time as much as we can */ 
		%if &max_yback^=-1 %then 		%let max_yback=&MAX_NYEARS;  
		/* we take all countries available for a given year */
		%let sampsize=0; %let max_sampsize=0;
		/* we will try to reach the quorum with the closest year in time; note that in
		* fact, this is redundant with sampsize=0 */ 
		%let thr_cum=1; 
		/* we want all countries to be included in the aggregate, whatever year is considered */
		%goto skip_parameters;
	%end;

	%if %error_handle(ErrorInputParameter, 
			%par_check(&max_yback, type=NUMERIC, set=0, range=0 &MAX_NYEARS) NE 0, mac=&_mac,	
			txt=%bquote(!!! Parameter NYEAR_BACK is a numeric value in [0, &MAX_NYEARS] !!!)) %then
		%goto exit;

	/* THR_CUM: ibid */
	%if %macro_isblank(thr_cum) %then				%let thr_cum=&thr_min;

	%if %error_handle(ErrorInputParameter, 
			%par_check(&thr_cum, type=NUMERIC, set=0 1, range=0 1) NE 0, mac=&_mac,	
			txt=%bquote(!!! Parameter THR_CUM is a numeric value in range [0,1] !!!)) %then
		%goto exit;

	/* SAMPSIZE: check/set */
	%if %macro_isblank(sampsize) %then				%let sampsize=0;

	%if %error_handle(ErrorInputParameter, 
			%par_check(&sampsize, type=NUMERIC, set=0, range=0) NE 0, mac=&_mac,	
			txt=%bquote(!!! Parameter SAMPSIZE is a numeric value >=0 !!!)) %then
		%goto exit;

	/* MAX_SAMPSIZE: check/set */
	%if %macro_isblank(max_sampsize) %then			%let max_sampsize=0;

	%if %error_handle(ErrorInputParameter, 
			%par_check(&max_sampsize, type=NUMERIC, set=0, range=0) NE 0, mac=&_mac,	
			txt=%bquote(!!! Parameter MAX_SAMPSIZE is a numeric value >=0 !!!)) 
			or %error_handle(ErrorInputParameter, 
				&max_sampsize LT &sampsize, mac=&_mac,	
				txt=%bquote(!!! Parameter MAX_SAMPSIZE must be >= SAMPSIZE !!!)) %then
		%goto exit;

	%if &max_yback=0 	/* we will look at the current year only */
		%then %do;
		%let thr_cum=0; /* we force this threshold to be ignored in practice */
	%end;

	%skip_parameters:

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* local variables used in this macro */
	%local L_GEO ngeo
		ans
		ctry_glob ctry_part ctry_miss 
		__pop_glob __pop_part
		max_ctry_n n_miss n_ctry
		_ny_back time_available;

	%if %symexist(G_PING_LAB_GEO) %then 			%let L_GEO=&G_PING_LAB_GEO;
	%else											%let L_GEO=GEO;

	/* initialise the output variables */
	%let &_run_agg_=NO;
	%let &_pop_infl_=-1;

	/* test the string passed as a parameter */
	%let ngeo=%list_length(&geo);

	/* retrieve the "type": country, geographical aggregated area...or mistake */
	%str_isgeo(&geo, _ans_=ans, _geo_=geo, cds_ctryxzone=&cds_ctryxzone, clib=&clib);

	%if %error_handle(ErrorInputParameter, 
			%list_find(&ans, 0) NE, mac=&_mac,		
			txt=%bquote(!!! Non geographical area found in the GEO list !!!)) %then 
		%goto exit;
	%else %if %error_handle(WarningInputParameter, 
			&ans NE %list_ones(&ngeo, item=1), mac=&_mac,		
			txt=! Geographical zone listed in GEO - Countries are defined from it !,
			verb=warn) %then %do;
		%zone_replace(&geo, time=&time, _ctrylst_=geo, cds_ctryxzone=&cds_ctryxzone, clib=&clib);
	%end;

	/* let us make some calculation on the considered aggregated zone/area
	 * first the max number of countries we may find = number of countries in the area */
	%let max_ctry_n=%list_length(&geo);

	%if &max_ctry_n=0 %then
		/* note that &_run_agg_ and &_pop_infl_ have been set already */
		%goto break_loop_0;

	/* in the case MAX_SAMPSIZE=0, we want to include all possible countries without restriction 
	* on the number */
	%if &max_sampsize=0 %then 		%let max_sampsize=&max_ctry_n;

	/* then the total population of the area */
	%ctry_population(&geo, &time, _pop_size_=__pop_glob, cds_popxctry=&cds_popxctry, clib=&clib);
	%if %error_handle(ErrorAvailableData, 
			&__pop_glob EQ, mac=&_mac,		
			txt=!!! No data available for given years !!!) %then 
		%goto exit;

	/* initialise the index _NY_BACK on the number of years for backward search */
	%let _ny_back=0;
	
	/* initialise some useful variables: say that all countries are missing when we initate
	* the search loop */
	%let ctry_miss=&geo;
	%let n_miss=max_ctry_n;

	/* LOOP_0: start the tests through an infinite loop ... */
	%do %while (1);
		/* go backward in time */
		%let time_available=%eval(&time - &_ny_back); /* when _NY_BACK=0, we explore current year */	

		/* LOOP_1: look for the partial subset of countries among missing countries that are present
		* in DSN in TIME_AVAILABLE; possibly proceed by randomly adding countries. 
		 * store (and update) the result (together with the year) in the table CTRYDSN, where other 
		* countries tested on previous years may already be stored */
		%do %while (1);
			/* when considering the year of the calculation (case TIME_AVAILABLE=TIME), we take all 
			 * countries available, no sampled selection is performed */
			%if &time_available=&time %then 	%let s_size=0; 
			%else								%let s_size=&sampsize;
			/* as we cannot add more countries than what is still missing (case S_SIZE>N_MISS), we
			 * just reduce the size of the future sampled selection */
			%if &s_size>&n_miss %then 			%let s_size=&n_miss; 
			/* actual selection (addition) of countries through random sampling */

			/* look for the list of countries available in year TIME_AVAILABLE among the list
			* CTRY_MISS of missing countries */
			%ctry_find(&idsn, &time_available, &ctrydsn, ctrylst=&ctry_miss, sampsize=&s_size, 
				_nctry_=n_ctry, ilib=&ilib, olib=&olib);

			%if %error_handle(ErrorAvailableData, 
					%ds_check(&ctrydsn, lib=&olib) NE 0 or &n_ctry EQ 0, mac=&_mac,		
					txt=! No available country for the considered year !, verb=warn) %then 
				%goto next_loop_0;

			/* retrieve the subset of countries available from YEAR_AVAILABLE onwards as a list 
			 * derived from CTRYDSN output above.
			 * the list may indeed cumulate countries over several years ranging from TIME_AVAILABLE
			 * to TIME */
			%let ctry_part=;
			%var_to_list(&ctrydsn, &L_GEO, _varlst_=ctry_part, lib=&olib);

			/* compute the new aggregated population for the partial list of countries
		     * note: for countries that are present in , we still look at the population in TIME:
			 * for this reason, TIME appears below, and not &TIME_AVAILABLE (this is a rough
		     * estimation!) */
			%let &_pop_part_=;
			%ctry_population(&ctry_part, &time, _pop_size_=&_pop_part_, cds_popxctry=&cds_popxctry, clib=&clib);

			/* let us compare this new aggregated population with the global (desired) population and 
		 	 * procede with the test again */ 
			%if &time_available=&time %then 	%let thres=&thr_min; 
			%else								%let thres=&thr_cum; 
			/* reset to '' */
			%let &_pop_infl_=;
			%let &_run_agg_=;
			/* do the actual comparison which returns _RUN_AGG_=YES iif 1/_POP_INFL_>THRES */
			%population_compare(&__pop_glob, &&&_pop_part_, _pop_infl_=&_pop_infl_, _ans_=&_run_agg_, 
								pop_thres=&thres);
			/* this is equivalent to running:
			%let &_pop_infl_=%sysevalf(&__pop_glob / &&&_pop_part_);
			%if %sysevalf(&__pop_part >= &__pop_glob * &thres) %then 	%let&_run_agg_=yes;
			%else 														%let &_run_agg_=no;
			*/
			%let ratio = %sysevalf(1 / &&&_pop_infl_);

			/* retrieve (hence, update for the next search in the loop) the list (subset) of missing 
			 * countries as the difference of the previous missing list (set) of countries minus the
			 * partial list (subset) of available countries just calculated */
			%let ctry_miss=%list_difference(&ctry_miss, &ctry_part);

			/* decrement the number of added countries from MAX_SAMPSIZE */
			%let max_sampsize=%sysevalf(&max_sampsize - &s_size);
			/* note that for TIME_AVAILABLE=TIME, MAX_SAMPSIZE is unchanged since S_SIZE=0 */
			
			/* how many countries are still missing ? */
			%let n_miss=%list_length(&ctry_miss);

			/* Here is the test for leaving the first "while" loop */
			%if &n_miss=0 /* we selected all available countries for this year_available, we cannot
			  			     add anything anymore */
				%then %do;
				%goto break_loop_1_case1;
			%end;
			%else %if &&&_run_agg_=yes /* i.e. &&&_POP_INFL_=1: we reached the "quorum" */
				or &time_available=&time /* for the first year, we do not run any sampling selection:
										  * all countries were selected */
				%then %do;
				%goto break_loop_1_case2;
			%end;
		%end;

		/* Here is a series of test for leaving the second "while" loop */

		%break_loop_1_case1:
		/* ctry_miss=(): as the 'missing' list empty, all countries are...available! */
		%let &_run_agg_=yes;
		%let &_pop_infl_=%sysevalf(1);
		%goto break_loop_0;	

		%break_loop_1_case2:
		/* test if we reached the "quorum"... but maybe we want more! */
		/* note that &_pop_infl_ has also been updated in the previous function */
		%if &thr_min<=&thr_cum %then %do;
			%let thr_min=&thr_cum;
			%goto next_loop_0;
		%end;
		%else %do;
			%goto break_loop_0;
		%end;	

		%next_loop_0:
		/* increment the number of year to go backward in time */
		%let _ny_back=%eval(&_ny_back+1);
		%if &_ny_back>&max_yback %then %do;
			%goto break_loop_0;
		%end;
	%end;

	%break_loop_0:
	/* return the results
	data _null_;
		call symput("&_pop_infl_",&_pop_infl);
		call symput("&_run_agg_","&_run_agg");
	run; */

	%exit:
	%if ISLIBALLOC=YES %then %do;
		libname rdb clear;
	%end;
%mend ctry_select;

%macro _example_ctry_select;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	libname rdb "&G_PING_C_RDB"; /* "&eusilc/IDB_RDB_TEST/C_RDB"; */ 

	/* retrieve current and past years */
	%let date=%sysfunc(datepart(%sysfunc(datetime())));
	%let cyear=%sysfunc(year(&date));
	/* set year of operation */
	%let year=%eval(&cyear - 1);

	%let ctry_code=EU28;
	%let ctry_glob=AT BE BG CY CZ DE DK EE ES FI FR EL HU IE
					IT LT LU LV MT NL PL PT RO SE SI SK UK HR;
	%put list of EU28 countries required: &ctry_glob;

	%let idsn=LI01;

	%let tab_part=TMP&sysmacroname;

	*%global pop_infl run_agg pop_part;
	%let pop_infl=;
	%let run_agg=;
	%let pop_part=;

	%work_clean(&tab_part); /* just in case... */
	%let max_yback=0;
	%let thr_min=0.7;
	%let sampsize=0;
	%put (i) Test countries available in &year for &idsn, with MAX_YBACK=&max_yback and THR_MIN=&thr_min ...;
	%put other variables to default values;
	%put dsn=&idsn ctry_glob=&ctry_glob year=&year tab_part=&tab_part;
	%ctry_select(&idsn, &ctry_glob, &year, &tab_part, 
				_pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
				max_yback=&max_yback, thr_min=&thr_min, sampsize=&sampsize, ilib=rdb);
	%put 	result in: pop_infl=&pop_infl, pop_part=&pop_part, run_agg=&run_agg;
	%ds_print(&tab_part, title="countries available in 2016 - Tpres=&thr_min");

	%work_clean(&tab_part);
	%let max_yback=0;
	%let thr_min=0.05;
	%let sampsize=0;
	%put (ii) Test countries currently available in &year for &idsn, with MAX_YBACK=&max_yback and THR_MIN=&thr_min ...;
	%put other variables to default values;
	%ctry_select(&idsn, &ctry_glob, &cyear, &tab_part, 
				_pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
				max_yback=&max_yback, thr_min=&thr_min, sampsize=&sampsize, ilib=rdb);
	%put 	result in: pop_infl=&pop_infl, pop_part=&pop_part, run_agg=&run_agg;
	%ds_print(&tab_part, title="countries available in 2016 - T_min=&thr_min");

	%work_clean(&tab_part);
	%let max_yback=1;
	%let thr_min=0.01;
	%let thr_cum=0.7;
	%let sampsize=1;
	%put (iii) Test countries available in &year for &idsn, with MAX_YBACK=&max_yback and THR_MIN=&thr_min ...;
	%put other variables to default values;
	%ctry_select(&idsn, &ctry_glob, &year, &tab_part, 
				_pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
				max_yback=&max_yback, thr_min=&thr_min, thr_cum=&thr_cum, sampsize=&sampsize,
				ilib=rdb);
	%put 	result in: pop_infl=&pop_infl, pop_part=&pop_part, run_agg=&run_agg;
	%ds_print(&tab_part, title="countries available in 2016 and 2015 - T_min=&thr_min, Tcum=&thr_cum");

	%work_clean(&tab_part);
	%put (iv) Take all countries (available in &year or previously) in DSN=&idsn with MAX_YBACK set to _ALL_ ...;
	%ctry_select(&idsn, &ctry_glob, &year, &tab_part, 
				_pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
				max_yback=_ALL_, ilib=rdb);
	%put 	result in: pop_infl=&pop_infl, pop_part=&pop_part, run_agg=&run_agg;
	%ds_print(&tab_part, title="countries available - Take all");

	/* deallocate the library */
	libname rdb clear;
	%work_clean(&tab_part);

	%put;
%mend _example_ctry_select;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ctry_select;  
*/

/** \endcond */
