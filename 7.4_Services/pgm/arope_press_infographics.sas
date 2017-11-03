/** 
## arope_press_infographics {#sas_arope_press_infographics}
Perform ad-hoc extraction for infographics publication on _AROPE_ on the occasion of the 
_International Day for the Eradication of Poverty_. 

	%arope_press_infographics(year, geo=, ilib=, idir=, odsn=, olib=);

### Arguments
* `year` : a (single) year of interest;
* `geo` : (_option_) a list of countries or a geographical area; default: `geo=EU28`;
* `ilib` : (_option_) name of the input library where to look for _AROPE_ indicators (see 
	note below); incompatible with `idir`; by default, `ilib` will be set to the value 
	`G_PING_LIBCRDB` (_e.g._, library associated to the path `G_PING_C_RDB`); 
* `idir` : (_option_) name of the input directory where to look for _AROPE_ indicators passed 
	instead of `ilib`; incompatible with `ilib`; by default, it is not used; 
* `odsn` : (_option_) generic name of the output datasets; default: `odsn=PC_AROPE`;
* `olib` : (_option_) name of the output library; by default, when not set, `olib=WORK`;

### Returns
Two datasets are generated:
* `&odsn._TOTAL_&yy` contains the _AROPE_ table with shares of total population,
* `&odsn._RESULTS_&yy` contains the _AROPE_ table with combined shares by sex, by age, 
	by working status (from 2015 publication onwards) by household composition, and 
	by education attainment level,

(where `yy` represents the last two digits of `year`) all stored in the library passed 
through `olib`.

### Example
In order to (re)generate the tables `PC_AROPE_15`, `PC_AROPE_RESULTS_15` and `PC_AROPE_TOTAL_15`, 
used for the graphic representations of the 2015 infographics publication below: 

<img src="img/arope_press_infographics.png" border="1" width="60%" alt="AROPE infographics">

you can simply launch:

	%arope_press_infographics(2015);
	%ds_export(PC_AROPE_RESULTS_15, fmt=csv);
	%ds_export(PC_AROPE_TOTAL_15, fmt=csv);

### Note
The publication is based on the following _AROPE_ indicators:
* _PEPS01_ for the total shares, shares by sex and shares by age,
* _PEPS02_ for the shares by working status,
* _PEPS03_ for the shares by household composition,
* _PEPS04_ for the shares by education attainment level. 

### References
1. Website of the UN initiative for the _International Day for the Eradication of Poverty_: 
http://www.un.org/en/events/povertyday.
2. Websites of infographics publications on _AROPE_: 
[2015](http://ec.europa.eu/eurostat/news/themes-in-the-spotlight/poverty-day),
[2016](http://ec.europa.eu/eurostat/news/themes-in-the-spotlight/poverty-day-2016),  and
[2017](http://ec.europa.eu/eurostat/news/themes-in-the-spotlight/poverty-day-2017).
3. Statistics explained on [poverty and social exclusion](http://ec.europa.eu/eurostat/statistics-explained/index.php/People_at_risk_of_poverty_or_social_exclusion).

### See also
[%arope_press_news](@ref sas_arope_press_news).
*/ /** \cond */

/* credits: grazzja */

%macro arope_press_infographics(year	/* Year of interest 			(REQ) */
								, geo=	/* Area of interest 			(OPT) */
								, idir=	/* Input directory name			(OPT) */
								, ilib=	/* Input library name 			(OPT) */
								, odsn=	/* Generic output dataset name 	(OPT) */
								, olib=	/* Output library name 			(OPT) */
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

	%local ans ctry 
		isLibTemp;
	%let isLibTemp=0;

	/* YEAR: check/set */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&year, type=INTEGER, range=2003) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for input YEAR !!!)) %then
		%goto exit;

	/* GEO: check/set */
	%if %macro_isblank(geo) %then	%let geo=EU27 EU28;
	%str_isgeo(&geo, _ans_=ans, _geo_=geo);
	%if %error_handle(ErrorInputParameter, 
			%list_count(&ans, 0) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong parameter GEO: must be country/geographical zone ISO code(s) !!!)) %then
		%goto exit;
	/* %else %if %list_count(&ans, 2) %then %do;
		%zone_replace(&geo, _ctrylst_=ctry);
		%let geo=%list_unique(&ctry &geo);
	%end; */

	/* IDIR/ILIB: check/set default input library */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(idir) EQ 0 and %macro_isblank(ilib) EQ 0, mac=&_mac,
			txt=%quote(!!! Incompatible parameters IDIR and ILIB: set one only !!!)) %then
		%goto exit;
	%else %if %macro_isblank(idir) EQ 0 /* IDIR passed */ %then %do;
		%let isLibTemp=1;
		libname _tmplib "&idir"; 
		%let ilib=_tmplib;
	%end;
	%else %if %macro_isblank(ilib) NE 0 /* ILIB not passed */ %then %do;
		%if %symexist(G_PING_LIBCRDB) %then 		%let ilib=&G_PING_LIBCRDB;
		%else %do;
			libname rdb "/ec/prod/server/sas/0eusilc/IDB_RDB/C_RDB"; /* &G_PING_C_RDB */
			%let ilib=rdb;
		%end;
	%end;

	/* PEPS01/PEPS03/PEPS04: check existence */
	%if %error_handle(ErrorInputDataset, 
			%ds_check(peps01, lib=&ilib) NE 0, mac=&_mac,
			txt=%quote(!!! Input table PEPS01 not found !!!)) 
			or %error_handle(ExistingOutputDataset, 
				%ds_check(peps03, lib=&ilib) NE 0, mac=&_mac,
				txt=%quote(!!! Input table PEPS03 not found !!!))
			or %error_handle(ExistingOutputDataset, 
				%ds_check(peps04, lib=&ilib) NE 0, mac=&_mac,
				txt=%quote(!!! Input table PEPS04 not found !!!)) %then 
		%goto exit;

	/* OLIB: set default output library */
	%if %macro_isblank(olib) %then 		%let olib=WORK;

	/* ODSN: set default generic name */
	%if %macro_isblank(odsn) %then 		%let odsn=PC_AROPE;
	%else 								%let odsn=%upcase(&odsn);

	/* COUNTRY_ORDER: set */ 
	%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
	%else										%let clib=LIBCFG; 
	/* libname clib "/ec/prod/server/sas/0eusilc/pdb"; */
	%if %symexist(G_PING_COUNTRY_ORDER) %then 	%let cds_ctry_order=&G_PING_COUNTRY_ORDER;
	%else										%let cds_ctry_order=COUNTRY_ORDER;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/
%put geo=&geo;
	%local yy;
	%let yy=%substr(&year,3,2);

	/** 1: compute AROPE total shares **/
	%ds_select(				PEPS01, 
							AROPE /*_&odsn._TOTAL_&yy*/, 
				var=		geo time ivalue iflag, 
				where=		%str(   age 		in 		%sql_list(TOTAL) 
								AND sex 		in 		%sql_list(T)
								AND unit 		in 		%sql_list(PC) 
								AND time 		in 		%sql_list(&year)
								AND geo 		in 		%sql_list(&geo)), 
				orderby= 	geo,
				ilib=		&ilib,
				olib=		&olib);
	/*	note: this is equivalent to:
	PROC SQL;
	   	CREATE &odsn._TOTAL_&yy AS 
	   	SELECT t1.geo, t1.time, t1.ivalue, t1.iflag
		FROM &ilib..PEPS01 t1
	  	WHERE t1.age in "TOTAL"  AND t1.sex in "T" AND t1.unit in "PC" AND t1.time in (&year) AND t1.geo in ("&geo")
		ORDER BY t1.geo;
	quit; */

	/* further order the data by country protocol order */
	PROC SQL noprint;
		CREATE TABLE &odsn._TOTAL_&yy AS 
		SELECT t1.*
		FROM AROPE AS t1
		LEFT JOIN &clib..&cds_ctry_order AS t2 
			ON t1.geo=t2.geo
		ORDER BY t2.ORDER;
	quit;

	/** 2: compute AROPE shares by feature **/

	/* 2.1: extract AROPE shares by sex */
	%ds_select(				PEPS01, 
							AROPE_SEX, 
				var=		geo time sex ivalue iflag, 
				where=		%str(   sex 		in 		%sql_list(M F)
								AND age 		in 		%sql_list(TOTAL) 
								AND unit 		in 		%sql_list(PC) 
								AND time 		in 		%sql_list(&year)
								AND geo 		in 		%sql_list(&geo)), 
				orderby= 	geo sex,
				ilib=		&ilib);

	/* 2.2: extract AROPE shares by age */
	%ds_select(				PEPS01, 
							AROPE_AGE, 
				var=		geo time age ivalue iflag, 
				where=		%str(   age 		in 		%sql_list(Y_LT18 Y_GE65) 
								AND sex 		in 		%sql_list(T)
								AND unit 		in 		%sql_list(PC) 
								AND time 		in 		%sql_list(&year)
								AND geo 		in 		%sql_list(&geo)), 
				orderby= 	geo age,
				ilib=		&ilib);

	/* 2.3: extract AROPE shares by household type */
	%ds_select(				PEPS03, 
							AROPE_HHTYP, 
				var=		geo time hhtyp ivalue iflag, 
				where=		%str(   hhtyp 		in 		%sql_list(HH_NDCH HH_DCH) 
								AND quantile 	in 		%sql_list(TOTAL)
								AND unit 		in 		%sql_list(PC) 
								AND time 		in 		%sql_list(&year)
								AND geo 		in 		%sql_list(&geo)), 
				orderby= 	geo hhtyp,
				ilib=		&ilib);

	/* 2.4: extract AROPE Shares by ISCED */
	%ds_select(				PEPS04, 
							AROPE_ISCED11, 
				var=		geo time isced11 ivalue iflag, 
				where=		%str(   isced11 	in 		%sql_list(ED0-2 ED5-8) 
								AND age 		in 		%sql_list(Y_GE18)
								AND sex 		in 		%sql_list(T)
								AND unit 		in 		%sql_list(PC) 
								AND time 		in 		%sql_list(&year)
								AND geo 		in 		%sql_list(&geo)), 
				orderby= 	geo isced11,
				ilib=		&ilib);

	/* 2.5: extract AROPE shares by working status */
	%ds_select(				PEPS02, 
							AROPE_WSTATUS, 
				var=		geo time wstatus ivalue iflag, 
				where=		%str(   sex 		in 		%sql_list(T)
								AND age 		in 		%sql_list(Y_GE18) 
								AND unit 		in 		%sql_list(PC)
								AND wstatus		in		%sql_list(EMP UNE) 
								AND time 		in 		%sql_list(&year)
								AND geo 		in 		%sql_list(&geo)), 
				orderby= 	geo wstatus,
				ilib=		&ilib);

	/* 2.6: build final table */
	PROC SQL noprint;
		CREATE TABLE &olib..&odsn._RESULTS_&yy AS 
		SELECT t1.geo,
			round(t2.ivalue,.1) as M, 			t2.iflag as FLAG_M,
			round(t3.ivalue,.1) as F, 			t3.iflag as FLAG_F,
			round(t4.ivalue,.1) as Y_LT18,  	t4.iflag as FLAG_Y_LT18, 
			round(t5.ivalue,.1) as Y_GE65, 		t5.iflag as FLAG_Y_GE65,
			round(t6.ivalue,.1) as EMP,			t6.iflag as FLAG_EMP, 
			round(t7.ivalue,.1) as UNE,  		t7.iflag as FLAG_UNE, 
			round(t8.ivalue,.1) as HH_NDCH,		t8.iflag as FLAG_HH_NDCH, 
			round(t9.ivalue,.1) as HH_DCH,  	t9.iflag as FLAG_HH_DCH, 
			round(ta.ivalue,.1) as ED0_2,		ta.iflag as FLAG_ED0_2, 
			round(tb.ivalue,.1) as ED5_8,  		tb.iflag as FLAG_ED5_8
		FROM &clib..&cds_ctry_order t1
		LEFT JOIN (SELECT * FROM AROPE_SEX 		WHERE sex="M"
			) t2 on t1.geo=t2.geo
		LEFT JOIN (SELECT * FROM AROPE_SEX 		WHERE sex="F"
			) t3 on t1.geo=t3.geo	
		LEFT JOIN (SELECT * FROM AROPE_AGE 		WHERE age="Y_LT18"
			) t4 on t1.geo=t4.geo
		LEFT JOIN (SELECT * FROM AROPE_AGE 		WHERE age="Y_GE65"
			) t5 on t1.geo=t5.geo
		LEFT JOIN (SELECT * FROM AROPE_WSTATUS 	WHERE wstatus="EMP"
			) t6 on t1.geo=t6.geo
		LEFT JOIN (SELECT * FROM AROPE_WSTATUS 	WHERE wstatus="UNE"
			) t7 on t1.geo=t7.geo
		LEFT JOIN (SELECT * FROM AROPE_HHTYP 	WHERE hhtyp="HH_NDCH"
			) t8 on t1.geo=t8.geo
		LEFT JOIN (SELECT * FROM AROPE_HHTYP 	WHERE hhtyp="HH_DCH"
			) t9 on t1.geo=t9.geo
		LEFT JOIN (SELECT * FROM AROPE_ISCED11 	WHERE isced11="ED0-2"
			) ta on t1.geo=ta.geo
		LEFT JOIN (SELECT * FROM AROPE_ISCED11 	WHERE isced11="ED5-8"
			) tb on t1.geo=tb.geo
		WHERE t1.geo in %sql_list(&geo)
		ORDER by t1.ORDER;
	quit;

	%if &isLibTemp %then %do;
		libname _tmplib clear;
	%end;

	%work_clean(AROPE, AROPE_SEX, AROPE_AGE, AROPE_WSTATUS, AROPE_HHTYP, AROPE_ISCED11);

	%exit:
%mend arope_press_infographics;

/** \endcond */
