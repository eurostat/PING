/** 
## ano_var_btcode {#sas_ano_var_btcode}

~~~sas
%ano_var_btcode(geo, time, db, var, wgt, db_d=, vartype=, coding=T, nobs=10, lib=WORK);
~~~

### Examples
In the following, we consider the example of anonymisation applied in practice 
for `geo=SI`. The input datasets are the common `UDB` files whose extension states 
whether they contain `R`, `P`, `H` or `D` variables.
1. Variable top-coding: say for the highest 10 original values of the variable 
`PY031G`, you want to replace the original values with their weighted average. 
Run:

~~~sas
%ano_var_btcode(SI, UDB_P, PY031G, PB040, coding=TOP, vartype=P, nobs=10);
~~~
2. Combined variables top-coding: say you want to replace the values of `PY030G` 
variable for observations that are highest for either `PY030G` or the related 
variable `PY031G`, doing the following: 
	* selecting the 10 IDs with the highest values of variable `PY030G`;
	* selecting the 10 IDs with the highest values of related variable `PY031G`;
	* considering the union of selected IDs (at least 10 observations, not more 
	than 20),

then replacing the original values for observations in the union above with 
weighted average, you can then run the following:

~~~sas
%ano_var_btcode(SI, UDB_P, PY030G, PB040, coding=TOP, relvar=PY031G, nobs=10, vartype=P);
~~~
3. Gross/net variables top-coding: say you want to simultaneously replace the 
highest original values of gross/net variables HY040G/HY040N, doing the following: 
	* selecting the 10 IDs with the highest original values of gross variable 
	`HY040G`;
	* selecting the 10 IDs with the highest original value of net variable `HY040N`;
	* considering the union of selected IDs (at least 10 observations, not more 
	than 20);

then replacing the original values of both gross/net variables for observations 
in the union above with their respective weighted averages, you can then run the 
following:

~~~sas
%ano_var_btcode(SI, UDB_H, HY040G HY040N, DB090, coding=TOP, db_d=UDB_D, nobs=10, vartype=H);
~~~
*/ /** \cond */

/* credits: gjacopo */

%macro ano_var_btcode(geo
					, time
					, db		/* Input bulk dataset 										(REQ) */
					, var		/* List of variable(s) to simultaneously top/bottom code 	(REQ) */
					, wgt		/* Name of the weight variable used together with VAR to compute the mean value of top/bottom coded observations 	(REQ) */
					, db_d=	/* Input D UDB dataset used to retrieve the weight variable from when the input UDB is H 							(OPT) */
					, relvar=	/* Related variable used to identify the observations (individuals) concerned by the top/bottom coding 				(OPT) */
					, nobs=		/* Number of observations (individuals) concerned by the top/bottom coding 											(OPT) */
					, coding=	/* Type of coding: either bottom (B) or top (T) 																	(OPT) */
					, vartype=	/* Type of the input variables passed in VAR: either H or P 														(OPT) */
					, cond=		/* Additional clause used to further restrict the observations on which the top/bottom coding is operated 			(OPT) */
					, keep=		/* Flag set to keep a copy of the adjusted variable VAR - When set, used to prefix VAR name							(OPT) */
					, lib=		/* Name of the input library where UDB is stored 																	(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;

	/************************************************************************************/
	/**                 stand-alone declarations/PING not available                    **/
	/************************************************************************************/

	%if %symexist(G_PING_ROOTPATH) EQ 1 %then %do; 
		%macro_put(&_mac);
	%end;
	%else %if %symexist(G_PING_PGM_LIGTH_LOADED) EQ 0 %then %do; 
		%if %symexist(G_PING_PGM_LIGTH_PATH) EQ 0 %then 	
			%let G_PING_PGM_LIGTH_PATH=/ec/prod/server/sas/0eusilc/7.3_Dissemination/pgm; 
		%include "&G_PING_SETUPPATH/ping_pgm_light.sas";
	%end;
 
	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local nvar nrelvar;

	/* GEO : check */
	%if %macro_isblank(geo) %then 			%goto exit;

	/* VAR : check */
	%if %macro_isblank(var) %then 			%goto exit;
	%let nvar=%list_length(&var);

	/* CODING : default set */
	%if %macro_isblank(coding) %then 		%let coding=T;
	%else 									%let coding=%upcase(&coding);
	%if "&coding"="BOTTOM" %then			%let coding=B;
	%else %if "&coding"="TOP" %then			%let coding=T;

	/* VARTYPE : default set */
	%if %macro_isblank(vartype) %then 		%let vartype=%substr(&var,1,1);
	%let vartype=%upcase(&vartype);

	/* NOBS : default set */
	%if %macro_isblank(nobs) %then 			%let nobs=10;

	/* LIB : default set */
	%if %macro_isblank(lib) %then 			%let lib=WORK;

	/* this is what happens when G_DEBUG=0: library is not loaded: no check is performed */
	%if %symexist(G_DEBUG) EQ 0 %then 	%goto check_skip;  
	%else %if &G_DEBUG EQ 0 %then 		%goto check_skip; 

	/* RELVAR : check */
	%let nrelvar=%list_length(&relvar);
	%if %error_handle(ErrorInputParameter, 
			&nrelvar NE 0 and &nrelvar NE &nvar, mac=&_mac,		
			txt=%quote(!!! Lists VAR and RELVAR must be of same length when RELVAR is passed !!!)) %then
		%goto exit;

	/* NOBS : check */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&nobs, type=INTEGER, range=0) NE 0, mac=&_mac,		
			txt=%quote(!!! Parameter NOBS must be an integer >0 !!!)) %then
		%goto exit;

	/* CODING : check */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&coding, type=CHAR, set=T B) NE 0, mac=&_mac,		
			txt=%quote(!!! Parameter CODING must be any of the char flags B or T !!!)) %then
		%goto exit;

	/* INCTYPE : check */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&inctype, type=CHAR, set=G N) NE 0, mac=&_mac,		
			txt=%quote(!!! Parameter INCTYPE must be any of the char flags G or N !!!)) %then
		%goto exit;

	/* VARTYPE : check */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&vartype, type=CHAR, set=H P R D) NE 0, mac=&_mac,		
			txt=%quote(!!! Parameter VARTYPE must be any of the char flags H, P, R or D !!!)) %then
		%goto exit;

	%local _lvar;

	/* DB : check */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&db, lib=&lib) EQ 1, mac=&_mac,		
			txt=%quote(!!! Input dataset %upcase(&db) not found !!!)) %then
		%goto exit;

	%let _lvar=;
    %ds_contents(&db, _varlst_=_lvar, lib=&lib);
	%if %error_handle(ErrorInputParameter,
			%list_difference(&wgt &var, &_lvar) NE , mac=&_mac,
			txt=%quote(!!! Variables &var, and &wgt must be present in input dataset %upcase(&db) !!!)) %then 
		%goto exit;	

	/* DB_D : check */
	%if %error_handle(ErrorInputParameter, 
			&vartype EQ H and %macro_isblank(db_d), mac=&_mac,		
			txt=%quote(!!! Parameter DB_D needs to be set when VARTYPE=H !!!)) %then
		%goto exit;
	
	%if not %macro_isblank(db_d) %then %do;
		%if %error_handle(ErrorInputDataset, 
				%ds_check(&db_d, lib=&lib) EQ 1, mac=&_mac,		
				txt=%quote(!!! Input dataset %upcase(&db_d) not found !!!)) %then
			%goto exit;

		%let _lvar=;
	    %ds_contents(&db_d, _varlst_=_lvar, lib=&lib);
		%if %error_handle(ErrorInputParameter,
				%list_difference(DB010 DB020 DB030, &_lvar) NE , mac=&_mac,
				txt=%quote(!!! Variables DB010, DB020, DB030 must be present in input dataset %upcase(&db_d) !!!)) %then 
			%goto exit;	
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/
	
	%check_skip:

	%local tmp __isempty __i
		__var __relvar
		__tmp __tmprel;
	%let tmp=_TMP_&db;

	/* select the NOBS highest amounts of the VAR variable(s) */
	%do __i=1 %to &nvar;
		%let __var=%scan(&var, &__i);
		%let __tmp=_TMP_&__var;

		PROC SQL outobs=&nobs nowarn;
	 		CREATE TABLE WORK.&__tmp AS 
			SELECT 
				&vartype.B010, &vartype.B020, &vartype.B030, 
				&wgt, /* if H-variable, the weight actually comes from IDB_D */ 
				&__var
		 	FROM &lib..&db AS idb
			%if "&vartype"="H" %then %do;		/* if H-variable */
				INNER JOIN &lib..&db_d AS idb_d 
				ON idb.HB010=idb_d.DB010 and idb.HB020=idb_d.DB020 and idb.HB030=idb_d.DB030
		 	%end;
			WHERE
				%if not %macro_isblank(cond) %then %do;		
					&cond and
			 	%end;
				%if "&time" ^= "_ALL_" %then %do;
					&vartype.B010 = &time and 
				%end;
				&vartype.B020 in %sql_list(&geo)
		 	ORDER BY &__var 
				%if "&coding"="T" %then %do; 
					DESCENDING /* top-coding */
				%end;
			/* %else: bottom-coding */
			;
		quit;

		/* check  that some observations were actually found (in case COND was passed) */
		%let __isempty=;
		%ds_isempty(&__tmp, _ans_=__isempty);
		%if %error_handle(ErrorInputDataset, 
				&__isempty NE 0, mac=&_mac,		
				txt=%quote(!!! No observation found for %upcase(&__var) !!!)) %then
			%goto exit;
	%end;

	/* select the NOBS highest amounts of the related RELVAR variable(s) */
	%if &nrelvar>0 /*not %macro_isblank(relvar)*/ %then %do;
		%do __i=1 %to &nrelvar; /* note that nrelvar=nvar when not null */
			%let __var=%scan(&var, &__i);
			%let __relvar=%scan(&relvar, &__i);
			%let __tmprel=_TMP_&__relvar;

			PROC SQL outobs=&nobs nowarn;
				CREATE TABLE WORK.&__tmprel AS 
				SELECT 
					&vartype.B010, &vartype.B020, &vartype.B030, 
					&wgt, 
					&__var, &__relvar
				FROM &lib..&db AS idb
				%if "&vartype"="H" %then %do;		/* if H-variable */
					INNER JOIN &lib..&db_d AS idb_d 
					ON idb.HB010=idb_d.DB010 and idb.HB020=idb_d.DB020 and idb.HB030=idb_d.DB030
				 %end;
				WHERE 
					%if not %macro_isblank(cond) %then %do;		
						&cond and
					%end;
					%if "&time" ^= "_ALL_" %then %do;
						&vartype.B010 = &time and 
					%end;
					&vartype.B020 in %sql_list(&geo)
				ORDER BY &__relvar 
					%if "&coding"="T" %then %do; 
						DESCENDING
					%end;
				;
			quit;

			/* among the NOBS observations with the highest/lowest value of the related variable __RELVAR, 
			* we select the subset of observations for which the value of the main variable __VAR is  
			* greater or equal than the value of __RELVAR */
			DATA WORK.&__tmprel; 
				SET WORK.&__tmprel;
				/* keep only those observations where VAR value >= related RELVAR value  */
 				WHERE &__var GE &__relvar;
			run;
		%end;
	%end;

	%if &nvar>1 or &nrelvar>0 %then %do;
		/* build the union of identifiers */
		PROC SQL;
			CREATE TABLE &tmp._union AS
			%do __i=1 %to &nvar;
				%let __tmp=_TMP_%scan(&var, &__i);
				SELECT 
					&vartype.B010, &vartype.B020, &vartype.B030 
				FROM WORK.&_tmp
				%if &nrelvar>0 %then %do;
					%let __tmprel=_TMP1_%scan(&relvar, &__i);
					UNION
					SELECT &vartype.B010, &vartype.B020, &vartype.B030 
					FROM WORK.&__tmprel;
				%end;
				%if &nvar>1 %then %do;
					UNION
				%end;
			%end;
		quit;

		/* assign variables to identifiers */
		PROC SQL;
			CREATE TABLE WORK.&tmp.1 as
			SELECT 
				t1.&vartype.B010, t1.&vartype.B020, t1.&vartype.B030
				%do __i=1 %to &nvar; 
					%let __var=%scan(&var, &__i);
					, idb.&__var
					%if &nrelvar>0 %then %do;
						%let __relvar=%scan(&relvar, &__i);
						, idb.&__relvar
					%end;
				%end;
				, &wgt 
			FROM &tmp._union AS t1 
			LEFT JOIN &lib..&db AS idb 
				ON (t1.&vartype.B010=idb.&vartype.B010 
				and t1.&vartype.B020=idb.&vartype.B020 
				and t1.&vartype.B030=idb.&vartype.B030)
			%if "&vartype"="H" %then %do;		/* if H-variable */
				LEFT JOIN &lib..&db_d AS idb 
					ON (t1.HB010=idb.DB010 and t1.HB020=idb.DB020 and t1.HB030=idb.DB030)
		 	%end;
			;
		quit;

		%work_clean(&tmp._union);
	%end;
	%else %do;
		DATA WORK.&tmp.1;
			SET _TMP_&__var;
		run;
	%end;

	/* remove weights where variable is missing or 0 in order to compute correct mean */
	PROC SQL;
		CREATE TABLE WORK.&tmp.2 as
		SELECT 
			&vartype.B010, &vartype.B020, &vartype.B030	/*,  &wgt */
			%do __i=1 %to &nvar; 
				%let __var=%scan(&var, &__i);
				, &__var
				, (case when &__var is missing or &__var=0 then 0 else &wgt end) as &wgt._&__var  
				/*%if &nrelvar>0 %then %do;
					%let __relvar=%scan(&relvar, &__i);
					, &__relvar 		
				%end; */
			%end;
		FROM WORK.&tmp.1;
	quit;

	/* compute weighted mean of the NOBS highest income variables */
	PROC SQL;
		CREATE TABLE WORK.&tmp.3 AS
		SELECT 
			&vartype.B010, &vartype.B020, &vartype.B030 /*,  &wgt */
			%do __i=1 %to &nvar; 
				%let __var=%scan(&var, &__i);
				/* , &__var */, &wgt._&__var
				, SUM(&wgt._&__var * &__var) / sum(&wgt._&__var) FORMAT=12.2 AS MEAN_&__var
			%end;
	 	FROM WORK.&tmp.2
		GROUP BY &vartype.B010, &vartype.B020;
	quit;

	/* store the original values by copying the variable */
	%if &keep NE %then %do;
		DATA &lib..&db;
			SET &lib..&db;
			%do __i=1 %to &nvar; 
				%let __var=%scan(&var, &__i);
				&keep.&__var = &__var;
			%end;
		run;
	%end;

	/* update dataset with weighted average of the NOBS highest income variables */
	PROC SQL;
		%do __i=1 %to &nvar; 
			%let __var=%scan(&var, &__i);
			UPDATE &lib..&db AS idb
			SET &__var = (
				SELECT DISTINCT MEAN_&__var 
				FROM WORK.&tmp.3 as &tmp.3
				WHERE idb.&vartype.B010=&tmp.3.&vartype.B010 
					and idb.&vartype.B020=&tmp.3.&vartype.B020 
					and idb.&vartype.B030=&tmp.3.&vartype.B030
					and &wgt._&__var NE 0
				)
		  	WHERE &__var ne (
				SELECT DISTINCT MEAN_&__var 
				FROM WORK.&tmp.3 as &tmp.3 
				WHERE idb.&vartype.B010=&tmp.3.&vartype.B010 
					and idb.&vartype.B020=&tmp.3.&vartype.B020 
					and idb.&vartype.B030=&tmp.3.&vartype.B030
					and &wgt._&__var NE 0
				)
			;
			%let __tmp=_TMP_%scan(&var, &__i);				
			%let __tmprel=_TMP_%scan(&relvar, &__i);
			DROP TABLE 
				WORK.&__tmp
				%if &nrelvar>0 %then %do;
					, WORK.&__tmprel
				%end;
				;
		%end;
	quit;

	%work_clean(&tmp.1, &tmp.2, &tmp.3);

	%exit:
%mend ano_var_btcode;

%macro _example_ano_var_btcode;
	/*%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;*/
	%let yyyy=2015;
	%let ctry=AT;

	DATA dbp;
		PB030=1; PB010=&yyyy; PB020="&ctry"; PX030=1; PY010G=10; PY080G=1;  PY090G=1; PB040=1; output;
		PB030=2; PB010=&yyyy; PB020="&ctry"; PX030=1; PY010G=40; PY080G=1;  PY090G=1; PB040=1; output;
		PB030=3; PB010=&yyyy; PB020="&ctry"; PX030=1; PY010G=.; PY080G=0; PY090G=2; PB040=1; output;
		PB030=4; PB010=&yyyy; PB020="&ctry"; PX030=2; PY010G=50; PY080G=5; PY090G=2; PB040=2; output;
		PB030=5; PB010=&yyyy; PB020="&ctry"; PX030=3; PY010G=60; PY080G=10; PY090G=3; PB040=3; output;
		PB030=6; PB010=&yyyy; PB020="&ctry"; PX030=3; PY010G=20; PY080G=10; PY090G=4; PB040=3; output;
		PB030=7; PB010=&yyyy; PB020="&ctry"; PX030=3; PY010G=200; PY080G=.; PY090G=5; PB040=3; output;
		PB030=14; PB010=&yyyy; PB020="&ctry"; PX030=3; PY010G=20; PY080G=10; PY090G=6; PB040=3; output;
		PB030=15; PB010=&yyyy; PB020="&ctry"; PX030=3; PY010G=120; PY080G=10; PY090G=7; PB040=3; output;
		PB030=8; PB010=&yyyy; PB020="&ctry"; PX030=4; PY010G=30; PY080G=50; PY090G=8; PB040=1; output;
		PB030=9; PB010=&yyyy; PB020="&ctry"; PX030=4; PY010G=130; PY080G=50; PY090G=9; PB040=1; output;
		PB030=10; PB010=&yyyy; PB020="&ctry"; PX030=5; PY010G=40; PY080G=100; PY090G=10; PB040=2; output;
		PB030=11; PB010=&yyyy; PB020="&ctry"; PX030=5; PY010G=100; PY080G=100; PY090G=11; PB040=2; output;
		PB030=12; PB010=&yyyy; PB020="&ctry"; PX030=5; PY010G=0; PY080G=100; PY090G=12; PB040=2; output;
		PB030=13; PB010=&yyyy; PB020="&ctry"; PX030=5; PY010G=80; PY080G=100; PY090G=13; PB040=2; output;
	run;

	DATA dbh;
		HB030=1; HB010=&yyyy; HB020="&ctry"; HY010=-100; HY020=-150;  HY022=-160; output;
		HB030=2; HB010=&yyyy; HB020="&ctry"; HY010=-200; HY020=-250; HY022=-260; output;
		HB030=3; HB010=&yyyy; HB020="&ctry"; HY010=300; HY020=200; HY022=190; output;
		HB030=4; HB010=&yyyy; HB020="&ctry"; HY010=400; HY020=300; HY022=290; output;
		HB030=5; HB010=&yyyy; HB020="&ctry"; HY010=500; HY020=400; HY022=390; output;
	run;

	DATA dbd;
		DB030=1; DB010=&yyyy; DB020="&ctry"; DB090=1; output;
		DB030=2; DB010=&yyyy; DB020="&ctry"; DB090=2; output;
		DB030=3; DB010=&yyyy; DB020="&ctry"; DB090=3; output;
		DB030=4; DB010=&yyyy; DB020="&ctry"; DB090=1; output;
		DB030=5; DB010=&yyyy; DB020="&ctry"; DB090=2; output;
	run;

	DATA dbp1; SET dbp; run;
	%ano_var_btcode(&ctry, &yyyy, dbp1, PY010G, PB040, nobs=5, coding=T, vartype=P);

	DATA dbp2; SET dbp; run;
	%ano_var_btcode(&ctry, &yyyy, dbp2, PY010G, PB040, relvar=PY080G, nobs=5, coding=T, keep=_i, vartype=P);

	DATA dbh1; SET dbh; run;
	%ano_var_btcode(&ctry, &yyyy, dbh1, HY010, DB090, db_d=dbd, nobs=2, coding=T, vartype=H);

	DATA dbh2; SET dbh; run;
	%ano_var_btcode(&ctry, &yyyy, dbh2, HY022, DB090, db_d=dbd, nobs=2, coding=B, cond=%quote(HY022<0), keep=_i, vartype=H);

%mend _example_ano_var_btcode;

/*
%_example_ano_var_btcode;
*/
