/** \cond */

/*
%MACRO EUVALS(eu, ms); /* legacy 
	%if %symexist(EUSILC) %then 	%let SETUP_PATH=&EUSILC;
	%else 		%let SETUP_PATH=/ec/prod/server/sas/0eusilc; 
	%include "&SETUP_PATH/library/autoexec/_setup_.sas";
	%include "&SETUP_PATH/Estimation/pgm/ctry_define.sas";
	%include "&SETUP_PATH/Estimation/pgm/ctry_select.sas";
	%include "&SETUP_PATH/Estimation/pgm/ctry_population.sas";
	%include "&SETUP_PATH/Estimation/pgm/population_compare.sas";
	%include "&SETUP_PATH/Estimation/pgm/zone_build.sas";
	%include "&SETUP_PATH/Estimation/pgm/zone_weight.sas";
	%include "&SETUP_PATH/Estimation/pgm/zone_compute.sas";

	%aggregate(&tab, &eu, &yyyy, &tab, grpdim=&grpdim, ctry_glob=&ms, flag=&flag, 
			   pop_file=' ', take_all=no, nyear_back=0, sampsize=0, max_sampsize=0, 
	     	   thres_presence=, thres_reach=' ', lib=rdb);

				
%mend EUVALS; 
*/

%macro EUVALS(eu
			, ms
			); /* dirty generic EUVALS */
	%local _mac;
	%let _mac=&sysmacroname;

	/* check for the existence of the parameters that are used in this program but
	* are defined outside (e.g., global variables and libraries) */
	%if %symexist(yyyy) EQ 0 or %symexist(tab) EQ 0 or %symexist(flag) EQ 0 or %symexist(grpdim) EQ 0 %then %do; 
		%put !!! Global variables YYYY, GRPDIM, FLAG and TAB need to be set - Exiting &_mac !!!;
		%goto exit;
	%end;
	%else %if %sysfunc(libref(ex_data)) NE 0 or %sysfunc(libref(rdb)) NE 0 %then %do; 
		%put !!! Libraries EX_DATA and RDB need to be defined - Exiting &_mac !!!;
		%goto exit;
	%end;

	/* make our life easier when testing this char variable */
	%let tab=%upcase(&tab);

	%local ilib
		euok
		infl
		flageu;

	/* define the input library : this is a borderline testing, based on the 
	* prior existence of not60... */
	%if %symexist(not60) EQ 1 and %sysfunc(exist(WORK.&tab, data)) %then %do;
		%put;
		%put --------------------------------------------------------------------------;
		%put ! &_mac: Aggregate calculated from dataset &tab in WORKing library !;
		%let ilib=WORK;
	%end;
	%else %if %sysfunc(exist(rdb.&tab, data)) %then %do;  /* not60 not used for RDB */
		%put;
		%put --------------------------------------------------------------------------;
		%put ! &_mac: Aggregate calculated from dataset &tab in rdb library !;
		%let ilib=rdb;
		%let not60=0;
	%end;
	%else %do;
		%put !!! Dataset %upcase(&tab) not found WORK/RDB !!!;
		%goto exit;
	%end;

	/* verbose mode... */
	%put Input parameters:;   
	%put *  eu=&eu;
	%put *  ms=&ms;
	%put Global parameters:;     
	%put *  yyyy=&yyyy;
	%put *  grpdim=&grpdim;
	%put *  flag=&flag;
	%put *  not60=&not60;
	%put --------------------------------------------------------------------------;
	%put;

	PROC SQL noprint;
		CREATE TABLE work.normsize AS 
		SELECT DISTINCT 		
			sum(Y&yyyy) AS norm_size 
		FROM ex_data.ccwgh60 
		WHERE DB020 in &ms;

		/*select list of countries present in the indicator for the year &yyyy */ 
		CREATE TABLE WORK.ctry_present AS
		SELECT DISTINCT 
			&tab..geo
		FROM &ilib..&tab AS &tab
		WHERE time = &yyyy AND &tab..geo in &ms;

		SELECT DISTINCT count(geo) AS N INTO :nobs 
		FROM WORK.ctry_present;

		/* calculate the real size of the pop for the year &yyyy in the indicator &tab 
		* for the aggregate &ms taking into account available countries*/

		CREATE TABLE work.realsize AS 
		SELECT DISTINCT 		
			sum(Y&yyyy) AS real_size 
		FROM ex_data.CCWGH60 AS ccwgh60 
		INNER JOIN ctry_present AS ctry_present 	
			ON (ccwgh60.DB020= ctry_present.geo) 
		WHERE ctry_present.geo in &ms;

		SELECT real_size INTO: real_size 	
		FROM work.realsize;

		CREATE TABLE work.weu AS 
		SELECT DISTINCT 		
			norm_size, 
			real_size,
			(norm_size*0.7) AS size60,
			(norm_size / real_size) AS infl,
			(CASE  WHEN real_size < CALCULATED size60 THEN 0  
				ELSE 1 
				END) AS euok
		FROM realsize, normsize;

		SELECT euok INTO :euok 
		FROM weu;

		SELECT infl INTO :infl 
		FROM weu;
	quit;

	%work_clean(weu, normsize, realsize, ctry_present);

	%let flageu=;
	%if &not60 %then %let euok=&not60;

	%if &euok and &yyyy > 2004 %then %do;
		/* take the normal number of country in the aggregate */
		%let neu=%substr(&eu,%eval(%length(&eu)-1),2); /* e.g., returns neu=27 from eu=EU27 */

	 	/* put flag s if some countries are missing*/
		%if "&neu" NE "EU" and &nobs NE &neu %then 		%let flageu=s;

		/* put flag s as BG RO are fake data */
		%if (&eu=EU27 AND &yyyy<2007) %then 			%let flageu=s;
	
		/* insert test for indicators required only for currency=EUR */
		PROC SQL;
			CREATE TABLE euval1 AS 
			SELECT 
				&tab..*, 
				ccwgh60.Y&yyyy,
		 		%if "&ilib"="WORK" %then %do;
					(CASE when unrel in(1,2) then (unrel * Y&yyyy)
			 			ELSE 0 END) AS wunrel
				%end;
				%else %do;
					(unrel * Y&yyyy) AS wunrel /* difference? */
				%end;
	 		FROM &ilib..&tab
			LEFT JOIN ex_data.CCWGH60 
				ON (&tab..geo = ccwgh60.DB020)
		 	%if "&tab"="DI10" or "&tab"="DI02" %then %do;
				WHERE geo in &ms and time = &yyyy and currency in ('EUR');
			%end;
			%if "&tab"="DI03" or "&tab"="DI04" or "&tab"="DI05" or "&tab"="DI07" or "&tab"="DI08" or "&tab"="DI09" 
					or "&tab"="DI13" or "&tab"="DI14" or  "&tab"="DI13b" or  "&tab"="DI14b" %then %do;
				WHERE geo in &ms and time = &yyyy and unit in ('EUR');
			%end;
			%else %do;
				WHERE geo in &ms and time = &yyyy ;
			%end;
		quit;

		PROC SQL noprint;
			CREATE TABLE euval AS 
			SELECT DISTINCT 
		 		&grpdim,
				%if "&ilib"="rdb" 
						or "&tab"="LI43" or "&tab"="LVHL23" or "&tab"="MDDD23" or "&tab"="PEPS13" %then %do;
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
				SUM(ntot) AS SUM_OF_ntot,
				(CASE WHEN (sum(wunrel)/(&real_size)) > 0.6 THEN 2
			  		WHEN (sum(wunrel)/(&real_size)) > 0.3 THEN 1
			 	 	WHEN (sum(wunrel)) ne 0 THEN 3
			 		ELSE 
						(CASE WHEN "&flageu" = "s" THEN 3 /* 4 in RDB2 ??? */
							ELSE 0 END)
					END) AS euunrel
			FROM work.euval1
			/*WHERE geo in &ms and time = &yyyy */
			GROUP BY &grpdim;

			CREATE TABLE WORK.&tab as
			SELECT DISTINCT 
				"&eu" AS geo,
				&yyyy AS time,
				&grpdim,
				unit,
				euvalue AS ivalue,
				"&flag" AS iflag FORMAT=$3. LENGTH=3,
				euunrel AS unrel,
				SUM_OF_n AS n,
				SUM_OF_ntot AS ntot,
				SUM_OF_totwgh AS totwgh,
				"&sysdate" AS lastup,
				"&sysuserid" AS	lastuser 
			FROM euval; 
		quit;

		%if "&ilib"="rdb" %then %do;
			/* Update RDB */
			DATA  rdb.&tab;
				SET rdb.&tab(WHERE=(not(time=&yyyy and geo="&eu")))
					WORK.&tab; 
			run;
		%end;
	%end;

	%work_clean(euval, euval1);

	%exit:
%mend EUVALS;

%macro _legacy_euvals/parmbuff;
	%EUVALS&syspbuff; 
%mend _legacy_euvals;


/** \endcond */
