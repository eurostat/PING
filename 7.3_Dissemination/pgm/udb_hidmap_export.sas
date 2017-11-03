/** 
## udb_hidmap_export {#sas_udb_hidmap_export}

~~~sas
	%udb_hidmap_export(geo, time, map, r_map=, ofn=, idir=, odir=, ilib=WORK);
~~~

### Arguments
* `geo` : list of desired countries ISO-codes		
* `time` : list of desired years 					
* `map` : input dataset 
* `r_map` : 	
* `idir` : 	
* `ilib` : 

### Returns
* `ofn` : 
* `odir` : 

### See also
[%ds_select](@ref sas_ds_select), [%ds_export](@ref sas_ds_export), 
[%ds_contents](@ref sas_ds_contents), [%var_to_list](@ref sas_var_to_list).
*/ /** \cond */

/* credits: grazzja */

%macro udb_hidmap_export(geo		/* List of extracted countries ISO-codse 	(REQ) */
						, time		/* List of extracted years 					(REQ) */
						, map		/* Input household ID mapping dataset 		(REQ) */
						, r_map=	/* Input personal ID mapping dataset 		(OPT) */
						, ofn=		/* Generic output filename					(OPT) */
						, idir=		/* input directory 							(OPT) */
						, ilib= 	/* Input library 							(OPT) */
						, odir=		/* Output directory 						(OPT) */
						, fmt=		/* Output format 							(OPT) */
						, mkdir=	/* Flag forcing output folder creation		(OPT) */
						);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %macro_isblank(geo) or %macro_isblank(time) or %macro_isblank(map) %then 
		%goto exit;

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local ntime  _ctries __ans
		isTemplib
		G_YEARINIT 
		G_HIDPERS;
	%let isTemplib=0;
	%let G_YEARINIT=2002;
	%let G_HIDPERS=2014;   /* First year that personal hidden mappings were implemented */

	/* FMT: currently only csv is supporred*/
	%if %macro_isblank(fmt) %then 					%let fmt=CSV;
	%else 											%let fmt=%upcase(&fmt);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&fmt, type=CHAR, set=CSV DTA) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong types/values for input FMT format !!!)) %then
		%goto exit;

	/* GEO: check/set */
	%if "&geo" NE "_ALL_" %then %do;
		%local isGeo;
		%str_isgeo(&geo, _ans_=isGeo, _geo_=_ctries);
		%if %error_handle(ErrorInputParameter, 
				%list_count(&isGeo, 0) NE 0, mac=&_mac,		
				txt=%quote(!!! Wrong parameter GEO: must be country/geographical zone ISO code(s) !!!)) %then
			%goto exit;
		%else %if %list_count(&isGeo, 2) NE 0 %then %do; 
			%zone_replace(&_ctries, _ctrylst_=_ctries); 
			%let _ctries=%list_unique(&_ctries); 
		%end;
	%end;

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

	/* ILIB/IDIR/MAP: check/set default */
	%if %error_handle(ErrorInputDataset, 
			%macro_isblank(ilib) EQ 0 and %macro_isblank(idir) EQ 0, mac=&_mac,		
			txt=!!! Incompatible options IDIR and ILIB !!!) %then
		%goto exit;
	%else %if %macro_isblank(ilib) and %macro_isblank(idir) %then 					
		%let ilib=WORK;
	%else %if %macro_isblank(ilib) %then %do;
		%let isTemplib=1;
		libname _tmplib "&idir";
		%let ilib=_tmplib;
	%end;

	/* check the existence of the dataset */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&map, lib=&ilib) NE 0, mac=&_mac,		
			txt=!!! Input household ID mapping dataset %upcase(&map) not found !!!) %then
		%goto quit;

	%if not %macro_isblank(r_map) %then %do;
		%if %error_handle(ErrorInputDataset, 
				%ds_check(&r_map, lib=&ilib) NE 0, mac=&_mac,		
				txt=!!! Input personal ID mapping dataset %upcase(&map) not found !!!) %then
			%goto quit;
		
	%end;

	/* ODIR/OFN: checking */
	%if %macro_isblank(odir) %then 					%let odir=%sysfunc(pathname(&ilib));
	%if %macro_isblank(ofn) %then 					%let ofn=HIDMAP_X; /*&map._;*/

	%if %macro_isblank(mkdir) %then 				%let mkdir=NO;
	%else 											%let mkdir=%upcase(&mkdir);

	%let __ans=%dir_check(&odir, mkdir=&mkdir);
	%if "&mkdir"="YES" %then %do;
		%if %error_handle(WarningOutputDirectory, 
			&__ans NE 0, mac=&_mac,		
			txt=%quote(! Output directory %upcase(&odir) not found - Will be created !), verb=warn) %then
		%goto warning0;
	%end;
	%else %do;
		%if %error_handle(ErrorOutputDirectory, 
			&__ans NE 0, mac=&_mac,		
			txt=%quote(!!! Output directory %upcase(&odir) not found !!!)) %then
		%goto quit;
	%end;
	%warning0:

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _l _c _b _y 
		_vars _where _diff
		_years _year _ctry;

	/* retrieve the list _VARS of variables in the dataset MAP */
	%let _vars=;
	%ds_contents(&map, _varlst_=_vars, lib=&ilib);

	/* check the existence of the variables of interest: DB010 DB020 DB030 R_DB030 */
	%if %error_handle(ErrorMissingVariable, 
			"%list_difference(DB010 DB020 DB030 R_DB030, &_vars)" NE "", mac=&_mac,		
			txt=%bquote(!!! One variable, at least, among DB010, DB020, DB030, R_DB030 is missing in &map !!!))  %then
		%goto quit;

	/* similarly, check for the existence of the RB010 RB020 RB030 R_RB030 variables in the personal
		* hidden mapping dataset */
	%if not %macro_isblank(r_map) %then %do;
		%let _vars=;
		%ds_contents(&r_map, _varlst_=_vars, lib=&ilib);
		%if %error_handle(ErrorMissingVariable, 
				"%list_difference(RB010 RB020 RB030 R_RB030, &_vars)" NE "", mac=&_mac,		
				txt=%bquote(!!! One variable, at least, among RB010, RB020, RB030, R_RB030 is missing in &r_map !!!))  %then
			%goto quit;
	%end;

	/* retrieve the list _YEARS of available years (1 per file in principle... who knows, that may
	* change!) */
	%var_to_list(&map, DB010, _varlst_=_years, distinct=YES, lib=&ilib);
	/* check that the desired TIME years are present in the dataset */ 
	%if "&time" NE "_ALL_" %then %do;
		%let _diff=%list_difference(&time, &_years);
		%if %error_handle(ErrorMissingData,  
				&_diff EQ &time, mac=&_mac,		
				txt=%quote(! No year in &time found in the dataset !)) %then
			%goto quit;
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
		%var_to_list(&map, DB020, _varlst_=_ctries, distinct=YES, lib=&ilib); 
	%end;
	
	/* generic macro used for extraction and export of mappings of interest */
	%macro _hidmap_selectAndExport(_imap, _level, vartype);
		%local _ofn _level _yy _maptmp;
		%let _maptmp=_TMP_HIDMAP_;
		/* variables: ofn, _ctry, _year are defined outside */

		/* define the condition _WHERE for the extraction of the correct data */
		%let _where=%quote(&vartype.B020 EQ "&_ctry" and &vartype.B010 EQ &_year);
		/* extract the data into new temporary dataset &_MAPTMP */
		%ds_select(&_imap, &_maptmp 
					, where=&_where, all=NO
					, var=&vartype.B010 &vartype.B020 &vartype.B030 R_&vartype.B030
					, ilib=&ilib, olib=WORK);
		/* in place of: 
		PROC SQL;
		   	CREATE TABLE WORK.&_maptmp AS 
		   	SELECT &vartype.B010, &vartype.B020, &vartype.B030, R_&vartype.B030 
			FROM &ilib..&_imap 
	      	WHERE &vartype.B020 = "&ctry";
		quit; */

		/* define the output file name _OFN using the generic OFN argument */
		%let _level=_%upcase(&_level)_;
		%let _yy=%substr(&_year,3,2);
		%let _ofn=&_ctry.&_level.&ofn.-&_yy;

		/* export the data for given TIME/GEO into the file _OFN of the desired ODIR folder */
		%ds_export(&_maptmp, odir=&odir, ofn=&_ofn, fmt=&fmt, ilib=WORK);
		/* in place of: 
		PROC EXPORT data=WORK.&_maptmp
		  	OUTFILE="&odir/&ctry._PERS_HIDMAP_X-&year..csv"
		   	DBMS=&fmt REPLACE;
		run; */
		
		/* clean your shit */
		%work_clean(&_maptmp);
	%mend _hidmap_selectAndExport;

	%do _y=1 %to %list_length(&_years);
		/* which year: that's in _YEAR ... */
		%let _year=%scan(&_years, &_y);
		/* extract the last 2 digits of current year into _YY */
		%let _yy=%substr(&_year,3,2);

		%do _c=1 %to %list_length(&_ctries);
			/* which country: that's in _CTRY ... */
			%let _ctry=%scan(&_ctries, &_c);
	
			%_hidmap_selectAndExport(&map, HH, D);
	
			%if not %macro_isblank(r_map) %then %do;
				%if %error_handle(WarningInputParameter, 
						&_year LT &G_HIDPERS, mac=&_mac,		
						txt=%quote(! Personal HID mapping not defined for year prior to &G_HIDPERS !), verb=warn) %then
					%goto next;
				/* %else... */
				%_hidmap_selectAndExport(&r_map, PERS, R);
			%end;

			%next:
		%end;
	%end;

	%quit:
	%if &isTemplib=1 %then %do;
		libname _tmplib clear;
	%end;

	%exit: 
%mend udb_hidmap_export;

%macro _example_udb_hidmap_export;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	DATA dbd;
		DB010=2016; DB020="AT"; DB030=1;  R_DB030=10;  output;
		DB010=2016; DB020="AT"; DB030=2;  R_DB030=20;  output;
		DB010=2016; DB020="AT"; DB030=3;  R_DB030=30;  output;
		DB010=2016; DB020="BE"; DB030=4;  R_DB030=40;  output;
		DB010=2016; DB020="BE"; DB030=5;  R_DB030=50;  output;
		DB010=2016; DB020="BG"; DB030=6;  R_DB030=60;  output;
		DB010=2016; DB020="BG"; DB030=7;  R_DB030=70;  output;
		DB010=2015; DB020="AT"; DB030=14; R_DB030=140; output;
		DB010=2015; DB020="AT"; DB030=15; R_DB030=150; output;
		DB010=2015; DB020="BE"; DB030=8;  R_DB030=80;  output;
		DB010=2015; DB020="BE"; DB030=9;  R_DB030=90;  output;
		DB010=2015; DB020="BG"; DB030=10; R_DB030=100; output;
		DB010=2014; DB020="AT"; DB030=11; R_DB030=110; output;
		DB010=2014; DB020="BE"; DB030=12; R_DB030=120; output;
		DB010=2014; DB020="BE"; DB030=13; R_DB030=130; output;
	run;

	%let odir=&G_PING_ROOTPATH/test/DUMMY/;
	%let idsn=dbd;
	%udb_hidmap_export(_ALL_, _ALL_, dbd, ilib=WORK, odir=%quote(&odir));

	/* another example with real hidmap, and using IDIR this time:
	%let idir=&G_PING_ROOTPATH/7.3_Dissemination/data/hidmap/;
	%let idsn=C15_hidmap_release_17_03;
	%udb_hidmap_export(_ALL_, _ALL_, &idsn, idir=&idir, odir=%quote(&odir)); */

%mend _example_udb_hidmap_export;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_udb_hidmap_export; 
*/

/** \endcond */

