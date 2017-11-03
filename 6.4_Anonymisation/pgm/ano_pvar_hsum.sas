/* TODO ANP_PVAR_HSUM
*/

/* credits: grazzja */

%macro ano_pvar_hsum(geo		/* Countries to operate the calculation										(REQ) */
					, time		/* Date of the survey 														(REQ) */
					, udb_p		/* Input/output P UDB dataset - Must contain the variables passed in PVAR	(REQ) */
					, pvar		/* List of input P variables that will be summed over all household members (REQ) */
					, ovar=		/* Name of the output variable summing all P variables in PVAR 				(OPT) */
					, lib=		/* Name of the input library where UDB is stored 							(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;

	/************************************************************************************/
	/**                 stand-alone declarations/PING not available                    **/
	/************************************************************************************/

	/* this is what happens when PING library is not loaded: no check is performed */
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

	%if &geo= or &time= or &pvar= %then 			%goto exit;

	%macro var_list(l); /*%list_quote(&pvar, mark=_EMPTY_, rep=%quote(, ))*/
		%sysfunc(tranwrd(%qsysfunc(compbl(%sysfunc(strip(&l)))), %quote( ), %quote(, )))
	%mend;

	%macro var_underscore(l); /*%list_quote(&pvar, mark=_EMPTY_, rep=%quote(_))*/
		%sysfunc(tranwrd(%qsysfunc(compbl(%sysfunc(strip(&pvar)))), %quote( ), %quote(_)))
	%mend;

	%if &ovar= %then 				%let ovar=sum_%var_underscore(&pvar); 
	%if %length(&ovar)>32 %then 	%let ovar=%substr(&ovar,1,32);
	%if &lib= %then 				%let lib=WORK;

	PROC SQL;
		/* create table (at personal level) with variables of interest 
		* and sum personal variables over household members */
		CREATE TABLE WORK._TMP1_&udb_p AS 
		SELECT DISTINCT 
			PB010, 
			PB020, 
			PX030 /*PHID*/, 
			PB030, 
			/*&pvar,*/
			SUM(%var_list(&pvar),0) as sum_pvar, /* sum of all P variables over 1 single member */
			SUM(calculated sum_pvar) as &ovar /* sum of all P variables over all members of the household */
		FROM &lib..&udb_p
		WHERE PB020 in %sql_list(&geo) and PB010=&time
		GROUP BY PB010, PB020, PX030
		/* note: we set the line below so as to avoid WARNING:
		* "A GROUP BY clause has been transformed into an ORDER BY clause because neither the SELECT clause..." */
		ORDER BY PB020, PX030; 
	quit;
			
	PROC SQL;
		CREATE TABLE WORK._TMP2_&udb_p as 
		SELECT 
			idb.*,
			tmp.&ovar
		FROM &lib..&udb_p AS idb
		LEFT JOIN WORK._TMP1_&udb_p AS tmp
			ON (idb.PB010 = tmp.PB010) AND (idb.PB020 = tmp.PB020) AND (idb.PX030 = tmp.PX030)
		WHERE idb.PB020 in %sql_list(&geo) and idb.PB010=&time
		ORDER BY idb.PB010, idb.PB020, idb.PX030, idb.PB030;
	quit;

	/* update the input dataset */
	DATA &lib..&udb_p;
		UPDATE &lib..&udb_p _TMP2_&udb_p;
		BY PB010 PB020 PX030 PB030;
	run;

	/* clean */
	PROC DATASETS lib=WORK nolist; 
		DELETE _TMP1_&udb_p _TMP2_&udb_p;  
	quit; 

	%exit:
%mend ano_pvar_hsum;

%macro _example_ano_pvar_hsum;
	%let yyyy=2015;
	%let ctry=AT;

	DATA dbp;
		PB030=1; PB010=&yyyy; PB020="&ctry"; PX030=1; PY010G=1; PY080G=1;  PY090G=1; output;
		PB030=2; PB010=&yyyy; PB020="&ctry"; PX030=1; PY010G=1; PY080G=1;  PY090G=1; output;
		PB030=3; PB010=&yyyy; PB020="&ctry"; PX030=1; PY010G=.; PY080G=0; PY090G=2; output;
		PB030=4; PB010=&yyyy; PB020="&ctry"; PX030=2; PY010G=1; PY080G=5; PY090G=2; output;
		PB030=5; PB010=&yyyy; PB020="&ctry"; PX030=3; PY010G=2; PY080G=10; PY090G=3; output;
		PB030=6; PB010=&yyyy; PB020="&ctry"; PX030=3; PY010G=2; PY080G=10; PY090G=4; output;
		PB030=7; PB010=&yyyy; PB020="&ctry"; PX030=3; PY010G=2; PY080G=.; PY090G=5; output;
		PB030=14; PB010=&yyyy; PB020="&ctry"; PX030=3; PY010G=2; PY080G=10; PY090G=6; output;
		PB030=15; PB010=&yyyy; PB020="&ctry"; PX030=3; PY010G=2; PY080G=10; PY090G=7; output;
		PB030=8; PB010=&yyyy; PB020="&ctry"; PX030=4; PY010G=3; PY080G=50; PY090G=8; output;
		PB030=9; PB010=&yyyy; PB020="&ctry"; PX030=4; PY010G=3; PY080G=50; PY090G=9; output;
		PB030=10; PB010=&yyyy; PB020="&ctry"; PX030=5; PY010G=4; PY080G=100; PY090G=10; output;
		PB030=11; PB010=&yyyy; PB020="&ctry"; PX030=5; PY010G=4; PY080G=100; PY090G=11; output;
		PB030=12; PB010=&yyyy; PB020="&ctry"; PX030=5; PY010G=0; PY080G=100; PY090G=12; output;
		PB030=13; PB010=&yyyy; PB020="&ctry"; PX030=5; PY010G=4; PY080G=100; PY090G=13; output;
	run;

	DATA dbp1; SET dbp; run;
	%ano_pvar_hsum(&ctry, &yyyy, dbp1, PY010G);

	DATA dbp2; SET dbp; run;
	%ano_pvar_hsum(&ctry, &yyyy, dbp2, PY010G PY080G);

	DATA dbp3; SET dbp; run;
	%ano_pvar_hsum(&ctry, &yyyy, dbp3, PY010G PY080G PY090G);

%mend _example_ano_pvar_hsum;	

/* 
%_example_ano_pvar_hsum; 
*/
