/** 
## pension_gap_coverage_rate {#sas_pension_gap_coverage_rate}
Perform ad-hoc extraction for Data collection by DG JUST for Commission's next annual 
report on gender equality. 

	%pension_gap_coverage_rate(year,dsn_name,weight,geo=, idir=, lib= ,odir=,ext_odsn=);

### Arguments
* `year`: a or more years of interest;
* `dsn_name`: output dataset:  GAP/COVERAGE rate;
* `weight`: weight ;
* `geo` : (_option_) a list of countries or a geographical area; default: `geo=EU28`;
* `idir`: (_option_) name of the output directory where to look for _GAP_ indicators passed 
	instead of `ilib`; incompatible with `ilib`; by default, it is not used; 
* `lib`: (_option_) name of the output library where to look for _GAP_ indicators (see 
	note below);  
* `odir=`:		 Input directory name			 
* `ext_odsn=`:	 Generic output dataset name. 	 
 

### Returns
Two datasets:
* `%%upcase(GAP)` contains the _GAP_ table with genger gap in pension,
* `%%upcase(COVERAGE_RATE)` contains the _COVERAGE_ genger gap coverage rate in pension 
stored in the library passed through `olib`.

and Two csv files:
* `%%upcase(GENDER_&years&ext_odsn` contains the _GAP_ table with genger gap in pension for all countries available for specific years (&years) ,
* `%%upcase(COVERAGE_&years&ext_odsn` contains the _COVERAGE_ genger gap coverage rate in pension all countries available for specific years (&years).
stored in the pathname  passed through `odir`.


### Note
The publication is based on the following  indicators:

### References
1. [2016] http://ec.europa.eu/europe2020/pdf/themes/2016/adequacy_sustainability_pensions_201605.pdf
This indicator is defined in the Pension Adequacy Report 2015.
The definition of the coverage gap is on page 149 and the results displayed in Figure 3.23 (p. 155).
This indicator complements the gender gap in pensions (which excludes the persons with no pension at all). 

### See also
[2015]SPC and DG EMPL:  The 2015 Pension Adequacy Report: current and future income adequacy in old age in EU.Vol 1
*/ /** \cond */

/* credits: grillo */

%macro pension_gap_coverage_rate(year	      /* Area of interest 						  (REQ) */
								, dsn_name   /* Type of calculation (GAP/COVERAGE RATE)  (REQ) */                                   
								, weight     /* Weight variable    					  (REQ) */ 
								, geo=	      /* country/zone   						  (OPT) */
								, lib= 	  /* Output Library - default is WORK      	  (OPT) */
								, odir=	  /* Input directory name			          (OPT) */
								, ext_odsn=  /* Generic output dataset name 	          (OPT) */
								);

    %local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac, txt=Loop over %list_length(&year) year for table);
	%put;
	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _iy 	/* loop increment for year */
		_ic		/* loop increment for country */
		yyyy   	/* scanned year from years */
		area type
		isgeo
        existsOutput
		TMPdsn
        ctrylst
		ctrylst_in
		_ans;

   	
	%let g_flag=;
 	/* run the operation (generation+update) for:
	 * 	- all years in &years 
	 * 	- all countries/zones in &geos */

    %work_clean();

    %if %macro_isblank(lib)     %then %let  lib=WORK;
    %let existsOutput=NO;
    
	%if %error_handle(ErrorInputParameter,
		%macro_isblank(dsn_name) EQ 1, 
		txt=%bquote(! Output datasets are missing),verb=warn) %then %do;
		%goto exit; 
	%end;

	/* GEO: check/set */
	%if %macro_isblank(geo) %then	%let geo=EU28;
	/* clean the list of geo and retrieve type */
	%str_isgeo(&geo, _ans_=isgeo, _geo_=geo);
	%if %error_handle(ErrorInputParameter, 
		%list_count(&isgeo, 0) NE 0, mac=&_mac,		
		txt=%quote(!!! Wrong parameter GEO: must be country/geographical zone ISO code(s) !!!)) %then
	%goto exit;

	/* check WEIGHT variable  */
	%if %error_handle(WarningParameter, 
	%macro_isblank(weight) EQ 1, 
	     txt=%bquote(! No weight variable passed - Uniform weighting is used !), verb=warn) %then 
		 %let weight=PB040;
         %goto warning2;
    %warning2:
	/************************************************************************************/
	/**         creating/temporary and/or permanent dataset                            **/
	/************************************************************************************/

    /* create the working output table if it does not already exist */

    %macro create(dsn    /* permanet dataset to create    */
		, yyyy           /* current year                  */ 
		, geo            /* current geo/zone              */ 
		, ndsn           /* program number to exsecute    */
		, lib=           /* library to create the dataset */
        , labs=          /* labels od dimensions          */
        , types=         /* type of dimensions            */
		, lens=          /* lenght of dimensions          */
		, TMPdsn=        /* temporary working dataset     */
        );

		%local _mac;
		%let _mac=&sysmacroname;
   		%put &_mac;

		/* local variables used in this macro */
		%local _i
			ans				/* local test variable */
			warmsg errmsg;	/* error management */

   		%if %macro_isblank(lib)      %then   %let lib=WORK;;
		%if %macro_isblank(TMPdsn)   %then 	 %let TMPdsn=dsn; 

		/* working dataset */
   		 %if  %ds_check(&TMPdsn, lib=WORK) EQ 1 %then %do;
	     %if &ndsn =1 %then %do;
		 	%let vara= geo time  age   sex  unit  ivalue  iflag  unrel  n   nwgh  ntot  totwgh lastup lastuser ;
		 	%let lena= 15   8     15     1    8      8      8     8      8     8     8     8        8      8    ;
		 	%let typa= char num  char  char char   num    char   num   num   num  num    num     char    char  ;
		 %end;
		 %else %if  &ndsn =2 %then %do;
			 %let vara= geo time  age   sex  npension unit ivalue  iflag  unrel  n   nwgh  ntot  totwgh lastup lastuser  ;
			 %let lena= 15   8     15     1      8      8     8      8      8     8     8    8      8       8      8      ;
			 %let typa= char num  char  char  num	  char  num    char   num   num   num  num    num     char   char    ;
	     %end;
	     	%ds_create(&TMPdsn, var=&vara, type=&typa, len=&lena,  ilib=WORK, olib=WORK);
		 %end;
  
		 %if %error_handle(ExistingDataset, 
			%ds_check(&dsn, lib=&lib) EQ 0, 
			txt=! Output table already exist !, verb=warn) %then %goto exit;
	
		/* permanent dataset */
	 	 %if &ndsn =1 %then %do;
			 	%ds_create(&dsn, var=&labs, len=&lens, type=&types, idsn=INDICATOR_CONTENTS_SEX, olib=&lib, ilib=LIBCFG);
		 %end;
	 	 %else %if  &ndsn =2 %then %do;
				%ds_create(&dsn, var=&labs, len=&lens, type=&types, idsn=INDICATOR_CONTENTS, olib=&lib, ilib=LIBCFG);
	 	 %end;
    
		%exit:
	%mend create;
	/************************************************************************************/
	/**         extraction                                                             **/
	/************************************************************************************/

    %macro extract( yyyy	 /* Year of interest                                          (REQ) */
			, clist			 /* Country/geographical area of interest                     (REQ) */
			, weight         /* weight                                                    (REQ) */
			, idb			 /* idb library                                               (REQ) */
			, pdb			 /* idb library                                               (REQ) */
			, odsn			 /* output dataset                                            (REQ) */
			, ndsn           /* program number to exsecute                                (REQ) */ 
			, dimensions=	 /* breakdown variables                                       (OPT) */
			, vsum=		     /* list of varible to sum                                    (OPT) */
			, cond=          /* condition to apply to if condition  (program number 1)    (OPT) */
			, elderly =      /* boolean value N/Y to take in account the elderly person   (OPT) */
			, pensioners =   /* boolean value N/Y to take in account the pensioner person (OPT) */ 
			);

		%local _mac _legacy;
		%let _mac=&sysmacroname;

		%put; 
		%put --------------------------------------------------------------------------;
		%put &_mac for &clist ;
		%put --------------------------------------------------------------------------;
		%put; 
		
		/* local variables that depend on the input parameters or simply used inside the macro */
		%local _i		/* loop increment                                     */
			yy			/* year substring, e.g. if yyyy=2012 then yy=12       */
			vtyp		/* type of variable: personal (P) or household (H)    */
			ndim		/* number of dimensions                               */
			dim			/* single scanned dimension                           */
			pvar        /* list vsum variables plus dsn                       */
			_vsum       /* single vsum variables                              */
			__vsum      /* single scanned vsum  plus dsn                      */
			_pvar       /* list vsum variables plus dsn with comma separater  */
			wrnmsg; 	/* error management variable                          */
	 
		/* test whether input parameters GEO and YYYY were passed */
		%if %macro_isblank(clist) or %macro_isblank(yyyy) or  %macro_isblank(vsum)    %then   %goto exit;
        
		/* proceed ... */
		%let yy=%substr(&yyyy,3,2);
		%let vtyp=%lowcase(%sysfunc(substr(&vsum, 1, 1)));
		%let qctry=%list_quote(&clist);
	 
		/* test the existence of the output dataset */
		%let wrnmsg=%quote(! Output table already exist- Overwrite !);
		%if %upcase(&_legacy)=YES %then %do;
			%if %sysfunc(exist(WORK.&odsn, data)) %then %do;
				%goto warning;
			%end;
		%end;
		%else %do;
			%if %error_handle(ExistingDataset, 
					%ds_check(&odsn, lib=WORK) EQ 0,  
					txt=&wrnmsg, verb=warn) %then 
				%goto warning;
		%end;
		%warning: 
		%if %macro_isblank(dimensions)       %then 	%let dimensions= AGE RB090;      /* list separator */
	    %if %macro_isblank(cond)             %then 	%let cond= where PENSION  ne 0;  /* list separator */
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
			CREATE TABLE WORK.&odsn as SELECT
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
		%if &ndsn=1 %then %do;             /* applied only for  gap (program number 1) */
			data &odsn; 
				 set &odsn; 
				 %if &elderly =N and  &pensioners=Y %then %do;
				  	 &cond;
				 %end;
				 %else %if &elderly =Y and  &pensioners=N %then %do;
				     ;
				 %end;
				 %else %do;
				 	 %put made correct selection for Elderly and Pensioners;
					 %goto exit;
				 %end;
			run;
	      %end;
		%exit:
	%mend extract;
	/************************************************************************************/
	/**         computetion                                                            **/
	/************************************************************************************/
	%macro compute (idsn 	    /* input dataset      					(REQ)*/
			, yyyy  		 	/* reference year     					(REQ)*/
			, odsn  		 	/* output dataset     					(REQ)*/
			, ndsn           	/* number of calculation                (REQ)*/
			, var=           	/* pension/npension                     (REQ)*/
			, dimensions=    	/* breakdown variables                  (OPT)*/
			, labels=        	/* labels for breakdown variables       (OPT)*/
			, iflag=         	/* flag variable 						(OPT)*/
			, stat2=         	/* statistic variable 					(OPT)*/
			);

		%let _mac=&sysmacroname;
		%put; 
		%put --------------------------------------------------------------------------;
		%put &_mac ;
		%put --------------------------------------------------------------------------;
		%put; 
		%if &stat2= 					%then 	%let stat2=mean;
		%if &iflag= 					%then 	%let iflag=;
	 	
		%if %macro_isblank(dimensions)  %then 	%let dimensions= AGE RB090;  
		
			/* locally used variables */
		%local _i			/* loop increment */
			_j			/* loop increment */
			tmp				/* name of the temporary dataset */
			ndim			/* number of dimensions */
			dim				/* single dimension */
			per_dimensions;	/* formatted crossed dimensions */
			 ; 
		%let tmp=TMP_&_mac;

	    %if %macro_isblank(odsn)   %then 	%let odsn=dsn; 

		
		/* retrieve the number of dimensions */
		%let ndim=%sysfunc(countw(&dimensions)); /* %list_length(&dimensions) */

	    %let per_dimensions=%list_quote(&dimensions, mark=_EMPTY_, rep=%quote(*));;
		%let _dimensions=%list_quote(&dimensions, mark=_EMPTY_, rep=%quote(,));

		/* set default labels */
		%if &labels= /* %macro_isblank(labels) */ %then %do;
			%let labels=&dimensions;
		%end;
	   
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
		RUN;


		/* perform the tabulate operation*/
	    %if &ndsn =2 %then %do;
	      	   PROC TABULATE data=work.IDB  out=WORK.&tmp ;
				 	%do _i=1 %to &ndim;
				 		%let dim=%scan(&dimensions, &_i);
						FORMAT &dim _fmt_&dim._.;
						CLASS &dim / MLF ;						
				 	%end;
		      	 	CLASS &var ;
		 	  	 	CLASS DB020;
			  	 	VAR weight;
			  	    TABLE DB020  * &per_dimensions, &var * weight * (RowPctSum N Sum) /printmiss;
		        RUN; 
	      %end;
		  %else  %if &ndsn =1 %then  %do;
		 		PROC MEANS data=work.idb  &stat2 N sumwgt noprint;
					CLASS DB020; 								/* DB020 will be used as row */
					%do _i=1 %to &ndim;
						%let dim=%scan(&dimensions, &_i);
						FORMAT &dim _fmt_&dim._.;
						CLASS  &dim / MLF ;						/* &dim will be used as row through &per_dimensions */
					%end;
					VAR &var;									/* &var will be used as row */
					WEIGHT WEIGHT;
					OUTPUT out=work.&tmp &stat2()=&stat2._20 N()=n sumwgt()=sum_of_WGHT ;
				run;
 
				%ds_select(&tmp, &tmp._1, where=_TYPE_=7);
				%let _dim=%list_quote(&dimensions, mark=_EMPTY_, rep=%quote(,));
		  %end;

		  PROC SQL;
		       INSERT INTO work.&odsn  
			    select distinct
			 	 	tmp.DB020 as geo FORMAT=$5. LENGTH=5,
			 	 	&yyyy as time,
			 	   	%do _i=1 %to &ndim;
						%let dim=%scan(&dimensions, &_i);
						%let lab=%scan(&labels, &_i);
						&dim as &lab,
					%end; 
					%if &ndsn = 2 %then %do;
			 	 		tmp.&var as &var,
	  					"Dif" as unit, 
			 	 		tmp.weight_PctSum_1101 as ivalue,
					%end;
					%else %if &ndsn =1 %then %do;
						"avg" as unit, 
						mean_20 as ivalue,
					%end;
			     	"&iflag "  as iflag,
					%if &ndsn = 2 %then %do;
			 	 		(case when sum(tmp.weight_N) < 20  then 2
			  	   	  		 when sum(tmp.weight_N) < 50  then 1
			  	  	  		 else 0
		     	   	  	 end) as unrel,
						tmp.weight_N as n,
			 	 		tmp.weight_sum as nwgh,
		     	 		sum(tmp.weight_N) as ntot,
	         	 		sum(tmp.weight_Sum) as totwgh,
					%end;
					%else  %if &ndsn = 1 %then %do;
						(case when n < 20 then 2
			 				when n < 50 then 1
			 				else 0
				 		end) as unrel,
	                    n as n,
						sum_of_WGHT as nwgh,
						n as ntot,
						sum(sum_of_WGHT) as totwgh,
					%end;
		     	 	"&sysdate" as lastup,
		     	 	"&sysuserid" as	lastuser 
				 	FROM WORK.&tmp._1 as tmp
	             	GROUP BY tmp.DB020,
					%do _i=1 %to &ndim;
						%let dim=%scan(&dimensions, &_i);
						tmp.&dim,
					%end;
					unit;
	    		 QUIT; 
		 %exit:
		  
	%mend compute;
	/************************************************************************************/
	/**         update GAP                                                             **/
	/************************************************************************************/

	%macro update_gap(odsn          /* output dataset                        (REQ)*/
            		, idsn          /* input  dataset                        (REQ)*/
					, ctry       
					, yyyy          /* reference year                        (REQ)*/
					, cond=         /* condition to apply to ds_append macro (OPT)*/
					, where=        /* condition to apply to ds_select macro (OPT)*/
					, lib=          /* output libname                        (OPT)*/
				    , iflag=        /* iflag value                           (OPT)*/
				    );

		%local _mac ;
		%let _mac=&sysmacroname;
	  	%put --------------------------------------------------------------------------;
		%put &_mac for  &ctry country &yyyy year;
		%put --------------------------------------------------------------------------;
		%put; 
	    %local ans;
	
		%let TMP=TMP_&_mac;
	    %work_clean(&TMP._1);
		%work_clean(&TMP);
	    %if %macro_isblank(iflag)       %then 	%let iflag= ;  
		%if %macro_isblank(lib)         %then 	%let lib=WORK ;  
		%if %macro_isblank(ilib)        %then 	%let ilib=WORK ;  
		%ds_isempty(&idsn, var=geo, _ans_=ans);

		%if %error_handle(ErrorInputDataset, 
			&ans  EQ 1, mac=&_mac,		
			txt=!!! input dataset %upcase(&idsn) empty!!!) %then
		%goto exit;

		%ds_sort(&idsn, asc=geo   age sex);
		%ds_copy(&idsn, &TMP._1);
	    %ds_select(&TMP._1, &TMP, where=&where ); 
		%ds_sort(&TMP._1, asc=geo   age sex);

		data &TMP._1;                                            
	 		set &TMP._1;
			f_Value=lag(ivalue);
		run;
		data &TMP._1;         
			set &TMP._1;
			if sex="M" then gap=(1-f_Value/ivalue)*100;
		run;
	   
		data &TMP._1(drop=f_value sex rename=(gap=ivalue));    
	 		set &TMP._1;
			drop ivalue;
			if  sex="F" then delete;
		run;
     
		PROC SQL;
			CREATE TABLE work.&TMP._2 /*&odsn*/  AS
			SELECT distinct
			a.geo ,
			a.time,
			a.age,
			"avg" as unit FORMAT=$8. LENGTH=8,
	   		a.ivalue,
			"&iflag" as iflag  FORMAT=$8. LENGTH=8,
			a.unrel,
			b.n as f_n,
			a.n as m_n,
			b.nwgh as f_nwgh,
			a.nwgh as m_nwgh,
			b.ntot as f_ntot,
			a.ntot as m_ntot,
			b.totwgh as f_totwgh,
	 		a.totwgh as m_totwgh ,
			"&sysdate" as lastup FORMAT=$8. LENGTH=8,
			"&sysuserid" as	lastuser FORMAT=$8. LENGTH=8  
		 FROM &TMP._1 as a
		 LEFT JOIN &TMP as b ON (a.geo = b.geo)  AND (a.age = b.age)  
	     ;
		QUIT;
	    %ds_select(&TMP._2,&TMP._3,where=%str(time =&yyyy and geo = "&ctry")); 
		%ds_append(&odsn, &TMP._3,  cond=&cond, lib=&lib, ilib=WORK);
		*%work_clean(&TMP._3, &TMP._2 );
	%exit:
	%mend update_gap;
	/************************************************************************************/
	/**         update COVERAGE                                                        **/
	/************************************************************************************/
	%macro update_rate(odsn     /* output dataset                        (REQ)*/
		            , idsn          /* input  dataset                        (REQ)*/
					, ctry   
					, yyyy          /* reference year                        (REQ)*/
					, var           /* variable to analyze                   (OPT)*/
					, cond=         /* condition to apply to ds_append macro (OPT)*/
					, where=        /* condition to apply to ds_select macro (OPT)*/
					, lib=          /* output libname                        (OPT)*/
					, iflag=        /* iflag value                           (OPT)*/
				    );

		%local _mac ;
		%let _mac=&sysmacroname;
	  	%put --------------------------------------------------------------------------;
		%put &_mac for &ctry country and &yyyy year ;
		%put --------------------------------------------------------------------------;
	
	    %local ans;
		
		%let TMP=TMP_&_mac;
	   
	    %if %macro_isblank(var)         %then 	%let var= npension; 
	    %if %macro_isblank(iflag)       %then 	%let iflag= ;  
		%if %macro_isblank(lib)         %then 	%let lib=WORK ;  
		
		%ds_isempty(&idsn, var=geo, _ans_=ans);

		%if %error_handle(ErrorInputDataset, 
			&ans  EQ 1, mac=&_mac,		
			txt=!!! input dataset %upcase(&idsn) empty!!!) %then
		%goto exit;
	    %ds_select(&idsn,&TMP,where=%str(&var=1));        /*  selection of  retirement persons  */
	 	%ds_sort(&TMP, asc=geo   age sex);

		data work.&TMP._1;                                            
	 		set work.&TMP;
			f_ivalue=lag(ivalue);
			f_n=lag(ivalue);
			f_nwgh=lag(nwgh);
			f_ntot=lag(ntot);
			f_totwgh=lag(totwgh);
		run;
		%ds_select(&TMP._1,&TMP._2,where=%str(sex="M"));

		PROC SQL;
			CREATE TABLE work.&TMP._3 AS
			SELECT distinct
			a.geo ,
			a.time,
			a.age,
			"dif" as unit FORMAT=$8. LENGTH=8,
	   		round((ivalue - f_ivalue),0.1) as ivalue,
			"&iflag" as iflag FORMAT=$8. LENGTH=8,
			a.unrel,
			(n - f_n) as n,
			(nwgh -f_nwgh) as nwgh ,
			(ntot- f_ntot)  as ntot,
			(totwgh - f_totwgh) as totwgh,
	 		"&sysdate" as lastup FORMAT=$8. LENGTH=8, 
			"&sysuserid" as	lastuser FORMAT=$8. LENGTH=8  
		 FROM &TMP._2 as a
	     ;
	QUIT;
 
	%ds_select(&TMP._3,&TMP._4,where=%str(time =&yyyy and geo = "&ctry")); 
	%ds_append(&odsn, &TMP._4,  cond=&cond, lib=&lib, ilib=WORK);
    *%work_clean(&TMP._3, &TMP._2);
	%exit:
	%mend update_rate;
	/*
    /************************************************************************************/
	/**         run the operation                                                      **/
	/************************************************************************************/
	/*
	/* run the operation (generation+update) for:
		 *  - all datasets, and 
	 	 * 	- all years in &years, and 
		 * 	- all countries/zones in &geos */
	%do _i=1 %to %list_length(&dsn_name)  ;      /* type  of calculation: GAP/COVERAGE  rate*/ 
 
	    %if %list_find(%scan(&dsn_name, &_i), gap)> 0  %then  %do;
		     %let  ndsn=1;
		
			 %let dsn=%upcase(gap);
		%end;
		%else %if  %list_find(%scan(&dsn_name, &_i), coverage_rate)> 0 %then %do;
	        %let  ndsn=2;
			 %let  force_Nwgh=0;
			%let dsn=%upcase(coverage_rate);
		%end;

	/************************************************************************************/
       						%put CALCULATION for %upcase(&dsn) ;  
 	/************************************************************************************/

		%macro_put(&_mac, txt=Loop over  %list_length(&year) zones/countries for geo &geo); 

		%put year=&year;
        %let ctrylst_in=;

		%do _iy=1 %to %list_length(&year);		/* loop over the list of input years */

            %let yyyy=%scan(&year, &_iy);
	/************************************************************************************/
       						%put CALCULATION for %upcase(&yyyy) ;  
 	/************************************************************************************/
            %if %error_handle(ExistingDataset, 
			%ds_check(&dsn, lib=WORK) EQ 0, 
				txt=%bquote(! Output table already exists - Results will be appended!),verb=warn) %then %do;
				%let existsOutput=YES;
				%goto warning1; 
			%end;
			%warning1:
	
            %create(&dsn,&yyyy, &geo,&ndsn,lib=&lib,labs=age ,  types=char, lens=15,TMPdsn=dsn);  
 			
			%macro_put(&_mac, txt=Loop over  %list_length(&geo) zones/countries for year &yyyy); 

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
					%ds_isempty(dsn, var=GEO, _ans_=_ans, lib=WORK);

					%if	&_ans NE 1 %then %do; 
						/* first retrieve the list of countries present in the dataset (i.e. 
						* processed already) */
					    %var_to_list(dsn, GEO, _varlst_=ctrylst_in, distinct=YES);
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
					%extract(&yyyy, &ctry,&weight, libcidb, libpdb, idb,&ndsn, dimensions=AGE RB090,vsum=PY100G PY080G PY110G); 

					%if "&dsn"="%upcase(gap)"  %then %do;
						%let var=pension;
						%compute(idb, &yyyy, dsn,&ndsn,var=&var, dimensions=AGE RB090,labels=AGE SEX);
					
						%update_gap(&dsn, dsn,&ctry,&yyyy,cond=(not(time=&yyyy and geo = "&ctry")),where=(SEX="F"),lib=&olib);   
					%end;
					%else %if  "&dsn"="%upcase(coverage_rate)" %then %do;
						  %let var=npension; 
	 				      %compute(idb, &yyyy, dsn,&ndsn,var=&var, dimensions=AGE RB090,labels=AGE SEX);
						 
						  %update_rate(&dsn, dsn,&ctry,&yyyy,cond=(not(time=&yyyy and geo = "&ctry")),where=(SEX="F"),lib=&olib);  
					%end;
				
				%end;
				%if &type = 2 %then %do;
			       	/* Aggregate calculation  */
				   %if  "%upcase(&dsn)"="%upcase(gap)"  %then %do;
				    /* %silc_agg_compute*/
						%silc_agg_compute(&area, &yyyy, dsn, AGGR,  force_Nwgh=1,
								max_yback=0, thr_min=0.7, ilib=WORK, olib=WORK);  
					 	%update_gap(&dsn, AGGR,&area,&yyyy,cond=(not(time=&yyyy and geo = "&area")),where=(SEX="F"),lib=&olib);    
					%end;
					%else %if  "%upcase(&dsn)"="%upcase(coverage_rate)" %then %do;
						  %silc_agg_compute(&area, &yyyy, dsn, AGGR,force_Nwgh=0,
								max_yback=0,thr_min=0.7, ilib=WORK, olib=WORK);  
						  %update_rate(&dsn, AGGR,&area,&yyyy,cond=(not(time=&yyyy and geo = "&area")),where=(SEX="F"),lib=&olib); 
					%end;
                    %work_clean(AGGR); 
				%end;
 			%end;                  		/* end loop over the list of input geo */
			%work_clean(dsn); 
		%end;                           /* end loop over the list of input years */
	   	%put end of first year &yyyy ;
	%end; /* end loop over number of request: gap and coverage rate */ 
	%put;
	/************************************************************************************/
       						%put EXPORT  %upcase(&dsn_name) file in csv ;   
 	/************************************************************************************/
    %put;
   	%do _i=1 %to %list_length(&dsn_name)  ; 
		%let years=%list_quote(&year, mark=_EMPTY_, rep=%quote(_)); 
 	    %if %list_find(%upcase(%scan(&dsn_name, &_i)), %upcase(gap))> 0  %then  %do; 				/*1: export GENDER gap in pension   */
		  	 %let  dsn=%upcase(gap);
			 %if %error_handle(ExistingDataset, 
			 	 	%ds_check(&dsn, lib=&lib) EQ 1, 
			 		txt=%bquote(! Output table does not exist!),verb=warn) %then %do;
				%goto next; 
			  %end;
			  %ds_export(&dsn, odir=&odir,ofn=RATE_GAP_&years&ext_odsn, delim=, dbms=, fmt=csv);
  	     %end;
		 %else %if %list_find(%upcase(%scan(&dsn_name, &_i)), %upcase(coverage_rate))> 0 %then %do; /*2: export COVERAGE rate          */
	        
              %let dsn=%upcase(coverage_rate);
			  %if %error_handle(ExistingDataset, 
		 	 		%ds_check(&dsn, lib=&lib) EQ 1, 
		 			txt=%bquote(! Output table does not exist!),verb=warn) %then %do;
			 	 %goto next; 
		  	   %end; 
	 	  	  %ds_export(&dsn, odir=&odir,ofn=RATE_COVERAGE_&years&ext_odsn, delim=, dbms=, fmt=csv);

		 %end;
	%next:
	%end;
%mend pension_gap_coverage_rate;


