/** 
## silc_benefits_taxes {#sas_silc_benefits_taxes}
Compute the per-capita benefits and taxes (benefits/allowances; taxes and social security contributions) for given 
geographical area(s) and period(s). 

~~~sas
	%silc_benefits_taxes(geo, year, varaddh=, varaddp=,vartaxes= ,breakdowns1=, breakdowns2=, weight=, 
		type=G, yes_or_not=YES, odsn=Benefits_Taxes_YES, olib=WORK);
~~~

### Arguments
* `geo`  : a list of countries or a geographical area; default: `geo=EU28`; 
* `year` : year of interest;
* `varaddh` : (_option_) list of  social benefits, at household level; default: `varaddh` is empty;
              The fiscal aggregate is attributed to each family  member proportionally to their gross total personal income
* `varaddp` : (_option_) list of social benefits, at personal level;default: `varaddp` is empty; 
* `vartaxes`: (_option_) list of tax/income;default: `vartaxes` is empty; 
* `breakdowns1`:(_option_) list of tax and contribution component;
* `breakdowns2`:(_option_) list of breakdowns variable: default: age and sex.
* `weight` : (_option_) personal weight variable used to weighting the distribution; default:
			`weight=RES_WGT`;
* `type`   : (_option_) flag set to 'N' or 'G' to consider net and gross values respectively;
			default: `type=G`;
* `yes_or_not`:(_option_) flag set to 'YES' or 'NOT' to consider ZERO and NOT ZERO values for benefits/taxes 
				variables respectively;
* `odsn`   : (_option_) generic name of the output datasets; default: `odsn=Ben_taxes`;
* `olib`   : (_option_) name of the output library; by default, when not set, `olib=WORK`;

### Returns
* `odsn` : (_option_) name of the output datasets; default: `odsn=Ben_taxes.&zero`;
* `olib` : (_option_) name of the output library; by default, when not set, `olib=WORK`;

### Example
Let us consider the following configuration parameters:

~~~sas
	%let year=2015;
	%let geo=AT;
	%let type=G;     	* gross values: this is default by the way;
	%let varaddh=HY050 HY060 HY070;
	%let varaddp=PY090G PY100G PY110G PY120G PY130G PY140G;
	%let vartaxes=HY040 HY080 HY090 HY110  PY010 PY021 PY050 PY080;
	%let breakdowns1=HY050 ;
	%let breakdowns2=AGE SEX;
	%let yes_or_not=NOT;  * then %let zero=YES the zero values are included;
	%let weight=RES_WGT ;  * this is the default;
	%let odsn=Ben_taxes.NotZero;
	%let olib=WORK;
~~~
we implicitely compute the Benefits and taxes, normally expressed as:

~~~sas
	%let var=HY050;
	SUM(PY010G,PY020G,PY050G,PY080G,PY090G,PY100G,PY110G,PY130G,PY140G) as totgross at personal level
	SUM(totgross) as tot_H by HH
	&var/tot_H as allowratio_&vars
	allowratio_&var * totgross as new &var
~~~
so as to produce the following `Ben_taxes.NotZero` table in `WORK` library:
| GEO | TIME |  AGE  |  SEX  | BENEFIT_TAX  | MEAN   | FLAG  |  N    |  NTOT |   NTOTWGH   |
|:---:|:----:|:-----:|:-----:|:------------:|:------:|:-----:|:-----:|:-----:|:-----------:|
| AT  |	2015 | Y15-19|  T    |      HY050   | 350.4  |       |  742  |  742  | 518055.49   |	
In practice, the example above realises the following stepwise calculations:

~~~sas
	PROC SQL;  
		CREATE TABLE work.dsn AS
		SELECT *,
    	sum(totgross) as tot_H,
		&var/(calculated tot_H) as allowratio_&var,
		(calculated allowratio_&var)*totgross as tax_&var  
    	FROM BASE 
		where &var>0 
		GROUP BY DB020, DB030
   	 ; 
	QUIT;
	data dsn (drop=tax_&var) ;
		set dsn;
 		&var=tax_&var;
	run;
	PROC TABULATE data=work.dsn out=&var ;
 	   FORMAT AGE f_age9.;
		FORMAT RB090 f_sex.;
 		CLASS DB020;
 		CLASS AGE /MLF;
		CLASS RB090 /MLF;
		VAR &var ;
		weight &weight;
		TABLE DB020 * AGE * RB090, &var  * ( N mean sum sumwgt) /printmiss;
	RUN;
~~~
where the datasets `&idb`, `&Hpdb`, and `&Ppdb` that appear above store the input personal 
and household data. These datasets, as well as the libraries `bdb` and `idb`, can be retrieved 
using the macro [%silc_db_locate](@ref sas_silc_db_locate).

### Notes
1. The list of (net and gross) benefits and taxes components normally considered (hence listed in `varaddp/h` 
and `vartaxes` variables) are to be chosen among: 
	+ social benefits, at personal level (`varaddp`):
		-`PY090G`: unemployment benefits,
		- `PY100G`: old-age benefits,
		- `PY110G`: survivors' benefits,
		- `PY120G`: sickness benefits,
		- `PY130G`: disability benefits,
		- `PY140G`: education-related allowances,
		
	+ social benefits, at household level (`varaddh`):
		-`HY050G`: family/children-related allowances),
		-`HY060G`: social exclusion not elsewhere classified),
		-`HY070G`: housing allowances),
		
	+ tax/income (`vartaxes`):
		-`HY140G`: tax on income and social insurance contributions, tax vs. benefit components separately,
		-`HY120G`: regular taxes on wealth,
		-`PY030G`: employers' social insurance contributions.
		
2. The breakdowns to be considered are generally:
	+ `breakdowns1`: all benefits and taxes variables,
	+ `breakdowns2: `age` (0-4, ........., 95+) and `sex`, e.g. using the following formats:

~~~sas
      VALUE f_age_ (multilabel)
            0 - 4 = "Y0-4"
			5 - 9 = "Y5-9"
			10 - 14 = "Y10-14"
			15 - 19 = "Y15-19"
			20 - 24 = "Y20-24"
			25 - 29 = "Y25-29"
	 	  	30 - 34 = "Y30-34"
			35 - 39 = "Y35-39"
			40 - 44 = "Y40-44"
			45 - 49 = "Y45-49"
			50 - 54 = "Y50-54"
			55 - 59 = "Y50-59"
			60 - 64 = "Y60-64"
			65 - 69 = "Y65-69"
			70 - 74 = "Y70-74"
			75 - 79 = "Y75-79"
			80 - 84 = "Y80-84"
			85 - 89 = "Y85-89"
			90 - 94 = "Y90-94"
	      	95 - HIGH = "Y_GE95"
				;
 	  VALUE f_RB090_ (multilabel)
			1 = "M"
			2 = "F"
			1 - 2 = "T";
~~~	

### References
1. EU-SILC survey reference document [doc65](https://circabc.europa.eu/sd/a/2aa6257f-0e3c-4f1c-947f-76ae7b275cfe/DOCSILC065%20operation%202014%20VERSION%20reconciliated%20and%20early%20transmission%20October%202014.pdf).
2. DG EMPL (2015): ["Wage and income inequality in the European Union"](http://ec.europa.eu/eurostat/cros/system/files/05-2014-wage_and_income_inequality_in_the_eu_0.pdf).
*/ /** \cond */

/* credits: grillma */

%macro silc_benefits_taxes(geo			/* Area of interest 											(REQ) */
					, year			/* Year of interest 											(REQ) */
					, varaddp= 		/* Personal variables 										    (OPT) */
					, varaddh= 		/* Household variables  										(OPT) */
					, vartaxes=	    /* Personal/Household variables 	                            (OPT) */
					, breakdowns1 =	/* Personal/Household variables 	                            (OPT) */
					, breakdowns2 =	/* Personal/Household variables 	                            (OPT) */
					, labels=		/* AGE		SEX		EMPL*/
					, weight= 		/* Weight variable												(OPT) */
					, type=	 		/* Flag describing the nature of income							(OPT) */
                    , yes_or_not=   /* Flag defining to keep/don't keep zero values                 (OPT) */
					, odsn=			/* Output dataset name 											(OPT) */
					, olib=			/* Output library name 											(OPT) */
					);
	/* for ad-hoc works, load PING library if it is not yet the case */
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
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
	%local G_ALLVARADDP
		G_ALLVARADDH
		G_ALLVARTAXES
	     ;
	%let G_ALLVARADDP  = PY010 PY020 PY021 PY030 PY050 PY080 PY090 PY100 PY110 PY120 PY130 PY140 ;
	%let G_ALLVARADDH  = HY050  HY060  HY070;
	%let G_ALLVARTAXES = HY140 HY120 PY030;
	%let G_BREAKDOWNS1 = PY090 PY100  PY110  PY120  PY130  PY140  HY050   HY060  HY070  HY140  HY120;
	%let G_BREAKDOWNS2 = SEX AGE;
    %let G_VARONLYG = HY051 HY052 HY053 HY054 HY061 HY062 HY063 HY064 HY071 HY072 HY073 HY074;
	%let G_VARONLYN = HY145;

 
	%local yy existsOutput
		 _breakdowns1 break1
		isgeo path ds _ans ctrylst ansempty;

    %let path=; 	
	%let ds=;
	%let existsOutput=NO;
	%let _breakdowns1=; 
	%let ansempty=;
	%let break1=; %let break2=; %let break3=; %let break4=; %let break5=;

	/* OLIB/ODSN: check/set default output  */
	%if %macro_isblank(olib) %then 				%let olib=WORK;
	%if %macro_isblank(odsn) %then 				%let odsn=Ben_Taxes;
	%else 										%let odsn=%upcase(&odsn);

	%let odsn=&odsn&yes_or_not;
	
	%if %error_handle(ExistingDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, 
			txt=%bquote(! Output table already exists - Results will be appended!),verb=warn) %then %do;
		%let existsOutput=YES;
		%goto warning1; 
	%end;
	%warning1:

	/* create the output table if it does not already exist */
	%if "&existsOutput"="NO" %then %do;
		PROC SQL;
		CREATE TABLE &olib..&odsn 
			(GEO char(4),
			TIME num(4),
			%do _k=1 %to %list_length(&labels);   
               	%scan(&labels, &_k) char(10), 
			%end;
			benefit_tax char(10),
			MEAN num,
			FLAG num,
			n num,
			NTOT num,
			NTOTWGH num
			);
		quit;
	%end;
		
	/* GEO: check/set */
	%if %macro_isblank(geo) %then	%let geo=EU28;
	/* clean the list of geo and retrieve type */
	%str_isgeo(&geo, _ans_=isgeo, _geo_=geo);
	%if %error_handle(ErrorInputParameter, 
			%list_count(&isgeo, 0) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong parameter GEO: must be country/geographical zone ISO code(s) !!!)) %then
		%goto exit;


	/* YEAR: check/set */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&year, type=INTEGER, range=%eval(2003)) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for input YEAR !!!)) %then
		%goto exit;
	%else 
		%let yy=%substr(&year,3,2);

	/* TYPE: check/set */
	%if %macro_isblank(type) %then				%let type=G;
	%else 										%let type=%upcase(&type);
    /* YES_OR_NOT: check/set */
	%if %macro_isblank(yes_or_not) %then		%let yes_or_not=YES;
	%else 										%let yes_or_not=%upcase(&yes_or_not);
 

	%if %error_handle(ErrorInputParameter, 
			%par_check(&type, type=CHAR, set=N G) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for income: must be Gross (G) or Net (N) !!!)) %then
		%goto exit;
	%else

	%let list1=%list_intersection(&varaddp, &G_ALLVARADDP);
	%let list2=%list_intersection(&varaddh, &G_ALLVARADDH);
	%let list3=%list_intersection(&vartaxes, &G_ALLVARTAXES);

	/* VARADDh/VARADDp/TAXES: check variables */
	%if %error_handle(ErrorInputParameter, 
			%list_difference(&varaddp, &list1) NE , mac=&_mac,		
			txt=%bquote(!!! Unrecognised social benefits, at personal level - Must be in &G_ALLVARADDP !!!)) 
			or %error_handle(ErrorInputParameter, 
				%list_difference(&varaddh, &list2) NE , mac=&_mac,		
				txt=%bquote(!!! Unrecognised social benefits, at household level - Must be in &G_ALLVARADDH !!!))  
				or %error_handle(ErrorInputParameter, 
					%list_difference(&vartaxes, &list3) NE , mac=&_mac,		
					txt=%bquote(!!! Unrecognised tax/income - Must be in &G_ALLVARTAXES !!!)) %then
		%goto exit;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(varaddp) EQ 1 and %macro_isblank(varaddh) EQ 1 and %macro_isblank(vartaxes) EQ 1, mac=&_mac,		
			txt=%quote(!!! Missing Taxes/Household/personal components of income/benefits !!!)) %then
		%goto exit;

	/* add the extension TYPE to the list of negative/positive component variables */
	%if not %macro_isblank(varaddp) %then %do;
		%let varaddp = %list_append(&varaddp, %list_ones(%list_length(&varaddp), item=&type), zip=_EMPTY_);
	%end;
	%if not %macro_isblank(varaddh) %then %do;
		%let varaddh = %list_append(&varaddh, %list_ones(%list_length(&varaddh), item=&type), zip=_EMPTY_);
	%end;
	%if not %macro_isblank(vartaxes) %then %do;
		%let vartaxes = %list_append(&vartaxes, %list_ones(%list_length(&vartaxes), item=&type), zip=_EMPTY_);
	%end;
	%if not %macro_isblank(breakdowns1) %then %do;
		%let breakdowns1 = %list_append(&breakdowns1, %list_ones(%list_length(&breakdowns1), item=&type), zip=_EMPTY_);
	%end;
	/* special cases: some components in VARADDP are either G only or N only... fix
	* see variables G_VARONLYN and G_VARONLYG declared in compute file */
	%if %error_handle(IgnoredParameter, 
			"&type" EQ "G" and %macro_isblank(%list_intersection(&varaddp, &G_VARONLYN)) NE 1, 
			txt=%bquote(! Components in %upcase(&G_VARONLYN) are Net only - Ignored !), verb=warn) %then %do; 
		%let varaddp = %list_difference(&varaddp, &G_VARONLYN);
		%goto warning2;
	%end;
	%if %error_handle(IgnoredParameter, 
			"&type" EQ "N" and %macro_isblank(%list_intersection(&varaddp, &G_VARONLYG)) NE 1, 
			txt=%bquote(! Components in %upcase(&G_VARONLYG) are Gross only - Ignored !), verb=warn) %then %do; 
		%let varaddp = %list_difference(&varaddp, &G_VARONLYG);
		%goto warning2;
	%end;
	%warning2:

	%if %error_handle(IgnoredParameter, 
			"&type" EQ "G" and %macro_isblank(%list_intersection(&varaddh, &G_VARONLYN)) NE 1, 
			txt=%bquote(! Components in %upcase(&G_VARONLYN) are Net only - Ignored !), verb=warn) %then %do; 
		%let varaddh = %list_difference(&varaddh, &G_VARONLYN);
		%goto warning3;
	%end;
	%if %error_handle(IgnoredParameter, 
			"&type" EQ "N" and %macro_isblank(%list_intersection(&varaddh, &G_VARONLYG)) NE 1, 
			txt=%bquote(! Components in %upcase(&G_VARONLYG) are Gross only - Ignored !), verb=warn) %then %do; 
		%let varaddh = %list_difference(&varaddh, &G_VARONLYG);
		%goto warning3;
	%end;
	%warning3:

		%if %error_handle(IgnoredParameter, 
			"&type" EQ "G" and %macro_isblank(%list_intersection(&vartaxes, &G_VARONLYN)) NE 1, 
			txt=%bquote(! Components in %upcase(&G_VARONLYN) are Net only - Ignored !), verb=warn) %then %do; 
		%let vartaxes = %list_difference(&vartaxes, &G_VARONLYN);
		%goto warning4;
	%end;
	%if %error_handle(IgnoredParameter, 
			"&type" EQ "N" and %macro_isblank(%list_intersection(&vartaxes, &G_VARONLYG)) NE 1, 
			txt=%bquote(! Components in %upcase(&G_VARONLYG) are Gross only - Ignored !), verb=warn) %then %do; 
		%let vartaxes = %list_difference(&vartaxes, &G_VARONLYG);
		%goto warning4;
	%end;
	%warning4:
	%if %error_handle(IgnoredParameter, 
			"&type" EQ "G" and %macro_isblank(%list_intersection(&breakdowns1, &G_VARONLYN)) NE 1, 
			txt=%bquote(! Components in %upcase(&G_VARONLYN) are Net only - Ignored !), verb=warn) %then %do; 
		%let breakdowns1 = %list_difference(&breakdowns1, &G_VARONLYN);
		%goto warning5;
	%end;
	%if %error_handle(IgnoredParameter, 
			"&type" EQ "N" and %macro_isblank(%list_intersection(&breakdowns1, &G_VARONLYG)) NE 1, 
			txt=%bquote(! Components in %upcase(&G_VARONLYG) are Gross only - Ignored !), verb=warn) %then %do; 
		%let breakdowns1 = %list_difference(&breakdowns1, &G_VARONLYG);
		%goto warning5;
	%end;
	%warning5:

	/* extract the list of breakdowns1 variables not already seleted in varaddp varaddh vartaxes */
	%let break1=%list_intersection(&breakdowns1, &varaddp);
	%let break2=%list_difference(&breakdowns1,&break1);
	%put break1=&break1;
	%put break2=&break2;

    %if %error_handle(IgnoredParameter, 
			  %macro_isblank(break2) EQ 1 , mac=&_mac, 
			txt=%bquote(! Components in %upcase(&breakdowns1) are included in P variables !), verb=warn) %then %do; 
		%let _breakdowns1 = ;
		%goto warning6;
	%end;

    %let break3 = %list_intersection(&break2, &varaddh);
	%let break4=%list_difference(&break2,&break3);
	%put break3=&break3;
    %put break4=&break4;

  	%if %error_handle(ErrorInputParameter, 
			 %macro_isblank(break4) EQ 1 , mac=&_mac,	
			txt=%bquote(!ALL Components in %upcase(&breakdowns1) are included in H variable !), verb=warn) %then %do; 
        %let _breakdowns1 = ;
		%goto warning6;
	%end;

	%let break5 = %list_intersection(&break4, &vartaxes);
	
	%let break6=%list_difference(&break4,&break5);

	%put break6=&break6;
	
  	%if %error_handle(IgnoredParameter, 
		   %macro_isblank(break6) EQ 1, mac=&_mac, 
			txt=%bquote(! Components in %upcase(&breakdowns1) are included in Taxes variable !), verb=warn) %then %do; 
			%put  &break4=break4;
        %let _breakdowns1 = ;
		%goto warning6;
	%end;
	%else 	%let _breakdowns1 = &break6;

	%warning6:

	/* WEIGHT: check variable - we do it here only
	* by default, WEIGHT is left as blank and the income distribution is not weighted!
	* when WEIGHT is passed, then it is checked later on, after the input IDB library has
	* been defined (see below) */
	%if %error_handle(WarningParameter, 
			%macro_isblank(weight) EQ 1, 
			txt=%bquote(! No weight variable passed - Uniform weighting is used !), verb=warn) %then 
		%goto warning7;
	%warning7:
	%macro benefits_taxes_compute(yyyy, ctry,dsn, weight, output);
		/************************************************************************************/
	/**                                 actual extraction                              **/
	/************************************************************************************/
    %local _i 
		_v
		listidb _libjoin  libjoin
		listidh _listidh
		listidt _listidt
		listbreak1 _listbreak1
  		;
     %let listidb=; %let listpdb=; %let listaddp=; %let listaddh=;%let listaddt=;%let listbreak1=;
	 %let _listidb=; %let _listpdb=; %let _listaddp=; %let _listaddh=;%let _listaddt=;%let _listbreak1=;
     %let libjoin=; %let _libjoin=;

	 %let dsn=TMP;

	 %let idblib=idb;
	 
     PROC SQL;
     CREATE TABLE &dsn  AS SELECT
     
	 IDB.DB010,IDB.DB020,IDB.DB030,idb.&weight, 
	 %do _i=1 %to %list_length(&breakdowns2);
	     	 %let _v=%scan(&breakdowns2, &_i);
             %let ans=%var_check(idb&yy, &_v, lib=&idblib);
			
             %if &ans=0 %then %do;
				 %let listidb=&listidb idb.&_v;
			 %end;
			 %else %do;
					%let _vtype=%upcase(%substr(&_v,1,1));
			        %let  listpdb=&listpdb   &_vtype..&_v;
					%let libjoin =&libjoin &_vtype;
			 %end;
	 %end;
     %if "&listpdb" NE "" %then %do;
			 %let _listpdb=%list_quote(&listpdb, mark=_EMPTY_, rep=%quote(,));
			 %put &_listpdb;
            &_listpdb,
	 %end;
	 %if "&listidb" NE "" %then %do;
			 %let _listidb=%list_quote(&listidb, mark=_EMPTY_, rep=%quote(,));
			 %put &_listidb marina;
			 &_listidb,
	 %end;
  	 %do _i=1 %to %list_length(&varaddp);
	 		%let _v=%scan(&varaddp, &_i);
	        %let _vtype=%upcase(%substr(&_v,1,1));
			%let libjoin =&libjoin &_vtype;
			%let listaddp=&listaddp   &_vtype..&_v;
	 %end;

	 %if "&listaddp" NE "" %then %do;
			%let _listaddp=%list_quote(&listaddp, mark=_EMPTY_, rep=%quote(,));
            &_listaddp,
			SUM(&_listaddp,0)  as totgross,  /* total gross values per individual */
	 %end;
	 %do _i=1 %to %list_length(&varaddh);
	 		%let _v=%scan(&varaddh, &_i);
	     	%let _vtype=%upcase(%substr(&_v,1,1));
			%let libjoin =&libjoin &_vtype;
			%let listaddh=&listaddh   &_vtype..&_v;
	 %end;

	 %if "&listaddh" NE "" %then %do;
			%let _listaddh=%list_quote(&listaddh, mark=_EMPTY_, rep=%quote(,));
			&_listaddh,
	 %end;
	 %do _i=1 %to %list_length(&vartaxes);
            %let _v=%scan(&vartaxes, &_i);
			%let _vtype=%upcase(%substr(&_v,1,1));
			%let libjoin =&libjoin &_vtype;
			%let listaddt=&listaddt   &_vtype..&_v;
	 %end;


	 %if "&listaddt" NE "" %then %do;
	     %let _listaddt=%list_quote(&listaddt, mark=_EMPTY_, rep=%quote(,));
		 &_listaddt,
	 %end;
	 %put &_breakdowns1=_breakdowns1 marina;
	 %if "&_breakdowns1" NE "" %then %do;
	 	%do _i=1 %to %list_length(&_breakdowns1);    
            %let _v=%scan(&_breakdowns1, &_i);
	        %let _vtype=%upcase(%substr(&_v,1,1));
			%let libjoin =&libjoin &_vtype;
			%let listbreak1=&listbreak1   &_vtype..&_v;
	 	%end;
	
	 	%if "&listbreak1" NE "" %then %do;
	   		%let _listbreak1=%list_quote(&listbreak1, mark=_EMPTY_, rep=%quote(,));
		 	&_listbreak1,
	 	%end;
	 %end;

     %let _libjoin=%list_unique(&libjoin, casense=no, sep=%quote( ));  /* remove double libname */
	 IDB.RB030
	 from &idblib..IDB&yy as IDB
	 %do  _i=1 %to %list_length(&_libjoin);
	      %let _lib=%scan(&_libjoin, &_i);
		  %let lib=&_lib.ds;
	      left JOIN &_lib.pdb.c&yy&_lib AS &_lib ON (idb.DB010 = &_lib..&_lib.B010) AND (idb.DB020 = &_lib..&_lib.B020)
		  AND 
		  %if (&_lib=P or &_lib=R) %then %do;
				(idb.RB030 = &_lib..&_lib.B030)
		  %end; 
		  %else %if (&_lib=H or &_lib=D) %then %do;
				(idb.DB030 = &_lib..&_lib.B030)
		  %end;
	 %end;
	 WHERE IDB.DB020="&ctry" and IDB.DB010=&yyyy
	 order BY  idb.DB020, idb.DB030, idb.RB030;
	 QUIT;
 
	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local dsn
		path ds
		Ppath Pds
		Hpath Hds
		_i _iy _ig _ic
		ctry ctrylst ctrylst_in ctrylst_sql
	 	area type per_breakdowns2
		_ans;

	%let path=; 	
	%let ds=;
	%let area=;
	%let ctrylst=;

	PROC FORMAT;
	    VALUE f_age_ (multilabel)
 
          	0 - 4 = "Y0-4"
			5 - 9 = "Y5-9"
			10 - 14 = "Y10-14"
			15 - 19 = "Y15-19"
			20 - 24 = "Y20-24"
			25 - 29 = "Y25-29"
	 	  	30 - 34 = "Y30-34"
			35 - 39 = "Y35-39"
			40 - 44 = "Y40-44"
			45 - 49 = "Y45-49"
			50 - 54 = "Y50-54"
			55 - 59 = "Y50-59"
			60 - 64 = "Y60-64"
			65 - 69 = "Y65-69"
			70 - 74 = "Y70-74"
			75 - 79 = "Y75-79"
			80 - 84 = "Y80-84"
			85 - 89 = "Y85-89"
			90 - 94 = "Y90-94"
	      	95 - HIGH = "Y_GE95"
			;
	VALUE f_RB090_ (multilabel)
			1 = "M"
			2 = "F"
			1 - 2 = "T";

	run;

	%let per_breakdowns2=%list_quote(&breakdowns2, mark=_EMPTY_, rep=%quote(*));;
	
    %put in &_mac: per_breakdowns2=&per_breakdowns2 yes_or_not=&yes_or_not marina;

    %do _i=1 %to %list_length(&breakdowns1);   
	    %let var=%scan(&breakdowns1, &_i);
		
		PROC SQL; 
			CREATE TABLE work.&dsn._1 AS 
			select * 
			FROM &dsn 
			%if "&yes_or_not"="NOT" %then %do;
			 	where &var>0 
			%end;
			GROUP BY DB020, DB030
		    ; 
		QUIT;
    	%ds_isempty(&dsn._1, var=&var, _ans_=_ans);

		%if &_ans NE 0 %then  %goto WORK;
		PROC SQL; 
		CREATE TABLE work.&dsn._1 AS
			SELECT *,
			
			%if   %upcase(%substr(&var,1,1))= H %then %do;
			    sum(totgross) as tot_H,
				&var/(calculated tot_H) as allowratio_&var,
				(calculated allowratio_&var)*totgross as tax_&var, 
			%end;
			%else %do;
				&var as tax_&var,  /* to verify */
			%end;
			"dummy" as dummy
		    FROM &dsn 
			%if "&yes_or_not"="NOT" %then %do;
			%put pippo;
				where &var>0 
			%end;
			GROUP BY DB020, DB030
		    ; 
		QUIT;
		DATA &dsn._1 (drop=tax_&var dummy) ;
			set &dsn._1;
		 	&var=tax_&var;
		RUN;

	/* perform the tabulate operation
	* define at the same time the class order used to retrieve the correct statistics based on 
	* in the table are inserted throughout the TABULATE procedure */
		PROC TABULATE data=WORK.&dsn._1 out=WORK.&var ; 
			CLASS DB020; 								/* DB020 will be used as row */
			%do _j=1 %to %list_length(&breakdowns2);
				%let dim=%scan(&breakdowns2, &_j);
			    CLASS &dim /MLF;
		        FORMAT &dim f_&dim._.;
			%end;		/* &dim will be used as row through &per_dimensions */
			var &var;									/* &var will be used as row */
			weight &weight;
			TABLE DB020 * &per_breakdowns2, &var * (N mean sum sumwgt) /printmiss;
		RUN;
		PROC SQL;
			insert into  &olib..&odsn SELECT 
			dB020 as geo FORMAT=$5. LENGTH=5,
			&yyyy as time,
			%do _k=1 %to %list_length(&breakdowns2);   
                %let lab=%scan(&labels, &_k); 
				%scan(&breakdowns2, &_k) as &lab, 
			%end;
		    "&var" as benefit_tax,
			&var._mean as mean,
		   	(case when sum(&var._N) < 20 then 2
				  when sum(&var._N) < 50 then 1
				  else 0
			      end) as flag,
			&var._N as n,
			sum(&var._N) as ntot,
			sum(&var._SumWgt) as totwgh
			FROM &var    
			GROUP BY DB020,
			%let _breakdowns2=%list_quote(&breakdowns2, mark=_EMPTY_, rep=%quote(,));
		    &_breakdowns2;
		QUIT; 
 
		*%work_clean(&dsn._1);
	    %WORK:
	%end;  /* end loop var */
	%exit:
	%mend benefits_taxes_compute;
	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/
	%macro benefits_taxes_aggregate(yyyy, zone, ctrylst, input, ilib, output, olib);
		%local _dsn _k;
		%let _dsn=TMp&sysmacroname;
        
		PROC SQL;
			CREATE TABLE WORK.&_dsn AS 
				SELECT 
			    %do _k=1 %to %list_length(&&labels);   
                	%let lab=%scan(&labels, &_k); 
					%scan(&labels, &_k) as &lab, 
				%end;
                BENEFIT_TAX, 
				NTOTWGH, 
				NTOT,
				N,
				(mean * NTOTWGH) as wval
			FROM &ilib..&input
			WHERE time = &yyyy and geo in %sql_list(&ctrylst); /* (%list_quote(&ctrylst)) */

			/*CREATE TABLE &olib..&output AS*/
            INSERT INTO &olib..&output  
		 		SELECT "&zone" as geo FORMAT=$4. LENGTH=4,
				&yyyy as time,
				%do _k=1 %to %list_length(&&labels);   
                	%let lab=%scan(&labels, &_k); 
					%scan(&labels, &_k) as &lab, 
				%end;
				BENEFIT_TAX,
				(sum(wval) / sum(NTOTWGH)) as mean,
				(case when sum(NTOT) < 20 then 2
					when sum(NTOT) < 50 then 1
					else 0
					end) as FLAG,
				sum(N) as N,
				sum(NTOT) as NTOT,
				sum(NTOTWGH) as NTOTWGH 
			FROM WORK.&_dsn
               GROUP BY DB020,
			   %let _labels=%list_quote(&labels, mark=_EMPTY_, rep=%quote(,));
		       &_labels;;
		quit;

		*%work_clean(&_dsn);
	%mend benefits_taxes_aggregate;

		/* UPDATE PROCEDERE */
	%macro benefits_taxes_update(yyyy, geo, input, ilib, output, olib);
		DATA &olib..&output;
			SET &olib..&output(WHERE=(not(time=&yyyy and geo = "&geo")))
		    	&ilib..&input; 
		RUN; 
	%mend benefits_taxes_update;
	
	/* run the operation (generation+update) for:
	 * 	- all years in &years, and 
	 * 	- all countries/zones in &geos */
	%do _iy=1 %to %list_length(&year);		/* loop over the list of input years */

		%let yyyy=%scan(&year, &_iy);
		%macro_put(&_mac, txt=Loop over %list_length(&geo) zones/countries for year &yyyy); 

		/* set/locate automatically all libraries of interest for the given year */
		%silc_db_locate(X, &yyyy, src=pdb, db=P H, _ds_=ds, _path_=path);
		%let Ppath = %scan(&path, 1, %quote( )); %let Pds=%scan(&ds, 1);
		libname Ppdb "&Ppath";
		%let Hpath = %scan(&path, 2, %quote( )); %let Hds=%scan(&ds, 2);
		libname Hpdb "&Hpath";
		%silc_db_locate(X, &yyyy, src=idb, _ds_=ds, _path_=path);
		libname idb "&path";
		%put "&Ppath" "&Hpath";
 
		/* check that everything is well defined */
		%if %error_handle(ErrorInputDataset, 
				%ds_check(&Pds, lib=Ppdb) NE 0, mac=&_mac,		
				txt=%quote(!!! Input dataset &Pds not found in library Ppdb !!!))
				or %error_handle(ErrorInputDataset, 
					%ds_check(&Hds, lib=Hpdb) NE 0, mac=&_mac,		
					txt=%quote(!!! Input dataset &Hds not found in library Hpdb !!!))
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

				/* actually compute the benefits_taxes coefficients */
			    %benefits_taxes_compute(&yyyy, &ctry,TMP, &weight, &odsn);
		
             %end;
			 /* update the output */
			 %ds_isempty(&odsn, var=GEO, _ans_=ansempty);
             %if (&ansempty EQ 0 and "&olib" NE "WORK") %then   %benefits_taxes_update(&yyyy, &ctry, &odsn, WORK, &odsn, &olib);
		
			 %if &type = 2 %then %do;

				%put &area, time=&yyyy, _ctrylst_=&ctrylst &yyyy, &area, &ctrylst, &odsn, &olib, &odsn, WORK marina;
			/* update the input/output */
		   	    %benefits_taxes_aggregate(&yyyy, &area, &ctrylst, &odsn, &olib, &odsn, WORK);

			/* update the output */
			 %ds_isempty(&odsn, var=GEO, _ans_=ansempty);
        
		     %if (&ansempty EQ 0 and "&olib" NE "WORK") %then   %benefits_taxes_update(&yyyy, &ctry, &odsn, WORK, &odsn, &olib);
			 %end;

		%end;

		/* deallocate the libraries */
		libname Ppdb clear;
		libname Hpdb clear;
		libname idb clear;
	%end;

	/* clean */
	*%work_clean(&odsn);

	%exit:
%mend silc_benefits_taxes;

/** \endcond */
