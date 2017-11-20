/**  
## silc_agg_compute {#sas_silc_agg_compute}
Legacy _"EUVALS"_-based code that calculates the EU aggregates of any indicator, whenever
data are available or not, in the "old-fashioned" way. 

~~~sas
	%silc_agg_compute(geo, time, idsn, odsn, ctrylst=,
					max_yback=0, thr_min=0.7, thr_cum=0, pdsn=CCWGH60, agg_only=yes, 
					force_Nwgh=NO, ilib=WORK, olib=WORK, plib=idb_rdb);
~~~

### Arguments
* `geo` : a given geographical area, _e.g._ EU28, EA, ...;
* `time` : year of interest;
* `idsn` : name of the dataset storing the indicator for which an aggregated value is 
	estimated over the `&geo` area and during the `&time` year;
* `ctrylst` : (_option_) list of (blank-separated, no quote) strings representing the 
	ISO-codes of all the countries supposed to belong to `&geo`; when not provided, it 
	is automatically determined from `&geo` and `&time` (see macro [%zone_to_ctry](@ref sas_zone_to_ctry));
* `max_yback` : (_option_) look backward in time, _i.e._ consider the `&max_yback` years 
	prior to the considered year; default: `max_yback=0`, _i.e._ only data available for 
	current year shall be considered; `max_yback` can also be set to `_ALL_` so as to take 
	all available data from the input dataset, whatever the year considered: in that case, 
	the other argument(s) normally used for building the list of countries (see below: 
	`thr_min`) are ignored; default: `max_yback=0` (_i.e._, only current year);
* `thr_min` : (_option_) value (in range [0,1]) of the threshold used to test whether 
	currently (_i.e._ for the year `time` under investigation):
		available population [time] / global population [time] >= `&thr_min` ? 
	default:  `thr_min=0.7`, _i.e._ the available population should be at least 70% of the 
	global population of the `geo` area; 
* `thr_cum`: (_option_) value (in range [0,1]) of the threshold used to test the cumulated 
	available population, _i.e._ whether: 
		available population [time-maxyback,time] / global population [time] >= `&thr_cum` ? 
	default:  `thr_cum=0`, _i.e._ there is no further test on the cumulated population once 
	the `thr_min` test on currently available population is passed; 
* `grpdim` : (_option_) list (blank separated, no comma) of dimensions used by the indicator; 
	if not set (default), it is retrieved automatically from the input table using 
	[%ds_contents](@ref sas_ds_contents) and considering the standard format of EU-SILC tables 
	(see also [%silc_ind_create](@ref sas_silc_ind_create));
* `agg_only` : (_option_) boolean flag (`yes/no`) set to keep in the output table the aggregate
	`geo` only; when set to `no`, then all data used for the aggregate estimation are kept in 
	the output table `odsn` (see below); default: `agg_only=yes`, _i.e._ only the aggregate 
	will be stored in `odsn`;
* `flag` : (_option_) who knows...?
* `force_Nwgh` : (_option_) additional boolean flag (`yes/no`) set when an additional
	variable `nwgh` (representing the weighted sample) is present in the output
	dataset; used in `EUvals` , where this option is not foreseen in the original `EUvals` 
	implementation; default: `force_Nwgh=no`;
* `pdsn` : (_option_) name of the dataset storing total populations per country; default: 
	`CCWGH60` (_"EUVALS"_ legacy);
* `plib` : (_option_) name of the library storing the population dataset `pdsn`; default: `plib` 
	is associated to the folder `&EUSILC/IDB_RDB` folder commonly used to store this file; 
* `ilib` : (_option_) input dataset library; default (not passed or ' '): `ilib=WORK`.

### Returns
* `odsn` : (generic) name of the output datasets; two tables are actually created: the table 
	`&odsn` will store all the calculations with the aggregated indicator; a table named 
	`CTRY_&odsn` will also store, for each country, the year of extraction of data for the 
	calculation of aggregates in year `time` will also be created; for instance for a given 
	calculated at `time=2015`, where BG data are missing till 2013, CY data till 2014, DE data 
	till 2012, ES till 2014, etc..., this table will look like:
		 geo | time
		-----|------
		  AT | 2015
		  BE | 2015
		  BG | 2013
		  CY | 2014
		  CZ | 2015
		  DE | 2012
		  DK | 2015
		  EE | 2015
		  EL | 2015
		  ES | 2014
 		  .. |  ....
		  
* `olib` : (_option_) output dataset library; default (not passed or ' '): `olib=WORK`.

### Example
Run macro `%%_example_silc_agg_compute`.

### Notes
1. The computed aggregate is not inserted into the input dataset `&idsn` but in the output `&odsn` 
dataset passed as an argument. If you want to actually update the input dataset, you will need to
explicitely call for it. For instance, say you want to calculate the 2016 EU28 aggregate of `PEPS01` 
indicator from the so-called `rdb` library:

~~~sas
	%silc_agg_compute(EU28, 2016, PEPS01, &odsn, ilib=rdb, olib=WORK);
	DATA rdb.PEPS01;
		SET rdb.PEPS01(WHERE=(not(time=2016 and geo=EU28))) 
			WORK.PEPS01; 
	run;
	%work_clean(PEPS01);
~~~
2. For that reason, the datasets `&idsn` and `&odsn` must be different!

### Reference
1. World Bank [aggregation rules](http://data.worldbank.org/about/data-overview/methodologies).

### See also
[%silc_EUvals](@ref sas_silc_euvals), [%ctry_select](@ref sas_ctry_select), 
[%zone_to_ctry](@ref sas_zone_to_ctry), [%var_to_list](@ref sas_var_to_list),
[%ds_contents](@ref sas_ds_contents).
*/ /** \cond */

/* credits: grazzja */

%macro silc_agg_compute(geo				/* Name of the geographical area considered for aggregation 		(REQ) */
						, time			/* Year of interest  												(REQ) */
						, idsn			/* Input dataset 													(REQ) */
						, odsn			/* Output dataset 													(REQ) */
						, ctrylst=		/* Input list of countries ISO-codes 								(OPT) */
						, max_yback=	/* Number of years to explore 										(OPT) */
						, thr_min=		/* Threshold on currently available population  					(OPT) */
						, thr_cum=		/* Threshold on cumulated available population  					(OPT) */
						, grpdim=		/* List of dimensions defined in the input indicator			  	(OPT) */
						, pdsn=			/* Name of the directory storing the population file 				(OPT) */
						, agg_only=		/* Boolean flag (0/1) set to keep only aggregates in the output   	(OPT) */
						, flag=			/* Dummy (?) flag								 					(OPT) */
						, mode=
						, force_Nwgh=   /* Boolean flag (0/1) set to add the variable nwgh   				(OPT) */
						, ilib=			/* Name of the input library 										(OPT) */
						, plib=			/* Name of the population library 									(OPT) */
						, olib=			/* Name of the output library 										(OPT) */
						);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local DEBUG VERBOSE 
		IDB_RDB;

	%if %macro_isblank(DEBUG) %then %do;
		%if %symexist(G_PING_DEBUG) %then 	%let DEBUG=&G_PING_DEBUG;
		%else 								%let DEBUG=0;
	%end;

	%if %macro_isblank(VERBOSE) %then %do;
		%if %symexist(G_PING_VERBOSE) %then 	%let VERBOSE=&G_PING_VERBOSE;
		%else 									%let VERBOSE=0;
	%end;

	%if %macro_isblank(IDB_RDB) %then %do;
		%if %symexist(G_PING_IDBRDB) %then 		%let IDB_RDB=&G_PING_IDBRDB;
		%else 									%let IDB_RDB=&EUSILC/IDB_RDB;
	%end;

	/* IDSN/ILIB: check */
	%if %macro_isblank(ilib) %then   	%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) NE 0, mac=&_mac,		
			txt=%quote(!!! Input dataset &idsn does not exist !!!)) %then 
		%goto exit;

	/* ODSN/OLIB: check */ 
	%if %macro_isblank(olib) %then   	%let olib=WORK;

	%if %error_handle(ErrorOutputDataset, 
		"&idsn" EQ "&odsn" and "%sysfunc(pathname(&ilib))" EQ "%sysfunc(pathname(olib))", mac=&_mac,		
			txt=%quote(!!! Input and output datasets must be different !!!)) %then 
		%goto exit;
	%else %if %error_handle(WarningOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,		
			txt=%quote(! Output dataset already exists !), verb=warn) %then 
		%goto warning1;
	%warning1:

	/* further checks */
	%local __years __ctrylst
		_i _tmp  
		ctryflagged nctrylst
		pop_infl run_agg pop_part;

	%local L_TIME L_GEO L_VALUE;
	%if %symexist(G_PING_LAB_TIME) %then 			%let L_TIME=&G_PING_LAB_TIME;
	%else											%let L_TIME=TIME;
	%if %symexist(G_PING_LAB_GEO) %then 			%let L_GEO=&G_PING_LAB_GEO;
	%else											%let L_GEO=GEO;
	%if %symexist(G_PING_LAB_VALUE) %then 			%let L_VALUE=&G_PING_LAB_VALUE;
	%else											%let L_VALUE=IVALUE;

	/* CTRYLST: set */
	%if %macro_isblank(ctrylst) %then %do;
		%let __ctrylst=;
		%zone_to_ctry(&geo, time=&time, _ctrylst_=__ctrylst);
	%end;
	%else 
		%let __ctrylst=&ctrylst;
	%let nctrylst_desired=%list_length(&__ctrylst);

	/* FORCE_NWGH: set default  */
	%if %macro_isblank(force_Nwgh) %then		%let force_Nwgh=NO; 
	%else 										%let force_Nwgh=%upcase(&force_Nwgh); 

	%if %error_handle(ErrorInputParameter, 
			%par_check(&force_Nwgh, type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong value for boolean flag FORCE_NWGH - Must be in YES or NO !!!)) %then 
		%goto exit;

	/* THR_MIN/THR_CUM: set default/check  */
	%if %macro_isblank(thr_min) %then				%let thr_min=0.7; 
	%else %if %error_handle(ErrorInputParameter, 
			%par_check(&thr_min, type=NUMERIC, range=0 1, set=0 1) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong input threshold value for THR_MIN - Must be in  [0,1] !!!)) %then 
		%goto exit;

	%if %macro_isblank(thr_cum) %then				%let thr_cum=0; 
	%else %if %error_handle(ErrorInputParameter, 
			%par_check(&thr_cum, type=NUMERIC, range=0 1, set=0 1) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong input threshold value for THR_CUM - Must be in  [0,1] !!!)) %then 
		%goto exit;

	/* MAX_YBACK: set default */
	%if %macro_isblank(max_yback) %then				%let max_yback=0;

	%if %error_handle(ErrorInputParameter, 
			"&max_yback" NE "_ALL_" and %par_check(&max_yback, type=INTEGER, range=0, set=0) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for MAX_YBACK - Must be _ALL_ or an int in  [0,inf[ !!!)) %then 
		%goto exit;

	%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
		%put;
		%put --------------------------------------------------------------------------;
		%put Considered countries:;
		%put &__ctrylst;
		%put --------------------------------------------------------------------------;
	%end;

	/* PDSN/PLIB: check/set */
	%if %macro_isblank(pdsn) %then 		%let pdsn=CCWGH60; /* default population file */
	%if %macro_isblank(plib) %then %do;
		libname _libtmp "&IDB_RDB"/*"&EUSILC/IDB_RDB"*/;
		%let plib=_libtmp;
	%end;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&pdsn, lib=&plib) NE 0, mac=&_mac,		
			txt=%quote(!!! Input population dataset &pdsn not found !!!)) %then 
		%goto exit;

	/* AGG_ONLY: set default/check  */
	%if %macro_isblank(agg_only) %then				%let agg_only=YES;
	%else 											%let agg_only=%upcase(&agg_only);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&agg_only, type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong boolean flag AGG_ONLY - Must be YES or NO !!!)) %then 
		%goto exit;

	/* MODE: set default/check  */ 
	%if %macro_isblank(mode) %then					%let mode=UPDATE;
	%else 											%let mode=%upcase(&mode);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&MODE, type=CHAR, set=INSERT UPDATE) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong flag MODE - Must be INSERT or UPDATE !!!)) %then 
		%goto exit;

	/* FLAG: set default/check  
	* hum...*/

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
		%put;
		%put --------------------------------------------------------------------------;
		%put Load input table;
		%put --------------------------------------------------------------------------;
	%end;

	/* List the countries CTRYLST that need to be retrieved for the estimation of the chosen GEO 
	* aggregate */

	%let _tmp=_TMP_INCTRY_&idsn;
	%if %ds_check(&_tmp, lib=WORK) EQ 0 %then %do;
		%work_clean(&_tmp);
	%end;

	%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
		%put;
		%put --------------------------------------------------------------------------;
		%put Retrieve all pairs (year,country) used in area &geo estimation;
		%put --------------------------------------------------------------------------;
	%end;

	%let pop_infl=;
	%let run_agg=;
	%let pop_part=;
	%ctry_select(&idsn, &__ctrylst, &time, &_tmp, max_yback=&max_yback, thr_min=&thr_min,
				_pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
				ilib=&ilib);

	/* check that the "quorum" is reached */
	%if %error_handle(ErrorInputParameter, 
			&run_agg EQ NO, mac=&_mac,		
			txt=%quote(!!! Not enough data available = no process running for this year !!!)) %then 
		%goto exit;

	%if &VERBOSE=1 or %eval(&G_PING_DEBUG>1) %then %do;
		%ds_print(&_tmp, title="List of pairs (country,year) used for &geo aggregate estimation of &idsn in year &time");
		%put;
		%put --------------------------------------------------------------------------;
		%put Total population represented in area &geo: &pop_part;
		%put Inflation rate: &pop_infl;
		%put --------------------------------------------------------------------------;
	%end;

	/* Store the pairs (country,year) into two separated lists */
	%let __years=;
	%var_to_list(&_tmp, &L_TIME, _varlst_=__years);
	%let __ctrylst=;
	%var_to_list(&_tmp, &L_GEO, _varlst_=__ctrylst);

	%let nctrylst=%list_length(&__ctrylst);
	/* note: YEARS is of same length as __CTRYLST */

	%if %error_handle(ErrorInputParameter, 
			&nctrylst NE &nctrylst_desired, mac=&_mac,		
			txt=%quote(! Not all countries available for given year !), verb=warn) %then 
		%goto warning2;
	%warning2:

	%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
		%put;
		%put --------------------------------------------------------------------------;
		%put Extract &idsn data corresponding to selected pairs (country,year);
		%put --------------------------------------------------------------------------;
	%end;

	/* extract the data of interest and already store it in the output dataset */
	PROC SQL noprint;
		CREATE TABLE &olib..&odsn AS 
		SELECT * 
		FROM &ilib..&idsn as idsn
		WHERE
			%do _i=1 %to &nctrylst;
				(idsn.&L_TIME=%scan(&__years,&_i) AND idsn.&L_GEO="%scan(&__ctrylst,&_i)")
				%if &_i<&nctrylst %then %do;
				OR
				%end;
			%end;
		;
	quit;
		
	%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
		%put;
		%put --------------------------------------------------------------------------;
		%put Reset year to reference year;
		%put --------------------------------------------------------------------------;
	%end;

	DATA &olib..&odsn;
		SET &olib..&odsn;
		&L_TIME=&time; /* set to one same year, the one we request */
	run;

	/**********************************************************************************/
	/** porcheria																	 **/

	/* how to avoid porcheria: be a smart ass, and retrieve automatically the list 
	* of main dimensions in GRPDIM from the indicator "skeleton" */
	%if %macro_isblank(grpdim) %then %do;
		%let grpdim=;
		%ds_contents(&idsn, _varlst_=grpdim, lib=&ilib);
		/* trim the columns that do not correspond to the desired dimensions:
		* - start at 2 since we get rid of (&L_GEO,&L_TIME) (in general, (GEO,TIME))
		* - keep all columns till the occurence of &L_VALUE (in general, IVALUE) in the list */ 
		%let grpdim=%list_difference(%list_slice(&grpdim, end=&L_VALUE), &L_TIME &L_GEO);
		%if %error_handle(ErrorInputParameter, 
				%macro_isblank(grpdim) EQ 1, mac=&_mac,		
				txt=%quote(!!! Too few dimension defined in &idsn beyond &L_VALUE, &L_TIME and &L_GEO !!!)) %then 
			%goto exit;
		/* or: %let grpdim=%list_quote(%list_slice(&grpdim, ibeg=3, end=&L_VALUE), mark=_EMPTY_); */
	%end;

	%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
		%put;
		%put --------------------------------------------------------------------------;
		%put Dimensions used with indicator &idsn: &grpdim;
		%put --------------------------------------------------------------------------;
	%end;

	%let grpdim=%list_quote(&grpdim, mark=_EMPTY_);

	%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
		%put;
		%put --------------------------------------------------------------------------;
		%put Run aggregate calculation...;
		%put --------------------------------------------------------------------------;
	%end;

	/* %include "&euvals_file"; */
	%silc_EUvals( &geo
				, (%list_quote(&__ctrylst))
				, mode=&mode				/* mode forced to? UPDATE in general works with both RDB and RDB2 */
				, _yyyy=&time				/* all years have been reset to TIME */
				, _tab=&odsn				/* ODSN will be updated */
				, _thres=&thr_cum 			/* that's where the THR_CUM test on cumulated population goes */
				, _flag=&flag				/* if we ever passed a flag... */
				, _not60=0					/* useless anyway */
				, _grpdim=%quote(&grpdim)	/* dimensions are passed at this stage! */
				, _rdb=&olib				/* where ODSN is located... */
				, _ccwgh60=&pdsn			/* just in case we passed a specific population file */
				, _ex_data=&plib			/* ibid above...*/
				, force_Nwgh=&force_Nwgh	/* that's for "special" indicators with a N fields */	
				);

 	/** fine della porcheria 														 **/
	/**********************************************************************************/
		
	%if &VERBOSE=1 or %eval(&DEBUG>1) %then %do;
		%put;
		%put --------------------------------------------------------------------------;
		%put Set "e" flag to countries that are not available in current year...;
		%put --------------------------------------------------------------------------;
	%end;

	%let ctryflagged=;
	PROC SQL noprint;
		SELECT DISTINCT QUOTE(TRIM(&L_GEO)) 
		INTO: ctryflagged separated by ',' 
		FROM &_tmp
		WHERE &L_TIME NE &time;
	quit;

	%if %macro_isblank(ctryflagged) %then %goto quit;

	DATA &olib..&odsn;
		SET &olib..&odsn;
		if &L_GEO in (&ctryflagged.) then iflag='e';
		/* if we are here, for sure the aggregate is also an estimate since at least one country
		* comes from previous years */
		else if &L_GEO="&geo" then iflag='e';
	run;

	%quit:
	
	/* further filter... */
	%if "&agg_only" = "YES" %then %do;
		DATA &olib..&odsn;
			SET &olib..&odsn(WHERE=(time=&time and geo="&geo"));
		run;
	%end;

	/* save the list of paris (country,year) used for calculation... */
	DATA &olib..ctry_&odsn._&time /*&olib..ctry_&odsn*/;
		RETAIN geo time; /* reorder */
		SET &_tmp;
	run;

	/* clean your shit... */
	%work_clean(&_tmp); 
	%if %sysfunc(libref(_libtmp)) EQ 0 %then %do;
		libname _libtmp clear;
	%end;

	%exit:
%mend silc_agg_compute;

%macro _example_silc_agg_compute;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local ivalue ovalue 
		max_yback;

	/* we currently launch this example in the highest level (1) of DEBUG only */
	%if %symexist(G_PING_DEBUG) %then 	%let oldDEBUG=&G_PING_DEBUG;
	%else %do;
		%global G_PING_DEBUG;
		%let oldDEBUG=0;
	%end;
	%let G_PING_DEBUG=2;

	DATA dumb;
		geo="AT  "; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="&sysdate"; lastuser="&sysuserid"; output;
		geo="BE"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output; 
		geo="BG"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="CY"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="CZ"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="DE"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="DK"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="EE"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="ES"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="FI"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="FR"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="EL"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="HU"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="IE"; time=2016; unit="PC"; ivalue=588;  flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="IT"; time=2015; unit="PC"; ivalue=1176; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="LT"; time=2015; unit="PC"; ivalue=1176; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="LU"; time=2015; unit="PC"; ivalue=1176; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="LV"; time=2015; unit="PC"; ivalue=1176; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="MT"; time=2015; unit="PC"; ivalue=1176; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="NL"; time=2015; unit="PC"; ivalue=1176; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="PL"; time=2015; unit="PC"; ivalue=1176; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="PT"; time=2014; unit="PC"; ivalue=2352; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="RO"; time=2014; unit="PC"; ivalue=2352; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="SE"; time=2014; unit="PC"; ivalue=2352; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="SI"; time=2014; unit="PC"; ivalue=2352; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="SK"; time=2014; unit="PC"; ivalue=2352; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="UK"; time=2014; unit="PC"; ivalue=2352; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
		geo="HR"; time=2014; unit="PC"; ivalue=2352; flag=""; unrel=0; n=1; ntot=1; totwgh=1; lastup="dumb"; lastuser="dumber"; output;
	run;

	DATA dumb_nwgh;
		SET dumb;
		nwgh=1; /* also check the case the variable NWGH exists in the table */ 
	run;

	%put;
	%let ovalue=%sysevalf((588*14 + 1176*7 + 2352*7) / (14+7+7)); /* 1176 */
	%put (i) Test a simple case by retrieving all available data to the latest year (MAX_YBACK=10);
	%silc_agg_compute(EU28, 2016, dumb, dumber, max_yback=_ALL_); 
	/* %obs_select(dumber, dumber, where=%quote(geo="EU28")); */
	%var_to_list(dumber, IVALUE, _varlst_=ivalue, where=%quote(geo="EU28"));
	%if %eval(&ivalue=&ovalue) %then 			
		%put OK: TEST PASSED - EU28 value computed over dataset is &ovalue;
	%else 						
		%put ERROR: TEST FAILED - EU28 computed value is &ivalue;

	%put;
	%let max_yback=1;
	%let ovalue=%sysevalf((588*14 + 1176*7) / (14+7)); /* 784 */ 
	%put (ii) Perform the same test by retrieving also data available in the last &max_yback year(s);
	%silc_agg_compute(EU28, 2016, dumb_nwgh, dumber_nwgh, max_yback=&max_yback); 
	%var_to_list(dumber_nwgh, IVALUE, _varlst_=ivalue, where=%quote(geo="EU28"));
	%if %eval(&ivalue=&ovalue) %then 			
		%put OK: TEST PASSED - EU28 value computed over dataset is &ovalue;
	%else 						
		%put ERROR: TEST FAILED - EU28 computed value is &ivalue;
	
	/* reset the DEBUG as it was (if it ever was set) */
	%let G_PING_DEBUG=&oldDEBUG;

	/* %work_clean(dumb, dumber, dumb_nwgh, dumber_nwgh); */
%mend _example_silc_agg_compute;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silc_agg_compute;
*/

/** \endcond */

