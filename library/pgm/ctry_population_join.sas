/** 
## ctry_population_join {#sas_ctry_population_join}
Join countries available for an aggregate area estimation together with their respective
population.
 
~~~sas
	%ctry_population_join(idsn, ctrydsn, time, odsn, where=, ilib=WORK, olib=WORK,
						  cds_popxctry=META_POPULATIONxCOUNTRY, clib=LIBCFG);
~~~

### Arguments
* `dsn` : a dataset representing the indicator for which an aggregated value is estimated;
* `ctrydsn` : name of the table where the list of countries with the year of estimation is
	stored;
* `time` : year of interest;
* `where` : (_option_) ; default: not set; 
* `cds_popxctry, clib` : (_option_) respectively, name and library of the configuration file storing 
	the population of different countries; by default, these parameters are set to the values 
	`&G_PING_POPULATIONxCOUNTRY` and `&G_PING_LIBCFG`' (_e.g._, `META_POPULATIONxCOUNTRY` and `LIBCFG`
	resp.); see [%meta_populationxcountry](@ref meta_populationxcountry)	for further description.
* `lib` : (_option_) input dataset library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
* `odsn` : name of the joined dataset;
* `olib` : (_option_) output library.

### Example
Run macro `%%_example_ctry_population_join`.

### See also
[%population_compare](@ref sas_population_compare), [%meta_populationxcountry](@ref meta_populationxcountry).
*/ /** \cond */

/* credits: gjacopo, marinapippi */

%macro ctry_population_join(idsn
							, ctrydsn
							, time
							, odsn
							, ilib=
							, olib=
							, where=
							, cds_popxctry=
							, clib=
							);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* IDSN/ILIB: check  the input dataset */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* CTRYDSN: check  the dataset */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&ctrydsn, lib=WORK) EQ 1, mac=&_mac,		
			txt=!!! Input country dataset %upcase(&ctrydsn) not found in WORK !!!) %then
		%goto exit;

	/* ODSN/OLIB: set the default output dataset */
	%if %macro_isblank(olib) %then 	%let olib=WORK;

	%if %error_handle(ErrorOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,		
			txt=! Output dataset %upcase(&odsn) already exists: will be replaced!, 
			verb=warn) %then
		%goto warning1;
	%warning1:

	/* CLIB/CDS_POPXCTRY: check the population file: the name should be defined globally (e.g. 
	 * in the _startup_default_), otherwise set it locally */
	%if %macro_isblank(clib) %then %do; 			
		%if %symexist(G_PING_LIBCFG) %then 				%let clib=&G_PING_LIBCFG;
		%else											%let clib=LIBCFG/*SILCFMT*/;
	%end; 

	%if %macro_isblank(cds_popxctry) %then %do; 			
		%if %symexist(G_PING_POPULATIONxCOUNTRY) %then 	%let cds_popxctry=&G_PING_POPULATIONxCOUNTRY;
		%else											%let cds_popxctry=POPULATIONxCOUNTRY;
	%end; 

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&cds_popxctry, lib=&clib) EQ 1, mac=&_mac,		
			txt=%quote(!!! Population dataset %upcase(&cds_popxctry) not found !!!))
		or 
		%error_handle(ErrorInputParameter, 
			%var_check(&cds_popxctry, Y&time, lib=&clib) EQ 1, mac=&_mac,		
			txt=%quote(!!! Variable %upcase(Y&time) does not exist in dataset %upcase(&cds_popxctry) !!!)) %then 
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* set variables' labels */
	%local l_time l_geo;
	%if %symexist(G_PING_LAB_TIME) %then 			%let l_time=&G_PING_LAB_TIME;
	%else											%let l_time=TIME;
	%if %symexist(G_PING_LAB_GEO) %then 			%let l_geo=&G_PING_LAB_GEO;
	%else											%let l_geo=GEO;

	/* retrieve the final list of available countries */
	%local ctrylst;
	%var_to_list(&ctrydsn, &l_geo, _varlst_=ctrylst, lib=WORK);

	PROC SQL;
		CREATE TABLE &olib..&odsn as 
		SELECT idsn.*, 
			dspop.Y&time, 
			%if %var_check(&idsn, unrel, lib=&ilib) EQ 0 %then %do;
				(unrel * Y&time) as wunrel 
			%end;
			%else %do;
				%if %symexist(G_PING_FLAG_UNREL) %then 	%do;	%let wunrel=&G_PING_FLAG_UNREL; 
				%end;
				%else %do;										%let wunrel=4; 
				%end;
				&wunrel as wunrel 
			%end;
	 	FROM &ilib..&idsn as idsn 
		INNER JOIN &ctrydsn 
			ON (idsn.&l_time = &ctrydsn..&l_time and idsn.&l_geo = &ctrydsn..&l_geo)
		INNER JOIN &clib..&cds_popxctry as dspop 
			ON (dspop.&l_geo=idsn.&l_geo)
		WHERE idsn.&l_geo in %sql_list(&ctrylst)
		%if not %macro_isblank(where) %then %do;
			and &where /* idsn.&label_unit in ('EUR') */
		%end;
		;
	quit;

	%exit:
%mend ctry_population_join;

%macro _example_ctry_population_join;
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

	/* first simple test */
	%_dstest25;
	%_dstest26;
	%_dstest27;

	%ds_print(_dstest25);
	%ds_print(_dstest27);

	%let tab_o=_tmp_out_example_aggregate_join;
	%ctry_population_join(_dstest25, _dstest27, 2014, &tab_o, where=%quote(unit="EUR") );
	%ds_print(&tab_o, title="Joined tables _dstest25 and _dstest27 on population");

	%work_clean(_dstest25);
	%work_clean(_dstest27);
	%work_clean(&tab_o);

	/* more complex test: combine with ctry_select */

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

	%let dsn=LI01;

	%let tab_part=_TMP&sysmacroname;
	%if %length(&tab_part)>32 %then %let tab_part=%substr(&tab_part,1,32);

	%*local pop_infl run_agg pop_part;
	%let pop_infl=;
	%let run_agg=;
	%let pop_part=;

	%put other variables to default values;
	%ctry_select(&dsn, &ctry_glob, &year, &tab_part, 
				_pop_infl_=pop_infl, _run_agg_=run_agg, _pop_part_=pop_part,
				take_all=YES, ilib=rdb, olib=WORK);
	%put 	result in: pop_infl=&pop_infl, pop_part=&pop_part, run_agg=&run_agg;
	%ds_print(&tab_part, title="Countries from year &year and prior");
	/*%work_clean(&tab_part);*/

	%ctry_population_join(&dsn, &tab_part, &year, &tab_o, ilib=rdb);
	%ds_print(&tab_o, title="Joined tables &tab_part and &dsn on population");

	%work_clean(&tab_part);
	%work_clean(&tab_o);

	%put;

	%exit:
%mend _example_ctry_population_join;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ctry_population_join;  
*/

/** \endcond */
