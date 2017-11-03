/** 
## silc_income_components_disaggregated {#sas_silc_income_components_disaggregated}
Retrieve (count) the occurrences of (dis)aggregated income variables in the input database. 

~~~sas
	%silc_income_components_disaggregated(geo, year, var, idsn=, level=, weight=, cond=FILLED,
		index=0 1 2 3 4, odsn=SUMMARY_INC, ilib=WORK, olib=WORK);
~~~

### Arguments
* `geo` : a list of countries or a geographical area; default: `geo=EU28`; 
* `year` : year of interest;
* `var` : list of (personal and household) income components to be considered for 
	disaggregation; 
* `index` : (_option_) index defining the disaggregated income component to analyse; it is
	any integer (or list of integers) in [0-4], where 0 means that the aggregated variable 
	will also be analysed; default: `index=0 1 2 3 4`, _i.e._ all disaggregated components 
	are analysed;
* `cond` : (_option_) flag/expression used to define which properties of the disaggregated
	variable is analysed; it can be:
		+ `MISSING` for counting the number of observations where the flag is 1;
		+ `NOTMISSING`, ibid for observations where the flag is NOT -1;
		+ `NULL` for counting the number of observations where either the variable or the flag
			are null (value =0),
		+ `NOTNULL`, ibid for observations where both the variable and the flag are non null 
			(value >0);
		+ `FILLED` for counting observations with non null variable (value >0) and observations 
			with non null flag (value >0);
 
* `idsn` : (_option_) name of the input dataset; when passed, all the variables listed in `var` 
	should be present in the dataset `idsn`; when not passed, the input dataset will be set
	automatically to the PDB for the given year and the type of the given variable (see macro
	[silc_db_locate](@ref sas_silc_db_locate)); default: not passed;
* `ilib` : (_option_) name of the input library passed together with `idsn`; default: not passed,
	_i.e._ set automatically to the library of the PDB;
* `weight` : !!! NOT IMPLEMENTED YET (_option_) personal weight variable used to weighting 
	the distribution; default: `weight=RB050a` !!!

### Returns
* `odsn` : (_option_) name of the output dataset; default: `odsn=SUMMARY_INC`;
* `olib` : (_option_) name of the output library; by default, when not set, `olib=WORK`.

### Notes
1. This macro simply counts the occurrences of disaggregated income components according to
the condition(s) expressed in `COND`. It does not use any `PROC FREQ` for instance.
2. The weight `weight` is currently not used.

### Reference
EU-SILC survey reference document [doc65](https://circabc.europa.eu/sd/a/2aa6257f-0e3c-4f1c-947f-76ae7b275cfe/DOCSILC065%20operation%202014%20VERSION%20reconciliated%20and%20early%20transmission%20October%202014.pdf).

### See also
[%silc_income_components_gini](@ref sas_silc_income_components_gini), [%silc_db_locate](@ref sas_silc_db_locate).
*/ /** \cond */

/* credits: grazzja */

%macro silc_income_components_disaggregated (geo			/* Area of interest 									(REQ) */
										, year		/* Year of interest 									(REQ) */
										, var 		/* Main (aggregated) income variable 					(OPT) */
										, index=	/* Index of disaggregated income variable 				(OPT) */
										/*, level=	 Level (household/personal) of the income variable 	(OPT) */
										/*, type=	 Type (Gross/Net) of income 							(OPT) */
										, cond=		/* Flag or SQL expression setting what is to be checked (OPT) */
										, weight= 	/* Weight variable										(OPT) */
										, pct=		/* Boolean flag used to return frequencies as %ages 	(OPT) */
										, idsn=		/* Input dataset name 									(OPT) */
										, ilib=		/* Input library name 									(OPT) */
										, odsn=		/* Output dataset name 									(OPT) */
										, olib=		/* Output library name 									(OPT) */
										);
	/* for ad-hoc works, load PING library if it is not yet the case */
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local G_YEARINIT 
		G_CHECK G_INDEXES 
		G_ALLVAR G_ALLHVAR G_ALLPVAR
		type	
		isGeo Pvar Hvar
		existsOutput existsInput
		ndisagg nvar ntype _ok pref;

	/* modify the values below if... */
	%let G_INDEXES=0 1 2 3 4; 							/* ...a new disaggregated income component... */
	%let G_ALLHVAR=HY050 HY060 HY070;					/* ...a new aggregated household income component... */
	%let G_ALLPVAR=PY090 PY100 PY110 PY120 PY130 PY140;	/* ...a new aggregated personal income component... */
	/* ...is added in the future */
	%let G_CHECKS = MISSING NOTMISSING NOTNULL NULL FILLED;

	%let G_YEARINIT=2002;								/* EU-SILC starting data... more or less */
	%let G_ALLVAR=&G_ALLHVAR &G_ALLPVAR;				/* just concatenate the values */
	%let isGeo=;
	%let Pvar=; %let Hvar=;
	%let existsInput=NO;	%let existsOutput=NO;

	/* ILIB/IDSN: check/set default output  */
	%if %macro_isblank(ilib) NE 1 or %macro_isblank(idsn) NE 1 %then %do;
		/* we assume that in some case just IDSN is passed */
		%if %macro_isblank(ilib) %then 				%let ilib=WORK;
		/* check whether the input dataset ILIB.IDSN is defined */
		%if %error_handle(ExistingDataset, 
				%ds_check(&idsn, lib=&ilib) NE 0, mac=&_mac,
				txt=%bquote(!!! Input table &idsn not found !!!)) %then 
			%goto exit; 
		%let existsInput=YES;
	%end;

	/* OLIB/ODSN: check/set default output  */
	%if %macro_isblank(olib) %then 				%let olib=WORK;				/* assign default library */
	%if %macro_isblank(odsn) %then 				%let odsn=SUMMARY_INC;		/* assign default output name */
	%else 										%let odsn=%upcase(&odsn);	/* upcase the name in any case */
	
	/* check whether the output dataset ODSN already exists; if so, warns that it will be replaced */
	%if %error_handle(ExistingOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,
			txt=%bquote(! Output table &odsn already exists - Table will be overwritten !),verb=warn) %then %do;
		%let existsOutput=YES;
		%goto warning1; 
	%end;
	%warning1:
		
	/* GEO: check/set */
	%if %macro_isblank(geo) %then	%let geo=EU28; /* default area zone */
	%if "&geo" NE "_ALL_" %then %do;
		/* for a given list GEO of ISO-codes, %STR_ISGEO returns (in ISGEO):
		*	- 2 in the position of EU areas' codes,
		*	- 1 in the position of countries' codes,
		* 	- 0 in the position of unrecognised/wrong codes */
		%str_isgeo(&geo, _ans_=isGeo, _geo_=geo);
		/* check for the presence of: 
		*	(1) wrong codes (then exit), 
		*	(2) EU area codes (then replace the area by the list of countries belonging to these areas) */
		%if %error_handle(ErrorInputParameter, 
				/*(1)*/ %list_count(&isGeo, 0) NE 0, mac=&_mac,		
				txt=%quote(!!! Wrong parameter GEO: must be country/geographical zone ISO code(s) !!!)) %then
			%goto exit;
		%else %if /*(2)*/ %list_count(&isGeo, 2) NE 0 %then %do; 
			%local ctry;
			%zone_replace(&geo, _ctrylst_=ctry); /* replace given areas by countries belonging to them */
			%let geo=%list_unique(&ctry &geo); 	/* avoid duplication of ISO-codes inside the list */
		%end;
		/* at this stage, the GEO list should contain ISO-codes of countries only */
	%end;
	/* %else: we leave the case GEO=_ALL_ for later (see call to %var_to_list inside the loop below) ... */

	/* YEAR: check/set */
	%if %symexist(G_PING_INITIAL_YEAR) %then 	%let yearinit=&G_PING_INITIAL_YEAR;
	%else										%let yearinit=&G_YEARINIT;
	
	/* check that YEAR>YEARINIT, i.e. it is in the range ]YEARINIT, infinity[ */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&year, type=INTEGER, range=&yearinit) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for input YEAR !!!)) %then
		%goto exit;

	/* TYPE: as for today, income disaggregated components are G only... who knows in the future? */
	%let type=G; 
	/* %if %macro_isblank(type) %then		%let type=G;	
	%else 								%let type=%upcase(&type);	
	%let ntype=%list_length(&type);
	%let _ok=%list_ones(&ntype, item=0); 
	%if %error_handle(ErrorInputParameter, 
			%par_check(&type, type=CHAR, set=N G) NE &_ok, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for income: TYPE must be Gross (G) and/or Net (N) !!!)) %then
		%goto exit;*/

	/* COND: check/set */
	%if %macro_isblank(cond) %then		%let cond=NOTNULL;			/* assign default operation: NOTNULL */
	%else 								%let cond=%upcase(&cond);	/* upcase the name in any case */

	/* INDEX: check/set default */
	%if %macro_isblank(index) %then		%let index=&G_INDEXES;		/* assign default type: all indexes */
	%else %if "&index"="_ALL_" %then	%let index=&G_INDEXES;

	/* how many indexes were provided?  */
	%let ndisagg=%list_length(&index);
	/* for each income variable there will be therefore NDISAGG disaggregated components
	* calculated */

	/* check that INDEX is actually an integer with values in G_INDEXES (e.g., 0, 1, 2, 3, or/and 4) */
	%let _ok=%list_ones(&ndisagg, item=0); /* a list composed of as many 0 as there are items in INDEX */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&index, type=INTEGER, set=&G_INDEXES) NE &_ok, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for INDEX: must be an integer in &G_INDEXES !!!)) %then
		%goto exit;

	/* LEVEL: check/set default
	%if %macro_isblank(level) %then		%let level=%substr(&var,1,1);
	%else 								%let level=%upcase(&level);
	* check that LEVEL is actually any of the characters P or H;
	%if %error_handle(ErrorInputParameter, 
			%par_check(&level, type=CHAR, set=P H) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for LEVEL: must be Household (H) or Personal (P) !!!)) %then
		%goto exit; */

	/* VAR: check variable */
	%if %macro_isblank(var) %then		%goto exit;

	/* check that VAR is any of the variables listed in either G_ALLHVAR or G_ALLPVAR above, also 
	* depending on the LEVEL type */
	%if %error_handle(ErrorInputParameter, 
			%list_difference(&var, &G_ALLVAR) NE , mac=&_mac,		
			txt=%bquote(!!! Unrecognised income component - Must be in &G_ALLVAR !!!)) %then
		%goto exit;

	/* PCT: check/set default */
	%if %macro_isblank(pct) %then		%let pct=NO;
	%else 								%let pct=%upcase(&pct);

	/* check that PCT is an actual boolean flag */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&pct, type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for boolean flag PCT: must be YES or NO !!!)) %then
		%goto exit;

	/* set the prefix of the output variables */
	%if "&pct" EQ "YES" %then		%let pref=PCT;
	%else				 			%let pref=SUM;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _iy _i _j
		_vard _var lvar
		_cond _cond_F
		_firstc _lastc
		ipath append;
	%let _vard=;

	%macro components_disaggregate(var, level);

		/* how many variables are provided?  */
		%let nvar=%list_length(&var);

		/* loop over the list of input years */
		%do _iy=1 %to %list_length(&year);		

			/* define current year */
			%let yyyy=%scan(&year, &_iy);
			/* extract the last 2 digits of YEAR; e.g., if YYYY=2015, then YY=15 */
			%let yy=%substr(&yyyy,3,2);	

			/* in the case no input dataset has been passed, we retrieve the original PDB 
			* location in our server */
			%if "&existsInput"="NO" %then %do;
				%let ipath=; %let idsn=;
				%silc_db_locate(X, &yyyy, src=pdb, db=&level, _ds_=idsn, _path_=ipath);
				/* allocate the library to the path where the PDB is located */
				libname pdb "&ipath";
				%let ilib=pdb;
			%end;

			/* remember that we did not solve the case GEO=_ALL_? here it is... */
			%if "&geo" EQ "_ALL_" %then %do; 
				/* note that we will enter this loop once at most */
				%let geo=;
				/* %VAR_TO_LIST will retrieve the list of all distinct countries available
				* in the input dataset */
				%var_to_list(&ds, &level.B020, _varlst_=geo, distinct=YES, lib=pdb);
			%end;

			/* loop over the list of input variables  */
			%do _i=1 %to &nvar;

				/* define current variable */
				%let _var=%scan(&var, &_i);
				%let lvar=%length(&_var); 							/* length of variable name */
				%let _pvar=%substr(&_var, 1, %eval(&lvar-1));		/* substring _PVAR minus the last char */
				%let _lastc=%substr(&_var, &lvar, 1);	/* last char */
				/* the last char in its name */
				%if "&_lastc" NE "0" %then 			/* if last char is ), we leave _PVAR as is */
					%let _pvar=&_pvar.&_lastc;

				%do _j=1 %to &ndisagg;

					/* define current disaggregated component (or the aggregated one if 0 is in the list) */
					%let _vard=&_pvar%scan(&index, &_j)&type;

					/* we first check whether the variable actually exists in the dataset or not */			
					%if %error_handle(ErrorInputParameter, 
							%var_check(&idsn, &_vard, lib=&ilib) NE 0, mac=&_mac,		
							txt=%quote(! Variable &_vard not found in dataset &idsn !), verb=warn) %then
						%goto next; /* skip this variable: go to the next iteration in the loop */

					%if "&cond"="MISSING" %then %do;
						%let _cond=%quote(&_vard._F EQ -1);
						%let _cond_F=&_cond;
					%end;
					%else %if "&cond"="NOTMISSING" %then %do;
						%let _cond=%quote(&_vard._F NE -1);
						%let _cond_F=&_cond;
					%end;
					%else %if "&cond"="NULL" %then %do;
						%let _cond=%quote(&_vard EQ 0 or &_vard._F EQ 0);
						%let _cond_F=&_cond;
					%end;
					%else %if "&cond"="NOTNULL" %then %do;
						%let _cond=%quote(&_vard GT 0 and &_vard._F GT 0);
						%let _cond_F=&_cond;
					%end;
					%else %if "&cond"="FILLED" %then %do;
						%let _cond=%quote(&_vard GT 0);
						%let _cond_F=%quote(&_vard._F GT 0);
					%end;
					%else %do;
						%let cond_F=&cond;
					%end;

					/* here comes the main operation: counting... */
					PROC SQL noprint;
						CREATE TABLE WORK.&pref._&level._&_vard AS 
						SELECT DISTINCT
							&level.B010 AS TIME, 
							&level.B020 AS GEO, 
							/* &_var, */
							%if "&pct" EQ "YES" %then %do;
								count(&level.B030)/100 AS nobs,
							%end;
							%else %do;
								1 AS nobs, 
							%end;
							SUM(CASE WHEN &_cond	THEN 1 ELSE 0 END) / (calculated nobs) AS &pref._&_vard,
							SUM(CASE WHEN &_cond_F THEN 1 ELSE 0 END) / (calculated nobs) AS &pref._&_vard._F
						FROM &ilib..&idsn as p
						WHERE &level.B010=&yyyy and &level.B020 in %sql_list(&geo)
						GROUP BY &level.B020;
					quit;

					PROC SQL noprint;
						%if &_iy=1 and &_i=1 and &_j=1 and "&toBeCreated" EQ "YES" %then %do;			
							CREATE TABLE &olib..&odsn AS
							SELECT 
								TIME, GEO, &pref._&_vard, &pref._&_vard._F
							FROM &pref._&level._&_vard;
						%end;
						%else %do;
							ALTER TABLE &olib..&odsn
							ADD &pref._&_vard num, &pref._&_vard._F num;
							
							UPDATE &olib..&odsn t1
							SET &pref._&_vard= (
									SELECT DISTINCT &pref._&_vard
									FROM &pref._&level._&_vard AS t2
									WHERE (t2.TIME = t1.TIME) AND (t2.GEO = t1.GEO)
								),
								&pref._&_vard._F = (
									SELECT DISTINCT &pref._&_vard._F
									FROM &pref._&level._&_vard AS t2
									WHERE (t2.TIME = t1.TIME) AND (t2.GEO = t1.GEO)
								)
							;
						%end;
					quit;

					%work_clean(&pref._&level._&_vard);
					%next:
				%end;
			%end;

			/* deallocate the libraries */
			%if "&existsInput"="NO" %then %do;
				libname &ilib clear;
			%end;

		%end;

		%let toBeCreated=NO; 
	%mend components_disaggregate;

	/* extract the list of P/H variables from the input list and reorder... */
	%do _i=1 %to %list_length(&var);
		%let _var=%scan(&var, &_i);
		%if "%upcase(%substr(&_var,1,1))" EQ "P" %then 			%let Pvar = &Pvar &_var;
		%else %if "%upcase(%substr(&_var,1,1))" EQ "H" %then 	%let Hvar = &Hvar &_var;
	%end;

	%let toBeCreated=YES; /*=%ds_check(&odsn, lib=&olib)*/
	%if %macro_isblank(Pvar) EQ 0 %then %do; 
		%components_disaggregate(&Pvar, P);
	%end;
	%if %macro_isblank(Hvar) EQ 0 %then %do; 
		%components_disaggregate(&Hvar, H);
	%end;

	%exit:
%mend silc_income_components_disaggregated;

/** \endcond */
