/** 
## silc_EUvals {#sas_silc_euvals}
Legacy "EUVALS" code that calculates the EU aggregates of either RDB or RDB2 indicators
in the "old-fashioned" way. 

~~~sas
	%silc_EUvals(eu, ms, _idb=, _yyyy=, _tab=, _thres=, _grpdim=, _flag=, _not60=, 
				_rdb=, _ex_data=, force_Nwgh=no);
~~~

### Arguments
* `eu` : ISO-code of the aggregate area (_e.g._, `EU28`);
* `ms` : list of country(ies) ISO-codes corresponding to (_i.e._, included in)  the 
	`eu` area;
* `mode` : flag (char) setting the mode of data output; it can be `UPDATE` (_e.g., for
	primary RDB indicators) or `INSERT` (for a secondary RDB2 indicators);
* `_yyyy` : year of interest;
* `_tab` : name of the input indicator (and the corresponding table as well);
* `_thres` : threshold (in range [0,1]) used to compare ratio of available population
	over the total area population; 
* `_grpdim` : list of dimension used by the indicator `_tab`;
* `_flag` : boolean flag (0/1) for...?  
* `_rdb`: name of the library where the indicator table `_tab` is located, _e.g._ 
	`_rdb=rdb` with primary indicators or `_rdb=WORK` with secondary indicators;
* `_ccwgh60`: name of the file storing countries' population;
* `_not60` : boolean flag (0/1) used to force the aggregate calculation;
* `_ex_data`: name of the library where the file `_ccwgh60` with countries' population 
	is stored;
* `force_Nwgh` : additional boolean flag (`yes/no`) set when an additional variable 
	`nwgh` (representing the weighted sample) is present in the output dataset; note that 
	this option is not foreseen in the original `EUvals` implementation; default: 
	`force_Nwgh=no`.

### Notes
1. In addition to the macro defined above, this file provides additional macros/scripts so 
as to be compatible with the current different uses of the so-called "EUvals" programs in 
EU-SILC production. Actually, the aggregate estimation is run at the "inclusion" of this file,
that is whenever the following command is used inside a SAS program:
~~~sas
		%include "<path_to_this_file>/silc_euvals.sas" 
~~~
The operation performed after the inclusion depends however on the type of indicator to be 
calculated, _i.e._ on whether:
	+ indicators in the so-called RDB2 database are processed: an `%%_EUVALS` macro is launched 
	so that aggregates are actually calculated,
	+ indicators in the so-called RDB database are processed: NOTHING happens (exit the program),
	+ the program is used together with the `PING` library: NOTHING happens either (exit the 
	program).

    In the two latter cases, the inclusion shall therfore be understood as a strict inclusion, with no 
actual operation running.
2. The macro `%%silc_EUvals` does not require the use of `PING` library.
3. The "weird" naming of this macro's parameters derives from the global parameters used in 
legacy `%%EUvals` program. 

### See also
[%silc_agg_compute](@ref sas_silc_agg_compute).
*/ /** \cond */

/* credits: grazzja, grillma */

%macro silc_EUvals(eu				/* ISO-code of a geographical area 					(REQ) */
					, ms			/* ISO-codes of country part of the EU area 		(REQ) */
					, mode=			/* Flag setting the mode of data output		 		(REQ) */
					, _yyyy=		/* Survey year of interest 							(REQ) */
					, _tab=			/* input indicator name								(REQ) */
					, _thres=		/* Population threshold								(REQ) */
					, _flag=		/* Dummy (?) flag								 	(REQ) */
					, _grpdim=		/* List of dimensions used by the indicator 		(REQ) */
					, _not60=		/* Flag for RDB2 indicators 						(REQ) */
					, _ccwgh60=		/* Name of the population dataset  					(REQ) */
					, _rdb=			/* Name of the library with the input indicator 	(REQ) */
					, _ex_data=		/* Name of the library with the population file 	(REQ) */
					, force_Nwgh=NO	/* Boolean flag used to add a NWGH variable 		(REQ) */
					); /* dirty stand-alone generic EUVALS */
	%local _mac;
	%let _mac=&sysmacroname;
  
	/************************************************************************************/
	/**                         some useful macro declaration                          **/
	/************************************************************************************/

	%macro _work_clean/parmbuff;
		%local ds num;
		%let num=1;	%let ds=%scan(&syspbuff,&num);
	   	%do %while(&ds ne);
			PROC DATASETS lib=WORK nolist; 
				delete &ds;  
			quit;
	   		%let num=%eval(&num+1);	%let ds=%scan(&syspbuff,&num);
	   	%end;
	%mend _work_clean;

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* make our life easier when testing this char variable */
	%let mode=%upcase(&mode);
	%let _tab=%upcase(&_tab);

	%if not %sysfunc(exist(&_rdb..&_tab, data)) %then %do;  
		%put !!! Input dataset &_rdb..&_tab does not exist - Exiting &_mac !!!;
		%goto exit;
	%end;

	%local euok
		infl
		flageu
		exists_Nwgh;
	%let exists_Nwgh=0;

	/* debug/verbose mode... */
	%put Input parameters:;   
	%put *  area (eu): &eu;
	%put *  list of countries (ms): &ms;
	%put *  indicator (tab): &_tab;
	%put *  survey year (yyyy): &_yyyy;
	%put *  population treshold (thres): &_thres;
	%put *  dimensions (grpdim): &_grpdim;
	%put *  flag: &_flag;
	%put *  not60: &_not60;
	%put --------------------------------------------------------------------------;
	%put;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	PROC SQL noprint;
		CREATE TABLE work._normsize AS 
		SELECT DISTINCT 		
			sum(Y&_yyyy) AS norm_size 
		FROM &_ex_data..&_ccwgh60 
		WHERE DB020 in &ms;

		/*select list of countries present in the indicator for the year &_YYYY */ 
		CREATE TABLE WORK._ctry_present AS
		SELECT DISTINCT 
			tab.geo
		FROM &_rdb..&_tab AS tab
		WHERE time = &_yyyy AND geo in &ms;

		SELECT DISTINCT count(geo) AS N INTO :nobs 
		FROM WORK._ctry_present;

		/* calculate the real size of the pop for the year &_YYYY in the indicator &_TAB 
		* for the aggregate &MS taking into account available countries */

		CREATE TABLE WORK._realsize AS 
		SELECT DISTINCT 		
			sum(Y&_yyyy) AS real_size 
		FROM &_ex_data..&_ccwgh60 AS ccwgh60 
		INNER JOIN _ctry_present AS ctry_present 	
		ON (ccwgh60.DB020= ctry_present.geo) 
		WHERE ctry_present.geo in &ms;

		SELECT real_size INTO: real_size 	
		FROM WORK._realsize;

		CREATE TABLE work._weu AS 
		SELECT DISTINCT 		
			norm_size, 
			real_size,
			(norm_size * &_thres) AS size60, /* legacy name... */
			(norm_size / real_size) AS infl,
			(CASE  WHEN real_size < CALCULATED size60 THEN 0  
				ELSE 1 
				END) AS euok
		FROM WORK._realsize, WORK._normsize;

		SELECT euok INTO :euok 
		FROM WORK._weu;

		SELECT infl INTO :infl 
		FROM WORK._weu;
	quit;

	%_work_clean(_weu, _normsize, _realsize, _ctry_present);

	%let flageu=;
	/* when present, NOT60 basically overwrites the flag EUOK 
	* it should only prevent the aggregates calculation, instead it forces it: anyway... */
	%if &_not60 %then %let euok=&_not60;

	/* test whether to go further or not */
	%if &euok EQ 0 or &_yyyy LE 2004 %then 		%goto exit;

	/* take the normal number of country in the aggregate */
	%let neu=%substr(&eu,%eval(%length(&eu)-1),2); /* e.g., returns neu=27 from eu=EU27 */

	 /* put flag s if some countries are missing*/
	%if "&neu" NE "EU" and &nobs NE &neu %then 		%let flageu=s;

	/* put flag s as BG RO are fake data */
	%if (&eu=EU27 AND &_yyyy<2007) %then 			%let flageu=s;
	
	/* insert test for indicators required only for currency=EUR */
	PROC SQL;
		CREATE TABLE euval1 AS 
		SELECT 
			&_tab..*, 
			ccwgh60.Y&_yyyy,
	 		/* note: we use foreign then definition of WUNREL then one provided in RDB2 */
			(CASE when unrel in(1,2) then (unrel * Y&_yyyy)
		 		ELSE 0 END) AS wunrel
		FROM &_rdb..&_tab
		LEFT JOIN &_ex_data..&_ccwgh60 AS ccwgh60
		ON (&_tab..geo = ccwgh60.DB020)
	 	%if "&_tab"="DI10" or "&_tab"="DI02" %then %do;
			WHERE geo in &ms and time = &_yyyy and currency in ('EUR');
		%end;
		%if "&_tab"="DI03" or "&_tab"="DI04" or "&_tab"="DI05" or "&_tab"="DI07" or "&_tab"="DI08" or "&_tab"="DI09" 
				or "&_tab"="DI13" or "&_tab"="DI14" or  "&_tab"="DI13b" or  "&_tab"="DI14b" %then %do;
			WHERE geo in &ms and time = &_yyyy and unit in ('EUR');
		%end;
		%else %do;
			WHERE geo in &ms and time = &_yyyy ;
		%end;
	quit;

	%let _dsid=%sysfunc(open(&_rdb..&_tab));
	%let exists_Nwgh=%sysfunc(varnum(&_dsid, NWGH));
	%let _rc=%sysfunc(close(&_dsid));

	/* careful: when RDB and WORK coincide, with the UPDATE mode below, we may 
	* actually be overwriting the output table: let us avoid it by introducing
	* a new variable name so as to actually CREATE a table that does not already
	* exist */
	%local __tab;
	/* we are careful and test whether the libraries WORK and _RDB coincide */
	%if "&mode" EQ "UPDATE" 
			and "%sysfunc(pathname(&_rdb))" EQ "%sysfunc(pathname(WORK))" %then 
		%let __tab=_&_tab;
	%else
		%let __tab=&_tab;

	/* run the calculations */
	PROC SQL noprint;
		CREATE TABLE WORK.euval AS 
		SELECT DISTINCT 
	 		&_grpdim,
			%if /* "&mode"="UPDATE" */ %sysfunc(findw(%quote(&_grpdim), unit)) NE 0
					or "&_tab"="LI43" or "&_tab"="LVHL23" or "&_tab"="MDDD23" or "&_tab"="PEPS13" %then %do;
				(CASE WHEN unit in ("THS_PER", "THS_CD08") THEN ivalue
					ELSE (ivalue * totwgh ) END) AS wivalue,
				SUM(totwgh) AS SUM_OF_totwgh,
				(SUM(CALCULATED wivalue)) AS SUM_OF_wivalue,
				(CASE WHEN unit in ("THS_PER", "THS_CD08") THEN ( CALCULATED SUM_of_wivalue * &infl)
					ELSE (CALCULATED SUM_OF_wivalue / CALCULATED SUM_OF_totwgh ) 
					END) AS euvalue,
			%end;
	        %else %do;
				(ivalue * totwgh ) AS wivalue,
				SUM(totwgh) as SUM_OF_totwgh,
				(SUM(CALCULATED wivalue)) AS SUM_OF_wivalue,
				(CALCULATED SUM_OF_wivalue / CALCULATED SUM_OF_totwgh ) AS euvalue,
			%end;
			SUM(n) AS SUM_OF_n,
			%if &exists_Nwgh GT 0 or "&force_Nwgh" EQ "YES" %then %do;
				SUM(nwgh) AS SUM_OF_nwgh, /* note: this is not used in original EUvals */
			%end;
			SUM(ntot) AS SUM_OF_ntot,
			(CASE WHEN (sum(wunrel)/(&real_size)) > 0.6 THEN 2
		  		WHEN (sum(wunrel)/(&real_size)) > 0.3 THEN 1
		 	 	WHEN (sum(wunrel)) ne 0 THEN 3
		 		ELSE 
					(CASE WHEN "&flageu" = "s" THEN 3 /* 4 in RDB2 ??? */
						ELSE 0 END)
				END) AS euunrel
		FROM WORK.euval1
		/*WHERE geo in &ms and time = &_yyyy */
		GROUP BY &_grpdim;

		%if "&mode" EQ "UPDATE" %then %do;
			CREATE TABLE WORK.&__tab AS
		%end;
		%else %if "&mode" EQ "INSERT" %then %do;
			INSERT INTO WORK.&__tab
		%end;
		SELECT DISTINCT 
			"&eu" 			AS geo /*FORMAT=$4. LENGTH=4*/,										
			&_yyyy 			AS time,																	
			&_grpdim,																	
			/* from now: the "unit" variable should be passed as a menber in _GRPDIM
			* if _GRPDIM is retrieved using %ds_contents, everything should go smoothly
			* since only what is needed is added											
				%if "&mode"="UPDATE" and %sysfunc(findw(%quote(&_grpdim), unit)) EQ 0 %then %do;
				* note the FINDW test: this way, we avoid the common warning:;
					WARNING: Variable unit already exists on file ????;
				unit,
			%end;*/
			euvalue 		AS ivalue,
			"&_flag" 		AS iflag FORMAT=$3. LENGTH=3,
			euunrel 		AS unrel,
			SUM_OF_n 		AS n,
			%if &exists_Nwgh GT 0 or "&force_Nwgh" EQ "YES" %then %do;
				SUM_OF_nwgh AS nwgh,
			%end;
			SUM_OF_ntot 	AS ntot,
			SUM_OF_totwgh 	AS totwgh,
			"&sysdate" 		AS lastup,
			"&sysuserid" 	AS	lastuser 
		FROM WORK.euval; 
	quit;

	%if "&mode" EQ "UPDATE" %then %do;
		/* update input RDB */
		DATA &_rdb..&_tab;
			SET &_rdb..&_tab(WHERE=(not(time=&_yyyy and geo="&eu")))
				WORK.&__tab; 
		run;
		%_work_clean(&__tab); 
	%end;

	%_work_clean(euval, euval1);

	%exit:
%mend silc_EUvals;


/** Backward compatibility - The macros/scripts below are declared/run when the current
* file is "included" into a SAS program using the command:
*		%include "<path_to_this_file>/silc_euvals.sas" 
* They have been defined/set so as to be compatible with the current different uses of
* the so-called "EUvals" programs in production. 
**/

/* 
## EUVALS 
Aggregation macro used for RDB indicators' estimation 
This is nothing else than a macro wrapper in that case */
%macro EUVALS /parmbuff; 
	/* check for the existence of the parameters that are used in this program but
	* are defined outside (e.g., global variables and libraries) */
	%if %symexist(yyyy) EQ 0 or %symexist(tab) EQ 0 or %symexist(flag) EQ 0 or %symexist(grpdim) EQ 0 %then %do; 
		%put !!! Global variables YYYY, GRPDIM, FLAG and TAB need to be set - Exiting &_mac !!!;
		%goto exit;
	%end;
	%else %if %sysfunc(libref(rdb)) NE 0 or %sysfunc(libref(ex_data)) NE 0 %then %do; 
		%put !!! Libraries RDB and EX_DATA need to be defined - Exiting &_mac !!!;
		%goto exit;
	%end;	
	/* at this stage, RDB and TAB are defined */
	%if not %sysfunc(exist(rdb.&tab, data)) %then %do;  
		%put !!! Input dataset rdb.&tab does not exist - Exiting &_mac !!!;
		%goto exit;
	%end;
	%else %if not %sysfunc(exist(ex_data.ccwgh60, data)) %then %do;  
		%put !!! Input population file ex_data.ccwgh60 not found - Exiting &_mac !!!;
		%goto exit;
	%end;

	%put;
	%put --------------------------------------------------------------------------;
	%put ! &_mac: Aggregate calculated from dataset &tab in rdb library !;

	%local args globargs;

	/* retrieve the original arguments: actually, that is (EU,MS) */
	%let args=%substr(&syspbuff,2,%eval(%length(&syspbuff)-2)); /* get rid of the parentheses */

	/* retrieve the list of global arguments defined outside this file */
	%let globargs=_yyyy=&yyyy
				, mode=UPDATE
				, _tab=&tab
				, _thres=0.7
				, _flag=&flag
				, _grpdim=%quote(&grpdim)
				, _not60=0
				, _rdb=rdb
				, _ccwgh60=ccwgh60
				, _ex_data=&ex_data;

	/* run the aggregate macro by passing both  global parameters as well */
	%silc_EUvals(&args, &globargs);

	%exit:
%mend EUVALS; 

/* 
## _EUVALS 
Aggregation macro used for RDB2 indicators' estimation 
This actually runs the aggregate estimation */
%macro _EUVALS /parmbuff; /* dummy parameters */
	/* check for the existence of the parameters that are used in this program but
	* are defined outside (e.g., global variables and libraries) */
	%if %symexist(yyyy) EQ 0 or %symexist(tab) EQ 0 or %symexist(grpdim) EQ 0 %then %do; 
		%put !!! Global variables YYYY, GRPDIM and TAB need to be set - Exiting &_mac !!!;
		%goto exit;
	%end;
	%else %if %sysfunc(libref(ex_data)) NE 0 %then %do; 
		%put !!! Library EX_DATA needs to be defined - Exiting &_mac !!!;
		%goto exit;
	%end;	
	/* at this stage, TAB is defined */
	%if not %sysfunc(exist(WORK.&tab, data)) %then %do;  
		%put !!! Input dataset WORK.&tab does not exist - Exiting &_mac !!!;
		%goto exit;
	%end;
	%else %if not %sysfunc(exist(ex_data.ccwgh60, data)) %then %do;  
		%put !!! Input population file ex_data.ccwgh60 not found - Exiting &_mac !!!;
		%goto exit;
	%end;

	/* macro used for "quoting" list of ISO-codes */
	%macro _list_quote(list);
		("%sysfunc(tranwrd(%sysfunc(compbl(&list)), %quote( ), %quote("%quote(,)")))")
	%mend;

	/* macro used to copy the data from one existing (i.e. already calculated) geographical 
	* area into another area so as to avoid recalculating twice the same thing */
	%macro _geo2geo(igeo, ogeo); 
		PROC SQL noprint;
			CREATE TABLE _TMP_&ogeo AS
			SELECT /*DISTINCT*/ 
				"&ogeo" AS geo,
				time,
				&grpdim,
				ivalue, iflag, unrel,
				n, ntot, totwgh,
				lastup, lastuser 
			FROM WORK.&tab
			WHERE geo="&igeo" and time=&yyyy;

			INSERT INTO WORK.&tab
			SELECT 
				*
			FROM _TMP_&ogeo;
		quit;

		PROC DATASETS lib=WORK nolist; /*%work_clean(_TMP_&ogeo);*/
			delete _TMP_&ogeo;  
		quit;
	%mend geo2geo;

	%local __i areas EU15 EU25 EU27 EU28
		EA12 EA13 EA15 EA16 EA17 EA18 EA19
		globargs;

	%let EU15=	AT BE DE DK ES FI FR EL IE IT LU NL PT SE UK;
	%let EU25=	AT BE CY CZ DE DK EE ES FI FR EL HU IE IT LT LU LV MT NL PL PT SE SI SK UK;
	%let EU27=	AT BE BG CY CZ DE DK EE ES FI FR EL HU IE IT LT LU LV MT NL PL PT RO SE SI SK UK;
	%let EU28=	AT BE BG CY CZ DE DK EE ES FI FR EL HU IE IT LT LU LV MT NL PL PT RO SE SI SK UK HR;

	%let EA12=	AT BE DE ES FI FR EL IE IT LU NL PT;
	%let EA13=	AT BE DE ES FI FR EL IE IT LU NL PT SI;
	%let EA15=	AT BE CY DE ES FI FR EL IE IT LU MT NL PT SI;
	%let EA16=  AT BE CY DE ES FI FR EL IE IT LU MT NL PT SI SK;
	%let EA17= 	AT BE CY DE EE ES FI FR EL IE IT LU MT NL PT SI SK;
	%let EA18=	AT BE CY DE EE ES FI FR EL IE IT LU LV MT NL PT SI SK;
	%let EA19=	AT BE CY DE EE ES FI FR EL IE IT LU LT LV MT NL PT SI SK;

	%let globargs=_yyyy=&yyyy
				, mode=INSERT
				, _tab=&tab
				, _thres=0.7
				, _flag=&flag
				, _grpdim=%quote(&grpdim)
				, _not60=&not60
				, _ccwgh60=ccwgh60
				, _rdb=WORK
				, _ex_data=&ex_data;

	%put;
	%put --------------------------------------------------------------------------;
	%put ! &_mac: Aggregate calculated from dataset &tab in WORKing library !;

	/* build the "quoted" list of countries' ISO-codes */
	%let areas=EU15 EU25 EU27 EU28 EA12 EA13 EA15 EA16 EA17 EA18 EA19;
	%do __i=1 %to %sysfunc(countw(&areas));
		%let area=%scan(&areas, &__i);
		%let &area = %_list_quote(&&&area); 
	%end;

	/* run the calculations */

	/* EA18/EA19: period [2005, ????] */
	%if &yyyy >= 2005 /* and &yyyy<= ???? */ %then %do;
		%silc_EUvals(EA18, 		&EA18, &globargs);
		%silc_EUvals(EA19, 		&EA19, &globargs);
	%end;

	/* EU27: period [2007, ????] */
	%if &yyyy >= 2007 /* and &yyyy<= ???? */ %then %do;
		%silc_EUvals(EU27,		&EU27, &globargs);
	%end;

	/* EU28: period [2010, ????] */
	%if &yyyy >= 2010 /* and &yyyy<= ???? */ %then %do;
		%silc_EUvals(EU28,		&EU28, &globargs);
	%end;

	/* EA: period ]-inf, ????] */
	%if &yyyy <= 2006 %then %do;
		%silc_EUvals(EA, 		&EA12, &globargs); 
	%end;
	%else %if &yyyy = 2007 %then %do;	
		%silc_EUvals(EA,		&EA13, &globargs);
	%end;
	%else %if &yyyy = 2008 %then %do;	
		%silc_EUvals(EA,		&EA15, &globargs);
	%end;
	%else %if &yyyy <= 2010 %then %do;
		%silc_EUvals(EA,		&EA16, &globargs);
	%end;
	%else %if &yyyy < 2014  %then %do;
		%silc_EUvals(EA,		&EA17, &globargs);
	%end;
	%else %if &yyyy = 2014  %then %do;
		%_geo2geo(EA18, EA); /* instead of recalculating:	%silc_EUvals(EA,	&EA18, &globargs); */
	%end;
	%else /* %if &yyyy <= ???? %then */ %do;
		%_geo2geo(EA19, EA); /* instead of recalculating:	%silc_EUvals(EA,	&EA19, &globargs); */
	%end;

	/* EU: period ]-inf, ????] */
	%if &yyyy < 2004 %then %do;
		%silc_EUvals(EU, 		&EU15, &globargs); 
	%end;
	%else %if &yyyy = 2004 %then %do;
		%silc_EUvals(EU, 		&EU25, &globargs);
	%end;
	%else %if &yyyy <= 2006 %then %do;
		%silc_EUvals(EU, 		&EU25, &globargs);
	%end;
	%else %if &yyyy <= 2009 %then %do;	
		%_geo2geo(EU27, EU); /* instead of recalculating:	%silc_EUvals(EU,	&EU27, &globargs); */
	%end;
	%else /* %if &yyyy <= ???? %then */ %do;
		%_geo2geo(EU28, EU); /* instead of recalculating:	%silc_EUvals(EU,	&EU28, &globargs); */
	%end;

	%exit:
%mend _EUVALS;

/*
## _EUVALS_include 
Aggregate macro launch at inclusion of this file 
This macro will run whenever this file is included into a program. However, the operation
performed after the inclusion depends on whether:
	- indicators in the RDB2 database are processed: %_EUVALS above is launched so that
	aggregates are actually calculated,
	- indicators in the RDB database are processed: NOTHING happens (exit the program),
	- the program is used together with the PING library: NOTHING happens (exit the program).
Therefore in the two latter cases, the inclusion shall be understood as a strict inclusion,
with no actual operation running.
We further introduce a variable G_RUN_EUVALS that can prevents the calculation of the 
aggregates when including this file by forcing its value to 0/NO.
*/
%macro _EUVALS_include;
	/* first check that we are into some RDB-like environment... if not, it does not make 
	* sense to try to go any further */
	%if %symexist(yyyy) EQ 0 
			or %symexist(tab) EQ 0 
			or %symexist(flag) EQ 0 
			or %symexist(grpdim) EQ 0 	
			or %sysfunc(libref(ex_data)) NE 0 %then
		%goto exit;

	/* then, check if the variable G_RUN_EUVALS exists and, in that case, whether it has been
	* set to prevent the running of EUVALS */
	%if %symexist(G_RUN_EUVALS) EQ 1 %then %do;
		%if "&G_RUN_EUVALS"="NO" or "&G_RUN_EUVALS"="0" %then %goto exit;
	%end;

	/* last, check whether we are processing RDB indicators or we are running with PING */ 
	%if %symexist(G_PING_ROOTPATH) EQ 1 
			or %symexist(G_PING_SETUPPATH) EQ 1 
			/* !!! note again that the testing below is BORDERLINE... better set G_RUN_EUVALS above !!! */
			or %symexist(not60) EQ 0
			or %sysfunc(exist(WORK.&tab, data)) EQ 0 %then
		%goto exit;

	/* if you reach that point, %_EUVALS is launched */
	%_EUVALS;

	%exit:
%mend _EUVALS_include;
%_EUVALS_include; /* run the macro above: something may happen...or not */

/** \endcond */

