/** 
## silc_pension_gap_coverage_rate {#sas_silc_pension_gap_coverage_rate}
Compute indicators on gender pension gap, _i.e._ gender differences in pension 
outcomes/benefits across EU-28.

~~~sas
	%silc_pension_gap_coverage_rate(year, geo=, odsn=, weight=, olib=, odir=, ext=);
~~~

### Arguments
* `year`: one or more years of interest;
* `geo` : (_option_) a list of countries or a geographical area; default: `geo=EU28`;
* `weight`: (_option_) weight used for individuals; by default, `weight=PB040`;
* `ext`:(_option_) generic output dataset name; by default, `ext=_in_pension`.	 
 
### Returns
* `odsn`: (_option_) a (list of) string characterising the output indicator(s) to be 
	calculated; it can be either:
		+ `GAP` when the gender gap in pension is calculated; a dataset `GAP` is created
			and exported to a csv file named `GENDER_&year&ext` for all available 
			countries/areas and all year(s) of interest;
		+ `COVERAGE` when the coverage rate is calculated; _ibid_, a dataset `COVERAGE` 
			is created and exported to a csv file named `COVERAGE_&year&ext` for all 
			available countries/areas and all year(s) of interest;

	default: `odsn=GAP COVERAGE`, _i.e._ both are calculated;
* `olib`:  (_option_) name of the library where the output indicator(s) is (are)
	stored; by default: `olib=WORK`;
* `odir`: (_option_) name of the directory where the output file(s) is (are) exported to.			 

### Example
In order to (re)generate two csv files `GAP_2016_in_pension` and  `COVERAGE_RATE_2016_in_pension` 
for geo=EU28, stored in &odir, you can simply launch:
~~~sas
	%silc_pension_gap_coverage_rate(2016, geo=EU28, odsn=GAP COVERAGE, weight=PB040, ext=_in_pension, olib=WORK,
		odir=&odir , ext=_in_pension);
~~~

### Notes
1. The gender gap in pensions is computed, in the simplest possible way, by comparing average
male and female pensions in the manner defined in the "Pension Adequacy Report" (Box 3.4, 
page 150):

<img src="img/pension-gap_box3-4_page150.png" border="1" width="60%" alt="Pension gap">
 
In addition, the coverage gap is defined as the extent to which women have less access to the 
pension system than men (_e.g._ zero pension income – as defined in EU-SILC).
2. Note the following methodological issues in the choice made for this indicator: 
* whether to include or not individuals with zero income in the average pension calculation 
(_i.e._ basing the calculation on the total population including non-pensioners),
* whether to consider people over 65 or ‘inner group’ of older people, namely those between 
65 and 79. 

### References
1. ["Current and future income adequacy in old age in the EU"](http://ec.europa.eu/social/main.jsp?catId=738&langId=en&pubId=7828&visible=0&), 
Pension Adequacy Report volumes [I](http://ec.europa.eu/social/BlobServlet?docId=14529&langId=en) 
and [II](https://webgate.ec.europa.eu/emplcms/social/BlobServlet?docId=14545&langId=en), 2015.
2. ["Report on equality between women and men in the EU"](http://ec.europa.eu/newsroom/document.cfm?doc_id=43416), 2017.

### See also
[%silc_pension_population_count](@ref silc_pension_population_count).
*/ /** \cond */

/* credits: grillo, grazzja */

%macro silc_pension_gap_coverage_rate(year 	    /* Area of interest 						  	(REQ) */
							  , odsn        /* Type of calculation (GAP/COVERAGE RATE)   	(REQ) */                                   
							  , weight      /* Weight variable    					      	(REQ) */ 
						 	  , geo=	    /* Country/Zone   						      	(OPT) */
							  , odir=		/* Output directory name						(OPT) */
							  , olib=		/* Output library name 							(OPT) */
							  , ext=  	    /* Generic output dataset name 	          		(OPT) */
						   	  );

 	%local _mac;
 	%let _mac=&sysmacroname;
 	%macro_put(&_mac);

 	/************************************************************************************/
 	/**                                 checkings/settings                             **/
 	/************************************************************************************/
	%local _iy 			/* loop increment for year    		  */
		_ic				/* loop increment for country 		  */
		yyyy   			/* scanned year               	 	  */
		area type       /* area and type of interest  		  */
		isgeo           /* countries list             		  */
	    existsOutput    /* boolean variable           		  */
		ctrylst         /* countries list per specific area   */
		ctrylst_in      /* countries list already calculated  */
		wdsn            /* working output dataset     		  */
		_year           /* list of year with _   as separetor */
		_ans;           /* result from test macro  		      */

	%let existsOutput=NO;
	%let wdsn=TMP;

	%let g_flag=;
	 /* run the operation (generation+update) for:
	 * 	- all years in &years 
	 * 	- all countries/zones in &geos */

	/* ODSN: check/set */
	%if %macro_isblank(odsn)	 	%then 		%let odsn=GAP COVERAGE;
	%else 										%let odsn=%upcase(&odsn);

	%let _ans=%list_ones(%list_length(&odsn), item=0);

	%if %error_handle(ErrorInputParameter,
			%par_check(&odsn, type=CHAR, set=GAP COVERAGE) NE &_ans, mac=&_mac,
			txt=%bquote(!!! Option ODSN not recognised - Must be either GAP or COVERAGE !!!)) %then
		%goto exit;  

	/* GEO: check/set */
	%if %macro_isblank(geo) %then	%let geo=EU28;
	/* clean the list of geo and retrieve type */
	%str_isgeo(&geo, _ans_=isgeo, _geo_=geo);
	%if %error_handle(ErrorInputParameter, 
			%list_count(&isgeo, 0) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong parameter GEO: must be country/geographical zone ISO code(s) !!!)) %then
		%goto exit;
	 /* ODIR/OLIB: check/set default output library */
	%if %error_handle(ErrorInputParameter, 
			%dir_check(&odir)  NE 0 , mac=&_mac,
			txt=%quote(!!! ODIR directory does not exist - !!!)) %then
		%goto exit;

	%if "&olib" NE "WORK"  %then %do;
	    libname olib "&olib"; 
		%let olib=olib;
	%end;

	/* WEIGHT: check variable  */
	%if %error_handle(WarningParameter, 
			%macro_isblank(weight) EQ 1, mac=&_mac, 
		    txt=%bquote(! No weight variable passed - Uniform weighting is used !), verb=warn) %then %do;
		 %let weight=PB040;
	     %goto warning;
	%end;
	%warning:

	/***************************************************************************************/
	/**         creating/temporary and/or permanent dataset                              **/
	/**************************************************************************************/
	%macro create(dsn    		/* permanet dataset to create    */
	   		   	,olib=          /* library to create the dataset */
	       		,labs=          /* labels od dimensions          */
	        	,types=         /* type of dimensions            */
				,lens=          /* lenght of dimensions          */
				,wdsn=        	/* temporary working dataset     */  
	    		);
		/* local variables used in this macro */
		%local _i
			idsn
			ans				/* local test variable */
			warmsg errmsg;	/* error management */

	  	/* working dataset */
	    %if  %macro_isblank(wdsn) EQ 0 		%then   %let wdsn=TMP;

		%if  %ds_check(&wdsn, lib=WORK) EQ 1 %then %do;
		    %if "&dsn"="GAP" %then %do;
				%let vara= geo time  age   sex  unit  ivalue  iflag  unrel  n   nwgh  ntot  totwgh lastup lastuser ;
				%let lena= 15   8     15     1    8      8      8     8      8     8     8     8        8      15    ;
				%let typa= char num  char  char char   num    char   num   num   num  num    num     char    char  ;
			%end;
			%else %if "&dsn"="COVERAGE" %then %do;
					%let vara= geo time  age   sex  npension unit ivalue  iflag  unrel  n   nwgh  ntot  totwgh lastup lastuser  ;
					%let lena= 15   8     15     1      8      8     8      8      8     8     8    8      8       8      15      ;
					%let typa= char num  char  char  num	  char  num    char   num   num   num  num    num     char   char    ;
			%end;
			%ds_create(&wdsn, var=&vara, type=&typa, len=&lena,  ilib=WORK, olib=WORK);
	    %end;

		%if %error_handle(ExistingDataset, 
				%ds_check(&dsn, lib=&olib) EQ 0,  
				txt=! Output table already exist !, verb=warn) %then 
			%goto exit;

		/* final dataset */
		%if "&dsn"="GAP" %then 
			%let idsn=META_INDICATOR_CONTENTS_SEX;
		%else %if "&dsn"="COVERAGE" %then
			%let idsn=META_INDICATOR_CONTENTS;
	 	%ds_create(&dsn, var=&labs, len=&lens, type=&types, idsn=&idsn, olib=&olib, ilib=LIBCFG);

		%exit:
	%mend create;

	/************************************************************************************************/
	/**         extraction                                                                         **/
	/************************************************************************************************/
	%macro extract(yyyy	         /* Single Year of interest                                   (REQ) */
				, clist			 /* Country/geographical area of interest                     (REQ) */
				, weight         /* weight                                                    (REQ) */
				, idb			 /* idb library                                               (REQ) */
				, pdb			 /* idb library                                               (REQ) */
				, odsn			 /* output dataset                                            (REQ) */
				, dimensions=	 /* breakdown variables                                       (OPT) */
				, vsum=		     /* list of varible to sum                                    (OPT) */
				, elderly =      /* boolean value N/Y to take in account the elderly person   (OPT) */
				, pensioners =   /* boolean value N/Y to take in account the pensioner person (OPT) */ 
				);
		/* local variables that depend on the input parameters or simply used inside the macro */
		%local _i		/* loop increment                                     */
			yy			/* year substring, e.g. if year=2012 then yy=12       */
			vtyp		/* type of variable: personal (P) or household (H)    */
			ndim		/* number of dimensions                               */
			dim			/* single scanned dimension                           */
			pvar        /* list vsum variables plus dsn                       */
			_vsum       /* single vsum variables                              */
			__vsum      /* single scanned vsum  plus dsn                      */
			_pvar       /* list vsum variables plus dsn with comma separater  */
		    ;
	 
		/* test whether input parameters GEO and year were passed */
		%if %macro_isblank(clist) or %macro_isblank(yyyy) or  %macro_isblank(vsum)    %then   %goto exit;
	    
		/* proceed ... */
		%let yy=%substr(&yyyy,3,2);
		%let vtyp=%lowcase(%sysfunc(substr(&vsum, 1, 1)));
		%let qctry=%list_quote(&clist);
	 
		/* test the existence of the output dataset */
		%if %error_handle(ExistingDataset, 
				%ds_check(&odsn, lib=WORK) EQ 0,  
				txt=%quote(! Output table already exist- Overwrite !), verb=warn) %then 
			%goto warning;
		%warning: 

		%if %macro_isblank(dimensions)       %then 	%let dimensions= AGE RB090;      /* list separator */
	 	%if %macro_isblank(elderly)    		 %then 	%let elderly=N;                  /* list separator */
		%if %macro_isblank(pensioners)  	 %then 	%let pensioners=Y;               /* list separator */
	 
		/* retrieve the number of dimensions */
		%let ndim=%sysfunc(countw(&dimensions));        /* %list_length(&dimensions) */
		%let nvar=%sysfunc(countw(&vsum)); 		        /* %list_length(&vsum) */

		%local __vsum _vsum pvar _pvar;
		%let pvar=;
		
		%do j=1 %to &nvar; 
			%let _vsum=%scan(&vsum, &j);
			%let __vsum=&vtyp..&_vsum;
			%let pvar=&pvar &__vsum;
		%end;

	    %let _pvar=%list_quote(&pvar, mark=_EMPTY_);

		PROC SQL;
			CREATE TABLE WORK.idb as SELECT
				idb.DB010, 
				idb.DB020,
				idb.DB030,  
			    idb.RB030,
				idb.&weight as WEIGHT,
				/* retrieve all desired dimensions */	
				%do i=1 %to &ndim; 
					%let _dim=%scan(&dimensions, &i);
					idb.&_dim,
				%end;
				/* note that &vtyp takes the value p  depending on the variable vsum  passed */
				SUM(&_pvar,0) as PENSION,
				(CASE WHEN CALCULATED PENSION > 0 THEN 1 ELSE 0 END) AS Npension
			FROM &idb..idb&yy as idb    
				LEFT JOIN &pdb..c&yy.&vtyp as &vtyp on (&vtyp..PB020=idb.DB020 and &vtyp..PB030=idb.RB030)
			WHERE  IDB.DB010=&yyyy and idb.AGE ge 65 and DB020 in (&qctry);
	 	QUIT;

		%if "&odsn"="GAP" %then %do; /* applied only for  gap (program number 1) */
			data &odsn; 
				 set &odsn; 
				 %if &elderly =N and  &pensioners=Y %then %do;
				  	 where PENSION  ne 0;
				 %end;
				 %else %if &elderly =Y and  &pensioners=N %then %do;
				     ;
				 %end;
			run;
	      %end;

		%exit:
	%mend extract;

	/*******************************************************************************************/
	/**         computation                                                                   **/
	/*******************************************************************************************/
	%macro compute(idsn 	        /* input dataset      			     	(REQ)*/
				, yyyy  		 	/* reference year     					(REQ)*/
				, wdsn  		 	/* temporary output dataset     		(REQ)*/
				, dsn               /* output dataset                       (REQ)*/
				, var=           	/* pension/npension                     (REQ)*/
				, dimensions=    	/* breakdown variables                  (OPT)*/
				, labels=        	/* labels for breakdown variables       (OPT)*/
				, iflag=         	/* flag variable 						(OPT)*/
				, stat2=         	/* statistic variable 					(OPT)*/
				);
		%if &stat2= 		%then 	%let stat2=mean;
		%if &iflag= 		%then 	%let iflag=;

		/* locally used variables */
		%local _i			/* loop increment */
			_j			/* loop increment */
			TMP				/* name of the temporary dataset */
			ndim			/* number of dimensions */
			dim				/* single dimension */
			per_dimensions;	/* formatted crossed dimensions */
			 ; 
		%let TMP=TMP_compute;

		/* retrieve the number of dimensions */
		%let ndim=%sysfunc(countw(&dimensions)); /* %list_length(&dimensions) */
		%let per_dimensions=%list_quote(&dimensions, mark=_EMPTY_, rep=%quote(*));;
		%let _dimensions=%list_quote(&dimensions, mark=_EMPTY_, rep=%quote(,));

		/* set default labels */
		%if %macro_isblank(labels) %then %let labels=&dimensions;

		/* define the list of "per variables", i.e. if dimensions=AGE RB090 HT1 QITILE,
		* then we will have per_dimensions=AGE*RB090*HT1*QITILE 
		* this is useful for the following PROC TABULATE */
		PROC FORMAT;
			VALUE  _fmt_RB090_ (multilabel)
				1 = "M"
				2 = "F" 
				;

			VALUE _fmt_age_ (multilabel)	
				65 - HIGH = "Y_GE65"
				65 - 74 = "Y65-74"
				65 - 79 = "Y65-79"
				;
		run;

		/* perform the tabulate operation*/
		%if "&dsn"="COVERAGE" %then %do;
		    PROC TABULATE data=work.IDB out=WORK.&TMP._1 ;
			 	%do _i=1 %to &ndim;
					%let dim=%scan(&dimensions, &_i);
					FORMAT &dim _fmt_&dim._.;
					CLASS &dim / MLF ;						
			 	%end;
		    	CLASS &var ;
		 	 	CLASS DB020;
			 	VAR weight;
			    TABLE DB020  * &per_dimensions, &var * weight * (RowPctSum N Sum) /printmiss;
		    run; 
		 %end;
		 %else %if "&dsn"="GAP" %then %do;
		 	PROC MEANS data=work.idb  &stat2 N sumwgt noprint;
				CLASS DB020; 			/* DB020 will be used as row */
				%do _i=1 %to &ndim;
					%let dim=%scan(&dimensions, &_i);
					FORMAT &dim _fmt_&dim._.;
					CLASS  &dim / MLF ;	/* &dim will be used as row through &per_dimensions */
				%end;
				VAR &var;				/* &var will be used as row */
				WEIGHT WEIGHT;
				OUTPUT out=work.&TMP &stat2()=&stat2._20 N()=n sumwgt()=sum_of_WGHT ;
			run;
			%ds_select(&TMP, &TMP._1, where=_TYPE_=7);
		%end;

		PROC SQL;
		    INSERT INTO work.&wdsn  
		    SELECT DISTINCT
				tmp.DB020 as geo FORMAT=$5. LENGTH=5,
		 		&yyyy as time,
		   		%do _i=1 %to &ndim;
					%let dim=%scan(&dimensions, &_i);
					%let lab=%scan(&labels, &_i);
					&dim as &lab,
				%end; 
				%if "&dsn"="COVERAGE" %then %do;
		 			tmp.&var as &var,
		  			"Dif" as unit, 
		 			tmp.weight_PctSum_1101 as ivalue,
				%end;
				%else %if "&dsn"="GAP" %then %do;
					"avg" as unit, 
					mean_20 as ivalue,
				%end;
		   		"&iflag "  as iflag,
				%if "&dsn"="COVERAGE" %then %do;
		 			(case when sum(tmp.weight_N) < 20  then 2
		  			 	when sum(tmp.weight_N) < 50  then 1
		  		 		else 0 end) as unrel,
					tmp.weight_N as n,
		 			tmp.weight_sum as nwgh,
		 			sum(tmp.weight_N) as ntot,
		     		sum(tmp.weight_Sum) as totwgh,
				%end;
				%else %if "&dsn"="GAP" %then %do;
					(case when n < 20 then 2
					when n < 50 then 1
					else 0 end) as unrel,
		            n as n,
					sum_of_WGHT as nwgh,
					n as ntot,
					sum(sum_of_WGHT) as totwgh,
				%end;
		    	"&sysdate" as lastup,
		    	"&sysuserid" as	lastuser FORMAT=$15. LENGTH=15 
			FROM WORK.&TMP._1 as tmp
		    GROUP BY tmp.DB020,
			%do _i=1 %to &ndim;
				%let dim=%scan(&dimensions, &_i);
				tmp.&dim,
			%end;
			unit;
		quit; 

		%work_clean(&TMP, &TMP._1);
		%exit:
	%mend compute;

	/**************************************************************************************/
	/**         update rate                                                              **/
	/**************************************************************************************/
	%macro update(odsn  	/* output dataset                         (REQ)*/
			   , idsn  	    /* input  dataset                         (REQ)*/
			   , ctry       /* reference country                      (REQ)*/
			   , yyyy		/* single reference year                  (REQ)*/
			   , var   	    /* variable to analyze                    (OPT)*/
			   , cond=    	/* condition to apply to ds_append macro  (OPT)*/
			   , where=     /* condition to apply to ds_select macro  (OPT)*/
			   , olib=      /* output libname                         (OPT)*/
			   , iflag=     /* iflag value                            (OPT)*/
		       );
		%local ans TMP;

		%let TMP=TMP_update;

		%if %macro_isblank(var)         %then 	%let var=npension; 
		%if %macro_isblank(iflag)       %then 	%let iflag= ;  

		%if "&odsn"="COVERAGE" %then %do;
		    %ds_select(&idsn, &TMP._1, where=%str(&var=1));  /* filter: selection of retirement persons */
		%end;
		%else %if "&odsn"="GAP" %then %do;
			%ds_copy(&idsn, &TMP._1);
		    %ds_select(&idsn, &TMP, where=%str(sex="F")); 	 /* keep for later... */
		%end;

		%ds_sort(&TMP._1, asc=GEO AGE SEX);

		%if "&odsn"="COVERAGE" %then %do;
			DATA work.&TMP._1;                                            
		 		SET work.&TMP._1;
				f_ivalue=lag(ivalue);
				f_n=lag(ivalue);
				f_nwgh=lag(nwgh);
				f_ntot=lag(ntot);
				f_totwgh=lag(totwgh);
			run;
			%ds_select(&TMP._1, &TMP._2, where=%str(sex="M"));
		%end;
		%else %if "&odsn"="GAP" %then %do;
			data &TMP._1;                                            
		 		SET work.&TMP._1;
				f_Value=lag(ivalue);
				if sex="M" then gap=(1-f_Value/ivalue)*100;
			run;
			data &TMP._2(drop=f_value sex rename=(gap=ivalue));    
		 		SET &TMP._1;
				drop ivalue;
				if  sex="F" then delete;
			run;
		%end;

		PROC SQL;
			CREATE TABLE work.&TMP._3 AS
			SELECT distinct
				a.geo ,
				a.time,
				a.age,
				%if "&odsn"="COVERAGE" %then %do;
					"dif" as unit FORMAT=$8. LENGTH=8,
			   		round((ivalue - f_ivalue),0.1) as ivalue,
				%end;
				%else %if "&odsn"="GAP" %then %do;
					"&iflag" as iflag FORMAT=$8. LENGTH=8,
					a.unrel,
				%end;
				%if "&odsn"="COVERAGE" %then %do;
					(n - f_n) as n,
					(nwgh -f_nwgh) as nwgh ,
					(ntot- f_ntot)  as ntot,
					(totwgh - f_totwgh) as totwgh,
				%end;
				%else %if "&odsn"="GAP" %then %do;
					b.n as f_n,
					a.n as m_n,
					b.nwgh as f_nwgh,
					a.nwgh as m_nwgh,
					b.ntot as f_ntot,
					a.ntot as m_ntot,
					b.totwgh as f_totwgh,
			 		a.totwgh as m_totwgh ,
				%end;
		 		"&sysdate" as lastup FORMAT=$8. LENGTH=8, 
				"&sysuserid" as	lastuser FORMAT=$8. LENGTH=8  
			FROM &TMP._2 as a
			%if "&odsn"="GAP" %then %do;
		 		LEFT JOIN &TMP as b ON (a.geo = b.geo) AND (a.age = b.age)  
			%end;
			;
		quit;

		%ds_select(&TMP._3, &TMP._4, where=%str(time =&yyyy and geo = "&ctry")); 
		%ds_append(&odsn, &TMP._4,  cond=&cond, lib=&olib, ilib=WORK);
		%work_clean(&TMP, &TMP._1, &TMP._2, &TMP._3, &TMP._4);
		%exit:
	%mend update;

	/******************************************************************************************/
	/**         run the operation                                                            **/
	/******************************************************************************************/
	/* for ad-hoc works, load PING library if it is not yet the case */

	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	/* run the operation (generation+update) for:
		 *  - all datasets, and 
	 	 * 	- all years in &years, and 
		 * 	- all countries/zones in &geos */
	%do _i=1 %to %list_length(&odsn)  ;      /* type  of calculation: GAP/COVERAGE  rate*/ 
	    
	    %let dsn=%scan(&odsn, &_i);

		/************************************************************************************/
	       						%put CALCULATION for %upcase(&dsn) ;  
	 	/************************************************************************************/

		%macro_put(&_mac, txt=Loop over %list_length(&year) zones/countries for geo &geo); 

	    %let ctrylst_in=;

		%do _iy=1 %to %list_length(&year);		/* loop over the list of input year */

	        %let yyyy=%scan(&year, &_iy);
			/************************************************************************************/
	       						%put CALCULATION for &yyyy year;  
			/************************************************************************************/
	        %if %error_handle(ExistingDataset, 
					%ds_check(&dsn, lib=WORK) EQ 0, mac=&_mac,
					txt=%bquote(! Output table already exists - Results will be appended !),verb=warn) %then %do;
				%let existsOutput=YES;
				%goto warning1; 
			%end;
			%warning1:

	        %create(&dsn, olib=&olib, labs=age, types=char, lens=15, wdsn=&wdsn);  

			%macro_put(&_mac, txt=Loop over %list_length(&geo) zones/countries for year &yyyy); 

	        /* run the operation (generation+update) for:
			 * 	- one single year &yyyy, and 
			 * 	- all countries/zones in &geos */
			%do _ig=1 %to %list_length(&geo); 		/* loop over the list of countries/zones */
	            %put geo=&geo; 
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
					%ds_isempty(&wdsn, var=GEO, _ans_=_ans, lib=WORK);

					%if	&_ans NE 1 %then %do; 
						/* first retrieve the list of countries present in the dataset (i.e. 
						* processed already) */
					    %var_to_list(&wdsn, GEO, _varlst_=ctrylst_in, distinct=YES);
						%put  ctrylst_in=&ctrylst_in in &dsn ;
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
					/* actually compute the GAP or COVERAGE rate  coefficients */
					%extract(&yyyy, &ctry, &weight, libcidb, libpdb, idb, dimensions=AGE RB090,
							vsum=PY100G PY080G PY110G); 

					%if "&dsn"="GAP"  %then
						%let var=pension;
					%else %if  "&dsn"="COVERAGE" %then
						  %let var=npension; 
					%compute(idb, &yyyy, &wdsn,&dsn,var=&var, dimensions=AGE RB090, labels=AGE SEX);
					%update(&dsn, &wdsn, &ctry, &yyyy, cond=(not(time=&yyyy and geo = "&ctry")), olib=&olib);   				
				%end;

				%if &type = 2 %then %do;
			       	/* Aggregate calculation  */
					%if "&dsn"="GAP"  %then
						%let force_Nwgh=1;
					%else %if  "&dsn"="COVERAGE" %then
						  %let force_Nwgh=0; 
				   	%silc_agg_compute(&area, &yyyy, &wdsn, AGGR,  force_Nwgh=&force_Nwgh,
						max_yback=0, thr_min=0.7, ilib=WORK, olib=WORK);  
					%update(&dsn, AGGR, &area, &yyyy, cond=(not(time=&yyyy and geo = "&area")), olib=&olib);    
	                %work_clean(AGGR); 
				%end;
	 		%end;   /* end loop "%do _ig=1 %to %list_length(&geo)" over the list of input geo */

			%work_clean(&wdsn); 
		%end;  /* end loop "%do _iy=1 %to %list_length(&year)" over the list of input years */
   		%put end of  &year year loop ;

		/************************************************************************************/
	       						%put EXPORT  %upcase(&dsn) file in csv ;   
	 	/************************************************************************************/
		%let _year=%list_quote(&year, mark=_EMPTY_, rep=%quote(_)); 

		%ds_export(&dsn, odir=&odir, ofn=&dsn._&_year&ext, delim=, dbms=, fmt=csv);
	    %work_clean(&dsn);
		%next:

	%end; /* end loop "%do _i=1 %to %list_length(&odsn)" of number output indicator(s) to be calculated: gap and coverage */ 
	%exit:
%mend silc_pension_gap_coverage_rate;


