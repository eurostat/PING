/** 
## pension_population_count {#sas_pension_population_count}
Count the number of pensioners and/or retired people of a given citizenship abroad, or in a 
given country by citizenship. 

	%pension_population_count(geo, year, zone=, idir=, ilib=, odsn=, olib=);

### Arguments
* `geo` : a country code whose population is considered: both retired/pensioned people:
		+ with the citizenship of this country,
		+ with any citizenship but living in this country,

	are considered; 
* `year` : year of interest;
* `zone` : (_option_) a list of countries or a geographical area; default: `geo=EU28`;
* `ilib` : (_option_) name of the input library where to look for _AROPE_ indicators (see 
	note below); incompatible with `idir`; by default, `ilib` will be set to the value 
	`G_PING_LIBCRDB` (_e.g._, library associated to the path `G_PING_C_RDB`); 
* `idir` : (_option_) name of the input directory where to look for _AROPE_ indicators passed 
	instead of `ilib`; incompatible with `ilib`; by default, it is not used; 
* `odsn` : (_option_) generic name of the output datasets; default: `odsn=THS_POP`;
* `olib` : (_option_) name of the output library; by default, when not set, `olib=WORK`;

### Returns
9 datasets are generated:
* `&odsn._RET_&geo._IN_FOR_&yy`, `&odsn._PEN_&geo._IN_FOR_&yy` and `&odsn._PENRET_&geo._IN_FOR_&yy` 
	contain the tables with total and sample populations of `geo`-national people (_i.e._ 
	with citizenship `PB220A=&geo`) living "abroad" (any foreign country) and who are 
	_retired_, _pensioned_ and either of those two  (_retired or pensioned_) respectively 
	(grouped by country of residence),
* `&odsn._RET_FOR_IN_&geo._&yy`, `&odsn._PEN_FOR_IN_&geo._&yy` and `&odsn._PENRET_FOR_IN_&geo._&yy` 
	contain the tables with total and sample populations of foreign people living in `geo` 
	(_i.e._ `PB020=geo`) and who are _retired_, _pensioned_ and either of those two 
	respectively (grouped by country of citizenship),
* `&odsn._RET_ZONE_IN_&geo._&yy`, `&odsn._PEN_ZONE_IN_&geo._&yy` and `&odsn._PENRET_ZONE_IN_&geo._&yy` 
	contain the tables with total and sample aggregated populations of foreign `zone`-national 
	people living in `geo` (_i.e._ with citizenship `PB220A in &zone`, at the exclusion of 
	`geo`, and `PB020=&geo`) and who are _retired_, _pensioned_ and either of those two 
	respectively (aggregated figure),

(where `yy` represents the last two digits of `year`, and with `odsn` and `geo` upcased when not 
already) all stored in the library passed through `olib`.

### Example
In order to generate the tables `POP_PENRET_FOR_IN_UK_14` and `POP_PENRET_UK_IN_FOR_14` 
of total populations of, respectively, foreign _pensioned or retired_ people living in UK and UK-national
_pensioned or retired_ people living abroad, and similarly for 2015, like in the request below:

<img src="img/pension_population_count.png" border="1" width="60%" alt="pension population count">

you can simply launch:

	%pension_count(2014, UK, zone=EU28);
	%ds_export(THS_POP_PENRET_FOR_IN_UK_14, fmt=csv);
	%ds_export(THS_POP_PENRET_UK_IN_FOR_14, fmt=csv);
	%pension_count(2015, UK, zone=EU28);
	%ds_export(THS_POP_PENRET_FOR_IN_UK_15, fmt=csv);
	%ds_export(THS_POP_PENRET_UK_IN_FOR_15, fmt=csv);

then similarly with year 2015. 

### Note
The status of a personed is evaluated as:
* _retired_ when `PL031 = 7`,
* _pensioned_ when `(PY035G>0 or PY080G>0 or PY100G>0 or PY110G>0)`,
* either _retired or pensioned_ when any of the cases above occurs.
*/ /** \cond */

/* credits: grazzja, grillma */

%macro pension_population_count(geo			/* Citizenship/country of interest 	(REQ) */
								, year		/* Year of interest 				(REQ) */
								, zone=		/* Area of interest 				(OPT) */
								, idir=		/* Input directory name				(OPT) */
								, ilib=		/* Input library name 				(OPT) */
								, odsn=		/* Generic output dataset name 		(OPT) */
								, olib=		/* Output library name 				(OPT) */
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

	%local yy;

	/* YEAR: check/set */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&year, type=INTEGER, range=%eval(2003)) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for input YEAR !!!)) %then
		%goto exit;
	%else
		%let yy=%substr(&year,3,2);
		
	/* ZONE: check/set */
	%local ans ctry;
	%if %macro_isblank(zone) %then	%let zone=EU27 EU28;
	%str_isgeo(&zone, _ans_=ans, _geo_=zone);
	%if %error_handle(ErrorInputParameter, 
			%list_count(&ans, 0) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong parameter ZONE: must be country/geographical zone ISO code(s) !!!)) %then
		%goto exit;
	%else %if %list_count(&ans, 2) %then %do;
		%zone_replace(&zone, _ctrylst_=ctry);
		%let zone=%list_unique(&ctry &zone);
	%end;

	/* IDIR/ILIB: check/set default input library */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(idir) EQ 0 and %macro_isblank(ilib) EQ 0, mac=&_mac,
			txt=%quote(!!! Incompatible parameters IDIR and ILIB: set one only !!!)) %then
		%goto exit;
	%else %if not %macro_isblank(idir) %then %do;
		%let islibtemp=1;
		libname lib "&idir"; 
		%let ilib=lib;
	%end;
	%else %if %macro_isblank(ilib) %then %do;
		%let islibtemp=0;
		%if %symexist(G_PING_LIBPDB) %then 		%let ilib=&G_PING_LIBPDB;
		%else %do;
			libname pdb "/ec/prod/server/sas/0eusilc/pdb"; /* "&G_PING_PDB" */
			%let ilib=pdb;
		%end;
	%end;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(c&yy.p, lib=&ilib) NE 0, mac=&_mac,		
			txt=%quote(!!! Input dataset C&yy.P not found in library %upcase(&ilib) !!!)) %then
		%goto exit;

	/* OLIB/ODSN: check/set default output  */
	%if %macro_isblank(olib) %then 				%let olib=WORK;
	%if %macro_isblank(odsn) %then 				%let odsn=THS_POP;
	%else 										%let odsn=%upcase(&odsn);

	/* GEO */
	%let geo=%upcase(&geo);
	%let zone=%upcase(&zone);

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local FLAG_RET;
	%let FLAG_RET=7;

	%macro count_presence(name, what=, who=, where=, by=);
		PROC SQL;
	   		CREATE TABLE &olib..&odsn._&what._&name._&yy AS 
	   		SELECT DISTINCT 
				PB010, 
	   			%if &by^=PB010 %then %do;
       				&by, 
				%end;
	            (SUM(PB040)) FORMAT=8.0 AS NBR_&what,
	            (COUNT(PB030)) AS COUNT_of_PB030
	      	FROM &ilib..c&yy.p 
	      	WHERE 
			%if not %macro_isblank(who) %then %do;
				PB220A in (%list_quote(&who)) and
			%end;
			%if not %macro_isblank(where) %then %do;
				PB020 in (%list_quote(&where)) and
			%end;
			%if "&what"="PENRET" %then %do;
				(
			%end;
			%if "&what"="PENRET" or "&what"="RET" %then %do;
				PL031 = &FLAG_RET
			%end;
			%if "&what"="PENRET" %then %do;
				or
			%end;
			%if "&what"="PENRET" or "&what"="PEN" %then %do;
				(PY035G>0 or PY080G>0 or PY100G>0 or PY110G>0)
			%end;
			%if "&what"="PENRET" %then %do;
				)
			%end;
	      	GROUP BY &by;
		quit;
	%mend;

	%count_presence(&geo._IN_FOR, 
					what= 	RET/*IRED*/,
					who=	&geo, 
					/* where=	&zone, */
					by=		PB020);

	%count_presence(FOR_IN_&geo, 
					what= 	RET/*IRED*/,
					where=	&geo, 
					by=		PB220A);

	%count_presence(ZONE_IN_&geo, 
					what= 	RET/*IRED*/,
					who=	%list_difference(&zone, &geo), 
					where=	&geo, 
					by=		PB010);

	%count_presence(&geo._IN_FOR, 
					what= 	PEN/*SIONED*/,
					who=	&geo, 
					/* where=	&zone, */
					by=		PB020);

	%count_presence(FOR_IN_&geo, 
					what= 	PEN/*SIONED*/,
					where=	&geo, 
					by=		PB220A);

	%count_presence(ZONE_IN_&geo, 
					what= 	PEN/*SIONED*/,
					who=	%list_difference(&zone, &geo), 
					where=	&geo, 
					by=		PB010);

	%count_presence(&geo._IN_FOR, 
					what= 	PENRET/*PENSIONED_OR_RETIRED*/,
					who=	&geo, 
					/* where=	&zone, */
					by=		PB020);

	%count_presence(FOR_IN_&geo, 
					what= 	PENRET/*PENSIONED_OR_RETIRED*/,
					where=	&geo, 
					by=		PB220A);

	%count_presence(ZONE_IN_&geo, 
					what= 	PENRET/*PENSIONED_OR_RETIRED*/,
					who=	%list_difference(&zone, &geo), 
					where=	&geo, 
					by=		PB010);

	%exit:
%mend pension_population_count;

/** \endcond */

