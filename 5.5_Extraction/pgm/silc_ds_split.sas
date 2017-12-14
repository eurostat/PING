/** 
## silc_ds_split {#sas_silc_ds_split}
Split a EU-SILC dataset into subsets that contain data for a given country and a given
year.

~~~sas
	%silc_ds_split(geo, time, idsn, odsn=, _ctrylst_=, _yearlst_=, _db_=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `geo` : list of desired countries ISO-codes		
* `time` : list of desired years 					
* `idsn` : input dataset 							
* `ilib` : input library name 

### Returns
* `odsn` : generic output file name 				
* `_ctrylst_` : output list of countries actually extracted 
* `_yearlst_` : output list of years actually extracted 	
* `_db_` : output level 	
* `olib` : output library name.

### See also
[%ds_select](@ref sas_ds_select), [%ds_contents](@ref sas_ds_contents), 
[%dir_check](@ref sas_dir_check), [%ds_check](@ref sas_ds_check), 
[%str_isgeo](@ref sas_str_isgeo), [%zone_replace](@ref sas_zone_replace),
[%var_to_list](@ref sas_var_to_list).
*/ /** \cond */

/* credits: gjacopo */

%macro silc_ds_split(geo				/* List of desired countries ISO-codse 			(REQ) */
					, time			/* List of desired years 						(REQ) */
					, idsn			/* Input dataset 								(REQ) */
					, odsn=			/* Generic output file name 					(OPT) */
					, _ctrylst_=	/* Output list of countries actually extracted 	(OPT) */
					, _yearlst_=	/* Output list of years actually extracted 		(OPT) */
					, _db_=
					, ilib= 		/* Input library name 							(OPT) */
					, olib=			/* Output library name 							(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _ctries 
		ntries ntime
		G_YEARINIT;
	%let G_YEARINIT=2002;

	%if %macro_isblank(geo) or %macro_isblank(time) or %macro_isblank(idsn) %then 
		%goto exit;

	/* ILIB/IDSN: check/set default */
	%if %macro_isblank(ilib) %then 					%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* ODSN/OLIB: set the default output library and the generic output name */
	%if %macro_isblank(olib) %then 					%let olib=WORK;
	%if %macro_isblank(odsn) %then 					%let odsn=&idsn._;

	/* GEO: check/set */
	/* %if %macro_isblank(geo) %then	%let geo=EU28; /* default area zone */
	%if "&geo" NE "_ALL_" %then %do;
		%local isGeo;
		/* for a given list GEO of ISO-codes, %STR_ISGEO returns (in ISGEO):
		*	- 2 in the position of EU areas' codes,
		*	- 1 in the position of countries' codes,
		* 	- 0 in the position of unrecognised/wrong codes */
		%str_isgeo(&geo, _ans_=isGeo, _geo_=_ctries);

		/* check for the presence of: 
		*	(1) wrong codes (then exit), 
		*	(2) EU area codes (then replace the area by the list of countries belonging to these areas) */
		%if %error_handle(ErrorInputParameter, 
				/*(1)*/ %list_count(&isGeo, 0) NE 0, mac=&_mac,		
				txt=%quote(!!! Wrong parameter GEO: must be country/geographical zone ISO code(s) !!!)) %then
			%goto exit;
		%else %if /*(2)*/ %list_count(&isGeo, 2) NE 0 %then %do; 
			%zone_replace(&_ctries, _ctrylst_=_ctries); /* replace given areas by countries belonging to them */
			%let _ctries=%list_unique(&_ctries); 	/* avoid duplication of ISO-codes inside the list */
		%end;
		/* at this stage, the GEO list should contain ISO-codes of countries only */
	%end;
	/* %else: we leave the case GEO=_ALL_ for later (see call to %var_to_list below) ... */

	/* TIME: check/set */
	%if "&time" NE "_ALL_" %then %do;
		%if %symexist(G_PING_INITIAL_YEAR) %then 	%let yearinit=&G_PING_INITIAL_YEAR;
		%else										%let yearinit=&G_YEARINIT;
	
		%let ntime=%list_length(&time);
	
		/* check that TIME>YEARINIT, i.e. it is in the range ]YEARINIT, infinity[ */
		%if %error_handle(ErrorInputParameter, 
				%par_check(&time, type=INTEGER, range=&yearinit) NE %list_ones(&ntime, item=0), mac=&_mac,		
				txt=%quote(!!! Wrong types/values for input TIME period !!!)) %then
			%goto exit;
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _l _c _b _y _ans
		_vars _where _diff
		db idsn
		_years _year _yy _ctry;

	/* retrieve the list _VARS of variables in the dataset IDSN */
	%let _vars=;
	%ds_contents(&idsn, _varlst_=_vars, lib=&ilib);
	
	/* check what is the type DB of the variables present in the dataset IDSN: test whether 
	* any of the variables DB020, HB020, PB020, or RB020 is present in the dataset */
	%do _l=1 %to 4;
		%let db=%scan(/* &G_PING_BASETYPES */P H D R, &_l);
		%if "%list_find(&_vars, &db.B020)" NE "" %then 	%goto proceed;
	%end;
	/* if we reach that point, it means that we did not reach the GOTO statement in the previous
	* loop, hence none of the variables DB020, HB020, PB020, or RB020 has been found in the dataset */
	%if %error_handle(ErrorMissingVariable, 
			1 /* always true! */, mac=&_mac,		
			txt=%quote(!!! No variable ?B020 found in the dataset !!!)) %then
		%goto exit;
	%proceed: /* at this stage, the variable DB stores the right type of variable */
	/* also check that that &DB.010 is in the dataset */

	%if %error_handle(ErrorMissingVariable, 
			"%list_find(&_vars, &db.B010)" EQ "", mac=&_mac,		
			txt=%quote(!!! No variable &db.B010 found in the dataset !!!)) %then
		%goto exit;

	/* retrieve the list _YEARS of available years (1 per file in principle... who knows, that may
	* change!) */
	%var_to_list(&idsn, &db.B010, _varlst_=_years, distinct=YES, lib=&ilib);
	/* check that the desired TIME years are present in the dataset */ 
	%if "&time" NE "_ALL_" %then %do;
		%let _diff=%list_difference(&time, &_years);
		%if %error_handle(ErrorMissingData,  
				&_diff EQ &time, mac=&_mac,		
				txt=%quote(! No year in &time found in the dataset !)) %then
			%goto exit;
		%else %if %error_handle(WarningMissingData, 
				&_diff  NE , mac=&_mac,		
				txt=%quote(! Some years in &time not available in the dataset !), verb=warn) %then
			%goto warning1;
		%warning1:
		%let _years=%list_intersection(&time, &_years);
	%end;
	/* %else: _YEARS already contain the list of all years available in the dataset */
	
	/* retrieve the list _CTRIES of available countries if not _ALL_ countries were selected */
	%if "&geo" EQ "_ALL_" %then %do;
		%var_to_list(&idsn, &db.B020, _varlst_=_ctries, distinct=YES, lib=&ilib); 
	%end;
	
	%do _y=1 %to %list_length(&_years);
		/* which year: that's in _YEAR ... */
		%let _year=%scan(&_years, &_y);
		/* extract the last 2 digits of current year into _YY */
		%let _yy=%substr(&_year,3,2);

		%do _c=1 %to %list_length(&_ctries);
			/* which country: that's in _CTRY ... */
			%let _ctry=%scan(&_ctries, &_c);

			/* define the condition _WHERE for the extraction of the correct data */
			%let _where=%quote(&db.B020 EQ "&_ctry" and &db.B010 EQ &_year);

			/* build the output file name _ODSN using the generic ODSN argument */
			%let _odsn=&odsn.&_ctry.&_yy.&db;
			/* note: if you ever modify the format of the name of this temporary dataset,
			* you will also have to modify the corresponding pieces of code in the macro
			* UDB_FILE_SPLIT (see definitions of _IDSN and _OFN in that macro) */

			%if %error_handle(WarningOutputDataset, 
					%ds_check(&_odsn, lib=&olib) EQ 0, mac=&_mac,		
					txt=! Output dataset %upcase(&_odsn) already exists: will be replaced !, 
					verb=warn) %then
				%goto warning2;
			%warning2:

			/* extract the data into new temporary dataset &_ODSN */
			%ds_select(&idsn, &_odsn, where=&_where, all=YES, ilib=&ilib, olib=&olib);
	
			/* check that the dataset is actually filled with some observations, otherwise delete it */
			%let _ans=;
			%ds_isempty(&_odsn, _ans_=_ans, lib=&olib);
			%if %error_handle(WarningOutputDataset, 
					&_ans EQ 1, mac=&_mac,		
					txt=! No data found for geo=&_ctry and time=_year !, verb=warn) %then %do;
				PROC DATASETS lib=&olib nolist;  delete &_odsn; quit; 
			%end;

		%end;
	%end;

	/* set the output */
	%if not %macro_isblank(_ctrylst_) %then %do;
		%let &_ctrylst_=&_ctries;
	%end;
	%if not %macro_isblank(_yearlst_) %then %do;
		%let &_yearlst_=&_years;
	%end;
	%if not %macro_isblank(_db_) %then %do;
		%let &_db_=&db;
	%end;
	/*data _null_;
		%if not %macro_isblank(_ctrylst_) %then %do;
			call symput("&_ctrylst_", "&_ctries");
		%end;
		%if not %macro_isblank(_yearlst_) %then %do;
			call symput("&_yearlst_", "&_years");
		%end;
		%if not %macro_isblank(_db_) %then %do;
			call symput("&_db_", "&db");
		%end;
	run;*/

	%exit:
%mend silc_ds_split;


%macro _example_silc_ds_split;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	DATA dbp;
		PB010=2016; PB020="AT"; PB030=1;  output;
		PB010=2016; PB020="AT"; PB030=2;  output;
		PB010=2016; PB020="AT"; PB030=3;  output;
		PB010=2016; PB020="BE"; PB030=4;  output;
		PB010=2016; PB020="BE"; PB030=5;  output;
		PB010=2016; PB020="BG"; PB030=6;  output;
		PB010=2016; PB020="BG"; PB030=7;  output;
		PB010=2015; PB020="AT"; PB030=14; output;
		PB010=2015; PB020="AT"; PB030=15; output;
		PB010=2015; PB020="BE"; PB030=8;  output;
		PB010=2015; PB020="BE"; PB030=9;  output;
		PB010=2015; PB020="BG"; PB030=10; output;
		PB010=2014; PB020="AT"; PB030=11; output;
		PB010=2014; PB020="BE"; PB030=12; output;
		PB010=2014; PB020="BE"; PB030=13; output;
	run;
		
	%let _ctries=;
	%let _years=;
	%silc_ds_split(_ALL_, _ALL_, dbp, odsn=test_, _ctrylst_=_ctries, _yearlst_=_years, ilib=WORK, olib=WORK);
	%put _ctries=&_ctries;
	%put _years=&_years;

%mend _example_silc_ds_split;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silc_ds_split; 
*/

/** \endcond */

