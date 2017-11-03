/** 
## income_components_gini {#sas_income_components_gini}
Compute the Gini coefficients of composite variable incomes for given geographical area(s)
and period(s). 

~~~sas
	%income_components_gini(geo, year, varadd=, varsub=, weight=, type=G, odsn=GINI_INC, olib=WORK);
~~~

### Arguments
* `geo` : a list of countries or a geographical area; default: `geo=EU28`; 
* `year` : year of interest;
* `varadd` : (_option_) list of (personal and household) income components to be considered  
	as contributing positively to the total income to be calculated; default: `varadd` is empty;
* `varsub` : (_option_) ibid for the list of (personal and household) income components   
	contributing negatively to the total income; default: `varsub` is empty; 
* `weight` : (_option_) personal weight variable used to weighting the distribution; default:
	`weight=RB050a`;
* `type` : (_option_) flag set to 'N' or 'G' to consider net and gross values respectively;
	default: `type=G`.

### Returns
* `odsn` : (_option_) name of the output datasets; default: `odsn=GINI_INC`;
* `olib` : (_option_) name of the output library; by default, when not set, `olib=WORK`.

### Example
Let us consider the following configuration parameters:

~~~sas
	%let year=2015;
	%let geo=AT;
	%let type=G;     	* gross values: this is default by the way;
	%let varadd=HY040 HY080 HY090 HY110  PY010 PY021 PY050 PY080;
	%let varsub=;
	%let weight=RB050a; * this is also the default;
	%let odsn=GINI_INC;
	%let olib=WORK;
~~~

we implicitely compute the Gini coefficient of the market outcome, normally expressed as:

	market = HY040G + HY080G + HY090G + HY110G 
		   + Sum{HH members}(PY010G + PY021G + PY050G + PY080)
	       = HY010 - [HY050G + HY060G + HY070G 
	       + Sum{all HH members}(PY090G +PY100G + PY110G +PY120G + PY130G +PY140G)]
	       = HY023 + (HY120G + HY130G + HY140G)

so as to produce the following `GINI_INC` table in `WORK` library:

| GEO | TIME |    GINI    | FLAG |  NTOT |    NTOTWGH   |
|:---:|-----:|-----------:|-----:|------:|-------------:|
| AT  |	2015 |49.790874267|   0  | 13213 | 8476450.5605 |	

In practice, the example above realises the following stepwise calculations:

~~~sas
	PROC SQL noprint;

		CREATE TABLE dsn1 as 
		SELECT DISTINCT 
			PB010, PB020, PHID, PB030, 
			PY010G, PY021G, PY050G, PY080, 
			SUM(PY010G, PY021G, PY050G, PY080,0) as sum_Pvaradd,
			SUM(calculated sum_Pvaradd) as Psum_add,
			0 as Psum_sub
		FROM bdb.&Pbdb as p
		WHERE PB020="AT" and PB010=2015
		GROUP BY PB020, PHID; 
			
		CREATE TABLE dsn2 as 
		SELECT DISTINCT 
			PB010, PB020, PHID, 
			(HY040G + HY080G + HY090G + HY110G + Psum_add - Psum_sub) as income,
			(calculated income / EQ_SS) as EQ_INC
		FROM dsn1 AS p
		LEFT JOIN bdb.&Hbdb  h 
			ON (p.PB010 = H.HB010) AND (p.PB020 = H.HB020) AND (p.PHID = H.HB030)
		LEFT JOIN idb.&ds as idb 
			ON (idb.DB010 = p.PB010) AND (idb.DB020 = p.PB020) AND (idb.DB030 = p.PHID)
		GROUP BY PB020, PHID;

		CREATE TABLE dsn3 as 
		SELECT DB010 as TIME, 
			DB020 as GEO, 
			DB030, RB030,
			&weight,
			count(RB030) as NTOT,
			sum(&weight) as NTOTWGH, 
			(case when calculated NTOT < 20 then 2
				when calculated NTOT < 50 then 1
				else 0 end) as FLAG, 	* our own rule
			EQ_INC
		FROM idb.&idb as idb
		LEFT JOIN dsn2  p 
			ON (idb.DB010 = p.PB010) AND (idb.DB020 = p.PB020) AND (idb.DB030 = p.PHID)
		WHERE DB020="AT" and DB010=2015;
	quit;

	PROC SORT data=dsn3;
		by EQ_INC;
	run;

	DATA gini(DROP=EQ_INC &weight ss swt swtvar swt2var swtvarcw);
		SET dsn3(DROP=DB030 RB030) end=last;
		RETAIN swt swtvar swt2var swtvarcw ss 0;
		ss + 1;
		swt +&weight;
		swtvar + &weight * EQ_INC;
		swt2var + &weight *&weight * EQ_INC;
		swtvarcw + swt *&weight * EQ_INC;
		if last then do;
			GINI  = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1);
			output;
		end;
	run;
~~~
where the datasets `&idb`, `&Hbdb`, and `&Pbdb` that appear above store the input personal 
and household data. These datasets, as well as the libraries `bdb` and `idb`, can be retrieved 
using the macro [%silc_db_locate](@ref sas_silc_db_locate).

### Notes
1. This macro will enable you to estimate the decomposition of disposable income Gini variation 
according to the contribution of different income sources.
2. The list of (net and gross) income components normally considered as positively contributing 
to the total income (hence listed in `varadd`) are to be chosen among: 
`HY040G/N`, `HY050G/N`, `HY051G`, `HY052G`, `HY053G`, `HY054G`, `HY060G/N`, `HY061G`, `HY062G`, 
`HY063G`, `HY064G`, `HY070G/N`, `HY071G`, `HY072G`, `HY073G`, `HY074G`, `HY080G/N`, `HY081G/N`, 
`HY090G/N`, `HY100G/N`, `HY110G/N`, `HY145N`, `HY170G/N`, `PY010G/N`, `PY021G/N`, `PY050G/N`, 
`PY080G/N`, `PY090G/N`, `PY100G/N`, `PY110G/N`, `PY120G/N`, `PY130G/N`, `PY140G/N`.
3. Ibid, the list of (net and gross) income components normally considered as negatively 
contributing to the total income (hence listed in `varsub`) are to be chosen among:
`HY120G/N`, `HY130G/N`, `HY131G/N`, `HY140G/N`.
4. By using specific configuration, it is possible to compute Gini coefficients over typical 
incomes, namely:
* total income _HY010_ as:
~~~sas
	%let varadd = HY040 HY050 HY060 HY070 HY080 HY090 HY110
		PY010 PY021 PY050 PY080 PY090 PY100 PY110 PY120 PY130 PY140;
	%let varsub =;
~~~	
* market income (see example above) as:
~~~sas
	%let varadd = HY040 HY080 HY090 HY110 PY010 PY021 PY050 PY080;
	%let varsub =;
~~~	
*  total disposable income _HY020_:
~~~sas
	%let varadd = HY040 HY050 HY060 HY070 HY080 HY090 HY110
		PY010 PY021 PY050 PY080 PY090 PY100 PY110 PY120 PY130 PY140;
	%let varsub = HY120 HY130 HY140;
~~~	
* intermediate disposable income _HY022_ (before social transfers other than old-age and 
survivor's benefits): 
~~~sas
	%let varadd = HY040 HY080 HY090 HY110
		PY010 PY021 PY050 PY080 PY090 PY100 PY110;
	%let varsub = HY120 HY130 HY140;
~~~	
* intermediate disposable income _HY023_ (before social transfers including old-age and 
survivor's benefits):
~~~sas
	%let varadd = HY040 HY080 HY090 HY110
		PY010 PY021 PY050 PY080;
	%let varsub = HY120 HY130 HY140;
~~~	

### References
1. EU-SILC survey reference document [doc65](https://circabc.europa.eu/sd/a/2aa6257f-0e3c-4f1c-947f-76ae7b275cfe/DOCSILC065%20operation%202014%20VERSION%20reconciliated%20and%20early%20transmission%20October%202014.pdf).
2. DG EMPL (2015): ["Wage and income inequality in the European Union"](http://ec.europa.eu/eurostat/cros/system/files/05-2014-wage_and_income_inequality_in_the_eu_0.pdf).

### See also
[income_components_disaggregated](@ref sas_income_components_disaggregated).
*/ /** \cond */

/* credits: grazzja */

%macro income_components_gini(geo		/* Area of interest 											(REQ) */
							, year		/* Year of interest 											(REQ) */
							, varadd= 	/* Personal/Household variables that count positively in income (OPT) */
							, varsub= 	/* Personal/Household variablesthat count negatively in income 	(OPT) */
							, weight= 	/* Weight variable												(OPT) */
							, cond=     /* condition to apply to the in extraction step					(OPT) */
							, type=	 	/* Flag describing the nature of income							(OPT) */
							, odsn=		/* Output dataset name 											(OPT) */
							, olib=		/* Output library name 											(OPT) */
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

	/* "static" local variables */
	%local G_ALLVARADD
		G_ALLVARSUB
		G_VARONLYG
		G_VARONLYN;
	%let G_ALLVARADD = HY040 HY050 HY051 HY052 HY053 HY054 HY060 HY061 HY062 HY063 HY064
		HY070 HY071 HY072 HY073 HY074 HY080 HY081 HY090 HY100 HY110 HY145 HY170 
		PY010 PY021 PY050 PY080 PY090 PY100 PY110 PY120 PY130 PY140;
	%let G_ALLVARSUB = HY120 HY130 HY131 HY140;
	%let G_VARONLYG = HY051 HY052 HY053 HY054 HY061 HY062 HY063 HY064 HY071 HY072 HY073 HY074;
	%let G_VARONLYN = HY145;

	%local yy existsOutput
		Pvarsub Pvaradd 
		Hvarsub Hvaradd
		_Pvarsub _Pvaradd
		_Hvarsub _Hvaradd
		isgeo ryear
		new;
	%let existsOutput=NO;
	%let Pvarsub=; 	%let _Pvarsub=;
	%let Pvaradd=; 	%let _Pvaradd=;
	%let Hvarsub=; 	%let _Hvarsub=;
	%let Hvaradd=; 	%let _Hvaradd=;

	/* OLIB/ODSN: check/set default output  */
	%if %macro_isblank(olib) %then 				%let olib=WORK;
	%if %macro_isblank(odsn) %then 				%let odsn=GINI_INC;
	%else 										%let odsn=%upcase(&odsn);

	%if %error_handle(ExistingDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, 
			txt=%bquote(! Output table already exists - Results will be appended!),verb=warn) %then %do;
		%let existsOutput=YES;
		%goto warning1; 
	%end;
	%warning1:
		
	/* GEO: check/set */
	%if %macro_isblank(geo) %then	%let geo=EU28;
	/* clean the list of geo and retrieve type */
	%str_isgeo(&geo, _ans_=isgeo, _geo_=geo);
	%if %error_handle(ErrorInputParameter, 
			%list_count(&isgeo, 0) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong parameter GEO: must be country/geographical zone ISO code(s) !!!)) %then
		%goto exit;
	/*%else %if %list_count(&isgeo, 2) %then %do;
		%local ctry;
		%zone_replace(&geo, _ctrylst_=ctry);
		%let geo=%list_unique(&ctry &geo);
	%end;*/

	/* YEAR: check/set */
	%if %symexist(G_PING_INITIAL_YEAR) %then 	%let YEARINIT=&G_PING_INITIAL_YEAR;
	%else										%let YEARINIT=2002;

	%let ryear=%list_ones(%list_length(&year), item=0);
    /* note the that %let ryear=%list_replace(&year, %list_unique(&year), 0); could work! */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&year, type=INTEGER, range=&YEARINIT) NE &ryear, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for input YEAR !!!)) %then
		%goto exit;
	%else
		%let yy=%substr(&year,3,2);
	
	/* TYPE: check/set */
	%if %macro_isblank(type) %then		%let type=G;
	%else 								%let type=%upcase(&type);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&type, type=CHAR, set=N G) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for income: must be Gross (G) or Net (N) !!!)) %then
		%goto exit;
	%else

	/* VARADD/VARSUB: check variables */
	%if %error_handle(ErrorInputParameter, 
			%list_difference(&varadd, &G_ALLVARADD) NE , mac=&_mac,		
			txt=%bquote(!!! Unrecognised positive income components - Must be in &G_ALLVARADD !!!)) 
			or %error_handle(ErrorInputParameter, 
				%list_difference(&varsub, &G_ALLVARSUB) NE , mac=&_mac,		
				txt=%bquote(!!! Unrecognised negative income components - Must be in &G_ALLVARSUB !!!)) %then
		%goto exit;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(varadd) EQ 1 and %macro_isblank(varsub) EQ 1, mac=&_mac,		
			txt=%quote(!!! Missing Household/personal components of income !!!)) %then
		%goto exit;

	/* add the extension TYPE to the list of negative/positive component variables */
	%if not %macro_isblank(varadd) %then %do;
		%let varadd = %list_append(&varadd, %list_ones(%list_length(&varadd), item=&type), zip=_EMPTY_);
	%end;
	%if not %macro_isblank(varsub) %then %do;
		%let varsub = %list_append(&varsub, %list_ones(%list_length(&varsub), item=&type), zip=_EMPTY_);
	%end;

	/* special cases: some components in VARADD are either G only or N only... fix
	* see variables G_VARONLYN and G_VARONLYG declared in compute file */
	%if %error_handle(IgnoredParameter, 
			"&type" EQ "G" and %macro_isblank(%list_intersection(&varadd, &G_VARONLYN)) NE 1, 
			txt=%bquote(! Components in %upcase(&G_VARONLYN) are Net only - Ignored !), verb=warn) %then %do; 
		%let varadd = %list_difference(&varadd, &G_VARONLYN);
		%goto warning2;
	%end;
	%if %error_handle(IgnoredParameter, 
			"&type" EQ "N" and %macro_isblank(%list_intersection(&varadd, &G_VARONLYG)) NE 1, 
			txt=%bquote(! Components in %upcase(&G_VARONLYG) are Gross only - Ignored !), verb=warn) %then %do; 
		%let varadd = %list_difference(&varadd, &G_VARONLYG);
		%goto warning2;
	%end;
	%warning2:

	/* extract the list of P/H variables to add or substract */
	%macro select_ph(var, op);
		%local _i _v;
		%do _i=1 %to %list_length(&&var&op);
			%let _v=%scan(&&var&op, &_i);
			%let _vtype=%upcase(%substr(&_v,1,1));
			%if "&_vtype" EQ "P" %then 
				%let Pvar&op = &&Pvar&op &_v;
			%else %if "&_vtype" EQ "H" %then 	
				%let Hvar&op = &&Hvar&op &_v;
			%else %if %error_handle(WrongParameter, 
					"&_vtype" NE "P" and "&_vtype" NE "H", 
					txt=%bquote(! Wrong variable name &_v: only P(ersonal)/H(ousehold) variables accepted - Ignored !), verb=warn) %then  
				%goto _warning;
			%_warning:
		%end;
		%if "&&Pvar&op" NE "" %then %do;
			%let _Pvar&op=%list_quote(&&Pvar&op, mark=_EMPTY_, rep=%quote(,));
		%end;
		%if "&&Hvar&op" NE "" %then %do;
			%let _Hvar&op=%list_quote(&&Hvar&op, mark=_EMPTY_, rep=%quote(+));
		%end;
	%mend;
	%select_ph(&varadd, add); /* set PVARADD, _PVARADD and HVARADD, _HVARADD */
	%select_ph(&varsub, sub); /* set PVARSUB, _PVARSUB and HVARSUB, _HVARSUB */

	/* WEIGHT: check variable - we do it here only
	* by default, WEIGHT is left as blank and the income distribution is not weighted!
	* when WEIGHT is passed, then it is checked later on, after the input IDB library has
	* been defined (see below) */
	%if %error_handle(WarningParameter, 
			%macro_isblank(weight) EQ 1, 
			txt=%bquote(! No weight variable passed - Uniform weighting is used !), verb=warn) %then 
		%goto warning3;
	%warning3:

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _dsn
		path ds
		Ppath Pds
		Hpath Hds
		_i _iy _ig _ic
		ctry ctrylst ctrylst_in ctrylst_sql
	 	area type
		_ans 
		ans;
	%let path=; 	
	%let ds=;

	%macro gini_compute(yyyy, ctry, weight, output);
		%local _dsn;
		%let _dsn=TMp&sysmacroname;

		PROC SQL noprint;

			/* simultaneousely create table (at personal level) with variables of interest 
			* and sum personal variables over household members */
			CREATE TABLE WORK.&_dsn.1 as 
			SELECT DISTINCT 
				PB010, 
				PB020, 
				PHID, 
				PB030, 
				%if &yyyy< 2009 %then %do;
					(case when PY080G_F=-5 then PY080N
						  else PY080G
					end) as PY80,
					(SUM(calculated PY80)) as SUM_PY80,
				%end;
				%else %if &yyyy> 2008 AND &yyyy< 2011 %then %do;
					(SUM(PY080G)) as SUM_PY080G,
				%end;
				%if %macro_isblank(Pvaradd) %then %do; 
					0 as Psum_add,
				%end;
				%else %do;
					&_Pvaradd, 
					SUM(&_Pvaradd,0) as sum_Pvaradd,
					SUM(calculated sum_Pvaradd) as Psum_add,
				%end;
				%if %macro_isblank(Pvarsub) %then %do; 
					0 as Psum_sub
				%end;
				%else %do;
					&_Pvarsub,
					SUM(&_Pvarsub,0) as sum_Pvarsub,
					SUM(calculated sum_Pvarsub) as Psum_sub
				%end;
			FROM Pbdb.&Pds as p
			WHERE PB020="&ctry" and PB010=&yyyy
			GROUP BY PB020, PHID
			/* note: we set the line below so as to avoid WARNING:
			* "A GROUP BY clause has been transformed into an ORDER BY clause because neither the SELECT clause..." */
			ORDER BY PB020, PHID; 
			
			/* create table (at household level) with equivalised composite income variable 
			* calculated from various household and personal income components */
			CREATE TABLE WORK.&_dsn.2 as 
			SELECT DISTINCT 
				PB010, 
				PB020, 
				PHID, 
				%if &yyyy<2009  %then %do;
				     SUM_PY80,
				%end;
				%else %if &yyyy>=2009 and &yyyy< 2011 %then %do;
				     SUM_PY080G,
				%end;
				((
				%if not %macro_isblank(Hvaradd) %then %do; 
					&_Hvaradd + 
				%end;
					Psum_add) - (Psum_sub 
				%if not %macro_isblank(Hvarsub) %then %do; 
					+ &_Hvarsub
				%end;
				)) as income,
				%if &yyyy<2009  %then %do;
					(SUM(calculated income, SUM_PY80) * HY025 / EQ_SS) as EQ_INC
				%end;
				%else %if &yyyy>=2009 and &yyyy<2011 %then %do;
					(SUM(calculated income, SUM_PY080G) * HY025 / EQ_SS) as EQ_INC
				%end;
				%else %if &yyyy>=2011 and &yyyy<2013 %then %do;
					(calculated income * HY025 / EQ_SS) as EQ_INC
				%end;
				%else %do;
					(calculated income / EQ_SS) as EQ_INC 
				%end;
			FROM WORK.&_dsn.1 AS p
			LEFT JOIN Hbdb.&Hds  h 
				ON (p.PB010 = H.HB010) AND (p.PB020 = H.HB020) AND (p.PHID = H.HB030)
			LEFT JOIN idb.&ds as idb 
				ON (idb.DB010 = p.PB010) AND (idb.DB020 = p.PB020) AND (idb.DB030 = p.PHID)
		  	GROUP BY PB020, PHID
			ORDER BY PB020, PHID;

			/* retrieve table (at personal level) with equivalised composite income variable 
			* reassigned to all household members and personel weight */
			CREATE TABLE WORK.&_dsn.3 as 
			SELECT 
				DB010 as TIME, 
				DB020 as GEO FORMAT=$4. LENGTH=4, 
				DB030, 
				RB030,
				%if %macro_isblank(weight) %then %do;
					1. as &weight,
				%end;
				%else %do; 
					&weight,
				%end;
				count(RB030) as NTOT,
				sum(&weight) as NTOTWGH, 
				(case when calculated NTOT < 20 then 2
					when calculated NTOT < 50 then 1
					else 0
				end) as FLAG,
				EQ_INC
			FROM idb.&ds as idb
			LEFT JOIN WORK.&_dsn.2  p 
				ON (idb.DB010 = p.PB010) AND (idb.DB020 = p.PB020) AND (idb.DB030 = p.PHID)
			WHERE DB020="&ctry" and DB010=&yyyy
			%if not %macro_isblank(cond) %then %do;
			    and &cond;
			%end;
			;
		quit;
 
		%work_clean(&_dsn.1, &_dsn.2);

		/* add*/
        %ds_isempty(&_dsn.3, var=GEO, _ans_=ans);
			 
		%if %error_handle(WarningParameter, 
			&ans EQ 1, 
			txt=%bquote(! No data available for &ctry !), verb=warn) %then 
		%goto warning4;
		 
       /* end */
		/* order the resulting table by income value (prior operation necessary to compute the#
		* Gini coefficients) */
		PROC SORT data=WORK.&_dsn.3;
			by EQ_INC;
		run;

		/* compute the Gini coefficients for the considered (ordered) variable using the 
		* given weight */
		DATA WORK.&output(DROP=EQ_INC &weight ss swt swtvar swt2var swtvarcw);
			SET WORK.&_dsn.3(DROP=DB030 RB030) end=last;
			RETAIN swt swtvar swt2var swtvarcw ss 0;
			ss + 1;
			swt +&weight;
			swtvar + &weight * EQ_INC;
			swt2var + &weight *&weight * EQ_INC;
			swtvarcw + swt *&weight * EQ_INC;
			if last then do;
				GINI  = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1);
				output;
			end;
			/* DROP swt swtvar swt2var swtvarcw ss; */
		run;

		/* if we ever wanted to compute some Gini index on a single observation, we would do:
		%local GINI;
		%gini(&_dsn.3, EQ_INC, weight=&weight, _gini_=GINI, method=, issorted=YES, lib=WORK);
		*/
        %warning4:
	
		%work_clean(&_dsn.3);
			
 
	%mend gini_compute;

	%macro gini_update(yyyy, geo, input, ilib, output, olib);
		DATA &olib..&output;
			SET &olib..&output(WHERE=(not(time=&yyyy and geo = "&geo")))
		    	&ilib..&input; 
		run; 
	%mend gini_update;

	%macro gini_aggregate(yyyy, zone, ctrylst, input, ilib, output, olib);
		%local _dsn;
		%let _dsn=TMp&sysmacroname;

		PROC SQL;
			CREATE TABLE WORK.&_dsn AS 
			SELECT GINI, 
				NTOTWGH, 
				NTOT,
				(GINI * NTOTWGH) as wval
			FROM &ilib..&input
			WHERE time = &yyyy and geo in %sql_list(&ctrylst); /* (%list_quote(&ctrylst)) */

			CREATE TABLE &olib..&output AS
			/* INSERT INTO &olib..&output */
			SELECT "&zone" as geo FORMAT=$4. LENGTH=4,
				&yyyy as time,
				(sum(wval) / sum(NTOTWGH)) as GINI,
				(case when sum(NTOT) < 20 then 2
					when sum(NTOT) < 50 then 1
					else 0
					end) as FLAG,
				sum(NTOT) as NTOT,
				sum(NTOTWGH) as NTOTWGH 
			FROM WORK.&_dsn;
		quit;

		%work_clean(&_dsn);
	%mend gini_aggregate;

	/* create the output table if it does not already exist */
	%if "&existsOutput"="NO" %then %do;
		PROC SQL;
		CREATE TABLE &olib..&odsn 
			(GEO char(4),
			TIME num(4),
			GINI num,
			FLAG num,
			NTOT num,
			NTOTWGH num
			);
		quit;
	%end;
    %local ans1;
	%let ans1=;
	/* run the operation (generation+update) for:
	 * 	- all years in &years, and 
	 * 	- all countries/zones in &geos */
	%do _iy=1 %to %list_length(&year);		/* loop over the list of input years */

		%let yyyy=%scan(&year, &_iy);
		%macro_put(&_mac, txt=Loop over %list_length(&geo) zones/countries for year &yyyy); 

		/* set/locate automatically all libraries of interest for the given year */
		%silc_db_locate(X, &yyyy, src=bdb, db=P H, _ds_=ds, _path_=path);
		%let Ppath = %scan(&path, 1, %quote( )); %let Pds=%scan(&ds, 1);
		libname Pbdb "&Ppath";
		%let Hpath = %scan(&path, 2, %quote( )); %let Hds=%scan(&ds, 2);
		libname Hbdb "&Hpath";
		%silc_db_locate(X, &yyyy, src=idb, _ds_=ds, _path_=path);
		libname idb "&path";

		/* check that everything is well defined */
		%if %error_handle(ErrorInputDataset, 
				%ds_check(&Pds, lib=Pbdb) NE 0, mac=&_mac,		
				txt=%quote(!!! Input dataset &Pds not found in library PBDB !!!))
				or %error_handle(ErrorInputDataset, 
					%ds_check(&Hds, lib=Hbdb) NE 0, mac=&_mac,		
					txt=%quote(!!! Input dataset &Hds not found in library HBDB !!!))
				or %error_handle(ErrorInputDataset, 
					%ds_check(&ds, lib=idb) NE 0, mac=&_mac,		
					txt=%quote(!!! Input dataset &Pds not found in library IDB !!!)) %then
			%goto exit;

		/* check WEIGHT variable - we do it here only */
		%if not %macro_isblank(weight) %then %do;
			%if %error_handle(ErrorInputParamater, 
					%var_check(&ds, &weight, lib=idb) NE 0, mac=&_mac,		
					txt=%quote(!!! Input weight variable %upcase(&weight) not found in dataset &ds !!!)) %then
				%goto exit;
		%end;

		/* run the operation (generation+update) for:
		 * 	- one single year &yyyy, and 
		 * 	- all countries/zones in &geos */
		%do _ig=1 %to %list_length(&geo); 		/* loop over the list of countries/zones */

			%let area=%scan(&geo, &_ig);
			%let type=%scan(&isgeo, &_ig);
			%macro_put(&_mac, txt=Operation for zone/country &area and year &yyyy); 

			%if &type = 1 %then %do;
				%let ctrylst_in=&area;
			%end;
			%else %if &type = 2 %then %do;

				/* the "list" ctrylst of countries is retrieved from the zone name using the
				* macro %zone_to_ctry for instance: 
				* 		if geo=EU28, then Qctries=BE DE FR IT LU NL DK IE UK ... 		*/
				%zone_to_ctry(&area, time=&yyyy, _ctrylst_=ctrylst);

				/* check what still needs to be computed: this is useful if you have already
				* made the calculation for countries that do belong to the zone 	*/ 
				%ds_isempty(&odsn, var=GEO, _ans_=_ans, lib=&olib);
				%if	&_ans NE 1 %then %do; 
					/* first retrieve the list of countries present in the dataset (i.e. 
					* processed already) */
					%var_to_list(&odsn, GEO, _varlst_=ctrylst_in, distinct=YES);
					/* then update the list of countries with those still to be computed by
					* difference */
					%let ctrylst_in=%list_difference(&ctrylst, &ctrylst_in);		
				%end;
				%else /* no change */
					%let ctrylst_in=&ctrylst;
			%end;

			/* retrieve the total number #{countries to be calculated}; this will be
			*  - 1 if you passed a country that was not calculated already 
			*  - #{countries in the zone} - #{countries already calculated} if you passed a zone
			* then loop over the list of countries that have not been processed yet */
			%do _ic=1 %to %list_length(&ctrylst_in); /* this may be 1 */
				%let ctry=%list_slice(&ctrylst_in, ibeg=&_ic, iend=&_ic);

				/* actually compute the Gini coefficients */
				%gini_compute(&yyyy, &ctry, &weight, gini);
  
				/* update the output */
						
	     		%if %error_handle(WarningParameter, 
					%ds_check(gini, lib=WORK) EQ 1,txt=%bquote(! No data available for  &ctry  !), verb=warn) %then 
	    			%goto warning5;
				%gini_update(&yyyy, &ctry, gini, WORK, &odsn, &olib);
			%end;

			%if &type = 2 %then %do;
				/* update the input/output */
				%gini_aggregate(&yyyy, &area, &ctrylst, &odsn, &olib, gini, WORK);

				/* update the output */
				 
	     		%if %error_handle(WarningParameter, 
					%ds_check(gini, lib=WORK) EQ 1,txt=%bquote(! No data available for  &ctry  !), verb=warn) %then 
	    			%goto warning5;
				%gini_update(&yyyy, &area, gini, WORK, &odsn, &olib);
			%end;
		    %warning5:
            %work_clean(gini);
		%end;

		/* deallocate the libraries */
		libname Pbdb clear;
		libname Hbdb clear;
		libname idb clear;
		%end;
 	/* clean */

	%exit:
%mend income_components_gini;

/** \endcond */

