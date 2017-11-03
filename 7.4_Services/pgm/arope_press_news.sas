/** 
## arope_press_news {#sas_arope_press_news}
Perform ad-hoc extraction for Eurostat press release on _AROPE_ on the occasion of the 
_International Day for the Eradication of Poverty_. 

	%arope_press_news(year, year_ref=, geo=, idir=, ilib=, odsn=, olib=);

### Arguments
* `year` : a (single) year of interest;
* `year_ref` : (_option_) reference year; default: `year_ref=2008`;
* `geo` : (_option_) a list of countries or a geographical area; default: `geo=EU27 EU28`;
* `ilib` : (_option_) name of the input library where to look for _AROPE_ indicators (see 
	note below); incompatible with `idir`; by default, `ilib` will be set to the value 
	`G_PING_LIBCRDB` (_e.g._, library associated to the path `G_PING_C_RDB`); 
* `idir` : (_option_) name of the input directory where to look for _AROPE_ indicators 
	passed instead of `ilib`; incompatible with `ilib`; by default, it is not used; 
* `odsn` : (_option_) generic name of the output datasets; default: `odsn=PC_AROPE`;
* `olib` : (_option_) name of the output library; by default, when not set, `olib=WORK`;

### Returns
Three datasets are generated:
* `&odsn._FIGURES_&yy` contains the _AROPE_ table with shares and total population,
* `&odsn._COMPONENTS_&yy` contains the _AROPE_ shares as well as its components 
	(_ARP_, _SMD_, _LWI_) shares for both years of interest `&year` and of reference 
	`&year_ref`,
* `&odsn._SERIES_&yy` contains the evaolution of _AROPE_ shares as well as its 
	components from year of reference `&year_ref` till `&year`,

(where `yy` represents the last two digits of `year`) all stored in the library passed
through `olib`.

### Example
In order to (re)generate the tables `PC_AROPE_FIGURES_15`, `PC_AROPE_COMPONENTS_15` 
and `PC_AROPE_SERIES_15`, used for the tables of the 2015 press release below: 

<img src="img/arope_press_news.png" border="1" width="60%" alt="AROPE press news">

you can simply launch:

	%arope_press_news(2015);
	%ds_export(PC_AROPE_FIGURES_15, fmt=csv);
	%ds_export(PC_AROPE_COMPONENTS_15, fmt=csv);
	%ds_export(PC_AROPE_SERIES_15, fmt=csv);

### Note
The publication is based on the following  indicators:
* _PEPS01_ for the extraction of AROPE total shares,
* _LI01_ for the extraction of ARP tresholds,
* _LI02_ for the extraction of ARP shares,
* _MDDD11_ for the extraction of SMD shares,
* _LVHL11_ for the extraction of LWI shares,
* _DI03_ for the extraction of ARP equivalised medians.

### References
1. Website of the UN initiative for the _International Day for the Eradication of Poverty_: 
http://www.un.org/en/events/povertyday.
2. Website of press releases on _AROPE_: 
[2015](http://ec.europa.eu/eurostat/en/web/products-press-releases/-/3-16102015-CP),
[2016](http://ec.europa.eu/eurostat/documents/2995521/7695750/3-17102016-BP-EN.pdf) and
[2017](http://ec.europa.eu/eurostat/documents/2995521/8314163/3-16102017-BP-EN.pdf).
3. _Sustainable development in the European Union – A statistical glance from the viewpoint of the UN sustainable development goals_, 
[edition 2016](http://ec.europa.eu/eurostat/documents/3217494/7745644/KS-02-16-996-EN-N.pdf).
4. Statistics explained on [poverty and social exclusion](http://ec.europa.eu/eurostat/statistics-explained/index.php/People_at_risk_of_poverty_or_social_exclusion).

### See also
[%arope_press_infographics](@ref sas_arope_press_infographics).
*/ /** \cond */

/* credits: grazzja */

%macro arope_press_news(year		/* Year of interest 			(REQ) */
						, year_ref=	/* Reference year 				(OPT) */
						, geo=		/* Area of interest 			(OPT) */
						, idir=		/* Input directory name			(OPT) */
						, ilib=		/* Input library name 			(OPT) */
						, odsn=		/* Generic output dataset name 	(OPT) */
						, olib=		/* Output library name 			(OPT) */
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

	%local years
		clib
		cds_ctry_order
		isLibTemp;
	%let isLibTemp=0;

	/* YEAR, YEAR_REF: check/set */
	%if %macro_isblank(year_ref) %then 	%let year_ref=2008;
	%else %if %error_handle(ErrorInputParameter, 
			%par_check(&year_ref, type=INTEGER, range=2003) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for input YEAR_REF !!!)) %then
		%goto exit;
	%if %error_handle(ErrorInputParameter, 
			%par_check(&year, type=INTEGER, range=%eval(&year_ref-1)) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for input YEAR !!!)) %then
		%goto exit;
	/* append both years */
	%let years=&year &year_ref;

	/* GEO: check/set */
	%local ans ctry;
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
		libname lib "&idir"; 
		%let ilib=lib;
	%end;
	%else %if %macro_isblank(ilib) NE 0 /* ILIB passed */ %then %do;
		%if %symexist(G_PING_LIBCRDB) %then 		%let ilib=&G_PING_LIBCRDB;
		%else %do;
			libname rdb "/ec/prod/server/sas/0eusilc/IDB_RDB/C_RDB"; /* &G_PING_C_RDB */
			%let ilib=rdb;
		%end;
	%end;

	/* OLIB/ODSN: check/set default output  */
	%if %macro_isblank(olib) %then 				%let olib=WORK;
	%if %macro_isblank(odsn) %then 				%let odsn=POP_AROPE;
	%else 										%let odsn=%upcase(&odsn);

	/* COUNTRY_ORDER: set */ 
	%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
	%else										%let clib=LIBCFG; 
	/* libname clib "/ec/prod/server/sas/0eusilc/pdb"; */
	%if %symexist(G_PING_COUNTRY_ORDER) %then 	%let cds_ctry_order=&G_PING_COUNTRY_ORDER;
	%else										%let cds_ctry_order=COUNTRY_ORDER;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local yy;
	%let yy=%substr(&year,3,2);

	/** 1: compute AROPE shares **/

	/* 1.1: extract AROPE shares */
	%ds_select(			PEPS01, 
						AROPE_PC, 
				var=	geo time ivalue iflag, 
				where=	%str(   age 		in 		%sql_list(TOTAL) 
							AND sex 		in 		%sql_list(T)
							AND unit 		in 		%sql_list(PC) 
							AND time 		in 		%sql_list(&years)
							AND geo 		in 		%sql_list(&geo)), 
				ilib=	&ilib);

	/* 1.2: compute AROPE figures */
	%ds_select(			PEPS01, 
						AROPE_TH, 
				var=	geo time ivalue iflag, 
				where=	%str(   age 		in 		%sql_list(TOTAL) 
							AND sex 		in 		%sql_list(T)
							AND unit 		in 		%sql_list(THS_PER) 
							AND time 		in 		%sql_list(&years)
							AND geo 		in 		%sql_list(&geo)), 
				ilib=	&ilib);

	/* merge/build final table */
	PROC SQL noprint;
		CREATE TABLE &olib..&odsn._FIGURES_&yy AS 
		SELECT t1.geo,		/* rounding: format=4.1 for PC, format=9.0 for THS_PER */
			round(t2.ivalue,.1) as AROPE_PC_&year_ref., t2.iflag as FLAG_AROPE_PC_&year_ref.,
			round(t3.ivalue,.1) as AROPE_PC_&year., 	t3.iflag as FLAG_AROPE_PC_&year.,
			round(t4.ivalue,10) as AROPE_TH_&year_ref.,	t4.iflag as FLAG_AROPE_TH_&year_ref., 
			round(t5.ivalue,10) as AROPE_TH_&year., 	t5.iflag as FLAG_AROPE_TH_&year.
		FROM &clib..&cds_ctry_order t1
		LEFT JOIN (SELECT * FROM AROPE_PC 	WHERE time=&year_ref.
			) t2 on t1.geo=t2.geo
		LEFT JOIN (SELECT * FROM AROPE_PC 	WHERE time=&year.
			) t3 on t1.geo=t3.geo
		LEFT JOIN (SELECT * FROM AROPE_TH 	WHERE time=&year_ref.
			) t4 on t1.geo=t4.geo
		LEFT JOIN (SELECT * FROM AROPE_TH 	WHERE time=&year.
			) t5 on t1.geo=t5.geo
		WHERE t1.geo in %sql_list(&geo)
	  	ORDER by t1.ORDER;
	quit;

	/* clean */
	%*work_clean(AROPE_PC, AROPE_TH);

	/** 2: compute AROPE components **/

	/* 2.1: extract ARP tresholds */
	%ds_select(			LI01, 
						TRESH, 
				var=	geo time hhtyp currency ivalue iflag, 
				where=	%str(   hhtyp 		in 		%sql_list(A1 A2_2CH_LT14) 
							AND currency 	in 		%sql_list(NAC) 
							AND indic_il 	in 		%sql_list(LI_C_MD60) 
							AND time 		in 		%sql_list(&years)
							AND geo 		in 		%sql_list(&geo)), 
				ilib=	&ilib);
	/*	note: this is equivalent to:
	PROC SQL;
		CREATE TABLE WORK.TRESH AS 
	   	SELECT t1.geo, t1.time, t1.hhtyp, t1.currency, t1.ivalue, t1.iflag
		FROM &ilib..LI01 t1
      	WHERE t1.hhtyp in ("A1","A2_2CH_LT14") AND t1.currency = "NAC" 
			AND t1.indic_il = "LI_C_MD60" AND t1.time in (&year_ref,&year) AND t1.geo in ("&geo");
	quit;*/

	/* 2.2: extract ARP shares */
	%ds_select(			LI02, 
						ARP, 
				var=	geo time age sex ivalue iflag, 
				where=	%str(   age 		in 		%sql_list(TOTAL) 
							AND sex 		in 		%sql_list(T)
							AND unit 		in 		%sql_list(PC) 
							AND indic_il 	in 		%sql_list(LI_R_MD60) 
							AND time 		in 		%sql_list(&years)
							AND geo 		in 		%sql_list(&geo)), 
				ilib=	&ilib);

	/* 2.3: extract SMD shares */
	%ds_select(			MDDD11, 
						SMD, 
				var=	geo time age sex ivalue iflag, 
				where=	%str(   age 		in 		%sql_list(TOTAL) 
							AND sex 		in 		%sql_list(T)
							AND unit 		in 		%sql_list(PC) 
							AND time 		in 		%sql_list(&years)
							AND geo 		in 		%sql_list(&geo)), 
				ilib=	&ilib);

	/* 2.4: extract LWI shares */
	%ds_select(			LVHL11, 
						LWI, 
				var=	geo time age sex ivalue iflag, 
				where=	%str(   age 		in 		%sql_list(Y_LT60) 
							AND sex 		in 		%sql_list(T)
							AND unit 		in 		%sql_list(PC_Y_LT60)  
							AND time 		in 		%sql_list(&years)
							AND geo 		in 		%sql_list(&geo)), 
				ilib=	&ilib);

	/* 2.5: extract ARP equivalised medians */
	%ds_select(			DI03, 
						MED_EQ, 
				var=	geo time unit ivalue iflag, 
				where=	%str(   age 		in 		%sql_list(TOTAL) 
							AND sex 		in 		%sql_list(T)
							AND unit 		in 		%sql_list(NAC)  /* !!! currency in fact... */
							AND indic_il 	in 		%sql_list(MED_E) 
							AND time 		in 		%sql_list(&years)
							AND geo 		in 		%sql_list(&geo)), 
				ilib=	&ilib);

	/* build final table */
	PROC SQL noprint;
		CREATE TABLE &olib..&odsn._COMPONENTS_&yy AS 
		SELECT t1.geo,
			round(t2.ivalue,.1) as ARP_&year_ref., 			t2.iflag as FLAG_ARP_&year_ref.,
			round(t3.ivalue,.1) as ARP_&year., 				t3.iflag as FLAG_ARP_&year.,
			round(tc.ivalue,1) as MED_&year_ref.,  			tc.iflag as FLAG_MED_&year_ref., 
			round(td.ivalue,1) as MED_&year., 				td.iflag as FLAG_MED_&year.,
			round(t4.ivalue,1) as TRESH_&year_ref._A1,		t4.iflag as FLAG_TRESH_&year_ref._A1, 
			round(t5.ivalue,1) as TRESH_&year._A1,  		t5.iflag as FLAG_TRESH_&year._A1, 
	        round(t6.ivalue,1) as TRESH_&year_ref._A2_2CH,  t6.iflag as FLAG_TRESH_&year_ref._A2_2CH, 
			round(t7.ivalue,1) as TRESH_&year._A2_2CH,  	t7.iflag as FLAG_TRESH_&year._A2_2CH, 
	        round(t8.ivalue,.1) as SMD_&year_ref.,  		t8.iflag as FLAG_SMD_&year_ref., 
			round(t9.ivalue,.1) as SMD_&year.,  			t9.iflag as FLAG_SMD_&year.,
	        round(ta.ivalue,.1) as LWI_&year_ref.,  		ta.iflag as FLAG_LWI_&year_ref., 
			round(tb.ivalue,.1) as LWI_&year., 				tb.iflag as FLAG_LWI_&year
		FROM &clib..&cds_ctry_order t1
		LEFT JOIN (SELECT * FROM ARP 	WHERE time=&year_ref.
			) t2 ON t1.geo=t2.geo
		LEFT JOIN (SELECT * FROM ARP 	WHERE time=&year.
			) t3 ON t1.geo=t3.geo
		LEFT JOIN (SELECT * FROM TRESH 	WHERE time=&year_ref. AND hhtyp="A1"
			) t4 ON t1.geo=t4.geo
		LEFT JOIN (SELECT * FROM TRESH 	WHERE time=&year. AND hhtyp="A1"
			) t5 ON t1.geo=t5.geo
		LEFT JOIN (SELECT * FROM TRESH 	WHERE time=&year_ref. AND hhtyp="A2_2CH_LT14"
			) t6 ON t1.geo=t6.geo
		LEFT JOIN (SELECT * FROM TRESH 	WHERE time=&year. AND hhtyp="A2_2CH_LT14"
			) t7 ON t1.geo=t7.geo
		LEFT JOIN (SELECT * FROM SMD 	WHERE time=&year_ref.
			) t8 ON t1.geo=t8.geo
		LEFT JOIN (SELECT * FROM SMD 	WHERE time=&year.
			) t9 ON t1.geo=t9.geo
		LEFT JOIN (SELECT * FROM LWI 	WHERE time=&year_ref.
			) ta ON t1.geo=ta.geo
		LEFT JOIN (SELECT * FROM LWI 	WHERE time=&year.
			) tb ON t1.geo=tb.geo
		LEFT JOIN (SELECT * FROM MED_EQ WHERE time=&year_ref.
			) tc ON t1.geo=tc.geo
		LEFT JOIN (SELECT * FROM MED_EQ WHERE time=&year.
			) td ON t1.geo=td.geo
		WHERE t1.geo in %sql_list(&geo)
		ORDER by t1.ORDER;
	quit;

	/* clean */
	%work_clean(ARP, TRESH, SMD, LWI, MED_EQ);

	/** 3: compute AROPE time-series **/
	%let COND_GEOTIME=	(geo="EU27" AND time>2007 AND time<2010 AND time>=&year_ref AND time<=&year)
					OR 
						(geo="EU28" AND time>=2010 AND time>=&year_ref AND time<=&year);
	/* 3.1: retrieve AROPE time-series */
	%ds_select(			PEPS01, 
						TS_AROPE, 
				var=	geo time ivalue iflag, 
				varas= 	geo time AROPE	FLAG_AROPE,
				where=	%str(   age 		in 		%sql_list(TOTAL) 
							AND sex 		in 		%sql_list(T)
							AND unit 		in 		%sql_list(PC) 
							AND (&COND_GEOTIME)), 
				orderby=time geo,
				ilib=	&ilib);

	/* using a UNION clause 
	PROC SQL;
		CREATE TABLE WORK.TAB_AROPE_EU27 AS 
	   	SELECT t1.geo, t1.time, round(t1.ivalue,.1) as ivalue, t1.iflag
	    	FROM RDB.peps01 t1
	      	WHERE t1.geo = 'EU27' AND t1.time > 2007 AND t1.time < 2010 AND t1.age = 'TOTAL' AND t1.sex = 'T' AND t1.unit = 'PC'
	      	ORDER BY t1.time, t1.geo;
	  	CREATE TABLE WORK.TAB_AROPE_EU28 AS 
	   	SELECT t1.geo, t1.time, round(t1.ivalue,.1) as ivalue, t1.iflag
	      	FROM RDB.peps01 t1
	      	WHERE t1.geo = 'EU28' AND t1.time > 2009 AND t1.age = 'TOTAL' AND t1.sex = 'T' AND t1.unit = 'PC_POP'
	      	ORDER BY t1.time, t1.geo;
	   	CREATE TABLE WORK.TAB_AROPE_EU AS 
	   	SELECT * FROM WORK.TAB_AROPE_EU27
	   		UNION
	   	SELECT * FROM WORK.TAB_AROPE_EU28;
	quit; */

	/* 3.2: retrieve ARP time-series */
	%ds_select(			LI02, 
						TS_ARP, 
				var=	geo time ivalue iflag, 
				varas= 	geo time ARP	FLAG_ARP,
				where=	%str(   age 		in 		%sql_list(TOTAL) 
							AND sex 		in 		%sql_list(T)
							AND unit 		in 		%sql_list(PC) 
							AND indic_il 	in 		%sql_list(LI_R_MD60)
							AND (&COND_GEOTIME)), 
				orderby=time geo,
				ilib=	&ilib);

	/* 3.3: retrieve SMD time-series */
	%ds_select(			MDDD11, 
						TS_SMD, 
				var=	geo time ivalue iflag, 
				varas= 	geo time SMD	FLAG_SMD,
				where=	%str(   age 		in 		%sql_list(TOTAL) 
							AND sex 		in 		%sql_list(T)
							AND unit 		in 		%sql_list(PC) 
							AND (&COND_GEOTIME)), 
				orderby=time geo,
				ilib=	&ilib);

	/* 3.4: retrieve LWI time-series */
	%ds_select(			LVHL11, 
						TS_LWI, 
				var=	geo time ivalue iflag, 
				varas= 	geo time LWI	FLAG_LWI,
				where=	%str(   age 		in 		%sql_list(Y_LT60) 
							AND sex 		in 		%sql_list(T)
							AND unit 		in 		%sql_list(PC_Y_LT60) 
							AND (&COND_GEOTIME)), 
				orderby=time geo,
				ilib=	&ilib);

	/* 3.5: build final table */
	DATA &olib..&odsn._SERIES_&yy;
		/* we cheat here since we want to avoid the message:
		* "WARNING: Multiple lengths were specified for the variable geo by input data set" */
		LENGTH geo $15.;
		/* actual merge */
		MERGE TS_AROPE TS_ARP TS_SMD TS_LWI;
		BY geo time;
		/* rounding */
		AROPE=round(AROPE,.1);
		ARP=round(ARP,.1);
		SMD=round(SMD,.1);
		LWI=round(LWI,.1);
	run;

	/* clean */
	%work_clean(TS_AROPE, TS_ARP, TS_SMD, TS_LWI);

	/* clear the temporary library reference if it exists */
	%if &isLibTemp %then %do;
		libname lib clear;
	%end;

	%exit:
%mend arope_press_news;

/** \endcond */
